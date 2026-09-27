# Phase 3: iam — Producer Relay + Consumer Conversion

## Requirements

iam is both a producer (own outbox, e.g. `UserCreated`) and a consumer of admin's `Tenant` events (`TenantEventConsumer`, populating iam's local `TenantRegistry`). This phase gives iam the same producer-side relay as Phase 2, then converts its one Kafka consumer to RabbitMQ — the first phase to exercise both halves of the migration and the first real integration test of Phase 1's `AbstractOutboxRelay` end to end.

## Design Constraints

- Producer-side steps mirror Phase 2 exactly (Flyway backfill migration, `OutboxRepository extends OutboxJpaRepository<OutboxEntry>`, concrete relay, `RabbitMqConfig` with publisher-confirm settings) — not re-derived here, follow that phase's template.
- `TenantEventConsumer` currently dedups via `UUID.fromString(headerValue(record, "id"))` and branches on `IamConstants.KAFKA_HEADER_EVENT_TYPE`, both read from Kafka record headers Debezium sets. The RabbitMQ replacement is CONFIRMED (user, Validation step): AMQP message properties — relay sets `messageId` (the outbox row id, as the dedup key) and a custom `headers` entry for event type when publishing (Phase 2's relay `publish()` hook), consumer reads `Message.getMessageProperties()` instead of `ConsumerRecord.headers()`, not `EventEnvelope<T>`/JSON body.
- No `KafkaHeaders.java` exists for iam (it already parses headers inline) — nothing to delete here, just replace the inline `headerValue` helper's Kafka-specific implementation.
- `spring-kafka` stays in `iam/pom.xml` for this phase (removed only in Phase 10, after every consumer-side service is confirmed working on RabbitMQ) — this phase adds `spring-boot-starter-amqp` alongside it, doesn't remove Kafka yet.

## Files to touch

- `pte-api/services/iam/src/main/resources/db/migration/V{n}__outbox_publish_state.sql` (new)
- `pte-api/services/iam/src/main/java/com/pte/iam/repository/OutboxRepository.java` (edit)
- `pte-api/services/iam/src/main/java/com/pte/iam/messaging/` — new `IamOutboxRelay.java`, `RabbitMqConfig.java`
- `pte-api/services/iam/src/main/java/com/pte/iam/messaging/consumer/TenantEventConsumer.java` (edit — `@KafkaListener` → `@RabbitListener`, header parsing rewritten)
- `pte-api/services/iam/src/main/resources/application.yml` (edit)
- `pte-api/services/iam/pom.xml` (edit — add `spring-boot-starter-amqp`)

## Steps

1. Producer side: Flyway backfill migration, `OutboxRepository` generic extension, `IamOutboxRelay`, `RabbitMqConfig` (exchange + publisher-confirm), `application.yml` RabbitMQ block — same pattern as Phase 2.
2. Define the queue/binding iam consumes from: bind a durable queue to admin's `outbox.admin.exchange` with a routing pattern matching the `Tenant` aggregate's event types (`Tenant.TenantOnboarded`, `Tenant.TenantSuspended`), plus a DLQ per the `notification` house style.
3. Convert `TenantEventConsumer.onTenantEvent` from `@KafkaListener(topics = ..., groupId = ...)` + `ConsumerRecord<String,String>` to `@RabbitListener(queues = ...)` + `Message`/`@Payload` + `MessageProperties`, replacing the Kafka header read with the AMQP-properties read per the Design Constraints (or the confirmed alternative).
4. Confirm dedup logic is unchanged in shape: still check `ProcessedEventRepository.existsById(eventId)` before applying, still insert a `ProcessedEvent` row after — only the transport-level extraction of `eventId`/event type changes.
5. Remove the Kafka topic constant(s) this consumer used (`IamConstants.TOPIC_TENANT_EVENTS`) once the RabbitMQ queue name replaces it; keep `IamConstants.KAFKA_HEADER_EVENT_TYPE` renamed to a transport-neutral name if it's now read from AMQP headers instead.
6. Do not remove `spring-kafka` from `iam/pom.xml` yet — both dependencies coexist this phase; Kafka cleanup is Phase 10, after every consumer-side service is verified.

## Success Criteria

- iam builds green; producer relay round-trips an event to RabbitMQ exactly as verified in Phase 2.
- Publishing a `Tenant` event from admin (post-Phase-2, running its own new relay) results in iam's `TenantRegistry` being upserted via the converted `@RabbitListener`, with no synchronous call from iam to admin.
- Re-delivering the same message (e.g. via RabbitMQ's manual redelivery or a forced nack-then-requeue) does not double-apply — `ProcessedEvent` dedup still holds under the new transport.
- iam no longer needs the previously-running Debezium/Kafka path to receive tenant events (verified by stopping the Debezium connector for admin and confirming the flow still works via RabbitMQ alone).

## Testing

Normal testing expectations, not TDD-first, not skipped:

- Integration test (real Postgres + RabbitMQ): produce a `TenantOnboarded`-shaped message onto the queue iam binds to, assert `TenantRegistry` is upserted and a `ProcessedEvent` row exists.
- Idempotency test: deliver the identical message twice, assert only one apply (no duplicate registry row, no exception on the second delivery).
- Existing iam test suite (auth/JWT/JWKS, tenant onboarding via admin's endpoint if end-to-end-tested) stays green — this phase must not regress unrelated iam behavior.
- Full reactor build stays green.

## Risks

- LOW (downgraded from MEDIUM — mechanism confirmed during Validation, see `plan.md`): AMQP message properties is settled ahead of this phase, removing the rework risk to Phases 4/6/7/8 that existed while it was still open. iam remains the first phase to actually exercise the pattern in code, so it's still the first real end-to-end check of the approach, just no longer a design-confirmation risk.
- LOW: Dropping the Kafka topic constant while `spring-kafka` is still a live dependency could leave dead Kafka config in `application.yml` (e.g. unused `bootstrap-servers`) until Phase 10. Mitigation: acceptable, explicitly cleaned up in Phase 10, not a functional risk in the interim.
