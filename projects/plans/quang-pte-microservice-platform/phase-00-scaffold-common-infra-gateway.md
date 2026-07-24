# Phase 0: Mono-repo Scaffold + pte-common + Infra + Gateway

## Requirements

Stand up the mono-repo skeleton every later phase builds on: Maven multi-module aggregator, the thin `pte-common` shared library, local infrastructure (Postgres, Kafka, Redis, RabbitMQ, Debezium) via docker-compose, and the Spring Cloud Gateway edge with JWT validation + per-tenant rate-limit. No business domain yet — this phase proves the skeleton compiles, runs, and routes.

## Design Constraints

- Mono-repo `pte-api/` with parent `pom.xml` aggregating modules: `pte-common`, `gateway` (this phase); other service modules added in their phases.
- `pte-common` is thin (coding standard §4): `ApiResponse<T>`, base `DomainException`, base `GlobalExceptionHandler`, JWT resource-server filter + `CurrentUser`, correlation-id/OpenTelemetry filter, `BaseEntity` (Long id, UUID publicId, audit, soft-delete), event envelope base. **No business entity, no service logic.**
- Gateway = Spring Cloud Gateway, route+filter only, no DB, no domain layers (coding standard §6).
- Secrets via env (`${VAR}`), never in `application.yml`.
- Java 21 / Spring Boot 4.1, matching existing `pte-api/pom.xml`.

## Steps

1. Create parent `pom.xml` (packaging `pom`) aggregating `pte-common` and `gateway`. Pin Spring Boot 4.1, Spring Cloud, Java version. Reuse existing `pte-api` maven wrapper.
2. Build `pte-common`:
   - `ApiResponse<T>` (success/error factory), `DomainException` base + `GlobalExceptionHandler` (`@ControllerAdvice`) mapping to `ApiResponse.error` + correct HTTP status.
   - `BaseEntity` (`@MappedSuperclass`): `Long id`, `UUID publicId`, `createdAt/updatedAt`, `boolean deleted`.
   - `JwtAuthenticationFilter` (resource-server: validate via JWKS URL, populate `CurrentUser{userId, tenantId, roles}`), `CurrentUser` holder.
   - `CorrelationIdFilter` + OpenTelemetry baggage propagation (traceId/attemptId).
   - `EventEnvelope` base (eventId, type, occurredAt, tenantId, traceId) + JSON/Avro serialization helper.
3. Write `docker-compose.yml` at repo root: Postgres (single instance, one DB per service created via init script), Kafka + Zookeeper/KRaft, Redis, RabbitMQ (mgmt UI), Debezium Connect, Schema Registry.
4. Build `gateway` (Spring Cloud Gateway): routes to service ports (placeholders), `JwtValidationFilter` at edge (reject unauthenticated), Redis-backed per-tenant `RequestRateLimiter` (key = tenantId claim), correlation-id forwarding.
5. Add per-service Postgres bootstrap: init SQL creating databases `iam, admin, authoring, scheduling, exam_delivery, proctor, scoring, reporting, notification, media` each with its own role/credential.
6. CI skeleton: one pipeline, per-module build + test stages.

## Success Criteria

- `./mvnw -pl pte-common,gateway -am package` builds green.
- `docker-compose up` brings Postgres (10 DBs), Kafka, Redis, RabbitMQ, Debezium, Schema Registry healthy.
- Gateway boots, rejects an unauthenticated request (401), forwards correlation-id, applies rate-limit when a tenantId exceeds the bucket.
- `pte-common` has zero business-domain classes (checklist §7 verified).

## Quality and Testing State

- Quality gate: not evaluated.
- Testing: not started. (Unit: ApiResponse/GlobalExceptionHandler/JWT filter; integration: gateway 401 + rate-limit via Testcontainers Redis.)

## Risks

- **MEDIUM: Debezium/Kafka local setup friction.** *Mitigation:* pin known-good image versions; document ports; health-check gates in compose.
- **LOW: pte-common scope creep.** *Mitigation:* checklist §7 enforced in review — any business type is a reject.
