# Phase 5: exam-delivery — Producer Relay + Consumer Conversion (Ordering-Sensitive)

## Requirements

exam-delivery is both a producer (`AnswerSubmitted`/`AttemptSubmitted` outbox) and a consumer of proctor's commands (`ProctorCommandConsumer`, applying `FORCE_SUBMIT`/`EXTEND_TIME`). Unlike Phases 3–4, this consumer is ordering-sensitive: two commands for the same attempt (e.g. an extend followed by a force-submit) must apply in the order proctor issued them, which Kafka's per-partition ordering gave for free and RabbitMQ's polling-outbox relay does not guarantee across concurrent pollers by default.

## Design Constraints

- Producer-side steps mirror Phases 2–4 (Flyway backfill, generic repository, concrete relay, `RabbitMqConfig` with publisher confirms). exam-delivery's zero-synchronous-outbound-during-an-attempt invariant (ADR-002) is unaffected — this migration only changes the outbound relay transport, not exam-delivery's request-path behavior.
- Ordering mitigation (per `plan.md`'s target design): route all `ProctorCommand` events for a given attempt through routing key `ProctorCommand.{attemptPublicId}` bound to a SINGLE durable queue consumed with concurrency = 1, so RabbitMQ's own FIFO-per-queue guarantee preserves enqueue order for that attempt even though publish order across different attempts/aggregates is not guaranteed. This is a queue/consumer-concurrency design choice, not a code-level sequencing mechanism — do not add artificial delays or a custom sequence-number scheme.
- **exam-delivery's own producer relay (built in this phase) must also stay single-instance**, for the same reason in the other direction: scoring's `AnswerIngestConsumer` (Phase 6) depends on `AnswerSubmitted` events reaching it in the order exam-delivery wrote them to its outbox. Record this alongside the proctor constraint below as an explicit deployment note for exam-delivery.
- **The proctor-command consumer-side guarantee above only holds if proctor's own relay (Phase 2) never runs more than one instance.** `SELECT ... FOR UPDATE SKIP LOCKED` lets concurrent pollers claim different unlocked rows — if proctor ever ran 2 relay instances, two `ProctorCommand` rows for the same attempt could be claimed by different instances and confirmed to RabbitMQ out of insertion order, before they ever reach exam-delivery's single queue. This plan does NOT add aggregate-hash-partitioned claiming to the relay (over-engineering for this team's scale) — instead, "single relay instance per producing service" is an explicit, documented deployment constraint for proctor specifically (and scoring, see Phase 6), not an implicit assumption. Record it in Phase 2's deployment notes for proctor and revisit only if proctor is ever scaled to multiple instances (plan-reviewer finding, ACCEPTED).
- `ProctorCommandConsumer` currently uses the dedicated `KafkaHeaders.require(record, "id")` helper (exam-delivery has its own `KafkaHeaders.java`). This file is deleted in this phase, not deferred to Phase 10, since it's exam-delivery-consumer-specific dead code the moment the conversion lands.
- The proctor producer side (its own outbox/relay) is delivered in Phase 2 — this phase only converts exam-delivery's consumption of proctor's commands, it does not touch proctor.

## Files to touch

- `pte-api/services/exam-delivery/src/main/resources/db/migration/V{n}__outbox_publish_state.sql` (new)
- `pte-api/services/exam-delivery/src/main/java/com/pte/examdelivery/repository/OutboxRepository.java` (edit)
- `pte-api/services/exam-delivery/src/main/java/com/pte/examdelivery/messaging/` — new `ExamDeliveryOutboxRelay.java`, `RabbitMqConfig.java`
- `pte-api/services/exam-delivery/src/main/java/com/pte/examdelivery/messaging/consumer/ProctorCommandConsumer.java` (edit)
- `pte-api/services/exam-delivery/src/main/java/com/pte/examdelivery/messaging/consumer/KafkaHeaders.java` (delete)
- `pte-api/services/exam-delivery/src/main/resources/application.yml` (edit)
- `pte-api/services/exam-delivery/pom.xml` (edit — add `spring-boot-starter-amqp`)

## Steps

1. Producer side: Flyway backfill migration, `OutboxRepository` generic extension, `ExamDeliveryOutboxRelay`, `RabbitMqConfig`, `application.yml` RabbitMQ block.
2. Design and bind the ordering-preserving queue for proctor commands: single durable queue bound to proctor's exchange for the `ProctorCommand` aggregate, listener container concurrency explicitly pinned to 1 for this queue (documented inline why — ordering, not throughput).
3. Convert `ProctorCommandConsumer.onProctorCommand` from `@KafkaListener` to `@RabbitListener`, replacing `KafkaHeaders.require(...)` with the Phase-3-confirmed AMQP-properties mechanism.
4. Delete `KafkaHeaders.java` from exam-delivery's consumer package now that nothing references it.
5. Confirm dedup logic unchanged in shape (`ProcessedEventRepository.existsById` before apply, `ProcessedEvent` save after).
6. Remove the now-unused Kafka topic constant (`ExamDeliveryConstants.TOPIC_PROCTOR_COMMAND_EVENTS`); leave `spring-kafka` in place until Phase 10.
7. Manually verify ordering under load: issue an extend-time then a force-submit for the same attempt in quick succession, confirm exam-delivery applies them in that order, not reversed.

## Success Criteria

- exam-delivery builds green; producer relay round-trips as verified in Phase 2/3.
- Proctor commands for a given attempt apply in the order issued, verified by the manual ordering check in Step 7 (and the corresponding automated test below).
- Redelivery of the same command does not double-apply (e.g. a force-submit redelivered does not re-force-submit an already-submitted attempt in a way that errors or double-counts).
- exam-delivery's zero-synchronous-outbound-during-attempt invariant is unaffected — no new sync call introduced anywhere in this phase.

## Testing

Normal testing expectations, not TDD-first, not skipped:

- Integration test (real Postgres + RabbitMQ): publish an extend-time then a force-submit for the same attempt in immediate succession, assert they apply in issue order.
- Idempotency test: redeliver the same command, assert no double-apply / no error on an already-terminal attempt.
- Existing exam-delivery test suite (attempt state machine, timer enforcement, submit flow) stays green — this phase must not regress the core exam-taking path.
- Full reactor build stays green.

## Risks

- HIGH: Ordering regression is the primary risk of this phase specifically — a force-submit applied before an extend-time (or vice versa, out of issue order) could corrupt attempt state. Mitigation: single-queue/concurrency=1 binding per Design Constraints, plus the explicit ordering test in Testing; do not relax concurrency for throughput without re-verifying ordering. This mitigation depends on proctor running a single relay instance (Design Constraints above) — a second instance would let publish order itself drift before it ever reaches this queue, upstream of any consumer-side fix.
- LOW: `KafkaHeaders.java` deletion is a clean removal (single consumer, no other references) — negligible risk.
