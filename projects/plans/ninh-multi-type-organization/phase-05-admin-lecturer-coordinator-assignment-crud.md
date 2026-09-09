# Phase 5: admin — Lecturer/Coordinator Assignment CRUD

## Requirements

Lets a Host assign a `LECTURER` user to a specific `StudentClass` and a
`PROGRAM_COORDINATOR` user to a specific `Program` — "just like a Proctor",
per the user's own framing. Completes the role work from Phase 4 with the
actual assignment mechanism.

Maps to: `plan.md` Decision 2; Research Summary item 6.

## Design Constraints

- **Mirrors `scheduling.ProctorAssignment`'s shape exactly**: target entity
  (`@ManyToOne StudentClass` / `@ManyToOne Program`) + bare assignee
  `assigneePublicId` (`UUID`, no cross-service FK to iam's `User`) +
  denormalized `tenantId` + a DB unique constraint
  (`(class_id, assignee_public_id)` / `(program_id, assignee_public_id)`)
  as the concurrency guard. **No `role` sub-enum on either assignment
  table** — unlike `ProctorAssignment`'s `LEAD_PROCTOR`/`ASSISTANT_PROCTOR`
  split, the feature spec doesn't ask for a Lecturer/Coordinator
  sub-classification; this is a deliberate, narrower mirror of the shape,
  not a missing feature.
- **One service class owns both join-entity CRUDs**
  (`assign`/`list`/`unassign` for each), same "one service, two+ sibling
  join-CRUDs" precedent as `scheduling.EnrollmentService` — name it
  `AssignmentService.java`, not two near-duplicate service classes.
- Authorization: `hasAnyRole('HOST_ADMIN','HOST_AUTHOR')` for list,
  `hasRole('HOST_ADMIN')` for assign/unassign — matches the existing
  narrower-than-list pattern already used by
  `scheduling.ProctorAssignmentController`/`EnrollmentController` for
  mutating operations.
- Assigning does **not** validate that the target user actually holds the
  `LECTURER`/`PROGRAM_COORDINATOR` role at the DB level (iam and admin are
  separate services/databases) — mirrors how `ProctorAssignment.proctorPublicId`
  is never validated against iam's `Role` either. The FE (Phase 9) is
  responsible for only offering users who actually have the right role
  (fetched via iam's existing `GET /users`, filtered client-side by
  `roles.includes(...)`, same pattern `AssignProctorModal.tsx` already
  uses via `useTenantProctors`).
- Tenant-scope validation: same `findOwned`-under-tenant pattern as Phases
  2/3 — assigning to a `StudentClass`/`Program` that doesn't belong to the
  caller's tenant is a 404, not a 403 (consistent "wrong tenant looks like
  not-found" convention).
- `ddl-auto: update` — no Flyway migration.

## Steps

1. `domain/LecturerAssignment.java` (`@ManyToOne StudentClass`,
   `assigneePublicId`, `tenantId`, unique on `(class_id, assignee_public_id)`).
   `domain/ProgramCoordinatorAssignment.java` (`@ManyToOne Program`,
   `assigneePublicId`, `tenantId`, unique on `(program_id, assignee_public_id)`).
   Both extend `BaseEntity`.
2. `repository/LecturerAssignmentRepository.java`,
   `repository/ProgramCoordinatorAssignmentRepository.java` —
   `findByStudentClass_PublicId`/`findByProgram_PublicId`.
3. `domain/exception/{LecturerAlreadyAssignedException,LecturerAssignmentNotFoundException,
   CoordinatorAlreadyAssignedException,CoordinatorAssignmentNotFoundException}.java`;
   `dto/request/{AssignLecturerRequest,AssignCoordinatorRequest}.java`;
   `dto/response/{LecturerAssignmentResponse,ProgramCoordinatorAssignmentResponse}.java`.
4. `service/AssignmentService.java` — `assignLecturer`/`listLecturers`/
   `unassignLecturer` (Class-scoped, via `ClassService`'s existing
   `findOwned`-equivalent — reuse, don't duplicate the tenant-check logic;
   expose a package-private/public `findOwned` on `ClassService` if it
   isn't already, same as `SessionService.findOwned`'s visibility);
   `assignCoordinator`/`listCoordinators`/`unassignCoordinator`
   (Program-scoped, same pattern via `ProgramService`).
5. `controller/LecturerAssignmentController.java`
   (`/organizations/{orgId}/programs/{programId}/classes/{classId}/lecturers`);
   `controller/ProgramCoordinatorAssignmentController.java`
   (`/organizations/{orgId}/programs/{programId}/coordinators`).
6. `constant/AdminConstants.java` — `EVENT_LECTURER_ASSIGNED`,
   `EVENT_LECTURER_UNASSIGNED`, `EVENT_COORDINATOR_ASSIGNED`,
   `EVENT_COORDINATOR_UNASSIGNED`; matching event records. Both the
   assign AND unassign sides write an outbox event from day one (no
   retrofit needed later, unlike the pre-existing `ProctorAssignment`
   gap that `ninh-host-add-student` Phase 2 had to close after the fact).
7. Tests: `AssignmentServiceTest.java` — assign/list/unassign for both
   Lecturer and Coordinator, duplicate-assignment rejected, cross-tenant
   404, unassign-then-reassign works (constraint releases on delete, same
   as `ProctorAssignment`).

## Success Criteria

- [ ] A `HOST_ADMIN` can assign a `LECTURER` user to a `StudentClass`, list
      assignees, and unassign — the same user can be reassigned to a
      different Class afterward.
- [ ] A `HOST_ADMIN` can do the same for `PROGRAM_COORDINATOR` on a
      `Program`.
- [ ] Assigning the same user to the same Class twice is rejected (DB
      unique constraint, not a silent duplicate row).
- [ ] Assigning to a Class/Program belonging to a different tenant is a
      404.
- [ ] `mvn -pl services/admin test` passes, including all new tests from
      Step 7.

## Quality and Testing State

- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after
  implementing this phase).
- Testing: not started.

## Risks

- No server-side check that the assignee actually holds the matching iam
  role — accepted (mirrors the existing `ProctorAssignment` precedent
  exactly), mitigated entirely on the FE side (Phase 9) by only offering
  correctly-roled users in the assignment picker.
