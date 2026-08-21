# Phase 5: Frontend `FILL_BLANKS_READING` (Drag & Drop)

## Requirements

Build the drag-and-drop fill-in-the-blanks Reading screen: a passage with inline gap boxes, and a shared word bank below containing more words than there are gaps (distractors). Students drag a word into a gap; a placed word can be dragged back out to undo.

Maps to: PTE task type `FILL_BLANKS_READING`.

## Design Constraints

- Uses `parseBlankPrompt` (Phase 2) to split `promptText` on `{{n}}` markers into a `Text.rich` tree; every gap `WidgetSpan` uses `PlaceholderAlignment.middle` (Phase 2's Design Constraint, applies here directly).
- Uses the existing `List<TaskOption>? options` field as the shared word bank (Phase 2/`plan.md` reuse decision) — `TaskOption.text` is the word, `orderIndex` its stable identity.
- `FillBlanksDragDropCubit extends TaskAnswerCubit<FillBlanksDragDropState>`; every drop/undo is a discrete event → immediate synchronous outbox write, `flushPendingEdit()` is a no-op.
- Payload = positional comma-join, one entry per gap in gap-index order, each entry the assigned word's `orderIndex`, empty entry for an unfilled gap — **including a required trailing empty entry** if the last gap is unanswered (e.g. `"2,0,"` not `"2,0"`), so backend positional parsing never misaligns. This is the single most error-prone part of this phase and must have a dedicated regression test (Step 9).
- Word-bank chips (`Draggable<TaskOption>`) must always render filtered from `task.options`' **original** order (`task.options.where((o) => !gapAssignments.values.contains(o))`), never from a separately mutated/re-appended list — an undone chip must reappear at its original bank position, not jump to the end.
- `DragTarget<TaskOption>` gap widgets use the `builder: (context, candidateData, rejectedData)` callback to switch background color to `AppColors.dragTargetHoverBackground` while a compatible chip hovers — required behavior, not polish.
- Reassigning an already-placed option to a different gap must clear its previous gap first (no option occupies two gaps simultaneously).
- Every gap and chip carries a `Semantics` label reflecting current state (e.g. `"Gap 1, empty"` / `"Gap 1, filled with 'mattered'"`), per `plan.md`'s accessibility requirement.
- Single scrollable column layout (no `ReadingPassageLayout` split) — the word bank sits below the passage as a fixed/pinned strip.

## Steps

1. Create `lib/features/exam_attempt/presentation/cubit/fill_blanks_drag_drop_state.dart`: `FillBlanksDragDropState { final Map<int, TaskOption> gapAssignments; }`.
2. Create `lib/features/exam_attempt/presentation/cubit/fill_blanks_drag_drop_cubit.dart`: `assignToGap(int gapIndex, TaskOption option)` (clears any other gap currently holding this option first, then assigns), `clearGap(int gapIndex)`; both write `outboxDao.upsertAnswer(payload: positionalJoin(gapCount, gapAssignments))` where the positional-join helper emits an empty entry (including trailing) for every unassigned gap index.
3. Create `lib/features/exam_attempt/presentation/widgets/fill_blanks_drag_drop_body.dart`: `Text.rich` from `parseBlankPrompt`; gap `WidgetSpan`s hold `DragTarget<TaskOption>` with hover-highlight; below, a `Wrap` of `Draggable<TaskOption>` bank chips filtered/ordered per the Design Constraints, itself wrapped in a bank-level `DragTarget<TaskOption>` that calls `clearGap` for a chip dragged back from a gap; filled gap slots are also `Draggable<TaskOption>` sources so a placed word can move directly to another gap or back to the bank.
4. Create `lib/features/exam_attempt/presentation/pages/fill_blanks_drag_drop_screen.dart`: banner + single-pane scroll containing `FillBlanksDragDropBody`.
5. Edit `task_type_dispatcher.dart`: add `_taskTypeFillBlanksReading = 'FILL_BLANKS_READING'`, switch arm, import.
6. Test: `fill_blanks_drag_drop_cubit_test.dart` — single-gap and multi-gap positional payload correctness; reassigning an option clears its old gap first (no duplicate assignment); `clearGap` produces the correct empty entry at that position.
7. Test: explicit regression test for the unanswered-**trailing**-gap empty-entry requirement (a 3-gap task with only gap 0 and 1 filled must write `"2,0,"`, not `"2,0"`).
8. Test (widget): dragging a bank chip into a gap updates the gap's visible content and removes the chip from the bank; dragging a filled gap's word back onto the bank area clears the gap and restores the chip.
9. Test (widget): the hover-highlight color changes while a compatible candidate is over a gap (via `DragTarget`'s `candidateData`).
10. Test (widget): bank chip order is stable — place a chip, undo it (drag back to bank), assert the bank's chip order is unchanged from its initial order, not appended to the end.

## Success Criteria

- [ ] Positional payload is correct for single- and multi-gap cases, including the required trailing empty entry.
- [ ] Reassigning an option never results in it occupying two gaps at once.
- [ ] Word-bank chip order is stable across place/undo cycles.
- [ ] `DragTarget` gaps visibly highlight while a compatible chip hovers.
- [ ] Every gap/chip carries a `Semantics` label reflecting current state.
- [ ] `flutter analyze` and `flutter test` both pass with zero new issues.

## Quality and Testing State

- Quality gate: not started.
- Testing: not started.

## Risks

- **HIGH**: the trailing-empty-entry payload requirement (Design Constraint 4) is the single easiest correctness bug to introduce silently in this entire plan — Step 7's dedicated regression test is non-negotiable and must assert on the literal string length/shape, not just "some payload was written."
- **LOW**: `Draggable`/`DragTarget` widget-test simulation in Flutter can be finicky for complex nested drag scenarios (gap-to-gap, gap-to-bank) — if a given interaction proves unreliable to simulate in a widget test, fall back to testing the cubit-level state transition directly and note the visual-only verification gap explicitly in this phase's Quality and Testing State, rather than silently skipping coverage.
