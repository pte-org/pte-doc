# Implementation Plan: Student Finish/Submit Gate and App-Level Exam Exit Lock

**Status:** In progress — Phases 1–4 complete; Phase 5 release build ready, manual matrix pending
**Date:** 2026-09-28
**Mode:** Hard plan; security-sensitive, multi-layer, release-demo oriented
**Repositories:** `pte-app`, `pte-api`, `pte-doc`
**Parent plan:** `pte-doc/projects/plans/quang-practice-anti-cheat-policy/plan.md`

## Execution progress

- [x] Phase 1 — terminal submission contract and client state model
- [x] Phase 2 — Finish exam UI and confirmation
- [x] Phase 3 — app-level exit guard and native bridge
- [x] Phase 4 — acknowledgement lifecycle, retry, and recovery
- [ ] Phase 5 — Windows release demo verification (release build/stack ready; interactive matrix pending)

## 1. Outcome

Deliver a demoable Windows student flow in which the student can always finish an exam, can submit an incomplete attempt, and cannot intentionally leave the active attempt before the server confirms terminal submission. After acknowledgement, the app unlocks and permits exit. The implementation remains app-level and explicitly does not configure Windows Assigned Access/Shell Launcher.

## 2. Existing baseline to preserve

The implementation must build on the current work rather than introduce a parallel flow:

- `pte-app/lib/core/security/lockdown_service.dart` already owns policy activation, fullscreen coordination, violation reporting, and native integration.
- `pte-app/windows/runner/lockdown_plugin.cpp` and `.h` already provide Windows-side hooks. The plugin must remain non-blocking and report events back to Dart rather than perform network work on the Windows message thread.
- `pte-app/windows/runner/flutter_window.cpp` already passes the top-level runner window handle to the lockdown plugin. Preserve this fix.
- `pte-app/windows/runner/main.cpp` already keeps login centered and bounded. Preserve the distinction between normal login and guarded exam windows.
- `pte-app/lib/features/exam_attempt/...` already has `ForceSubmitRequested`, `AttemptCompleted`, repository force-submit behavior, answer synchronization, and timer-expiry handling. Reuse the canonical path after verifying the exact response semantics.
- `pte-app/lib/core/widgets/exam/exam_header_bar.dart`, `exam_footer_bar.dart`, `exam_navigation_actions.dart`, `task_advance_button.dart`, `confirm_dialog.dart`, and `primary_button.dart` are the shared chrome/action surface. Do not add task-type-specific finish buttons.
- The parent anti-cheat plan already defines the practice policy flag and warning/audit semantics. This plan consumes that policy; it does not redesign it.

## 3. Scope guard

Every implementation decision must satisfy these rules:

1. Student app only. Do not change proctor or host workflows.
2. Demo-first app lock. Do not touch OS policy, registry, Assigned Access, or Shell Launcher.
3. Submit is allowed with unanswered tasks.
4. Server acknowledgement, not a local route/state change, unlocks exit.
5. Keep timer behavior and current scoring/reporting boundaries.
6. Preserve the centered windowed login and fullscreen only after the guarded exam/device-check phase begins.
7. Prefer extending existing public services and repositories over cross-layer reach-through.

## 4. Dependency and risk map

| Dependency/risk | Handling |
|---|---|
| Existing `AttemptCompleted` may represent local task exhaustion rather than acknowledged submit | Trace repository/API response first; add an explicit acknowledgement-bearing result/event if needed. Do not unlock from state name alone. |
| Speaking recordings may still be uploading when Finish exam is pressed | Reuse the existing sync/media flush contract; surface retry when terminal preparation cannot be completed. |
| Alt+Tab cannot be absolutely blocked by a normal Windows app | Detect focus loss, audit, restore focus/fullscreen where possible, and document the limitation. |
| Native close handlers can deadlock if they await Dart/network work | Native layer only vetoes/queues a signal; Dart owns user-facing warning/audit. |
| User clicks submit repeatedly or network retries overlap | One command owner, in-flight guard, and terminal-state reconciliation. |
| Process is killed outside the app | On next launch, query/rehydrate server attempt state; never treat local absence as submitted. |
| Existing dirty worktree has prior fullscreen/UI changes | Make targeted changes only; inspect diffs before editing and do not reset unrelated work. |

## 5. Phase sequence

| Phase | Deliverable | Main repository | Depends on |
|---|---|---|---|
| 1 | Terminal submission contract and client state model | `pte-api`, `pte-app` | Parent anti-cheat baseline |
| 2 | Shared Finish exam UI and confirmation flow | `pte-app` | Phase 1 |
| 3 | App-level exit guard and native Windows event bridge | `pte-app` | Phase 1 |
| 4 | Submission/lock lifecycle integration, retry, and recovery | `pte-app`, targeted `pte-api` only if contract gap is proven | Phases 2–3 |
| 5 | Release build and demo verification matrix | `pte-app`, `pte-doc` | Phase 4 |

