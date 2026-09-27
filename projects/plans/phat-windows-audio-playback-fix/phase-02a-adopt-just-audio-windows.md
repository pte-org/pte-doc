# Phase 2a: Adopt just_audio_windows (Branch A — only if Phase 1 spike succeeded)

## Requirements
Finalize `just_audio_windows` as the app's Windows audio backend so `AudioPlayerServiceImpl` and `DeviceCheckAudioPlayerImpl` produce real audio output on Windows, with no changes to either class or to the public `AudioPlayerService`/`DeviceCheckAudioPlayer` interfaces. Only run this phase if Phase 1 recorded a "yes" outcome.

## Steps
1. Finalize the dependency and wiring approach proven out in the Phase 1 spike (pubspec entry plus whatever override/registration made it work) as a clean, committable change.
2. Confirm no other platform's dependency resolution shifted as a side effect — Android, iOS, and macOS must resolve to the exact same native just_audio backends they use today.
3. Run a full clean Windows build to confirm the app compiles and launches with the new backend wired in, not just the spike's quick-run check.
4. Re-open the "Test Mic and Sound" screen and confirm both "Play my recording" and "Play test sound" reach their completed/finished state correctly (functional correctness pass; the audible-sound confirmation itself belongs to Phase 3).
5. Run the existing automated test suite and static analysis to confirm nothing broke.
6. Run `flutter build apk --debug` and `flutter build ios --no-codesign` — compile-only checks, no device/signing needed — to catch any Android/iOS-side resolution or build-toolchain break that `flutter analyze`/`flutter test` cannot see.
7. Document the final dependency wiring (what was added, why, and any caveat) directly in the pubspec or a short inline comment near the override, so a future maintainer understands why a third-party federated package is being forced in.

## Success Criteria
- `flutter pub get` resolves cleanly with the finalized wiring in place.
- `flutter build windows` completes successfully from a clean state.
- `flutter build apk --debug` and `flutter build ios --no-codesign` both complete successfully (compile-only Android/iOS safety net).
- `flutter analyze` and the existing automated test suite (`flutter test`) both pass with no new failures.
- `AudioPlayerServiceImpl` and `DeviceCheckAudioPlayerImpl` source files are unchanged (diff against pre-Phase-1 state shows zero lines changed in either).
- Android/iOS/macOS resolved package versions for just_audio and its platform backends are unchanged from before this phase.

## Risks
- A federated-plugin override that works for `flutter run` but not `flutter build` (release-mode plugin registration differs) — mitigated by step 3's full clean build check.
- Future `just_audio` or `just_audio_windows` version bumps could silently break the override wiring — mitigated by the inline documentation in step 6 flagging this as a deliberate, non-obvious wiring choice.
