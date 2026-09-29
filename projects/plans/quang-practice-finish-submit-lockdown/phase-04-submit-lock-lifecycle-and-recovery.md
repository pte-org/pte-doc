# Phase 4 — Acknowledgement lifecycle, retry, and recovery

## Objective

Connect the Finish exam UI, attempt submission, sync/media readiness, and native exit guard into one monotonic lifecycle that behaves correctly under success, failure, duplicate events, timer expiry, and relaunch.

## Scope and likely files

- `pte-app/lib/features/exam_attempt/...` bloc/application state and events.
- `pte-app/lib/core/sync/sync_engine.dart` and media upload coordinator.
- `pte-app/lib/core/network/api_client.dart` and exception mapping.
- `pte-app/lib/core/security/lockdown_service.dart` and Phase 3 guard.
- `pte-app/lib/app.dart` exam route/state listener.
- Existing attempt and lockdown tests.
- `pte-api` only if Phase 1 proves a server response/idempotency gap.

## Steps

1. On task-shell entry, activate the guard before rendering the first task. If activation fails, keep the existing failure/retry behavior and do not silently start an unguarded exam.
2. On manual Finish exam:
   - snapshot answered/unanswered counts for the dialog;
   - flush/reconcile pending answer and media work through the existing sync boundary;
   - issue one terminal force-submit command;
   - keep native exit blocked.
3. On success, transition the application owner to an acknowledgement-bearing submitted state, then in order:
   - record success audit/event;
   - stop attempt-specific sync/timers as the existing lifecycle requires;
   - tell the native guard exit is allowed;
   - release fullscreen;
   - show the submitted completion surface.
4. On failure, keep the app in the guarded task shell, map the error to retryable/non-retryable UI behavior, and make Retry re-enter the same single-flight submission function.
5. Treat an already-terminal server response as successful reconciliation when the server proves the attempt is submitted. Do not loop or show a false retry state.
6. Ensure timer expiry enters the same terminal acknowledgement gate. Preserve the existing automatic force-submit rule; do not add a second timer or alter countdown semantics.
7. Ensure final-task navigation cannot unlock the app before the server terminal response. If the current bloc emits `AttemptCompleted` earlier, split or annotate the state so the exit guard still observes acknowledgement.
8. On app relaunch/resume, fetch the current server attempt state before deciding whether to activate an active guard or show submitted state. A stale local completion marker must never grant exit.
9. Verify route pops, app lifecycle callbacks, native close signals, and timer events all converge on the same guard owner. Remove any alternate direct `SystemNavigator.pop`/window-close path from active exam screens if present.
10. Add user-facing copy for offline/retry and submitted states without exposing raw HTTP/stack-trace text.

## Design Constraints

- Monotonic terminal security: no failure or local completion can move to exitable.
- Manual submission can be incomplete and is intentional.
- Do not block indefinitely waiting for media; return a retryable state with a clear cause if required terminal preparation cannot complete.
- Do not duplicate answer submission APIs or bypass current encryption/integrity policy paths.
- Keep host/proctor/report scope untouched.
- Preserve current timer and route behavior except where required to prevent premature exit.

## Quality and Testing State

- **Quality:** APPROVED. Receipt: `quality/phase-04-submit-lock-lifecycle-and-recovery-receipt.json`.
- **Testing:** PASSED. `93` focused lifecycle/sync/security tests, `14` exam widget tests, and the changed-scope analyzer passed. The release/manual Windows matrix is Phase 5.

## Acceptance criteria

- Every exit path observes the same acknowledgement gate.
- Healthy submission unlocks only after the server response is received.
- Failed submission never unlocks and can be retried without duplicating terminal work.
- Timer expiry still submits according to existing behavior and does not bypass the guard.
- Relaunch with an active server attempt returns to guarded state.
