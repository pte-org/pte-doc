# Phase 04 — PTE App Policy Activation, Audit Adapter, Retry, and Fail-Closed Behavior

**Depends on:** Phases 1 and 3  
**Enables:** Phase 5 Windows release gate  
**Stories:** P1 activation before task; P1 warning/audit without losing attempt

## Objective

Make the Windows student app consume the pinned policy safely, preserve the
existing activation-before-render ordering, send audit events to the
authenticated student contract, and make offline delivery eventually
idempotent. Practice `STANDARD` remains warning/audit-only.

## Exact files/packages likely to change

- `pte-app/lib/core/security/lockdown_mode.dart`
- `pte-app/lib/core/security/models/violation_event.dart`
- `pte-app/lib/core/security/violation_reporter.dart`
- `pte-app/lib/core/security/lockdown_service.dart` only for minimal event
  construction or warning/audit plumbing; no enforcement escalation
- `pte-app/lib/core/security/violation_retry_coordinator.dart` (new), unless an
  existing security lifecycle owner is selected after implementation review
- `pte-app/lib/core/di/security_module.dart`
- `pte-app/lib/core/storage/app_database.dart`
- `pte-app/lib/core/storage/tables/local_violations_table.dart`
- `pte-app/lib/core/storage/dao/local_violation_dao.dart`
- generated `pte-app/lib/core/storage/app_database.g.dart`
- generated `pte-app/lib/core/storage/dao/local_violation_dao.g.dart`
- `pte-app/lib/features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart`
- `pte-app/lib/features/exam_attempt/domain/task_view.dart` only if required
  to make the response policy non-null/type-safe
- focused tests under:
  - `pte-app/test/unit/core/security/lockdown_service_test.dart`
  - `pte-app/test/unit/features/exam_attempt/exam_attempt_bloc_lockdown_test.dart`
  - `pte-app/test/unit/storage/local_violation_dao_test.dart`
  - new `violation_reporter`/retry contract tests
  - relevant warning-banner widget test

## Implementation steps

1. Change the policy parser so an unknown non-null wire value raises a typed
   policy/attempt error. Do not turn an unknown value into `LockdownMode.none`.
   Treat a null response as an error for a new attempt; the backend response
   mapper is responsible for normalizing documented legacy rows before the app
   receives them.
2. Preserve the existing `ExamAttemptBloc` order:

   ```text
   start/resume attempt -> read pinned lockdownMode
   -> activateLockdown -> only then start sync/timer/render task 1
   ```

   Activation failure must continue to emit the retryable attempt error and
   must not arm `SyncEngine` or render a task. `NONE` remains the only no-op.
3. Keep `LockdownService` semantics explicit:
   - `STANDARD`: fullscreen, clear/block clipboard, block shortcuts, monitor;
   - `STRICT`: Standard plus existing configured forbidden-app action;
   - any reported violation: warning UI plus audit only for Practice Standard;
     no pause, force-submit, invalidate, or terminate path is added.
4. Extend the local violation event/model with a stable UUID
   `clientEventId`. Keep local severity for diagnostics if useful, but do not
   send client severity as an authority field. Serialize only the new endpoint
   contract: `clientEventId`, allowlisted type, optional client occurrence time,
   and bounded detail; the attempt ID belongs in the URL.
5. Replace both reporter POST locations (initial send and retry) with
   `/api/v1/attempts/{attemptPublicId}/security-violations` and the Phase 3
   payload. Mark a row sent only after a successful or idempotent receipt.
   Treat authentication refresh through the existing API client as normal;
   retain retryable rows on network/5xx failures.
6. Add local Drift schema version 5. Add `client_event_id` to fresh tables and
   backfill existing rows during upgrade before they are retried. If SQLite
   cannot add the non-null constraint directly, add the column, generate IDs
   for existing rows, then enforce uniqueness through an index; document this
   in the migration code. Regenerate Drift files using the repository's normal
   build_runner command.
7. Add a small retry coordinator around the existing `NetworkCanary` plus a
   bounded periodic fallback. Start it from the security module and dispose it
   with app lifecycle. It invokes the existing `retryUnsent` method without
   coupling audit delivery to answer outbox/timer/navigation state. Ensure only
   one retry sweep is active at a time.
