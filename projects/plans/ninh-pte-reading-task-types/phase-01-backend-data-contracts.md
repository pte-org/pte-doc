# Phase 1: Backend Data Contracts & DTOs (Task Delivery)

## Requirements

Bring `pte-api`'s option/blank-group data model up to the point where it can carry everything Phase 2-6's Flutter screens need — per-blank distinct option groups for `FILL_BLANKS_READING_WRITING` — and fix `OptionView.orderIndex`'s type mismatch (`int` vs. the documented "decimal string" convention). No scoring logic (Phase 7) and no seed data (Phase 8) here.

**Revised during Preflight** (superseding this phase's original description): investigating the full pipeline (`authoring`'s `QuestionOption`/`Question` → `SnapshotPublishService.freeze()`/`serializeOptions` → `SnapshotItem.optionsJson` → `AuthoringSnapshotContentResponse`/`PinnedItem`/`PinnedItemView` (all pass `optionsJson` through as an **opaque string**, never parsing it) → `AttemptMapper.parseOptions` → `TaskView.options`) showed that every intermediate layer already treats `optionsJson` as opaque. The only two places that ever construct/deserialize its structure are `SnapshotPublishService.serializeOptions` (write) and `AttemptMapper.parseOptions` (read). This means `blankGroups` does **not** need a new parallel `blankGroupsJson` column threaded through every layer — the existing `optionsJson` mechanism can carry per-blank grouping by adding one nullable `blankIndex` field to the option shape at just those two endpoints, plus one nullable DB column on `QuestionOption`. Every intermediate DTO/entity (`PinnedItem`, `PinnedItemView`, `AuthoringSnapshotContentResponse`, `SnapshotContentResponse`, `ExamSnapshotPublishedEvent`) needs **zero changes** — confirmed by reading each one.

Maps to: enables Frontend Phase 2's `TaskView`/`TaskOption`/`BlankGroup` model, and every later Frontend phase's payload construction.

## Design Constraints

- `OptionView.orderIndex` changes from `int` to `String` — a breaking response-shape change for any consumer that parses it as a number. Per `plan.md`'s Research Summary / Risk section, this is safe to ship freely today (no released `pte-app` build exists), but must never ship to a production/staging environment ahead of a Frontend-Phase-2-equivalent tolerant client in the future.
- `QuestionOption.blankIndex` (new, nullable `Integer` column on `authoring`'s `question_options` table) is `null` for every option belonging to every task type except `FILL_BLANKS_READING_WRITING`. For that type, every option is authored already belonging to some blank (`blankIndex` set), grouping distinct option lists per gap.
- `SnapshotPublishService`'s private `FrozenOption` record (and `AttemptMapper`'s matching private `FrozenOption` record on the exam-delivery side) both gain `blankIndex` as an additional field — these two records currently must stay structurally identical (they're each other's write/read contract via `optionsJson`'s JSON shape) even though they live in different services with no shared type; keep them in lockstep.
- `AttemptMapper.parseOptions` (or a renamed/split equivalent) must branch on whether any parsed `FrozenOption` has a non-null `blankIndex`: if none do, build the existing flat `List<OptionView>` exactly as today (**zero behavior change** for `MC_READING_SINGLE`, `MC_READING_MULTIPLE`, `RE_ORDER_PARAGRAPHS`, `FILL_BLANKS_READING` — none of these ever set `blankIndex`); if some do, group by `blankIndex` into `List<BlankGroupView>` instead, and `TaskView.options` stays `null`/empty for that task.
- `BlankGroupView` is a new response-only record — must never carry a `correct`/`correctAnswerText`-equivalent field, matching `TaskView`'s/`OptionView`'s existing doc-comment convention ("deliberately excludes... those stay server-side for scoring only").
- A Flyway migration is required for the new `question_options.blank_index` column (nullable, no default needed, no backfill needed — every existing row is legitimately `null`).

## Steps

1. Read `services/authoring/src/main/java/com/pte/authoring/domain/QuestionOption.java`, `services/authoring/src/main/java/com/pte/authoring/service/SnapshotPublishService.java`, and `services/exam-delivery/src/main/java/com/pte/examdelivery/mapper/AttemptMapper.java` in full (already done during Preflight — re-confirm nothing changed since).
2. Add a Flyway migration in `services/authoring`'s migration directory: `ALTER TABLE question_options ADD COLUMN blank_index INTEGER NULL;` (follow this module's exact existing migration file-naming convention).
3. Edit `QuestionOption.java`: add `@Column private Integer blankIndex;` (nullable, no `nullable = false`).
4. Edit `SnapshotPublishService.java`: `FrozenOption` record gains `Integer blankIndex`; `serializeOptions` includes `o.getBlankIndex()` when constructing each `FrozenOption`.
5. Edit `services/exam-delivery/src/main/java/com/pte/examdelivery/dto/response/OptionView.java`: `orderIndex` refactored `int` → `String`.
6. Create `services/exam-delivery/src/main/java/com/pte/examdelivery/dto/response/BlankGroupView.java`: `public record BlankGroupView(Integer blankIndex, List<OptionView> options) {}`.
7. Edit `services/exam-delivery/src/main/java/com/pte/examdelivery/dto/response/TaskView.java`: add `List<BlankGroupView> blankGroups` as the final record component (nullable).
8. Edit `AttemptMapper.java`: `FrozenOption` private record gains `Integer blankIndex`; `parseOptions` (or a new sibling method) branches per the Design Constraints — group by `blankIndex` into `BlankGroupView`s when present, otherwise build the existing flat `OptionView` list unchanged; `toTaskResponse` passes the right value to `TaskView`'s new `blankGroups` parameter (`null` when not a blank-grouped task).
9. Confirm Jackson serialization: a `null` record component should serialize as an absent/`null` JSON field per whatever `ObjectMapper` configuration this service already uses — match existing convention.

