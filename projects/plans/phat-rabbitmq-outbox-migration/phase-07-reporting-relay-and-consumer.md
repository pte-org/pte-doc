# Phase 7: reporting — Producer Relay + Consumer Conversion

## Requirements

reporting is both a producer (own outbox, `AttemptPublished`) and the busiest consumer in the platform: `AttemptIngestConsumer` (exam-delivery's `AttemptSubmitted`/`AnswerSubmitted`), `AnswerScoredConsumer` (scoring's `AnswerScored`), and `PublishConsumer` (scheduling's `PublishRequested`). This phase converts all three, completing RabbitMQ migration for every currently-Kafka-dependent consumer service except notification (Phase 8).

## Design Constraints

- Producer-side steps mirror Phases 2–6 (Flyway backfill, generic repository, concrete relay, `RabbitMqConfig` with publisher confirms).
- reporting's read model is a pure projection (per its own phase-08 design constraints from Milestone 1: "owns no source-of-truth", no cross-service DB join, no synchronous call to any producer) — this migration changes only the transport the projection is built from, not that constraint.
- None of reporting's three consumers are ordering-sensitive in the same way as exam-delivery/scoring's per-attempt streams: `AttemptIngestConsumer` upserts idempotently by `attemptPublicId`/`answerPublicId`, `AnswerScoredConsumer` updates an existing projection row by id, `PublishConsumer` acts on a session-level command. Standard concurrency is fine for all three; do not apply Phase 5/6's single-queue-concurrency=1 pattern here unless a specific race is found during testing.
- reporting has its own `KafkaHeaders.java` shared by all three consumers — delete it once all three are converted.
- reporting consumes from THREE different producers (exam-delivery, scoring, scheduling) across three different exchanges — three separate queue bindings, not one, mirroring the three separate topics it consumed from under Kafka.

## Files to touch

- `pte-api/services/reporting/src/main/resources/db/migration/V{n}__outbox_publish_state.sql` (new)
- `pte-api/services/reporting/src/main/java/com/pte/reporting/repository/OutboxRepository.java` (edit)
- `pte-api/services/reporting/src/main/java/com/pte/reporting/messaging/` — new `ReportingOutboxRelay.java`, `RabbitMqConfig.java`
- `pte-api/services/reporting/src/main/java/com/pte/reporting/messaging/consumer/AttemptIngestConsumer.java` (edit)
- `pte-api/services/reporting/src/main/java/com/pte/reporting/messaging/consumer/AnswerScoredConsumer.java` (edit)
- `pte-api/services/reporting/src/main/java/com/pte/reporting/messaging/consumer/PublishConsumer.java` (edit)
- `pte-api/services/reporting/src/main/java/com/pte/reporting/messaging/consumer/KafkaHeaders.java` (delete)
- `pte-api/services/reporting/src/main/resources/application.yml` (edit)
- `pte-api/services/reporting/pom.xml` (edit — add `spring-boot-starter-amqp`)

## Steps

1. Producer side: Flyway backfill migration, `OutboxRepository` generic extension, `ReportingOutboxRelay`, `RabbitMqConfig`, `application.yml` RabbitMQ block.
2. Bind three durable queues (one per producer: exam-delivery's `ExamAttempt`/`AnswerSubmitted` traffic, scoring's `AnswerScored`, scheduling's `PublishRequested`), each with its own DLQ per the `notification` house style.
3. Convert `AttemptIngestConsumer`, `AnswerScoredConsumer`, `PublishConsumer` from `@KafkaListener` to `@RabbitListener`, replacing `KafkaHeaders.require(...)`/`requireString(...)` with the Phase-3-confirmed mechanism in all three.
4. Delete `messaging/consumer/KafkaHeaders.java` once all three consumers no longer reference it.
5. Confirm dedup logic unchanged in shape across all three consumers (`ProcessedEventRepository.existsById` before apply, save after).
6. Remove the three now-unused Kafka topic constants; leave `spring-kafka` in place until Phase 10.
7. Re-run reporting's existing publish-gate scenario end to end (submit → score → publish) entirely over RabbitMQ to confirm the full projection pipeline still produces a correct report.

## Success Criteria

- reporting builds green; producer relay round-trips as verified in Phase 2/3.
- A full submit → score → publish flow (driven from exam-delivery, scoring, scheduling, all already migrated or migrated in this same reactor build) produces a correct, published `AttemptReport` entirely over RabbitMQ, with no Kafka involvement.
- Redelivery of any of the three consumed message types does not double-apply (no duplicate `AnswerProjection`, no re-publish side effect).
- reporting still owns no source-of-truth and makes no synchronous call to any producer — unaffected by this phase.

## Testing

Normal testing expectations, not TDD-first, not skipped:

- Integration test per consumer (real Postgres + RabbitMQ): produce a shaped message on each of the three queues, assert the corresponding projection update and `ProcessedEvent` row.
- End-to-end scenario test: attempt submitted → answer scored → session published, assert the resulting report is correct and visibility-gated per the existing publish-gate rules.
- Idempotency test per consumer: redeliver, assert no double-apply.
- Existing reporting test suite (10–90 aggregation, insufficient-data handling, publish-gate visibility) stays green.
- Full reactor build stays green.

## Risks

- MEDIUM: Three independent consumer conversions in one phase increase the chance of a copy-paste error in one of the three header-extraction rewrites going unnoticed. Mitigation: the end-to-end scenario test (Step 7 / Testing) exercises all three in sequence, not just in isolation.
- LOW: reporting's read model has the most consumers of any service in this migration, making it the largest single-phase surface area — but no new design pattern is introduced here (Phases 3–6 already proved everything reused).
