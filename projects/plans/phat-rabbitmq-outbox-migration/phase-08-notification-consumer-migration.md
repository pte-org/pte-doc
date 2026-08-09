# Phase 8: notification — Consumer-Only Migration

## Requirements

notification is the platform's 12th service and the only pure consumer with no outbox of its own — it consumes `UserCreated`, `StudentEnrolled`, `AttemptPublished`, `ViolationDetected` (`UserDirectoryConsumer`, `EnrollmentNotificationConsumer`, `AttemptPublishedConsumer`, `ViolationNotificationConsumer`) and sends email via its existing RabbitMQ work queue. This phase converts all four `@KafkaListener`s to `@RabbitListener`s; there is no producer-side work here at all, unlike every other phase in this plan.

## Design Constraints

- notification already depends on `spring-boot-starter-amqp` and already has a working `RabbitMqConfig.java` (the DirectExchange + DLQ + `Jackson2JsonMessageConverter` + `RetryOperationsInterceptor` house style every other phase's producer config has been adapted from) — this phase ADDS the four event-backbone consumer queues alongside the existing `EMAIL_QUEUE`/`EMAIL_DLQ` work queue, kept as clearly separate concerns (event-backbone consumption vs. the internal email work queue), same separation principle as scoring's Phase 6 treatment.
- All four consumers subscribe to events published by OTHER services' relays (iam for `UserCreated`, scheduling for `StudentEnrolled`, reporting for `AttemptPublished`, proctor for `ViolationDetected`) — this phase only lands cleanly once those 4 producers are already migrated (Phases 2, 3, 4, 7), so this phase is ordered last among the per-service consumer phases.
- notification has its own `KafkaHeaders.java` shared by all four consumers — delete it once all four are converted, same treatment as exam-delivery/scoring/reporting.
- None of the four consumers are ordering-sensitive (each acts on an independent, self-contained event — a new user, an enrollment, a published report, a violation) — standard concurrency for all four, no single-queue-concurrency=1 pattern needed here.

## Files to touch

- `pte-api/services/notification/src/main/java/com/pte/notification/config/RabbitMqConfig.java` (edit — add 4 queue/exchange bindings)
- `pte-api/services/notification/src/main/java/com/pte/notification/messaging/consumer/UserDirectoryConsumer.java` (edit)
- `pte-api/services/notification/src/main/java/com/pte/notification/messaging/consumer/EnrollmentNotificationConsumer.java` (edit)
- `pte-api/services/notification/src/main/java/com/pte/notification/messaging/consumer/AttemptPublishedConsumer.java` (edit)
- `pte-api/services/notification/src/main/java/com/pte/notification/messaging/consumer/ViolationNotificationConsumer.java` (edit)
- `pte-api/services/notification/src/main/java/com/pte/notification/messaging/consumer/KafkaHeaders.java` (delete)
- `pte-api/services/notification/src/main/resources/application.yml` (edit — remove Kafka bootstrap config)

## Steps

1. Bind four durable queues in `RabbitMqConfig`, each to the correct producer's exchange (iam, scheduling, reporting, proctor) and correct routing key, each with its own DLQ — added alongside, not replacing, the existing email work-queue config.
2. Convert all four `@KafkaListener` consumers to `@RabbitListener`, replacing `KafkaHeaders.require(...)`/`requireString(...)` with the Phase-3-confirmed mechanism.
3. Delete `messaging/consumer/KafkaHeaders.java` once all four consumers no longer reference it.
4. Confirm dedup logic unchanged in shape across all four consumers.
5. Remove the four now-unused Kafka topic constants and the Kafka bootstrap-servers block from `application.yml`; `spring-kafka` dependency removal itself is deferred to Phase 10 alongside every other service.
6. Re-run each of the four notification scenarios end to end (a user created, a student enrolled, an attempt published, a violation detected) against the now-migrated producers, confirming an email lands in Mailpit for each.

## Success Criteria

- notification builds green.
- All four events (from their now-RabbitMQ-native producers) result in the correct email being sent, verified against Mailpit.
- Redelivery of any of the four message types does not double-send an email.
- The existing email work queue (retry/backoff/DLQ to `EMAIL_DLQ`) is unaffected by the new event-backbone queues added alongside it.

## Testing

Normal testing expectations, not TDD-first, not skipped:

- Integration test per consumer (real Postgres + RabbitMQ + Mailpit or a mail-sending stub): produce a shaped message on each of the four queues, assert the corresponding email is sent/queued and a `ProcessedEvent` row exists.
- Idempotency test per consumer: redeliver, assert no double-send.
- Existing notification test suite (SMTP send, retry/backoff/DLQ on the email work queue) stays green.
- Full reactor build stays green — this is the last of the 6 originally Kafka-consuming services, so the reactor build at the end of this phase is also the first checkpoint where NO service still requires Kafka to function correctly (Kafka/Debezium containers are still present but no longer load-bearing, pending Phase 10's removal).

## Risks

- LOW: This phase depends on Phases 2, 3, 4, 7 already being complete (their producers must be emitting to RabbitMQ for notification's consumers to have anything to consume) — sequencing risk if run out of order. Mitigation: explicit dependency noted in `plan.md`, phase ordering enforces it.
- LOW: Four independent consumer conversions in one phase, same copy-paste-error risk as Phase 7 — mitigated the same way, by testing each end to end against Mailpit rather than only unit-testing the parsing logic.
