import 'package:flutter_test/flutter_test.dart';
import 'package:fs_exam_app/data/bank_repository.dart';
import 'package:fs_exam_app/data/models/question.dart';

Map<String, dynamic> questionJson(String qid, int answerIndex) => {
      'qid': qid,
      'schema_version': 1,
      'domain': 'survey-computations',
      'topic': 'inverse',
      'difficulty': 1,
      'stem': 'Stem $qid',
      'choices': ['a', 'b', 'c', 'd'],
      'answer_index': answerIndex,
      'explanation': 'Why.',
      'parameters': {},
      'seed': 1,
    };

Map<String, dynamic> bankJson(List<Map<String, dynamic>> questions) => {
      'schema_version': 1,
      'generator': 'fs-exam-prep',
      'engine_version': '1.0.0',
      'question_count': questions.length,
      'questions': questions,
    };

void main() {
  test('parses a valid bank', () {
    final bank = parseBank(bankJson([
      questionJson('aaa', 0),
      questionJson('bbb', 2),
    ]));
    expect(bank, hasLength(2));
    expect(bank[1].correctChoice, 'c');
  });

  test('rejects question_count mismatch', () {
    final payload = bankJson([questionJson('aaa', 0)]);
    payload['question_count'] = 99;
    expect(() => parseBank(payload), throwsA(isA<BankFormatException>()));
  });

  test('rejects duplicate qids', () {
    final payload = bankJson([questionJson('aaa', 0), questionJson('aaa', 1)]);
    expect(() => parseBank(payload), throwsA(isA<BankFormatException>()));
  });

  test('rejects non-v1 bank schema_version', () {
    final payload = bankJson([questionJson('aaa', 0)]);
    payload['schema_version'] = 2;
    expect(() => parseBank(payload), throwsA(isA<BankFormatException>()));
  });

  test('rejects missing top-level field', () {
    final payload = bankJson([questionJson('aaa', 0)]);
    payload.remove('questions');
    expect(() => parseBank(payload), throwsA(isA<BankFormatException>()));
  });
}
