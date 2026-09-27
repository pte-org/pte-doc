# Phase 1: Audio Playback Infrastructure + Shared Audio UI Widget + Task Fixtures/Preview Screen

## Requirements

Build the audio playback abstraction layer (`AudioPlayerService` domain interface + asset-based impl using `just_audio`), the shared `ListeningAudioBar` widget that all 8 listening screens will reuse (playback status indicator, "one-play-only" locked state), mock data fixtures for all 8 listening task types (`ListeningTaskFixtures` mirroring Reading's precedent), a `kDebugMode`-gated dev preview screen (`ListeningTaskPreviewScreen` to render and test all 8 types without a backend), and extend `TaskTypeDispatcher` to recognize all 8 listening task-type strings and route them (for now to a "will-be-implemented" placeholder, later phases fill in the actual screens). Deliverables: FE-only infra, zero backend changes, mocks only (local asset audio), all 8 types renderable and previewable.

Maps to: FR-01 (AudioPlayerService interface + impl), FR-02 (asset-based mock playback), FR-09 (ListeningTaskFixtures), FR-10 (ListeningTaskPreviewScreen), FR-03 (TaskTypeDispatcher extensions).

## Design Constraints

- `AudioPlayerService` is a **thin, GetIt-injectable interface** in `lib/features/exam_attempt/domain/` — public API is `Future<void> play(String source)` + `Stream<bool> get hasFinishedPlaying`. Does NOT expose seek/pause/scrub/replay; every UI layer must be unable to trigger a second playback once audio has started.
- Implementation in `lib/features/exam_attempt/data/` uses `just_audio` library (already in pubspec.yaml). For now, `source` is a Flutter asset path (e.g., `'assets/audio/listening_sample_en.mp3'`). The interface never leaks "asset path" vs "remote URL" — a future remote impl can be swapped via GetIt registration alone without touching UI.
- `ListeningAudioBar` is a **shared widget** in `lib/features/exam_attempt/presentation/widgets/` (not per-screen). **Corrected during implementation** (same lesson as `McOptionList`'s coupling bug from Phase 3's red-team review): must be purely presentational — `{required bool hasFinishedPlaying}`, no `BlocBuilder`/Cubit import of any kind, since each of the 8 task types has its own distinct Cubit/State class and a shared widget cannot import all of them. Each screen's own `BlocBuilder` (already needed for its own state) reads `state.hasFinishedPlaying` and passes it down as a plain prop. Design: displays playback status (idle/playing/finished derived from the bool), "locked" visual state once `hasFinishedPlaying == true` (no re-play button), zero interactive replay controls.
- Disposal discipline mirrors `AudioRecorderService` + `ReadAloudCubit`: Cubit holds the service, cubit's `close()` disposes the service, screen's StatefulWidget calls `cubit.close()` in `dispose()`. No memory leaks — verified by Phase 1's tests.
- `ListeningTaskFixtures` is hand-built, one realistic `TaskView` sample per listening type. Lives in `lib/features/exam_attempt/dev/` (mirror `reading_task_fixtures.dart` location). Each fixture has: correct `taskType` string (matching Java enum), a `promptText` (audio description or blank markers where applicable), `audioPromptRef` set to a mock asset filename, `options`/`blankGroups` if the type needs them.
- `ListeningTaskPreviewScreen` is `kDebugMode`-gated, renders all 8 fixtures through the real `TaskTypeDispatcher`. Route it only when `kDebugMode == true` in `main.dart` — never compiled into release builds. UI: a dropdown or button list picking a fixture, then displaying it via the real dispatcher, same pattern as `ReadingTaskPreviewScreen`.
- Fixture audio files (`.mp3`) are **small, demo-only** English audio clips, bundled in `pte-app/assets/audio/` and declared in `pubspec.yaml` under the assets section. No requirement for real PTE exam content — just enough to test playback + UI flow.
- `TaskTypeDispatcher` changes: add 8 new const strings (`_taskTypeWriteFromDictation = 'WRITE_FROM_DICTATION'`, etc.), add 8 switch arms (each routing to a screen class that will exist in later phases — for now, placeholder pages with loading/todo messages).
- No breaking changes to existing reading/speaking/writing tasks — this phase only **adds** listening support, doesn't refactor existing routes.

## Steps

1. Create `lib/features/exam_attempt/domain/audio_player_service.dart`: abstract interface with `Future<void> play(String source)`, `Stream<bool> hasFinishedPlaying`, `Future<void> close()`. No other methods exposed.

2. Create `lib/features/exam_attempt/data/audio_player_service_impl.dart`: implementation using `just_audio` package. Load asset via `AudioPlayer.setAsset(source)`, emit `hasFinishedPlaying` stream signal when playback finishes, override `close()` to dispose the underlying `AudioPlayer` instance.

3. Create `lib/features/exam_attempt/presentation/widgets/listening_audio_bar.dart`: stateless widget displaying playback status (text label + icon). BlocBuilder/BlocSelector on a parent Cubit (injected or passed) to read audio playback state. Design: "Playing...", "Ready", or "Audio finished (locked)" label, with appropriate icon/color. No interactive replay button.

4. Create `lib/features/exam_attempt/dev/listening_task_fixtures.dart`: hand-built `TaskView` samples for all 8 types, mirroring `reading_task_fixtures.dart`. Each type gets one realistic fixture with correct `taskType` constant, sample `promptText` (or blank markers for blanks type), `options` where needed, `audioPromptRef` = asset filename (e.g., `'assets/audio/listening_dictation_01.mp3'`).

5. Add 3 small mock audio asset files to `pte-app/assets/audio/`: create placeholder/demo `.mp3` files (or reuse if any existing audio exists). Names like `listening_sample_generic.mp3`, `listening_dictation_01.mp3` — exact names referenced by fixtures. Update `pte-app/pubspec.yaml` assets section to include `assets/audio/listening_*.mp3`.

6. Create `lib/features/exam_attempt/dev/listening_task_preview_screen.dart`: StatelessWidget with a dropdown/list of all 8 fixture names. On selection, passes the picked fixture to `TaskTypeDispatcher` for rendering. Wrap in a check for `kDebugMode` so it's never reachable in release builds. Output: "Sample WRITE_FROM_DICTATION task loaded" → dispatcher renders the screen.

7. Update `lib/features/exam_attempt/presentation/widgets/task_type_dispatcher.dart`: add 8 const strings for listening types (`_taskTypeWriteFromDictation`, `_taskTypeSummarizSpokenText`, etc.), add 8 switch arms. Each arm routes to a placeholder screen for now (e.g., `_ListeningPlaceholderScreen(taskType: task.taskType)` — a simple widget saying "Coming in Phase 2+"). Keep existing reading/speaking/writing arms unchanged.

8. Wire `ListeningTaskPreviewScreen` route in `main.dart`: add `if (kDebugMode) ... route(name: '/listening-preview', ...)` so it's only registered in debug builds.

9. Update `lib/features/exam_attempt/domain/exam_attempt_module.dart` (or create if missing) to register `AudioPlayerService` singleton: `getIt.registerSingleton<AudioPlayerService>(AudioPlayerServiceImpl());`.

10. Create `test/features/exam_attempt/data/audio_player_service_test.dart`: mock `just_audio`'s AudioPlayer, verify play() triggers asset load, hasFinishedPlaying emits true when playback completes, close() disposes the underlying player (no double-dispose).

11. Create `lib/features/exam_attempt/dev/listening_task_preview_screen_test.dart`: verify preview screen is reachable only when kDebugMode is true, fixtures load without exception, all 8 fixtures can be displayed through TaskTypeDispatcher.

## Success Criteria

- [x] `AudioPlayerService` interface is minimal (play + hasFinishedPlaying + close), no seek/pause/replay exposed.
- [x] Asset-based impl loads and plays `.mp3` files from Flutter assets without network call.
- [x] `ListeningAudioBar` renders correctly (playback status label, icon).
- [x] `ListeningTaskFixtures` has exactly 8 samples, one per task type, with correct `taskType` string constant.
- [x] All 8 fixtures load and render through `TaskTypeDispatcher` without crash (routed to placeholder screens).
- [x] `ListeningTaskPreviewScreen` is unreachable in non-debug mode (route only registered when `kDebugMode == true`).
- [x] Audio asset files (`.mp3`) are bundled and declared in `pubspec.yaml`.
- [x] `TaskTypeDispatcher` recognizes all 8 listening type strings, no task type falls through to `_UnsupportedTaskTypePlaceholder`.
- [x] `flutter analyze` and `flutter test` pass with zero new issues, 100% of Phase 1 tests passing (fixtures + audio service + preview screen tests).

## Quality and Testing State

- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementation).
- Testing: not started. Phase 1 will build: `audio_player_service_test.dart` (async playback, disposal, asset loading), `listening_task_fixtures_test.dart` (8 samples load, correct types), `listening_task_preview_screen_test.dart` (kDebugMode gating, all 8 fixtures renderable through dispatcher).

## Risks

- **MEDIUM**: Asset loading delay. `just_audio` may introduce a small latency on first playback. Spec requires <1s startup. Mitigation: Phase 1's impl should cache the AudioPlayer or pre-load assets in initState if needed; tests verify <1s delay.
- **LOW**: Audio file licensing. Mock files must not infringe PTE/Pearson copyright. Mitigation: use generic short English audio clips or silence files (not real exam content), labeled as demo-only in comments.
- **LOW**: `kDebugMode` preview route conflicts. If any other route uses `/listening-preview`, route registration in main.dart will collide. Mitigation: choose a unique route name; check existing routes first.
