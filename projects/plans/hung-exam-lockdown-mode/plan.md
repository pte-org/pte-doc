# Plan: Exam Lockdown Mode

**Spec:** [spec.md](spec.md)
**Date:** 2026-09-07
**Status:** Ready
**Mode:** Hard
**Created by:** Plan Agent

---

## Overview

This plan delivers strict exam lockdown enforcement for Flutter desktop app (Windows only) during exam attempts, ensuring exam integrity through comprehensive system-level controls. Students taking STRICT-mode exams will be locked into fullscreen with blocked clipboard operations, disabled system shortcuts, prevented screenshots, and auto-terminated third-party applications. Violations are reported real-time to proctors via WebSocket. The lockdown mechanism is policy-driven (extends ExamPolicy with lockdownMode: NONE/STANDARD/STRICT), transparent to exam flow, and automatically activates/deactivates with attempt lifecycle.

## Phases

- [x] Phase 1: Backend Policy Extension [quality: approved; testing: skipped] — Extend `ExamPolicy` entity with `LockdownMode` enum (NONE/STANDARD/STRICT); add to DTOs (ExamPolicyResponse, EntitlementResponse, AttemptTaskResponse); update default policies (PRACTICE→NONE, MOCK_TEST→STANDARD, REAL_EXAM→STRICT); extend ViolationType enum with lockdown violations.
- [x] Phase 2: Platform Channels Foundation [quality: approved; testing: skipped] — Implement Flutter platform channels (WindowManagerChannel, ProcessManagerChannel, ClipboardMonitorChannel, ShortcutInterceptorChannel) and native plugin for Windows C++ with method signatures and event streams (EventSink deferred to Phase 3).
- [ ] Phase 3: Native Windows Implementation [quality: pending; testing: pending] — Implement Windows lockdown plugin in C++: fullscreen enforcement with WH_KEYBOARD_LL hooks blocking Alt+Tab/Win+D/PrintScreen, clipboard monitoring, process enumeration/termination via ToolHelp32, violation event callbacks to Dart.
- [ ] Phase 4: Flutter Service Layer [quality: pending; testing: pending] — Implement LockdownService (activation/deactivation/monitoring orchestration), ViolationReporter (offline-first local storage + HTTP reporting with retry), forbidden apps config loading, integration with ExamAttemptBloc lifecycle.
- [ ] Phase 5: UI & Error Handling [quality: pending; testing: pending] — Implement lockdown activation failure dialog, violation warning banner (STANDARD mode), user-facing error messages, local violation Drift table, Drift DAO for offline queueing.

**Plan status: IN_PROGRESS — Phase 1-2 complete, Phase 3 ready.**

## Research Summary

Architectural decisions locked during brainstorm (applied as-is, not for re-derivation):

1. **ExamPolicy.lockdownMode extension** — New enum column on `scheduling`'s `ExamPolicy` (@Embeddable), mirroring existing `answerIntegrityLevel` pattern. Mode-based defaults: PRACTICE→NONE (no enforcement), MOCK_TEST→STANDARD (warnings only), REAL_EXAM→STRICT (full enforcement). Nullable column with @PostLoad backfill to NONE for legacy sessions.

2. **Platform-specific native plugins** — Flutter cannot enforce OS-level lockdown via Dart alone. Windows requires WH_KEYBOARD_LL low-level keyboard hooks (blocks shortcuts before they reach OS), ToolHelp32 process enumeration, SetWindowLong fullscreen enforcement. Exposed via MethodChannel to Dart.

3. **Forbidden apps list is JSON-configurable** — `assets/config/forbidden_apps.json` with platform-specific arrays (windows: `["chrome.exe", "discord.exe", ...]`). LockdownService loads at activation time, attempts termination for STRICT mode only. STANDARD mode detects but does not kill.

4. **Violation reporting is offline-first** — ViolationReporter writes to local Drift table (`local_violations`) immediately, attempts HTTP POST to `/api/proctor/violations` (reusing existing endpoint + ViolationType enum), marks `sent:true` on success. SyncEngine-style retry on connectivity restore. No new proctor endpoint needed — existing `/api/proctor/violations` already accepts FlagViolationRequest.

