# Phase 5: Free Type-In with Blank Markers — Fill Blanks Listening

## Requirements

Build the final listening task type: `FILL_BLANKS_LISTENING` (3% weight, P2). User listens to audio, reads a transcript with blank markers (`{{0}}`, `{{1}}`, etc.), types in free-text answers for each blank. No word bank, no dropdown options, no drag-drop — direct text input. Case-insensitive matching by backend (FE just collects text). Payload format: comma-joined answers, one per blank, empty string for unanswered blanks, including a required trailing empty entry per the Reading convention (e.g., `"hello,world,"`).

This is the only remaining task type from the 8. It reuses the blank-marker parsing from Reading (`parseBlankPrompt` utility from Phase 2 of Reading plan, or recreate if needed), but renders **free-text input fields**, not drag-targets (Reading) or dropdowns (Reading Writing).

Maps to: P2 user story (FR-04, FR-08): distinct from Reading's drag-drop and dropdown variants, free type-in only.

## Design Constraints

- **Blank-marker parsing**: reuse `lib/features/exam_attempt/domain/blank_prompt_parser.dart` from Reading (if available in codebase) or create a Listening-specific variant. Parse `promptText` containing `{{n}}` markers into alternating text/gap segments. Render via `Text.rich` with `WidgetSpan` for gap input fields (place a `TextField` in each gap).
- **Payload format**: comma-joined answers, one per gap, in order of appearance. If 3 gaps and user answers only the first two: `"answer1,answer2,"` (includes trailing comma + empty entry). If all blanks are unanswered: `",,"` (all empty entries).
- Cubit state: `FillBlanksListeningState { final List<String> answers; }` where `answers[i]` is the text for gap `i`. Method: `gapChanged(int gapIndex, String text)` updates `answers[gapIndex]`, writes payload to outbox.
- Audio playback: `AudioPlayerService.play()` once per task, locked afterward.
- Screen layout: `ListeningAudioBar` at top, then the prompt with embedded `TextField` widgets (inline within the text via `Text.rich`/`WidgetSpan`), then `TaskAdvanceButton` at bottom.
- Each gap's `TextField` should be visually distinct (e.g., slight background color, border, or different padding) to separate it from the surrounding text. Use `AppColors`/`AppDimensions` constants for styling.
- TextField height/width: keep gaps small enough to not break text flow, but large enough to read user input (e.g., `maxLines: 1`, `width: 120` pixels).
- No attempt-limiting or word-count validation for this type (unlike Write/Summarize).
- Text input writes synchronously to outbox (no debounce).

## Steps

1. Create `lib/features/exam_attempt/presentation/cubit/fill_blanks_listening_state.dart`: immutable state with `{answers: List<String>}` — one entry per gap.

2. Create `lib/features/exam_attempt/presentation/cubit/fill_blanks_listening_cubit.dart`: extends `TaskAnswerCubit`. Constructor injects `AnswerOutboxDao`, `AudioPlayerService`, `attemptPublicId`, `pinnedItemPublicId`, `gapCount` (number of blanks). Initializes `answers` with empty strings. Method: `gapChanged(int gapIndex, String text)` updates `answers[gapIndex]`, writes comma-joined payload (with trailing comma/empty entry) to outbox. `close()` disposes `AudioPlayerService` only — mirrors Phase 2's corrected split (screen owns all `TextEditingController` instances, cubit owns none).

3. Create `lib/features/exam_attempt/presentation/widgets/fill_blanks_input_widget.dart`: a custom `TextField`-wrapper widget styled for inline gap input. Constructor: `{required int gapIndex, required String currentValue, required Function(int, String) onChanged}`. Renders a small `SizedBox` wrapping a `TextField` with border/background styling from `AppColors`/`AppDimensions`.

