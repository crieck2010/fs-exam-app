import 'package:flutter_test/flutter_test.dart';
import 'package:fs_exam_app/data/models/question.dart';
import 'package:fs_exam_app/features/study/srs/confidence.dart';
import 'package:fs_exam_app/features/study/srs/srs_record.dart';
import 'package:fs_exam_app/features/study/srs/study_repository.dart';
import 'package:fs_exam_app/features/study/study_event.dart';
import 'package:shared_preferences/shared_preferences.dart';

Question _q(String qid) => Question(
      qid: qid,
      schemaVersion: 1,
      domain: 'survey-computations',
      topic: 't',
      difficulty: 1,
      stem: 'Stem $qid',
      choices: const ['a', 'b', 'c', 'd'],
      answerIndex: 0,
      explanation: 'Why.',
      parameters: const {},
      seed: 1,
    );

AnswerEvent _answer(String qid, bool correct, ConfidenceLevel confidence,
        DateTime at) =>
    AnswerEvent(
      question: _q(qid),
      isCorrect: correct,
      quality: confidence.qualityFor(correct),
      confidence: confidence,
      sessionKind: 'quiz',
      answeredAt: at,
    );

void main() {
  late StudyRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repo = StudyRepository(await SharedPreferences.getInstance());
  });

  test('recordAnswer writes journal + SRS record with graded quality',
      () async {
    final at = DateTime(2026, 10, 9, 12);
    await repo.recordAnswer(_answer('q1', true, ConfidenceLevel.knewIt, at));

    final journal = repo.loadJournal();
    expect(journal, hasLength(1));
    expect(journal.first.qid, 'q1');
    expect(journal.first.quality, 5);
    expect(journal.first.confidence, 'knewIt');

    final records = repo.loadRecords();
    expect(records['q1']!.lastQuality, 5);
    expect(records['q1']!.repetitions, 1);
  });

  test('journal prunes events older than 90 days', () async {
    final now = DateTime(2026, 10, 9, 12);
    await repo.recordAnswer(
        _answer('old', true, ConfidenceLevel.guessed, DateTime(2026, 1, 1)));
    await repo.recordAnswer(_answer('new', true, ConfidenceLevel.guessed, now));
    final journal = repo.loadJournal();
    expect(journal.map((e) => e.qid), ['new']);
  });

  test('journal round-trips through JSON', () async {
    final at = DateTime(2026, 10, 9, 12);
    await repo.recordAnswer(_answer('q1', false, ConfidenceLevel.guessed, at));
    // reload from a fresh repository instance over the same prefs
    final repo2 = StudyRepository(await SharedPreferences.getInstance());
    final journal = repo2.loadJournal();
    expect(journal, hasLength(1));
    expect(journal.first.isCorrect, isFalse);
    expect(journal.first.sessionKind, 'quiz');
    expect(journal.first.answeredAtMs, at.millisecondsSinceEpoch);
  });

  test('lifetime counter increments per answer, independent of pruning',
      () async {
    final now = DateTime(2026, 10, 9, 12);
    expect(repo.loadLifetimeAnswered(), 0);
    await repo.recordAnswer(_answer('a', true, ConfidenceLevel.guessed, now));
    await repo.recordAnswer(_answer('b', false, ConfidenceLevel.guessed, now));
    // old event gets pruned from the journal but still counted
    await repo.recordAnswer(
        _answer('c', true, ConfidenceLevel.guessed, DateTime(2026, 1, 1)));
    expect(repo.loadLifetimeAnswered(), 3);
    expect(repo.loadJournal().map((e) => e.qid), ['a', 'b']);
  });

  test('celebrated milestones persist as a set', () async {
    expect(repo.loadCelebratedMilestones(), isEmpty);
    await repo.saveCelebratedMilestones({'streak_7'});
    await repo.saveCelebratedMilestones({'streak_7', 'questions_100'});
    expect(repo.loadCelebratedMilestones(), {'streak_7', 'questions_100'});
  });

  test('exam date round-trips and clears', () async {
    expect(repo.examDateKey, isNull);
    await repo.setExamDate('2027-04-16');
    expect(repo.examDateKey, '2027-04-16');
    await repo.clearExamDate();
    expect(repo.examDateKey, isNull);
  });
}
