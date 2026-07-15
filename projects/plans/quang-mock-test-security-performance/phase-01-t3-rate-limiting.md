# Phase 1 (Track 3): Rate Limiting

**Track:** 3 — Performance & Scalability
**Covers:** FR-08 · User story: P2 (rate limiting)
**Depends on:** nothing — can start immediately
**Status: DEFERRED to Week 2+ backlog** — per user-confirmed 1-week timeline, this P2 phase is cut from week 1 so the Track 3 owner can focus on the P1 load-test baseline (phase-02-t3-load-testing.md). Pick this up once Week 1's P1 scope ships.

---

## Design Constraints

- Rate limit **per-student** on exam-delivery endpoints, not just per-IP — a shared school/testing-center network (many students, one IP) must not get globally throttled by one aggressive client.
- Auth endpoints get stricter, separate limits (per-IP is acceptable there — login abuse is the concern, not legitimate shared-network load).
- Excess requests return 429 with a `Retry-After` header, not a silent drop or generic 500.
- Use Resilience4j (`resilience4j-spring-boot3`) — already the natural fit for this Spring Boot 4.1 stack, no need to introduce a separate API gateway for this phase (that's a future infra concern, not in scope here).

## Files to Touch

- `aptis-api/pom.xml` (or build.gradle) — add `resilience4j-spring-boot3` dependency if not present.
- `aptis-api/src/main/resources/application.yml` — rate limiter configuration (per-endpoint instances).
- `aptis-api/src/main/java/com/aptis/modules/examdelivery/controller/ExamAttemptController.java` — `@RateLimiter` annotations on submit-answer/submit-exam/fetch-question endpoints.
- `aptis-api/src/main/java/com/aptis/modules/iam/controller/` (auth controller) — `@RateLimiter` on login endpoint.
- `aptis-api/src/main/java/com/aptis/common/exception/GlobalExceptionHandler.java` — map `RequestNotPermitted` (Resilience4j) to 429 with `Retry-After`.

## Implementation Steps

1. Add Resilience4j dependency and configure rate limiter instances in `application.yml` — one for exam-delivery (per-student key resolver), one for auth (per-IP key resolver).
2. Implement a custom key resolver for the exam-delivery limiter using the authenticated student ID (from JWT), not the raw IP.
3. Annotate exam-delivery and auth endpoints with `@RateLimiter(name = "...")`.
4. Map `RequestNotPermitted` to a 429 response with `Retry-After` header in `GlobalExceptionHandler`.
5. Tests: exceeding the configured threshold returns 429; requests from different students on the same IP are not cross-throttled.

## Acceptance Criteria

- [ ] Rate limiter returns 429 on excess requests per documented threshold.
- [ ] Per-student limiting confirmed not to cross-throttle different students on a shared IP.
- [ ] Maps to spec success criterion: "Rate limiter returns 429 on excess requests per documented threshold."

## Quality and Testing State

- Quality: not evaluated
- Testing: not started
