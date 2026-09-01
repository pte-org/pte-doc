# Phase 1: Backend Timing Config for DESCRIBE_IMAGE and PERSONAL_INTRODUCTION

## Requirements
A real attempt containing a `DESCRIBE_IMAGE` or `PERSONAL_INTRODUCTION` item can be pinned without `TaskTimingConfig.timingFor()` throwing `TaskTimingNotConfiguredException` — both types get their user-confirmed static prep/response seconds.

## Steps
1. Add a `DESCRIBE_IMAGE` entry to `task-timing.json` with prepSeconds=25, responseSeconds=40 (static shape, no `preListenSeconds`/`preRecordSeconds` — matches `READ_ALOUD`'s existing entry, not the 5 dynamic-computation audio-prompt types).
2. **Separately, as its own clearly-labeled step (not folded into the Describe Image work above):** add a `PERSONAL_INTRODUCTION` entry with prepSeconds=25, responseSeconds=30 — this is the entirety of this task type's scope for this whole plan, nothing else in any later phase touches it.
3. Update the config file's own top-of-file comment if it enumerates which task types are configured, so it stays accurate.
4. Confirm no other code path (e.g. a hardcoded task-type allowlist elsewhere in exam-delivery) also needs these two type names added — grep for existing usages of a comparable already-configured type name (e.g. `READ_ALOUD`) to check for parallel lists that would otherwise silently exclude the new types.
5. Add or extend a unit/integration test that loads the real `task-timing.json` and asserts `timingFor("DESCRIBE_IMAGE")` and `timingFor("PERSONAL_INTRODUCTION")` both return the expected values without throwing.
6. Run the exam-delivery test suite to confirm no existing test (e.g. one that asserts the exact set of configured task types) needs updating for the two new entries.

## Success Criteria
- `TaskTimingConfig.timingFor("DESCRIBE_IMAGE")` returns `{prepSeconds: 25, responseSeconds: 40, preListenSeconds: null, preRecordSeconds: null}`.
- `TaskTimingConfig.timingFor("PERSONAL_INTRODUCTION")` returns `{prepSeconds: 25, responseSeconds: 30, preListenSeconds: null, preRecordSeconds: null}`.
- Full exam-delivery test suite passes with no regressions.

## Risks
- The config file's top-of-file comment currently reads "Only Milestone-1's 3 delivered task types are configured" — leaving it stale after this change would mislead future readers. Mitigation: Step 3 explicitly updates it.
