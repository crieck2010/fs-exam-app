import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/question.dart';
import '../study/srs/confidence.dart';
import '../study/study_event.dart';

/// Per-question answer state for the results screen.
class AnswerRecord {
  final Question question;
  final int selectedIndex;

  const AnswerRecord({required this.question, required this.selectedIndex});

  bool get isCorrect => question.isCorrect(selectedIndex);
}

/// Owns quiz session state: current position, locked-in answers, scoring.
///
/// Flow per question: select -> confidence prompt -> explanation.
/// Answers lock on first tap (exam discipline); the confidence-graded
/// quality feeds the SRS scheduler; the explanation is the study rep.
///
/// [onAnswerLocked] fires once per question, after confidence is submitted.
/// The controller stays persistence-agnostic — the study layer wires the
/// hook.
class QuizController extends ChangeNotifier {
  final List<Question> questions;

  /// Where this session came from: 'quiz' | 'qotd' | 'review' | 'drill' | 'retake'.
  final String sessionKind;

  /// Called exactly once per question, after confidence is submitted.
  final Future<void> Function(AnswerEvent event)? onAnswerLocked;

  int _index = 0;
  final Map<String, int> _answers = {};
  final Set<String> _awaitingConfidence = {};

  QuizController(
    this.questions, {
    this.sessionKind = 'quiz',
    this.onAnswerLocked,
  }) : assert(questions.isNotEmpty);

  int get index => _index;
  int get total => questions.length;
  Question get current => questions[_index];
  bool get isLast => _index == questions.length - 1;

  bool get answered => _answers.containsKey(current.qid);
  int? get selectedIndex => _answers[current.qid];

  /// True when the current question is answered but confidence hasn't
  /// been submitted yet.
  bool get needsConfidence => _awaitingConfidence.contains(current.qid);

  /// Locks in an answer. Ignored if the question was already answered.
  /// The study hook fires later, in [submitConfidence].
  void select(int choiceIndex) {
    if (answered) return;
    final question = current;
    _answers[question.qid] = choiceIndex;
    _awaitingConfidence.add(question.qid);
    notifyListeners();
  }

  /// Submits self-reported confidence, computes SM-2 quality, and fires
  /// the study hook. Ignored if this question isn't awaiting confidence.
  void submitConfidence(ConfidenceLevel level) {
    final question = current;
    if (!_awaitingConfidence.remove(question.qid)) return;
    final selected = _answers[question.qid]!;
    final correct = question.isCorrect(selected);
    notifyListeners();
    final hook = onAnswerLocked;
    if (hook != null) {
      // Fire-and-forget: study persistence must never block the UI.
      unawaited(hook(AnswerEvent(
        question: question,
        isCorrect: correct,
        quality: level.qualityFor(correct),
        confidence: level,
        sessionKind: sessionKind,
        answeredAt: DateTime.now(),
      )));
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

  double get scoreFraction => total == 0 ? 0 : correctCount / total;

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
