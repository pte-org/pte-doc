# Phase 1: Device-Check Audio Player Seam + Strings

## Requirements
A new `lib/features/device_check/` module exists with a small, testable audio-playback abstraction capable of playing both a local file path (the candidate's own recording) and a bundled asset path (the fixed test-sound clip), plus a strings constants class ready for the screens built in Phase 2. No existing `AudioPlayerService`/`AudioRecorderService` code is modified.

## Steps
1. Create the `lib/features/device_check/` module skeleton (`constants/`, `domain/`, `data/` folders) mirroring how sibling top-level features (e.g. `report`) are structured — not nested under `exam_attempt`.
2. Define a `DeviceCheckAudioPlayer` abstract seam exposing: start playback from a local file path, start playback from a bundled asset path, a stream that signals when the current playback has finished, and a way to release its resources — documented with the same "why two entry points" rationale as the design doc.
3. Implement that seam backed directly by the `just_audio` package, following the existing `AudioPlayerServiceImpl`'s lifecycle shape (listen for the player reaching its completed state, forward that as a one-shot signal on a broadcast stream, clean up the stream subscription and the underlying player together on release).
4. Confirm the exact bundled sound-test asset by listing `assets/audio/` and picking one short, clearly-speech `.wav` file (candidate: `listening_sample_dictation.wav`) — listen to or otherwise verify it isn't a mid-sentence fragment; note the final choice as a named constant, not a scattered literal.
5. Create `DeviceCheckStrings` with a private unnamed constructor (matching `SpeakingWritingStrings`'s pattern) containing every user-facing string this feature will need: screen title, mic-section instruction, sound-section instruction, record/stop/play button labels, the two "did you hear this clearly?" prompts, and Yes/No button labels.
6. Add a short module-level doc comment on the new abstraction explaining why it exists separately from `AudioPlayerService` (asset-only design constraint on the production Listening player) so a future reader doesn't "simplify" it back into one shared player.

## Success Criteria
- `flutter analyze` reports 0 issues for the new `lib/features/device_check/domain/device_check_audio_player.dart` and `lib/features/device_check/data/device_check_audio_player_impl.dart` files.
- The chosen sound-test asset path resolves to a real file under `assets/audio/` (verified by listing the directory) and is referenced through exactly one named constant.
- No changes exist to `lib/features/exam_attempt/listening/domain/audio_player_service.dart`, `lib/features/exam_attempt/listening/data/audio_player_service_impl.dart`, or anything under `lib/features/exam_attempt/speaking_writing/domain/audio_recorder_service.dart` / its impl.

## Risks
- Picking an asset that turns out to be a poor "can you hear this" sample (too short, mid-sentence, or oddly clipped) after implementation starts: mitigate by actually listening to the top 2 candidates from `assets/audio/` before committing to one, not just picking the first alphabetically.
- Diverging accidentally from `AudioPlayerServiceImpl`'s proven completion-signal pattern (e.g. missing the subscription cleanup on close, leaking a player instance): mitigate by keeping the new impl's `close()` method structurally side-by-side with the existing one during implementation and diffing them mentally line-for-line.
