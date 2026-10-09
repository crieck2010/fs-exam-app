/// Self-reported confidence after answering, mapped onto the SM-2
/// 0-5 quality scale.
///
/// Pure Dart (no Flutter imports): the mapping is testable in isolation.
///
/// SM-2 quality semantics:
///   5 = perfect response        4 = correct with hesitation
///   3 = correct with difficulty  2 = wrong, but answer looked familiar
///   1 = wrong, answer unfamiliar 0 = complete blackout
///
/// Multiple choice only observes correct/incorrect, so confidence supplies
/// the missing resolution:
///
/// | confidence   | correct | incorrect |
/// |--------------|---------|-----------|
/// | Knew it      |    5    |     1     |
/// | Pretty sure  |    4    |     1     |
/// | Guessed      |    3    |     2     |
///
/// Note "Knew it" + wrong = 1: confident-but-wrong is the most dangerous
/// state, so it re-enters the fast review lane.
enum ConfidenceLevel {
  guessed(
    label: 'Guessed',
    correctQuality: 3,
    incorrectQuality: 2,
  ),
  fairlySure(
    label: 'Pretty sure',
    correctQuality: 4,
    incorrectQuality: 1,
  ),
  knewIt(
    label: 'Knew it',
    correctQuality: 5,
    incorrectQuality: 1,
  );

  final String label;
  final int correctQuality;
  final int incorrectQuality;

  const ConfidenceLevel({
    required this.label,
    required this.correctQuality,
    required this.incorrectQuality,
  });

  int qualityFor(bool correct) => correct ? correctQuality : incorrectQuality;
}
