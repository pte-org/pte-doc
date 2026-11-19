# Phase 4: Chaining, batch cancel, reconciler

## Goal
Every child terminal transition promotes the next PENDING child, or stops the batch (cancel / fatal), and closes the
batch with a recomputed status — always holding the batch row lock first. Batch cancel is idempotent. A scheduled
reconciler repairs any open batch without an open child.

## Files
Create
- `generation/batch/BatchChainingService.java` — `onChildTerminal(long batchId, long jobId)`, `@Transactional(propagation = MANDATORY)`
- `generation/batch/BatchStatusCalculator.java` — pure
- `generation/batch/BatchReconciler.java` — `@Scheduled(fixedDelayString = "${itembank.generation.batch.reconcile-delay-ms:300000}")`, `@ConditionalOnProperty(prefix = "itembank.generation", name = "enabled", havingValue = "true")`

Change
- `generation/worker/JobLeaseService.java` — `finish`, stale-CANCELLING branch of `claimNext`
- `generation/batch/QuestionGenerationBatchService.java` — `cancel`
- `generation/job/QuestionGenerationJobService.java` — `cancel` on a child → `GENERATION_JOB_PART_OF_BATCH` (409)
- `generation/repository/GenerationJobRepository.java` — `findBatchIdById`, `promoteNext`, `cancelPending`, `cancelQueued` guard `PENDING, QUEUED`, `existsByBatchIdAndStatusIn`
- `generation/repository/GenerationJobItemRepository.java` — `cancelOpenUnleasedByBatch` (items of PENDING/QUEUED children)
- `generation/repository/GenerationBatchRepository.java` — `markRunning`, `requestCancel`, `close` (guarded `status in OPEN`), `refreshCounters` (from items of all children)

## Steps
1. B1 lock order in `JobLeaseService.finish(claim, requested, code)` and stale-cancel:
   ```
   Long batchId = jobs.findBatchIdById(jobId)                 // plain select, no lock
   if batchId != null: batches.findByIdForUpdate(batchId)       // batch FIRST
   refreshCounters; compute status (existing logic)
   if jobs.finish(...) == 1 && batchId != null: chaining.onChildTerminal(batchId, jobId)   // guarded: lost lease never chains
   ```
2. `onChildTerminal`:
   ```
   job = jobs.findById(jobId); batch = (already locked)
   fatal = FATAL_FAILURE_CODES.contains(job.failureCode)          // H1: any status (REQUESTER_NOT_ALLOWED finishes CANCELLED)
   if batch.cancelRequested || fatal:
       items.cancelOpenUnleasedByBatch(batchId, now); jobs.cancelPending(batchId, now, fatal ? job.failureCode : null)
   else if jobs.promoteNext(batchId) == 1: batches.refreshCounters(batchId); return     // guarded PENDING→QUEUED, idempotent
   if !jobs.existsByBatchIdAndStatusIn(batchId, JobStatus.OPEN):
       batches.refreshCounters(batchId); batches.close(batchId, BatchStatusCalculator.of(batch, counters), fatalCode, now)
   ```
   `promoteNext`: native `update ... set status='QUEUED' where id = (select id ... where batch_id=:b and status='PENDING' order by batch_seq limit 1) and status='PENDING'`.
   `cancelPending` leaves `started_at` null → quota refund (U2).
3. `BatchStatusCalculator`: `cancelRequested` → `CANCELLED`; `succeeded == total` → `COMPLETED`; `succeeded > 0` → `PARTIALLY_COMPLETED`; else `FAILED`.
4. Cancel (`POST /batches/{id}/cancel`), M6 + L1:
   ```
   batch = findByPublicId; GenerationAccessPolicy.requireAccess(caller, batch)
   lock batch FOR UPDATE
   if status in {CANCELLING, CANCELLED} → return current (idempotent, 200)
   if terminal → GENERATION_BATCH_NOT_CANCELLABLE (409)
   requestCancel (cancel_requested=true; RUNNING→CANCELLING)
   cancelPending + cancelOpenUnleasedByBatch      // FIRST: PENDING and QUEUED children
   running = child in LEASED → jobs.markCancelling(running.publicId)   // runner honours it; its finish hook closes the batch
   if no open child → close(CANCELLED)
   audit BATCH_CANCELLED
   ```
5. L2 hook failure: an exception in the hook rolls back the whole `finish` tx (job stays RUNNING, lease expires, job is resumed and finishes again). Log `WARN` with ids + error class, increment Micrometer counter `generation.batch.hook.failures` (if `MeterRegistry` is available in the module; else log only). Reconciler is the backstop.
6. `BatchReconciler.tick`: for each id from `batches.findOpenIdsWithoutOpenChild()` (open batch, `not exists` child in `OPEN`): new tx, lock batch, re-check, `refreshCounters`, `close(calculated)`; log `WARN` "batch repaired". Also: open batch whose only open children are `PENDING` with none `QUEUED/LEASED` and `cancel_requested=false` → `promoteNext` (lost promotion repair).

