import 'package:flutter_test/flutter_test.dart';
import 'package:fs_exam_app/data/models/question.dart';
import 'package:fs_exam_app/features/study/qotd/qotd.dart';
import 'package:fs_exam_app/features/study/srs/srs_record.dart';

Question _q(String qid) => Question(
      qid: qid,
      schemaVersion: 1,
      domain: 'survey-computations',
      topic: 'inverse',
      difficulty: 1,
      stem: 'Stem $qid',
      choices: const ['a', 'b', 'c', 'd'],
      answerIndex: 0,
      explanation: 'Why.',
      parameters: const {},
      seed: 1,
    );

void main() {
  final bank = List.generate(50, (i) => _q('q$i'));

  test('same date always yields the same question', () {
    final date = DateTime(2026, 10, 9, 8, 30);
    final a = questionOfTheDay(bank, date);
    final b = questionOfTheDay(bank, DateTime(2026, 10, 9, 23, 59));
    expect(a.qid, b.qid);
  });

  test('the question changes from one day to the next (over a week)', () {
    final seen = <String>{};
    for (var d = 0; d < 7; d++) {
      seen.add(questionOfTheDay(bank, DateTime(2026, 10, 9 + d)).qid);
    }
    expect(seen.length, greaterThan(1));
  });

  test('dueQuestions excludes questions not yet due', () {
    final now = DateTime(2026, 10, 9, 12);
    final scheduler = SrsScheduler();
    // q0 reviewed and not due until far future; q1..q3 new.
    final records = {
      'q0': scheduler.review(const SrsRecord(), 4, now),
    };
    final due = SrsScheduler.dueQuestions(records, bank, now, limit: 3);
    expect(due, hasLength(3));
    expect(due.any((q) => q.qid == 'q0'), isFalse);
  });

  test('overdue reviews sort before never-seen questions', () {
    final now = DateTime(2026, 10, 9, 12);
    final scheduler = SrsScheduler();
    final old = scheduler.review(const SrsRecord(), 4, DateTime(2026, 9, 1));
    final records = {'q5': old}; // due 2026-09-02, long overdue
    final due = SrsScheduler.dueQuestions(records, bank, now, limit: 50);
    expect(due.first.qid, 'q5');
    // never-seen questions come after all reviewed-due ones
    final firstNew = due.indexWhere((q) => q.qid != 'q5');
    expect(due.sublist(firstNew).every((q) => q.qid != 'q5'), isTrue);
  });
}
