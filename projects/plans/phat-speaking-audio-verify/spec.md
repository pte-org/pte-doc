# Spec: Verify desktop audio (mic + playback) for speaking tasks across platforms

**Date:** 2026-08-24
**Status:** Cooked — P1 story 1 fully met; P1 story 2 partially met (see Success Criteria)

---

## Problem Statement

`pte-app`'s speaking tasks already implement mic recording (`record`) and prompt playback (`just_audio`) end-to-end, but this has only ever run on Windows. Scouting found a concrete gap: macOS's `Info.plist`/entitlements are missing the keys required for a sandboxed app to request microphone access, which will hard-block recording on macOS. The developer (solo, Windows-only machine right now) needs to close that known gap and get a real confidence signal that audio works, without requiring hardware/access they don't currently have.

---

## User Stories

- **[P1]** As the developer, I want macOS's `Info.plist` and entitlements to declare the microphone usage keys required by App Sandbox, so that a future macOS build doesn't hard-fail on mic permission.
  Accepted when: `macos/Runner/Info.plist` has `NSMicrophoneUsageDescription` with a non-empty, user-facing string, and both `DebugProfile.entitlements` and `Release.entitlements` have `com.apple.security.device.audio-input` set to `true`.

- **[P1]** As the developer, I want to confirm on the one platform I can actually run (Windows) that a speaking task truly records mic audio to a valid file and plays prompt audio, so that I have at least one real, verified platform before touching the others.
  Accepted when: running any one speaking screen (e.g. Read Aloud) via `flutter run -d windows` produces a `.wav` file with size > 0 bytes after the auto-record window ends, and the task's prompt/listening audio audibly plays.

- **[P3]** _(out of scope — noted for future)_ Real macOS/Linux hands-on permission + record test once a device or teammate is available.

- **[P3]** _(out of scope — noted for future)_ GitHub Actions build matrix (windows/macos/ubuntu-latest) to automate build verification.

---

## Functional Requirements

1. FR-01: `macos/Runner/Info.plist` declares `NSMicrophoneUsageDescription` with a purpose string suitable for App Store / notarization review (explains why the speaking exam needs the mic).
2. FR-02: `macos/Runner/DebugProfile.entitlements` and `macos/Runner/Release.entitlements` both add `com.apple.security.device.audio-input` = `true`, alongside the existing `com.apple.security.app-sandbox`.
3. FR-03: A manual verification pass on Windows (`flutter run -d windows`) exercises at least one speaking screen end-to-end: prompt audio plays, mic records automatically per the timer, and the resulting file is confirmed non-empty (e.g. via `PendingMediaUploadDao` state or checking the file on disk).

---

## Non-Functional Requirements

- Performance: N/A for this round (no perf targets — verification/bugfix only).
- Security: `NSMicrophoneUsageDescription` string must not be a placeholder — it should state the real purpose (speaking exam recording) since macOS review can reject vague usage strings.
- Availability: N/A.

---

## Success Criteria

- [x] `macos/Runner/Info.plist` contains a non-empty `NSMicrophoneUsageDescription` key.
- [x] `macos/Runner/DebugProfile.entitlements` and `macos/Runner/Release.entitlements` both contain `com.apple.security.device.audio-input` = `true`.
- [ ] On Windows, one full speaking-task run (via `flutter run -d windows`) produces a recorded `.wav` file with size > 0 bytes, and prompt audio is confirmed audible. **Partially met:** the app builds and runs on Windows, and the auto-record prep countdown is confirmed live (30→0) after fixing an unrelated build blocker and a dev-preview timer-seeding gap (see plan.md). The recording itself never triggers in the dev-preview harness because `TimerService`'s prep→response phase transition requires a successful server-poll reconciliation, which the harness's fake attempt ID can never get — tracked as a residual risk (plan.md Risks), not confirmed this round.
- [x] `flutter analyze` passes on the touched macOS config files (no YAML/plist syntax errors).

---

## Out of Scope

- Real-device (or cloud-Mac) permission + recording test on macOS — deferred until a device/teammate is available.
- Linux runtime verification — no blocking issue found during scouting, but not exercised this round.
- Real-time mic volume/amplitude meter — genuine feature gap found during scouting (not in `AudioRecorderService` today), tracked for a separate brainstorm/spec.
- GitHub Actions CI build matrix — deferred by explicit user decision this round.
- Playback of the candidate's own recorded answer — not part of real PTE speaking behavior either; not requested.

---

## Assumptions

- The `record` package (v6.2.1) reads the standard macOS App Sandbox microphone entitlement/Info.plist keys the same way other AVFoundation-based recorders do — this is based on Apple's documented sandboxing requirements, not confirmed against a live macOS build in this session.
- Windows needs no additional manifest capability for mic access, since `pte-app` builds as a classic Win32 desktop app (not MSIX/UWP-packaged) — `windows/runner/runner.exe.manifest` was not found to declare any capability-based restrictions.
- Linux (`record_linux`/PipeWire) is assumed unaffected by this fix; not independently verified.

---

## Follow-up (unscheduled, not blocking this spec)

- Real macOS/Linux device access — timeline unknown; revisit once a device or teammate is available. Not required for this spec's FRs.
- GitHub Actions CI build matrix — explicitly deferred this round per user decision; revisit as a separate brainstorm/plan when prioritized.
- Confirm the actual mic-open/record-to-file step on Windows — needs either a fake `TimerRepository` for the dev-preview harness (so its fake attempt can poll successfully and reach `TimerPhase.response`) or a real `pte-api` backend + login flow. Found and root-caused during this round's Phase 2, not fixed (developer chose to stop rather than expand scope further).
