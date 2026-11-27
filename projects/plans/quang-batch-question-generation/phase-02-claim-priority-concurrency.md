# Phase 2: Claim — priority, concurrency, no head-of-line blocking

## Goal
Jobs wait `QUEUED` instead of being rejected; `maxConcurrentJobs` is enforced at claim on live leases; claims are
serialized across instances; previews/standalone jobs go before batch children (U1); expired-lease jobs are always
resumable even when the cap is reached (M2).

## Files
Change
- `generation/repository/GenerationJobRepository.java` — `lockClaims`, `countLiveLeases`, `lockNextResumable`, `lockNextQueued` (replace `lockNextClaimable`); remove `countByStatusIn` if unused
- `generation/worker/JobLeaseService.java` — `claimNext`; inject `GenerationLimits`, `GenerationBatchRepository`
- `generation/job/QuestionGenerationJobService.java` — delete the `GENERATION_TOO_MANY_JOBS` branch in `checkCaps`
- `generation/constant/QuestionGenerationConstants.java` — `CLAIM_ADVISORY_LOCK_KEY` (≠ `SUBMIT_ADVISORY_LOCK_KEY = 7_340_034L`; grep `pg_advisory` for collisions); `@Deprecated GENERATION_TOO_MANY_JOBS`

## Steps
1. Queries:
   ```sql
   -- lockNextResumable(now): dead worker's job, never cap-checked (it replaces a dead lease)
   select id from question_generation_jobs
   where deleted = false and status in ('RUNNING','CANCELLING') and lease_until < :now
   order by lease_until limit 1 for update skip locked;
   -- lockNextQueued(): previews/standalone first, then batches FIFO
   select id from question_generation_jobs
   where deleted = false and status = 'QUEUED'
   order by (batch_id is not null), created_at, batch_seq, id limit 1 for update skip locked;
   ```
   `countLiveLeases(now)` = `status in LEASED and leaseUntil >= now and deleted = false`.
   Index: `CREATE INDEX ix_qgen_jobs_queued ON question_generation_jobs ((batch_id is not null), created_at, batch_seq, id) WHERE status='QUEUED' AND deleted=false;` (add to V53).
2. `claimNext(workerId)`:
   ```
   jobs.lockClaims(CLAIM_ADVISORY_LOCK_KEY)
   ids = jobs.lockNextResumable(now)
   if ids non-empty:
       stale CANCELLING → close path with batch hook (phase 4: batch lock first)
       else markRunning (resume) → return claim
   if countLiveLeases(now) >= limits.maxConcurrentJobs() → return empty     // M2: QUEUED excluded only when cap reached
   ids = jobs.lockNextQueued(); if empty → return empty
   job = findById; if job.batchId != null → batches.findByIdForUpdate(job.batchId)  // B1: batch first
   ```
   B1 ordering note: `lockNextQueued` locks the job row before the batch row. To keep batch-first, for a batch child
   read `batch_id` with a plain select first, then `findByIdForUpdate(batch)`, then `findById` + guarded `markRunning`
   (guard `status = QUEUED` handles a cancel that won meanwhile → returns 0 → return empty). Then `batches.markRunning(batchId, now)` (`QUEUED→RUNNING`, no-op otherwise).
   Concretely: `lockNextQueued` returns `(id, batch_id)` **without** `for update` (claims are already serialized by the advisory lock; cancels are guarded updates), then lock batch, then `markRunning` guarded.
3. Worker unchanged: one job per instance (`busy` flag, executor 1) → effective concurrency `min(instances, cap)`.

