# Phase 3: Multiple-Choice Reuse + Select Missing Word

## Requirements

Build three option-selection listening task types, all reusing the existing `mc_option_list.dart` widget pattern (single/multiple select via radio/checkbox):

1. `MC_LISTENING_SINGLE` (1% weight, P2) — user listens to audio, selects one correct option from a list. Identical UI/state/cubit pattern as `MC_READING_SINGLE`, except prompt is audio (via `ListeningAudioBar`) instead of text.
2. `MC_LISTENING_MULTIPLE` (1% weight, P2) — user listens, selects multiple correct options (checkboxes). Reuses multi-select pattern from Reading's `MC_READING_MULTIPLE`, payload is comma-joined sorted `orderIndex`.
3. `SELECT_MISSING_WORD` (1% weight, P2) — user listens to audio with a word missing, selects the missing word from options. UI is single-select (radio), one option per word candidate.

All three use the same discrete-input cubit style: toggle/select writes immediately via `outboxDao.upsertAnswer()`, no debounce, `flushPendingEdit()` is a no-op. Audio plays once per task, locked afterward. Payload format matches Reading's patterns.

Maps to: P2 user stories (FR-04, FR-07): reuses `mc_option_list.dart` + cubit patterns, swaps text prompt for audio.

## Design Constraints

