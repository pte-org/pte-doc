# Plan: 8 PTE Listening Task-Type Screens (pte-app — FE Only, Mock-First)

Status: Completed
Date: 2026-08-22
Mode: Hard
Test: Default (no --tdd)

## Overview

The exam-attempt flow in `pte-app` currently supports 5 reading task types and 2 other types (Write Essay, Read Aloud), but has **zero support for Listening — 1 of the 4 core PTE skills**. `TaskTypeDispatcher` fallback to `_UnsupportedTaskTypePlaceholder` for all 8 listening types (`WRITE_FROM_DICTATION`, `SUMMARIZE_SPOKEN_TEXT`, `HIGHLIGHT_INCORRECT_WORDS`, `FILL_BLANKS_LISTENING`, `MC_LISTENING_MULTIPLE`, `MC_LISTENING_SINGLE`, `SELECT_MISSING_WORD`, `HIGHLIGHT_CORRECT_SUMMARY`). This plan adds UI + mock-data support for all 8, following the exact Reading precedent architecture (`TaskTypeDispatcher` switch arms → per-type Cubit/State/Screen), **reusing existing patterns** (audio disposal like `ReadAloudCubit`, word-count validation like `WriteEssayCubit`, option-selection like `McReadingSingleCubit`). The backend (`exam-delivery` service) has zero routing/timing config for these 8 types today — this is FE-only, mock-first; a separate backend plan will handle `task-timing.json` + DTO wiring once UI is complete. Audio playback uses a new `AudioPlayerService` abstraction (thin interface, `just_audio`-based impl, asset-bundled mock media files) — this service is not exposed to UI for direct control; the implementation locks playback to "one-play-only" at the architecture layer.

## Phases

