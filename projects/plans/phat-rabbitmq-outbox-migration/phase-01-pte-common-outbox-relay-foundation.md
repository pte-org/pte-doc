# Phase 1: pte-common Outbox Relay Foundation

## Requirements

Every later phase needs to add "a scheduled job that publishes this service's unpublished outbox rows to RabbitMQ" in a few lines, not by hand-rolling the SKIP LOCKED query and publisher-confirm handshake per service. This phase builds that reusable foundation in `pte-common`: publish-state tracking on the outbox row itself, a generic repository exposing the SKIP LOCKED batch query, an abstract relay template method, and a separate cleanup job — no service is touched yet.

## Design Constraints

- `pte-common` stays thin (infra plumbing only, per its own POM description) — no business logic, no service-specific routing/exchange knowledge in these base classes; that lives in each service's concrete subclass (Phase 2+).
- New Spring AMQP dependency in `pte-common` follows the existing `provided`-scope pattern already used for `spring-boot-starter-data-jpa`/`webmvc`/`oauth2-resource-server` — the library declares the API surface it compiles against, each service's own POM pulls the real runtime dependency.
- Do NOT introduce ShedLock for the relay. `SELECT ... FOR UPDATE SKIP LOCKED` already gives correct per-row mutual exclusion across multiple instances of the same service; ShedLock would incorrectly serialize the entire poll method to a single instance, defeating horizontal scaling of the relay. Document this explicitly in a Javadoc note on `AbstractOutboxRelay`, since the team has used ShedLock elsewhere and may reach for it here out of habit.
- Publish-then-flip must be committed **per row, not per batch**: the poll method fetches a batch, but each row's publish+flip runs in its own `REQUIRES_NEW` transaction (a separate Spring-managed bean method, called through the proxy — never self-invoked via `this`, which silently bypasses `@Transactional`). One row's `waitForConfirmsOrDie` failure rolls back only that row's transaction; every already-confirmed sibling in the batch stays committed. Without this, a single bad row in a 100-row batch would roll back the whole batch — undoing every already-broker-confirmed publish in it and amplifying duplicate delivery far beyond normal at-least-once (plan-reviewer finding, ACCEPTED).
- `publishAttempts`/`lastError` must be persisted in that same per-row `REQUIRES_NEW` transaction, specifically in the `catch` branch before re-throwing (or instead of re-throwing, if the row is quarantined — see below) — never left inside a transaction that's about to roll back, or the counter never survives the failure it's meant to record.
- Cap retries: once `publishAttempts` reaches a configurable threshold (`pte.outbox.max-publish-attempts`, default e.g. 10), flip the row to a quarantined state (`published` stays `false`, but excluded from the SKIP LOCKED batch query, e.g. via a `quarantined boolean` column or `publishAttempts < :max` in the WHERE clause) instead of retrying forever. A quarantined row must not silently vanish from view — log at ERROR with the row id/eventType, and it's still visible via a normal SQL query against the outbox table for operator investigation. This closes the "poisoned row permanently stalls the whole outbox pipeline with no visible signal" failure mode (plan-reviewer finding, ACCEPTED).

## Files to touch

- `pte-api/pte-common/src/main/java/com/pte/common/messaging/AbstractOutboxEntry.java` (edit — add columns)
- `pte-api/pte-common/src/main/java/com/pte/common/messaging/OutboxJpaRepository.java` (new)
- `pte-api/pte-common/src/main/java/com/pte/common/messaging/AbstractOutboxRelay.java` (new)
- `pte-api/pte-common/src/main/java/com/pte/common/messaging/AbstractOutboxCleanupJob.java` (new)
- `pte-api/pte-common/pom.xml` (edit — add `spring-boot-starter-amqp`, `provided` scope)

## Steps

