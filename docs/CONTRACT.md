# Contract: engine schema v1 ↔ Dart model

The app implements the **fs-exam-prep schema v1** contract
(`fs-exam-prep/schema/question-v1.json`, guarantees in
`fs-exam-prep/docs/SCHEMA_CONTRACT.md`).

## Field mapping

| Engine (JSON) | Dart (`Question`) | Validation |
|---|---|---|
| `qid` | `qid` | non-empty string, unique per bank |
| `schema_version` | `schemaVersion` | must be `1` |
| `domain` | `domain` | string (matched to `kDomains` slugs for display) |
| `topic` | `topic` | string |
| `difficulty` | `difficulty` | int 1–3 |
| `stem` | `stem` | non-empty string |
| `choices` | `choices` | exactly 4 unique non-empty strings |
| `answer_index` | `answerIndex` | int 0–3 |
| `explanation` | `explanation` | non-empty string |
| `parameters` | `parameters` | object (opaque to the app) |
| `seed` | `seed` | int |

Bank-level: `schema_version` must be 1, `question_count` must equal
`questions.length`.

## Grading rule

Client-side, per contract: `selectedIndex == answerIndex`. No partial
credit.

## Change protocol

- The v1 line never breaks this mapping (engine guarantee).
- If the engine ever ships schema v2: update `Question.fromJson`,
  `parseBank`, `flutter_contract` expectations, and this doc **together**,
  and add a v1→v2 migration test. Do not silently widen parsing.
