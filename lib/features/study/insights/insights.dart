import '../../../data/models/question.dart';
import '../study_event.dart';

/// Accuracy insight for one domain.
class DomainInsight {
  final String domain;
  final int answered;
  final int correct;

  const DomainInsight({
    required this.domain,
    required this.answered,
    required this.correct,
  });

  double get accuracy => answered == 0 ? 0 : correct / answered;
}

/// Focus areas (weakest domains) and strengths (strongest domains),
/// derived from the answer journal. Pure Dart — no Flutter imports.
///
/// A domain only qualifies with at least [minAttempts] answers in the
/// window — ranking on 2 answers is noise, not insight.
class Insights {
  final List<DomainInsight> focus;
  final List<DomainInsight> strengths;
  final List<DomainInsight> all;

  const Insights({
    required this.focus,
    required this.strengths,
    required this.all,
  });

  factory Insights.build(
    List<StudyEvent> journal,
    DateTime now, {
    int windowDays = 30,
    int minAttempts = 5,
    int take = 2,
  }) {
    final cutoffMs =
        now.subtract(Duration(days: windowDays)).millisecondsSinceEpoch;
    final grouped = <String, List<StudyEvent>>{};
    for (final e in journal) {
      if (e.answeredAtMs < cutoffMs) continue;
      grouped.putIfAbsent(e.domain, () => []).add(e);
    }

    final qualified = <DomainInsight>[];
    for (final entry in grouped.entries) {
      if (entry.value.length < minAttempts) continue;
      final correct = entry.value.where((e) => e.isCorrect).length;
      qualified.add(DomainInsight(
        domain: entry.key,
        answered: entry.value.length,
        correct: correct,
      ));
    }
    qualified.sort((a, b) => a.accuracy.compareTo(b.accuracy));

    return Insights(
      focus: qualified.take(take).toList(),
      strengths: qualified.reversed.take(take).toList(),
      all: qualified,
    );
  }

  /// Builds a drill session for a focus domain: previously-failed questions
  /// first (most recent failure first — freshest pain), then unseen
  /// questions from the domain to fill up to [limit].
  static List<Question> drillQuestions({
    required String domain,
    required List<Question> bank,
    required List<StudyEvent> journal,
    int limit = 20,
  }) {
    final inDomain = bank.where((q) => q.domain == domain).toList();
    final byQid = {for (final q in inDomain) q.qid: q};

    // Last outcome per question, from the journal (chronological).
    final lastFailureMs = <String, int>{};
    final everSeen = <String>{};
    for (final e in journal) {
      if (e.domain != domain || !byQid.containsKey(e.qid)) continue;
      everSeen.add(e.qid);
      if (e.isCorrect) {
        lastFailureMs.remove(e.qid);
      } else {
        lastFailureMs[e.qid] = e.answeredAtMs;
      }
    }

    final failed = lastFailureMs.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final picked = <Question>[];
    for (final entry in failed) {
      if (picked.length >= limit) break;
      picked.add(byQid[entry.key]!);
    }
    if (picked.length < limit) {
      final unseen = inDomain.where((q) => !everSeen.contains(q.qid)).toList()
        ..shuffle();
      picked.addAll(unseen.take(limit - picked.length));
    }
    return picked;
  }
}
