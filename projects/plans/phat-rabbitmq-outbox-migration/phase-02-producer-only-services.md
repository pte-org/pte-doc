# Phase 2: Producer-Only Services (admin, authoring, proctor)

## Requirements

Wire the first 3 of the 8 outbox-writing services onto the new relay: admin, authoring, and proctor publish events but consume none via Kafka today, so this phase is pure producer-side migration with no `@KafkaListener` conversion — the simplest slice, done first to prove the Phase 1 base classes and the backfill-on-migrate pattern before the more complex dual-role services (Phases 3–7).

## Design Constraints

- Each service's existing outbox-writing call sites (`AbstractOutboxWriter` usage inside business transactions) are untouched — only the relay/publish mechanism changes, not how or when a row is written.
- The Flyway migration for each service must, in the same migration, both add the new publish-state columns AND backfill every pre-existing row to `published = true`. Debezium is retired at cutover (Phase 10); if historical rows are left `published = false`, the new relay would attempt to redeliver years of history the first time it runs. This backfill pattern is established here and repeated identically in Phases 3–7.
- RabbitMQ config per service follows `notification`'s house style (`RabbitMqConfig.java`: `DirectExchange` + DLQ via `x-dead-letter-exchange`/`x-dead-letter-routing-key`, `Jackson2JsonMessageConverter`) adapted for a producer: add publisher-confirm settings (`spring.rabbitmq.publisher-confirm-type=correlated`, `publisher-returns=true`, `template.mandatory=true`) since these 3 services only need to publish, not consume — no listener container factory required here.
- Exchange/routing-key convention: one topic exchange per producing service (`outbox.{service}.exchange`), routing key `{aggregateType}.{eventType}` — set here as the reusable template Phases 3–7 also follow.

## Files to touch

- `pte-api/services/admin/src/main/resources/db/migration/V{n}__outbox_publish_state.sql` (new)
- `pte-api/services/admin/src/main/java/com/pte/admin/repository/OutboxRepository.java` (edit — `extends OutboxJpaRepository<OutboxEntry>`)
- `pte-api/services/admin/src/main/java/com/pte/admin/messaging/` — new `AdminOutboxRelay.java`, `RabbitMqConfig.java`
- `pte-api/services/admin/src/main/resources/application.yml` (edit — RabbitMQ connection + `pte.outbox.*` overrides)
- `pte-api/services/admin/pom.xml` (edit — add `spring-boot-starter-amqp`)
- Same 5 file categories repeated under `pte-api/services/authoring/` and `pte-api/services/proctor/`

## Steps

1. Write the Flyway migration for each of the 3 services: add `published`/`published_at`/`publish_attempts`/`last_error` to that service's `outbox` table, backfill existing rows `published = true` in the same script.
2. Change each service's `OutboxRepository` to `extends OutboxJpaRepository<OutboxEntry>`, dropping the old bare `JpaRepository<OutboxEntry, UUID>` extension.
3. Add `spring-boot-starter-amqp` to each service's `pom.xml`; add a `RabbitMqConfig` (topic exchange + DLQ, publisher-confirm properties) adapted from `notification`'s house style.
4. Add a concrete `{Service}OutboxRelay extends AbstractOutboxRelay<OutboxEntry>` per service, wiring `publish()` to `RabbitTemplate.convertAndSend(exchange, routingKey, payload)` with routing key `{aggregateType}.{eventType}`.
5. Add the RabbitMQ connection block to each service's `application.yml` (host/port/credentials, matching `notification`'s existing block) alongside `pte.outbox.poll-interval-ms`/`pte.outbox.batch-size` overrides if defaults need tuning.
6. Build and run each service against the existing local RabbitMQ (already in `docker-compose.yml`) and Postgres; do not remove Debezium/Kafka yet — both mechanisms coexist during this phase (Debezium continues running against the same outbox table for the other 5 not-yet-migrated services; these 3 simply stop being tailed once their connector is later removed in Phase 10).

## Success Criteria

- All 3 services build green (`mvn -pl admin,authoring,proctor -am install`).
- Triggering an existing outbox-writing action per service (e.g. admin onboarding a tenant) produces a row that the new relay picks up and marks `published = true` within one poll interval; the message is observable on the exchange via the RabbitMQ management UI.
- Rows backfilled by the Flyway migration are `published = true` and are NOT redelivered when the relay first runs.
- No change in existing business behavior — the 3 services' non-messaging endpoints and existing tests are unaffected.

## Testing

Normal testing expectations, not TDD-first, not skipped:

- Per service, an integration test against real (Testcontainers or the project's existing convention) Postgres + RabbitMQ: write an outbox row via the existing writer inside a test transaction, invoke the relay's poll method directly (not waiting for `@Scheduled`), assert `published` flips true and a test consumer bound to the exchange receives the message.
- A migration test (row-count/backfill check) confirming pre-existing rows are marked `published = true` by the new Flyway script, not left `false`.
- Full reactor build (`mvn install`) stays green with these 3 services changed.

## Risks

- MEDIUM: Backfill-on-migrate must complete before the new relay's scheduled job starts polling, or a service could crash-loop redelivering historical events on first boot. Mitigation: the backfill runs inside the same Flyway migration transaction (Flyway completes before the Spring context is ready to run `@Scheduled` tasks), so ordering is structurally guaranteed, not just assumed.
- LOW: Exchange/queue naming drift across the 3 services if each is hand-written independently. Mitigation: literally copy-adapt `notification`'s `RabbitMqConfig.java` as the starting template for all 3, don't design from scratch per service.
