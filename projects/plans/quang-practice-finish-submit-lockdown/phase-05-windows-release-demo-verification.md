# Phase 5 — Windows release build and demo verification

## Objective

Prove the intended demo flow with a real Windows release binary and document the exact app-level limitation so the result is not mistaken for an OS kiosk.

## Scope and artifacts

- `pte-app` release build output and local launch procedure.
- `pte-doc/projects/plans/quang-practice-finish-submit-lockdown/` verification notes/checklist.
- Existing anti-cheat ADR/checklist from the parent plan, updated only for the new finish/exit boundary.
- Local API/session data already used for the student demo.

## Steps

1. Confirm local API and web stack are healthy without printing `.env` values or credentials.
2. Build the Windows release binary:

   ```powershell
   cd D:\GitHub\pte-org\pte-app
   flutter build windows --release
   ```

3. Launch the release binary, verify login remains centered and bounded, and enter the provided local student session.
4. Execute the manual matrix below and capture only non-sensitive screenshots/log summaries.
5. Verify server-side attempt status after success and failure cases. Confirm the final successful state is visible in the host-facing flow without changing host/proctor code in this scope.
6. Record known limitations: Alt+Tab is detected/reacted to best effort; absolute prevention requires managed Windows kiosk configuration and is deferred.
7. If the release build fails, diagnose the changed app/native surface first. Do not delete Docker volumes or reset unrelated worktree changes.

## Manual demo matrix

| ID | Action | Expected |
|---|---|---|
| D-01 | Start app | Login is normal windowed, centered, max-bounded. |
| D-02 | Login and enter Device Check | Device Check enters fullscreen as already implemented. |
| D-03 | Enter exam | First task is fullscreen; finish action is visible. |
| D-04 | Visit speaking/listening/reading/writing | Shared finish action remains visible across all four skills/task types. |
| D-05 | Finish with zero answers | Counts are shown; submit is allowed after confirmation. |
| D-06 | Finish with partial answers | Counts are correct; submit is allowed. |
| D-07 | Double-click Submit | One terminal request; controls show in-progress state. |
| D-08 | Disable API/network during submit | Retryable error; task remains; close/Alt+F4 does not intentionally exit. |
| D-09 | Restore API and Retry | Server acknowledgement transitions to submitted. |
| D-10 | Close/Alt+F4 before submit | App remains in guarded attempt; warning/audit is observable. |
| D-11 | Minimize/focus loss/Alt+Tab | Warning/audit and best-effort re-arm; known OS limitation recorded. |
| D-12 | Let timer expire | Existing timer behavior submits through the same acknowledgement gate. |
| D-13 | After successful submit | Submitted state appears; explicit exit works; fullscreen/guard is released. |
| D-14 | Relaunch before submit if feasible | Server-active attempt returns guarded; no local unlock bypass. |

## Design Constraints

- Release/demo evidence must distinguish app-level behavior from OS-level guarantees.
- Do not install or modify Windows kiosk policies.
- Use local-only data and avoid exposing credentials in artifacts.
- Manual acceptance is required for native window behavior even if automated tests pass.

## Quality and Testing State

- **Quality:** Release scope reviewed; no implementation blocker found. The final gate remains open until the interactive Windows matrix is observed.
- **Testing:** Release build passed (`flutter build windows --release`), the local Compose stack is healthy, and the release process launched successfully. D-01 through D-14 still require an operator-visible run with a valid local student session; Docker was initially unavailable and was then started locally, so no session result is being invented here.

## Current execution evidence

- Release artifact: `pte-app/build/windows/x64/runner/Release/pte_app.exe`.
- Local API health: `http://localhost:8091/actuator/health` returned HTTP 200; the application container reported healthy.
- Docker was started with the existing local Compose files; no volumes were deleted.
- The release binary is running as `pte_app`; the remaining evidence is the manual login/device-check/exam interaction and host-side status check.

## Acceptance criteria

- A release binary completes D-01 through D-13, with D-14 attempted where the local session lifecycle permits.
- The app does not unlock before a server-confirmed terminal state.
- The student can submit incomplete work and then exit normally after success.
- The demo notes clearly state that this is not Assigned Access/Shell Launcher kiosk security.