## Design Constraints
- Lock order batch → job in finish, stale-cancel, claim (phase 2), cancel. `GenerationJobRunner` stays batch-agnostic.
- At most one child per batch in `JobStatus.ACTIVE` (promotion only after previous terminal; index backs it).
- Coding standards (`pte-api/docs/CODING_STANDARDS_API.md`, see plan.md "Coding standards"): files ≤ 300 lines, services ≤ 5 public methods, `internal/**` packages ≤ 15 direct classes, injected `Clock` as last ctor arg (entities receive `Instant now`), `@Transactional` only on services (`readOnly = true` for queries), codes/messages/numbers in `*Constants`, `ApiResponse<T>`, domain exceptions + global `@ControllerAdvice` (no controller try-catch), `@Valid` + Bean Validation on DTOs, no `@Data` on entities, DTOs never expose entities, comments explain WHY; `app/src/test/java/com/pte/architecture` tests green, allowlists only shrink.
- `BatchChainingService` (1 public method), `BatchReconciler` (1 `@Scheduled` method, its own short `@Transactional` per batch via the chaining/repository service, not self-invocation), `BatchStatusCalculator` pure static. Reconcile delay default as a constant + property. Race handling follows the Concurrency section: guarded conditional updates + pessimistic batch lock, documented lock order.
- Preflight: terminal paths grepped — `jobs.finish(` only in `JobLeaseService.finish` (callers: `GenerationJobRunner` x5 incl. REQUESTER_NOT_ALLOWED → CANCELLED), `finishStaleCancelling(` only in `JobLeaseService.resume`, `cancelQueued(` only in `QuestionGenerationJobService.cancel` (children now rejected with 409). `@Scheduled` already used by `QuestionGenerationWorker` (scheduling enabled); Micrometer `MeterRegistry` is available (actuator, e.g. `TaskTypeObservability`) → hook failure counter lives in `BatchChainingService` (log + count + rethrow, so `finish` rolls back). Cancel needs `GenerationAccessPolicy.requireAccess(caller, batch)`, `GenerationBatchNotFoundException` and the detail response, so those (planned for phase 5) are created here; `QuestionGenerationBatchQueryService.detail` is shared by cancel and GET.

## Quality and Testing State
- quality: skipped_by_user (decision: user_confirmed_skip)
- testing: passed — 793 run / 0 failed / 33 skipped. New: BatchChainingServiceTest 12 (promote; last child closes PARTIALLY_COMPLETED; cancel_requested stops waiting children first then closes CANCELLED; PROVIDER_AUTH FAILED stops; REQUESTER_NOT_ALLOWED with status CANCELLED stops (H1); ordinary failure keeps going; open child keeps batch open; hook failure counted + rethrown; reconcile close / promote lost / healthy untouched / cancelled stops waiting), BatchStatusCalculatorTest 3, BatchReconcilerTest 2, QuestionGenerationBatchServiceTest +5 cancel (waiting first then markCancelling running child, batch lock first; QUEUED closes at once; CANCELLING/CANCELLED idempotent; COMPLETED → 409; other writer → 404), JobLeaseServiceTest +4 (batch lock before jobs.finish then hook; lost lease never chains; standalone untouched; stale cancel locks batch then chains), QuestionGenerationJobServiceTest +1 (child cancel → GENERATION_JOB_PART_OF_BATCH), H2 GenerationBatchQueriesTest 6 (JSONB rows round-trip, promoteNext lowest PENDING only, cancelPending keeps started_at null + fatal code, counters from items, guarded markRunning/requestCancel/close, reconciler finder queries). Production fix found by tests: FATAL_FAILURE_CODES.contains(null) NPE (Set.of) → null-checked. Postgres stub-generator IT and latch ITs (cancel vs finish, cancel vs claim) not written: need the dedicated lifecycle DB; covered by unit inOrder tests + live smoke.
- integration: Postgres ITs run 2026-11-18 on a throwaway postgres:17 container (DB pte_lifecycle_test; host :5432 is a native Postgres, not pte-postgres, so a separate container on 127.0.0.1:55440 was used, then removed): 22 run / 0 failed / 0 skipped, stable over 3 runs (opt-in: -Dlifecycle.test.db.url/.user/.password, -DargLine=-Duser.timezone=UTC); without the property all 20 skip, subset 535 run / 0 failed / 29 skipped. No production bug found. BatchCancelRacePostgresIntegrationTest 4 (batch lock held by one tx until pg_stat_activity shows the other waiting): cancel→finish and finish→cancel, cancel→claim (claim returns empty, child never started) and claim→cancel (child CANCELLING, worker finish closes) — no deadlock, batch CANCELLED, no PENDING/QUEUED child left. Reconciler: missed hook → COMPLETED with counters; cancel-requested batch → CANCELLED; lost promotion → next child QUEUED. Run end to end: submit 2 rows → children run one after another to COMPLETED, batch COMPLETED 4/4 (worker loop drives JobLeaseService and marks items SAVED; the StubItemGenerator pipeline needs the full app context and is not booted).

## Tests
- Unit `BatchStatusCalculatorTest`; `BatchChainingServiceTest`: promote; last child closes; cancel_requested stops; PROVIDER_AUTH (FAILED) stops; **REQUESTER_NOT_ALLOWED with status CANCELLED stops (H1)**; hook not called when guarded finish = 0.
- Unit `JobLeaseServiceTest`: batch lock taken before `jobs.finish` (`inOrder`).
- Unit `BatchReconcilerTest`: open batch without open child → closed; stuck PENDING → promoted; healthy batch untouched.
- Unit cancel: CANCELLING/CANCELLED → idempotent 200; COMPLETED → 409.
- Postgres IT (stub generator): 3 children run sequentially to COMPLETED; `promoteNext` twice → once.
- Latch ITs (CountDownLatch, two threads, deterministic): cancel vs finish of RUNNING child (both orders → batch CANCELLED, no deadlock, remaining children CANCELLED); cancel vs in-flight claim (M6); assert invariant "no open batch without open child" after each.

## Acceptance criteria
- Every job terminal path chains exactly once; cancel frees the user's slot once the running child stops; reconciler repairs injected inconsistencies.

## Risks
- Missed terminal path — grep callers of `jobs.finish(`, `finishStaleCancelling(`, `cancelQueued(`; reconciler as net.
