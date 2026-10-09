# Changelog

## v0.4.0 — 2026-10-09
- **Milestone celebrations** — 7/30/100-day streaks and 100/500/1000
  lifetime questions, checked on app open, each celebrated exactly once
  via a trophy dialog. Lifetime counter lives separately from the pruned
  journal so it never undercounts.
- **Exam countdown** — optional exam date in Settings drives a home
  countdown card with study phases (distant → building → focused →
  final week → exam day → passed), each with phase-appropriate advice.
- **Weak-area pings** — in the crunch zone (≤ 30 days out), the home
  focus card becomes an urgent ping naming the weakest section with a
  one-tap drill, dismissible for the day; the 8 AM QOTD notification
  body also names the weak area ("23 days to exam day — Boundary Law
  needs work").
- Tests: milestone unlock/no-refire, countdown phase boundaries,
  lifetime counter independence, exam-date persistence.

## v0.3.0 — 2026-10-09
- **Confidence-graded reviews** — one-tap "How confident were you?"
  (Guessed / Pretty sure / Knew it) after each answer maps onto the full
  SM-2 0–5 quality scale; Next unlocks after submitting so no review is
  ever silently unscheduled.
- **Weekly study report** — headline stats (answered, accuracy, active
  days, QOTDs), per-section accuracy bars weakest-first, SRS queue health.
- **Focus areas & strengths** — weakest/strongest sections from the last
  30 days (min 5 attempts to qualify — no ranking on noise); one-tap
  drills serve previously-failed questions first, then unseen ones.
- **Notification nudges** — QOTD 8 AM daily, conditional 8 PM streak
  saver (re-armed on every app open, zero background execution), Monday
  8 AM weekly report; per-nudge toggles in Settings. See
  docs/NOTIFICATIONS.md for the full idea list and platform setup.
- **Answer journal** — append-only event log (90 days / 5000 cap) feeding
  the report and insights; `sessionKind` tracked per event
  (quiz/qotd/review/drill/retake).
- Tests: confidence matrix, weekly report aggregation, insights gating
  and drill ordering, journal persistence + pruning.

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
