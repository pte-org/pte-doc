# Phase 4: Frontend `RE_ORDER_PARAGRAPHS`

## Requirements

Build the paragraph-reorder Reading screen: a set of server-shuffled paragraph blocks the student drags into what they believe is the correct order.

Maps to: PTE task type `RE_ORDER_PARAGRAPHS`.

## Design Constraints

- Uses the existing `List<TaskOption>? options` field (per Phase 2/`plan.md`'s reuse decision) — `TaskOption.text` is a full paragraph's text, `TaskOption.orderIndex` is its **stable correct-position identity**, never its current on-screen position. This is the one place identity-vs-position confusion is easiest to introduce; every reference to a paragraph's "position" in this phase's code must be unambiguous about which one it means.
- `ReOrderParagraphsCubit extends TaskAnswerCubit<ReOrderParagraphsState>`; initial state is seeded directly from `task.options` in the server-delivered (shuffled) order — never re-sorted by `orderIndex` at load time, or the task becomes trivial.
- Each `reorder(oldIndex, newIndex)` call is a discrete drop event → immediate synchronous outbox write, `flushPendingEdit()` is a no-op, matching every other new cubit in this plan.
- Payload = comma-joined `orderIndex` values in the student's **current** list order — the sequence itself is the answer, not a separate index-to-position mapping.
- Uses a single scrollable column layout (no `ReadingPassageLayout` split) — there's no separate "options pane" distinct from the reorderable list itself; this is a documented exception to the split-pane pattern, not an oversight.
- Every paragraph tile gets a `Semantics` label reflecting its current position (e.g. `"Paragraph, position 2 of 4, draggable"`), per `plan.md`'s accessibility requirement.

## Steps

1. Create `lib/features/exam_attempt/presentation/cubit/re_order_paragraphs_state.dart`: `ReOrderParagraphsState { final List<TaskOption> currentOrder; }`.
2. Create `lib/features/exam_attempt/presentation/cubit/re_order_paragraphs_cubit.dart`: constructor seeds `currentOrder` from `task.options`; `reorder(int oldIndex, int newIndex)` mutates the list, then writes `outboxDao.upsertAnswer(payload: currentOrder.map((o) => o.orderIndex).join(','))`.
3. Create `lib/features/exam_attempt/presentation/widgets/re_order_paragraphs_list.dart`: `ReorderableListView`, items keyed `ValueKey(option.orderIndex)` (identity, not position), each item wrapped in a `Semantics` label per the Design Constraints.
4. Create `lib/features/exam_attempt/presentation/pages/re_order_paragraphs_screen.dart`: banner + single-pane scroll containing `ReOrderParagraphsList`.
5. Edit `task_type_dispatcher.dart`: add `_taskTypeReOrderParagraphs = 'RE_ORDER_PARAGRAPHS'`, switch arm, import.
6. Test: `re_order_paragraphs_cubit_test.dart` — initial state matches the server-shuffled order exactly (not re-sorted); a reorder call writes the correct identity-`orderIndex` sequence, not list-position values (explicit "not the list position" assertion, mirroring the existing `mc_reading_single_cubit_test.dart` pattern); multiple sequential reorders each independently produce the correct payload.
7. Test: a widget test simulating a drag reorder (`tester.drag` on `ReorderableListView`) and asserting the resulting cubit state/payload matches the new visual order.

## Success Criteria

- [ ] Initial paragraph order matches the server-shuffled `task.options` order exactly, never re-sorted client-side.
- [ ] A reorder writes the correct sequence of stable identities, verified against a case where identity and position diverge.
- [ ] `flushPendingEdit()` is a verified no-op.
- [ ] Every paragraph tile carries a `Semantics` label reflecting its current position.
- [ ] `flutter analyze` and `flutter test` both pass with zero new issues.

## Quality and Testing State

- Quality gate: not started.
- Testing: not started.

## Risks

- **MEDIUM**: this task type has the highest identity-vs-position confusion risk in the whole plan (per `plan.md`'s Design Decision 2) — the cubit test's explicit "not the list position" assertion (Step 6) is the primary defense and must not be weakened to a looser "some payload was written" check.
