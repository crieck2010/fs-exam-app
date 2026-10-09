import 'package:flutter_test/flutter_test.dart';
import 'package:fs_exam_app/features/study/exam/exam_countdown.dart';

void main() {
  final now = DateTime(2026, 10, 9, 12);

  ExamCountdown at(int year, int month, int day) =>
      ExamCountdown.fromDateKey(
          '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}',
          now);

  test('phase boundaries', () {
    expect(at(2027, 2, 1).phase, ExamPhase.distant); // 115 days
    expect(at(2026, 12, 9).phase, ExamPhase.building); // 61 days
    expect(at(2026, 11, 9).phase, ExamPhase.building); // 31 days
    expect(at(2026, 11, 8).phase, ExamPhase.focused); // 30 days
    expect(at(2026, 10, 17).phase, ExamPhase.focused); // 8 days
    expect(at(2026, 10, 16).phase, ExamPhase.finalWeek); // 7 days
    expect(at(2026, 10, 10).phase, ExamPhase.finalWeek); // 1 day
    expect(at(2026, 10, 9).phase, ExamPhase.examDay); // today
    expect(at(2026, 10, 8).phase, ExamPhase.passed); // yesterday
  });

  test('daysUntil counts calendar days', () {
    expect(at(2026, 10, 9).daysUntil, 0);
    expect(at(2026, 10, 16).daysUntil, 7);
    expect(at(2026, 10, 8).daysUntil, -1);
  });

  test('headlines read naturally', () {
    expect(at(2026, 10, 16).headline, '7 days to exam day');
    expect(at(2026, 10, 10).headline, '1 day to exam day');
    expect(at(2026, 10, 9).headline, 'Exam day is today');
    expect(at(2026, 10, 8).headline, 'Exam date passed');
  });

  test('crunch zone is the focused + final week phases', () {
    expect(at(2026, 11, 8).isCrunch, isTrue); // 30d
    expect(at(2026, 10, 10).isCrunch, isTrue); // 1d
    expect(at(2026, 11, 9).isCrunch, isFalse); // 31d
    expect(at(2026, 10, 9).isCrunch, isFalse); // exam day itself
  });

  test('every phase has advice', () {
    for (final phase in ExamPhase.values) {
      final cd = ExamCountdown(daysUntil: 0, phase: phase);
      expect(cd.advice, isNotEmpty);
      expect(cd.headline, isNotEmpty);
    }
  });
}