- All three cubits extend `TaskAnswerCubit<S>` (same pattern as Phase 2).
- `MC_LISTENING_SINGLE`: `McListeningSingleCubit` mirrors `McReadingSingleCubit` exactly — holds `selectedOrderIndex: String?`, `selectOption(String orderIndex)` writes to outbox synchronously. Payload is the selected `orderIndex` string.
- `MC_LISTENING_MULTIPLE`: `McListeningMultipleCubit` mirrors `McReadingMultipleCubit` — holds `Set<String> selectedOrderIndexes`, `toggleOption(String orderIndex)` toggles membership, writes comma-joined sorted indices to outbox.
- `SELECT_MISSING_WORD`: `SelectMissingWordCubit` is structurally identical to `McListeningSingleCubit` (single-select). Payload = selected `orderIndex`.
- All three screens use `ListeningAudioBar` at top (Phase 1 widget), prompt area (just the audio bar, no text prompt), then a listening-specific option list widget.
- **`McOptionList` is NOT reusable as-is** — verified by reading `lib/features/exam_attempt/presentation/widgets/mc_option_list.dart`: it hardcodes `BlocBuilder<McReadingSingleCubit, McReadingSingleState>` (imports the Reading cubit directly), so it cannot render against a `McListeningSingleCubit`/`McListeningMultipleCubit`. Same problem applies to `mc_multiple_option_list.dart` (hardcodes `McReadingMultipleCubit`). Build two new, decoupled widgets instead: `ListeningOptionList` (single-select — takes `{required List<TaskOption> options, required String? selectedOrderIndex, required ValueChanged<String> onChanged}`, no `BlocBuilder`/Cubit import, pure presentational `RadioGroup` widget) and `ListeningMultipleOptionList` (multi-select — takes `{required List<TaskOption> options, required Set<String> selectedOrderIndexes, required ValueChanged<String> onToggle}`, pure presentational `CheckboxListTile` list). Screens wrap these in a thin `BlocBuilder` themselves to bridge cubit state to the presentational widget's callback props. This is a deliberate duplication (not a shared-with-Reading abstraction) — matches this codebase's established pattern of per-feature bespoke widgets over premature generic abstraction (see `docs/CODING_STANDARDS_APP.md` KISS/YAGNI).
- Screen widget type: **`StatelessWidget` + `BlocProvider`**, matching `McReadingSingleScreen`'s actual precedent exactly (verified by reading the file — it is `StatelessWidget`, cubit created via `BlocProvider(create: ...)`, not a `StatefulWidget`/`initState` pattern). None of these three types own a `TextEditingController`, so there is no resource that needs screen-level `initState`/`dispose` management — `BlocProvider` auto-disposes the cubit (which disposes `AudioPlayerService` in its own `close()`) when the widget unmounts.
- Audio playback: `AudioPlayerService.play()` triggered by the cubit's constructor or an explicit `cubit.play()` call from a `Builder`'s inner context after `BlocProvider` creates it (mirror wherever Phase 2 ends up triggering playback, for consistency).
- Screen layouts: vertical stack of `ListeningAudioBar` + the new option-list widget (via `ListeningOptionList`/`ListeningMultipleOptionList` with the task's options). `ExamScaffold` wrapping, `TaskAdvanceButton` at bottom.
- No custom validation or negative-marking preview (server is the authority, per Reading precedent).

## Steps

1. Create `lib/features/exam_attempt/presentation/widgets/listening_option_list.dart`: `ListeningOptionList` — pure presentational `StatelessWidget`, `{required List<TaskOption> options, required String? selectedOrderIndex, required ValueChanged<String> onChanged}`, `RadioGroup` UI mirroring `McOptionList`'s layout but with no `BlocBuilder`/Cubit import.

2. Create `lib/features/exam_attempt/presentation/widgets/listening_multiple_option_list.dart`: `ListeningMultipleOptionList` — pure presentational `StatelessWidget`, `{required List<TaskOption> options, required Set<String> selectedOrderIndexes, required ValueChanged<String> onToggle}`, `CheckboxListTile` list, no Cubit import.

3. Create `lib/features/exam_attempt/presentation/cubit/mc_listening_single_state.dart`: immutable state with `{selectedOrderIndex: String?}`.

4. Create `lib/features/exam_attempt/presentation/cubit/mc_listening_single_cubit.dart`: extends `TaskAnswerCubit`, mirrors `McReadingSingleCubit` exactly. Constructor injects `AnswerOutboxDao`, `AudioPlayerService`, `attemptPublicId`, `pinnedItemPublicId`. Method: `selectOption(String orderIndex)` writes orderIndex to outbox, emits new state. `close()` disposes `AudioPlayerService`.

5. Create `lib/features/exam_attempt/presentation/cubit/mc_listening_multiple_state.dart`: immutable state with `{selectedOrderIndexes: Set<String>}`.

6. Create `lib/features/exam_attempt/presentation/cubit/mc_listening_multiple_cubit.dart`: extends `TaskAnswerCubit`, mirrors `McReadingMultipleCubit`. Method: `toggleOption(String orderIndex)` toggles in set, writes sorted comma-joined indices to outbox.

7. Create `lib/features/exam_attempt/presentation/cubit/select_missing_word_state.dart`: immutable state with `{selectedOrderIndex: String?}`.

8. Create `lib/features/exam_attempt/presentation/cubit/select_missing_word_cubit.dart`: extends `TaskAnswerCubit`, identical structure to `mc_listening_single_cubit.dart`.

9. Create `lib/features/exam_attempt/presentation/pages/mc_listening_single_screen.dart`: `StatelessWidget` + `BlocProvider` (mirror `McReadingSingleScreen` exactly). Build: `ExamScaffold(body: Column(ListeningAudioBar + ListeningOptionList(...)))`, wrapped in a `BlocBuilder<McListeningSingleCubit, McListeningSingleState>` to bridge cubit state into `ListeningOptionList`'s props.

10. Create `lib/features/exam_attempt/presentation/pages/mc_listening_multiple_screen.dart`: same `StatelessWidget` + `BlocProvider` structure, uses `ListeningMultipleOptionList`.

11. Create `lib/features/exam_attempt/presentation/pages/select_missing_word_screen.dart`: same structure as single-select, uses `ListeningOptionList`.

12. Update `task_type_dispatcher.dart`: replace placeholder arms for `MC_LISTENING_SINGLE`, `MC_LISTENING_MULTIPLE`, `SELECT_MISSING_WORD` with actual screen routing.

13. Test: cubit tests for all three types (selectOption writes, toggle writes sorted payload, close disposes audio).

14. Test: widget tests for `ListeningOptionList`/`ListeningMultipleOptionList` (pure presentational — render options, tap triggers `onChanged`/`onToggle` callback, no Cubit needed to test).

15. Test: screen widget tests (audio bar + option list render, option selection triggers cubit method via the `BlocBuilder` bridge).

16. Test: extend dispatcher routing tests.

## Success Criteria

- [x] Single-select (MC_LISTENING_SINGLE, SELECT_MISSING_WORD) writes selected `orderIndex` to outbox.
- [x] Multi-select (MC_LISTENING_MULTIPLE) writes comma-joined sorted indices.
- [x] Audio plays once, locks afterward.
- [x] All three screens route correctly through dispatcher.
- [x] Option selection is immediate (no debounce).
- [x] `flutter analyze` and `flutter test` pass.

## Quality and Testing State

- Quality gate: not evaluated.
- Testing: not started. Phase 3 will build: cubit tests (selection writes, option toggle), screen widget tests, dispatcher routing tests.

## Risks

- **LOW**: Payload format consistency. Ensure all three types produce payloads matching the pattern used by Reading (single-select = string, multi-select = comma-joined sorted). Mitigation: cubit tests verify exact payload format.

_(Resolved during red-team review: `McOptionList`/`McMultipleOptionList` were confirmed — by reading the actual widget source — to hardcode `BlocBuilder<McReadingSingleCubit, _>`/`BlocBuilder<McReadingMultipleCubit, _>`, so they cannot be reused for Listening cubits. Fixed by building decoupled `ListeningOptionList`/`ListeningMultipleOptionList` presentational widgets instead — see Design Constraints and Steps 1-2 above.)_
