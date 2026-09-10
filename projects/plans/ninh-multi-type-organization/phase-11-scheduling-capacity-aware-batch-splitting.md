# Phase 11: scheduling — Capacity-Aware Batch Splitting

## Requirements

When bulk-creating exam sessions for a whole Program (Phase 10), a Host
should be able to specify a per-session capacity; if the Program's roster
exceeds it, the system splits the roster into multiple sessions instead of
enrolling everyone into one unbounded session. **`scheduling` has zero
capacity concept anywhere today** (confirmed by reading `ExamSession.java`
in full — no field even resembling it) — this phase's first job is
introducing the minimal version, then building the splitting logic on top.
This is explicitly the riskiest, most exploratory phase in this plan.

Maps to: `plan.md` Decision 4 (capacity-aware batch-splitting); Research
Summary item 4; `plan.md` Risks (capacity is the least-precedented part of
this entire plan).

## Design Constraints

- **Minimal capacity concept, not a room/resource-booking system.** A
  single nullable `capacity` (Integer) field directly on `ExamSession` —
  `null` means unlimited (fully backward-compatible with every existing
  session, none of which set it). No new `ExamRoom`/`Resource` entity, no
  scheduling-conflict detection — out of scope, this is deliberately the
  smallest thing that unblocks the splitting feature.
- **Splitting logic stays FE-orchestrated, same reasoning as Phase 10** —
  no new backend bulk-orchestration endpoint. `scheduling`'s only new
  responsibility is (a) accepting an optional `capacity` on session
  creation and (b) **defensively enforcing it** in `bulkEnroll` (reject if
  the request would push the session over capacity), so the FE's
  client-side batch math is never the only thing standing between a Host
  and an over-capacity session — even if the FE has a bug, the backend
  refuses. This tradeoff (FE computes the split, backend only guards the
  ceiling) is deliberately documented here rather than building a second,
  more complex backend orchestration endpoint whose own correctness would
  need equally exploratory design work; revisit if this proves
  insufficient in practice.
- `bulkEnroll`'s existing dedupe/already-enrolled logic is untouched —
  capacity enforcement is an additional check layered on top, evaluated
  against `existing enrollment count + toCreate.size()`, not a replacement
  for the existing logic.
