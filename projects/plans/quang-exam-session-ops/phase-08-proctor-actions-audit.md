# Phase 8: Proctor Privileged Actions & Audit Logging

## Requirements

Implement 4 privileged proctor actions on the proctor dashboard: force-submit (immediately complete an attempt), extend-time (add minutes to a student's per-section or overall time), flag-violation (mark an attempt with an integrity concern), and broadcast-announcement (send a text message to all students in the room). Each action must produce an immutable audit log entry in a new `PROCTOR_ACTION` table (columns: actor_id, target_attempt_id, action_type, timestamp, details_json) before returning success to the proctor. Actions take effect on the student's session within seconds via Phase 7 WebSocket push.

Maps to: **P1 Story #7 | FR-07**

## Design Constraints

- Each of the 4 actions must write exactly one `PROCTOR_ACTION` audit row within the same database transaction as the state change (atomicity).
- Audit rows must be immutable after creation (no updates, only inserts); audit table should have no DELETE permissions in production.
- Proctor must be authorized to perform actions only on attempts/students in their assigned session/room (no cross-room actions).
- Actions must be non-repudiable: actor_id, timestamp, and action details must all be recorded correctly and verifiably.
- Broadcast-announcement is a special case: it's a one-to-many action (targets all students in the room); the audit row should record this clearly (e.g., action_type="BROADCAST_ANNOUNCEMENT", details include the message text and recipient count).
- **CRITICAL — authorization must be atomic with the state change**: the "proctor assigned to this room" check must happen inside the same database transaction as the state mutation (e.g. via `SELECT ... FOR UPDATE` on the room/session-assignment row, or a `WHERE assigned_proctor_id = :proctorId` clause on the update itself), not as a separate check-then-act step. A check performed before loading the target row, with the mutation applied afterward, leaves a window where a revoked assignment or a stale read lets an unauthorized proctor's action land — no data mutation may occur until authorization is verified against the current, locked state of the row.
- **CRITICAL — concurrent state-change locking**: force-submit and a legitimate in-flight student submission race on the same `ExamAttempt` row. Use pessimistic locking (`SELECT ... FOR UPDATE` on `ExamAttempt` within the transaction) so only one of {student submit, proctor force-submit} wins; the other must receive a 409 Conflict rather than silently overwriting state. Optimistic locking (version field) is an acceptable alternative only if the losing request is retried/reported as a conflict, not silently dropped.
- Proctor actions are idempotent: performing the same action twice (e.g. a double-click on force-submit) must not be treated as two independent state transitions — check current state before mutating (e.g. "if already SUBMITTED, return 200 OK" instead of attempting the transition again).

## Steps

1. Create the `PROCTOR_ACTION` table schema with columns: id (UUID primary key), actor_id (UUID, not null), target_attempt_id (UUID, nullable — null for broadcast), action_type (enum: FORCE_SUBMIT, EXTEND_TIME, FLAG_VIOLATION, BROADCAST_ANNOUNCEMENT), action_timestamp (OffsetDateTime, not null), details (JSON, nullable, contains action-specific details like duration_minutes for extend-time, message_text for broadcast).

2. Implement force-submit action: POST /api/proctoring/attempts/{attemptId}/force-submit. Within a single transaction: `SELECT ... FOR UPDATE` the target `ExamAttempt`, verify (against the locked row) the attempt's session is assigned to the authenticated proctor, verify status is not already SUBMITTED (if it is, return 200 OK idempotently without re-writing), mark status to SUBMITTED, set submittedAt to now, write the `PROCTOR_ACTION` audit row — all in that one transaction. If the row was concurrently locked/modified by the student's own submit, the loser of the lock receives 409 Conflict.

3. Implement extend-time action: POST /api/proctoring/attempts/{attemptId}/extend-time with body {minutes: int, sectionId: UUID (optional)}. Within a single transaction: lock and verify proctor-to-room assignment against the current row (same pattern as step 2); if `sectionId` is provided, increment (or create) the corresponding `SessionTimeOverride.override_minutes` row from Phase 4; if omitted, increment the attempt's overall remaining time; write audit row with action_type=EXTEND_TIME, details includes {section_id (nullable), original_minutes, added_minutes, new_total_minutes}.

4. Implement flag-violation action: POST /api/proctoring/attempts/{attemptId}/flag-violation with body {reason: string}. Within a single transaction: lock and verify proctor-to-room assignment against the current row, add a flag record or set a flag field on ExamAttempt, write audit row with action_type=FLAG_VIOLATION, details includes {reason}.

5. Implement broadcast-announcement action: POST /api/proctoring/sessions/{sessionId}/broadcast with body {message: string}. Verify proctor-to-room assignment against the session row (lock not required here since there's no per-attempt state mutation), send the message to all students' WebSocket connections in that session (via SimpMessagingTemplate) as plaintext only (no HTML/Markdown parsing — client escapes on display), write audit row with action_type=BROADCAST_ANNOUNCEMENT, details includes {message_text, recipient_count}, in the same transaction as the audit write.

6. Authorization is not a separate pre-check: each endpoint's proctor-to-room verification (steps 2–5) must read the current, locked state of the target row inside the action's transaction — never verify against a value read before the transaction/lock was acquired. If verification fails, return 403 Forbidden and roll back before any mutation.

7. Implement service layer that performs the state change, writes the audit row, and pushes status updates to the proctor dashboard (triggering WebSocket message via Phase 7 mechanism).

8. Test end-to-end for each action: perform the action, verify audit row is created, verify student sees the effect (e.g., extended time reflected in their timer), verify proctor dashboard receives the update.

## Success Criteria

- All 4 actions are available from the proctor API (force-submit, extend-time, flag, broadcast all respond with 200 OK).
- Each action creates exactly one PROCTOR_ACTION audit row with correct actor_id, timestamp, and action_type.
- Force-submit immediately changes student's attempt status to SUBMITTED; student cannot submit again.
- Extend-time adds the specified minutes to the student's timer; effect is visible on student's client within seconds.
- Flag-violation records the reason in audit details; flagged attempt is visible in audit query.
- Broadcast-announcement is received by all students in the room via WebSocket within 2 seconds.

## Quality and Testing State

- Quality gate: **approved** (report: `quality/phase-08-proctor-actions-audit-quality-report.json`, receipt issued 2026-07-16). One HIGH finding fixed: authorization was checked via an unlocked read of `exam.getProctorId()` after locking only `ExamAttempt` — combined into a single atomic `findByIdAndAssignedProctorForUpdate` query (WHERE clause + lock, closing the CRITICAL constraint gap). One MEDIUM: `proctor_action` migration was missing BaseEntity's `updated_at`/`is_deleted` columns — fixed, plus a related pre-existing Phase 7 bug found and fixed opportunistically (V9's proctor table used `deleted` instead of `is_deleted`).
- Testing: **passed** — 180 total in the full suite (179 passed, 1 pre-existing unrelated skip), zero regressions across phases 1-8. New: `ProctorActionServiceTest` (9), `ProctorBroadcastServiceTest` (6), `ProctorActionAuditServiceTest` (10), plus extensions to `ExamAttemptTest` (+7) and `StompAuthChannelInterceptorTest` (+8). Report: `tests/phase-08-proctor-actions-audit-test-report.json`.

## Session Notes

- **Schema adaptation**: the plan's `extend-time` request specified `sectionId: UUID`, but no "Section" entity with a UUID id exists — Phase 4's `SessionTimeOverride` keys on (examId, skill, part) instead, so the request/response DTOs use `skill`+`part` (both optional; omitted = apply to `ExamAttempt.extraTimeMinutes` instead).
- **Placement decision**: the 3 per-attempt actions (force-submit, extend-time, flag) and broadcast all live in `examdelivery` (which owns `ExamAttempt`/counts attempts), not `proctor` — `proctor` only owns the audit trail (`ProctorAction`) and WebSocket infra, called into from `examdelivery` (an already-established one-directional dependency from Phase 7).
- **New: students can now open a WebSocket connection** (Phase 7 was proctor-only) — required for broadcast delivery via `/topic/exam/{examId}/announcements`. A new `StudentAttemptLookup` interface in `common` lets the interceptor (in `proctor`) authorize a student's subscription without `proctor` depending on `examdelivery` directly (would have cycled back, since `examdelivery` already depends on `proctor`); `examdelivery` implements it.
- **Idempotency scope**: only `forceSubmit()` is idempotent (double-click safe, no duplicate audit row) per the phase's own example; `extendTime()`/`flag()` are each treated as legitimately repeatable, distinct events, not wrapped in the same guard.
- STOMP subscription authorization tightened from Phase 7's "unrecognized destination → let it through" to deny-by-default, since the connecting population is no longer proctor-only.
- Build Gate: PASS.

## Risks

- **Audit table write failure silent**: If the PROCTOR_ACTION insert fails after the state change commits, the action takes effect but audit row is missing. Mitigation: wrap state change and audit insert in a database transaction with proper error handling; if audit insert fails, roll back the entire action (fail-safe); log the error and return 500 Internal Server Error to the proctor.
- **Action timing race condition**: If a student submits at the same time a proctor force-submits, the two state changes might conflict. Resolved by mandatory `SELECT ... FOR UPDATE` locking specified in Step 2; the loser gets a 409 Conflict or explicit "action already completed" error.
- **Extend-time interaction with per-section time**: Phase 4 stores per-section overrides in a dedicated `SessionTimeOverride` table (FK to section_id). Extend-time's request body must include an optional `sectionId` — if provided, increments that section's `SessionTimeOverride.override_minutes` (creating the row if absent); if omitted, applies to the attempt's overall remaining time. Document this branch explicitly in the endpoint's request schema; test both paths.
- **Broadcast-announcement message injection**: If the message text is not sanitized, a proctor could send SQL injection or XSS payloads. Mitigation: treat the message as plaintext (no HTML/Markdown parsing); store in JSON as a string; on display, escape HTML entities in the client.
