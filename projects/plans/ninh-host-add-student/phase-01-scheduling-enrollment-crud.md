# Phase 1: scheduling — Enrollment CRUD Completion (Bulk-Create, List, Remove)

## Requirements

`Enrollment` today only supports a single-item `POST` (`EnrollmentService`'s
own docstring: *"Milestone 1 scope — no file import"*). This phase adds:
1. Bulk-enroll (for the Excel-import path — Phase 0 creates N accounts,
   this phase enrolls all N into one session in a single call).
2. List enrollments for a session (Host needs to see the current roster).
3. Remove a single enrollment (Host can undo a mistaken add).

Maps to: `plan.md` Decisions #1, #3; Research Summary items 1, 8.

## Design Constraints

- **Same service class, same controller, extended.** `EnrollmentController`
  (`/sessions/{sessionPublicId}/enrollments`) and `EnrollmentService`
  already exist — add methods, don't create a parallel service.
- **No cross-service validation of `studentPublicId`.** The existing
  single-enroll endpoint never verifies the id belongs to a real `STUDENT`
  user in the right tenant (confirmed by reading `enrollStudent` — it only
  stamps `session.getTenantId()` onto the row). Bulk-enroll matches this
  exact scope — it is not more strict than the endpoint it's extending.
  This is a pre-existing gap, not something this phase either introduces
  or is responsible for closing.
- **Bulk-enroll conflict handling**: pre-query existing
  `(session, studentPublicId)` pairs for the incoming id list, exclude
  matches from the insert set, `saveAll` the remainder in one
  `@Transactional` method, respond with both `enrolled` and
  `alreadyEnrolled` id lists. Still wrap the save in a
  `try/catch(DataIntegrityViolationException)` around the whole batch as a
  defensive fallback for the rare true concurrent-double-enroll race (same
  guard rationale as the existing single-enroll path, extended to
  batch-level — if it fires, the whole batch 409s and the caller retries,
  same behavior class as today's single-item conflict).
- **Hard delete, not soft-status** (Research Summary item 8 — `Enrollment`
  is a join-table fact, not a lifecycle entity; explicitly different from
  the Tenant/Organization "never hard-delete" precedent, and the reasoning
  for the difference is written down, not just asserted).
- **Outbox on every write, including delete (ADR-002, no exceptions).** New
  events: `EVENT_STUDENT_ENROLLED` reused for each bulk-enrolled row (same
  event as single-enroll — semantically identical fact); new
  `EVENT_STUDENT_UNENROLLED` for the delete path.
- **List response should carry enough for the FE to render without a
  second round-trip per row** — `EnrollmentResponse` already has
  `publicId, sessionPublicId, studentPublicId`; the FE joins
  `studentPublicId` against `iam`'s **`GET /users`** (caller-tenant-scoped
  via `UserService.listByTenant(caller)`'s own `caller.tenantId()` — **not**
  `GET /users/by-tenant/{tenantId}`, which is `PLATFORM_ADMIN`-only and
  would 403 for the `HOST_ADMIN`/`HOST_AUTHOR` caller this whole plan
  serves — caught by this plan's own red-team pass before implementation)
  client-side (already fetched once for the roster page — see Phase 4) to
  show name/email/className, rather than this endpoint calling out to iam
  itself. Keeps `scheduling` free of a new cross-service dependency for a
  read path.
- Authorization: same as existing single-enroll —
  `hasAnyRole('HOST_ADMIN','HOST_AUTHOR')` for bulk-enroll and list;
  `hasRole('HOST_ADMIN')` for delete (mirrors `ProctorAssignmentController`'s
  narrower delete-class precedent — removing a person from a roster is a
  step above "author" scope, consistent with how the existing `/score`/
  `/publish` host-commands are already `HOST_ADMIN`-only on
  `SessionController`).

## Steps

1. `dto/request/BulkEnrollRequest.java` (new) — `record BulkEnrollRequest(
   @NotEmpty List<UUID> studentPublicIds)`.
2. `dto/response/BulkEnrollResponse.java` (new) — `record
   BulkEnrollResponse(List<UUID> enrolled, List<UUID> alreadyEnrolled)`.
3. `repository/EnrollmentRepository.java` — add
   `List<Enrollment> findBySession_PublicId(UUID sessionPublicId)` and
   `List<Enrollment> findBySessionAndStudentPublicIdIn(ExamSession session, List<UUID> studentPublicIds)`
   (or equivalent derived-query pair) for the list + pre-check-conflict
   steps.
4. `SchedulingConstants` — add `EVENT_STUDENT_UNENROLLED = "StudentUnenrolled"`.
5. `domain/event/StudentUnenrolledEvent.java` (new) — mirror
   `StudentEnrolledEvent`'s field shape (`sessionPublicId`,
   `studentPublicId`, `tenantId`).
