import 'package:flutter_test/flutter_test.dart';
import 'package:fs_exam_app/features/study/milestones/milestones.dart';

void main() {
  test('unlocks streak milestones at thresholds', () {
    final unlocked = MilestoneChecker.newlyUnlocked(
      streak: 7,
      lifetimeAnswered: 0,
      celebrated: {},
    );
    expect(unlocked.map((m) => m.id), ['streak_7']);
    expect(unlocked.first.title, '7-day streak!');
  });

  test('unlocks question milestones at thresholds', () {
    final unlocked = MilestoneChecker.newlyUnlocked(
      streak: 0,
      lifetimeAnswered: 1000,
      celebrated: {},
    );
    // >= means jumping past thresholds still unlocks all of them
    expect(unlocked.map((m) => m.id),
        ['questions_100', 'questions_500', 'questions_1000']);
  });

  test('never re-fires celebrated milestones', () {
    final unlocked = MilestoneChecker.newlyUnlocked(
      streak: 30,
      lifetimeAnswered: 500,
      celebrated: {'streak_7', 'streak_30', 'questions_100', 'questions_500'},
    );
    expect(unlocked, isEmpty);
  });

  test('below every threshold unlocks nothing', () {
    final unlocked = MilestoneChecker.newlyUnlocked(
      streak: 6,
      lifetimeAnswered: 99,
      celebrated: {},
    );
    expect(unlocked, isEmpty);
  });

  test('mixed unlock: streak and questions together', () {
    final unlocked = MilestoneChecker.newlyUnlocked(
      streak: 100,
      lifetimeAnswered: 250,
      celebrated: {'streak_7', 'streak_30', 'questions_100'},
    );
    expect(unlocked.map((m) => m.id), ['streak_100']);
  });
}
