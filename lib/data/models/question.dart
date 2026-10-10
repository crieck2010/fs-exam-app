/// Dart mirror of the fs-exam-prep engine's schema v1
/// (fs-exam-prep/schema/question-v1.json).
///
/// The field names, types, and validation rules here must match the engine
/// contract exactly. If the engine ever ships schema v2, this model and
/// [BankRepository] must be updated together — see docs/CONTRACT.md.
class Question {
  final String qid;
  final int schemaVersion;
  final String domain;
  final String topic;
  final int difficulty; // 1 = recall/one-step, 2 = multi-step, 3 = exam-hard
  final String stem;
  final List<String> choices; // exactly 4, unique
  final int answerIndex; // 0-3
  final String explanation;
  final Map<String, dynamic> parameters;
  final int seed;

  const Question({
    required this.qid,
    required this.schemaVersion,
    required this.domain,
    required this.topic,
    required this.difficulty,
    required this.stem,
    required this.choices,
    required this.answerIndex,
    required this.explanation,
    required this.parameters,
    required this.seed,
  });

  static const List<String> requiredFields = [
    'qid',
    'schema_version',
    'domain',
    'topic',
    'difficulty',
    'stem',
    'choices',
    'answer_index',
    'explanation',
    'parameters',
    'seed',
  ];

  /// Parses and validates a question map. Throws [BankFormatException]
  /// on any contract violation — a corrupt bank must fail loudly, never
  /// silently misgrade.
  factory Question.fromJson(Map<String, dynamic> json) {
    for (final field in requiredFields) {
      if (!json.containsKey(field)) {
        throw BankFormatException('question is missing field "$field"');
      }
    }
    if (json['schema_version'] != 1) {
      throw BankFormatException(
          'unsupported schema_version ${json['schema_version']} (expected 1)');
    }
    final difficulty = json['difficulty'];
    if (difficulty is! int || difficulty < 1 || difficulty > 3) {
      throw BankFormatException('difficulty must be 1-3, got $difficulty');
    }
    final rawChoices = json['choices'];
    if (rawChoices is! List || rawChoices.length != 4) {
      throw const BankFormatException('choices must be a list of 4 strings');
    }
    final choices = rawChoices.map((e) => e.toString()).toList();
    if (choices.toSet().length != 4 || choices.any((c) => c.isEmpty)) {
      throw const BankFormatException('choices must be 4 unique non-empty strings');
    }
    final answerIndex = json['answer_index'];
    if (answerIndex is! int || answerIndex < 0 || answerIndex > 3) {
      throw BankFormatException('answer_index must be 0-3, got $answerIndex');
    }
    final stem = json['stem'].toString();
    final explanation = json['explanation'].toString();
    if (stem.isEmpty || explanation.isEmpty) {
      throw const BankFormatException('stem and explanation must be non-empty');
    }
    final parameters = json['parameters'];
    if (parameters is! Map) {
      throw const BankFormatException('parameters must be an object');
    }
    return Question(
      qid: json['qid'].toString(),
      schemaVersion: 1,
      domain: json['domain'].toString(),
      topic: json['topic'].toString(),
      difficulty: difficulty,
      stem: stem,
      choices: choices,
      answerIndex: answerIndex,
      explanation: explanation,
      parameters: Map<String, dynamic>.from(parameters),
      seed: (json['seed'] as num).toInt(),
    );
  }

  /// Client-side grading, per the engine contract.
  bool isCorrect(int selectedIndex) => selectedIndex == answerIndex;

  String get correctChoice => choices[answerIndex];
}

/// Thrown when a bank file violates the v1 contract.
class BankFormatException implements Exception {
  final String message;
  const BankFormatException(this.message);

  @override
  String toString() => 'BankFormatException: $message';
}
