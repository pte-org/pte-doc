# Phase 1: Backend Data Contracts & DTOs (Task Delivery)

## Requirements

Bring `pte-api`'s `exam-delivery` service's student-facing `TaskView`/`OptionView` DTOs up to the point where they can carry everything Phase 2-6's Flutter screens need: per-blank distinct option groups for `FILL_BLANKS_READING_WRITING`, and a data type for `orderIndex` that actually matches the documented "decimal string" convention instead of silently being an `int`. This phase touches only the response-DTO/mapper layer — no scoring logic (Phase 7) and no seed data (Phase 8) here.

Maps to: enables Frontend Phase 2's `TaskView`/`TaskOption`/`BlankGroup` model, and every later Frontend phase's payload construction.

## Design Constraints

- `OptionView.orderIndex` changes from `int` to `String` — a breaking response-shape change for any consumer that parses it as a number. Per `plan.md`'s Research Summary item 14 / Risk section, this is safe to ship freely today (no released `pte-app` build exists), but must never ship to a production/staging environment ahead of a Frontend-Phase-2-equivalent tolerant client in the future — leave this constraint documented in this phase's own code comments, not just in `plan.md`, so it survives independently of this plan being read.
- `BlankGroupView` is a new response-only record — it must never carry a `correct`/`correctAnswerText`-equivalent field, matching `TaskView`'s and `OptionView`'s existing doc-comment convention ("deliberately excludes... those stay server-side for scoring only").
- `blankGroups` must serialize as `null`/omitted for every task type except `FILL_BLANKS_READING_WRITING` — do not populate it defensively for other types "just in case."
- `AttemptMapper` (or wherever the entity→DTO mapping currently lives for `TaskView`) is the only place `blankGroups` gets populated from the frozen exam snapshot — no shortcut that reads it from a different layer.

## Steps

1. Read `services/exam-delivery/src/main/java/com/pte/examdelivery/dto/response/TaskView.java`, `OptionView.java`, and `AttemptMapper.java` in full to confirm the current mapping path from whatever entity/snapshot type backs `TaskView` today.
2. Create `services/exam-delivery/src/main/java/com/pte/examdelivery/dto/response/BlankGroupView.java`: `public record BlankGroupView(Integer blankIndex, List<OptionView> options) {}`, matching the existing record-DTO style already used by `TaskView`/`OptionView`.
3. Edit `OptionView.java`: change `int orderIndex` to `String orderIndex`. Update every call site that constructs an `OptionView` (search the codebase for `new OptionView(`) to pass a `String` (e.g. `String.valueOf(entity.getOrderIndex())` if the underlying entity/DB column stays an integer — only the DTO-layer type changes here, not necessarily the persistence layer, unless the entity itself already stores a string).
4. Edit `TaskView.java`: add `List<BlankGroupView> blankGroups` as the final record component (nullable — omitted from the constructor call for every task type except `FILL_BLANKS_READING_WRITING`).
5. Edit `AttemptMapper.java`: for a task whose `taskType == FILL_BLANKS_READING_WRITING`, populate `blankGroups` from the frozen snapshot's per-blank option data; for every other task type, pass `null`.
6. Confirm Jackson serialization: a `null` record component should serialize as an absent/`null` JSON field per whatever `ObjectMapper` configuration this service already uses (check for `@JsonInclude` conventions elsewhere in the module) — match existing convention, don't introduce a new serialization-inclusion policy for just this field.

## Success Criteria

- [ ] `OptionView.orderIndex` is `String`, and every existing call site compiles against the new type.
- [ ] `BlankGroupView` exists with exactly `{blankIndex, options}`, no correctness-leaking field.
- [ ] `TaskView` carries `blankGroups`, populated only for `FILL_BLANKS_READING_WRITING`, `null`/omitted for every other type.
- [ ] A mapper unit test confirms the above for at least one task of each affected type.
- [ ] `OptionView.orderIndex` round-trips as a JSON string in a serialization test (not a JSON number).
- [ ] The module builds and its existing test suite still passes (no regression to `MC_READING_SINGLE`'s existing option-serialization behavior).

## Quality and Testing State

- Quality gate: not started.
- Testing: not started.

## Risks

- **MEDIUM (carried from `plan.md`)**: this is a breaking DTO-shape change. Mitigated today by there being no released `pte-app` build; becomes a live deployment-ordering constraint the moment one exists (see `plan.md` Research Summary item 14).
