# Plan: Exam Session Support Operations (Upload, Delivery, Proctoring, Session Settings)

Status: 🟢 Completed
Date: 2026-07-15
Mode: Hard
Created by: Quang

## Overview

This plan delivers end-to-end exam session operations: question authoring for all 4 skills (Vendor and Host scoped), bulk import, session configuration, skill-subset filtering, live proctor dashboards via WebSocket, 4 privileged proctor actions with audit logging, and explicit retry approvals. Unblocks mock-test security/performance work and supports the first full slice of aptis-lms beyond flat-MCQ MVP.

## Phases

- [x] Phase 1: Question Entity Extension & Vendor/Host Authoring — Extend `Question` entity with `tenantId`/`source` enum; implement CRUD and UI for all 4 skills (MCQ, Listening, Writing, Speaking) [quality: approved; backend only — aptis-web UI not implemented, tracked as gap]
- [x] Phase 2: Audio Upload Wiring for Listening/Speaking — Reuse existing `CloudinaryServiceImpl` proxy pattern for question authoring audio [quality: approved]
- [x] Phase 3: Bulk Import (Excel/ZIP) for Flat MCQ — Synchronous import with per-row validation and error reporting [quality: approved]
- [x] Phase 4: Exam Session Settings & Configuration — Add 5-axis configurable session settings (skill subset, per-section time, proctor-required, availability window, retry count) [quality: approved; "session" = existing Exam entity, no separate ExamSession layer exists]
- [x] Phase 5: Delivery API Skill-Subset Filtering & Constraints — Filter exam content by session settings; enforce availability window; strip answers [quality: approved, zero findings]
- [x] Phase 6: ExamAttempt Status Model & Heartbeat Mechanism — Add intermediate status enum and client-initiated heartbeat with server timeout detection [quality: approved, zero findings; tests: 36/36 passed]
- [x] Phase 7: WebSocket/STOMP Infrastructure & PROCTOR Role — Add WebSocket/STOMP with JWT auth, per-room authorization, new PROCTOR role, realtime status push [quality: approved; tests: 141/142 passed (1 unrelated pre-existing skip)]
- [x] Phase 8: Proctor Privileged Actions & Audit Logging — Implement 4 actions (force-submit, extend-time, flag, broadcast) with `PROCTOR_ACTION` audit table [quality: approved; tests: 179/180 passed]
- [x] Phase 9: RetryRequest Entity & Approval Queue — Standalone retry-request approval flow; block exam start on pending requests [quality: approved, 1 HIGH fixed (transaction isolation moved to outer boundary); tests: 230/230 passed]

## Research Summary

Two researcher agents validated these decisions during `/ck:plan --researcher`:

1. **WebSocket/STOMP for proctor realtime**: Add `spring-boot-starter-websocket` to `aptis-api` pom.xml; authenticate at STOMP CONNECT via `ChannelInterceptor.preSend()` validating JWT (reuse `JwtService`); store room assignment in `WebSocketSession` attributes at handshake; use per-room topic destinations (e.g., `/user/{sessionId}/queue/attempt-status`) gated by `@PreAuthorize` at subscription; use Spring's in-memory `SimpleBroker` (explicitly NOT RabbitMQ/Redis — that's a future scaling item at >50 concurrent sessions); design pushed message as serializable POJO `ProctorStatusMessage` to decouple from broker swap later.

2. **Heartbeat mechanism**: Client-initiated heartbeat every ~10s updates `ExamAttempt.lastHeartbeatAt` via lightweight endpoint or STOMP message; server-side considers attempt DISCONNECTED after missing 3 consecutive heartbeats (~30s at 10s interval), not a single miss, to avoid false positives from network jitter; a scheduled job or event-driven check applies this timeout and updates status.

3. **RetryRequest**: New standalone entity (studentId, attemptId/sessionId, status enum{PENDING,APPROVED,REJECTED}, requestedAt, reviewedAt, reviewedBy) — its own approval queue, explicitly NOT shared with any AI Writing/Speaking scoring-confirmation queue. Exam start must check for and block on any PENDING RetryRequest.

4. **Audio upload**: Reuse `CloudinaryServiceImpl` proxy-upload pattern as-is for question authoring — no new upload mechanism, just wire question-authoring endpoints to it.

5. **Bulk import (FR-02)**: Synchronous request-response for Excel/ZIP import — validate all rows in-transaction, return per-row error array in response. Explicitly NOT async job/polling pattern (files <100KB/<1000 rows per spec).

