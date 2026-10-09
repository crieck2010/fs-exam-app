# Architecture

`fs-exam-app` is the **thin UI layer** of the FS Exam Prep program (Phase 2).
All question intelligence lives in the `fs-exam-prep` Python engine; this app
only renders versioned JSON banks the engine produces. That split is the
suite-wide convention: engine = pure logic, UI = presentation.

## Layer map

```
lib/
    main.dart                  Entry: loads persisted theme before first frame.
    app.dart                   MaterialApp: light/dark themes + ThemeMode.
    core/
        theme/
            app_theme.dart         Material 3 light/dark ColorSchemes (one seed).
            theme_controller.dart  ThemeMode state + SharedPreferences persistence.
        monetization/
            monetization.dart      Phase 3 seam: Entitlements interface + stub.
        notifications/
            notification_service.dart  Local nudges: QOTD, streak saver,
                                       weekly report (+ Settings toggles).
    data/
        models/question.dart       Dart mirror of engine schema v1 (validated).
        bank_repository.dart       Asset loading + v1 contract validation.
    features/
        domains/                   Home: study hub (streak, QOTD, review queue)
                                   + domain section picker.
        quiz/                      Session state (QuizController) + one-question
                                   screens with immediate feedback.
        results/                   Score, per-domain breakdown, miss review.
        settings/                  Theme mode segmented control, about.
        study/
            srs/                   SM-2 scheduler + confidence mapping (pure Dart,
                                   no Flutter) + StudyRepository
                                   (SharedPreferences: records, journal).
            streaks/               Pure streak state machine.
            qotd/                  Deterministic daily question + controller.
            insights/              WeeklyReport + Insights builders (pure Dart).
            report/                Weekly report screen.
            milestones/            Milestone unlock logic (pure Dart).
            exam/                  ExamCountdown phases (pure Dart).

assets/banks/*.json                Engine-generated banks (tools/generate_banks.py).
tools/generate_banks.py            Regenerates assets from the Python engine.
```

## Data flow

```
fs-exam-prep engine --(tools/generate_banks.py)--> assets/banks/bank-seed-N.json
                                                              |
domain picker --selects domains--> filter + shuffle + take(N) |
                                                              v
QuizController --select(i)--> lock answer, reveal explanation |
                                                              v
ResultsScreen: score, per-domain breakdown, drill-misses
```

## Key decisions

1. **No on-device generation (shell).** Banks are pre-generated and bundled.
   Regenerating with a new seed = a fresh exam; the pipeline is one command.
   (A full Dart port of the 48 generators is a possible Phase 2.x upgrade —
   the v1 schema makes it a pure re-implementation task.)
2. **Validation on load.** `parseBank` enforces the v1 contract (fields,
   4 unique choices, answer index, unique qids, count). A corrupt bank throws
   `BankFormatException` instead of silently misgrading — same philosophy as
   the engine.
3. **Grading is client-side**: `selectedIndex == answerIndex`, per contract.
4. **Theme before first frame.** `ThemeController` reads SharedPreferences in
   `main()` so the app never flashes the wrong theme on startup.
5. **Answers lock on first tap** (exam discipline); explanations show
   immediately (study value).
6. **Monetization is a seam, not a feature.** `Entitlements` is checked at
   quiz start; the stub grants everything. Phase 3 swaps the implementation.
7. **Study state is layered, not entangled.** `QuizController` exposes an
   `onAnswerLocked` hook; the study layer (`features/study`) wires SRS
   recording, QOTD, and streaks through it. The scheduler itself is pure
   Dart — see `docs/SPACED_REPETITION.md`.

## Scaling notes

- Banks are static assets: add seeds for freshness, or fetch banks from a
  CDN later without changing the parser (v1 lock guarantees compatibility).
- New engine domains appear in the picker automatically (driven by bank
  contents + `kDomains` metadata; add display info per new slug).
- Spaced repetition / analytics can layer on `AnswerRecord`s without
  touching the engine.
