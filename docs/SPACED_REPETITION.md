# Spaced repetition

v0.2.0 adds a study layer on top of the quiz engine: a **question of the
day**, **day streaks**, and **SM-2 spaced-repetition scheduling**.

## Algorithm: SM-2

Each question carries an `SrsRecord`: easiness factor `EF` (starts 2.5,
floor 1.3), interval in days, consecutive successful repetitions, and the
next due date. After each locked-in answer:

```
quality q: correct -> 4, incorrect -> 2
EF' = EF + (0.1 - (5-q) * (0.08 + (5-q) * 0.02)), floored at 1.3
q < 3 : repetitions = 0, interval = 1 day        (ladder restarts)
q >= 3: repetitions += 1
        interval = 1          (1st success)
                 | 6          (2nd success)
                 | round(prev * EF')  (3rd+)
next_due = today + interval
```

The scheduler is **pure Dart** (`lib/features/study/srs/srs_record.dart`,
zero Flutter imports) — the app-side equivalent of the program's
engine-first rule. `test/srs_scheduler_test.dart` pins the vectors above.

### Quality mapping (v0.2.0)

Multiple choice only observes correct/incorrect, so quality is binary:
correct = 4 (good recall), incorrect = 2 (fail, restarts the ladder).
A future version may add a confidence prompt ("knew it" / "guessed") to
use the full 0–5 range — the scheduler already supports it.

## Question of the day

Deterministic: `questionOfTheDay(bank, date)` seeds `Random` with the local
day count, so every user with the same bank gets the **same question** on
the same day. Answering it (right or wrong) extends the streak; the answer
also feeds the SRS scheduler. State is idempotent per day.

## Streaks

`recordStreakDay(state, today)` is a pure state machine
(`lib/features/study/streaks/streak_logic.dart`): same-day calls are
no-ops, a consecutive day extends, any gap restarts at 1; `best` is tracked
separately. Displayed as a flame badge in the home AppBar.

## Review queue

`SrsScheduler.dueQuestions(records, bank, now, limit)` returns due items,
**most overdue first, never-seen questions last** — reinforce what's
slipping before introducing new material. The home "due for review" card
opens a 20-question review session (oldest due first); every answer
re-enters the scheduler, so the queue is self-maintaining.

## Storage

`StudyRepository` persists to SharedPreferences as JSON
(`srs_records_v1`, `streak_v1`, `qotd_*`). Ample for thousands of records
on one device. If review history ever needs real querying (analytics,
cross-device sync), migrate this repository to sqflite — the interface
(`recordAnswer`, `loadRecords`, `loadStreak`, QOTD accessors) stays the
same, and the pure scheduler doesn't change at all.
