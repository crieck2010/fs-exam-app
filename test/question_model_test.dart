import 'package:flutter_test/flutter_test.dart';
import 'package:fs_exam_app/data/models/question.dart';

Map<String, dynamic> validQuestionJson() => {
      'qid': 'abc123def456',
      'schema_version': 1,
      'domain': 'survey-computations',
      'topic': 'inverse',
      'difficulty': 2,
      'stem': 'What is the azimuth?',
      'choices': ['10\u00b0', '20\u00b0', '30\u00b0', '40\u00b0'],
      'answer_index': 1,
      'explanation': 'Because.',
      'parameters': {'a': 1},
      'seed': 42,
    };

void main() {
  test('parses a valid v1 question', () {
    final q = Question.fromJson(validQuestionJson());
    expect(q.qid, 'abc123def456');
    expect(q.correctChoice, '20\u00b0');
    expect(q.isCorrect(1), isTrue);
    expect(q.isCorrect(0), isFalse);
  });

  test('rejects a missing field', () {
    final json = validQuestionJson()..remove('explanation');
    expect(() => Question.fromJson(json), throwsA(isA<BankFormatException>()));
  });

  test('rejects duplicate choices', () {
    final json = validQuestionJson()
      ..['choices'] = ['10\u00b0', '20\u00b0', '20\u00b0', '40\u00b0'];
    expect(() => Question.fromJson(json), throwsA(isA<BankFormatException>()));
  });

  test('rejects wrong choice count', () {
    final json = validQuestionJson()
      ..['choices'] = ['10\u00b0', '20\u00b0'];
    expect(() => Question.fromJson(json), throwsA(isA<BankFormatException>()));
  });

  test('rejects out-of-range answer_index', () {
    final json = validQuestionJson()..['answer_index'] = 4;
    expect(() => Question.fromJson(json), throwsA(isA<BankFormatException>()));
  });

  test('rejects non-v1 schema_version', () {
    final json = validQuestionJson()..['schema_version'] = 2;
    expect(() => Question.fromJson(json), throwsA(isA<BankFormatException>()));
  });

  test('rejects bad difficulty', () {
    final json = validQuestionJson()..['difficulty'] = 5;
    expect(() => Question.fromJson(json), throwsA(isA<BankFormatException>()));
  });
}
