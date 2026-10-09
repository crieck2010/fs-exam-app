import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/monetization/monetization.dart';
import '../../data/bank_repository.dart';
import '../../data/models/question.dart';
import '../quiz/quiz_screen.dart';
import '../settings/settings_screen.dart';
import '../study/qotd/qotd.dart';
import '../study/srs/srs_record.dart';
import '../study/srs/study_repository.dart';
import '../study/streaks/streak_logic.dart';
import 'domain_info.dart';

/// Home screen: study hub on top (streak, question of the day, spaced
/// review), domain section picker below.
///
/// The domain list is the app's "section picker" — each section maps 1:1
/// to an engine domain slug.
class DomainPickerScreen extends StatefulWidget {
  const DomainPickerScreen({super.key});

  @override
  State<DomainPickerScreen> createState() => _DomainPickerScreenState();
}

class _DomainPickerScreenState extends State<DomainPickerScreen> {
  final _repository = BankRepository();
  final _entitlements = StubEntitlements();

  Future<_HomeData>? _dataFuture;
  final Set<String> _selected = {...kDomains.map((d) => d.slug)};
  int _questionCount = 20;

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
  }

  Future<_HomeData> _load() async {
    final study = context.read<StudyRepository>();
    // Newest bundled bank; all bundled banks share schema v1.
    final questions =
        await _repository.loadBank(BankRepository.availableBanks.last);
    final counts = <String, int>{};
    for (final q in questions) {
      counts[q.domain] = (counts[q.domain] ?? 0) + 1;
    }
    final now = DateTime.now();
    final qotd = QotdController(repo: study, bank: questions, now: now);
    qotd.addListener(_refresh);
    final due = SrsScheduler.dueQuestions(study.loadRecords(), questions, now,
        limit: 100000); // uncapped: this is the displayed count
    return _HomeData(
      questions: questions,
      counts: counts,
      streak: study.loadStreak(),
      dueCount: due.length,
      qotd: qotd,
    );
  }

  void _refresh() => setState(() {});

  Future<void> _reload() async {
    final old = await _dataFuture;
    if (!mounted) return;
    old?.qotd.removeListener(_refresh);
    old?.qotd.dispose();
    setState(() {
      _dataFuture = _load();
    });
  }

  @override
  void dispose() {
    _dataFuture?.then((d) {
      d.qotd.removeListener(_refresh);
      d.qotd.dispose();
    });
    super.dispose();
  }

  /// Records one locked-in answer into the SRS scheduler (all sessions).
  Future<void> _recordSrs(Question question, bool isCorrect) async {
    await context
        .read<StudyRepository>()
        .recordAnswer(question, isCorrect, DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FS Exam Prep'),
        actions: [
          FutureBuilder<_HomeData>(
            future: _dataFuture,
            builder: (context, snapshot) {
              final streak = snapshot.data?.streak;
              if (streak == null || streak.count == 0) {
                return const SizedBox.shrink();
              }
              return Tooltip(
                message: 'Day streak (best: ${streak.best})',
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department,
                          color: Colors.orange, size: 22),
                      Text('${streak.count}',
                          style:
                              Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: FutureBuilder<_HomeData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load the question bank:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildHome(context, snapshot.data!);
        },
      ),
    );
  }

  Widget _buildHome(BuildContext context, _HomeData data) {
    final theme = Theme.of(context);
    final selectable = data.counts.keys.toSet();
    final poolSize = _selected
        .where(selectable.contains)
        .fold<int>(0, (sum, slug) => sum + data.counts[slug]!);
    final count = min(_questionCount, poolSize);

    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _qotdCard(context, data),
          if (data.dueCount > 0) _dueCard(context, data),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('Pick your sections',
                style: theme.textTheme.headlineSmall),
          ),
          for (final domain in kDomains)
            if (selectable.contains(domain.slug))
              CheckboxListTile(
                secondary: Icon(domain.icon),
                title: Text(domain.name),
                subtitle: Text(
                    '${domain.blurb}\n${data.counts[domain.slug]} questions available'),
                isThreeLine: true,
                value: _selected.contains(domain.slug),
                onChanged: (value) => setState(() {
                  if (value == true) {
                    _selected.add(domain.slug);
                  } else {
                    _selected.remove(domain.slug);
                  }
                }),
              ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('Questions:'),
                    Expanded(
                      child: Slider(
                        value: _questionCount.toDouble(),
                        min: 5,
                        max: 50,
                        divisions: 9,
                        label: '$_questionCount',
                        onChanged: (v) =>
                            setState(() => _questionCount = v.round()),
                      ),
                    ),
                    Text('$_questionCount'),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: Text(
                        'Start quiz ($count question${count == 1 ? '' : 's'})'),
                    onPressed: _selected.isEmpty || poolSize == 0
                        ? null
                        : () => _startQuiz(context, data, count),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _qotdCard(BuildContext context, _HomeData data) {
    final theme = Theme.of(context);
    final qotd = data.qotd;
    final info = domainInfo(qotd.today.domain);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.today_outlined, size: 32),
        title: const Text('Question of the day'),
        subtitle: Text(
          qotd.answered
              ? (qotd.wasCorrect == true
                  ? 'Answered correctly — streak extended'
                  : 'Answered — nice work showing up')
              : '${info.name} · keeps your streak alive',
        ),
        trailing: qotd.answered
            ? Icon(
                qotd.wasCorrect == true ? Icons.check_circle : Icons.cancel,
                color: qotd.wasCorrect == true
                    ? Colors.green
                    : theme.colorScheme.error,
              )
            : FilledButton(
                onPressed: () => _openQotd(context, data),
                child: const Text('Answer'),
              ),
        onTap: qotd.answered ? null : () => _openQotd(context, data),
      ),
    );
  }

  Widget _dueCard(BuildContext context, _HomeData data) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.history_outlined, size: 32),
        title: Text('${data.dueCount} due for review'),
        subtitle: const Text('Spaced repetition — oldest due first'),
        trailing: FilledButton.tonal(
          onPressed: () => _startReview(context, data),
          child: const Text('Review'),
        ),
        onTap: () => _startReview(context, data),
      ),
    );
  }

  Future<void> _openQotd(BuildContext context, _HomeData data) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          questions: [data.qotd.today],
          title: 'Question of the day',
          onAnswerLocked: (question, isCorrect) =>
              data.qotd.markAnswered(isCorrect, DateTime.now()),
        ),
      ),
    );
    _reload();
  }

  Future<void> _startReview(BuildContext context, _HomeData data) async {
    final study = context.read<StudyRepository>();
    final now = DateTime.now();
    final due = SrsScheduler.dueQuestions(
        study.loadRecords(), data.questions, now,
        limit: 20);
    if (due.isEmpty || !context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          questions: due,
          title: 'Spaced review',
          onAnswerLocked: _recordSrs,
        ),
      ),
    );
    _reload();
  }

  Future<void> _startQuiz(
      BuildContext context, _HomeData data, int count) async {
    final pool = data.questions
        .where((q) => _selected.contains(q.domain))
        .toList()
      ..shuffle(Random());
    final questions = pool.take(count).toList();

    // Phase 3 seam: the freemium quota check lives behind Entitlements.
    if (!await _entitlements.canStartQuiz(questions.length)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Daily free question limit reached. '
                'Unlock unlimited quizzes in Settings.')),
      );
      return;
    }

    final names = _selected.length == kDomains.length
        ? 'Mixed review'
        : _selected.map((s) => domainInfo(s).name).join(', ');
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          questions: questions,
          title: names,
          onAnswerLocked: _recordSrs,
        ),
      ),
    );
    _reload();
  }
}

class _HomeData {
  final List<Question> questions;
  final Map<String, int> counts;
  final StreakState streak;
  final int dueCount;
  final QotdController qotd;

  const _HomeData({
    required this.questions,
    required this.counts,
    required this.streak,
    required this.dueCount,
    required this.qotd,
  });
}
