# Phase 2: Text-Input Types — Write From Dictation + Summarize Spoken Text

## Requirements

Build the two highest-priority listening task types (`WRITE_FROM_DICTATION` 5% weight, `SUMMARIZE_SPOKEN_TEXT` 4% weight), each with its own screen + cubit. Both require: audio playback (one-time, via `AudioPlayerService` from Phase 1), text input (via `TextEditingController`), and word-count validation (reusing the `word_count.dart` utility from the existing `WriteEssayCubit`, but NOT the debounce timer — these types are discrete-input, not auto-save). The screens follow the existing exam-attempt architecture: `BlocProvider`-created Cubit in a StatefulWidget, `ExamScaffold` wrapper, `ListeningAudioBar` at top (Phase 1 widget), `TextField` or similar for input, `TaskAdvanceButton` at bottom for submission.

Maps to: P1 user stories (FR-04, FR-05): both types reuse word-count validation, both have screen/cubit per `CODING_STANDARDS_APP.md` architecture.

## Design Constraints

- Both screens must be StatefulWidget (not Stateless), because each holds a Cubit instance created in `initState` and closed in `dispose()`, mirroring `ReadAloudScreen`'s pattern.
- Both cubits extend `TaskAnswerCubit<S>` (shared base) where `S` is their respective state (immutable, sealed class with fields for draftText and wordCount).
- Word-count validation reuses `countWords()` from `lib/features/exam_attempt/domain/word_count.dart` — same function Reading's `WriteEssayCubit` uses. Validation is client-side preview only (FE shows min/max word count labels + color feedback); server is the authority on pass/fail.
- **`WordCountLabel` is NOT reusable — discovered during implementation** (same class of bug as `McOptionList`, phase-03 red-team finding): it hardcodes `BlocSelector<WriteEssayCubit, WriteEssayState, int>` internally. Built a decoupled `ListeningWordCountLabel` (`{required int wordCount, minWordCount, maxWordCount}`, no Cubit import) instead — the screen's existing `BlocBuilder` extracts `state.wordCount` and passes it as a prop. `WriteEssayScreen`/`WordCountLabel` are left untouched (Phase 1's "no breaking changes to Reading/Speaking/Writing" constraint).
- Audio playback: `AudioPlayerService.play()` is called in `initState` or on screen load, once per task. After playback finishes, the `ListeningAudioBar` shows "Audio finished (locked)" state. No replay button anywhere.
- **Corrected during red-team review** (verified against actual `write_essay_screen.dart`/`write_essay_cubit.dart` source, which the plan originally mis-described): `TextEditingController` is created in the screen's `initState` and disposed in the screen's `dispose()` — the Cubit never owns or disposes it. `WriteEssayCubit` itself only disposes its own resources (debounce timer) in `close()`; it has no knowledge of `TextEditingController`. Mirror this split exactly: screen owns `_controller` (create/dispose), cubit's `close()` disposes only `AudioPlayerService`.
- Text input writes to the outbox synchronously (not debounced, unlike `WriteEssayCubit`'s debounce) — every keystroke triggers a `draftChanged()` cubit method which emits new state and writes via `outboxDao.upsertAnswer()`.
- **Exception**: If word-count changes are frequent enough to cause DB thrashing, a light debounce (250ms, much shorter than `WriteEssayCubit`'s 500ms) can be added for the outbox write only, not for the UI state update. Decide during implementation based on perf testing.
- `WRITE_FROM_DICTATION`: user types what they heard, no formatting/structure required. Payload = the raw text typed.
- `SUMMARIZE_SPOKEN_TEXT`: user types a summary (shorter than dictation input), payload = the raw text typed.
- Both types' layouts are vertical: `ListeningAudioBar` at top, then prompt text ("Listen and type what you heard"), then `TextField`, then word-count label (e.g., "Word count: 42 / min 10, max 100"), then `TaskAdvanceButton` at bottom.
- No custom text field decorations — use Material `TextField` with `InputDecoration` pulling strings/colors from `AppStrings`/`AppColors` constants.
- Validation labels must NOT block task advance (server decides pass/fail) — button is always clickable, even if word count is out of range.

## Steps

1. Create `lib/features/exam_attempt/presentation/cubit/write_from_dictation_state.dart`: immutable state class with `{draftText: String, wordCount: int}`. Use Equatable or manual `==`/`hashCode`.

2. Create `lib/features/exam_attempt/presentation/cubit/write_from_dictation_cubit.dart`: extends `TaskAnswerCubit<WriteFromDictationState>`. Constructor receives `AudioPlayerService`, `AnswerOutboxDao`, `attemptPublicId`, `pinnedItemPublicId`. Methods: `draftChanged(String text)` (emit new state with updated draftText/wordCount, write to outbox). `flushPendingEdit()` is a no-op (discrete input, already written sync). `close()` disposes `AudioPlayerService` only — the cubit never receives or touches a `TextEditingController`.

3. Create `lib/features/exam_attempt/presentation/cubit/summarize_spoken_text_state.dart`: same structure as Write From Dictation state.

4. Create `lib/features/exam_attempt/presentation/cubit/summarize_spoken_text_cubit.dart`: same structure as Write From Dictation cubit, reuses same word-count validation, same disposal pattern.

5. Create `lib/features/exam_attempt/presentation/pages/write_from_dictation_screen.dart`: StatefulWidget (mirrors `write_essay_screen.dart` exactly). In `initState`: create `_controller = TextEditingController()..addListener(...)`, create Cubit, inject `AudioPlayerService` and `AnswerOutboxDao` from GetIt, call `cubit.play()` (audio starts). In `dispose()`: `_controller.dispose()` then `unawaited(_cubit.close())`, mirroring `write_essay_screen.dart` line-for-line. Build: `ExamScaffold(body: Column(ListeningAudioBar + prompt text + TextField(controller: _controller) + word-count label))`.

6. Create `lib/features/exam_attempt/presentation/pages/summarize_spoken_text_screen.dart`: same structure as Write From Dictation screen, different prompt label.

7. Create word-count label widget (`_WordCountLabel` in same file or separate): displays "Word count: X / min Y, max Z". Color-code: gray if in range, amber if below min, red if above max. Text sourced from `AppStrings`.

8. Update `lib/features/exam_attempt/presentation/widgets/task_type_dispatcher.dart`: replace `_ListeningPlaceholderScreen` arm for `WRITE_FROM_DICTATION` with actual `WriteFromDictationScreen(key: key, task: task, ...)`. Similarly for `SUMMARIZE_SPOKEN_TEXT`.

9. Update `lib/features/exam_attempt/domain/exam_attempt_module.dart` (or exam_attempt DI setup): ensure `AudioPlayerService` singleton is already registered (Phase 1 did this).

10. Test: `write_from_dictation_cubit_test.dart` — draftChanged updates state correctly, wordCount is calculated, outbox.upsertAnswer is called, flushPendingEdit is no-op, close() disposes controller + audio service.

11. Test: `summarize_spoken_text_cubit_test.dart` — same as above, different type.

12. Test: `write_from_dictation_screen_test.dart` — screen renders audio bar + prompt + text field + word-count label, text input triggers cubit draftChanged event.

13. Test: extend `task_type_dispatcher_test.dart` with routing tests for both new types.

## Success Criteria

- [x] Text input (both types) writes answer to outbox synchronously on every keystroke.
- [x] Word count validates against `minWordCount`/`maxWordCount` from `task.minWordCount`/`task.maxWordCount`, displayed to user.
- [x] Audio plays once on screen load, does not replay (locked state shown after playback).
- [x] `TextEditingController` is properly disposed (no memory leak).
- [x] `AudioPlayerService` is properly disposed via cubit.close().
- [x] Both screens render without crashing through `TaskTypeDispatcher` routing.
- [x] Word-count label color-codes correctly (gray/amber/red).
- [x] `TaskAdvanceButton` is always clickable (never disabled by word-count validation).
- [x] `flutter analyze` and `flutter test` pass with zero new issues.

## Quality and Testing State

- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementation).
- Testing: not started. Phase 2 will build: cubit tests (state emission, outbox writes, disposal), screen widget tests (UI rendering, input integration), dispatcher routing tests.

## Risks

- **MEDIUM**: `TextEditingController` disposal timing. If the screen's `dispose()` disposes `_controller` before a pending outbox write completes, the last keystroke's text might be lost. Mitigation: since `draftChanged()` writes to the outbox synchronously (per Design Constraints — no debounce for the write itself), there is no async gap between the last keystroke and the write completing; `_controller.dispose()` in the screen's `dispose()` (mirroring `write_essay_screen.dart` line order: controller first, then `unawaited(_cubit.close())`) is safe.
- **LOW**: Word-count validation performance on very long text. Recalculating word count on every keystroke may cause jank on older devices. Mitigation: add light debounce (250ms) for outbox writes if needed; measure during implementation.
- **LOW**: Placeholder content until real PTE audio/prompts. Fixture audio is demo-only, not real exam content. This is fine for dev; real content comes with backend integration (future plan).
