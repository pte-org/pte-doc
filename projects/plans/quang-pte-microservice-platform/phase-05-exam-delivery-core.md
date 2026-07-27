# Phase 5: exam-delivery — Core Attempt Flow (Objective)

## Requirements

The critical path and the platform's most-protected service. A student starts an attempt against a session; exam-delivery **pins** the snapshot + composition into its own store at start (self-contained thereafter), serves tasks one at a time with per-task prep/response timers enforced server-side, accepts answer submissions, and advances immediately without waiting for scoring. Milestone 1 proves this end-to-end with Multiple Choice Reading (objective, no audio, no vendor). Writes `AnswerSubmitted`/`AttemptSubmitted` via Transactional Outbox. Zero synchronous outbound calls while a student is testing.

## Design Constraints

- `com.pte.examdelivery`, DB `exam_delivery`, uniform layout.
- **Snapshot + composition pinned at attempt creation** into `PinnedExamSnapshot` (denormalized copy referenced by publicId). The invariant is **zero sync outbound calls _during_ the attempt** — exactly **one guarded sync pull is allowed at attempt-create** (via `client/`, timeout+circuit-breaker) to fetch the snapshot+composition to pin. After IN_PROGRESS, no outbound call occurs. (Once Phase 6 backbone exists, exam-delivery may instead consume `ExamSnapshotPublished`/`SessionScheduled` and cache locally, removing even the create-time pull.)
- Per-task timer enforced **server-side** (client timer is UX only, not the source of truth); prep-time + response-time per task type from pinned composition/config.
- Transactional Outbox: `AnswerSubmitted`, `AttemptSubmitted` written in the same local TX as the answer/attempt state change.
- Redis **warm cache + single-flight** for pinned-snapshot reads (immutable → infinite TTL, no invalidation); Redis is hot layer only, source of truth in Postgres.
- Attempt state machine: `CREATED → IN_PROGRESS → SUBMITTED` (SCORING/SCORED/PUBLISHED driven later by events).
- Concurrency: unique constraint (studentPublicId, sessionId) prevents double attempt; optimistic `@Version` on attempt.
- Resource isolation: own connection pool; heavy/other-service work never on the submit/timer path.

## Steps

1. Entities: `ExamAttempt` (status, sessionPublicId, studentPublicId, @Version), `AttemptAnswer` (taskRef, payload, status), `TimerState`, `PinnedExamSnapshot` + `PinnedItem`, `OutboxEntry`. `domain/enums`: `AttemptStatus`, `AnswerStatus`. Flyway `V1__exam_delivery.sql`.
2. `SnapshotPinService`: on attempt start, copy snapshot+composition (from cached scheduling/authoring events or a one-time pull at creation) into `PinnedExamSnapshot`. After this, no outbound calls.
3. `AttemptService` (state machine): `startAttempt` (pins, guards double-attempt), `getNextTask`, `submitAttempt`. Keep ≤5 public methods; split helpers.
4. `TimerService`: server-side prep/response enforcement per task; reject/auto-submit an answer past its response window.
5. `AnswerSubmitService`: persist `AttemptAnswer` (status SUBMITTED) + write `AnswerSubmitted` outbox row in one TX; advance immediately. `submitAttempt` writes `AttemptSubmitted`.
6. Redis: warm-cache pinned snapshot on attempt start; `single-flight` (`SET NX lock:snapshot:{publicId}`) for cold reads.
7. Controllers: `AttemptController` (start, next-task, submit-answer, submit-attempt), `TimerController` (heartbeat). `ApiResponse<T>`, `@Valid`.
8. `messaging/outbox` table + writer (publisher activation deferred to Phase 6). No consumers yet (AnswerScored/ProctorCommand/AttemptPublished consumed from Phase 7/10/8).
9. Tests: pinning makes attempt independent of authoring (simulate authoring down → attempt still completes); timer auto-submits past window; double-attempt rejected by DB constraint; outbox row written atomically with answer; MCQ end-to-end.

## Success Criteria

