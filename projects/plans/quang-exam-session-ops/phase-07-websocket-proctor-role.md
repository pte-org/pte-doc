# Phase 7: WebSocket/STOMP Infrastructure & PROCTOR Role

## Requirements

Add `spring-boot-starter-websocket` dependency to aptis-api; implement STOMP frame authentication at CONNECT time using the existing JWT service; add a new PROCTOR role to IAM; implement per-room authorization on STOMP subscription so that a proctor assigned to session-room X can only subscribe to X's status stream; design a `ProctorStatusMessage` POJO for serialization; implement realtime status push via `/user/{sessionId}/queue/attempt-status` topic. Use Spring's in-memory `SimpleBroker` (not RabbitMQ/Redis — explicitly out-of-scope for >50 concurrent sessions scaling).

Maps to: **P1 Story #5, #6 (WebSocket) | FR-04, FR-06**

## Design Constraints

- Must use in-memory SimpleBroker only; no RabbitMQ/Redis/message broker relay (defer to a post-50-concurrent-sessions scaling effort).
- WebSocket session authentication must reuse the existing JWT (don't invent a separate session/cookie mechanism).
- Per-room authorization must be verified at STOMP subscription time (not just at message receive); a proctor assigned to room X cannot subscribe to room Y's topic.
- Do not rely on HttpSession for WebSocket state; store room assignment in WebSocketSession attributes at handshake.
- ProctorStatusMessage must be a plain serializable POJO (no framework dependencies) so a future broker swap doesn't require schema changes.
- **CRITICAL — deployment topology precondition**: SimpleBroker is in-memory and single-node; it silently breaks correctness (not just scale) if `aptis-api` runs on more than one instance without sticky-session routing to the same node per WebSocket connection — a proctor on instance A will never see updates from a student routed to instance B. This is a precondition to verify, not a future scaling concern.

## Steps

0. **Deployment topology — verified 2026-07-15**: `aptis-api` runs as a single instance (one `api` service in `docker-compose.yml`, no replicas/scale config, no Redis/RabbitMQ dependency, session state via in-memory Caffeine cache, no Kubernetes manifests or multi-instance CI/CD deployment). SimpleBroker is safe to use as designed. **If this topology changes later** (horizontal scaling introduced), this phase's SimpleBroker choice must be revisited before deploying multiple instances — either add sticky-session routing at the load balancer for WebSocket upgrades, or replace SimpleBroker with a broker relay (RabbitMQ/Redis); do not silently scale out without addressing this.

1. Add `spring-boot-starter-websocket` to aptis-api pom.xml.

2. Implement a `ChannelInterceptor.preSend()` handler that intercepts STOMP CONNECT frames, extracts the JWT from the CONNECT headers (e.g., Authorization header or custom header), validates it via the existing `JwtService`, and attaches the authenticated principal to the `MessageHeaders`; reject CONNECT with code 403 if JWT is invalid.

3. Create a WebSocket configuration class (annotated with `@Configuration`, implementing `WebSocketMessageBrokerConfigurer`) that:
   - Enables STOMP with a SimpleBroker
   - Registers message destinations (e.g., `/user/queue`, `/topic/rooms`)
   - Enables message-send-to-user functionality (so messages can be routed to specific user sessions)
   - Registers the `ChannelInterceptor` from step 2

4. Add PROCTOR role to the existing IAM role enum (add to `IamApiConstants.ROLE_PROCTOR = "PROCTOR"`).

5. Implement a `@PreAuthorize("hasAuthority('PROCTOR')")` check on a subscription endpoint or in a custom `ChannelInterceptor.postSend()` that validates the authenticated principal is assigned to the session/room in the subscription destination (e.g., if subscribing to `/user/{sessionId}/queue/attempt-status`, verify the proctor's `assignedSessionId` matches the path parameter).

6. Design a `ProctorStatusMessage` POJO with fields: attemptId, studentName, status (enum), currentSection, submittedAt, lastHeartbeatAt, notes; ensure it's serializable (Jackson-compatible).

7. Implement a service method that, when `ExamAttempt` status changes (Phase 6), looks up the assigned proctor for that session and pushes a `ProctorStatusMessage` to the proctor's `/user/{sessionId}/queue/attempt-status` destination via Spring's `SimpMessagingTemplate`.

8. Implement a logout handler that forcibly closes all active WebSocket connections for the authenticated user (via `SimpMessagingTemplate` or a `SessionDisconnectEvent`-driven cleanup), so a stale connection cannot keep receiving proctor messages after HTTP logout.

9. Test end-to-end: create a proctor user, assign to a session, connect via WebSocket with JWT, subscribe to the session's status topic, start a student exam attempt, verify the proctor receives a status message within 1 second; additionally test logout closes the WebSocket connection and a subsequent message attempt on it is rejected.

## Success Criteria

- STOMP CONNECT requires a valid JWT (invalid JWT returns 403).
- Proctor can subscribe to their assigned session's topic; subscription to an unassigned session returns 403 Forbidden.
- Status change on a student attempt triggers a ProctorStatusMessage push to the assigned proctor's queue.
- Message contains all required fields (attemptId, status, etc.) and is received within 5 seconds of the status change (latency goal from spec).
- Proctor is uniquely identified in the system with a PROCTOR role that cannot perform other user actions.

## Quality and Testing State

- Quality gate: **approved** (report: `quality/phase-07-websocket-proctor-role-quality-report.json`, receipt issued 2026-07-16). Two findings fixed before approval: deprecated `org.springframework.lang.NonNull` → `org.jspecify.annotations.NonNull`; WebSocket session registry now also cleans up via `SessionDisconnectEvent` (not just STOMP DISCONNECT frames) to close a leak risk on abrupt disconnects.
- Testing: **passed** — 141/142 in the full suite (1 pre-existing, unrelated skip). New coverage: `StompAuthChannelInterceptorTest` (15 — CONNECT auth, SUBSCRIBE room authorization including the required "unassigned session → rejected" case, revoked-session rejection, DISCONNECT cleanup), `ProctorWebSocketSessionRegistryTest` (12), `ProctorStatusPushServiceTest` (9), `ExamServiceTest` (17 — assignProctor cross-tenant rejection, unassignProctor, isStartable). Report: `tests/phase-07-websocket-proctor-role-test-report.json`.

## Session Notes

- **Scope note**: "PROCTOR role" required building a full account layer (Proctor entity, Host-scoped creation via `POST /v1/host/proctors`, login/refresh/profile wiring in AuthService) that wasn't explicitly itemized in this phase's Steps but is a hard prerequisite — mirrors the existing Grader entity/creation pattern (auto-generated password, BCrypt hash) but scoped to a Host's own organization (like Student), since proctors are hired/managed by the school, not centrally by Admin.
- **Proctor↔Exam assignment**: `Exam.proctorId` (nullable Long) — one proctor per exam at a time, matching the "1 proctor : 1 room" decision from planning. `ExamService.isStartable` (Phase 4 stub) now checks real assignment instead of the hardcoded `false`. Cross-tenant assignment is rejected (`ProctorRepository.findByIdAndOrganizationId`).
- **Module cycle avoided**: `examdelivery` now calls into the new `proctor` module (to push realtime status) and `proctor` calls into `iam`/`examoperations` — a naive proctor-logout hook would have created an iam↔proctor cycle, so `AuthService.logout()` publishes a neutral `UserLoggedOutEvent` (in `common`) instead of depending on `proctor` directly; a `ProctorLogoutListener` in the `proctor` module reacts to it.
- STOMP destination convention `/user/{examId}/queue/attempt-status` deliberately embeds the exam ID in the per-user sub-destination (not Spring's typical generic `/queue/foo` shape) specifically so subscription-time room authorization is literally testable per the phase's Design Constraint wording.
- Removed a dead, pre-existing Spring Initializr test stub's ability to silently break `./mvnw test`: `AptisApiApplicationTests` (dated before this plan, inert until Phase 6 added test infra) now fails to load the full context (needs real DB/JWT/Cloudinary credentials) — disabled at class level with a documented reason rather than deleted, since deleting a failing test outright isn't appropriate; a Testcontainers-backed Postgres test profile is tracked as future work.
- Build Gate: PASS.

## Risks

- **Authorization leakage across rooms**: If the subscription authorization check is not correctly scoped to the sessionId path parameter, a malicious proctor with a valid JWT could subscribe to another room's topics. Mitigation: implement `@PreAuthorize` check with explicit sessionId comparison from the subscription destination; write a unit test that attempts to subscribe to an unassigned session and verify it's rejected.
- **STOMP message ordering guarantees**: If multiple status updates occur in rapid succession (e.g., SECTION_SWITCH then SUBMITTED), messages might be delivered out-of-order or duplicated if the SimpleBroker is overwhelmed. Mitigation: include a sequence number or timestamp in `ProctorStatusMessage`; proctor dashboard should order messages by timestamp client-side; in-memory SimpleBroker guarantees in-order delivery per destination only within a single-node deployment (see Step 0 topology precondition) — this is a temporary mitigation until a broker swap at scale.
- **WebSocket session lifecycle mismatch with HTTP**: If a proctor WebSocket session persists after HTTP session logout, the proctor could receive messages indefinitely. Mitigation: implement a logout endpoint that forcibly closes all WebSocket connections for that user (via `SimpMessagingTemplate` or a `SessionDisconnectEvent` listener), added as an explicit step in this phase, not deferred; add an end-to-end test asserting a stale WebSocket connection is rejected after logout.
- **Proctor action idempotency** (applies to Phase 8, called out here since it touches the same push channel): repeated identical proctor actions (e.g. double-clicking force-submit) must not be treated as new state transitions — Phase 8 implements this via a status check before mutating.
