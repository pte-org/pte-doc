# Phase 01: Admin inbound messaging infrastructure

## Goal

Give the Admin service the ability to consume events at all. Admin is
publish-only today; nothing downstream in this plan can work until it can
receive, deduplicate, and dead-letter IAM events.

## Why this is its own phase

`services/admin/src/main/java/com/pte/admin/messaging/RabbitMqConfig.java:12`
documents the current state explicitly: *"admin only publishes — no listener
container factory here"*. Admin has `OutboxEntry`, `AdminOutboxRelay`, and
`AdminOutboxCleanupJob`, but no `messaging/consumer/` package, no
`ProcessedEvent` entity, and no `ProcessedEventRepository`. Every other
consuming service (iam, scoring, scheduling, reporting, notification,
exam-delivery) has all three. This phase reaches parity; it delivers no user
visible behavior on its own.

## Work items

1. Add `ProcessedEvent` in `com.pte.admin.domain` extending
   `com.pte.common.messaging.AbstractProcessedEvent`, plus
   `ProcessedEventRepository`, mirroring the existing services.
2. Add a listener container factory and consumer-side settings to
   `RabbitMqConfig`. Keep the existing producer beans and the
   `setAlwaysConvertToInferredType(true)` converter behavior unchanged; update
   the class javadoc, which currently asserts Admin never listens.
3. Declare the inbound queue, its DLQ, the binding to
   `outbox.iam.exchange`, and the routing pattern for user events. Add the
   corresponding constants to `AdminConstants`, following the naming already
   used in `IamConstants` (`QUEUE_TENANT_EVENTS`, `QUEUE_TENANT_EVENTS_DLQ`,
   `TENANT_EVENTS_ROUTING_PATTERN`,
   `TENANT_EVENTS_DEAD_LETTER_ROUTING_KEY`).
4. Add the consumer-side properties to
   `services/admin/src/main/resources/application.yml` — listener concurrency,
   acknowledge mode, and retry — matching the values an existing consuming
   service uses rather than inventing new ones.
5. Add the idempotency guard helper the consumer will call in Phase 2: check
   `ProcessedEvent` by event id, skip if present, record after successful
   handling, inside the same transaction as the projection write.
6. Add the schema migration for the `processed_events` table. Do not rely on
   `ddl-auto: update`, which is dev-only despite being enabled in
   `application.yml:17`.

## Design constraints

- Preflight: mirrored `services/iam` `RabbitMqConfig` and `TenantEventConsumer`,
  `services/notification` retry/DLQ conventions, and the shared
  `AbstractProcessedEvent`/repository shape. Admin's existing outbox exchange,
  relay, and publisher converter remain unchanged; this phase adds only the
  inbound IAM event path and its idempotency infrastructure.

- Copy the established pattern from
  `services/iam/src/main/java/com/pte/iam/messaging/consumer/TenantEventConsumer.java`
  and its `RabbitMqConfig`. Do not invent a new messaging convention for one
  service.
- Producer behavior must not regress: the outbox relay, its exchange bean, and
  publisher-confirm settings stay exactly as they are.
- A poison message must land in the DLQ, not block the queue.
- The idempotency check and the business write share one transaction, or
  at-least-once delivery will double-apply.

## Quality and testing state

- Unit tests: not started; user preference is `unitest: ko`.
- Quality: approved, 0 findings (report:
  `quality/phase-01-admin-event-consumer-infrastructure-quality-report.json`).
- Required non-unit verification: `admin` compiles and boots; RabbitMQ
  management UI (or `rabbitmqctl`) shows the new queue, DLQ, and binding
  declared after startup; publishing a hand-crafted malformed message routes it
  to the DLQ without stalling the consumer.

## Acceptance criteria

- Admin starts with no bean-wiring errors and both publishes and listens.
- Queue, DLQ, and binding to `outbox.iam.exchange` exist after a cold start.
- `processed_events` table is created by the migration, not by `ddl-auto`.
- Replaying the same event id twice results in one applied effect.
- Existing Admin outbox publishing is unaffected.

## Cook status

- Implemented and verified on 2026-09-15.
- Unit tests skipped by explicit user preference.
- No commit or push created.