- A student completes an MCQ attempt end-to-end with server-enforced per-task timers; no synchronous outbound call occurs during the attempt (verified by test with authoring/scheduling stubbed down).
- `AnswerSubmitted`/`AttemptSubmitted` rows are written to the outbox atomically with the state change.
- Snapshot reads hit Redis warm cache; a cold read triggers exactly one DB load under concurrency (single-flight verified).
- Double attempt for the same (student, session) is rejected by DB constraint, not app check alone.

## Quality and Testing State

- Quality gate: **approved** (2026-07-24). 0 findings. Report + receipt: `pte-api/plans/quang-pte-microservice-platform/quality/phase-05-exam-delivery-core-{quality-report,receipt}.json`.
- Testing: not started — **declined by user** (quality-only cook run). Build Gate green: full 7-module reactor `mvn install` (pte-common+gateway+iam+admin+authoring+scheduling+exam-delivery).

## New architectural piece: service-to-service auth (not anticipated in original design constraints)
Student's own JWT lacks roles for authoring's/scheduling's human-facing endpoints. Added a `/internal/**` surface on authoring+scheduling, authenticated by shared API-key header (`X-Internal-Service-Key`, `InternalApiKeyFilter` in pte-common) via a SEPARATE `SecurityFilterChain` (`@Order(1)`, narrower matcher) evaluated before the normal JWT chain (`@Order(2)`) — explicit placeholder for the mTLS/service-mesh trust ADR-003 defers. exam-delivery's clients always pass the CALLING STUDENT'S OWN identity (from its own validated JWT), never forward the raw token.
- authoring: `GET /internal/snapshots/{publicId}` → full content incl. correct answers (`SnapshotContentResponse`), never on the public endpoint.
- scheduling: `GET /internal/sessions/{publicId}/entitlement?studentPublicId=...` → verifies Enrollment + session OPEN before releasing composition/snapshot ref.

## Implementation notes
- Composition selects task TYPES (not individual items, matches scheduling's actual model) — every snapshot item whose type is included gets pinned in original snapshot order; a composition `timingOverrideSeconds` overrides RESPONSE time only, prep stays default.
- `TaskTimingConfig` (`config/task-timing.json`) covers only the 3 Milestone-1 task types; unconfigured types fail fast (`TaskTimingNotConfiguredException`) rather than silently defaulting — timing values are approximate placeholders pending official Pearson sourcing (tracked risk).
- Auto-expire: `getNextTask`/`submitAnswer` lazily auto-finalize an elapsed unanswered task and advance (no background scheduler needed for Milestone 1 — a true "expire even if the client never calls back" sweep is deferred).
- `NotEntitledException` excluded from the `scheduling` circuit breaker's failure count (`ignore-exceptions` in application.yml) so legitimate 403s never trip the breaker.
- Redis caches the FULL `PinnedItemView` (incl. correct answers) — acceptable for Milestone 1 (same trust zone as Postgres, single Redis instance); revisit if Redis access control diverges from DB's later.

## Runtime-verification TODO
- `docker compose up postgres redis` + run iam+authoring+scheduling+exam-delivery → full attempt lifecycle: start (pins snapshot, warms cache) → next-task → submit-answer (MCQ/Read Aloud/Write Essay) → auto-expire on elapsed timer → complete → verify authoring/scheduling can be stopped mid-attempt with the attempt still completable; verify double-attempt rejected; verify single-flight under concurrent cold-cache requests.

## Risks

- **HIGH: Timer correctness & clock trust.** Client clocks lie. *Mitigation:* server-authoritative timing; heartbeat only informs UX; response window enforced on submit timestamp server-side.
- **MEDIUM: Pin completeness.** Missing a field at pin time forces a runtime call later (breaks isolation). *Mitigation:* pin the full composition+task content; test attempt with all upstream services down.
- **MEDIUM: Outbox before backbone.** Outbox rows accumulate until Phase 6 wires Debezium. *Mitigation:* acceptable; rows are durable; relay activates in Phase 6.
