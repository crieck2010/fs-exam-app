import '../../../data/models/question.dart';

/// Spaced-repetition state per question, implementing the SM-2 algorithm
/// (SuperMemo 2).
///
/// Pure Dart — zero Flutter imports — so the scheduling math is unit-testable
/// in isolation, mirroring the engine-first split of the program: this is
/// the "scheduling engine", the widgets are the thin UI.
class SrsRecord {
  /// Easiness factor, starts at 2.5, never below 1.3.
  final double ef;

  /// Current interval in days.
  final int intervalDays;

  /// Consecutive successful reviews.
  final int repetitions;

  /// Epoch ms (local midnight) when the item becomes due; null = new.
  final int? nextDueEpochMs;

  /// Last SM-2 quality (0-5), if reviewed.
  final int? lastQuality;

  const SrsRecord({
    this.ef = 2.5,
    this.intervalDays = 0,
    this.repetitions = 0,
    this.nextDueEpochMs,
    this.lastQuality,
  });

  bool get isNew => nextDueEpochMs == null;

  bool isDue(DateTime now) =>
      nextDueEpochMs == null || nextDueEpochMs! <= now.millisecondsSinceEpoch;

  Map<String, dynamic> toJson() => {
        'ef': ef,
        'intervalDays': intervalDays,
        'repetitions': repetitions,
        'nextDueEpochMs': nextDueEpochMs,
        'lastQuality': lastQuality,
      };

  factory SrsRecord.fromJson(Map<String, dynamic> json) => SrsRecord(
        ef: (json['ef'] as num).toDouble(),
        intervalDays: json['intervalDays'] as int,
        repetitions: json['repetitions'] as int,
        nextDueEpochMs: json['nextDueEpochMs'] as int?,
        lastQuality: json['lastQuality'] as int?,
      );
}

/// The SM-2 scheduling engine.
class SrsScheduler {
  static const double initialEf = 2.5;
  static const double minEf = 1.3;

  /// Applies one SM-2 review. [quality] is 0-5.
  SrsRecord review(SrsRecord record, int quality, DateTime now) {
    assert(quality >= 0 && quality <= 5, 'quality must be 0-5');

    var ef = record.ef +
        (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    if (ef < minEf) ef = minEf;

    final int repetitions;
    final int intervalDays;
    if (quality < 3) {
      // Forgotten: restart the interval ladder.
      repetitions = 0;
      intervalDays = 1;
    } else {
      repetitions = record.repetitions + 1;
      if (repetitions == 1) {
        intervalDays = 1;
      } else if (repetitions == 2) {
        intervalDays = 6;
      } else {
        intervalDays = (record.intervalDays * ef).round();
      }
    }

    final today = DateTime(now.year, now.month, now.day);
    final nextDue = today.add(Duration(days: intervalDays));
    return SrsRecord(
      ef: double.parse(ef.toStringAsFixed(4)),
      intervalDays: intervalDays,
      repetitions: repetitions,
      nextDueEpochMs: nextDue.millisecondsSinceEpoch,
      lastQuality: quality,
    );
  }

  /// v0.2.0 quality mapping for multiple-choice: we only observe
  /// correct/incorrect. Correct = 4 (good recall), incorrect = 2 (fail,
  /// restarts the ladder). A future version may add a confidence prompt
  /// to reach the full 0-5 range.
  static int qualityFor(bool correct) => correct ? 4 : 2;

  /// Returns due questions, most overdue first, capped at [limit].
  /// Previously reviewed items come before never-seen ones: the queue
  /// first reinforces what is slipping, then introduces new material.
  static List<Question> dueQuestions(
    Map<String, SrsRecord> records,
    List<Question> bank,
    DateTime now, {
    int limit = 20,
  }) {
    final nowMs = now.millisecondsSinceEpoch;
    final due = bank.where((q) {
      final record = records[q.qid];
      return record == null || record.nextDueEpochMs == null ||
          record.nextDueEpochMs! <= nowMs;
    }).toList();
    due.sort((a, b) {
      // Never-reviewed sorts after everything with a real due date.
      final ra = records[a.qid]?.nextDueEpochMs ?? (1 << 62);
      final rb = records[b.qid]?.nextDueEpochMs ?? (1 << 62);
      return ra.compareTo(rb);
    });
    return due.take(limit).toList();
  }
}