## 6. Cross-phase state ownership

Use the following ownership model:

- `ExamAttemptBloc` (or the existing attempt application owner) owns terminal submission intent, in-flight protection, acknowledgement, retryable failure, and completion reason.
- A dedicated small `ExamExitGuard`/equivalent application service owns whether exit is allowed and delegates native window commands to `LockdownService`. If adding a new service is unnecessary, extend `LockdownService` with an explicit terminal-exit permission rather than adding widget-local callbacks.
- Shared exam chrome renders actions from the application state. It must not call the API directly.
- The native Windows plugin owns message-thread interception and emits lightweight violation/focus signals. It must not decide that a local screen is submitted.

Canonical rule:

```text
server terminal acknowledgement -> application Submitted state
Submitted state -> allow native exit + release fullscreen
anything else -> remain guarded
```

## 7. Phase deliverables

Detailed steps and acceptance criteria live in the phase files:

1. [Phase 1 — terminal submission contract and state model](phase-01-terminal-submit-contract-and-state.md)
2. [Phase 2 — Finish exam UI and confirmation](phase-02-finish-exam-ui-and-confirmation.md)
3. [Phase 3 — app-level exit guard and native bridge](phase-03-app-exit-guard-and-native-bridge.md)
4. [Phase 4 — acknowledgement lifecycle, retry, and recovery](phase-04-submit-lock-lifecycle-and-recovery.md)
5. [Phase 5 — Windows release demo verification](phase-05-windows-release-demo-verification.md)

## 8. End-to-end acceptance matrix

| Scenario | Expected result |
|---|---|
| Open login | Normal centered bounded window; no fullscreen/exit guard. |
| Enter Device Check | Existing fullscreen behavior remains; no login regression. |
| Enter first task | Fullscreen/app guard active; finish action visible. |
| Press Finish with all tasks unanswered | Confirmation shows counts; submit remains enabled. |
| Confirm submit with healthy API | One terminal request; submitted state only after response; then explicit exit is available. |
| Confirm submit while API is offline | Retryable failure; task remains; window remains guarded; no exit. |
| Double-click submit | One in-flight command; no duplicate terminal transition. |
| Close/Alt+F4 before submit | Close is vetoed/re-armed where supported; warning and audit emitted. |
| Minimize/focus loss/Alt+Tab before submit | Warning/audit; fullscreen/focus re-arm best effort; app remains in attempt. |
| Timer expires | Existing timer rule is preserved; terminal path still requires acknowledgement before exit. |
| Relaunch with server-active attempt | Attempt is guarded again; local stale state cannot unlock it. |
| After successful submit, click Exit application | Lock releases and normal close succeeds. |
| Windows OS task switching | Known limitation documented; app-level response is observable, not a kiosk guarantee. |

## 9. Verification strategy

The plan is implementation-ready, but no tests or quality checks are run while writing the plan. Each phase has an explicit testing/quality state so the cook run can choose the appropriate checks. The release phase includes manual validation because native Windows window behavior cannot be established by Dart unit tests alone.

Minimum verification before demo:

- `flutter analyze` on changed app/native bridge surfaces, or a focused analyzer if unrelated baseline errors prevent a full run.
- Focused Dart unit/widget tests for the terminal state machine, confirmation UI, and exit guard.
- Windows release build: `flutter build windows --release`.
- Manual release matrix from Phase 5 using a real local session and the test student.
- Read-only inspection of server attempt status and audit events after success/failure cases.

## 10. Rollback and safety

- Feature rollback must be possible by disabling the new finish/exit guard integration while preserving existing attempt submission and fullscreen behavior.
- Never delete local Docker volumes or reset dirty repositories to recover from a failed demo.
- Do not print credentials, access tokens, audio payloads, or `.env` values in logs or plan artifacts.
- If native interception causes a startup regression, temporarily keep the native hook passive and retain the Dart confirmation/submit flow while diagnosing; do not bypass server acknowledgement in production code.

## 11. Handoff

After the three open copy/expiry choices in `spec.md` are confirmed, implement with:

```text
/ck:cook --hard --plan D:\GitHub\pte-org\pte-doc\projects\plans\quang-practice-finish-submit-lockdown\plan.md
```

The cook run should confirm tests and quality checks per phase. The final release/demo claim is not valid until Phase 5's manual matrix has been executed against a release binary.
