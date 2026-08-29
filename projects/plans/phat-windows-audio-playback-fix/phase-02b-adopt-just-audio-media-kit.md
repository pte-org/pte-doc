# Phase 2b: Adopt just_audio_media_kit (Branch B — only if Phase 1 spike failed)

## Requirements
Restore real Windows audio output by bridging just_audio to a libmpv-backed `media_kit` player on Windows only, leaving macOS, Android, and iOS on their existing native just_audio backends untouched. Only run this phase if Phase 1 recorded a "no" outcome.

## Steps
1. Before adding the dependency, verify `just_audio_media_kit`'s pinned `just_audio_platform_interface` requirement is actually compatible with the app's pinned `just_audio: ^0.10.6` via a real dependency resolution attempt — do not assume compatibility from research notes alone.
2. If a `just_audio` version bump is strictly required to satisfy that resolution, bump only the minimum necessary and flag it explicitly as a follow-up requiring manual Android/iOS regression verification before release (no hardware available this cycle to verify inline).
3. Add the bridge dependency and the Windows-only native audio libraries it needs for Windows builds.
4. Add a single, explicit per-platform initialization call at app startup that enables the bridge for Windows only and leaves macOS/Android/iOS on their default native backends — call it once, before any `AudioPlayer` instance is constructed anywhere in the app.
5. Run a full clean Windows build to confirm the native libraries bundle correctly and the app launches.
6. Re-open the "Test Mic and Sound" screen and confirm both "Play my recording" and "Play test sound" reach their completed/finished state correctly (functional correctness pass; the audible-sound confirmation itself belongs to Phase 3).
7. Run the existing automated test suite and static analysis to confirm nothing broke, paying particular attention to anything that touches `AudioPlayerService`/`DeviceCheckAudioPlayer` construction paths.
8. Run `flutter build apk --debug` and `flutter build ios --no-codesign` — compile-only checks, no device/signing needed — to catch any Android/iOS-side resolution or build-toolchain break, especially important here since this branch is the one actually capable of forcing a `just_audio` version bump.

## Success Criteria
- Dependency resolution (step 1) is confirmed compatible, or the minimum necessary bump is documented with its follow-up regression requirement (step 2).
- `flutter build windows` completes successfully from a clean state with the native audio libraries bundled.
- `flutter build apk --debug` and `flutter build ios --no-codesign` both complete successfully (compile-only Android/iOS safety net).
- The startup initialization call is provably Windows-only (code inspection: the flag passed for every non-Windows platform is explicitly disabled/false, not merely defaulted).
- `AudioPlayerServiceImpl` and `DeviceCheckAudioPlayerImpl` internals are unchanged beyond what's strictly required by any `just_audio` version bump from step 2 (ideally zero changes) — the public interfaces are never touched.
- `flutter analyze` and the existing automated test suite (`flutter test`) both pass with no new failures.
- If a `just_audio` bump occurred, it is called out as an open risk/follow-up item in the plan, not silently absorbed.

## Actual Results (2026-08-25)
- Step 1: `flutter pub add just_audio_media_kit media_kit_libs_windows_audio` resolved cleanly. `just_audio` stayed pinned at `^0.10.6` — **no bump required**, confirmed via `pubspec.lock` diff.
- Step 2: N/A — no bump needed.
- Steps 3–4: dependencies added; `JustAudioMediaKit.ensureInitialized(windows: true, linux: false, android: false, iOS: false, macOS: false)` added at the very top of `lib/main.dart`'s `main()`, before any module setup.
- Step 5: `flutter build windows` succeeded clean (`√ Built build\windows\x64\runner\Debug\aptis_app.exe`), native lib registered (`package:media_kit_libs_windows_audio registered.`). One benign third-party CMake dev-warning (`media_kit_libs_windows_audio`'s own `add_custom_command` missing an explicit PRE_BUILD/PRE_LINK/POST_BUILD arg) — not actionable from this app's code.
- Step 6: **Both `setFilePath` (mic playback) and `setAsset` (bundled asset playback) audibly confirmed working** by the developer — see plan.md Session Notes for the full diagnostic trail (an intermediate false negative on `setAsset` turned out to be a separate, pre-existing silent-fixture-data bug, not a backend problem — proven by swapping in a real sine-wave tone, which played correctly).
- Step 7: `flutter test` — all 491 tests pass, 0 failures.
- Step 8: `flutter build apk --debug` — **succeeded** (`√ Built build\app\outputs\flutter-apk\app-debug.apk`, only pre-existing benign Gradle/Java-version warnings unrelated to this change). `flutter build ios --no-codesign` — **could not run**: `flutter build ios` is not an available subcommand on a Windows host (requires macOS + Xcode). This is the pre-acknowledged "no iOS hardware/toolchain available this cycle" residual risk from `plan.md`'s Risks section, not a new gap introduced here.
- One environment blocker unrelated to package choice, encountered and resolved along the way: `flutter run -d windows`/`flutter build windows` requires Windows Developer Mode enabled (`Building with plugins requires symlink support`) whenever a new native Windows plugin is added — this affected both the Phase 1 spike and this phase identically, confirming it's an environment prerequisite, not something either backend choice avoids.

Verdict: **PASSED** (Android compile-only check passed; iOS compile-only check untestable on this machine, tracked as residual risk, not a failure).

## Risks
- HIGH: A forced `just_audio` version bump could subtly change behavior on Android/iOS with no hardware available to verify this cycle — mitigated by keeping the bump to the strict minimum and explicitly flagging it as a required follow-up regression check rather than treating this phase as fully closing the loop on those platforms.
- MEDIUM: `just_audio_media_kit`'s release cadence is stale — check pub.dev for a newer version before pinning, since a fresher release may resolve the platform-interface compatibility question more favorably.
- LOW: Native library bundling increases Windows build size by several MB — acceptable, no mitigation needed.
- LOW: Incorrect per-platform flag wiring could silently enable the media_kit backend on macOS too, regressing the one platform confirmed working today — mitigated by the explicit code-inspection check in the success criteria.
