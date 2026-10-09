import '../../data/models/question.dart';
import 'srs/confidence.dart';

/// A locked-in answer, enriched with confidence-graded quality.
/// Passed to the study layer via `QuizController.onAnswerLocked`.
class AnswerEvent {
  final Question question;
  final bool isCorrect;
  final int quality; // SM-2 0-5
  final ConfidenceLevel confidence;
  final String sessionKind; // 'quiz' | 'qotd' | 'review' | 'drill' | 'retake'
  final DateTime answeredAt;

  const AnswerEvent({
    required this.question,
    required this.isCorrect,
    required this.quality,
    required this.confidence,
    required this.sessionKind,
    required this.answeredAt,
  });

  StudyEvent toStudyEvent() => StudyEvent(
        qid: question.qid,
        domain: question.domain,
        topic: question.topic,
        isCorrect: isCorrect,
        quality: quality,
        confidence: confidence.name,
        sessionKind: sessionKind,
        answeredAtMs: answeredAt.millisecondsSinceEpoch,
      );
}

/// Persisted form of [AnswerEvent] (question by reference, not by value —
/// the bank JSON is the source of truth for question content).
class StudyEvent {
  final String qid;
  final String domain;
  final String topic;
  final bool isCorrect;
  final int quality;
  final String confidence;
  final String sessionKind;
  final int answeredAtMs;

  const StudyEvent({
    required this.qid,
    required this.domain,
    required this.topic,
    required this.isCorrect,
    required this.quality,
    required this.confidence,
    required this.sessionKind,
    required this.answeredAtMs,
  });

  DateTime get answeredAt =>
      DateTime.fromMillisecondsSinceEpoch(answeredAtMs);

  Map<String, dynamic> toJson() => {
        'qid': qid,
        'domain': domain,
        'topic': topic,
        'isCorrect': isCorrect,
        'quality': quality,
        'confidence': confidence,
        'sessionKind': sessionKind,
        'answeredAtMs': answeredAtMs,
      };

  factory StudyEvent.fromJson(Map<String, dynamic> json) => StudyEvent(
        qid: json['qid'] as String,
        domain: json['domain'] as String,
        topic: json['topic'] as String,
        isCorrect: json['isCorrect'] as bool,
        quality: (json['quality'] as num).toInt(),
        confidence: json['confidence'] as String,
        sessionKind: json['sessionKind'] as String,
        answeredAtMs: (json['answeredAtMs'] as num).toInt(),
      );
}
