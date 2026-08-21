# Phase 3: Frontend `MC_READING_MULTIPLE`

## Requirements

Build the checkbox multi-select Reading screen: a passage plus a question with more than one correct answer allowed. The UI itself performs no scoring/negative-marking logic (that's server-side, per `plan.md`'s Research Summary) — it only needs to allow multi-select and write the correct payload shape.

Maps to: PTE task type `MC_READING_MULTIPLE`.

## Design Constraints

- Mirrors `McReadingSingleCubit`/`McReadingSingleScreen` structurally (per Phase 2's infra): `BlocProvider` creating the cubit in the screen widget, `ExamScaffold(body: ReadingTaskHeaderBanner + ReadingPassageLayout(...), bottomAction: TaskAdvanceButton(...))`.
- `McReadingMultipleCubit extends TaskAnswerCubit<McReadingMultipleState>`; `flushPendingEdit()` is an intentional no-op — every toggle writes to the outbox synchronously, per `plan.md`'s "all 4 new types are discrete-selection style" decision.
- Payload = comma-joined selected `orderIndex`, **numerically sorted ascending** regardless of toggle order (e.g. toggling `"2"` then `"0"` still writes `"0,2"`, not `"2,0"`) — this is the one payload-shape property most likely to regress if written insertion-ordered instead of sorted.
- Untoggling every option must write payload `""`, not omit the write — the outbox row must reflect "answered, currently empty" the same way any other state change does.
- Do not implement any client-side "select N of M" validation or negative-marking preview — the server is the sole authority on correctness, consistent with `WRITE_ESSAY`'s existing non-gating word-count pattern.

## Steps

1. Create `lib/features/exam_attempt/presentation/cubit/mc_reading_multiple_state.dart`: `McReadingMultipleState { final Set<String> selectedOrderIndexes; }` (Equatable).
2. Create `lib/features/exam_attempt/presentation/cubit/mc_reading_multiple_cubit.dart`: `toggleOption(String orderIndex)` toggles membership in the set, then writes `outboxDao.upsertAnswer(payload: (selectedOrderIndexes.toList()..sort((a,b) => int.parse(a).compareTo(int.parse(b)))).join(','))`.
3. Create `lib/features/exam_attempt/presentation/widgets/mc_multiple_option_list.dart`: `CheckboxListTile` per `TaskOption`, `BlocBuilder`/`BlocSelector` wired to `toggleOption`.
4. Create `lib/features/exam_attempt/presentation/pages/mc_reading_multiple_screen.dart`: banner + `ReadingPassageLayout(passage: Text(task.promptText ?? ''), interactive: McMultipleOptionList(...))`.
5. Edit `lib/features/exam_attempt/presentation/widgets/task_type_dispatcher.dart`: add `_taskTypeMcReadingMultiple = 'MC_READING_MULTIPLE'`, a new switch arm, and the screen import.
6. Test: `mc_reading_multiple_cubit_test.dart` — toggling `"0"` then `"2"` then `"3"` writes `"0,2,3"`; untoggling `"2"` afterward writes `"0,3"`; untoggling everything writes `""`; `flushPendingEdit()` never calls the outbox (`verifyNever`).
7. Test: extend `task_type_dispatcher_test.dart` with an `MC_READING_MULTIPLE` case (ValueKey teardown + correct screen selected, mirroring the existing `MC_READING_SINGLE` case).

## Success Criteria

- [x] Selecting multiple checkboxes writes a sorted, comma-joined `orderIndex` payload regardless of click order.
- [x] Deselecting all options writes an empty-string payload, not a missing/omitted write.
- [x] `flushPendingEdit()` is a verified no-op.
- [x] `TaskTypeDispatcher` correctly routes `MC_READING_MULTIPLE` to the new screen.
- [x] `flutter analyze` and `flutter test` both pass with zero new issues (214/214 passing, up from 206).

## Quality and Testing State

- Quality gate: approved (0 blocking findings). Report: `pte-app/plans/ninh-pte-reading-task-types/quality/phase-03-mc-reading-multiple-quality-report.json`. Receipt issued.
- Testing: PASSED — 6/6 new cubit tests (`mc_reading_multiple_cubit_test.dart`, including reverse-toggle-order and untoggle-to-empty cases) + 2/2 new dispatcher routing tests. Full suite: 214/214 passing.

## Risks

- **LOW**: `Set<String>` iteration order is unspecified in Dart — the explicit numeric sort at write time is the only thing preventing a nondeterministic payload; the cubit test in Step 6 is the primary defense against this regressing silently.
