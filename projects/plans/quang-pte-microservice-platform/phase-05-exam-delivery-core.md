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

- Quality gate: not evaluated.
- Testing: not started.

## Risks

- **HIGH: Timer correctness & clock trust.** Client clocks lie. *Mitigation:* server-authoritative timing; heartbeat only informs UX; response window enforced on submit timestamp server-side.
- **MEDIUM: Pin completeness.** Missing a field at pin time forces a runtime call later (breaks isolation). *Mitigation:* pin the full composition+task content; test attempt with all upstream services down.
- **MEDIUM: Outbox before backbone.** Outbox rows accumulate until Phase 6 wires Debezium. *Mitigation:* acceptable; rows are durable; relay activates in Phase 6.
