import 'package:flutter_test/flutter_test.dart';
import 'package:fs_exam_app/features/study/insights/weekly_report.dart';
import 'package:fs_exam_app/features/study/study_event.dart';

StudyEvent _event({
  required String domain,
  required bool correct,
  required DateTime at,
  String sessionKind = 'quiz',
}) =>
    StudyEvent(
      qid: '${domain}_${at.millisecondsSinceEpoch}_${correct ? 1 : 0}',
      domain: domain,
      topic: 't',
      isCorrect: correct,
      quality: correct ? 4 : 2,
      confidence: 'fairlySure',
      sessionKind: sessionKind,
      answeredAtMs: at.millisecondsSinceEpoch,
    );

void main() {
  final now = DateTime(2026, 10, 9, 12);

  List<StudyEvent> journal() => [
        // 4 correct computations on Oct 8, 1 wrong on Oct 7
        ...List.generate(
            4,
            (i) => _event(
                domain: 'survey-computations',
                correct: true,
                at: DateTime(2026, 10, 8, 10, i))),
        _event(
            domain: 'survey-computations',
            correct: false,
            at: DateTime(2026, 10, 7, 10)),
        // 2 wrong boundary on Oct 6
        ...List.generate(
            2,
            (i) => _event(
                domain: 'boundary-law-and-real-property',
                correct: false,
                at: DateTime(2026, 10, 6, 10, i))),
        // stale event outside the 7-day window
        _event(
            domain: 'survey-computations',
            correct: false,
            at: DateTime(2026, 9, 1, 10)),
        // a QOTD
        _event(
            domain: 'survey-computations',
            correct: true,
            at: DateTime(2026, 10, 9, 8),
            sessionKind: 'qotd'),
      ];

  test('aggregates the 7-day window only', () {
    final report = WeeklyReport.build(journal(), now);
    expect(report.answered, 8); // 5 + 2 + 1 qotd; Sep 1 excluded
    expect(report.correct, 5);
    expect(report.accuracy, closeTo(5 / 8, 1e-9));
    expect(report.qotdAnswered, 1);
    expect(report.activeDays, 4); // Oct 6, 7, 8, 9
  });

  test('per-domain stats and weakest-first ordering', () {
    final report = WeeklyReport.build(journal(), now);
    expect(report.perDomain['boundary-law-and-real-property']!.answered, 2);
    expect(report.perDomain['survey-computations']!.answered, 6);
    final ordered = report.domainsByAccuracy;
    expect(ordered.first.domain, 'boundary-law-and-real-property');
    expect(ordered.first.accuracy, 0);
    expect(ordered.last.accuracy, closeTo(5 / 6, 1e-9));
  });

  test('empty journal yields a zero report', () {
    final report = WeeklyReport.build([], now);
    expect(report.answered, 0);
    expect(report.accuracy, 0);
    expect(report.activeDays, 0);
    expect(report.perDomain, isEmpty);
  });
}
