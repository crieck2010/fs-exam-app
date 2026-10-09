import 'package:flutter_test/flutter_test.dart';
import 'package:fs_exam_app/features/study/srs/confidence.dart';

void main() {
  test('confidence x correctness maps to SM-2 quality', () {
    expect(ConfidenceLevel.knewIt.qualityFor(true), 5);
    expect(ConfidenceLevel.fairlySure.qualityFor(true), 4);
    expect(ConfidenceLevel.guessed.qualityFor(true), 3);
    expect(ConfidenceLevel.guessed.qualityFor(false), 2);
    expect(ConfidenceLevel.fairlySure.qualityFor(false), 1);
    // Confident-but-wrong is the most dangerous state: fast review lane.
    expect(ConfidenceLevel.knewIt.qualityFor(false), 1);
  });

  test('qualities stay inside the SM-2 0-5 range', () {
    for (final level in ConfidenceLevel.values) {
      expect(level.qualityFor(true), inInclusiveRange(0, 5));
      expect(level.qualityFor(false), inInclusiveRange(0, 5));
    }
  });

  test('labels are human-readable', () {
    expect(ConfidenceLevel.guessed.label, 'Guessed');
    expect(ConfidenceLevel.fairlySure.label, 'Pretty sure');
    expect(ConfidenceLevel.knewIt.label, 'Knew it');
  });
}
