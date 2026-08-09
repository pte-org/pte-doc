# Phase 4: scheduling — Producer Relay + Consumer Conversion

## Requirements

scheduling is both a producer (own outbox, e.g. `SessionScheduled`, `StudentEnrolled`, `ScoringRequested`/`PublishRequested` commands) and a consumer of authoring's `ExamSnapshotPublished` (`SnapshotEventConsumer`, upserting `SnapshotRef`). This phase repeats Phase 3's shape for scheduling, using the header/correlation mechanism confirmed in Phase 3 (no re-litigating that decision here).

## Design Constraints

- Producer-side steps mirror Phase 2/3 (Flyway backfill, generic repository, concrete relay, `RabbitMqConfig` with publisher confirms).
- `SnapshotEventConsumer` dedups the same way iam's consumer did pre-migration (`headerValue(record, "id")`, branch on `SchedulingConstants.KAFKA_HEADER_EVENT_TYPE`) — apply the exact same transport-level rewrite Phase 3 established, no design decisions left open here.
- No `KafkaHeaders.java` exists for scheduling (inline header parsing, same as iam) — rewrite the inline helper, nothing to delete.
- The Phase 4 (original walking-skeleton) design note that scheduling's event-driven snapshot cache is the happy path with the create-time sync pull to authoring as a resilient fallback stays unchanged — this migration only changes the transport under the happy path, not the fallback behavior.

## Files to touch

- `pte-api/services/scheduling/src/main/resources/db/migration/V{n}__outbox_publish_state.sql` (new)
- `pte-api/services/scheduling/src/main/java/com/pte/scheduling/repository/OutboxRepository.java` (edit)
- `pte-api/services/scheduling/src/main/java/com/pte/scheduling/messaging/` — new `SchedulingOutboxRelay.java`, `RabbitMqConfig.java`
- `pte-api/services/scheduling/src/main/java/com/pte/scheduling/messaging/consumer/SnapshotEventConsumer.java` (edit)
- `pte-api/services/scheduling/src/main/resources/application.yml` (edit)
- `pte-api/services/scheduling/pom.xml` (edit — add `spring-boot-starter-amqp`)

## Steps

1. Producer side: Flyway backfill migration, `OutboxRepository` generic extension, `SchedulingOutboxRelay`, `RabbitMqConfig`, `application.yml` RabbitMQ block.
2. Bind a durable queue to authoring's `outbox.authoring.exchange` for the `ExamSnapshot` aggregate's published event, plus DLQ.
3. Convert `SnapshotEventConsumer.onSnapshotEvent` from `@KafkaListener` to `@RabbitListener`, replacing header extraction with the Phase-3-confirmed mechanism.
4. Confirm dedup logic unchanged in shape (`ProcessedEventRepository.existsById` before apply, `ProcessedEvent` save after).
5. Remove the now-unused Kafka topic constant (`SchedulingConstants.TOPIC_SNAPSHOT_EVENTS`) in favor of the RabbitMQ queue name; leave `spring-kafka` in place until Phase 10.
6. Verify the create-time sync-pull fallback to authoring (unrelated to this migration) still compiles and works untouched.

## Success Criteria

- scheduling builds green; producer relay round-trips as verified in Phase 2/3.
- Publishing `ExamSnapshotPublished` from authoring (post-Phase-2) results in scheduling's `SnapshotRef` being upserted via the converted `@RabbitListener`, with no synchronous call to authoring on the happy path.
- Redelivery of the same message does not double-apply.
- Stopping authoring's Debezium connector does not break this flow — it now runs entirely over RabbitMQ.

## Testing

Normal testing expectations, not TDD-first, not skipped:

- Integration test (real Postgres + RabbitMQ): produce an `ExamSnapshotPublished`-shaped message, assert `SnapshotRef` is upserted with a `ProcessedEvent` row.
- Idempotency test: duplicate delivery, assert single apply.
- Existing scheduling test suite (session/composition/enrollment) stays green.
- Full reactor build stays green.

## Risks

- LOW: Scheduling's snapshot cache correctness under the new transport is the same logic as before, only the delivery mechanism changed — low regression risk given Phase 3 already proved the pattern.
- LOW: Losing the create-time sync-pull fallback's relevance if the event-driven path is now reliably faster — not a risk to functionality, just a possible later cleanup opportunity, out of scope for this migration.