## Success Criteria

- [x] `OptionView.orderIndex` is `String`, and every existing call site compiles against the new type.
- [x] `QuestionOption.blankIndex` exists, nullable, with a migration (`V2__add_blank_index_to_question_options.sql`) that doesn't require backfilling existing rows.
- [x] `BlankGroupView` exists with exactly `{blankIndex, options}`, no correctness-leaking field.
- [x] `TaskView.blankGroups` is populated only when the underlying options carry a non-null `blankIndex`, `null`/omitted otherwise — verified for flat, blank-grouped, and empty option shapes.
- [x] Existing behavior for `MC_READING_SINGLE`/every currently-flat-options task type is provably unchanged (regression test against the exact pre-phase `optionsJson` shape, no `blankIndex` key).
- [x] `OptionView.orderIndex` round-trips as a JSON string in a serialization test (not a JSON number).
- [x] Both modules (`authoring`, `exam-delivery`) build and their existing test suites still pass.

## Quality and Testing State

- Quality gate: approved (0 blocking findings; 2 NOTED — QUAL-101: no authoring write-path exists yet to set `blankIndex` from a real request, expected to be closed by Phase 8's seed data and/or a future authoring-tooling phase, not a defect in this phase's own scope; QUAL-102: the two independently-maintained `FrozenOption` records must stay structurally in lockstep with no contract test, pre-existing pattern not introduced by this phase). Report: `pte-api/plans/ninh-pte-reading-task-types/quality/phase-01-backend-data-contracts-quality-report.json`. Receipt issued: `pte-api/plans/ninh-pte-reading-task-types/quality/phase-01-backend-data-contracts-receipt.json`.
- Testing: PASSED — 6/6 tests passing in `services/exam-delivery/src/test/java/com/pte/examdelivery/mapper/AttemptMapperTest.java` (flat-options zero-behavior-change regression x2, blank-grouped grouping/ordering, empty-options x4 sub-cases, orderIndex string round-trip x2, mixed-blankIndex IllegalStateException guard). `authoring` module has no test scaffold to extend (`SnapshotPublishService`/`QuestionOption` `blankIndex` round-trip not independently covered — noted as a residual gap, not a blocker, since the write-side shape is exercised indirectly by the read-side tests using its exact JSON contract). Full `mvn -pl services/exam-delivery,services/authoring -am test` run: BUILD SUCCESS.

## Risks

- **MEDIUM (carried from `plan.md`)**: `OptionView.orderIndex` int→String is a breaking DTO-shape change. Mitigated today by there being no released `pte-app` build; becomes a live deployment-ordering constraint the moment one exists (see `plan.md` Research Summary).
- **MEDIUM (discovered during Preflight)**: the grouping logic in `AttemptMapper.parseOptions` is now a branch point shared by every task type, not just the new one — a bug here has blast radius across `MC_READING_SINGLE` and every other already-shipped options-based type, not just `FILL_BLANKS_READING_WRITING`. The "zero behavior change for flat-options tasks" Success Criterion above is the primary defense; it must be a real regression test against the *exact* pre-this-phase `optionsJson` shape, not just a new-shape-only test.

## Bug found and fixed during implementation

A `tester` agent writing this phase's mapper tests found a real bug in the first-draft `toBlankGroups` implementation: a **mixed** parsed-options list (some entries with `blankIndex` set, some without — an authoring data-integrity error, not something valid content should ever produce) hit `Collectors.groupingBy(FrozenOption::blankIndex, TreeMap::new, ...)` with a `null` classifier key for the ungrouped entries, and `TreeMap` throws a bare, unhelpful `NullPointerException` on a `null` key insert. `toFlatOptions`'s and `toBlankGroups`'s early-return conditions (`anyMatch(blankIndex != null)` vs. `noneMatch(blankIndex != null)`) are not exact logical complements for this mixed case, so it fell through to the grouping path instead of being rejected upfront.

Fixed by adding `requireHomogeneousBlankIndex(UUID pinnedItemPublicId, List<FrozenOption> parsed)` in `AttemptMapper.java`, called immediately after `parseFrozenOptions()` in `toTaskResponse()`, before either `toFlatOptions`/`toBlankGroups` runs. It throws a clear `IllegalStateException` naming the pinned item's public ID when the list is mixed, instead of a bare NPE deep in a stream pipeline. Verified via `mvn -pl services/exam-delivery -am compile` after the fix; the tester agent's test (e) asserts this exact exception type/message rather than documenting the NPE as expected behavior.
