# Plan: Windows Desktop Audio Playback Fix
Status: ✅ Complete
Date: 2026-08-24
Mode: Hard

## Overview
`just_audio` has no Windows backend, so every `AudioPlayer` call in `AudioPlayerServiceImpl` and `DeviceCheckAudioPlayerImpl` is a silent no-op on `flutter run -d windows`. This plan spikes the cheapest fix first (`just_audio_windows` as a drop-in backend) and falls back to a gated `just_audio_media_kit` bridge only if the spike fails, restoring audible playback on Windows without regressing macOS (confirmed-working) or Android/iOS (unverified this cycle, must stay untouched).

## Phases
- [x] Phase 1: Windows Backend Spike — FAILED for the case that matters. Dependency resolved cleanly, Flutter auto-wired `just_audio_windows` with zero app-code changes, `setFilePath` (local file playback) worked and was audibly confirmed by the developer — but `setAsset` (bundled Flutter asset playback) stayed silent. Production `AudioPlayerService` is asset-only by design, so this branch does not fix the motivating bug.
- [x] Phase 2a: Adopt just_audio_windows (branch A) — SKIPPED (Phase 1 failed the setAsset case). `just_audio_windows` dependency removed.
- [x] Phase 2b: Adopt just_audio_media_kit (branch B, taken — Phase 1 spike failed) — gated Windows-only bridge with native lib bundling. PASSED: both `setFilePath` and `setAsset` audibly confirmed working; `flutter test` (491/491) and `flutter build apk --debug` both pass; `flutter build ios` untestable on this Windows host (pre-acknowledged residual risk).
- [x] Phase 3: Manual Windows Audio Verification — PASSED. "Play my recording" audible; "Play test sound" proven working via a temporary real-tone swap (the shipped fixture asset itself is silent — separate flagged issue, see Risks); Listening preview path confirmed no-crash.

## Research Summary
Two backend options were researched for Windows playback:

