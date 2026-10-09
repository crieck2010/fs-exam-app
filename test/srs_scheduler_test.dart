import 'package:flutter_test/flutter_test.dart';
import 'package:fs_exam_app/features/study/srs/srs_record.dart';

void main() {
  final scheduler = SrsScheduler();
  final now = DateTime(2026, 10, 9, 12);

  test('first correct review: interval 1, EF unchanged', () {
    final r = scheduler.review(const SrsRecord(), 4, now);
    expect(r.repetitions, 1);
    expect(r.intervalDays, 1);
    expect(r.ef, 2.5);
    expect(r.nextDueEpochMs,
        DateTime(2026, 10, 10).millisecondsSinceEpoch);
  });

  test('second correct review: interval 6', () {
    var r = scheduler.review(const SrsRecord(), 4, now);
    r = scheduler.review(r, 4, now);
    expect(r.repetitions, 2);
    expect(r.intervalDays, 6);
  });

  test('third correct review: interval = round(6 * EF)', () {
    var r = scheduler.review(const SrsRecord(), 4, now);
    r = scheduler.review(r, 4, now);
    r = scheduler.review(r, 4, now);
    expect(r.repetitions, 3);
    expect(r.intervalDays, 15); // round(6 * 2.5)
  });

  test('incorrect review restarts the ladder and lowers EF', () {
    var r = scheduler.review(const SrsRecord(), 4, now);
    r = scheduler.review(r, 4, now);
    r = scheduler.review(r, 2, now);
    expect(r.repetitions, 0);
    expect(r.intervalDays, 1);
    // 2.5 + (0.1 - 3 * (0.08 + 3 * 0.02)) = 2.18
    expect(r.ef, closeTo(2.18, 1e-9));
  });

  test('EF never drops below 1.3', () {
    var r = const SrsRecord();
    for (var i = 0; i < 10; i++) {
      r = scheduler.review(r, 0, now);
    }
    expect(r.ef, 1.3);
  });

  test('quality mapping: correct -> 4, incorrect -> 2', () {
    expect(SrsScheduler.qualityFor(true), 4);
    expect(SrsScheduler.qualityFor(false), 2);
  });

  test('new records are due; reviewed records respect nextDue', () {
    expect(const SrsRecord().isDue(now), isTrue);
    final reviewed = scheduler.review(const SrsRecord(), 4, now);
    // due tomorrow -> not due now
    expect(reviewed.isDue(now), isFalse);
    // due when we pass the due date
    expect(reviewed.isDue(DateTime(2026, 10, 11)), isTrue);
  });

  test('record survives a JSON round trip', () {
    final r = scheduler.review(const SrsRecord(), 4, now);
    final back = SrsRecord.fromJson(r.toJson());
    expect(back.ef, r.ef);
    expect(back.intervalDays, r.intervalDays);
    expect(back.repetitions, r.repetitions);
    expect(back.nextDueEpochMs, r.nextDueEpochMs);
    expect(back.lastQuality, r.lastQuality);
  });
}
