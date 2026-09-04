# Plan: Speaking Task Audio — macOS Mic Gap Fix + Windows Verification
Status: 🟢 Done (Phase 2 partially verified — see Session Notes)
Date: 2026-08-24
Mode: Fast

## Overview
Close a scouted macOS mic-permission gap (missing Info.plist/entitlement keys) in the already-implemented speaking-task audio flow, then manually verify on Windows — the only platform currently testable — that recording and playback work end-to-end.

## Phases
- [x] Phase 1: macOS Mic Permission Config — add `NSMicrophoneUsageDescription` and the `audio-input` entitlement to the 3 affected macOS files
- [x] Phase 2: Windows Manual Audio Verification — partially verified: prep countdown confirmed live (30→0) after an in-scope dev-preview timer-seeding fix; full auto-record trigger (phase→response, mic actually opening) not confirmed this round — needs a real backend attempt to poll against (see Session Notes)

## Research Summary
N/A (Fast mode — gap and fix were identified during scouting, no separate research phase run).

## Dependencies
None. Both phases touch disjoint files and can be done in either order; neither depends on an external service. Phase 1 cannot be build-verified without macOS hardware (see Risks).

## Risks
- HIGH: macOS entitlement/Info.plist changes cannot be build- or run-verified this round — no macOS hardware available. Mitigation: keys and values are set exactly per Apple's documented App Sandbox microphone-access requirements (same mechanism AVFoundation-based recorders rely on); tracked as an explicit residual risk per the spec's Follow-up section, to be confirmed once a macOS device or teammate is available. Not a blocker for this plan's completion.
- LOW: Windows verification is a one-time manual checklist, not an automated test. Mitigation: checklist is explicit and reproducible by any developer with a Windows machine and a working mic; CI/build-matrix automation is explicitly deferred (spec Out of Scope).
- LOW: Malformed plist/entitlements XML could silently break a future macOS build. Mitigation: Phase 1 success criteria requires the files remain well-formed plist XML and that `flutter analyze` stays clean.
- MEDIUM (new, found during Phase 2): `TimerService`'s prep→response phase transition is driven exclusively by a successful server poll (`GET .../timer`) reconciling `_phase` — the local sub-second tick loop only advances the displayed countdown number, never the phase itself (by design, phase-04 Design Constraints: "phase is self-derived only on the very first seed... every later reconciliation adopts the server's own phase field directly"). This is why the dev-preview harness (fake `attemptPublicId`, no real backend attempt to poll) can show the prep countdown reaching 0 but never flips to "Recording" / never opens the mic. Not fixed this round (user chose to stop rather than add a fake `TimerRepository` for dev-preview). Residual, unverified risk: if this same poll genuinely fails repeatedly in production right at the prep→response boundary (network hiccup), a real candidate's recording could also fail to auto-start — mitigated in production by the poll's own retry loop (fires again every `_defaultPollInterval` = 10s) succeeding on a later attempt, unlike dev-preview's permanently-failing fake ID. Worth a dedicated follow-up investigation, not scoped here.

## Session Notes
<!-- Updated by cook automatically — do not edit manually -->

**Last active:** 2026-08-24 (Phase 1 + Phase 2 done, Phase 2 partially verified)
**Phase in progress:** none — plan complete for this round
**Status:** Both phases done. Prep-countdown timer wiring confirmed live on Windows; full mic-recording trigger not confirmed (blocked on needing a real backend attempt) — stopped here per developer decision, tracked as a residual risk.

### Decisions made this session
- Used the exact `NSMicrophoneUsageDescription` string confirmed by the developer: "This app needs microphone access to record your spoken answers during PTE speaking exam tasks."
- `flutter analyze` surfaced 2 pre-existing errors in `re_order_paragraphs_list.dart` (reading feature) — confirmed via `git status`/`git diff --stat` to be unrelated to this plan's 3 touched files.
- Reverted an incidental `pubspec.lock` change that `flutter analyze` triggered (dependency re-resolution) to keep the diff scoped to only the intended macOS files.
- **Scope expansion #1 (approved by developer):** the `re_order_paragraphs_list.dart` errors turned out to be a hard Windows build blocker (`onReorderItem` doesn't exist on `ReorderableListView` in the installed Flutter 3.41.9 stable) — fixed by reverting to `onReorder` with the standard pre-removal index adjustment, since `ReOrderParagraphsCubit.reorder` already expected that exact semantics per its own doc comment. Verified with a targeted `flutter analyze` pass (no issues) and a full successful `flutter run -d windows`.
- **Scope expansion #2 (approved by developer):** `SpeakingWritingTaskPreviewScreen` (the dev-only harness used to reach a speaking screen without login) never dispatched anything to `ExamAttemptBloc`, so it never left its initial state and the auto-record countdown was permanently frozen. Added a `kDebugMode`-only `DevPreviewAttemptSeeded` event + handler (mirrors `_emitFromResponse`'s in-progress seeding, minus the network call) and wired `SpeakingWritingTaskPreviewScreen` to dispatch it on task selection. Verified: the prep countdown now genuinely ticks 30→0 live (confirmed by the developer's screenshot).
- **Stopped short of Scope expansion #3:** once countdown hits 0, `TimerService` only flips `prep`→`response` phase on a *successful server poll* reconciliation (by design — local ticks never self-advance phase). The dev-preview's fake `attemptPublicId` can never poll successfully, so phase — and therefore the actual `record` package `start()` call — never fires in this harness. Fixing that would need a fake `TimerRepository` + DI wiring for dev-preview, which the developer opted not to do this round; the plan's audio-recording-trigger success criterion is therefore not confirmed on Windows this round (see plan.md Risks).

### Next immediate action
None queued. Follow-up options (not scheduled): (a) add a fake `TimerRepository` for dev-preview to finish this verification without a backend, or (b) verify via a real `pte-api` backend + login instead of the dev-preview harness.