- [x] Phase 1: Audio Playback Infrastructure + Shared Audio UI Widget + Task Fixtures/Preview Screen [quality: approved; report+receipt: pte-app/plans/quang-listening-task-types/quality/ (moved out of pte-doc — receipt.py requires reviewed files + report in the same git repo; pte-app and pte-doc are separate sibling repos, so report/receipt live in pte-app alongside the code they reviewed). testing: skipped by user] — Build `AudioPlayerService` domain interface + asset-based impl, `ListeningAudioBar` shared widget, `ListeningTaskFixtures` (1 mock sample per 8 types), `ListeningTaskPreviewScreen` (`kDebugMode`-gated), extend `TaskTypeDispatcher` with all 8 constant strings and placeholder routing.
- [x] Phase 2: Text-Input Types — Highest-Priority Write/Summarize [quality: approved; report+receipt: pte-app/plans/quang-listening-task-types/quality/. testing: skipped by user. Also fixed a pre-existing broken test (task_type_dispatcher_test.dart needed the new required audioPlayerService param) and a second McOptionList-class coupling bug in WordCountLabel — built ListeningWordCountLabel instead of touching the shared widget.] — Build `WRITE_FROM_DICTATION` screen/cubit (audio + text input with word-count validation reused from `WriteEssayCubit` pattern), `SUMMARIZE_SPOKEN_TEXT` screen/cubit (audio + text input, word-count validation).
- [x] Phase 3: Multiple-Choice Reuse + Select Missing Word [quality: approved; report+receipt: pte-app/plans/quang-listening-task-types/quality/. testing: skipped by user] — Build two new decoupled presentational widgets (`ListeningOptionList` single-select, `ListeningMultipleOptionList` multi-select — Reading's `McOptionList`/`McMultipleOptionList` are hardcoded to Reading cubits and are NOT reusable, confirmed by reading their source), then `MC_LISTENING_SINGLE`, `MC_LISTENING_MULTIPLE`, `SELECT_MISSING_WORD` screens/cubits (`StatelessWidget` + `BlocProvider`, mirroring `McReadingSingleScreen`'s actual pattern), swapping text prompt for audio.
- [x] Phase 4: Click-to-Toggle Word Selection + Correct Summary [quality: approved; report+receipt: pte-app/plans/quang-listening-task-types/quality/. testing: skipped by user] — Build `HIGHLIGHT_INCORRECT_WORDS` screen/cubit (audio + transcript with click-to-toggle word selection, backed by `Set<int> selectedWordIndices` state, rendered via `Wrap` of tappable word widgets — genuinely new UI, no precedent). `HIGHLIGHT_CORRECT_SUMMARY` screen/cubit (audio + single-select paragraph list — real PTE format is pick-one-correct-summary, not multi-toggle; reuses Phase 3's `ListeningOptionList` and `McListeningSingleCubit` shape directly, no new widget).
- [x] Phase 5: Free Type-In with Blank Markers [quality: approved; report+receipt: pte-app/plans/quang-listening-task-types/quality/. testing: skipped by user] — Build `FILL_BLANKS_LISTENING` screen/cubit (audio + transcript with `{{n}}` blank markers, free type-in per blank, case-insensitive string matching, no word bank, no drag-drop — distinct from Reading's drag-drop variant).

## Research Summary

Decisions below were established via prior investigation with the user, architecture decision memos, and direct codebase inspection:

1. **Full FE-only scope, no backend changes**: confirmed with user — this plan is mock-data + UI only. Backend routing/timing config for 8 listening types is explicitly out of scope; a separate plan will add `task-timing.json` entries and ensure `exam-delivery`'s `TaskView` DTO fetching works once FE ship. **The FE UI should never be blocked by a backend that doesn't yet know these task types exist.**

2. **AudioPlayerService as a thin, testable abstraction** — confirmed via architecture discussion. Public interface is deliberately minimal: `Future<void> play(String source)` + a `hasFinishedPlaying` signal. Does NOT expose seek/pause/scrub/replay to the caller; every UI layer must be unable to trigger a second play. Implementation uses `just_audio` (already a `pubspec.yaml` dependency, never used until now), and the impl is swappable via GetIt registration — today plays from local assets (flutter asset path), future impl can be remote (presigned URL) by swapping the service instance, zero UI changes. Disposal discipline mirrors `AudioRecorderService`/`ReadAloudCubit` (see `read_aloud_screen.dart` for the pattern — call `close()` on the cubit, which disposes the recorder, in `dispose()` of the StatefulWidget).

3. **One shared `ListeningAudioBar` widget for all 8 screens** — confirmed. Every listening screen reuses the same audio UI: a play indicator (playing/idle/done), optional transcript label, and "already played, locked" visual state. No per-screen audio-UI invention. This widget is built in Phase 1 and imported by Phases 2-5.

4. **Click-to-toggle word selection for HIGHLIGHT_INCORRECT_WORDS** — confirmed per spec FR-06. A `Wrap` of individual tappable word widgets (each word is a `GestureDetector`/`InkWell` wrapping a `Text`), backed by a Cubit holding `Set<int> selectedWordIndices` (toggle on tap, no selection limit). This directly mirrors `mc_option_list.dart` + `mc_reading_single_cubit.dart` per-item-selection pattern — same state-management style, same Cubit architecture. Each word gets a stable `ValueKey`/index for correct toggle behavior and testability.

5. **Single-select for HIGHLIGHT_CORRECT_SUMMARY, corrected during red-team review** — real PTE format is picking the ONE paragraph that correctly summarizes the audio, not toggling multiple as correct (the initial draft incorrectly modeled this as multi-select/checkboxes). Structurally identical to `MC_LISTENING_SINGLE`: reuses Phase 3's `ListeningOptionList` widget and `McListeningSingleCubit`'s shape (`selectedOrderIndex: String?`), just with paragraph-length option text instead of short choices. No new widget needed for this type.

6. **FILL_BLANKS_LISTENING is free type-in, not drag-drop** — confirmed. No word bank, no options dropdown per gap. User types directly in text fields below each blank marker. Case-insensitive string match against a correct answer (backend will handle scoring; FE just collects the text). Explicitly different from Reading's `FILL_BLANKS_READING` (drag-drop) and `FILL_BLANKS_READING_WRITING` (dropdown per gap). Use the same `{{n}}` blank-marker convention from Reading's `parseBlankPrompt`, but render free-text input fields, not drag targets or dropdowns.

7. **All cubits are discrete-selection or simple-input style** — confirmed. No debounce/auto-save like `WriteEssayCubit` except for the two explicit text-input types (Write From Dictation, Summarize Spoken Text), which reuse `WriteEssayCubit`'s word-count validation (not the debounce timer itself; just the `wordCount` logic). Every other type (MC-style) writes synchronously, no `flushPendingEdit()` work.

8. **Task-type string constants must match `pte-api/services/authoring/.../PteTaskType.java` exactly** — confirmed. Using the 8 exact strings: `WRITE_FROM_DICTATION`, `SUMMARIZE_SPOKEN_TEXT`, `HIGHLIGHT_INCORRECT_WORDS`, `FILL_BLANKS_LISTENING`, `MC_LISTENING_MULTIPLE`, `MC_LISTENING_SINGLE`, `SELECT_MISSING_WORD`, `HIGHLIGHT_CORRECT_SUMMARY`. If backend enum names change in authoring, FE switch-case must change in sync.

9. **Mock audio assets are local Flutter assets, not network** — confirmed. Phase 1 bundles small `.mp3` files in `pte-app/assets/audio/` (declare in `pubspec.yaml`), `AudioPlayerService` impl reads from asset bundle. No `MediaRepository`, no presigned-URL mocking. Future remote impl (post-backend-integration) will swap the service.

10. **Fixtures are hand-built, not backend-seeded** — confirmed per Reading precedent. One sample `TaskView` per listening type in `ListeningTaskFixtures`, populated with realistic promptText (with audio markers and/or blank markers), options, mock audio asset names. Shared by dev preview screen and later widget tests.

11. **`McOptionList`/`McMultipleOptionList` are NOT reusable for Listening — corrected during red-team review**. Confirmed by reading the actual widget source: both hardcode `BlocBuilder<McReadingSingleCubit, _>` / `BlocBuilder<McReadingMultipleCubit, _>` respectively, importing the Reading cubit type directly rather than being generic over any option-selection cubit. Phase 3 builds two new, purely presentational widgets instead (`ListeningOptionList`, `ListeningMultipleOptionList` — no `BlocBuilder`/Cubit import, just options + selected-state + callback props), which Phase 4's `HIGHLIGHT_CORRECT_SUMMARY` also reuses. This is deliberate duplication with Reading's widgets, not a shared generic component — consistent with this codebase's existing pattern of per-type bespoke widgets over premature abstraction.

12. **Screen widget type: `StatelessWidget` + `BlocProvider` by default, `StatefulWidget` only when a screen owns a `TextEditingController`** — confirmed by reading both `McReadingSingleScreen` (StatelessWidget + BlocProvider, no controller) and `WriteEssayScreen` (StatefulWidget, owns `_controller`, disposes it in `dispose()`) as the two real precedents. Phases 3 and 4 (no text input) use the StatelessWidget pattern; Phases 2 and 5 (own one or more `TextEditingController`s) use the StatefulWidget pattern. In all cases the Cubit's `close()` disposes only `AudioPlayerService` — it never owns a `TextEditingController`, matching `WriteEssayCubit`'s actual (verified) behavior.

## Dependencies

- `pte-app`'s existing exam-attempt architecture (`ninh-student-exam-flow` plan, completed 2026-07-26): `TaskTypeDispatcher`, `TaskAnswerCubit<S>` + `FlushableAnswerCubit`, `TaskAdvanceButton`, `SyncEngine`/`AnswerOutboxDao`, `ExamScaffold`, common widgets (`PrimaryButton`, `StatusBanner`, `showConfirmDialog`), and the `word_count.dart` utility (reused for word-count validation).
- `just_audio` (already in `pubspec.yaml`, unused until now) for audio playback.
- `pte-api`'s `services/authoring` (PteTaskType enum defining the 8 listening types — must match string constants).
- Reading precedent (`ninh-pte-reading-task-types` plan): `TaskTypeDispatcher` routing pattern, `ReadingTaskFixtures`/`ReadingTaskPreviewScreen` structure (mirror for Listening), Cubit per-type architecture, blank-marker parsing (reused).
- No new Flutter pubspec dependencies beyond `just_audio` (already present).
- No new backend dependencies or changes (FE-only, mock-first).

## Risks

- **HIGH: Backend blocking real usage**. This plan ships FE UI + mock data. Backend (`exam-delivery`) has zero routing/timing config for any of the 8 listening types today (task-timing.json only configures 3 legacy task types per past PRs). A future backend plan must add these task types to `task-timing.json`, update `TaskView` DTO parsing, and wire scoring evaluators. Until then, this UI cannot run against a real API — only mocks work. **State this clearly so nobody confuses "UI done" with "feature done".**
  - **Mitigation**: Phase 1 explicitly documents mock-only support in `ListeningTaskPreviewScreen`'s output. Phase documentation states "FE-only, mock-data, backend-blocking."

- **MEDIUM: Stale prior art**. There is an abandoned plan at `pte-app/plans/audio-player/` (dated 2026-07-03, references defunct `lib/features/listening/`, Question model, never implemented). This is superseded and must NOT be used as a reference or reused for file paths. Any developer finding this old plan will be confused.
  - **Mitigation**: Phase 1 notes that the old `pte-app/plans/audio-player/` is abandoned, not to be followed. New code uses `lib/features/exam_attempt/` (existing structure), not a new `lib/features/listening/`.

- **MEDIUM: Audio playback edge cases**. The `AudioPlayerService` interface is thin, but impl must handle: (1) asset loading delay, (2) disposal while playing, (3) re-instantiation per task (via `ValueKey` in `TaskTypeDispatcher`). Tests must verify cleanup to prevent memory leaks.
  - **Mitigation**: Phase 1 includes explicit cubit disposal in screen widget's `dispose()` (mirror `ReadAloudScreen`'s pattern). Phase tests verify that `AudioPlayerService.close()` is called.

- **LOW: `HIGHLIGHT_INCORRECT_WORDS` backend scoring still OPEN**. Per `pte-doc/projects/plans/quang-pte-pivot/phase-01-contract-draft.md`, the Java QuestionType → scoring mapping for this task type is flagged "STILL OPEN". This doesn't affect FE correctness (FE just collects selected-word indices), but backend phases will need to clarify scoring before real evaluation can work.
  - **Mitigation**: Phase 4 notes this in its Risks section. No action needed for this plan; backend team will close the open question later.

- **LOW: FILL_BLANKS_LISTENING free type-in correctness**. Spec says "case-insensitive string match" but doesn't specify whether partial-word match, fuzzy match, or exact (minus case/whitespace) match. For now, assume exact match (case-insensitive, ignore leading/trailing whitespace). Backend scoring will clarify the exact algorithm later.
  - **Mitigation**: Phase 5 notes assumption in design constraints. FE collects answer as-typed; backend evaluator will do the actual matching.

- **LOW: Word-selection toggle stability**. Using `Set<int>` with word indices requires a stable word-ordering and index assignment. If blank-prompt parsing or transcript rendering changes the word-list order, indices can drift. Mitigated by explicit unit tests in Phase 4.
  - **Mitigation**: Phase 4 includes `blank_prompt_parser_test.dart` and `highlight_incorrect_words_cubit_test.dart` verifying index stability and toggle semantics.

- **LOW: Mock audio asset sourcing — resolved**. Confirmed with user: Claude generates/sources the placeholder `.mp3` files during Phase 1 implementation (not provided by the user) — short public-domain or generated English speech samples (~10-20s), naming convention `assets/audio/listening_sample_<n>.mp3`. `AudioPlayerService.play()` must not crash the UI if an asset is missing — log and emit `hasFinishedPlaying = true` so the task doesn't hang.

- **LOW: Task-type string constants — already verified, not just assumed**. The 8 strings in this plan were cross-checked directly against `pte-api/services/authoring/src/main/java/com/pte/authoring/domain/enums/PteTaskType.java` (lines 36-43) during brainstorm scouting — all 8 match exactly. No further verification step needed in Phase 1; this note exists so a future reader doesn't re-flag it as unverified.

- **LOW: Audio startup <1s performance target unverified**. Spec requires playback to start within 1s of task load; Phase 1's plan doesn't specify how this gets measured.
  - **Mitigation**: Phase 1 testing should include a simple stopwatch-style assertion (call `play()`, assert `playing` state reached within 1000ms) using a small bundled asset. Not expected to be an issue for local assets, but should be an explicit test, not an assumption.

## Quality Gates & Coding Standards

Every phase must adhere to `pte-app/docs/CODING_STANDARDS_APP.md` and `CLAUDE.md`:
- File ≤ 300 lines (BLoC exception: bloc/event/state separate files).
- `dispose()` for every controller/subscription (audio service, text controllers).
- `mounted` check after every `await` before using BuildContext.
- Sealed/immutable Cubit states.
- No hardcoded strings (use `AppStrings.*`), colors (use `AppColors.*`), dimensions (use `AppDimensions.*`).
- GetIt DI via `*_module.dart`.

Every phase will run `flutter analyze` and `flutter test` pre-submission. Quality gate approval is required before merging.