1. Extend `AbstractOutboxEntry` with `published` (boolean, default false), `publishedAt` (nullable `Instant`), `publishAttempts` (int, default 0), `lastError` (nullable `String`), `quarantined` (boolean, default false) — additive only, existing columns/behavior unchanged.
2. Add `spring-boot-starter-amqp` to `pte-common/pom.xml` at `provided` scope, matching the existing pattern for JPA/web/oauth2 dependencies.
3. Build `OutboxJpaRepository<T extends AbstractOutboxEntry>`: a `#{#entityName}`-based JPQL query selecting the oldest unpublished, non-quarantined batch (`WHERE published = false AND quarantined = false AND publishAttempts < :maxAttempts`), `@Lock(PESSIMISTIC_WRITE)` + `@QueryHint(name = "jakarta.persistence.lock.timeout", value = "-2")` (Hibernate 6's SKIP LOCKED trigger), `Pageable` for batch size — generic enough that each service's own `OutboxRepository` becomes a one-line `extends OutboxJpaRepository<OutboxEntry>`.
4. Build `AbstractOutboxRelay<T>`: `@Scheduled(fixedDelayString = "${pte.outbox.poll-interval-ms:2000}")`, non-transactional poll method that fetches a batch via the repository, then for EACH row calls a separate proxied bean method `processRow(T entry)` annotated `@Transactional(propagation = REQUIRES_NEW)` — inside that per-row transaction: call an abstract `publish(T entry)` hook (service supplies exchange/routing-key mapping), synchronously wait for the broker confirm, flip `published`/`publishedAt`. On a per-row publish failure: increment `publishAttempts`, set `lastError`, and if `publishAttempts` has now reached `pte.outbox.max-publish-attempts` (default 10), set `quarantined = true` — commit this failure state in the same `REQUIRES_NEW` transaction (do not let it roll back), then stop processing (no re-throw) so the batch loop continues to the next row unaffected.
5. Build `AbstractOutboxCleanupJob<T>`: a separate `@Scheduled` daily job doing a batched `DELETE ... WHERE published = true AND published_at < now() - interval '7 days'`, deliberately isolated from the hot poll transaction so cleanup never blocks or is blocked by publishing.
6. Add the ShedLock-avoidance Javadoc note on `AbstractOutboxRelay` (Design Constraints above) and document `pte.outbox.poll-interval-ms`/`pte.outbox.batch-size` as the two config knobs every subclass inherits, with defaults (2000–5000ms / ~100) baked into the abstract classes so a service only needs an `application.yml` override, never new code, to tune them.
7. Build `pte-common` in isolation (`mvn -pl pte-common -am install`) to confirm the new abstract/generic classes compile cleanly against the provided-scope JPA/AMQP dependencies with no concrete subclass yet in the reactor.

## Success Criteria

- `pte-common` builds green in isolation and as part of the full reactor.
- `OutboxJpaRepository`'s generated SQL (checked via Hibernate SQL logging in a throwaway test entity, or deferred and re-verified at first real use in Phase 3) shows a `for update skip locked` clause.
- `AbstractOutboxRelay` carries the ShedLock-avoidance Javadoc; `pte.outbox.poll-interval-ms`, `pte.outbox.batch-size`, and `pte.outbox.max-publish-attempts` are documented with defaults, no magic numbers duplicated elsewhere.
- A single failing row in a batch does not roll back or block already-confirmed siblings, and does not stall the pipeline once quarantined — verify via the per-row `REQUIRES_NEW` transaction boundary, exercised concretely in Phase 3's integration test (this phase's classes have no concrete entity yet to test against directly).
- No behavior change to any existing service — `AbstractOutboxWriter` and every current `OutboxEntry extends AbstractOutboxEntry` still compile unchanged (additive columns only).

## Testing

Normal testing expectations, not TDD-first, not skipped:

- Unit test `AbstractOutboxCleanupJob`'s date-cutoff logic in isolation (no broker/DB needed — verify the query/predicate boundary, e.g. via a lightweight in-memory or mocked repository).
- Full relay-loop behavior (SKIP LOCKED under concurrent pollers, publisher-confirm round-trip, transactional flip) cannot be meaningfully exercised without a concrete entity, a real Postgres, and a real RabbitMQ — defer that integration test to Phase 3 (iam), the first service to wire a concrete `AbstractOutboxRelay` subclass, and treat it as this phase's acceptance gate by proxy.
- `mvn -pl pte-common -am install` must pass as the phase's build gate.

## Risks

- MEDIUM: Hibernate 6's SKIP LOCKED trigger via `lock.timeout = -2` is a lesser-known mechanism, not `SELECT ... FOR UPDATE SKIP LOCKED` written literally. Mitigation: verify the generated SQL log explicitly before trusting it in Phase 3, don't assume from the Hibernate docs alone.
- LOW: Generic `#{#entityName}` SpEL query behavior is dialect-sensitive in principle. Mitigation: this stack is Postgres-only end to end, so cross-dialect risk doesn't apply in practice.
- LOW: `publish(T entry)` must send only `entry.getPayload()` to the broker, never the entity itself — `lastError`/`publishAttempts` are internal bookkeeping and must never leak into a message body a consumer receives. Confirm this explicitly when implementing `publish()` in Phase 2+ (plan-reviewer finding, NOTED).
