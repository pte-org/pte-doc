# Phase 2 (Track 3): Load Testing — Baseline

**Track:** 3 — Performance & Scalability
**Covers:** FR-07 (baseline half) · User story: P1 (500 concurrent)
**Depends on:** Phase 1 (rate limiting must be in place and its thresholds accounted for in test design, or explicitly bypassed for load-test service accounts).

---

## Design Constraints

- Establish the **real baseline first** — 100-500 concurrent is a user estimate, not a measured number. Don't jump to optimization (Phase 3) before this phase produces actual data.
- Run **both** a cold-cache and warm-cache pass — Caffeine cache can mask real query performance; a cold-start test reveals the true worst case (e.g. right when a scheduled exam session opens and many students hit the API simultaneously for the first time).
- Load-test scenarios must exercise the real exam-delivery path: fetch question → submit answer (repeated) → submit exam, not just a single hot endpoint in isolation.
- Load-test traffic must not be blocked by Phase 1's rate limiter — use a documented service-account exemption or a sanctioned higher threshold for the test tenant, not a global rate-limiter bypass that could mask production behavior.

## Files to Touch

- New `aptis-api/load-tests/` (or equivalent) — Gatling simulation scripts.
- `aptis-api/src/main/resources/application.yml` — confirm/add a load-test profile if DB connection pool or other settings need test-specific tuning to observe real capacity (document any deviation from production config clearly).

## Implementation Steps

1. Set up Gatling (JVM-native, fits the Spring Boot stack) with a simulation modeling the real exam flow: fetch-question → submit-answer (looped per question) → submit-exam.
2. Run a cold-cache pass: restart the API / clear Caffeine before the run, ramp to 500 concurrent virtual users, record p95 latency and failure/lost-submission count.
3. Run a warm-cache pass: same scenario after cache is populated, compare against cold-cache numbers.
4. Monitor DB connection pool (HikariCP) saturation and JVM GC behavior during both runs.
5. Document results (p95 latency per endpoint, failure rate, bottleneck observations) — this becomes the input to Phase 3.

## Acceptance Criteria

- [ ] Load test executed at 500 concurrent virtual users, both cold and warm cache, with documented results.
- [ ] Zero-loss verification: `SELECT COUNT(*)` on submitted attempts matches the expected count from the test run.
- [ ] Baseline bottlenecks (if any) documented for Phase 3 to address.

## Quality and Testing State

- Quality: not evaluated
- Testing: not started
