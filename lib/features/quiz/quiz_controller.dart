import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/question.dart';

/// Per-question answer state for the results screen.
class AnswerRecord {
  final Question question;
  final int selectedIndex;

  const AnswerRecord({required this.question, required this.selectedIndex});

  bool get isCorrect => question.isCorrect(selectedIndex);
}

/// Owns quiz session state: current position, locked-in answers, scoring.
///
/// Answers lock on first tap (exam discipline); the explanation is revealed
/// immediately so every question is a study rep, not just a test.
class QuizController extends ChangeNotifier {
  final List<Question> questions;

  /// Called exactly once per question when an answer locks in. The study
  /// layer wires this to SRS recording / QOTD / streaks; the controller
  /// itself stays persistence-agnostic.
  final Future<void> Function(Question question, bool isCorrect)? onAnswerLocked;

  int _index = 0;
  final Map<String, int> _answers = {};

  QuizController(this.questions, {this.onAnswerLocked})
      : assert(questions.isNotEmpty);

  int get index => _index;
  int get total => questions.length;
  Question get current => questions[_index];
  bool get isLast => _index == questions.length - 1;

  bool get answered => _answers.containsKey(current.qid);
  int? get selectedIndex => _answers[current.qid];

  /// Locks in an answer. Ignored if the question was already answered.
  void select(int choiceIndex) {
    if (answered) return;
    final question = current;
    _answers[question.qid] = choiceIndex;
    notifyListeners();
    // Fire-and-forget: study persistence must never block the UI.
    final hook = onAnswerLocked;
    if (hook != null) {
      unawaited(hook(question, question.isCorrect(choiceIndex)));
    }
  }

  void next() {
    if (_index < questions.length - 1) {
      _index++;
      notifyListeners();
    }
  }

  void previous() {
    if (_index > 0) {
      _index--;
      notifyListeners();
    }
  }

  int get answeredCount => _answers.length;

  int get correctCount => questions
      .where((q) => _answers[q.qid] != null && q.isCorrect(_answers[q.qid]!))
      .length;

  double get scoreFraction =>
      total == 0 ? 0 : correctCount / total;

  List<AnswerRecord> get records => questions
      .where((q) => _answers.containsKey(q.qid))
      .map((q) => AnswerRecord(question: q, selectedIndex: _answers[q.qid]!))
      .toList();

  List<Question> get missed => records
      .where((r) => !r.isCorrect)
      .map((r) => r.question)
      .toList();

  /// Per-domain {correct, total} for the results breakdown.
  Map<String, List<int>> domainBreakdown() {
    final map = <String, List<int>>{};
    for (final q in questions) {
      final entry = map.putIfAbsent(q.domain, () => [0, 0]);
      entry[1]++;
      final sel = _answers[q.qid];
      if (sel != null && q.isCorrect(sel)) entry[0]++;
    }
    return map;
  }
}
