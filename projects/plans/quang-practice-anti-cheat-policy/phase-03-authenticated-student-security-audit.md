# Phase 03 — Authenticated Student Security Audit Transport and Host Read Model

**Depends on:** Phase 1  
**Enables:** Phase 4 app transport and Phase 5 end-to-end audit verification  
**Stories:** P1 student warning/audit; P2 host policy/audit visibility

## Objective

Create the missing authenticated student audit contract. Persist lockdown
events against the attempt without fabricating a proctor session, make retries
idempotent, and expose a minimal additive host read model that combines student
lockdown events with existing proctor events.

## Migration preflight decision

The source tree initially contained two unapplied `V68` scripts:
`V68__prevent_duplicate_active_question_revisions.sql` and
`V68__drop_program_coordinator_assignments.sql`. The local PostgreSQL
`flyway_schema_history` contained successful migrations only through `V66`; no
`V67` or `V68` migration had been applied. The unapplied chain was therefore
re-sequenced according to the migration-renumber branch chronology:

- `V67__prevent_duplicate_active_question_revisions.sql`
- `V68__attempt_task_navigation.sql`
- `V69__drop_program_coordinator_assignments.sql`

`V70__attempt_security_events.sql` is reserved as the next unique version for
this phase. No applied migration filename or checksum was changed.

## Exact files/packages likely to change

Existing backend files:

- `pte-api/app/src/main/java/com/pte/attempt/internal/controller/AttemptController.java`
- `pte-api/app/src/main/java/com/pte/attempt/AttemptService.java`
- `pte-api/app/src/main/java/com/pte/attempt/internal/constant/AttemptConstants.java`
- `pte-api/app/src/main/java/com/pte/proctoring/internal/controller/ViolationAuditController.java`

New backend files, kept inside the attempt module except for the read adapter:

- `pte-api/app/src/main/java/com/pte/attempt/domain/AttemptSecurityEvent.java`
- `pte-api/app/src/main/java/com/pte/attempt/domain/enums/LockdownViolationType.java`
- `pte-api/app/src/main/java/com/pte/attempt/internal/dto/request/RecordSecurityViolationRequest.java`
- `pte-api/app/src/main/java/com/pte/attempt/internal/dto/response/SecurityViolationReceipt.java`
- `pte-api/app/src/main/java/com/pte/attempt/dto/response/AttemptSecurityEventView.java`
- `pte-api/app/src/main/java/com/pte/attempt/internal/repository/AttemptSecurityEventRepository.java`
- `pte-api/app/src/main/java/com/pte/attempt/internal/service/AttemptSecurityAuditService.java`
- `pte-api/app/src/main/java/com/pte/attempt/internal/service/AttemptSecurityAuditRetentionService.java` (new)
- `pte-api/app/src/main/resources/application.yml` (retention property)
- `pte-api/app/src/main/java/com/pte/attempt/internal/service/AttemptSecurityAuditQueryService.java` (new)
  behind a public method on `AttemptService`; do not expose the repository to another module

Migration:

- `pte-api/app/src/main/resources/db/migration/V<next-unique>__attempt_security_events.sql` (selected after Flyway preflight)

Existing proctoring read files used to assemble the additive contract:

- `pte-api/app/src/main/java/com/pte/proctoring/internal/service/ViolationService.java`
- `pte-api/app/src/main/java/com/pte/proctoring/internal/dto/response/ViolationEventResponse.java`
- `pte-api/app/src/main/java/com/pte/proctoring/internal/constant/ProctorConstants.java`
- `pte-api/app/src/main/java/com/pte/proctoring/internal/dto/response/SecurityAuditEntryResponse.java` (new)
- `pte-api/app/src/main/java/com/pte/proctoring/internal/dto/response/SecurityAuditPageResponse.java` (new)
- `pte-api/app/src/main/java/com/pte/proctoring/internal/service/SecurityAuditQueryService.java` (new)

Tests:

- new student endpoint/service/repository tests under
  `pte-api/app/src/test/java/com/pte/attempt/...`
- `pte-api/app/src/test/java/com/pte/proctoring/internal/service/ViolationServiceTest.java`
- `pte-api/app/src/test/java/com/pte/proctoring/internal/service/SecurityAuditQueryServiceTest.java`
- focused controller authorization test for the additive security-audit route
- migration/integration contract test in the existing API test convention

Host read consumer (the existing host-audit feature is in `pte-app`, not
tenant-web):

- `pte-app/lib/features/host_audit/domain/host_audit_types.dart`
- `pte-app/lib/features/host_audit/data/models/host_audit_models.dart`
- `pte-app/lib/features/host_audit/data/repositories/host_audit_repository_impl.dart`

- `pte-app/test/features/host_audit/...` repository/model tests

