# Phase 10: Infra Cleanup — Remove Kafka, Debezium, Schema Registry

## Requirements

Every producer (Phases 2–7) and consumer (Phases 3–8) is verified working entirely on RabbitMQ before this phase runs. This phase removes the now-load-bearing-nothing infrastructure: the Kafka/Schema-Registry/Debezium containers from `docker-compose.yml`, the Debezium connector configs, and the `spring-kafka` Maven dependency from every service that had it — plus `spring-boot-starter-amqp` added anywhere still missing it.

## Design Constraints

- This phase runs LAST among the infra/dependency changes — never before every producer/consumer phase is confirmed working, or a still-Kafka-dependent service would be stranded with no broker.
- `wal_level=logical` on the Postgres container (`docker-compose.yml`) was required only for Debezium's WAL tailing — safe to revert to the default once Debezium is removed, but only if nothing else in the stack depends on logical replication (confirm before removing; if uncertain, leave it set, it's a low-cost no-op with no relay in this migration depending on it).
- Schema Registry was already documented as "deferred/unused YAGNI" even under Kafka (Milestone 1 Phase 6 design constraint) — removing it has no functional impact, only removes dead infrastructure.
- Root `pom.xml` and `pte-common/pom.xml` were confirmed NOT to declare `spring-kafka` centrally (each service declares it individually) — this phase's dependency removal is a per-service `pom.xml` edit, not a parent-POM change.

## Files to touch

- `pte-api/docker-compose.yml` (edit — remove `kafka`, `schema-registry`, `debezium-connect`, `debezium-connectors-setup` service blocks)
- `pte-api/docker/debezium/` (delete entire directory — connector JSONs + registration script)
- `pte-api/services/{admin,authoring,exam-delivery,iam,proctor,reporting,scheduling,scoring}/pom.xml` (edit — confirm `spring-boot-starter-amqp` present, added in Phases 2–7 already; verify, don't re-add)
- `pte-api/services/{scoring,scheduling,reporting,notification,iam,exam-delivery}/pom.xml` (edit — remove `spring-kafka` dependency)
- `pte-api/services/{scoring,scheduling,reporting,notification,iam,exam-delivery}/src/main/resources/application.yml` (edit — remove any remaining Kafka bootstrap-servers/consumer config)

## Steps

1. Confirm (build-gate, not assumption) that every service builds and its test suite passes with RabbitMQ as the only broker before touching any infra file — re-run the full reactor build first.
2. Remove `kafka`, `schema-registry`, `debezium-connect`, `debezium-connectors-setup` service definitions from `docker-compose.yml`; leave `rabbitmq`, `postgres`, `redis`, `minio`, `mailpit`, `jaeger` untouched.
3. Delete `pte-api/docker/debezium/` entirely (connector JSONs, registration script).
4. Revisit `wal_level=logical` on the Postgres service definition — remove only if confirmed nothing else depends on logical replication, otherwise leave as a documented no-op.
5. Remove `spring-kafka` from the 6 services that had it (`scoring`, `scheduling`, `reporting`, `notification`, `iam`, `exam-delivery`); confirm each of the 8 outbox-producing services has `spring-boot-starter-amqp` present (already added per-service in Phases 2–7 — this step verifies, not re-does).
6. Sweep each affected `application.yml` for now-dead Kafka config (`bootstrap-servers`, consumer group settings) and remove it.
7. Full reactor build + `docker compose config` validation + `docker compose up -d` smoke test — bring up the trimmed stack and confirm every service starts cleanly with no Kafka/Debezium container present at all.

## Success Criteria

- `docker compose config` is valid with `kafka`, `schema-registry`, `debezium-connect`, `debezium-connectors-setup` entirely absent.
- `docker compose up -d` brings up a stack with no Kafka/Debezium/Schema-Registry container, and every service starts cleanly against it.
- No service's `pom.xml` references `spring-kafka`; all 8 producing services reference `spring-boot-starter-amqp`.
- No `application.yml` references a Kafka bootstrap-servers property anywhere in the reactor.
- Full reactor build (`mvn install`) is green with Kafka fully absent from the local environment (not just from the code — actually absent from the running stack this build/test run targets).

## Testing

Normal testing expectations, not TDD-first, not skipped:

- Full reactor build + full existing test suite across all services, run against the trimmed `docker-compose.yml` stack (no Kafka container present) — this is the definitive regression check that nothing silently still depended on Kafka.
- A smoke-test pass through the platform's core flows (tenant onboarding, question authoring, session scheduling, an exam attempt submit → score → publish, a proctor command, a notification email) run once end to end against the Kafka-free stack.
- `docker compose config` validated as part of CI/build if such a check exists in this repo's build pipeline; otherwise run manually and record the result.

## Risks

- HIGH: This is the point of no return for Kafka/Debezium — if any service was missed in Phases 2–8 verification, removing the broker breaks it with no fallback. Mitigation: Step 1's build-gate re-run before touching any infra file is mandatory, not optional; do not proceeed on assumption that "Phases 2–8 were fine."
- LOW: `wal_level=logical` removal is a Postgres restart-required change — mitigation: leave it set if there's any doubt, it costs nothing to keep.
- LOW: Schema Registry removal has zero functional risk (already unused/YAGNI under Kafka too) — pure cleanup.
