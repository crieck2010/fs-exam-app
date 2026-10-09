import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/monetization/monetization.dart';
import '../../data/bank_repository.dart';
import '../../data/models/question.dart';
import '../quiz/quiz_screen.dart';
import '../settings/settings_screen.dart';
import 'domain_info.dart';

/// Home screen: pick one or more FS domains, set the question count,
/// and start a quiz. The domain list is the app's "section picker" —
/// each section maps 1:1 to an engine domain slug.
class DomainPickerScreen extends StatefulWidget {
  const DomainPickerScreen({super.key});

  @override
  State<DomainPickerScreen> createState() => _DomainPickerScreenState();
}

class _DomainPickerScreenState extends State<DomainPickerScreen> {
  final _repository = BankRepository();
  final _entitlements = StubEntitlements();

  late final Future<_BankSummary> _bankFuture;
  final Set<String> _selected = {...kDomains.map((d) => d.slug)};
  int _questionCount = 20;

  @override
  void initState() {
    super.initState();
    _bankFuture = _loadSummary();
  }

  Future<_BankSummary> _loadSummary() async {
    // Load the newest bundled bank; all bundled banks share schema v1.
    final questions =
        await _repository.loadBank(BankRepository.availableBanks.last);
    final counts = <String, int>{};
    for (final q in questions) {
      counts[q.domain] = (counts[q.domain] ?? 0) + 1;
    }
    return _BankSummary(questions: questions, counts: counts);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FS Exam Prep'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: FutureBuilder<_BankSummary>(
        future: _bankFuture,
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
          return _buildPicker(context, snapshot.data!);
        },
      ),
    );
  }

  Widget _buildPicker(BuildContext context, _BankSummary summary) {
    final theme = Theme.of(context);
    final selectable = summary.counts.keys.toSet();
    final poolSize = _selected
        .where(selectable.contains)
        .fold<int>(0, (sum, slug) => sum + summary.counts[slug]!);
    final count = min(_questionCount, poolSize);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Pick your sections',
              style: theme.textTheme.headlineSmall,
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              for (final domain in kDomains)
                if (selectable.contains(domain.slug))
                  CheckboxListTile(
                    secondary: Icon(domain.icon),
                    title: Text(domain.name),
                    subtitle: Text(
                        '${domain.blurb}\n${summary.counts[domain.slug]} questions available'),
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
            ],
          ),
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
                      : () => _startQuiz(context, summary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _startQuiz(BuildContext context, _BankSummary summary) async {
    final pool = summary.questions
        .where((q) => _selected.contains(q.domain))
        .toList()
      ..shuffle(Random());
    final count = min(_questionCount, pool.length);
    final questions = pool.take(count).toList();

    // Phase 3 seam: the freemium quota check lives behind Entitlements.
    // The stub always allows; a real implementation gates here.
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizScreen(questions: questions, title: names),
      ),
    );
  }
}

class _BankSummary {
  final List<Question> questions;
  final Map<String, int> counts;

  const _BankSummary({required this.questions, required this.counts});
}
