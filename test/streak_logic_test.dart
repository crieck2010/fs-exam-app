import 'package:flutter_test/flutter_test.dart';
import 'package:fs_exam_app/features/study/streaks/streak_logic.dart';

void main() {
  test('first day starts a streak of 1', () {
    final s = recordStreakDay(const StreakState(), DateTime(2026, 10, 9));
    expect(s.count, 1);
    expect(s.best, 1);
    expect(s.lastDate, '2026-10-09');
  });

  test('same day is idempotent', () {
    var s = recordStreakDay(const StreakState(), DateTime(2026, 10, 9));
    s = recordStreakDay(s, DateTime(2026, 10, 9, 23, 59));
    expect(s.count, 1);
    expect(s.best, 1);
  });

  test('consecutive day extends the streak', () {
    var s = recordStreakDay(const StreakState(), DateTime(2026, 10, 9));
    s = recordStreakDay(s, DateTime(2026, 10, 10));
    s = recordStreakDay(s, DateTime(2026, 10, 11));
    expect(s.count, 3);
    expect(s.best, 3);
  });

  test('a missed day restarts at 1 but keeps best', () {
    var s = recordStreakDay(const StreakState(), DateTime(2026, 10, 9));
    s = recordStreakDay(s, DateTime(2026, 10, 10));
    s = recordStreakDay(s, DateTime(2026, 10, 12)); // skipped the 11th
    expect(s.count, 1);
    expect(s.best, 2);
  });

  test('state survives a JSON round trip', () {
    final s = recordStreakDay(const StreakState(), DateTime(2026, 10, 9));
    final back = StreakState.fromJson(s.toJson());
    expect(back.count, s.count);
    expect(back.best, s.best);
    expect(back.lastDate, s.lastDate);
  });

  test('dateKey formats local dates', () {
    expect(dateKey(DateTime(2026, 1, 5)), '2026-01-05');
  });
}
