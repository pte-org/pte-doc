# Phase 4: Click-to-Toggle Word/Text Selection

## Requirements

Build the two novel selection-style listening task types, both requiring a new UI interaction pattern (click-to-toggle) not present in prior Reading/Speaking/Writing tasks:

1. `HIGHLIGHT_INCORRECT_WORDS` (4% weight, P1) — user listens to audio, reads a transcript, clicks individual words to toggle selection (mark as "incorrect"). Selected words are highlighted. Cubit state holds `Set<int> selectedWordIndices`, toggle on tap, no selection limit. Payload = comma-joined sorted word indices (e.g., `"1,5,7"`).

2. `HIGHLIGHT_CORRECT_SUMMARY` (< 1% weight, P2) — user listens to audio, then picks the ONE paragraph/option that correctly summarizes it. **Corrected during red-team review**: real PTE format is single-answer (pick the one correct summary, not "toggle multiple as correct") — this is structurally identical to `MC_LISTENING_SINGLE` from Phase 3, just with a paragraph-length option list instead of short choices. Reuses Phase 3's `ListeningOptionList` widget directly (no new toggle/checkbox widget). Payload = the single selected `orderIndex` string.

`HIGHLIGHT_INCORRECT_WORDS` requires a genuinely new custom widget (`Wrap`-based tappable word list). `HIGHLIGHT_CORRECT_SUMMARY` requires no new widget — it reuses Phase 3's `ListeningOptionList`. Audio plays once per task via `ListeningAudioBar`. Discrete-input cubits (sync writes, no debounce).

Maps to: P1/P2 user stories (FR-04, FR-06, FR-07): novel word-selection UI for Incorrect Words; single-select reuse for Correct Summary.

## Design Constraints

- `HIGHLIGHT_INCORRECT_WORDS` UI: parse `task.promptText` into individual words (split on whitespace), render each word as a tappable `GestureDetector` or `InkWell` wrapping a `Text` widget, group words via `Wrap` for line-wrapping layout. Each word gets a `ValueKey<int>(wordIndex)` for stable re-render. Selected words are highlighted (background color from `AppColors`, or text color, or border — design choice, use AppColors constants).
- Word-index assignment: words are indexed 0, 1, 2, ... in order of appearance in `promptText`. Index must be stable and independent of line-wrapping. Regex split on `\s+` (whitespace) to extract words; punctuation is included in the word (e.g., "wonderful." is word index N, not separate from a period).
- `HIGHLIGHT_CORRECT_SUMMARY` UI: single-select, reuse Phase 3's `ListeningOptionList` widget as-is with `task.options` (each option is a full paragraph of text — `ListeningOptionList`'s `RadioListTile`-per-option layout already handles multi-line option text). Screen widget type and cubit shape mirror `McListeningSingleCubit`/`mc_listening_single_screen.dart` from Phase 3, not a new pattern.
- Cubits: `HighlightIncorrectWordsCubit` holds `Set<int> selectedWordIndices`, method `toggleWord(int wordIndex)` toggles membership, writes comma-joined sorted indices to outbox. `HighlightCorrectSummaryCubit` is single-select — holds `selectedOrderIndex: String?`, method `selectOption(String orderIndex)`, writes the single orderIndex to outbox (structurally identical to `McListeningSingleCubit` from Phase 3).
- Audio playback: `AudioPlayerService.play()` triggered on cubit creation, locked afterward. Disposal in cubit's `close()`.
- Screen widget type: `HighlightIncorrectWordsScreen` is `StatelessWidget` + `BlocProvider` (no `TextEditingController`, same reasoning as Phase 3 — `BlocProvider` auto-disposes the cubit on unmount). `HighlightCorrectSummaryScreen` likewise `StatelessWidget` + `BlocProvider`, mirroring `mc_listening_single_screen.dart` almost exactly.
- Screen layouts: `ListeningAudioBar` at top, then the word `Wrap` (Incorrect Words) or `ListeningOptionList` (Correct Summary), then `TaskAdvanceButton` at bottom.
- No client-side validation or correctness checking (server decides).

## Steps

1. Create a helper function/utility to parse `promptText` into words: `List<String> parseWordsFromTranscript(String text)` in `lib/features/exam_attempt/domain/` (or inline in the cubit). Splits on whitespace, preserves punctuation as part of each word.

2. Create `lib/features/exam_attempt/presentation/widgets/word_selection_list.dart`: `WordSelectionList` StatelessWidget. Constructor: `{required List<String> words, required Set<int> selectedIndices, required Function(int) onToggle}`. Renders `Wrap` of tappable word widgets. Each word is `GestureDetector` → `Container` (background color based on selected state) → `Text(word)`. On tap: calls `onToggle(wordIndex)`.