- **just_audio_windows** (Researcher B's primary pick): a third-party federated WinRT-MediaPlayer-backed implementation of just_audio's Windows platform interface. If pub/plugin resolution accepts it as the Windows `default_package` (via `dependency_overrides` or equivalent — NOT declared as such by just_audio itself today), this requires zero changes to `AudioPlayerServiceImpl`/`DeviceCheckAudioPlayerImpl`, zero native DLL bundling (WinRT MediaPlayer ships with the OS), and zero macOS re-verification risk. This is untested/unconfirmed and is exactly what Phase 1 spikes.
- **just_audio_media_kit** (Researcher A's primary pick): a maintained bridge that swaps just_audio's Windows backend to libmpv via `media_kit`, gated per-platform through an explicit `ensureInitialized(windows: true, ...)` bootstrap call so macOS/Android/iOS keep their native just_audio backends untouched. Confirmed-working pattern in the just_audio ecosystem, but requires bundling `media_kit_libs_windows_audio` (several MB), and its pinned `just_audio_platform_interface: ^4.5.0` compatibility with the app's pinned `just_audio: ^0.10.6` is unverified until `flutter pub get` is actually run against it.
- **audioplayers** (Researcher B's fallback) and raw **media_kit** `Player` (no bridge) were both rejected as first choices: audioplayers requires rewriting both Impl classes' internals and a mandatory macOS re-verification pass (different backend, not just_audio's); raw media_kit carries the same native-bundling weight as the media_kit bridge with no compatibility upside.

Chosen approach: Phase 1 spikes `just_audio_windows` cheaply and fast. If it resolves cleanly and produces audible sound, Phase 2a finalizes it (zero code changes, no native bundling, no macOS risk — strictly the cheapest option). If the spike fails for any reason (resolution conflict, plugin registration doesn't pick it up, silent no-op persists), Phase 2b falls back to the gated `just_audio_media_kit` bridge. Only one of Phase 2a/2b is executed, determined by the Phase 1 outcome.

## Dependencies
- Phase 2a and Phase 2b are mutually exclusive — do not execute both. The Phase 1 spike result is the gate.
- Phase 3 depends on whichever of Phase 2a/2b was executed.
- **Branch bookkeeping:** once Phase 1's outcome is known, immediately mark the untaken branch's checkbox below as skipped (not left as `- [ ]`) — e.g. `- [x] Phase 2b: ... (SKIPPED — Phase 1 succeeded, Phase 2a taken)`. This prevents a future `/ck:cook` resume from treating the discarded branch as still-pending work.

## Risks
- HIGH: Android/iOS have no available test hardware this cycle — any dependency change that could theoretically touch their code paths (e.g. an unnecessary `just_audio` version bump forced by the media_kit bridge's `just_audio_platform_interface: ^4.5.0` pin) must default to leaving those platforms' resolved packages/behavior completely untouched. If a bump is strictly unavoidable, it must be called out as a follow-up requiring manual Android/iOS regression before release, not silently absorbed into this plan.
- MEDIUM: `just_audio_media_kit`'s maintenance cadence is a mild concern (latest known release notably old) — if Phase 2b is taken, check pub.dev for a newer release before pinning, and re-confirm `just_audio_platform_interface` compatibility at that time rather than assuming the version noted during research still holds.
- MEDIUM: `just_audio_windows`'s federated-plugin wiring is unconfirmed — Phase 1 exists specifically to fail fast and cheap on this before any further work is sunk into it.
- LOW: Bundling `media_kit_libs_windows_audio` (Phase 2b only) increases Windows build size by several MB — acceptable for a desktop app, no mitigation needed beyond noting it.
- LOW: Recording (`record`/`record_windows`) and the web target are explicitly out of scope for this plan — no phase should touch `AudioRecorderService`/`record_windows` config or `sqlite3`/`dart:ffi` web storage code; any incidental need to touch either is a signal to stop and re-scope.
- **FOLLOW-UP (found during Phase 2b, out of this plan's scope):** all 8 bundled `assets/audio/listening_sample_*.wav` fixture files are silent placeholder data (essentially all-zero PCM — 1 non-zero byte out of 32000). Per `AudioPlayerServiceImpl`'s own doc comment these are the actual files real Listening-task audio plays in the current mock-data phase, so no platform (not just Windows) can produce audible Listening prompt audio today. This is a content/data problem, not a code or backend bug, and needs real recorded audio content — not addressed by this plan.
- iOS compile-only build check (`flutter build apk --debug`'s counterpart) could not be run — `flutter build ios` is not an available subcommand on a Windows host. Consistent with the plan's pre-acknowledged "no iOS hardware/toolchain this cycle" risk; Android compile-only check passed cleanly.

## Session Notes
<!-- Updated by cook automatically — do not edit manually -->

**Last active:** 2026-08-25
**Phase in progress:** phase-01-windows-backend-spike
**Status:** Paused mid-Phase-1, waiting on user's manual audible-sound confirmation

### Decisions made this session
- Added `just_audio_windows: ^0.2.3` as a direct dependency (`flutter pub add just_audio_windows`) — resolved cleanly, no `dependency_overrides` needed, no version conflicts, no bump to pinned `just_audio: ^0.10.6`.
- Confirmed Flutter's federated-plugin auto-resolution picked it up automatically as the Windows backend: `just_audio_windows` now appears in `windows/flutter/generated_plugins.cmake` alongside `connectivity_plus`, `flutter_secure_storage_windows`, `record_windows` — zero manual wiring/override required.
- Zero changes made to `AudioPlayerServiceImpl`/`DeviceCheckAudioPlayerImpl` — confirmed by construction (no edits attempted), satisfying Phase 1's "zero app-code changes" success criterion.
- Hit an environment blocker unrelated to package choice: `flutter run -d windows` failed with "Building with plugins requires symlink support" because Windows Developer Mode was off (`AllowDevelopmentWithoutDevLicense = 0` in registry). User enabled Developer Mode via `ms-settings:developers`. Noted for the record: this would have blocked Phase 2b (`just_audio_media_kit` + `media_kit_libs_windows_audio`) identically, since it's triggered by adding any new native Windows plugin — not specific to `just_audio_windows`.
- After enabling Developer Mode, `flutter build windows` + `flutter run -d windows --dart-define=DEV_SKIP_AUTH=true` succeeded cleanly: `√ Built build\windows\x64\runner\Debug\aptis_app.exe`, app launched, no `PlatformException`/`MissingPluginException`/exceptions in the run log before the app window was closed.
- **Not yet confirmed:** the actual audible-sound check (Phase 1 step 4 — "Play test sound" / "Play my recording" must be *heard*, not just reach their completed state). User paused before completing this manual step; app window was closed before confirming. This is the one remaining gate before Phase 1's go/no-go outcome can be recorded.

### Phase 1 final outcome (recorded 2026-08-25)
Developer confirmed on real hardware: "Play my recording" (`setFilePath`, local `.wav`) — **audible, works**. "Play test sound" (`setAsset`, bundled `assets/audio/listening_sample_dictation.wav`) — **silent, does not work**. Both files are the same `.wav` format, ruling out a codec issue; the only variable is source type (local file vs. Flutter asset), matching the researcher's flagged risk that `just_audio_windows` leaves byte-stream/asset-style sources untested/unsupported. Since the production `AudioPlayerService` (real Listening/Speaking exam audio) is asset-only by design, `just_audio_windows` does not fix the bug that motivated this plan — it only incidentally fixes local-file playback (relevant to `DeviceCheckAudioPlayer`'s mic-recording-playback path only). Verdict: **FAIL** on the criterion that matters. `just_audio_windows` dependency removed via `flutter pub remove just_audio_windows`. Proceeding to Phase 2b.

### Phase 2b outcome + a major mid-flight discovery (2026-08-25)
`just_audio_media_kit` bootstrap added to `lib/main.dart` (`JustAudioMediaKit.ensureInitialized(windows: true, linux: false, android: false, iOS: false, macOS: false)`), Windows-only, before any `AudioPlayer` construction. Resolved cleanly with **no `just_audio` version bump**. `flutter build windows` succeeded with `media_kit_libs_windows_audio` correctly bundled.

First manual test repeated the exact same pattern as Phase 1: "Play my recording" (`setFilePath`) audible, "Play test sound" (`setAsset`, `assets/audio/listening_sample_dictation.wav`) silent. Rather than accept that as a second backend failure, inspected the asset file directly: **`listening_sample_dictation.wav` (and all 7 other `assets/audio/listening_sample_*.wav` fixtures) are silent placeholder data — essentially all-zero PCM (1 non-zero byte out of 32000)**, not real recorded audio. Verified the hypothesis conclusively by generating a real 440Hz sine-wave WAV, temporarily swapping `deviceCheckTestSoundAssetPath` to point at it, rebuilding, and confirming with the developer that it played audibly. Reverted the swap immediately after confirming (debug asset deleted, constant restored).

**Conclusion: `just_audio_media_kit` correctly plays both local files and bundled assets on Windows.** The original "Play test sound" silence — in BOTH Phase 1 (`just_audio_windows`) and the first Phase 2b attempt — was caused by the fixture data itself being silent, not by either audio backend. This means Phase 1's "FAIL" verdict was likely a **misdiagnosis of the true root cause** (it may well have also worked correctly with real audio content), but this is not being re-investigated: `just_audio_media_kit` is already proven fully working end-to-end and was the research's primary recommended option regardless, so reverting to re-test `just_audio_windows` would be pure churn with no upside.

**New, separate, out-of-scope finding to flag to the developer:** all 8 bundled `assets/audio/listening_sample_*.wav` fixtures are silent placeholder files. Per `AudioPlayerServiceImpl`'s own doc comment, these are the actual files real Listening-task audio plays today ("mock-data phase... never a network URL"), so this silent-fixture-data issue affects the Listening feature's audio playback on **every platform**, not just Windows — it has nothing to do with this plan's backend fix. Tracked as a flagged follow-up, not fixed here (content/data problem, not a code bug — needs real recorded audio, not something to synthesize with a sine tone as a permanent fix).

### Next immediate action
All phases complete. Proceeding to `/ck:cook`'s Step 4 (code review) and Step 5 (finalize).
