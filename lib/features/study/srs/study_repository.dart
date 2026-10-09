import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/question.dart';
import '../srs/srs_record.dart';
import '../streaks/streak_logic.dart';

/// Persists per-user study state: SRS records, streak, and question-of-the-day.
///
/// Storage is SharedPreferences (JSON) in v0.2.0 — ample for thousands of
/// records. If review history ever needs querying at scale, migrate to
/// sqflite; the repository interface stays the same (see
/// docs/SPACED_REPETITION.md).
class StudyRepository {
  final SharedPreferences prefs;

  StudyRepository(this.prefs);

  static const _kRecords = 'srs_records_v1';
  static const _kStreak = 'streak_v1';
  static const _kQotdDate = 'qotd_date_v1';
  static const _kQotdCorrect = 'qotd_correct_v1';

  Map<String, SrsRecord> loadRecords() {
    final raw = prefs.getString(_kRecords);
    if (raw == null || raw.isEmpty) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return {
      for (final entry in map.entries)
        entry.key: SrsRecord.fromJson(entry.value as Map<String, dynamic>),
    };
  }

  Future<void> saveRecords(Map<String, SrsRecord> records) {
    return prefs.setString(_kRecords,
        jsonEncode({for (final e in records.entries) e.key: e.value.toJson()}));
  }

  /// Feeds one answered question into the SM-2 scheduler.
  Future<void> recordAnswer(Question question, bool correct, DateTime now) async {
    final records = loadRecords();
    final scheduler = SrsScheduler();
    records[question.qid] = scheduler.review(
      records[question.qid] ?? const SrsRecord(),
      SrsScheduler.qualityFor(correct),
      now,
    );
    await saveRecords(records);
  }

  StreakState loadStreak() {
    final raw = prefs.getString(_kStreak);
    if (raw == null || raw.isEmpty) return const StreakState();
    return StreakState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveStreak(StreakState state) =>
      prefs.setString(_kStreak, jsonEncode(state.toJson()));

  String? get qotdAnsweredDate => prefs.getString(_kQotdDate);

  bool? get qotdWasCorrect =>
      prefs.containsKey(_kQotdCorrect) ? prefs.getBool(_kQotdCorrect) : null;

  Future<void> setQotdAnswered(String dateKeyValue, bool correct) async {
    await prefs.setString(_kQotdDate, dateKeyValue);
    await prefs.setBool(_kQotdCorrect, correct);
  }
}