5. **Lockdown activation blocks exam start on failure** — For STRICT mode, if fullscreen enforcement, process termination, or shortcut hooking fails, LockdownService returns error and ExamAttemptBloc prevents StartAttempt. User sees activation failure dialog with retry option. STANDARD mode allows degraded start (logs failure but doesn't block).

6. **Clipboard blocking strategy: block external paste only** — User requirement was "block external paste, allow internal copy/paste". Windows: monitor clipboard change events (AddClipboardFormatListener), track source (SetClipboardViewer chain), reject paste if source is external process. Internal app copy/paste (within pte-app) is allowed.

7. **Admin privileges for process termination** — Windows TerminateProcess requires PROCESS_TERMINATE access right, which needs elevated privileges for protected processes (browsers, system apps). App must request UAC elevation on launch when starting STRICT-mode exam. Elevation check happens at lockdown activation; if denied, fallback to detection-only (log violations, don't kill).

8. **Lockdown lifecycle tied to ExamAttemptBloc** — Activation: in `_onStartOrResumeAttempt`, after successful `repository.startOrResume()`, check `response.lockdownMode`; if not NONE, call `await lockdownService.activateLockdown(mode)`. Deactivation: in `_onCompleteAttempt`, after submission, call `await lockdownService.deactivateLockdown()`. Also deactivate on app dispose/crash via AppLifecycleObserver.

9. **ViolationType enum extensions** — Reuse existing `com.pte.proctor.domain.enums.ViolationType` (already has SCREENSHOT_DETECTED, TAB_SWITCH, etc.). Add: LOCKDOWN_FULLSCREEN_EXIT, LOCKDOWN_CLIPBOARD_PASTE, LOCKDOWN_SCREENSHOT_ATTEMPT, LOCKDOWN_SHORTCUT_BLOCKED, LOCKDOWN_FORBIDDEN_APP_DETECTED. No schema migration needed (enum values are code-only).

10. **No VM detection or multi-monitor blocking in Phase 1** — Open question "Should we detect VMs?" answered: not in initial scope (high false-positive risk with development VMs, Docker Desktop, WSL2). Multi-monitor handling: fullscreen enforced on primary display only; secondary displays are not blocked (proctor can see via screen share if student switches to secondary). Both are deferred post-MVP based on real violation data.

## Dependencies

- Existing `scheduling` service with `ExamPolicy` (@Embeddable on `ExamSession`), `SessionService`, `ExamMode` enum.
- Existing `exam-delivery` service with `AttemptService`, `AttemptController`, `ExamAttempt` entity, `SnapshotPinService` (pins policy at StartAttempt).
- Existing `proctor` service with `ViolationService`, `POST /api/proctor/violations` endpoint, `ViolationType` enum.
- Existing `pte-app` (Flutter) with `ExamAttemptBloc`, `lib/core/network/api_client.dart`, `lib/core/sync/sync_engine.dart` (for retry pattern).
- Windows SDK: `windows.h`, `tlhelp32.h`, `shellapi.h` (process enumeration, hooks).
- Flutter: `flutter/services.dart` (MethodChannel), Drift (local violation storage).

## Risks

- **CRITICAL — Platform channel interop failure modes**: If native plugin crashes (e.g., null pointer in C++ hook), Flutter app crashes entirely (no graceful fallback). Mitigation: Phase 2/3 wrap every native call in try-catch (C++), return error Result to Dart instead of throwing across FFI boundary. Phase 4 LockdownService treats activation errors as exam-blocking for STRICT, warning-only for STANDARD.
- **CRITICAL — UAC permission denial UX**: If user denies UAC elevation (Windows), process termination silently fails (no error returned by OpenProcess). User thinks lockdown is active but forbidden apps are still running. Mitigation: Phase 3 test actual termination capability after activation (try to terminate a known-safe test process, verify exit code), surface permission error explicitly in activation result. Phase 4 shows specific "Permissions required" dialog with OS-appropriate instructions.
- **HIGH — Keyboard hook conflicts with accessibility tools**: Windows WH_KEYBOARD_LL hooks can prevent screen readers, sticky keys, or other assistive tech from functioning. Disabling these violates accessibility law in some jurisdictions. Mitigation: Phase 3 allowlist specific accessibility-related VK codes (VK_LSHIFT/VK_RSHIFT held for sticky keys, VK_NUMLOCK for mouse keys), log allowlist hits but don't block them. STANDARD mode does not install hooks (detection-only).
- **MEDIUM — Clipboard monitoring performance**: AddClipboardFormatListener (Windows) fires on every clipboard change system-wide, including non-text formats (images, files). Monitoring thread could consume CPU if student repeatedly copies large data. Mitigation: Phase 3 filter clipboard events by format (CF_TEXT/CF_UNICODETEXT only), debounce rapid-fire events (max 1 check per 100ms). Log warning if event queue exceeds 50 pending.
- **MEDIUM — Fullscreen edge case: multiple monitor disconnect/reconnect**: If student unplugs monitor while in fullscreen, Windows may resize window to new primary display bounds, briefly showing desktop/taskbar. Mitigation: Phase 3 register for WM_DISPLAYCHANGE messages, re-apply fullscreen rect on display config change. Test with USB display adapters.
- **MEDIUM — Partial deployment ordering**: Phase 1 (backend) must deploy before Phase 4/5 (app), otherwise app requests lockdownMode field that backend doesn't return (breaks StartAttempt). Phase 4/5 app must not ship until Phase 1 is live in target environment. Mitigation: deploy backend first, verify `/api/exam-delivery/attempts` response includes `lockdownMode` via Postman/curl before releasing new app version.
- **LOW — Process name spoofing**: Malicious student could rename `chrome.exe` to `notepad.exe` to evade forbidden-apps detection. Mitigation: acknowledged but not mitigated in Phase 1 (signature verification of running processes requires kernel-mode driver or Admin-level access we don't have). Proctor's real-time screen share is the primary catch; lockdown is a deterrent layer, not cryptographically bulletproof.
- **NOTED (out-of-scope)**: Network activity monitoring (detect unauthorized VPN/hotspot), screenshot prevention via DRM flags (Windows DXGI overlays, macOS CGDisplayCapture block), and VM detection (check CPUID hypervisor bit, SMBIOS manufacturer) are all deferred to post-MVP based on actual cheating patterns observed in production. Phase 1 focuses on the explicitly-requested constraints only.

### Cook-time infra note (applies to all 5 phases)

Same limitation as sibling plans: `ck:quality`'s receipt mechanism requires one git repo containing both the quality report and every reviewed file, but this project spans 4 separate repos (`pte-api`, `pte-app`, `pte-web`, `pte-doc`) under a non-repo parent. Cryptographic receipts are skipped; each phase's `## Quality and Testing State` records the `ck:quality --gate` result directly, with the JSON report saved under `quality/{phase}-quality-report.json` in this plan directory.

### Red-team review

Pending — will run `plan-reviewer` after Phase 1 spec is finalized.

---

## Cook Order Recommendation

Phases must be cooked in strict sequence due to dependency chain:

1. Phase 1 (backend policy extension) — unblocks all Flutter phases
2. Phase 2 (platform channels foundation) — unblocks Phase 3/4
3. Phase 3 (Windows native impl) — implements native lockdown
4. Phase 4 (Flutter service layer) — depends on Phase 2/3
5. Phase 5 (UI & error handling) — depends on Phase 4

Suggested invocation:

```
/ck:cook pte-doc/projects/plans/hung-exam-lockdown-mode/phase-01-backend-policy-extension.md
/ck:cook pte-doc/projects/plans/hung-exam-lockdown-mode/phase-02-platform-channels-foundation.md
/ck:cook pte-doc/projects/plans/hung-exam-lockdown-mode/phase-03-windows-native-impl.md
/ck:cook pte-doc/projects/plans/hung-exam-lockdown-mode/phase-04-flutter-service-layer.md
/ck:cook pte-doc/projects/plans/hung-exam-lockdown-mode/phase-05-ui-error-handling.md
```

## Teacher Override Extension (FR-07) — 2026-09-09

Phase 1 originally documented override via `PATCH /sessions/{id}/policy` only.
This extension adds override at session creation time.

**FR-07**: Teacher có thể override `LockdownMode` khi tạo session thông qua
`CreateSessionRequest.lockdownMode` (optional, 6th field). Override thắng ExamMode default.

- `CreateSessionRequest.lockdownMode` (optional, nullable)
- Teacher override wins over `ExamMode` default
- Validation: `PRACTICE + STRICT` → HTTP 400 (`IllegalArgumentException`)

See: [spec.md](spec.md) "Teacher Override Extension (FR-07)" and
[phase-01-backend-policy-extension.md](phase-01-backend-policy-extension.md) Step 3 (extended section)