This is a data-contract adaptation for the existing `pte-app` host-audit
reader; no proctor/host visual redesign is in scope.

## Implementation steps

0. Perform the migration preflight before creating any SQL file:
   - list all migration files by version and query `flyway_schema_history` in
     each target environment;
   - determine which duplicate `V68` script, if any, is applied;
   - never rename an applied file/checksum;
   - resequence only unapplied duplicate scripts according to repository
     chronology, then select the next unique version for this table;
   - record the selected version in the plan/ADR and run `flyway validate` plus
     a disposable local `flyway migrate`.
   Do not continue to the table implementation while the chain is ambiguous.
1. Define a bounded `LockdownViolationType` allowlist for the four existing
   app signals: fullscreen exit, blocked shortcut, clipboard change/paste, and
   forbidden-app detection. Keep it separate from the existing manual proctor
   `ViolationType` enum so old proctor vocabulary and hashes do not change.
2. Add `RecordSecurityViolationRequest` with:
   - required `clientEventId`, bounded to a safe length;
   - required allowlisted `violationType`;
   - optional `clientOccurredAt` for diagnostics only;
   - bounded `detail` text/JSON.
   Do not accept client severity, tenant, student, session, or authoritative
   timestamp.
3. Add the selected `V<next-unique>__attempt_security_events.sql` with an additive table. Required
   columns:

   ```text
   id BIGINT identity primary key
   public_id UUID unique not null
   created_at / updated_at / deleted
   attempt_id BIGINT not null references exam_attempts(id)
   attempt_public_id UUID not null
   session_public_id UUID not null
   student_public_id UUID not null
   tenant_id UUID not null
   client_event_id VARCHAR(128) not null
   violation_type VARCHAR(64) not null
   severity VARCHAR(16) not null
   detail TEXT
   client_occurred_at TIMESTAMP WITH TIME ZONE
   detected_at TIMESTAMP WITH TIME ZONE not null
   ```

   Add a unique constraint on `(attempt_id, client_event_id)` and indexes for
   `(tenant_id, session_public_id, detected_at)`,
   `(attempt_public_id, detected_at)`, and the idempotency lookup. The table is
  separate because `violation_events.proctor_session_id` is mandatory and the
  student has no proctor session.
   Bound `detail` at the request/service boundary and make the normalized
   host query cursor-based with a default page size of 50 and a hard maximum
   of 100. The MVP retention decision is 180 calendar days from
   `detectedAt`, owned by Platform Operations. `AttemptSecurityAuditRetentionService`
   runs a daily scheduled cleanup that marks expired rows `deleted=true`; the
   read query excludes deleted rows and no hard delete is performed in this
   release. The property is configurable for a deployment, with 180 as the
   default, and the ADR records the backup/retention owner.
4. Implement the student POST in the attempt controller with `STUDENT` role
   protection. The service must load the attempt by path ID, verify the current
   student and tenant, verify the pinned snapshot, and reject an attempt whose
   effective policy is `NONE`. For `STANDARD`, derive `WARNING`; for `STRICT`,
   derive `CRITICAL`. Use the server's `Instant.now()` for `detectedAt`.
5. Handle a duplicate `(attempt, clientEventId)` as an idempotent success with
   the original receipt. Do not create a second row or publish a second audit
   event. If a client reuses the same ID for a different event, return a stable
   conflict rather than overwriting the first event.
6. Add the public attempt-module read method returning
   `AttemptSecurityEventView`; it must be the only cross-module access to
   student events. Keep controller/repository/entity classes internal.
7. Add exactly
   `GET /api/v1/exam-sessions/{sessionPublicId}/security-audit?limit=&cursor=`.
   Return `SecurityAuditPageResponse` with `entries` and `nextCursor`. Merge
   existing proctor entries and student entries, label `source`, order by
   server `detectedAt` plus `publicId`, and enforce:
   - `HOST_ADMIN`: `SessionService.verifyHostAccess`;
   - `PROCTOR`: `SessionService.checkProctorAssignment` for the caller.
   Keep `/api/v1/exam-sessions/{sessionPublicId}/violations` unchanged for
   backward compatibility.
8. Update the existing `pte-app` host-audit repository from the stale
   `/api/proctor/exam-sessions/.../violations` reader to the new normalized
   endpoint, and adapt its domain/model only for `source`, `severity`,
   `clientEventId`, cursor and the server `detectedAt`. Do not change the live
   proctor STOMP transport or add commands, automatic penalties, or a new
   proctor workflow.

## Data flow and trust boundaries