6. **Audit logging**: Bespoke, feature-specific `PROCTOR_ACTION` table (actor, target_attempt_id, action_type, timestamp, details) — explicitly NOT a shared generic `AuditLog` service. Every one of the 4 proctor privileged actions (force-submit, extend-time, flag, broadcast) must write a row.

7. **Question-bank data model**: Single `Question` table extended with `tenantId: UUID` (nullable — null=Vendor-owned/shared, non-null=Host-scoped) and `source: enum{VENDOR,HOST}`, following existing `Asset` entity's `tenantId` pattern for consistency.

## Dependencies

- Existing `iam`, `tenancy`, `questionbank`, `examoperations`, `examdelivery`, `asset`, `storage` modules in `aptis-api` (Spring Boot 4.1 / Java / Maven)
- Existing `CloudinaryServiceImpl` (storage module) proxy-upload pattern and `Asset` entity model
- Existing JWT + Spring Security `@PreAuthorize` for role-based access control
- Existing roles (ADMIN, HOST, STUDENT, GRADER) to which PROCTOR will be added
- `spring-boot-starter-websocket` dependency (to be added to pom.xml in Phase 7)
- No external audit-logging framework; bespoke `PROCTOR_ACTION` table

## Red-Team Review (plan-reviewer, 2026-07-15)

Verdict: **BLOCK** on first pass — 3 CRITICAL + 9 HIGH findings. All 12 were **ACCEPTED** and fixed directly in the relevant phase files (see diffs in phase-02, 03, 04, 05, 06, 07, 08, 09):

- Phase 7: added a mandatory Step 0 deployment-topology check before building on SimpleBroker (single-node/sticky-session precondition) — **verified 2026-07-15: `aptis-api` is single-instance (docker-compose, no Redis/RabbitMQ, in-memory Caffeine session cache), so SimpleBroker is confirmed safe** — plus a logout-triggered WebSocket cleanup step.
- Phase 8: authorization checks are now mandated to run atomically (locked-row read) inside the same transaction as the state mutation, for all 4 proctor actions; force-submit uses `SELECT ... FOR UPDATE` against concurrent student submits; actions are idempotent by design.
- Phase 6: heartbeat timeout unified to a single 35-second elapsed-time threshold (was inconsistently 30s/35s across step vs. risk text); submit transition uses the same row-level locking as Phase 8's force-submit.
- Phase 9: tenant check now runs before role check on approve/reject; retry status read is explicitly READ COMMITTED-or-stronger; approved requests transition to CONSUMED to close the re-approval race; `max_retry_count` semantics defined explicitly (total attempts, not "extra" retries).
- Phase 5: answer-stripping DTO is now mandatory on every student-facing Question-returning endpoint, with an enumeration-based security test (not per-endpoint review).
- Phase 2: MIME-type whitelist + 50MB size validation moved from "risk mitigation" into a required implementation step.
- Phase 3: audio uploads to Cloudinary now run fully before the DB transaction opens, so a mid-import upload failure can't leave a half-committed state or an ambiguous error.
- Phase 4: per-section time overrides use a dedicated `SessionTimeOverride` table (not JSON), giving Phase 8's extend-time action a well-typed target.

9 additional NOTED findings were either subsumed by the fixes above or are accepted residual risk (see below). Re-review not re-run after fixes (all findings were mechanical/additive, no new phase dependencies introduced) — a `ck:quality --gate` pass per phase during cook is the next verification point.

## Risks

- **MEDIUM (accepted residual)**: STOMP message ordering under SimpleBroker — in-order delivery is only guaranteed per-destination within a single node (see Phase 7 Step 0 topology precondition); `ProctorStatusMessage` carries a timestamp so the proctor dashboard can reorder client-side if messages arrive out of sequence. Revisit if/when a broker relay (RabbitMQ/Redis) is introduced at higher concurrent-session scale.

- **MEDIUM**: Session settings enforcement inconsistency — if exam-delivery code fails to enforce the availability window or skill-subset filter in one code path, students could start sessions outside the window or see questions from disabled skills. Mitigation: add integration-level tests for each setting axis (skill subset, availability window, per-section time); verify filter logic at the section-fetch and question-level; review all exam-delivery endpoints before Phase 5 completion.

- **LOW**: PROCTOR role creation without tenant scoping — if a Host can create a PROCTOR user that's not linked to their tenant, proctor might see sessions from other tenants. Mitigation: enforce `tenantId` on proctor user creation; add pre-condition check in "assign proctor to session" flow; test cross-tenant access in audit phase.
