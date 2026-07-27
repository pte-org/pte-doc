# Phase 6: Event Backbone Integration

## Requirements

Wire the outbox tables every prior phase already writes to (iam, admin, authoring, scheduling, exam-delivery) into a real Kafka event stream via Debezium's outbox-event-router pattern, and prove the pattern end-to-end with two concrete, idempotent consumers: iam consuming admin's `TenantOnboarded`/`TenantSuspended` (closing the ADR-001 "tenant registry lives in iam" gap left open since Phase 2), and scheduling consuming authoring's `ExamSnapshotPublished` (replacing reliance on the Phase-4 guarded sync pull with an event-driven cache warm, while keeping the sync pull as a resilient fallback for cache-miss/first-boot). Also adds distributed tracing (OpenTelemetry via Micrometer Tracing) across every service so a single `attemptId`/request can be traced end-to-end, per the plan's Phase-6 risk mitigation commitment.

## Design Constraints

- Debezium's `io.debezium.transforms.outbox.EventRouter` SMT reads each service's `outbox` table via Postgres logical replication (`wal_level=logical`, already set in Phase 0's compose) and publishes to topic `outbox.event.{aggregateType}`, key = `aggregate_id`, value = the `payload` column verbatim (already valid JSON from each service's `OutboxWriter`). `event_type`/`tenant_id` become Kafka headers. Column names must be configured explicitly (my schema is snake_case; Debezium's SMT defaults are not) — see connector JSON.
- **Idempotency is mandatory, not optional**: Kafka is at-least-once. Every consumer dedups by the outbox row's `id` (delivered as the Debezium-added `id` header) before applying an event, via a shared `AbstractProcessedEvent` pattern (pte-common) — 2nd occurrence of this pattern after outbox extraction, same DRY threshold logic.
- **Scope decision (documented, not silent): Avro + Schema Registry deferred.** JSON payloads (already typed via each service's own event records) are sufficient while producer and consumer changes land in the same mono-repo PR. Revisit when the platform has independently-deployed teams evolving schemas apart — Schema Registry container stays in `docker-compose.yml` unused until then.
- Consumers only ever *add* local read-optimized state (iam's `TenantRegistry`, scheduling's existing `SnapshotRef`) — never mutate another service's source-of-truth, never call back synchronously to the producer.
- Tracing: Micrometer Tracing + OTLP exporter, sampled at 100% for Milestone 1 (no production traffic yet); correlation-id filter (Phase 0) stays as a secondary, human-readable identifier alongside OTel's W3C trace context.

## Steps

1. `pte-common`: `AbstractProcessedEvent` (`eventId` PK, `processedAt`) — infra plumbing, not business data.
2. Debezium connector JSON (`docker/debezium/connectors/*.json`) for iam, admin, authoring, scheduling, exam_delivery outbox tables; a one-shot `debezium-connectors-setup` compose service registers them via the Connect REST API once Debezium is healthy.
3. iam: `TenantRegistry` entity (tenantId, status) + `ProcessedEvent` + Kafka `@KafkaListener` consuming `outbox.event.Tenant`, dedup-then-upsert.
4. scheduling: extend `SnapshotRefService`/add a consumer for `outbox.event.ExamSnapshot`, dedup-then-cache (same table shape the guarded pull already populates — Phase 4's "may instead consume... removing even the create-time pull" now partially realized: event-driven happy path, sync pull remains as fallback).
5. Kafka client config (`spring-kafka`, `StringDeserializer` for key/value, manual JSON parsing into each service's own event record — no shared DTOs across the wire) added to iam and scheduling only (the two services with concrete consumers this phase).
6. Tracing dependencies + `management.tracing`/OTLP config added to all 7 services (gateway, iam, admin, authoring, scheduling, exam-delivery) + a Jaeger container in `docker-compose.yml`.

## Success Criteria

- Debezium connector configs are valid (JSON schema, column mapping matches actual Flyway schema) — registered via the setup script against a running stack.
- iam and scheduling consumers are idempotent: replaying the same event twice does not double-apply (verified by dedup-table check, not by trusting Kafka's delivery guarantee).
- No consumer calls back synchronously to its producer service.
- A trace spanning gateway → a service → Postgres is visible end-to-end for at least one request.

## Quality and Testing State

- Quality gate: **approved** (2026-07-26). 0 blocking, 1 LOW (missing-header handling in consumers has no explicit Kafka error handler/DLQ — operational hardening, deferred post-Milestone-1). Report + receipt: `pte-api/plans/quang-pte-microservice-platform/quality/phase-06-event-backbone-{quality-report,receipt}.json`.
- Testing: not started — **declined by user** (quality-only cook run). Build Gate green: full 7-module reactor `mvn install`. `docker compose config` valid; all 5 Debezium connector JSON files syntactically valid (verified via JSON parse).

## Runtime-verification TODO (not run here — no live Kafka/Debezium/Postgres cluster in this environment)
- `docker compose up -d` (brings up Postgres/Kafka/Debezium/Jaeger/Redis/RabbitMQ) → `docker compose up debezium-connectors-setup` (registers all 5 connectors) → check `curl http://localhost:8092/connectors` lists all 5, each `RUNNING`.
- Onboard a tenant via admin → confirm iam's `tenant_registry` table gets the row (event round-trip).
- Publish a snapshot via authoring → confirm scheduling's `snapshot_refs` table gets upserted WITHOUT scheduling calling authoring (event-driven path, not the Phase-4 sync-pull fallback).
- Replay the same Kafka message twice (e.g. reset consumer group offset) → confirm no duplicate/double-apply (idempotency).
- Hit any endpoint through the gateway → confirm a trace appears in Jaeger UI (localhost:16686) spanning gateway → service → Postgres.

## Risks

- **HIGH: Cannot fully verify live** — no Kafka/Debezium/Postgres cluster running in this environment; connector JSON and consumer logic are correct-by-construction and locally build-gated, but true end-to-end replication has not been observed running. *Mitigation:* explicit Runtime-verification TODO; `docker compose up` + manual connector registration + produce-a-tenant-then-check-iam-registry is the concrete verification script for whoever runs this stack next.
- **MEDIUM: Debezium column-name mapping is brittle** — any future Flyway migration renaming outbox columns breaks the connector silently until the next CDC event. *Mitigation:* column names are infra-plumbing from `AbstractOutboxEntry`, unlikely to change; connector JSON is version-controlled alongside the schema.
- **LOW: Avro deferred** — accepted scope decision (see Design Constraints); revisit post-Milestone-1.
