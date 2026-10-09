import 'package:flutter/material.dart';

import '../../data/models/question.dart';
import '../domains/domain_info.dart';
import '../results/results_screen.dart';
import '../study/srs/confidence.dart';
import '../study/study_event.dart';
import 'quiz_controller.dart';

/// One question per screen: stem, four choices, confidence prompt,
/// immediate feedback with the worked explanation, then next.
/// Answers lock on first tap.
class QuizScreen extends StatefulWidget {
  final List<Question> questions;
  final String title;
  final String sessionKind;

  /// Wired by the study layer (SRS recording, QOTD, streaks, journal).
  /// Fires after confidence is submitted. Null for plain practice sessions.
  final Future<void> Function(AnswerEvent event)? onAnswerLocked;

  const QuizScreen({
    super.key,
    required this.questions,
    required this.title,
    this.sessionKind = 'quiz',
    this.onAnswerLocked,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final QuizController _controller;

  @override
  void initState() {
    super.initState();
    _controller = QuizController(
      widget.questions,
      sessionKind: widget.sessionKind,
      onAnswerLocked: widget.onAnswerLocked,
    );
    _controller.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_refresh);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final question = _controller.current;
    final info = domainInfo(question.domain);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${_controller.index + 1} / ${_controller.total}',
                style: theme.textTheme.titleMedium,
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              LinearProgressIndicator(
                value: (_controller.index + 1) / _controller.total,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  Chip(
                    avatar: Icon(info.icon, size: 18),
                    label: Text(info.name),
                  ),
                  Chip(label: Text('Difficulty ${question.difficulty}/3')),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    question.stem,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...List.generate(4, (i) => _choiceButton(context, question, i)),
              if (_controller.needsConfidence) ...[
                const SizedBox(height: 8),
                _confidenceCard(context),
              ],
              if (_controller.answered && !_controller.needsConfidence) ...[
                const SizedBox(height: 8),
                Card(
                  color: colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              question.isCorrect(_controller.selectedIndex!)
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: question.isCorrect(_controller.selectedIndex!)
                                  ? Colors.green
                                  : colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              question.isCorrect(_controller.selectedIndex!)
                                  ? 'Correct'
                                  : 'Not quite — correct answer: ${question.correctChoice}',
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(question.explanation),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  if (_controller.index > 0)
                    OutlinedButton(
                      onPressed: _controller.previous,
                      child: const Text('Back'),
                    ),
                  const Spacer(),
                  FilledButton(
                    // Next unlocks after confidence: skipping it would
                    // drop the question from SRS scheduling.
                    onPressed: _controller.answered &&
                            !_controller.needsConfidence
                        ? () {
                            if (_controller.isLast) {
                              _finish();
                            } else {
                              _controller.next();
                            }
                          }
                        : null,
                    child: Text(_controller.isLast ? 'See results' : 'Next'),
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

  /// One-tap self-report that grades the SM-2 quality of this review.
  /// The explanation reveals after this — the tap is the price of
  /// honest scheduling.
  Widget _confidenceCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How confident were you?',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            // SegmentedButton with no persistent selection: each option
            // is a one-tap submit, the Material 3 pattern for exclusive
            // choice from a small set.
            SegmentedButton<ConfidenceLevel>(
              segments: [
                for (final level in ConfidenceLevel.values)
                  ButtonSegment(
                    value: level,
                    label: Text(level.label),
                    icon: Icon(_confidenceIcon(level)),
                  ),
              ],
              selected: const <ConfidenceLevel>{},
              onSelectionChanged: (selection) =>
                  _controller.submitConfidence(selection.first),
            ),
          ],
        ),
      ),
    );
  }

  IconData _confidenceIcon(ConfidenceLevel level) {
    switch (level) {
      case ConfidenceLevel.guessed:
        return Icons.help_outline;
      case ConfidenceLevel.fairlySure:
        return Icons.thumb_up_outlined;
      case ConfidenceLevel.knewIt:
        return Icons.bolt_outlined;
    }
  }

  Widget _choiceButton(BuildContext context, Question question, int i) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final answered = _controller.answered;
    final selected = _controller.selectedIndex == i;
    final isAnswer = i == question.answerIndex;

    Color? background;
    Color? foreground;
    if (answered) {
      if (isAnswer) {
        background = Colors.green;
        foreground = Colors.white;
      } else if (selected) {
        background = colorScheme.error;
        foreground = colorScheme.onError;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: answered ? null : () => _controller.select(i),
          style: ElevatedButton.styleFrom(
            backgroundColor: background,
            foregroundColor: foreground,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            textStyle: theme.textTheme.bodyLarge,
          ),
          child: Row(
            children: [
              Text('${'ABCD'[i]}.  ',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Expanded(child: Text(question.choices[i])),
              if (answered && isAnswer)
                const Icon(Icons.check, size: 20),
              if (answered && selected && !isAnswer)
                const Icon(Icons.close, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _finish() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResultsScreen(
          records: _controller.records,
          total: _controller.total,
          title: widget.title,
          allQuestions: _controller.questions,
          onAnswerLocked: widget.onAnswerLocked,
        ),
      ),
    );
  }
}
