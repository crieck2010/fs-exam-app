import '../streaks/streak_logic.dart';
import '../study_event.dart';

/// Per-domain accuracy over the report window.
class DomainStat {
  final String domain;
  final int answered;
  final int correct;

  const DomainStat({
    required this.domain,
    required this.answered,
    required this.correct,
  });

  double get accuracy => answered == 0 ? 0 : correct / answered;
}

/// A week-in-review, built purely from the answer journal.
/// Pure Dart — no Flutter imports.
class WeeklyReport {
  final DateTime weekStart;
  final int answered;
  final int correct;
  final int activeDays;
  final int qotdAnswered;
  final Map<String, DomainStat> perDomain;

  const WeeklyReport({
    required this.weekStart,
    required this.answered,
    required this.correct,
    required this.activeDays,
    required this.qotdAnswered,
    required this.perDomain,
  });

  double get accuracy => answered == 0 ? 0 : correct / answered;

  /// Domains sorted by accuracy ascending (weakest first) — the natural
  /// reading order for a study report.
  List<DomainStat> get domainsByAccuracy {
    final list = perDomain.values.toList();
    list.sort((a, b) => a.accuracy.compareTo(b.accuracy));
    return list;
  }

  factory WeeklyReport.build(
    List<StudyEvent> journal,
    DateTime now, {
    int windowDays = 7,
  }) {
    final cutoffMs =
        now.subtract(Duration(days: windowDays)).millisecondsSinceEpoch;
    final events =
        journal.where((e) => e.answeredAtMs >= cutoffMs).toList();

    final perDomain = <String, DomainStat>{};
    final days = <String>{};
    var correct = 0;
    var qotd = 0;
    for (final e in events) {
      if (e.isCorrect) correct++;
      if (e.sessionKind == 'qotd') qotd++;
      days.add(dateKey(e.answeredAt));
      final stat = perDomain[e.domain];
      perDomain[e.domain] = DomainStat(
        domain: e.domain,
        answered: (stat?.answered ?? 0) + 1,
        correct: (stat?.correct ?? 0) + (e.isCorrect ? 1 : 0),
      );
    }

    return WeeklyReport(
      weekStart: DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: windowDays)),
      answered: events.length,
      correct: correct,
      activeDays: days.length,
      qotdAnswered: qotd,
      perDomain: perDomain,
    );
  }
}