3. Create `lib/features/exam_attempt/presentation/cubit/highlight_incorrect_words_state.dart`: immutable state with `{selectedWordIndices: Set<int>}`.

4. Create `lib/features/exam_attempt/presentation/cubit/highlight_incorrect_words_cubit.dart`: extends `TaskAnswerCubit`. Constructor injects `AnswerOutboxDao`, `AudioPlayerService`, `attemptPublicId`, `pinnedItemPublicId`. Method: `toggleWord(int wordIndex)` toggles in set, writes comma-joined sorted indices (e.g., `"1,5,7"`) to outbox. `close()` disposes audio service.

5. Create `lib/features/exam_attempt/presentation/pages/highlight_incorrect_words_screen.dart`: `StatelessWidget` + `BlocProvider` (mirror `mc_listening_single_screen.dart`'s structure from Phase 3, not a StatefulWidget). Build: parse words from `task.promptText`, render `ExamScaffold(body: Column(ListeningAudioBar + WordSelectionList(words: ..., selectedIndices: ..., onToggle: cubit.toggleWord) + TaskAdvanceButton))` inside a `BlocBuilder`.

6. Create `lib/features/exam_attempt/presentation/cubit/highlight_correct_summary_state.dart`: immutable state with `{selectedOrderIndex: String?}` — single-select, mirrors `mc_listening_single_state.dart` from Phase 3.

7. Create `lib/features/exam_attempt/presentation/cubit/highlight_correct_summary_cubit.dart`: extends `TaskAnswerCubit`. Method: `selectOption(String orderIndex)` writes the selected orderIndex to outbox (same pattern as `McListeningSingleCubit` from Phase 3 — copy its structure, do not build a Set-based toggle cubit).

8. Create `lib/features/exam_attempt/presentation/pages/highlight_correct_summary_screen.dart`: `StatelessWidget` + `BlocProvider`, near-identical to `mc_listening_single_screen.dart` from Phase 3 — reuses `ListeningOptionList` with `task.options`. Build: `ExamScaffold(body: Column(ListeningAudioBar + ListeningOptionList(...) + TaskAdvanceButton))`.

9. Update `task_type_dispatcher.dart`: route both new types to their screens.

10. Test: `highlight_incorrect_words_cubit_test.dart` — toggleWord updates state, toggles in/out of set, writes sorted comma-joined indices to outbox, close disposes.

11. Test: `word_selection_list_test.dart` — renders all words, taps call onToggle, selected words have highlighting.

12. Test: `highlight_correct_summary_cubit_test.dart` — selectOption writes the single orderIndex to outbox, mirrors `mc_listening_single_cubit_test.dart` from Phase 3.

13. Test: screen widget tests.

14. Test: extend dispatcher routing tests.

## Success Criteria

- [x] Word indices are stable (based on split order, not visual position).
- [x] Word selection toggles correctly (tap = toggle in set).
- [x] Payload is comma-joined sorted word indices (e.g., `"1,5,7"`).
- [x] Selected words are visually highlighted.
- [x] Audio plays once, locks afterward.
- [x] Option selection works for Correct Summary (single `orderIndex` string — same payload shape as `MC_LISTENING_SINGLE`, not comma-joined).
- [x] Both screens route correctly through dispatcher.
- [x] `flutter analyze` and `flutter test` pass.

## Quality and Testing State

- Quality gate: not evaluated.
- Testing: not started. Phase 4 will build: cubit tests (toggle writes correct payload), widget tests (word/option toggle rendering and interaction), screen tests.

## Risks

- **MEDIUM**: Word-index stability. If text parsing or re-rendering changes word order/count, indices can drift and payloads become incorrect. Mitigation: explicit unit tests (`word_selection_list_test.dart`) verifying indices match the original split order. Use `ValueKey<int>(wordIndex)` on each word widget to prevent Flutter from reordering.
- **MEDIUM**: Punctuation handling. Words like "wonderful." include the period. Spec doesn't clarify whether to strip punctuation before highlighting. For now, assume punctuation stays with the word (e.g., word index 5 is "wonderful.", not "wonderful"). Backend scoring will clarify if needed.
- **LOW**: Visual feedback for selected words. Chosen highlight color must be readable and distinct from unselected. Use `AppColors` constant for consistency.
- **LOW**: `HIGHLIGHT_INCORRECT_WORDS` backend scoring still OPEN (per plan.md Risks). No action needed for FE; backend team will clarify scoring algorithm later.
