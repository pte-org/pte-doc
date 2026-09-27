# Phase 6: Frontend `FILL_BLANKS_READING_WRITING` (Dropdown)

## Requirements

Build the dropdown fill-in-the-blanks Reading screen: a passage with several gaps, each gap having its own distinct dropdown list of word choices (not a shared word bank). Falls back to a graceful `StatusBanner` when the backend hasn't yet populated `blankGroups` for this task (Phase 1/8 dependency).

Maps to: PTE task type `FILL_BLANKS_READING_WRITING`.

## Design Constraints

- Uses `parseBlankPrompt` (Phase 2) and `PlaceholderAlignment.middle`, same as Phase 5.
- Uses `TaskView.blankGroups` (Phase 2's `BlankGroup` model), **not** the shared `options` field — each gap's dropdown items come only from `task.blankGroups![gapIndex].options`, never any other gap's list or the top-level `options`.
- **Fallback**: if `task.blankGroups == null || task.blankGroups!.isEmpty`, render the existing `StatusBanner` common widget (`lib/core/widgets/status_banner.dart`) with `AppStrings.fillBlanksContentUnavailableTitle`/`Message` instead of the interactive body — this is expected to be the common case until Phase 1 and Phase 8 both ship to whatever environment this screen is running against, and must degrade gracefully, not crash or blank-screen.
- `FillBlanksDropdownCubit extends TaskAnswerCubit<FillBlanksDropdownState>`; state is a fixed-length `List<String?>` (length = `blankGroups.length`), each discrete `DropdownButton.onChanged` selection is an immediate synchronous outbox write, `flushPendingEdit()` is a no-op.
- Payload = same positional comma-join convention as Phase 5, including the required trailing empty entry for an unanswered final gap.
- Every gap's `DropdownButton` carries a `Semantics` label reflecting current state, per `plan.md`'s accessibility requirement.
- Single scrollable column layout (no `ReadingPassageLayout` split).

## Steps

1. Create `lib/features/exam_attempt/presentation/cubit/fill_blanks_dropdown_state.dart`: `FillBlanksDropdownState { final List<String?> selectedOrderIndexes; }`.
2. Create `lib/features/exam_attempt/presentation/cubit/fill_blanks_dropdown_cubit.dart`: constructor initializes a `List<String?>` of length `blankGroups.length` (all `null`); `selectOption(int gapIndex, String orderIndex)` updates the position, writes `outboxDao.upsertAnswer(payload: positionalJoin(selectedOrderIndexes))` (reuse or mirror Phase 5's positional-join helper — do not reimplement the trailing-empty-entry logic independently if it can be shared).
3. Create `lib/features/exam_attempt/presentation/widgets/fill_blanks_dropdown_body.dart`: `Text.rich` from `parseBlankPrompt`, gap `WidgetSpan`s hold a `DropdownButton<String>` sourced strictly from `task.blankGroups![gapIndex].options`; `Semantics` labels per Design Constraints.
4. Create `lib/features/exam_attempt/presentation/pages/fill_blanks_dropdown_screen.dart`: banner, then either `StatusBanner` fallback (when `blankGroups` is null/empty) or `FillBlanksDropdownBody` (when populated).
5. Edit `task_type_dispatcher.dart`: add `_taskTypeFillBlanksReadingWriting = 'FILL_BLANKS_READING_WRITING'`, switch arm, import.
6. Test: `fill_blanks_dropdown_cubit_test.dart` — positional payload correctness including the trailing-empty-entry case; a dedicated regression test asserting gap N's available options come **only** from `blankGroups[N].options`, never from gap N-1 or N+1's list (guards the "each blank has its own distinct list" requirement, the defining property of this task type vs. Phase 5's shared word bank).
7. Test (widget): each gap renders as an independent `DropdownButton` with its own item list, verified by comparing two different gaps' rendered item sets.
8. Test (widget): the `blankGroups == null` case renders `StatusBanner` with the correct fallback copy, not the interactive body and not a crash — use the Phase 2 fixture (or a variant with `blankGroups: null`) for this case.

## Success Criteria

- [x] Each gap's dropdown offers only that gap's own `BlankGroup.options`, never another gap's or the shared `options` field.
- [x] Positional payload is correct, including the required trailing empty entry.
- [x] `blankGroups == null`/empty renders the `StatusBanner` fallback, not a crash or blank screen.
- [x] Every gap's dropdown carries a `Semantics` label reflecting current state.
- [x] `flutter analyze` and `flutter test` both pass with zero new issues (244/244 passing, up from 233).

**Additions beyond the original Steps list**:
1. Extracted a shared `positionalPayload(List<String?>)` helper (`lib/features/exam_attempt/domain/positional_payload.dart`) and refactored Phase 5's `FillBlanksDragDropCubit` to use it — per this phase's own Step 2 instruction ("reuse or mirror Phase 5's positional-join helper... do not reimplement independently"), a pure extract-method refactor with no behavior change (Phase 5's existing tests still pass unchanged).
2. **UX fix found during implementation**: the original design (StatusBanner-only fallback, no cubit/advance button) would leave a student permanently stuck on this task if `blankGroups` is unavailable — there would be no `TaskAdvanceButton` to move past it. Fixed by always constructing `FillBlanksDropdownCubit` (with `blankGroupCount: 0` in the fallback case) so the advance button is always present, only the body content (interactive dropdowns vs. `StatusBanner`) is conditional. Verified by a dedicated test ("the advance button is still present in the fallback state").

## Quality and Testing State

- Quality gate: approved (0 blocking findings). Report: `pte-app/plans/ninh-pte-reading-task-types/quality/phase-06-fill-blanks-dropdown-quality-report.json`. Receipt issued.
- Testing: PASSED — 5/5 cubit tests (single/multi-gap payload, trailing-empty-entry, re-selection isolation, flushPendingEdit no-op) + 6/6 widget tests (per-gap distinct dropdown items, cross-gap selection isolation, StatusBanner fallback for null/empty blankGroups, advance-button-always-present, populated-content renders body not fallback). Full suite: 244/244 passing.

## Risks

- **MEDIUM**: this is the one task type genuinely blocked from live backend verification until Phase 1 and Phase 8 both ship (per `plan.md`'s Risk section) — the `StatusBanner` fallback and the Phase 2 dev-fixture preview screen are this phase's only verification path until then; do not treat "looks right against the dev fixture" as equivalent to "verified against real backend data" when reporting this phase's completion.
- **LOW**: sharing the positional-join helper with Phase 5 (Step 2) risks a subtle divergence if Phase 5 lands first and this phase's usage doesn't match its exact signature — confirm the helper's location/shape against Phase 5's actual implementation before writing this phase's cubit, don't assume from this plan's description alone.
