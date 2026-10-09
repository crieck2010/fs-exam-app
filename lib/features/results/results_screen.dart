import 'package:flutter/material.dart';

import '../../data/models/question.dart';
import '../domains/domain_info.dart';
import '../quiz/quiz_controller.dart';
import '../quiz/quiz_screen.dart';

/// Score summary, per-domain breakdown, and expandable review of every
/// answered question with its worked explanation.
class ResultsScreen extends StatelessWidget {
  final List<AnswerRecord> records;
  final int total;
  final String title;
  final List<Question> allQuestions;

  /// Forwarded to retake/drill sessions so SRS keeps learning.
  final Future<void> Function(Question question, bool isCorrect)? onAnswerLocked;

  const ResultsScreen({
    super.key,
    required this.records,
    required this.total,
    required this.title,
    required this.allQuestions,
    this.onAnswerLocked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final correct = records.where((r) => r.isCorrect).length;
    final pct = total == 0 ? 0.0 : correct / total;
    final missed = records.where((r) => !r.isCorrect).toList();

    final breakdown = <String, List<int>>{};
    for (final r in records) {
      final entry = breakdown.putIfAbsent(r.question.domain, () => [0, 0]);
      entry[1]++;
      if (r.isCorrect) entry[0]++;
    }

    return Scaffold(
      appBar: AppBar(title: Text('$title — results')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        '${(pct * 100).round()}%',
                        style: theme.textTheme.displayLarge?.copyWith(
                          color: pct >= 0.7
                              ? Colors.green
                              : theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('$correct of $total correct',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: pct,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text('By section', style: theme.textTheme.titleLarge),
              ...breakdown.entries.map((e) {
                final info = domainInfo(e.key);
                final c = e.value[0], t = e.value[1];
                return ListTile(
                  leading: Icon(info.icon),
                  title: Text(info.name),
                  trailing: Text('$c / $t'),
                  subtitle: LinearProgressIndicator(
                    value: t == 0 ? 0 : c / t,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
              if (missed.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Review your misses (${missed.length})',
                    style: theme.textTheme.titleLarge),
                ...missed.map((r) => Card(
                      child: ExpansionTile(
                        title: Text(
                          r.question.stem,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                            'You chose: ${r.question.choices[r.selectedIndex]}'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'Correct: ${r.question.correctChoice}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text(r.question.explanation),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retake'),
                    onPressed: () {
                      final retry = List<Question>.of(allQuestions)..shuffle();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => QuizScreen(
                            questions: retry,
                            title: title,
                            onAnswerLocked: onAnswerLocked,
                          ),
                        ),
                      );
                    },
                  ),
                  if (missed.isNotEmpty)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.target),
                      label: const Text('Drill misses'),
                      onPressed: () {
                        final drill =
                            missed.map((r) => r.question).toList()..shuffle();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => QuizScreen(
                              questions: drill,
                              title: '$title — misses',
                              onAnswerLocked: onAnswerLocked,
                            ),
                          ),
                        );
                      },
                    ),
                  TextButton(
                    child: const Text('New quiz'),
                    onPressed: () => Navigator.of(context)
                        .popUntil((route) => route.isFirst),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
