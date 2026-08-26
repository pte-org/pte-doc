# Phase 2: scheduling — ProctorAssignment CRUD Completion (List, Unassign)

## Requirements

`ProctorAssignment` today only supports a single-item `POST`. This phase
adds list (Host needs to see who's currently assigned to a session) and
unassign (Host can edit the assignment — remove a Proctor from a session).
This is the entire meaning of "Host chỉnh sửa quyền của Giám thị" per
Decision #4 in `plan.md` — no new permission model, just completing this
CRUD.

Maps to: `plan.md` Decision #4; Research Summary items 1, 7, 8.

## Design Constraints

- Same `EnrollmentService` class as Phase 1 (it already owns
  `assignProctor` — confirmed by reading the file). Add
  `listProctors`/`unassignProctor` there, not a new service.
- Hard delete, same reasoning as Phase 1's `unenroll` (join-table fact, not
  a lifecycle entity).
- Outbox on the new delete path: `EVENT_PROCTOR_UNASSIGNED`. (Note:
  `assignProctor`'s existing code does NOT currently write an outbox event
  for the assign side either — confirmed by reading `EnrollmentService.java`,
  it saves and returns without calling `outboxWriter`. This phase adds the
  outbox write to `assignProctor` too, bringing it in line with ADR-002,
  since it's already being touched — flag this as a small pre-existing gap
  being closed opportunistically, not scope creep, since leaving the
  assign-side silently un-audited while adding a fully-audited
  unassign-side would be an inconsistent, confusing asymmetry.)
- Authorization: `hasRole('HOST_ADMIN')` for all three operations
  (assign/list/unassign) — matches the existing single-assign endpoint's
  narrower-than-enrollment authorization (already `HOST_ADMIN`-only, not
  `HOST_AUTHOR`).
- List response, same join strategy as Phase 1: `ProctorAssignmentResponse`
  carries `proctorPublicId` only; FE joins against `iam`'s
  `GET /users/by-tenant/{tenantId}` client-side for name/email.

## Steps

1. `SchedulingConstants` — add `EVENT_PROCTOR_ASSIGNED = "ProctorAssigned"`,
   `EVENT_PROCTOR_UNASSIGNED = "ProctorUnassigned"`.
2. `domain/event/ProctorAssignedEvent.java`,
   `domain/event/ProctorUnassignedEvent.java` (new) — mirror
   `StudentEnrolledEvent`'s shape (`sessionPublicId`, `proctorPublicId`,
   `tenantId`).
3. `repository/ProctorAssignmentRepository.java` — add
   `List<ProctorAssignment> findBySession_PublicId(UUID sessionPublicId)`.
4. `EnrollmentService`:
   - `assignProctor(...)` — extend existing method to also write
     `EVENT_PROCTOR_ASSIGNED` in the same transaction (currently missing —
     see Design Constraints).
   - `listProctors(UUID sessionPublicId, CurrentUser caller)` —
     `@Transactional(readOnly = true)`. `findOwned` then map to
     `List<ProctorAssignmentResponse>`.
   - `unassignProctor(UUID sessionPublicId, UUID assignmentPublicId, CurrentUser caller)`
     — `@Transactional`. `findOwned` the session; load the
     `ProctorAssignment` by `publicId`, verify it belongs to this session
     (404 if not), delete, write `EVENT_PROCTOR_UNASSIGNED`.
5. `ProctorAssignmentController`:
   - `@GetMapping list(...)`.
   - `@DeleteMapping("/{assignmentPublicId}") unassign(...)`.
6. `domain/exception/ProctorAssignmentNotFoundException.java` (new, if no
   suitable existing exception fits — check first).
7. Unit tests (extend `EnrollmentServiceTest.java` or add
   `ProctorAssignmentServiceTest.java`, whichever matches the existing test
   file's scope): `assignProctor` now writes an outbox event (regression
   test for the gap being closed); `listProctors` returns only this
   session's assignments; `unassignProctor` deletes and writes the outbox
   event; `unassignProctor` on an assignment from a different session
   404s.

## Success Criteria

- [ ] `POST /sessions/{id}/proctors` still works as before, and now also
      writes an outbox event (verify via test, not just manually).
- [ ] `GET /sessions/{id}/proctors` returns exactly this session's assigned
      proctors.
- [ ] `DELETE /sessions/{id}/proctors/{assignmentPublicId}` removes the
      assignment; the same proctor can be re-assigned afterward.
- [ ] `mvn -pl services/scheduling -am test` passes, including the new
      tests.

## Quality and Testing State

- Not started.
