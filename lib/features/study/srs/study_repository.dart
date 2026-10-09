import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../study_event.dart';
import 'srs/srs_record.dart';
import 'streaks/streak_logic.dart';

/// Persists per-user study state: SRS records, answer journal, streak,
/// and question-of-the-day.
///
/// Storage is SharedPreferences (JSON) in v0.3.0 — ample for thousands of
/// records. If review history ever needs querying at scale, migrate to
/// sqflite; the repository interface stays the same (see
/// docs/SPACED_REPETITION.md).
class StudyRepository {
  final SharedPreferences prefs;

  StudyRepository(this.prefs);

  static const _kRecords = 'srs_records_v1';
  static const _kJournal = 'answer_journal_v1';
  static const _kStreak = 'streak_v1';
  static const _kQotdDate = 'qotd_date_v1';
  static const _kQotdCorrect = 'qotd_correct_v1';
  static const _kLifetime = 'lifetime_answered_v1';
  static const _kCelebrated = 'celebrated_milestones_v1';
  static const _kExamDate = 'exam_date_v1';
  static const _kWeakPingDismissed = 'weak_ping_dismissed_v1';

  /// Journal retention: 90 days, max 5000 events. The weekly report and
  /// insights only ever look back 30 days, so this is generous headroom.
  static const _kJournalMaxDays = 90;
  static const _kJournalCap = 5000;

  // ---- SRS records ----

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

  // ---- Answer journal (append-only, pruned) ----

  List<StudyEvent> loadJournal() {
    final raw = prefs.getString(_kJournal);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return [
      for (final item in list)
        StudyEvent.fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<void> _saveJournal(List<StudyEvent> events) {
    return prefs.setString(
        _kJournal, jsonEncode([for (final e in events) e.toJson()]));
  }

  /// Records one answered question: appends to the journal (pruned),
  /// feeds the confidence-graded quality into the SM-2 scheduler, and
  /// bumps the lifetime answer counter (the journal is pruned, so the
  /// lifetime count lives separately).
  Future<void> recordAnswer(AnswerEvent event) async {
    final journal = loadJournal()..add(event.toStudyEvent());
    final cutoff = DateTime.now()
        .subtract(const Duration(days: _kJournalMaxDays))
        .millisecondsSinceEpoch;
    final pruned =
        journal.where((e) => e.answeredAtMs >= cutoff).toList();
    final capped = pruned.length > _kJournalCap
        ? pruned.sublist(pruned.length - _kJournalCap)
        : pruned;
    await _saveJournal(capped);
    await prefs.setInt(_kLifetime, loadLifetimeAnswered() + 1);

    final records = loadRecords();
    records[event.question.qid] = SrsScheduler().review(
      records[event.question.qid] ?? const SrsRecord(),
      event.quality,
      event.answeredAt,
    );
    await saveRecords(records);
  }

  // ---- Lifetime + milestones ----

  int loadLifetimeAnswered() => prefs.getInt(_kLifetime) ?? 0;

  Set<String> loadCelebratedMilestones() =>
      prefs.getStringList(_kCelebrated)?.toSet() ?? {};

  Future<void> saveCelebratedMilestones(Set<String> ids) =>
      prefs.setStringList(_kCelebrated, ids.toList());

  // ---- Exam date ----

  /// 'yyyy-MM-dd' local, or null when not set.
  String? get examDateKey => prefs.getString(_kExamDate);

  Future<void> setExamDate(String dateKeyValue) =>
      prefs.setString(_kExamDate, dateKeyValue);

  Future<void> clearExamDate() => prefs.remove(_kExamDate);

  /// 'yyyy-MM-dd' of the last day the weak-area ping was dismissed.
  String? get weakPingDismissedDate => prefs.getString(_kWeakPingDismissed);

  Future<void> setWeakPingDismissed(String dateKeyValue) =>
      prefs.setString(_kWeakPingDismissed, dateKeyValue);

  // ---- Streak ----

  StreakState loadStreak() {
    final raw = prefs.getString(_kStreak);
    if (raw == null || raw.isEmpty) return const StreakState();
    return StreakState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveStreak(StreakState state) =>
      prefs.setString(_kStreak, jsonEncode(state.toJson()));

  // ---- Question of the day ----

  String? get qotdAnsweredDate => prefs.getString(_kQotdDate);

  bool? get qotdWasCorrect =>
      prefs.containsKey(_kQotdCorrect) ? prefs.getBool(_kQotdCorrect) : null;

  Future<void> setQotdAnswered(String dateKeyValue, bool correct) async {
    await prefs.setString(_kQotdDate, dateKeyValue);
    await prefs.setBool(_kQotdCorrect, correct);
  }
}