## Design Constraints
- Short claim transaction, no provider calls; transaction-scoped advisory lock.
- Lock order batch → job for every path that touches a batch child.
- Coding standards (`pte-api/docs/CODING_STANDARDS_API.md`, see plan.md "Coding standards"): files ≤ 300 lines, services ≤ 5 public methods, `internal/**` packages ≤ 15 direct classes, injected `Clock` as last ctor arg (entities receive `Instant now`), `@Transactional` only on services (`readOnly = true` for queries), codes/messages/numbers in `*Constants`, `ApiResponse<T>`, domain exceptions + global `@ControllerAdvice` (no controller try-catch), `@Valid` + Bean Validation on DTOs, no `@Data` on entities, DTOs never expose entities, comments explain WHY; `app/src/test/java/com/pte/architecture` tests green, allowlists only shrink.
- Sizes now: `JobLeaseService` 99 lines / 4 public methods, `GenerationJobRepository` 110 lines — after this phase both must stay ≤ 300; if `claimNext` grows beyond ~40 lines extract a package-private `worker/JobClaimSelector` (worker 5→6 classes). `CLAIM_ADVISORY_LOCK_KEY` in `QuestionGenerationConstants`.
- Preflight: read `JobLeaseService` (99 lines, 4 public), `GenerationJobRepository` (`lockNextClaimable` skip-locked, `countByStatusIn` used only by `checkCaps` + tests), `QuestionGenerationJobService.checkCaps`, `JobLeaseServiceTest`/`GenerationRepositoryQueriesTest`/Postgres IT callers; only other advisory key is `SUBMIT_ADVISORY_LOCK_KEY = 7_340_034L` (practice uses its own hashed key). Decision: both candidate selects (`findNextResumable`, `findNextQueued`) are plain selects (no `FOR UPDATE`) because the claim advisory lock already serializes claimers and every state change is guarded — this keeps the batch-row-first lock order (no job row lock is held before the batch lock).

## Quality and Testing State
- quality: skipped_by_user (decision: user_confirmed_skip)
- testing: passed — 490 run / 0 failed / 9 skipped (generation + itembank Question* + architecture + ModuleStructureTest); JobLeaseServiceTest 16 (cap+resume M2, cap+queued only waits, claim lock before reads, batch lock before markRunning, guarded markRunning 0 → empty, non-QUEUED after batch lock → empty), QuestionGenerationJobServiceTest (busy system → QUEUED), GenerationRepositoryQueriesTest H2 (standalone before batch children, seq order U1; expired-lease resumable; countLiveLeases). Postgres IT updated (resumable/live-lease, claim advisory lock) but skipped without -Dlifecycle.test.db.url; two-claimer and cancel-vs-claim latch ITs not written (need the dedicated DB).
- integration: Postgres ITs run 2026-11-18 on a throwaway postgres:17 container (DB pte_lifecycle_test; host :5432 is a native Postgres, not pte-postgres, so a separate container on 127.0.0.1:55440 was used, then removed): 22 run / 0 failed / 0 skipped, stable over 3 runs (opt-in: -Dlifecycle.test.db.url/.user/.password, -DargLine=-Duser.timezone=UTC); without the property all 20 skip, subset 535 run / 0 failed / 29 skipped. No production bug found. BatchClaimPostgresIntegrationTest 3: 6 threads x 3 rounds (CyclicBarrier) cap=2 → exactly 2 claims, live leases never > 2; preview then standalone claimed before an older batch child; expired lease resumed at cap=1 while a QUEUED job waits. Cancel-vs-claim latch ITs in BatchCancelRacePostgresIntegrationTest (both orders).

## Tests
- Unit `worker/JobLeaseServiceTest`: cap reached + expired lease exists → resume claimed (M2); cap reached + only QUEUED → empty; preview QUEUED newer than batch child → preview claimed (U1); lock before queries (`inOrder`); guarded `markRunning` 0 → empty.
- Unit `job/QuestionGenerationJobServiceTest`: submit at cap → QUEUED, no `GENERATION_TOO_MANY_JOBS`.
- Postgres IT: order `standalone, batchA seq0, batchB seq0`; two threads claim with cap=1 → one RUNNING; expired lease resumed at cap; overlapping submits of two batches never interleave within a batch (M1: seq order kept by `created_at, batch_seq, id`).
- Latch IT: cancel batch vs claim of its QUEUED child (cancel holds batch lock; claim blocks, then sees CANCELLED → empty).

## Acceptance criteria
- No path returns `GENERATION_TOO_MANY_JOBS`; ≤ cap live leases under concurrency; previews never wait behind batches.

## Risks
- Batch starvation if previews are submitted continuously — acceptable (previews are 1 item, one per user).
