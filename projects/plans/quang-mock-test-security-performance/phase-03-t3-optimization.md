# Phase 3 (Track 3): Performance Optimization to Target

**Track:** 3 — Performance & Scalability
**Covers:** FR-07 (optimization half) · User story: P1 (500 concurrent, p95 < 1s)
**Depends on:** Phase 2 (load-test baseline results — this phase fixes what Phase 2 found, it does not speculate).

---

## Design Constraints

- Optimize based on **measured** bottlenecks from Phase 2, not speculative tuning. If Phase 2 showed no bottleneck at 500 concurrent, this phase's scope shrinks to confirming the target is already met and documenting margin.
- Common likely culprits given the stack (address only if Phase 2 confirms): N+1 queries in `examdelivery` repositories, missing indexes on hot-path queries (`exam_attempt` lookups by student/exam/status), Caffeine cache misconfiguration (TTL too short, wrong keys), HikariCP pool sizing.
- Any query/index change must not break the DB constraints added by Track 1 Phase 2 (`session_token`, unique active-attempt constraint) — coordinate if touching the same tables.

## Files to Touch

- `aptis-api/src/main/java/com/aptis/modules/examdelivery/repository/` — query optimization, add indexes via new Flyway migration if needed.
- `aptis-api/src/main/java/com/aptis/modules/examdelivery/service/` — caching adjustments (Caffeine config).
- `aptis-api/src/main/resources/application.yml` — HikariCP pool sizing if Phase 2 showed pool exhaustion.

## Implementation Steps

1. Take the specific bottlenecks documented in Phase 2 and address each one individually (don't batch unrelated changes).
2. For query issues: add missing indexes (new Flyway migration), fix N+1 patterns (batch fetch / join fetch).
3. For cache issues: tune Caffeine TTL/size, verify cache keys are correct for the hot paths.
4. For connection pool issues: right-size HikariCP based on observed concurrency, not a guess.
5. Re-run the Phase 2 Gatling suite (both cold and warm) after each significant change to confirm improvement, not just once at the end.

## Acceptance Criteria

- [ ] Re-run load test: 500 concurrent virtual users, p95 latency < 1s, 0 failed/lost submissions — matches spec success criterion exactly.
- [ ] Each fix traceable to a specific bottleneck identified in Phase 2 (no unexplained changes).

## Quality and Testing State

- Quality: not evaluated
- Testing: not started
