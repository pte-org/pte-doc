# Phase 1: Timing Config — Add SUMMARIZE_WRITTEN_TEXT

## Requirements

Fix the `TimerService` fail-fast on the `SUMMARIZE_WRITTEN_TEXT` task type by adding a timing entry in `task-timing.json`. No other change in this phase.

## Design Constraints

- PTE official duration: **10 minutes** (600 seconds) for `SUMMARIZE_WRITTEN_TEXT` (one sentence, 5–75 words).
- Prep time: **0 seconds** — matches the existing `WRITE_ESSAY` entry's `prepSeconds=0` and the Flutter dev fixture (`kSummarizeWrittenTextDurationSeconds = 600` in `pte-app/lib/features/exam_attempt/speaking_writing/dev/writing_task_fixtures.dart`).
- Match the existing entry's JSON shape exactly — same key, same field names, same nesting depth.
- Do **not** change `WRITE_ESSAY`'s existing entry (`0 / 1200`) — already correct.

## Steps

1. Open `pte-api/services/exam-delivery/src/main/resources/config/task-timing.json`.
2. Inside the `timings` object, add one entry alphabetically:
   ```json
   "SUMMARIZE_WRITTEN_TEXT": { "prepSeconds": 0, "responseSeconds": 600 }
   ```
3. Reorder keys so `SUMMARIZE_WRITTEN_TEXT` sits next to `WRITE_ESSAY` if the file is otherwise alphabetically ordered; otherwise keep the insertion order stable.
4. Run `mvn -pl services/exam-delivery compile` to confirm the JSON parses (it is loaded via `ObjectMapper.readTree` at startup — a syntax error throws and prevents boot).
5. Boot the `exam-delivery` service locally; confirm startup log line indicates `SUMMARIZE_WRITTEN_TEXT` is now registered.

## Success Criteria

- [ ] `task-timing.json` contains a `SUMMARIZE_WRITTEN_TEXT` entry with `prepSeconds=0`, `responseSeconds=600`.
- [ ] `WRITE_ESSAY` entry unchanged.
- [ ] `mvn -pl services/exam-delivery compile` succeeds.
- [ ] `exam-delivery` service boots without throwing on `TimerService` initialization.
