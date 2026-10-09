# Changelog

## v0.2.0 — 2026-10-09
- Study layer: **question of the day** (deterministic per calendar day,
  same question for all users), **day streaks** (flame badge, best tracking,
  pure state machine), **SM-2 spaced repetition** (pure-Dart scheduler,
  review queue with most-overdue-first ordering, every answer feeds back).
- Home screen is now a study hub: QOTD card, "due for review" card, streak
  badge, then the domain section picker.
- `QuizController.onAnswerLocked` hook wires study persistence without
  entangling session state; results retake/drill sessions forward it.
- Storage: SharedPreferences JSON via `StudyRepository` (sqflite migration
  path documented). Docs: SPACED_REPETITION.md.
- Tests: SM-2 vectors (independently verified), streak transitions, QOTD
  determinism, review-queue ordering.

## v0.1.0 — 2026-10-09
- Initial shell: domain section picker (7 FS domains), quiz flow with
  immediate feedback + explanations, results with per-section breakdown and
  miss review/drill modes, settings with system/light/dark theme.
- Engine contract: Dart mirror of schema v1, bank validation on load,
  `tools/generate_banks.py` pipeline; 2 bundled banks (480 questions each).
- Phase 3 seam: `Entitlements` interface + stub (quiz start already gates).
- Docs: ARCHITECTURE, CONTRACT, THEMING, BUILD. CI: analyze + test.
