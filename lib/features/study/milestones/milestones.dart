/// Milestone celebrations, checked on app open. Pure Dart — no Flutter
/// imports — so the unlock logic is unit-testable in isolation.
///
/// Celebrated milestone IDs are persisted (`celebrated_milestones_v1`);
/// each milestone fires exactly once, ever.
class Milestone {
  final String id;
  final String title;
  final String message;

  const Milestone({
    required this.id,
    required this.title,
    required this.message,
  });
}

class MilestoneChecker {
  static const List<int> streakThresholds = [7, 30, 100];
  static const List<int> questionThresholds = [100, 500, 1000];

  /// Returns milestones unlocked by the current totals that have not been
  /// celebrated yet. `>=` (not `==`) so no milestone is ever skipped, even
  /// if the totals jumped past a threshold between checks.
  static List<Milestone> newlyUnlocked({
    required int streak,
    required int lifetimeAnswered,
    required Set<String> celebrated,
  }) {
    final unlocked = <Milestone>[];
    for (final days in streakThresholds) {
      final id = 'streak_$days';
      if (streak >= days && !celebrated.contains(id)) {
        unlocked.add(Milestone(
          id: id,
          title: '$days-day streak!',
          message: _streakMessage(days),
        ));
      }
    }
    for (final count in questionThresholds) {
      final id = 'questions_$count';
      if (lifetimeAnswered >= count && !celebrated.contains(id)) {
        unlocked.add(Milestone(
          id: id,
          title: '${_formatCount(count)} questions answered!',
          message: _questionMessage(count),
        ));
      }
    }
    return unlocked;
  }

  static String _streakMessage(int days) {
    switch (days) {
      case 7:
        return 'A full week of showing up. The habit is forming.';
      case 30:
        return 'A month of daily reps. This is how surveyors are made.';
      default:
        return 'Triple digits. You are in rare air — keep it alive.';
    }
  }

  static String _questionMessage(int count) {
    switch (count) {
      case 100:
        return 'Centurion. The question bank is getting to know you.';
      case 500:
        return 'Serious volume. Your weakest sections are on notice.';
      default:
        return 'Four figures. Exam day should be nervous — not you.';
    }
  }

  static String _formatCount(int count) =>
      count >= 1000 ? '${count ~/ 1000},000' : '$count';
}
