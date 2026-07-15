# Phase 1 (Track 4): Append-Only Audit Log

**Track:** 4 — Payload Security & Audit
**Covers:** FR-09 · User story: P2 (audit log)
**Blocking dependency for:** Track 1 Phases 2, 3, 4

---

## Design Constraints

- Audit log is **append-only** — no update/delete API, ever. Enforce at the DB layer (no `UPDATE`/`DELETE` grants on the table for the application role, or a DB trigger that rejects them) in addition to not exposing those operations in the service layer.
- Must be usable by other tracks (Track 1) before Track 4 finishes — ship the schema + a minimal `AuditLogService.record(...)` early; don't gold-plate this phase with the full audit *viewer* UI (that can land later without blocking anyone).
- Event types needed by other tracks now: `LOGIN`, `SUBMIT`, `BLUR_EVENT`, `MULTI_DEVICE_BLOCKED`, `TAMPER_ATTEMPT`. Use an extensible `eventType` string/enum, not a hardcoded list, so future event types don't require a migration.

## Files to Touch

- `aptis-api/src/main/resources/db/migration/` — new Flyway migration: `audit_log` table (`id`, `actor_id`, `action` / `event_type`, `exam_attempt_id` nullable, `metadata` JSONB, `created_at`).
- `aptis-api/src/main/java/com/aptis/common/audit/AuditLog.java` — new entity.
- `aptis-api/src/main/java/com/aptis/common/audit/AuditLogService.java` — new service, `record(actorId, eventType, examAttemptId, metadata)`.
- `aptis-api/src/main/java/com/aptis/common/audit/AuditLogRepository.java` — new repository, read-only query methods (by attempt, by actor, by event type, by time range).

## Implementation Steps

1. Write Flyway migration for `audit_log` table with an index on `exam_attempt_id` and `created_at`.
2. Create `AuditLog` JPA entity — immutable (no setters after construction beyond what JPA requires).
3. Create `AuditLogService.record(...)` — single write path, always appends, never updates.
4. Create `AuditLogRepository` with only `save` and read/query methods exposed — no update/delete methods on the repository interface.
5. Add a DB-level safeguard (trigger or restricted grant) rejecting `UPDATE`/`DELETE` on `audit_log`.
6. Write unit test confirming `AuditLogService.record(...)` persists correctly and that attempting to mutate an existing row via direct repository access fails.

## Acceptance Criteria

- [ ] `audit_log` table exists via Flyway migration, with `event_type`, `actor_id`, `exam_attempt_id`, `metadata`, `created_at` columns.
- [ ] `AuditLogService.record(...)` is callable by other modules (verify via a smoke call from `ExamAttemptService`).
- [ ] Direct `UPDATE`/`DELETE` against `audit_log` is rejected at the DB layer, verified by test.
- [ ] Maps to spec success criterion: "Post-submit mutation attempts return a rejection response and produce an audit log entry" (this phase provides the log entry mechanism; Track 1 Phase 2 wires the rejection).

## Quality and Testing State

- Quality: not evaluated
- Testing: not started