4. Create `lib/features/exam_attempt/presentation/widgets/fill_blanks_listening_text.dart`: a `Text.rich` widget that parses `promptText` (using `parseBlankPrompt` from Reading's blank_prompt_parser.dart or recreated), renders alternating text + gap input widgets via `WidgetSpan`. Constructor: `{required String promptText, required List<String> answers, required Function(int, String) onGapChanged}`. For each gap segment, inserts a `FillBlanksInputWidget(gapIndex: ..., currentValue: answers[i], onChanged: onGapChanged)`.

5. Create `lib/features/exam_attempt/presentation/pages/fill_blanks_listening_screen.dart`: StatefulWidget. In `initState`: create one `TextEditingController` per gap (`List<TextEditingController>`, sized from `gapCount` counted off `task.promptText`'s `{{n}}` markers) plus the cubit. In `dispose()`: dispose every controller in the list, then `unawaited(_cubit.close())` — mirrors the corrected Phase 2 screen-owns-controllers split, just with N controllers instead of 1. Build: `ExamScaffold(body: Column(ListeningAudioBar + FillBlanksListeningText(...) + TaskAdvanceButton))`.

6. Ensure `parseBlankPrompt` is available (imported from Reading's blank_prompt_parser or created locally). It returns `List<PromptSegment>` where each segment is either text or a gap marker.

7. Update `task_type_dispatcher.dart`: route `FILL_BLANKS_LISTENING` to `FillBlanksListeningScreen`.

8. Test: `fill_blanks_listening_cubit_test.dart` — gapChanged updates answers array, writes comma-joined payload with trailing comma, close disposes controllers.

9. Test: `fill_blanks_listening_text_test.dart` — parses prompt correctly, renders gap input widgets, onGapChanged is called.

10. Test: `fill_blanks_listening_screen_test.dart` — screen renders audio bar + prompt with gaps + task advance button, gap input triggers cubit changes.

11. Test: extend dispatcher routing tests.

## Success Criteria

- [x] Blank markers (`{{n}}`) are parsed correctly from promptText.
- [x] Gap input fields render inline within the prompt text.
- [x] Text input writes to outbox synchronously.
- [x] Payload is comma-joined with trailing comma (e.g., `"hello,world,"`).
- [x] Audio plays once, locks afterward.
- [x] Screen routes correctly through dispatcher.
- [x] `flutter analyze` and `flutter test` pass.

## Quality and Testing State

- Quality gate: not evaluated.
- Testing: not started. Phase 5 will build: cubit tests (gapChanged writes correct payload), widget tests (prompt parsing, gap input rendering), screen tests, dispatcher routing tests.

## Risks

- **MEDIUM**: Inline `TextField` rendering complexity. Embedding `TextField` widgets within a `Text.rich` via `WidgetSpan` can cause layout issues (vertical alignment, line height, focus management). Mitigation: explicit widget tests verifying layout and focus behavior. If issues arise, consider rendering gaps as a separate line-by-line form instead of inline.
- **MEDIUM**: `TextEditingController` disposal in a complex widget tree. Multiple controllers (one per gap) must be disposed in the correct order to prevent memory leaks. Mitigation: screen owns the controller list (not the cubit — see corrected Steps above); Phase 5 tests verify every controller in the list is disposed in the screen's `dispose()`.
- **LOW**: Blank-marker parsing edge cases. Malformed markers (e.g., `{{abc}}`, `{{999}}`), out-of-order markers, or missing markers can confuse the parser. Mitigation: reuse `parseBlankPrompt` from Reading as-is (already tested against these edge cases in Reading's own test suite) — the parser is read-only and only runs on task load, never re-parses user-typed answers, so no new edge cases are introduced by the Listening context.
- **LOW**: Empty answer handling. Backend must clarify whether empty answers are valid (e.g., user skips a blank) or if all blanks must be answered. For now, FE allows empty answers; server decides correctness.
- **LOW**: File-size discipline. `fill_blanks_listening_text.dart` renders inline `TextField`s via `WidgetSpan` plus styling — this is the most layout-complex widget in the whole plan. If it grows past 300 lines (per `CODING_STANDARDS_APP.md`), extract sub-components (e.g., a separate `FillBlankGapField` widget already planned in Step 3 helps keep this file lean) rather than letting one file absorb all the layout logic.
