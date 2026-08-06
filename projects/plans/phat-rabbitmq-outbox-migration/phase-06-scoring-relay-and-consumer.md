# Phase 6: scoring — Producer Relay + Consumer Conversion (Ordering-Sensitive)

## Requirements

scoring is both a producer (own outbox, `AnswerScored`/`AttemptScored`) and a consumer of two topics: `ScoringCommandConsumer` (host-issued scoring commands) and `AnswerIngestConsumer` (ingesting submitted answers to score). Like exam-delivery (Phase 5), answer ingestion per attempt is ordering-sensitive — scoring a later answer before an earlier one for the same attempt could produce an inconsistent partial-scoring state.

## Design Constraints

- Producer-side steps mirror Phases 2–5 (Flyway backfill, generic repository, concrete relay). scoring already depends on `spring-boot-starter-amqp` (from its existing AI-vendor scoring queue, Milestone 1 Phase 9) — this phase reuses that dependency, does not add a duplicate.
- Ordering mitigation for `AnswerIngestConsumer`: same pattern as Phase 5 — route `AnswerSubmitted` events through a routing key scoped to `attemptPublicId`, single durable queue, listener concurrency = 1 for this specific queue. `ScoringCommandConsumer` (host commands, one-shot, not a stream of ordered per-attempt events) does not need this constraint — normal concurrency is fine there.
- **`AnswerSubmitted` is published by exam-delivery's relay (Phase 5), not scoring's own.** This consumer-side guarantee only holds if exam-delivery's relay never runs more than one instance — same reasoning as Phase 5's proctor constraint, just the other direction (exam-delivery is the producer here, scoring the ordering-sensitive consumer). This is already covered by the "single relay instance per producing service" deployment constraint recorded against exam-delivery; no new action in this phase beyond noting the dependency explicitly (plan-reviewer finding, ACCEPTED).
- scoring has its own `KafkaHeaders.java` (`messaging/consumer/KafkaHeaders.java`) shared by both consumers — delete it once both are converted, same as exam-delivery's Phase 5 treatment.
- scoring's existing AI-vendor RabbitMQ queue (retry/backoff/DLQ, Milestone 1 Phase 9) is a SEPARATE concern from this outbox-relay migration — do not conflate the two RabbitMQ usages or merge their exchanges/queues; they serve different purposes (one is a work queue for AI vendor calls, the other is the event backbone).

## Files to touch

- `pte-api/services/scoring/src/main/resources/db/migration/V{n}__outbox_publish_state.sql` (new)
- `pte-api/services/scoring/src/main/java/com/pte/scoring/repository/OutboxRepository.java` (edit)
- `pte-api/services/scoring/src/main/java/com/pte/scoring/messaging/` — new `ScoringOutboxRelay.java`, extend existing `RabbitMqConfig.java` (or add a second config class clearly separated from the AI-vendor queue config)
- `pte-api/services/scoring/src/main/java/com/pte/scoring/messaging/consumer/ScoringCommandConsumer.java` (edit)
- `pte-api/services/scoring/src/main/java/com/pte/scoring/messaging/consumer/AnswerIngestConsumer.java` (edit)
- `pte-api/services/scoring/src/main/java/com/pte/scoring/messaging/consumer/KafkaHeaders.java` (delete)
- `pte-api/services/scoring/src/main/resources/application.yml` (edit)

## Steps

1. Producer side: Flyway backfill migration, `OutboxRepository` generic extension, `ScoringOutboxRelay`, exchange/publisher-confirm config added distinctly from the existing AI-vendor queue config.
2. Bind an ordering-preserving queue for `AnswerSubmitted` ingestion (routing key scoped by `attemptPublicId`, concurrency = 1) and a normal-concurrency queue for host scoring commands.
3. Convert `ScoringCommandConsumer` and `AnswerIngestConsumer` from `@KafkaListener` to `@RabbitListener`, replacing `KafkaHeaders.require(...)`/`requireString(...)` calls with the Phase-3-confirmed mechanism.
4. Delete `messaging/consumer/KafkaHeaders.java` once both consumers no longer reference it.
5. Confirm dedup logic unchanged in shape for both consumers.
6. Remove the now-unused Kafka topic constants for both consumers; leave `spring-kafka` in place until Phase 10.
7. Manually verify answer-ingestion ordering: submit two answers for the same attempt in quick succession, confirm scoring processes them in submission order.

## Success Criteria

- scoring builds green; producer relay round-trips as verified in Phase 2/3.
- Answers for a given attempt are ingested/scored in submission order, verified by the manual check in Step 7 and the corresponding automated test below.
- Host scoring commands still apply correctly (no ordering requirement, but no regression).
- Redelivery of any consumed message does not double-score an answer.
- scoring's existing AI-vendor queue (Milestone 1 Phase 9) is unaffected — verified by its existing tests still passing.

## Testing

Normal testing expectations, not TDD-first, not skipped:

- Integration test (real Postgres + RabbitMQ): submit two answers for the same attempt in immediate succession, assert ingestion/scoring order matches submission order.
- Idempotency test: redeliver an `AnswerSubmitted` message, assert no double-score.
- Existing scoring test suite (objective rule-based scoring, AI-vendor queue retry/backoff/DLQ) stays green.
- Full reactor build stays green.

## Risks

- HIGH: Ordering regression on answer ingestion is the primary risk — double-scoring or out-of-order partial state for an attempt undermines score correctness. Mitigation: single-queue/concurrency=1 binding for `AnswerIngestConsumer` specifically, plus the explicit ordering test; `ScoringCommandConsumer` is not subject to the same constraint and should not be over-constrained.
- MEDIUM: Two RabbitMQ concerns (AI-vendor work queue vs. event-backbone relay) now coexist in one service — risk of accidental config/exchange cross-wiring. Mitigation: explicit separate config classes/exchange names, called out in Design Constraints, reviewed at merge time.