6. `EnrollmentService`:
   - `bulkEnroll(UUID sessionPublicId, BulkEnrollRequest request, CurrentUser caller)`
     — `@Transactional`. `findOwned` the session (existing helper). Query
     existing pairs, split enrolled/skip sets, `saveAll` the new rows,
     write one outbox event per newly-enrolled row, return
     `BulkEnrollResponse`.
   - `list(UUID sessionPublicId, CurrentUser caller)` —
     `@Transactional(readOnly = true)`. `findOwned` then map
     `findBySessionId(session.getId())` to `List<EnrollmentResponse>`
     (corrected from this doc's original `findBySession_PublicId` guess —
     `EnrollmentRepository` already had `findBySessionId(Long sessionId)`
     as an established convention, reused as-is rather than adding a
     second, differently-shaped finder).
   - `unenroll(UUID sessionPublicId, UUID enrollmentPublicId, CurrentUser caller)`
     — `@Transactional`. `findOwned` the session; load the `Enrollment` by
     `publicId`, verify it belongs to this session (404
     `EnrollmentNotFoundException` if not — don't let a caller unenroll a
     row from a different session by guessing a publicId), delete, write
     `EVENT_STUDENT_UNENROLLED`.
7. `EnrollmentController`:
   - `@PostMapping("/bulk") bulkEnroll(...)`.
   - `@GetMapping list(...)`.
   - `@DeleteMapping("/{enrollmentPublicId}") @PreAuthorize("hasRole('HOST_ADMIN')") unenroll(...)`.
8. `domain/exception/EnrollmentNotFoundException.java` (new, if no
   suitable existing exception fits — check `domain/exception/` first).
9. Unit tests (`EnrollmentServiceTest.java`, new or extended — check first
   whether one exists): `bulkEnroll` creates all new rows and reports
   pre-existing ones in `alreadyEnrolled` without erroring; `bulkEnroll`
   writes one outbox event per newly-created row (not per input id);
   `list` returns only this session's enrollments; `unenroll` deletes and
   writes the outbox event; `unenroll` on an enrollment from a different
   session 404s rather than deleting.

## Success Criteria

- [ ] `POST /sessions/{id}/enrollments/bulk` with 10 new student ids
      enrolls all 10; a follow-up call with 5 of the same ids + 5 new ones
      reports the first 5 in `alreadyEnrolled` and enrolls only the 5 new.
- [ ] `GET /sessions/{id}/enrollments` returns exactly this session's
      roster.
- [ ] `DELETE /sessions/{id}/enrollments/{enrollmentPublicId}` removes the
      row; the same student can be re-enrolled afterward without conflict.
- [x] `mvn -pl services/scheduling -am test` passes, including the new
      tests (6/6, `EnrollmentServiceTest` — this service's first-ever test
      suite).

## Quality and Testing State

- Backend: `mvn -pl services/scheduling -am test` — passing (12/12 in the
  final combined suite, after Phase 2 added its own tests to the same
  file; this phase's own contribution was 6, then +1 fixing QUAL-001
  below, +5 from Phase 2 = 12).
- Quality gate (`ck:quality`, `quality-reviewer` agent, scoped to this
  phase's files): first pass found 1 MEDIUM (QUAL-001), 0 BLOCKER/HIGH,
  1 NOTED (QUAL-002) — fixed/addressed:
  - QUAL-001 (test coverage gap): `bulkEnroll`'s
    `try/catch(DataIntegrityViolationException)` fallback — the exact
    concurrency guard this phase's Design Constraints call out — had zero
    test coverage; every existing test only stubbed `saveAll`'s happy
    path. Fixed: added
    `bulkEnroll_concurrentRaceOnSave_throwsAlreadyEnrolled_writesNoOutbox`
    (stubs `saveAll` to throw `DataIntegrityViolationException`, asserts
    `AlreadyEnrolledException` and zero outbox writes). Also added a
    doc-comment on `bulkEnroll` noting this catch's correctness depends on
    `Enrollment`'s `GenerationType.IDENTITY` id strategy forcing a
    synchronous per-row flush inside `saveAll` — flagged for re-verification
    if that id strategy ever changes.
  - QUAL-002 (NOTED, not actioned): reviewer observed Phase 1 and Phase 2
    were implemented back-to-back in the same uncommitted working tree,
    recommending a commit between phases so git-blame-based attribution
    stays reliable across future gate re-reviews. Not actioned — the
    project's standing instruction for this entire engagement is to never
    create a git commit (the user commits their own work); this plan
    follows that instruction throughout, consistent with how the prior
    `ninh-host-account-management`/`ninh-tenant-host-admin` plans were
    also cooked without any commits between phases.
  Re-verified: 0 BLOCKER, 0 HIGH, 0 MEDIUM — APPROVED.
- Manual E2E: not yet run — deferred to the user running the stack, same
  pattern as every phase in the prior plans.
