import 'package:flutter_test/flutter_test.dart';
import 'package:fs_exam_app/data/models/question.dart';
import 'package:fs_exam_app/features/study/insights/insights.dart';
import 'package:fs_exam_app/features/study/study_event.dart';

StudyEvent _event({
  required String qid,
  required String domain,
  required bool correct,
  required DateTime at,
}) =>
    StudyEvent(
      qid: qid,
      domain: domain,
      topic: 't',
      isCorrect: correct,
      quality: correct ? 4 : 2,
      confidence: 'fairlySure',
      sessionKind: 'quiz',
      answeredAtMs: at.millisecondsSinceEpoch,
    );

Question _q(String qid, String domain) => Question(
      qid: qid,
      schemaVersion: 1,
      domain: domain,
      topic: 't',
      difficulty: 1,
      stem: 'Stem $qid',
      choices: const ['a', 'b', 'c', 'd'],
      answerIndex: 0,
      explanation: 'Why.',
      parameters: const {},
      seed: 1,
    );

void main() {
  final now = DateTime(2026, 10, 9, 12);
  const weak = 'boundary-law-and-real-property';
  const strong = 'survey-computations';
  const thin = 'applied-math-statistics'; // only 2 attempts: must not qualify

  List<StudyEvent> journal() => [
        // weak: 2/6
        ...List.generate(
            6,
            (i) => _event(
                qid: 'w$i',
                domain: weak,
                correct: i < 2,
                at: DateTime(2026, 10, 8, 10, i))),
        // strong: 9/10
        ...List.generate(
            10,
            (i) => _event(
                qid: 's$i',
                domain: strong,
                correct: i < 9,
                at: DateTime(2026, 10, 8, 11, i))),
        // thin: 0/2 — below minAttempts
        ...List.generate(
            2,
            (i) => _event(
                qid: 't$i',
                domain: thin,
                correct: false,
                at: DateTime(2026, 10, 8, 12, i))),
      ];

  test('focus = weakest qualifying, strengths = strongest qualifying', () {
    final insights = Insights.build(journal(), now);
    expect(insights.focus.map((i) => i.domain), [weak, strong]);
    expect(insights.strengths.map((i) => i.domain), [strong, weak]);
    expect(insights.all.map((i) => i.domain),
        containsAll([weak, strong]));
    expect(insights.all.map((i) => i.domain), isNot(contains(thin)));
  });

  test('minAttempts gate: nothing qualifies, lists are empty', () {
    final insights = Insights.build(journal(), now, minAttempts: 50);
    expect(insights.focus, isEmpty);
    expect(insights.strengths, isEmpty);
  });

  test('drillQuestions: failed first (recent first), then unseen', () {
    final bank = [
      ...List.generate(4, (i) => _q('w$i', weak)), // w0,w1 correct; w2,w3 wrong
      _q('w_new', weak), // unseen
      _q('s0', strong),
    ];
    // journal has w0..w5 events; bank only has w0-w3 + w_new
    final drill = Insights.drillQuestions(
      domain: weak,
      bank: bank,
      journal: journal(),
      limit: 10,
    );
    final ids = drill.map((q) => q.qid).toList();
    // failed w3 (10:03) before w2 (10:02); w0,w1 excluded (correct last);
    // w_new fills after.
    expect(ids, ['w3', 'w2', 'w_new']);
    expect(ids, isNot(contains('s0')));
  });

  test('drillQuestions respects the limit', () {
    final bank = List.generate(30, (i) => _q('n$i', weak));
    final drill = Insights.drillQuestions(
      domain: weak,
      bank: bank,
      journal: journal(),
      limit: 5,
    );
    expect(drill, hasLength(5));
  });
}
