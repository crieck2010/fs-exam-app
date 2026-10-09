/// Phase 3 seam: freemium entitlements.
///
/// The quiz flow checks [Entitlements] before starting a session, but the
/// only implementation shipped in the shell is [StubEntitlements], which
/// grants unlimited access. Phase 3 will add a real implementation backed
/// by in-app purchases (one-time unlock) and AdMob (rewarded ads for extra
/// questions) without touching the quiz UI.
///
/// Usage:
/// ```dart
/// final entitlements = StubEntitlements();
/// if (await entitlements.canStartQuiz(questionCount)) { ... }
/// ```
abstract class Entitlements {
  /// True when the user owns the paid unlock.
  Future<bool> get isPro;

  /// Free questions remaining today for anonymous users.
  Future<int> get remainingFreeQuestionsToday;

  /// Gate checked by the domain picker before starting a quiz.
  Future<bool> canStartQuiz(int questionCount) async {
    if (await isPro) return true;
    return questionCount <= await remainingFreeQuestionsToday;
  }
}

/// Development/stub implementation: everything is free.
class StubEntitlements implements Entitlements {
  @override
  Future<bool> get isPro async => false;

  @override
  Future<int> get remainingFreeQuestionsToday async => 1 << 20;

  @override
  Future<bool> canStartQuiz(int questionCount) async => true;
}
