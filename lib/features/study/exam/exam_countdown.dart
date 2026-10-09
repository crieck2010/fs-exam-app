/// Exam countdown: days until the user's exam date, with a study phase.
/// Pure Dart — no Flutter imports.
///
/// The exam date is stored as a 'yyyy-MM-dd' key (see `dateKey`).
enum ExamPhase {
  /// More than 90 days out.
  distant,

  /// 31–90 days: build volume.
  building,

  /// 8–30 days: focus areas over strengths.
  focused,

  /// 1–7 days: light review, trust the system.
  finalWeek,

  /// Today.
  examDay,

  /// The date has passed.
  passed,
}

class ExamCountdown {
  /// Negative when the exam date has passed.
  final int daysUntil;
  final ExamPhase phase;

  const ExamCountdown({required this.daysUntil, required this.phase});

  String get headline {
    switch (phase) {
      case ExamPhase.examDay:
        return 'Exam day is today';
      case ExamPhase.passed:
        return 'Exam date passed';
      default:
        return '$daysUntil day${daysUntil == 1 ? '' : 's'} to exam day';
    }
  }

  String get advice {
    switch (phase) {
      case ExamPhase.distant:
        return 'Plenty of runway. Build the daily habit — streaks compound.';
      case ExamPhase.building:
        return 'Steady daily reps. Let spaced repetition do the heavy lifting.';
      case ExamPhase.focused:
        return 'Under a month out — drill your focus areas, not your strengths.';
      case ExamPhase.finalWeek:
        return 'Light review only this week. Trust the system you built.';
      case ExamPhase.examDay:
        return "You've done the work. Breathe, read carefully, good luck.";
      case ExamPhase.passed:
        return 'Set your next exam date, or clear it to hide the countdown.';
    }
  }

  /// The exam crunch zone where weak-area pings activate.
  bool get isCrunch => phase == ExamPhase.focused || phase == ExamPhase.finalWeek;

  factory ExamCountdown.fromDateKey(String dateKeyValue, DateTime now) {
    final parts = dateKeyValue.split('-').map(int.parse).toList();
    final exam = DateTime(parts[0], parts[1], parts[2]);
    final today = DateTime(now.year, now.month, now.day);
    final daysUntil = exam.difference(today).inDays;

    final ExamPhase phase;
    if (daysUntil < 0) {
      phase = ExamPhase.passed;
    } else if (daysUntil == 0) {
      phase = ExamPhase.examDay;
    } else if (daysUntil <= 7) {
      phase = ExamPhase.finalWeek;
    } else if (daysUntil <= 30) {
      phase = ExamPhase.focused;
    } else if (daysUntil <= 90) {
      phase = ExamPhase.building;
    } else {
      phase = ExamPhase.distant;
    }
    return ExamCountdown(daysUntil: daysUntil, phase: phase);
  }
}
