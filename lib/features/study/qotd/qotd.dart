import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../data/models/question.dart';
import '../srs/study_repository.dart';
import '../streaks/streak_logic.dart';

/// Deterministic daily question: every user with the same bank gets the same
/// question on the same calendar day (local time). The seed is the day count,
/// so the question changes at local midnight.
Question questionOfTheDay(List<Question> bank, DateTime date) {
  assert(bank.isNotEmpty, 'bank must not be empty');
  final day = DateTime(date.year, date.month, date.day);
  final dayNumber = day.difference(DateTime(2020, 1, 1)).inDays;
  return bank[Random(dayNumber).nextInt(bank.length)];
}

/// Owns today's question, its answered state, and the streak update that
/// answering it triggers.
class QotdController extends ChangeNotifier {
  final StudyRepository _repo;
  final List<Question> _bank;

  late final String todayKey;
  late final Question today;
  bool _answered = false;
  bool? _wasCorrect;

  QotdController({
    required StudyRepository repo,
    required List<Question> bank,
    required DateTime now,
  })  : _repo = repo,
        _bank = bank {
    todayKey = dateKey(now);
    today = questionOfTheDay(bank, now);
    _answered = _repo.qotdAnsweredDate == todayKey;
    _wasCorrect = _repo.qotdWasCorrect;
  }

  bool get answered => _answered;
  bool? get wasCorrect => _wasCorrect;

  /// Locks in today's answer: persists QOTD state, extends the streak,
  /// and feeds the question to the SRS scheduler. Idempotent per day.
  Future<void> markAnswered(bool correct, DateTime now) async {
    if (_answered) return;
    _answered = true;
    _wasCorrect = correct;
    await _repo.setQotdAnswered(todayKey, correct);
    await _repo.saveStreak(recordStreakDay(_repo.loadStreak(), now));
    await _repo.recordAnswer(today, correct, now);
    notifyListeners();
  }
}
