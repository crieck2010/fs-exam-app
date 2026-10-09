import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/question.dart';
import '../../domains/domain_info.dart';
import '../../quiz/quiz_screen.dart';
import '../insights/insights.dart';
import '../insights/weekly_report.dart';
import '../srs/study_repository.dart';
import '../study_event.dart';

/// Week-in-review: headline stats, per-section accuracy, focus areas and
/// strengths, and one-tap drills for the focus areas.
class WeeklyReportScreen extends StatelessWidget {
  final List<StudyEvent> journal;
  final List<Question> bank;
  final int dueCount;

  const WeeklyReportScreen({
    super.key,
    required this.journal,
    required this.bank,
    required this.dueCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final report = WeeklyReport.build(journal, now);
    final insights = Insights.build(journal, now);

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly report')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _headlineRow(context, report),
              const SizedBox(height: 16),
              _sectionTitle(theme, 'By section (weakest first)'),
              if (report.perDomain.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                        'Answer some quizzes this week and your per-section '
                        'breakdown will appear here.'),
                  ),
                ),
              for (final stat in report.domainsByAccuracy)
                _domainBar(context, stat),
              const SizedBox(height: 16),
              _sectionTitle(theme, 'Focus areas'),
              if (insights.focus.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                        'Needs at least 5 answers per section in the last '
                        '30 days to call out focus areas.'),
                  ),
                ),
              for (final f in insights.focus)
                _insightRow(context, f, isFocus: true),
              const SizedBox(height: 16),
              _sectionTitle(theme, 'Strengths'),
              if (insights.strengths.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Your strongest sections will appear here.'),
                  ),
                ),
              for (final s in insights.strengths)
                _insightRow(context, s, isFocus: false),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.history_outlined),
                  title: const Text('Spaced-repetition queue'),
                  subtitle: Text(dueCount == 0
                      ? 'All caught up. Nothing due for review.'
                      : '$dueCount question${dueCount == 1 ? '' : 's'} due for review'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: theme.textTheme.titleLarge),
    );
  }

  Widget _headlineRow(BuildContext context, WeeklyReport report) {
    final theme = Theme.of(context);
    return Row(
      children: [
        _statCard(context, '${report.answered}', 'answered'),
        const SizedBox(width: 8),
        _statCard(context, '${(report.accuracy * 100).round()}%',
            'accuracy',
            color: report.accuracy >= 0.7 ? Colors.green : null),
        const SizedBox(width: 8),
        _statCard(context, '${report.activeDays}', 'active days'),
        const SizedBox(width: 8),
        _statCard(context, '${report.qotdAnswered}', 'QOTDs',
            icon: Icons.today_outlined),
      ],
    );
  }

  Widget _statCard(BuildContext context, String value, String label,
      {Color? color, IconData? icon}) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              if (icon != null) Icon(icon, size: 20),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(label, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _domainBar(BuildContext context, DomainStat stat) {
    final theme = Theme.of(context);
    final info = domainInfo(stat.domain);
    final color = stat.accuracy >= 0.7
        ? Colors.green
        : (stat.accuracy >= 0.5 ? Colors.orange : theme.colorScheme.error);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(info.icon, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(info.name)),
                Text(
                  '${(stat.accuracy * 100).round()}% (${stat.correct}/${stat.answered})',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: stat.accuracy,
                minHeight: 8,
                color: color,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _insightRow(BuildContext context, DomainInsight insight,
      {required bool isFocus}) {
    final theme = Theme.of(context);
    final info = domainInfo(insight.domain);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          isFocus ? Icons.target : Icons.emoji_events_outlined,
          color: isFocus ? theme.colorScheme.error : Colors.green,
        ),
        title: Text(info.name),
        subtitle: Text(
            '${(insight.accuracy * 100).round()}% over ${insight.answered} answers'),
        trailing: isFocus
            ? FilledButton.tonal(
                onPressed: () => _drillFocus(context, insight),
                child: const Text('Drill'),
              )
            : null,
      ),
    );
  }

  void _drillFocus(BuildContext context, DomainInsight insight) {
    final questions = Insights.drillQuestions(
      domain: insight.domain,
      bank: bank,
      journal: journal,
      limit: 20,
    );
    if (questions.isEmpty || !context.mounted) return;
    final study = context.read<StudyRepository>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          questions: questions,
          title: 'Focus: ${domainInfo(insight.domain).name}',
          sessionKind: 'drill',
          onAnswerLocked: (event) => study.recordAnswer(event),
        ),
      ),
    );
  }
}