8. Add terminal handling for a server rejection that means the pinned policy is
   `NONE` or the event type is invalid; it must not retry forever. Preserve the
   local row and log the reason for diagnostics. Network and transient server
   errors remain retryable.
9. Keep the current warning stream/banner wiring. Add assertions/tests that a
   violation does not change attempt status or dispatch `ForceSubmitRequested`.

## Data flow

```text
Pinned AttemptTaskResponse.lockdownMode
  -> strict parser
  -> LockdownService activation
  -> OS violation stream
  -> existing warning stream/banner
  -> local Drift insert with clientEventId
  -> authenticated student POST
  -> sent flag after receipt
  -> NetworkCanary/periodic retry on reconnect
```

The local row is the short-term source of truth. Server idempotency is the
long-term duplicate guard; a timeout after server commit is safe to retry.

## Dependencies and handoff

- Phase 1 must guarantee new attempt responses contain a valid policy.
- Phase 3 must be deployed/available before the app changes its POST route.
- Phase 5 must use a freshly built Windows release to verify the actual native
  plugin, not only Dart unit tests.

## Acceptance criteria

- [x] `NONE` does not activate lockdown and the task opens normally.
- [x] `STANDARD` activates before task 1; activation failure blocks task render
  and leaves a retryable error.
- [x] Unknown or missing non-normalized policy does not silently become `NONE`.
- [x] All four existing signal types create a local row before network send.
- [x] Initial send and retry use the authenticated attempt endpoint and exact
  client event ID.
- [x] Offline rows remain pending; reconnect/periodic retry sends them and the
  server stores exactly one event.
- [x] Duplicate success marks the local row sent without inserting another
  server event.
- [x] Practice Standard violations show the existing warning and do not pause,
  force-submit, invalidate, or terminate the attempt.
- [x] Existing task navigation, timer, answer sync, audio/media upload and
  submit flows remain unchanged.

**Status:** Complete after hard-checkpoint confirmation. The accepted full-suite
audio/auto-record baseline remains documented and is outside this phase.

## Design Constraints

- Pinned `lockdownMode`, not `examMode`, drives activation.
- Fail closed for invalid policy data; fail open only in the explicitly defined
  `NONE` policy, never through a parser fallback.
- Local persistence precedes network delivery and survives process death.
- Retry is bounded, single-flight, and independent of the answer outbox.
- Do not add process/screen recording, VM, multi-monitor, or continuous
  surveillance capabilities.
- Do not change Windows native fullscreen implementation unless verification
  proves a source defect; this phase consumes the existing platform channel.

## Quality and Testing State

**Quality:** APPROVED. The Phase 4 review found no blocker, high, medium, or
low findings. One accepted note records the existing native-audio/auto-record
unit baseline outside this phase. Receipt was issued and verified.
**Testing:** PASSED for the Phase 4 scope: 34 focused tests and 29
exam-attempt regression tests passed; scoped analyzer, formatting, and diff
checks passed. The full `pte-app` unit suite completed with 384 passed and 3
failures in the unrelated audio/auto-record tests, so no global green claim is
made for this phase.

Evidence:

- `pte-doc/projects/plans/quang-practice-anti-cheat-policy/tests/phase-04-pte-app-policy-activation-and-audit-adapter-test-report.json`
- `pte-doc/projects/plans/quang-practice-anti-cheat-policy/quality/phase-04-pte-app-policy-activation-and-audit-adapter-quality-report.json`
- `pte-doc/projects/plans/quang-practice-anti-cheat-policy/quality/phase-04-pte-app-policy-activation-and-audit-adapter-receipt.json`

Required verification after implementation:

- Unit tests for parser unknown/null behavior, activation ordering, activation
  failure, Standard vs Strict hooks, and warning-only state preservation.
- DAO/migration tests for client ID generation, upgrade backfill, sent flag and
  retry ordering.
- Reporter tests for exact URL/payload, local-first behavior, retryable versus
  terminal failures, and duplicate receipt handling.
- App-level test that the retry coordinator reacts to reconnect and does not
  start concurrent sweeps.
- Run focused Flutter tests and analyzer for changed packages; record platform
  limitations separately from passing Dart tests.
