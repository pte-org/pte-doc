# Phase 10: Proctor — Live Supervision

## Requirements

A proctor assigned to an exam session (scheduling's `ProctorAssignment`, Phase 4) opens a live monitoring session, can force-submit or extend time for a specific student's attempt, and can flag a violation against an attempt. Per ADR-001, `proctor` shares no DB with `exam-delivery` — every attempt-affecting action travels as an async command (`ProctorCommand`) through the event backbone; `exam-delivery` consumes and applies it. Violations are recorded in a tamper-evident, hash-chained audit log and emit `ViolationDetected` for future consumers (notification in Phase 11).

## Design Constraints

- `com.pte.proctor`, DB `proctor` (role/DB already pre-provisioned in Phase 0's `01-create-databases.sql`), uniform layout.
- **No sync call from proctor into exam-delivery, ever** (ADR-002 communication matrix: proctor's only edge to exam-delivery is `ProctorCommand` via the event backbone). The one guarded sync call this phase makes is proctor → scheduling, to verify the caller is actually assigned to the session (`/internal/sessions/{id}/proctor-assignment`) — mirrors the exam-delivery→scheduling entitlement-check precedent from Phase 5, and is not on any student-facing critical path.
- **WebSocket/STOMP is the primary command surface** (per plan.md), not REST — this is genuinely real-time: several proctors can watch the same session and see each other's flags/commands live via a shared topic. JWT is authenticated on the STOMP `CONNECT` frame's `Authorization` header (not the HTTP handshake — native WS handshakes in most browser clients can't set custom headers; STOMP frames can, uniformly, regardless of client).
- **Tamper-evident audit log**: each `ViolationEvent` is SHA-256 hash-chained to the previous one within its `ProctorSession` (`hash = SHA256(sessionPublicId|seq|attemptPublicId|type|detail|detectedAt|prevHash)`); the running `lastSequenceNo`/`lastHash` head lives on `ProctorSession` and advances in the same transaction as the new row, so there's no race window. Verifying integrity later = replay in sequence order and recompute; a tampered/deleted row breaks the chain. External anchoring (e.g. periodic hash publication to a write-once store) is out of scope for Milestone 1 — documented cut.
- Two outbound event types, both written now (outbox), consumed later where relevant:
  - `ProctorCommand` (aggregateType `ProctorCommand`, topic `outbox.event.ProctorCommand`) — `commandType` ∈ `{FORCE_SUBMIT, EXTEND_TIME}`. **Consumed this phase** by exam-delivery.
  - `ViolationDetected` (aggregateType `ViolationEvent`, topic `outbox.event.ViolationEvent`) — **not consumed this phase** (Phase 11 notification, and reporting, are the eventual consumers); matches the established project convention of writing the outbox row before the consuming phase exists.
- exam-delivery gains its first Kafka **consumer** (it had none through Phase 9 — outbox-only producer). Idempotent via a new `ProcessedEvent` ledger (`AbstractProcessedEvent`), same pattern as scoring/reporting/scheduling.
- A proctor-issued `FORCE_SUBMIT`/`EXTEND_TIME` is a distinct authorization path from the student's own `submitAttempt`/timer flow (system-applied, tenant-scoped only, no student-ownership check) — kept in a separate `ProctorCommandService` in exam-delivery rather than overloading `AttemptService` (which is already at the ≤5-public-method ceiling).

## Steps

1. scheduling: `ProctorAssignmentRepository.existsBySessionIdAndProctorPublicId`; `ProctorNotAssignedException`; `EntitlementService` gains a second public method `checkProctorAssignment(sessionPublicId, proctorPublicId)`; `InternalSessionController` gains `GET /internal/sessions/{publicId}/proctor-assignment?proctorPublicId=...`.
2. proctor module (11th service): `ProctorSession` (sessionPublicId, proctorPublicId, tenantId, status ACTIVE/ENDED, lastSequenceNo, lastHash), `ViolationEvent` (proctorSessionId FK, attemptPublicId, violationType, detail, sequenceNo, prevHash, hash), `OutboxEntry`. Flyway `V1__proctor.sql`.
3. `SchedulingClient` + `InternalClientConfig` (RestClient + resilience4j circuit breaker, mirrors exam-delivery's Phase 5 client) — the one guarded call, made once per WS `open`, not per command.
4. `ProctorSessionService.open`/`close` (idempotent open: an existing ACTIVE session for the same session+proctor is resumed, not duplicated).
5. `ProctorCommandService.issueCommand` — validates session ACTIVE, writes `ProctorCommand` outbox row, broadcasts a confirmation over STOMP.
6. `ViolationService.flag` — computes the next hash-chain link, saves `ViolationEvent` + updated `ProctorSession` head in one TX, writes `ViolationDetected` outbox row, broadcasts.
7. WebSocket: `WebSocketConfig` (STOMP endpoint `/ws`, broker prefix `/topic`+`/queue`, app prefix `/app`), `StompAuthChannelInterceptor` (validates JWT on CONNECT, rejects unauthenticated frames), 3 `@MessageMapping` handlers (open/command/violation) — PROCTOR role enforced explicitly in the shared `currentUser()` helper since `@PreAuthorize` doesn't reliably apply to `@MessageMapping` — + broadcast to `/topic/proctor-sessions/{sessionPublicId}`. Plain REST: `GET /exam-sessions/{sessionPublicId}/violations` (audit review across every proctor who watched that exam session), `POST /proctor-sessions/{proctorSessionPublicId}/close`.
8. exam-delivery: add `spring-kafka`; `ProcessedEvent`/`ProcessedEventRepository` (first consumer this service has had); `ProctorCommandConsumer` (`@KafkaListener(topics = "outbox.event.ProctorCommand")`, idempotent, dispatches by `commandType`); `ProctorCommandService.forceSubmit`/`extendResponseTime` (tenant-scoped lookup via new `ExamAttemptRepository.findByPublicIdAndTenantId`, silent no-op if attempt not found or not IN_PROGRESS — same honest-no-op convention as scoring's consumers).
9. Infra: `docker/debezium/connectors/proctor-outbox-connector.json`; gateway gains a `ws://` route for `/api/proctor/ws/**` (listed before the general `/api/proctor/**` HTTP route); parent `pom.xml` module list gains `proctor`.

## Success Criteria

- A proctor connects over STOMP, opens a `ProctorSession` for a session they're assigned to (verified against scheduling); a proctor NOT assigned is rejected.
- A `FORCE_SUBMIT` command reaches exam-delivery via Kafka and transitions the target attempt from `IN_PROGRESS` to `SUBMITTED`, writing `AttemptSubmitted`.
- An `EXTEND_TIME` command pushes the target attempt's current `TimerState.responseDeadline` forward by the requested seconds.
- A flagged violation is persisted with a correct hash chain (each row's `hash` recomputes from `prevHash` + its own fields) and broadcast live to any other proctor subscribed to the same session's topic.
- No component in this phase makes a synchronous call from proctor into exam-delivery — verified by code inspection (only Kafka in, only scheduling client out).

## Quality and Testing State

- Quality gate: **APPROVED** (`ck:quality --gate`). First pass returned CHANGES_REQUIRED with 1 HIGH + 2 MEDIUM blocking findings, all fixed and verified in a second pass:
  - QUAL-001 (HIGH): `ProctorSessionRepository`'s lookups had no `tenantId` filter, so a caller who is a proctor in one tenant could reach another tenant's `ProctorSession`/`ViolationEvent` chain by publicId. Fixed by adding tenant-scoped repository methods and threading `caller.tenantId()` through `ProctorSessionService.open/close/findOwned` and both call sites.
  - QUAL-002 (MEDIUM): the 3 STOMP `@MessageMapping` handlers had no PROCTOR role check (`@PreAuthorize` doesn't enforce reliably on `@MessageMapping`). Fixed by adding an explicit `hasRole("PROCTOR")` check inside the shared `currentUser(Principal)` helper every handler routes through.
  - QUAL-003 (MEDIUM): the STOMP endpoint allowed WS origin `"*"`. Fixed with a configurable `proctor.ws.allowed-origin-patterns` property (default `http://localhost:*`).
  - QUAL-004 (LOW, non-blocking): `ViolationEventRepository.findByProctorSessionIdOrderBySequenceNoAsc` was tenant-unfiltered AND, on inspection, dead code (zero call sites) — removed rather than patched (YAGNI).
- Testing: skipped by user direction (quality-only cook mode).

## Risks

- **MEDIUM: WS-through-gateway routing unverified.** Spring Cloud Gateway's WebSocket proxying (`ws://` route) is configured per documented pattern but not runtime-tested this session (no test execution this cook run). *Mitigation:* flagged as a runtime-verification TODO; falls back to hitting proctor directly on its own port for local dev if gateway proxying needs adjustment.
- **LOW: Extend-time race.** If a proctor's `EXTEND_TIME` command arrives after the student has already auto-advanced to the next task, it extends whatever `TimerState` is current at apply-time, not necessarily the task the proctor was looking at. Inherent to async commands (ADR-002 eventual-consistency trade-off), not a bug — documented, not fixed.
- **LOW: Hash-chain anchoring.** The chain proves internal consistency (no row silently edited/deleted without detection on replay) but nothing external anchors it — a full DB compromise could rewrite the whole chain consistently. Out of scope for Milestone 1.