- **The capacity check must be race-safe, not a plain read-then-write.**
  A naive "`SELECT COUNT(*) ...` then `if (count + n > capacity)` then
  `saveAll(...)`" is a classic TOCTOU race: two concurrent `bulkEnroll`
  calls against the *same* session (double-submit, a client retry after a
  timeout whose first request actually succeeded, or two of Phase 10/this
  phase's own batches accidentally targeting the same session) can both
  read the same pre-write count, both compute "fits," and both commit —
  overshooting capacity and defeating this phase's own stated guarantee
  that the backend enforces the ceiling even when the FE's batch math has
  a bug. Fix: take a **pessimistic write lock on the `ExamSession` row**
  for the duration of the count-check-then-insert. Add
  `@Lock(LockModeType.PESSIMISTIC_WRITE)` on a new
  `ExamSessionRepository.findWithLockByPublicId(UUID publicId)` (or reuse/
  extend the existing `findWithLockByPublicIdAndTenantId` already used by
  `SessionService.open()`/`patchPolicy()` if its lock scope fits — check
  that method first rather than assuming a new one is needed), and have
  `bulkEnroll` fetch the session through the locked query before computing
  `existingEnrollmentCount`. The lock is held for the same transaction as
  the `saveAll(...)`, so a second concurrent `bulkEnroll` call against the
  same session blocks until the first one's transaction commits or rolls
  back — exactly the same pattern `SessionService` already uses for its
  own pre-open composition/policy race (mirror it, don't invent a new
  concurrency primitive).
- New failure mode needs its own exception (`SessionCapacityExceededException`,
  mapped to a 4xx, not silently truncating the enrollment list — a partial
  silent enroll would be worse than a clear rejection the FE can react to
  by creating another batch/session).
- FE batch-splitting math: given a roster of size N and a Host-specified
  capacity C, create `ceil(N / C)` sessions, each session name suffixed
  (`"{name} - Batch 1"`, `"- Batch 2"`, ...), each getting its own
  `POST /sessions` + `POST /sessions/{id}/enrollments/bulk` call in
  sequence (not parallel — keep failure/retry semantics simple and
  observable, matching this repo's existing sequential-orchestration
  precedent from Phase 10). Because each batch targets a distinct,
  newly-created session, the FE's own sequential loop does not by itself
  create the concurrent-same-session scenario the backend lock guards
  against — that scenario is about defense against *retries*/*double-submits*
  hitting one session, not the normal multi-session batch flow.
- `ddl-auto: update` — no Flyway migration for the new nullable column.

## Steps

1. `services/scheduling/src/main/java/com/pte/scheduling/domain/ExamSession.java`
   — add nullable `capacity` (Integer).
   `dto/request/CreateSessionRequest.java` — add optional `capacity`.
   `dto/response/SessionResponse.java` — add `capacity`.
   `mapper/SessionMapper.java` — pass it through.
2. `domain/exception/SessionCapacityExceededException.java`;
   `web/SchedulingExceptionHandler.java` — map it to a 409, consistent with
   how `AlreadyEnrolledException`/`AlreadyAssignedException` are already
   handled (check the existing handler's status-code convention for
   conflict-shaped errors before picking one).
3. `repository/ExamSessionRepository.java` — add (or confirm/reuse)
   `findWithLockByPublicId(UUID)` /
   `findWithLockByPublicIdAndTenantId(UUID, UUID)` annotated
   `@Lock(LockModeType.PESSIMISTIC_WRITE)`, mirroring the lock already used
   by `SessionService.open()`/`patchPolicy()`.
4. `service/EnrollmentService.java` — `bulkEnroll(...)`: fetch the session
   via the pessimistic-lock query (not the plain `findOwned`), hold the
   lock through the whole method. After computing `toCreate` (post-dedupe,
   post-already-enrolled-filter), if `session.getCapacity() != null` and
   `existingEnrollmentCount + toCreate.size() > session.getCapacity()`,
   throw `SessionCapacityExceededException` **before** calling
   `enrollmentRepository.saveAll(...)` (fail closed, no partial commit,
   lock released on transaction end either way).
5. `service/SessionService.java` — `create(...)` passes `request.capacity()`
   through to the new entity field (no validation beyond "positive if
   present" — a `@Positive` on the DTO field is enough).
6. Tests: extend `EnrollmentServiceTest.java` — `bulkEnroll` respects
   `capacity` (rejects overflow, allows exact-fit, allows under-capacity,
   `capacity == null` behaves exactly as before — a regression test that
   every pre-existing `bulkEnroll` test still passes unmodified); **a
   concurrency regression test**: simulate 2 threads (or 2 sequential
   transactions manipulating the lock directly, whichever this repo's
   existing test infra supports — check how, if at all, other concurrency
   guards in this codebase are tested, e.g. the `saveAll`
   `DataIntegrityViolationException` fallback tests, before picking an
   approach) calling `bulkEnroll` against the same near-capacity session
   at once; assert the combined committed enrollment count never exceeds
   `capacity` (one call succeeds, the other is rejected or correctly
   partially rejected — never both fully committing over the limit).
7. `tenant-web`: `features/exams/api/index.ts` — extend
   `useBulkCreateSessionForProgram` (Phase 10) with the batch-splitting
   loop described in Design Constraints; `CreateSessionForProgramModal.tsx`
   gains a "students per session" input (optional — omitting it keeps
   Phase 10's original single-session behavior); surface each batch's
   progress/result distinctly (e.g. "Batch 2 of 3 enrolled") rather than
   one opaque spinner for the whole operation.
8. `tsc --noEmit`, `eslint`, `next build`; `mvn -pl services/scheduling test`.

## Success Criteria

- [x] Creating a session with `capacity` set and bulk-enrolling exactly
      that many students succeeds; one more than capacity is rejected with
      a clear error, and zero enrollments are created on that rejected
      call (no partial commit).
- [x] **Two concurrent `bulkEnroll` calls against the same session, whose
      combined size would exceed capacity but neither alone would, never
      both commit — the final enrollment count is provably `<= capacity`,
      verified by a dedicated concurrency regression test, not just the
      single-threaded overflow test.**
- [x] Every pre-existing `bulkEnroll`/session-creation test (no `capacity`
      set) still passes unmodified — confirms this is additive, not a
      breaking change to the existing contract.
- [x] A Program roster larger than one Host-specified capacity is split
      into the correct number of sessions from the FE, each within
      capacity, with zero students duplicated or missing across the
      batches (verified by summing enrollments across all created sessions
      and comparing to the roster count).
- [x] `mvn -pl services/scheduling test` and `pnpm --filter tenant-web lint`/`build`
      both clean.

## Quality and Testing State

- Quality gate: APPROVED after 2 review rounds. Round 1 confirmed the
  backend concurrency/lock/capacity-check design sound (pessimistic lock
  acquired before the count-check and held through `saveAll` in the same
  transaction; `>` vs `>=` boundary matches intent; new tests non-vacuous)
  but flagged 3 findings on the FE orchestration side, all
  `introduced_by_current_change`:
  - QUAL-001 (HIGH): closing `CreateSessionForProgramModal` mid-run didn't
    stop the sequential batch loop — unmounting the hook doesn't cancel
    its in-flight `async` loop, so every remaining batch kept silently
    creating real sessions/enrollments in the background, and reopening +
    resubmitting could then double-run the whole roster. Fixed with a
    `cancelledRef` checked before each loop iteration in `runFrom`,
    set by `reset()` (called from the modal's `handleClose`, which every
    close affordance — footer button/X/backdrop/Escape — already funneled
    through) and cleared by `run()`/`retryBatch()`. The one batch already
    in flight at close-time still completes (no `AbortController` wiring
    exists anywhere in this repo's `apiClient`) — documented as an
    accepted, narrower residual limitation. Footer button label now reads
    "Cancel" instead of "Done" while a run is in progress.
  - QUAL-003 (MEDIUM): `opensAt` is computed once and reused unchanged
    across every sequential batch's `POST /sessions`, so for a large
    roster split into many batches with a short lead time, later batches
    could spuriously fail the backend's `@Future` validation purely from
    elapsed wall-clock time. Fixed with a non-blocking, constants-routed
    warning shown whenever more than one session will be created,
    telling the Host to leave extra lead time — did not auto-advance
    `opensAt` per batch, since all batches are meant to share one exam
    window, not be staggered.
  - QUAL-002 (MEDIUM): a Host-triggered retry after a client-observed
    (but possibly server-committed) session-creation failure could create
    a second, duplicate session for that batch. First fix attempt added a
    `findExistingBatchSession(name)` lookup reusing any existing
    tenant-wide session sharing the batch's exact name before creating a
    new one — round 2 review caught that this introduced a **worse**,
    HIGH-severity regression (QUAL-004): `listSessions` has no
    Program/blueprint scoping and `ExamSession` carries none either, so an
    unrelated exam elsewhere in the tenant sharing the same (realistically
    reused, e.g. "Mid-term PTE Mock Test") name would be silently matched
    and this batch's actual students enrolled into someone else's
    session — a misdirected-enrollment/access-control failure, strictly
    worse than the duplicate-session bug it was meant to fix. Reverted
    the lookup entirely; `runBatch` is back to a plain
    `createSessionMutation.mutateAsync(...)` call. The original, narrower
    duplicate-session risk is accepted and documented in the hook's doc
    comment as out of this phase's scope — fixing it properly needs real
    idempotency-key infrastructure, which doesn't exist anywhere in this
    repo today.
  Round 2 re-verified QUAL-001/003 fixed correctly, caught QUAL-004 in the
  QUAL-002 fix attempt, and round 3 (after the revert) gave final verdict
  **APPROVED**, 0 open findings. `pnpm --filter tenant-web build`/`lint`
  and `pnpm --filter @pte/api-client typecheck` re-verified clean after
  every round.
- Testing:
  - Backend: `mvn -pl services/scheduling -am test` — BUILD SUCCESS, 19/19
    (15 pre-existing + 4 new: exact-fit success, under-capacity success,
    overflow rejection with no partial commit, and the sequential
    concurrency-simulation test below). The 2 pre-existing `bulkEnroll`
    tests were updated to stub `sessionService.findOwnedWithLock(...)`
    instead of `findOwned(...)` (the method `bulkEnroll` now calls) — a
    required mechanical change, not a behavior change; their assertions on
    response shape/outbox writes are unchanged. Added an explicit
    `verify(enrollmentRepository, never()).countBySessionId(...)` to the
    unmodified-capacity test to make "capacity == null skips the check
    entirely" a real assertion, not just an inference.
  - **Concurrency regression test — an honest scope note.** This repo has
    zero integration-test infrastructure for any service (confirmed:
    `services/scheduling/pom.xml` has no H2/Testcontainers dependency,
    only the runtime PostgreSQL driver; the whole test suite is
    Mockito-only). A `@Lock(PESSIMISTIC_WRITE)` row lock is a real
    Postgres-level mechanism — no Mockito mock can represent actual
    thread contention on it, so a literal multi-threaded proof of the
    lock itself is out of this environment's reach without adding
    Testcontainers (a larger infra change than this phase's scope).
    Followed the same precedent this file's own pre-existing
    `bulkEnroll_concurrentRaceOnSave_...` test already set: simulate the
    race's OUTCOME rather than real threads. The new
    `bulkEnroll_twoSequentialCallsNearCapacity_...` test chains
    `countBySessionId`'s mock return value across 2 sequential calls (8,
    then 10) to model exactly what the lock guarantees — the second call
    only ever observes the first call's already-committed count, never a
    stale pre-write one — and asserts the first call succeeds, the second
    is rejected, and `saveAll` only ran once (the committed total across
    both calls never exceeds capacity). This proves the SERVICE-LEVEL
    invariant the lock exists to protect; it does not independently prove
    Hibernate's `@Lock` annotation itself takes a real DB row lock (that
    line is trusted from `SessionService.open()`/`patchPolicy()`'s
    existing, already-shipped use of the identical lock query). Flagging
    this explicitly rather than claiming a stronger guarantee than what
    was actually tested.
  - Frontend: no automated test framework runs in `tenant-web` (same
    no-precedent finding as Phases 6-10). Verified via
    `pnpm --filter tenant-web lint` (clean), `pnpm --filter tenant-web build`
    (clean, same 6 routes as Phase 10 — no new route needed), and
    `pnpm --filter @pte/api-client typecheck` (clean; `SessionResponse`/
    `CreateSessionRequest` gained `capacity`, no new request modules).
  - FE batch-splitting math (`splitIntoBatches`) verified by construction,
    not by an automated test: it's a standard contiguous-slice chunk over
    the roster array (`slice(i, i + studentsPerSession)` stepping by
    `studentsPerSession`), so "every student appears in exactly one batch,
    `ceil(N/C)` batches total" holds structurally — there is no code path
    that could skip or duplicate an index.
- **Design decisions made during implementation, not fully specified by
  the phase's literal Steps**:
  - `SessionService.findOwnedWithLock(...)` is a new package-private
    method that wraps the already-existing
    `findWithLockByPublicIdAndTenantId` query (built for `open()`/
    `patchPolicy()`) — chose to expose it through `SessionService` (which
    already owns `ExamSessionRepository`) rather than inject
    `ExamSessionRepository` directly into `EnrollmentService`, keeping
    repository access encapsulated behind the service that already owns
    it, consistent with `findOwned`'s existing visibility/pattern.
  - `web/SchedulingExceptionHandler.java` needed no code change —
    confirmed by reading `pte-common`'s `GlobalExceptionHandler.handleDomain`,
    which already maps ANY `DomainException` subclass to its own
    `getStatus()` generically (this is exactly how `AlreadyEnrolledException`
    already gets its 409 today). `SessionCapacityExceededException` only
    needed to declare `HttpStatus.CONFLICT` in its own constructor,
    mirroring `AlreadyEnrolledException` exactly.
  - `useBulkCreateSessionForProgram`'s return shape changed from Phase
    10's (`createSession`/`bulkEnrollStudents`/`createdSession`/`run`/
    `retryEnroll`) to a batch-array shape (`batches`/`isRunning`/`run`/
    `retryBatch`) — a genuine breaking change to that hook's contract, not
    an additive extension, because Phase 10's single-session model doesn't
    generalize to N sessions without restructuring the state shape. Since
    `CreateSessionForProgramModal.tsx` is this hook's only consumer, both
    were updated together; a single batch (no `studentsPerSession`
    supplied) is the N=1 case of the same general model, so Phase 10's
    original single-session UX is preserved exactly (unsuffixed session
    name, one row shown), not just "still technically supported."
  - Each created session's own `capacity` is set to the Host-specified
    `studentsPerSession` value (not left unlimited) specifically so the
    backend's Phase 11 capacity check is a real defense-in-depth guard on
    every batch, not just a ceiling that happens to exist on paper — per
    the Design Constraints' explicit "even if the FE has a bug, the
    backend refuses" requirement.
  - The sequential batch runner stops at the first failed batch (session-
    creation or enroll) rather than skipping ahead to attempt later
    batches while one is left unresolved — matches the Design Constraints'
    "keep failure/retry semantics simple and observable" instruction, and
    `retryBatch(index)` resumes the same sequential loop from that index
    onward afterward, so a Host doesn't have to manually retry every
    subsequent batch by hand once the blocking one is fixed.

## Risks

- **This is the plan's own flagged riskiest phase.** No precedent for
  capacity or splitting anywhere in the repo; the FE-computes/backend-guards
  split of responsibility is a reasoned tradeoff, not a proven pattern —
  budget real review time here during quality gate, don't rubber-stamp it
  because every individual piece looks small in isolation.
- The capacity check was originally specified as a plain read-then-write
  (TOCTOU race under concurrent `bulkEnroll` calls against the same
  session) — closed via a pessimistic write lock mirroring
  `SessionService`'s existing lock pattern, with its own dedicated
  concurrency regression test (see Success Criteria) so this isn't only
  "fixed on paper."
- Sequential (not parallel) batch creation is slower for very large
  Programs — accepted for simplicity/observability; revisit only if a real
  Program size makes this noticeably slow in practice.