```text
Student app local row
  -> POST attempt/{id}/security-violations (student JWT)
  -> AttemptSecurityAuditService
       -> ownership + pinned lockdown check
       -> server severity/timestamp/tenant
       -> unique attempt_security_events row
  -> idempotent receipt

Host read
  -> GET exam-sessions/{session}/security-audit (HOST_ADMIN/PROCTOR)
  -> public AttemptService read + existing ViolationService read
  -> normalized, time-ordered audit entries

```
The concrete route is `GET /api/v1/exam-sessions/{sessionPublicId}/security-audit?limit=&cursor=`.
Authorization is role-specific: `HOST_ADMIN` must pass
 `SessionService.verifyHostAccess`; `PROCTOR` must pass
 `SessionService.checkProctorAssignment`. The response is cursor-paged with
a default limit of 50 and a hard maximum of 100.

## Dependencies and handoff

- Phase 1 supplies the pinned `LockdownMode` and policy invariants.
- Phase 4 must use this exact route, payload and idempotency behavior.
- Phase 5 must test both authenticated online delivery and offline replay.

## Acceptance criteria

- [x] Student POST accepts a valid event only for the authenticated student's
  own attempt and tenant.
- [x] Unauthenticated, wrong student, wrong tenant, invalid type, missing
  client ID, and `NONE` policy cases are rejected without an inserted row.
- [x] Server derives severity (`STANDARD` warning, `STRICT` critical), tenant,
  student, attempt and receive timestamp.
- [x] Replaying one `clientEventId` returns one logical event and one row.
- [x] A same-ID/different-event conflict cannot overwrite the original event.
- [x] Migration has the required FK, unique constraint and query indexes.
- [x] The duplicate V68 chain is resolved and documented, the selected
  migration version is unique, and flyway validate passes before migrate.
- [x] Host can read student events through the additive normalized endpoint,
  alongside existing proctor events, with tenant isolation.
- [x] HOST_ADMIN ownership and assigned-PROCTOR authorization are tested; an
  unassigned proctor cannot read the session.
- [x] The normalized response has a hard page limit, cursor semantics, bounded
  detail, and the fixed 180-day Platform Operations retention policy; no
  unbounded list response is introduced.
- [x] The old proctor/STOMP endpoint and its hash-chain semantics remain intact.

**Status:** Complete after hard-checkpoint confirmation. The accepted full-suite
lifecycle/audio baseline failures remain documented and are not part of this
phase's scope.

## Design Constraints

- Student events belong to the attempt boundary. Proctoring must call the
  attempt module's public service/view, never its internal repository.
- Do not create a fake `ProctorSession` for a student.
- Client detail and client occurrence time are evidence fields only; server
  identity, severity and receive order are authoritative.
- Keep the audit endpoint observational. It must not pause, force-submit,
  invalidate, terminate, or alter scoring/report state.
- The migration is additive and safe for existing sessions/attempts. Do not
  alter or relax the mandatory `proctor_session_id` column.
- Limit payload sizes and allowlist event types to prevent arbitrary audit
  storage.
- Use cursor pagination with a default of 50 and hard maximum of 100. The
  retention window is 180 days from detectedAt, owned by Platform Operations;
  the daily cleanup marks deleted=true and all read queries exclude deleted
  rows. No hard delete occurs in this release.

## Quality and Testing State

**Quality:** APPROVED. The Phase 3 quality report has zero blocking findings;
the receipt was issued and verified.  
**Testing:** Focused backend gate 17/17 passed; pte-app host-audit tests 8/8
passed; focused analyzer and production compile passed. Flyway validated and
the local Docker PostgreSQL database migrated successfully through V70. The
full backend suite still has 3 failures and 6 errors in pre-existing
lifecycle/audio tests outside this phase; this is recorded as an accepted
baseline note, not a Phase 3 failure.

Evidence:

- `pte-doc/projects/plans/quang-practice-anti-cheat-policy/tests/phase-03-authenticated-student-security-audit-test-report.json`
- `pte-doc/projects/plans/quang-practice-anti-cheat-policy/quality/phase-03-authenticated-student-security-audit-quality-report.json`
- `pte-doc/projects/plans/quang-practice-anti-cheat-policy/quality/phase-03-authenticated-student-security-audit-receipt.json`

Required verification after implementation:

- Controller/service tests for role, ownership, tenant, policy and payload
  validation.
- Repository/integration tests for the FK, indexes, unique idempotency and
  duplicate response.
- API contract test that verifies the exact student route and response.
- Read-model test proving old proctor events remain visible and student events
  are merged without changing the old endpoint.
- Migration boot test against the local PostgreSQL profile.
- Retention-job test proving rows older than the configured 180-day window are
  marked deleted and excluded from host reads without hard deletion.
- Migration boot test must also run flyway validate against the selected history.
- pte-app host-audit model/repository tests must cover the exact normalized
  route, pagination fields, source/severity and duplicate-safe display.
