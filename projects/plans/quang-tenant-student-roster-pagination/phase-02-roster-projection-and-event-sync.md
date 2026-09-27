# Phase 02: Roster projection and event synchronization

## Goal

Extend the IAM user event payload, create the Admin-owned roster projection, and
keep it current for every newly created or suspended student.

## Work items

1. Extend `com.pte.iam.domain.event.UserCreatedEvent`. It currently carries only
   `userPublicId`, `email`, `tenantId`, `roles`. Add `fullName`, `studentCode`,
   `phone`, `status`, and the immutable `createdAt` — the projection cannot
   derive creation time from its own insert, because backfilled rows would sort
   wrong.
2. Update both publish sites so the new fields are populated:
   `UserService.create` (`UserService.java:95`) and
   `UserBulkCreateWriter` (`UserBulkCreateWriter.java:79`). The bulk import path
   must not be forgotten — it is how most students are created.
3. Verify the existing consumer still deserializes the widened payload.
   `notification`'s `UserDirectoryConsumer` binds
   `messaging/consumer/dto/UserCreatedEvent.java`, a narrower record. Confirm
   the Jackson configuration ignores unknown properties rather than assuming it;
   if it does not, fix the deserialization config before shipping the producer
   change.
4. Add the `StudentRosterEntry` entity in `com.pte.admin.domain` with only safe
   display fields: `studentPublicId`, `tenantId`, `email`, `fullName`,
   `studentCode`, `phone`, `status`, `createdAt`. Never copy password data,
   login hashes, or IAM internal ids.
5. Add the unique constraint `(tenant_id, student_public_id)` — this is the
   upsert key that makes replay and rebuild idempotent — plus indexes for
   `(tenant_id, created_at)` and the searchable columns (normalized full name,
   email, phone, student code).
6. Add `StudentRosterConsumer` in `com.pte.admin.messaging.consumer` handling
   `UserCreated` (upsert, STUDENT role only) and `UserSuspended` (status
   update). Use the Phase 1 idempotency guard inside the write transaction.
   Phase 5 adds the `UserReactivated` branch to this same consumer — leave the
   event-type dispatch open for it rather than hard-coding two cases.
7. Add the explicit, idempotent schema migration for the projection table and
   its indexes.
8. Record the standing constraint in the IAM service docs: adding a user-update
   endpoint requires emitting a `UserUpdated` event and extending this consumer,
   or the projection serves stale profile data.

## Design constraints

- Preflight: confirmed the two IAM `UserCreated` producers (`UserService` and
  `UserBulkCreateWriter`), the narrow notification DTO's
  `@JsonIgnoreProperties(ignoreUnknown = true)`, IAM's `User` fields/status,
  and Admin's separate database/entity conventions. The projection will use a
  local wire DTO and `(tenant_id, student_public_id)` upsert key; no IAM
  domain import or cross-database query is permitted.

- IAM owns user identity/authentication; Admin owns academic hierarchy and
  membership. No direct database query across services.
- Adding fields to a published event is only safe if every existing consumer
  tolerates them — item 3 is a gate, not a note.
- The projection is non-authoritative. It is never the source of truth for
  authentication, and it is always rebuildable from IAM.
- Only STUDENT-role users enter the projection. Hosts, proctors, and platform
  users must not appear in a student roster.
- IAM's free-text `class_name` profile field is not copied and is not an
  assignment.
- Upserts key on `(tenant_id, student_public_id)`, never on a generated id.

## Quality and testing state

- Unit tests: not started; user preference is `unitest: ko`.
- Quality: approved, 0 findings (report:
  `quality/phase-02-roster-projection-and-event-sync-quality-report.json`).
- Required non-unit verification: `iam`, `admin`, and `notification` compile;
  create a student through the live API and confirm the projection row appears
  with all display fields; confirm `notification` logs no deserialization
  failure for the same event; suspend the student and confirm the projection
  status follows; replay the event and confirm no duplicate row.

## Acceptance criteria

- A student created through `POST /users` produces exactly one projection row in
  the correct tenant, with a `createdAt` matching IAM's.
- A student created through `POST /users/bulk` does the same.
- A non-STUDENT user produces no projection row.
- `notification`'s existing consumer continues to process `UserCreated` without
  error after the payload widens.
- Suspending a user updates the projection `status`.
- Redelivering the same event leaves the row unchanged and creates no duplicate.
- The projection table and indexes come from the migration, not `ddl-auto`.

## Cook status

- Implemented and verified on 2026-09-15.
- Unit tests skipped by explicit user preference.
- No commit or push created.
