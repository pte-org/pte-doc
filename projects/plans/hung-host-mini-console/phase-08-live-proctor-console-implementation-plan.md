# Authorized Live Proctor Console Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver an authorized live console where assigned `PROCTOR` users can monitor and control their sessions, same-tenant `HOST_ADMIN` users can monitor read-only, and `HOST_AUTHOR` users cannot subscribe.

**Architecture:** Keep the existing gateway route, STOMP controller, proctor session, outbox, and Kafka contracts. Add destination authorization at the proctor inbound-channel boundary, an assigned-session query in scheduling, a typed STOMP-only event envelope, and a standalone Flutter `live_proctor` feature with bounded reconnect and snapshot recovery.

**Tech Stack:** Java 21, Spring Boot WebMVC/WebSocket/Security/Data JPA, JUnit 5/Mockito, Flutter/Dart 3.11.5, BLoC/GetIt/Dio, and `stomp_dart_client: ^3.0.1` (Dart 3 and Windows supported).

## Global Constraints

- Work only on `hung/feat/host-mini-console`; do not push, merge, rebase, or switch branch.
- Resolve and commit the currently reviewed Phase-09 handoff diff before Phase-08 source work so phase evidence is not mixed.
- Follow TDD: add one focused failing test, observe the expected failure, implement the minimum behavior, and rerun the focused test.
- Backend authorization is authoritative; Flutter role checks only control presentation.
- `PROCTOR` controls only an assigned active session; `HOST_ADMIN` is same-tenant read-only; `HOST_AUTHOR` has no live access.
- Keep the existing `/api/proctor/ws` gateway route and `/topic/proctor-sessions/{sessionPublicId}` topic.
- Reject client `SEND` frames to broker destinations; commands must use `/app/**`.
- Do not change IAM, database schemas, Kafka topics, or outbox event payloads.
- A STOMP `COMMAND_ACCEPTED` event means queued in the outbox, not applied by exam-delivery.
- Reconnect delays are exactly 1, 2, 4, 8, and 15 seconds, then stable manual-retry failure.
- Every mutation is single-flight, confirmed, and never automatically retried.
- All new Flutter code follows feature-first `data/domain/presentation`, repository abstraction, GetIt module, sealed events, immutable states, shared strings/colors, disposal, mounted checks, and the 300-line file limit.
- Runtime absence is recorded as `IMPLEMENTED_AWAITING_RUNTIME_VERIFICATION`, never as a pass.

---

## File Map

### `pte-api/services/scheduling`

- Create `dto/response/AssignedProctorSessionResponse.java`: exact response projection.
- Create `service/ProctorAssignmentQueryService.java`: caller-scoped assignment query.
- Create `controller/MyProctorAssignmentController.java`: `GET /proctor-assignments/me`.
- Create `domain/exception/ProctorContextRequiredException.java`: service-level role/tenant denial.
- Modify `constant/SchedulingConstants.java`: stable `PROCTOR_CONTEXT_REQUIRED` code.
- Modify `repository/ProctorAssignmentRepository.java`: deterministic fetch-join query.
- Create `src/test/.../service/ProctorAssignmentQueryServiceTest.java`: identity, tenant, role, and ordering contract.

### `pte-api/services/proctor`

- Create `service/StompDestinationAuthorizationService.java`: subscribe/send policy.
- Create `domain/exception/StompSubscriptionForbiddenException.java` and `StompCommandForbiddenException.java`: stable denial codes.
- Modify `constant/ProctorConstants.java`: stable STOMP denial codes.
- Modify `config/StompAuthChannelInterceptor.java`: delegate `SUBSCRIBE` and `SEND` authorization.
- Modify `repository/ProctorSessionRepository.java`: exact active-session existence queries.
- Create `dto/response/LiveProctorEventResponse.java` and `domain/enums/LiveProctorEventType.java`: typed live envelope.
- Modify `service/ProctorCommandService.java` and `ViolationService.java`: publish typed live events.
- Modify `service/ProctorSessionService.java`: active ownership check by scheduling session.
- Create focused unit tests for authorization, envelope publication, and REST recovery scope.

### `pte-app/lib/features/live_proctor`

- Create `domain/live_proctor_types.dart`: assigned session, console capability, live event, violation snapshot, and command inputs.
- Create `domain/repositories/live_proctor_repository.dart`: REST and transport-independent contract.
- Create `data/models/live_proctor_models.dart`: strict JSON mapping.
- Create `data/transport/live_proctor_transport.dart`: package-independent interface.
- Create `data/transport/stomp_live_proctor_transport.dart`: `stomp_dart_client` adapter.
- Create `data/repositories/live_proctor_repository_impl.dart`: ApiClient/TokenStore/transport composition.
- Create `presentation/bloc/assigned_sessions_*`: proctor workspace states.
- Create `presentation/bloc/live_proctor_*`: connection, recovery, commands, and retry.
- Create `presentation/pages/proctor_workspace_page.dart`, `live_proctor_entry_page.dart`, and `live_proctor_page.dart`.
- Create `live_proctor_module.dart`: GetIt registration.
- Modify root auth routing, session detail navigation, strings, `main.dart`, and `pubspec.yaml`.

---

### Task 0: Clean Phase Boundary

**Files:**
- Review only: current Phase-09 changes in `pte-app` and `pte-doc`
- Verify: all three repository working trees

**Interfaces:**
- Consumes: approved Phase-09 source/evidence diff
- Produces: a clean Phase-08 starting point with Phase-09 recorded separately

- [ ] **Step 1: Re-run the Phase-09 handoff checks**

Run in `pte-app`:

```powershell
flutter analyze
flutter test --reporter compact
git diff --check
```

Expected: analysis clean, 295 or more tests pass, and `git diff --check` exits
zero.

- [ ] **Step 2: Present the exact Phase-09 status**

Run in each repository:

```powershell
git status --short
git diff --stat
```

Expected: only the previously reviewed Phase-09 architecture repair and
evidence are present; `pte-api` is clean.

- [ ] **Step 3: Commit only after Hung approves**

In `pte-app`, stage only:

```powershell
git add lib/features/host_audit/presentation/pages/notification_audit_page.dart lib/features/host_audit/presentation/pages/violation_audit_page.dart lib/features/host_console/presentation/pages/host_console_page.dart lib/features/scheduling/presentation/pages/session_detail_page.dart lib/features/scoring_review/presentation/pages/session_scoring_page.dart plans/hung-host-mini-console/quality/phase-09-qa-gate-quality-report.json plans/hung-host-mini-console/quality/phase-09-qa-gate-receipt.json
git commit -m "refactor(host): enforce feature-owned entry pages"
```

In `pte-doc`, stage only:

```powershell
git add projects/plans/hung-host-mini-console/phase-09-qa-gate.md projects/plans/hung-host-mini-console/plan.md projects/plans/hung-host-mini-console/quality/phase-09-qa-gate-quality-report.json projects/plans/hung-host-mini-console/tests/phase-09-qa-gate-test-report.json
git commit -m "docs(qa): record host console phase 09 gate"
```

Expected: app repair and canonical documentation are separate repository
commits; all three working trees are clean before Task 1.

---

### Task 1: Assigned Proctor Session Query

**Files:**
- Create: `pte-api/services/scheduling/src/main/java/com/pte/scheduling/dto/response/AssignedProctorSessionResponse.java`
- Create: `pte-api/services/scheduling/src/main/java/com/pte/scheduling/service/ProctorAssignmentQueryService.java`
- Create: `pte-api/services/scheduling/src/main/java/com/pte/scheduling/controller/MyProctorAssignmentController.java`
- Create: `pte-api/services/scheduling/src/main/java/com/pte/scheduling/domain/exception/ProctorContextRequiredException.java`
- Modify: `pte-api/services/scheduling/src/main/java/com/pte/scheduling/repository/ProctorAssignmentRepository.java`
- Modify: `pte-api/services/scheduling/src/main/java/com/pte/scheduling/constant/SchedulingConstants.java`
- Test: `pte-api/services/scheduling/src/test/java/com/pte/scheduling/service/ProctorAssignmentQueryServiceTest.java`

**Interfaces:**
- Consumes: `CurrentUser(UUID userId, UUID tenantId, List<String> roles)` and existing `ProctorAssignment`
- Produces: `List<AssignedProctorSessionResponse> listMine(CurrentUser caller)` and `GET /api/scheduling/proctor-assignments/me`

- [ ] **Step 1: Write failing service tests**

Cover these exact assertions:

```java
assertEquals(proctorId, capturedProctorId.getValue());
assertEquals(tenantId, capturedTenantId.getValue());
assertEquals(List.of(firstSessionResponse, secondSessionResponse), result);
assertThrows(ProctorContextRequiredException.class,
        () -> service.listMine(new CurrentUser(userId, tenantId, List.of("HOST_ADMIN"))));
```

The fixture must intentionally contain another proctor and another tenant and
verify neither can be returned by the repository call.

- [ ] **Step 2: Verify the focused test fails**

Run:

```powershell
.\mvnw.cmd -pl services/scheduling -am -Dtest=ProctorAssignmentQueryServiceTest -Dsurefire.failIfNoSpecifiedTests=false test
```

Expected: FAIL because the query service and response record do not exist.

- [ ] **Step 3: Add the exact response and query**

Implement:

```java
public record AssignedProctorSessionResponse(
        UUID assignmentPublicId,
        UUID sessionPublicId,
        String name,
        Instant opensAt,
        Instant closesAt,
        String status) {
}
```

Add a repository `@Query` that fetches `assignment.session` and scopes by both
`proctorPublicId` and `tenantId`, ordered by `session.opensAt ASC` and
`session.publicId ASC`.

Implement `listMine` so it rejects null tenant or callers without `PROCTOR`,
passes only `caller.userId()` and `caller.tenantId()` to the repository, and
maps the six response fields without exposing tenant or another user ID.
`ProctorContextRequiredException` extends `DomainException` with
`HttpStatus.FORBIDDEN` and
`SchedulingConstants.PROCTOR_CONTEXT_REQUIRED`.

- [ ] **Step 4: Expose the caller-derived controller**

Implement:

```java
@RestController
@RequestMapping("/proctor-assignments")
@PreAuthorize("hasRole('PROCTOR')")
class MyProctorAssignmentController {
    @GetMapping("/me")
    ApiResponse<List<AssignedProctorSessionResponse>> listMine() {
        return ApiResponse.success(service.listMine(currentUser()));
    }
}
```

The method must accept no query parameter or request body.

- [ ] **Step 5: Run scheduling gates**

Run:

```powershell
.\mvnw.cmd -pl services/scheduling -am test
.\mvnw.cmd -pl services/scheduling -am package
```

Expected: the focused tests and package pass.

- [ ] **Step 6: Commit the scheduling slice**

```powershell
git add services/scheduling/src/main/java/com/pte/scheduling/dto/response/AssignedProctorSessionResponse.java services/scheduling/src/main/java/com/pte/scheduling/service/ProctorAssignmentQueryService.java services/scheduling/src/main/java/com/pte/scheduling/controller/MyProctorAssignmentController.java services/scheduling/src/main/java/com/pte/scheduling/domain/exception/ProctorContextRequiredException.java services/scheduling/src/main/java/com/pte/scheduling/repository/ProctorAssignmentRepository.java services/scheduling/src/main/java/com/pte/scheduling/constant/SchedulingConstants.java services/scheduling/src/test/java/com/pte/scheduling/service/ProctorAssignmentQueryServiceTest.java
git commit -m "feat(scheduling): expose assigned proctor sessions"
```

---

### Task 2: STOMP Destination Authorization

**Files:**
- Create: `pte-api/services/proctor/src/main/java/com/pte/proctor/service/StompDestinationAuthorizationService.java`
- Create: `pte-api/services/proctor/src/main/java/com/pte/proctor/domain/exception/StompSubscriptionForbiddenException.java`
- Create: `pte-api/services/proctor/src/main/java/com/pte/proctor/domain/exception/StompCommandForbiddenException.java`
- Modify: `pte-api/services/proctor/src/main/java/com/pte/proctor/config/StompAuthChannelInterceptor.java`
- Modify: `pte-api/services/proctor/src/main/java/com/pte/proctor/repository/ProctorSessionRepository.java`
- Modify: `pte-api/services/proctor/src/main/java/com/pte/proctor/constant/ProctorConstants.java`
- Test: `pte-api/services/proctor/src/test/java/com/pte/proctor/service/StompDestinationAuthorizationServiceTest.java`
- Test: `pte-api/services/proctor/src/test/java/com/pte/proctor/config/StompAuthChannelInterceptorTest.java`

**Interfaces:**
- Consumes: authenticated `StompPrincipal`, STOMP command, and destination
- Produces: `void authorizeSubscribe(CurrentUser caller, String destination)` and `void authorizeSend(CurrentUser caller, String destination)`

- [ ] **Step 1: Write the authorization matrix tests**

Create parameterized or individual tests proving:

```java
service.authorizeSubscribe(proctor, "/topic/proctor-sessions/" + sessionId);
service.authorizeSubscribe(hostAdmin, "/topic/proctor-sessions/" + sessionId);
assertThrows(StompSubscriptionForbiddenException.class,
        () -> service.authorizeSubscribe(hostAuthor, topic));
assertThrows(StompSubscriptionForbiddenException.class,
        () -> service.authorizeSubscribe(otherTenantAdmin, topic));
assertThrows(StompCommandForbiddenException.class,
        () -> service.authorizeSend(hostAdmin, "/app/proctor-sessions/" + proctorSessionId + "/commands"));
assertThrows(StompCommandForbiddenException.class,
        () -> service.authorizeSend(proctor, "/topic/proctor-sessions/" + sessionId));
```

Also cover malformed UUID, unknown destination, inactive session, and
unassigned proctor.

- [ ] **Step 2: Verify tests fail before implementation**

Run:

```powershell
.\mvnw.cmd -pl services/proctor -am -Dtest=StompDestinationAuthorizationServiceTest,StompAuthChannelInterceptorTest -Dsurefire.failIfNoSpecifiedTests=false test
```

Expected: FAIL because the authorization service and interceptor branches do
not exist.

- [ ] **Step 3: Add repository predicates and policy**

Add exact predicates:

```java
boolean existsBySessionPublicIdAndProctorPublicIdAndTenantIdAndStatus(
        UUID sessionPublicId, UUID proctorPublicId, UUID tenantId,
        ProctorSessionStatus status);

boolean existsBySessionPublicIdAndTenantIdAndStatus(
        UUID sessionPublicId, UUID tenantId, ProctorSessionStatus status);
```

Allow `/user/queue/proctor-session` and `/user/queue/errors` only for an
authenticated principal. For the session topic, use the first predicate for
`PROCTOR`, the second for `HOST_ADMIN`, and reject every other role.
Both denial exceptions extend Spring `MessagingException` and pass only their
respective stable constant (`STOMP_SUBSCRIPTION_FORBIDDEN` or
`STOMP_COMMAND_FORBIDDEN`) to `super`, ensuring the STOMP `ERROR` frame does not
leak session existence.

Allow `PROCTOR` sends only to:

```text
/app/sessions/{sessionPublicId}/open
/app/proctor-sessions/{proctorSessionPublicId}/commands
/app/proctor-sessions/{proctorSessionPublicId}/violations
```

The existing controller/service remains responsible for assignment ownership
and command validation. Reject all broker-destination sends and every Host send.

- [ ] **Step 4: Delegate from the interceptor**

Keep JWT decoding on `CONNECT`. On `SUBSCRIBE` and `SEND`, require an inherited
`StompPrincipal`, read `accessor.getDestination()`, and call the matching
authorization method. Do not duplicate repository logic inside the interceptor.

- [ ] **Step 5: Run proctor authorization tests and package**

```powershell
.\mvnw.cmd -pl services/proctor -am test
.\mvnw.cmd -pl services/proctor -am package
```

Expected: all authorization cases pass and the module packages.

- [ ] **Step 6: Commit the security boundary**

```powershell
git add services/proctor/src/main/java/com/pte/proctor/config/StompAuthChannelInterceptor.java services/proctor/src/main/java/com/pte/proctor/service/StompDestinationAuthorizationService.java services/proctor/src/main/java/com/pte/proctor/domain/exception/StompSubscriptionForbiddenException.java services/proctor/src/main/java/com/pte/proctor/domain/exception/StompCommandForbiddenException.java services/proctor/src/main/java/com/pte/proctor/constant/ProctorConstants.java services/proctor/src/main/java/com/pte/proctor/repository/ProctorSessionRepository.java services/proctor/src/test/java/com/pte/proctor/service/StompDestinationAuthorizationServiceTest.java services/proctor/src/test/java/com/pte/proctor/config/StompAuthChannelInterceptorTest.java
git commit -m "fix(proctor): authorize stomp destinations"
```

---

### Task 3: Typed Live Events and Recovery Scope

**Files:**
- Create: `pte-api/services/proctor/src/main/java/com/pte/proctor/domain/enums/LiveProctorEventType.java`
- Create: `pte-api/services/proctor/src/main/java/com/pte/proctor/dto/response/LiveProctorEventResponse.java`
- Modify: `pte-api/services/proctor/src/main/java/com/pte/proctor/service/ProctorCommandService.java`
- Modify: `pte-api/services/proctor/src/main/java/com/pte/proctor/service/ViolationService.java`
- Modify: `pte-api/services/proctor/src/main/java/com/pte/proctor/service/ProctorSessionService.java`
- Test: `pte-api/services/proctor/src/test/java/com/pte/proctor/service/LiveEventPublicationTest.java`
- Test: `pte-api/services/proctor/src/test/java/com/pte/proctor/service/ViolationRecoveryAuthorizationTest.java`

**Interfaces:**
- Produces: `LiveProctorEventResponse<T>(UUID eventId, LiveProctorEventType eventType, UUID sessionPublicId, Instant occurredAt, T data)`
- Preserves: existing `ProctorCommandPublished` and `ViolationDetectedEvent` outbox payloads

- [ ] **Step 1: Write failing message-capture tests**

Capture the second argument passed to `SimpMessagingTemplate.convertAndSend`
and assert:

```java
assertEquals(LiveProctorEventType.COMMAND_ACCEPTED, event.eventType());
assertEquals(sessionId, event.sessionPublicId());
assertEquals(request, event.data());
assertNotNull(event.eventId());
assertNotNull(event.occurredAt());
```

For violations, assert `eventId == ViolationEvent.publicId`,
`occurredAt == detectedAt`, and `data` is the mapped persisted response.
Separately capture the outbox writes and assert their existing domain-event
types and fields are unchanged.

- [ ] **Step 2: Verify publication tests fail**

```powershell
.\mvnw.cmd -pl services/proctor -am -Dtest=LiveEventPublicationTest,ViolationRecoveryAuthorizationTest -Dsurefire.failIfNoSpecifiedTests=false test
```

Expected: FAIL because raw payloads are still published.

- [ ] **Step 3: Add the live-only envelope**

Implement:

```java
public enum LiveProctorEventType {
    COMMAND_ACCEPTED,
    VIOLATION_DETECTED
}

public record LiveProctorEventResponse<T>(
        UUID eventId,
        LiveProctorEventType eventType,
        UUID sessionPublicId,
        Instant occurredAt,
        T data) {
}
```

Wrap only calls to `messagingTemplate.convertAndSend`. Do not alter either
outbox writer call.

- [ ] **Step 4: Restrict proctor snapshot recovery**

Add:

```java
ProctorSession findActiveOwnedBySession(
        UUID sessionPublicId, UUID proctorPublicId, UUID tenantId)
```

In `ViolationService.listForSession`, require this local active ownership for a
`PROCTOR`; retain tenant-scoped historical audit for `HOST_ADMIN` and
`HOST_AUTHOR`.

- [ ] **Step 5: Run all modified-backend gates**

```powershell
.\mvnw.cmd -pl services/scheduling,services/proctor -am test
.\mvnw.cmd -pl services/scheduling,services/proctor -am package
```

Expected: both services and dependencies pass.

- [ ] **Step 6: Commit the live contract**

```powershell
git add services/proctor/src/main/java/com/pte/proctor/domain/enums/LiveProctorEventType.java services/proctor/src/main/java/com/pte/proctor/dto/response/LiveProctorEventResponse.java services/proctor/src/main/java/com/pte/proctor/service/ProctorCommandService.java services/proctor/src/main/java/com/pte/proctor/service/ViolationService.java services/proctor/src/main/java/com/pte/proctor/service/ProctorSessionService.java services/proctor/src/test/java/com/pte/proctor/service/LiveEventPublicationTest.java services/proctor/src/test/java/com/pte/proctor/service/ViolationRecoveryAuthorizationTest.java
git commit -m "feat(proctor): publish typed live session events"
```

---

### Task 4: Flutter Domain and REST Contracts

**Files:**
- Modify: `pte-app/pubspec.yaml`
- Create: `pte-app/lib/features/live_proctor/domain/live_proctor_types.dart`
- Create: `pte-app/lib/features/live_proctor/domain/repositories/live_proctor_repository.dart`
- Create: `pte-app/lib/features/live_proctor/data/models/live_proctor_models.dart`
- Create: `pte-app/lib/features/live_proctor/data/repositories/live_proctor_repository_impl.dart`
- Test: `pte-app/test/unit/features/live_proctor/data/live_proctor_models_test.dart`
- Test: `pte-app/test/unit/features/live_proctor/data/live_proctor_repository_impl_test.dart`

**Interfaces:**
- Produces: `AssignedProctorSession`, `LiveProctorEvent`, `LiveViolation`, `LiveConsoleCapability`, `ProctorCommandInput`, `FlagViolationInput`
- Produces:

```dart
abstract interface class LiveProctorRepository {
  Stream<LiveProctorSignal> get signals;
  Future<List<AssignedProctorSession>> loadAssignedSessions();
  Future<List<LiveViolation>> loadViolationSnapshot(String sessionPublicId);
  Future<void> connect({
    required String sessionPublicId,
    required LiveConsoleCapability capability,
  });
  Future<String> openProctorSession(String sessionPublicId);
  Future<void> issueCommand(
    String proctorSessionPublicId,
    ProctorCommandInput input,
  );
  Future<void> flagViolation(
    String proctorSessionPublicId,
    FlagViolationInput input,
  );
  Future<void> disconnect();
}
```

`LiveProctorSignal` is a sealed domain family containing live event,
recoverable disconnect, authentication terminal, and authorization terminal
cases. No `stomp_dart_client` type crosses this interface.

- [ ] **Step 1: Add strict failing model tests**

Assert the assigned-session model requires all six backend fields and parses
timestamps strictly. Assert the live envelope switches only on
`COMMAND_ACCEPTED` and `VIOLATION_DETECTED`; an unknown type returns a typed
`LiveUnknownEvent` rather than throwing or closing the stream.

- [ ] **Step 2: Verify tests fail**

```powershell
flutter test test/unit/features/live_proctor/data/live_proctor_models_test.dart test/unit/features/live_proctor/data/live_proctor_repository_impl_test.dart
```

Expected: FAIL because the feature does not exist.

- [ ] **Step 3: Add the compatible STOMP dependency**

Add:

```yaml
stomp_dart_client: ^3.0.1
```

Run:

```powershell
flutter pub get
flutter build windows --debug
```

Expected: dependency resolution and Windows debug build pass. If the build
fails because of the package, stop this task and record the exact compatibility
failure; do not substitute a hand-written STOMP parser.

- [ ] **Step 4: Implement REST mapping**

Use exact paths:

```dart
await apiClient.get<List<dynamic>>(
  '/api/scheduling/proctor-assignments/me',
);
await apiClient.get<List<dynamic>>(
  '/api/proctor/exam-sessions/$sessionPublicId/violations',
);
```

Map into immutable domain values. Never accept a tenant or proctor override.

- [ ] **Step 5: Run focused tests and analysis**

```powershell
dart format lib/features/live_proctor test/unit/features/live_proctor
flutter test test/unit/features/live_proctor/data
flutter analyze
```

Expected: focused tests pass and analysis is clean.

- [ ] **Step 6: Commit the domain/data slice**

```powershell
git add pubspec.yaml pubspec.lock lib/features/live_proctor/domain lib/features/live_proctor/data/models lib/features/live_proctor/data/repositories test/unit/features/live_proctor/data
git commit -m "feat(proctor): add live console contracts"
```

---

### Task 5: STOMP Transport Adapter

**Files:**
- Create: `pte-app/lib/features/live_proctor/data/transport/live_proctor_transport.dart`
- Create: `pte-app/lib/features/live_proctor/data/transport/stomp_live_proctor_transport.dart`
- Modify: `pte-app/lib/features/live_proctor/data/repositories/live_proctor_repository_impl.dart`
- Test: `pte-app/test/unit/features/live_proctor/data/stomp_live_proctor_transport_test.dart`

**Interfaces:**
- Produces:

```dart
abstract interface class LiveProctorTransport {
  Stream<LiveTransportMessage> get messages;
  Future<void> connect({
    required String accessToken,
    required String sessionPublicId,
    required LiveConsoleCapability capability,
  });
  Future<String> openProctorSession(String sessionPublicId);
  void sendCommand(String proctorSessionPublicId, ProctorCommandInput input);
  void flagViolation(String proctorSessionPublicId, FlagViolationInput input);
  Future<void> disconnect();
}
```

- [ ] **Step 1: Write transport lifecycle tests with an injectable client factory**

Verify connect headers contain exactly
`Authorization: Bearer test-access-token`, Host
Admin subscribes only to the session topic and private error queue, Proctor
subscribes to private open/error queues before sending open, and disconnect
cancels every subscription and closes the controller once.

- [ ] **Step 2: Verify transport tests fail**

```powershell
flutter test test/unit/features/live_proctor/data/stomp_live_proctor_transport_test.dart
```

Expected: FAIL because the transport is absent.

- [ ] **Step 3: Implement the adapter without package types escaping**

Use gateway URL:

```text
ws://localhost:8080/api/proctor/ws
```

Configure `stompConnectHeaders` with the bearer token and disable package-level
automatic reconnect. Expose only project-owned `LiveTransportMessage` values.
Await the private open response before allowing Proctor command calls.

- [ ] **Step 4: Map terminal errors and make disconnect idempotent**

Emit an authentication-terminal message for STOMP authentication failure, an
authorization-terminal message for the two stable forbidden codes, and a
recoverable disconnect for network closure. Calling `disconnect` twice must not
throw or retain callbacks.

- [ ] **Step 5: Run transport and repository tests**

```powershell
flutter test test/unit/features/live_proctor/data
flutter analyze
```

Expected: all live-proctor data tests pass.

- [ ] **Step 6: Commit the transport**

```powershell
git add lib/features/live_proctor/data/transport lib/features/live_proctor/data/repositories/live_proctor_repository_impl.dart test/unit/features/live_proctor/data
git commit -m "feat(proctor): add authenticated stomp transport"
```

---

### Task 6: Live Proctor BLoCs and Recovery

**Files:**
- Create: `pte-app/lib/features/live_proctor/presentation/bloc/assigned_sessions_event.dart`
- Create: `pte-app/lib/features/live_proctor/presentation/bloc/assigned_sessions_state.dart`
- Create: `pte-app/lib/features/live_proctor/presentation/bloc/assigned_sessions_bloc.dart`
- Create: `pte-app/lib/features/live_proctor/presentation/bloc/live_proctor_event.dart`
- Create: `pte-app/lib/features/live_proctor/presentation/bloc/live_proctor_state.dart`
- Create: `pte-app/lib/features/live_proctor/presentation/bloc/live_proctor_bloc.dart`
- Test: `pte-app/test/unit/features/live_proctor/presentation/assigned_sessions_bloc_test.dart`
- Test: `pte-app/test/unit/features/live_proctor/presentation/live_proctor_bloc_test.dart`

**Interfaces:**
- Consumes: `LiveProctorRepository`, an injectable delay function, and transport messages
- Produces: disconnected, connecting, recovering, connected, reconnecting, command-in-flight, and failure states

- [ ] **Step 1: Write failing assigned-session BLoC tests**

Cover loading, ordered loaded data, empty, failure, and retry. Verify one load
event makes exactly one repository call.

- [ ] **Step 2: Write failing reconnect/recovery tests**

Inject a delay recorder and assert:

```dart
expect(recordedDelays, const [
  Duration(seconds: 1),
  Duration(seconds: 2),
  Duration(seconds: 4),
  Duration(seconds: 8),
  Duration(seconds: 15),
]);
```

Verify attempt six enters stable failure. Verify a manual retry restarts at one
second. Verify events received during snapshot load are buffered and merged by
`eventId`, with persisted violations ordered by `sequenceNo`.

- [ ] **Step 3: Verify BLoC tests fail**

```powershell
flutter test test/unit/features/live_proctor/presentation
```

Expected: FAIL because the BLoCs do not exist.

- [ ] **Step 4: Implement the minimal state machines**

Use sealed event classes and separate immutable state classes. Keep connection
status and command status explicit; do not represent them with unrelated
booleans. Unknown live events update diagnostics only and do not terminate the
connection.

- [ ] **Step 5: Add command safety tests and implementation**

Verify duplicate command/violation events are ignored while a mutation is in
flight, failures preserve the input, and no retry is scheduled for mutations.
Expose `COMMAND_ACCEPTED` as accepted/queued copy, never completed copy.

- [ ] **Step 6: Verify lifecycle cancellation**

Test that logout/dispose closes the message subscription, calls transport
disconnect once, cancels pending reconnect, and prevents later emissions.

- [ ] **Step 7: Run focused tests**

```powershell
dart format lib/features/live_proctor/presentation/bloc test/unit/features/live_proctor/presentation
flutter test test/unit/features/live_proctor/presentation
flutter analyze
```

Expected: all BLoC tests pass and analysis is clean.

- [ ] **Step 8: Commit the state layer**

```powershell
git add lib/features/live_proctor/presentation/bloc test/unit/features/live_proctor/presentation
git commit -m "feat(proctor): add live console state recovery"
```

---

### Task 7: Role-Aware Flutter Workspaces

**Files:**
- Create: `pte-app/lib/features/live_proctor/live_proctor_module.dart`
- Create: `pte-app/lib/features/live_proctor/presentation/pages/proctor_workspace_page.dart`
- Create: `pte-app/lib/features/live_proctor/presentation/pages/live_proctor_entry_page.dart`
- Create: `pte-app/lib/features/live_proctor/presentation/pages/live_proctor_page.dart`
- Modify: `pte-app/lib/app.dart`
- Modify: `pte-app/lib/main.dart`
- Modify: `pte-app/lib/features/host_console/domain/host_access_policy.dart`
- Modify: `pte-app/lib/features/scheduling/presentation/pages/session_detail_page.dart`
- Modify: `pte-app/lib/core/constants/app_strings.dart`
- Test: `pte-app/test/widget/app_auth_gate_test.dart`
- Test: `pte-app/test/widget/features/live_proctor/proctor_workspace_page_test.dart`
- Test: `pte-app/test/widget/features/live_proctor/live_proctor_page_test.dart`
- Test: `pte-app/test/widget/features/scheduling/session_pages_test.dart`

**Interfaces:**
- Consumes: feature-owned BLoC factories and `LiveConsoleCapability`
- Produces: Proctor root workspace, Host Admin read-only entry, and controller/read-only console variants

- [ ] **Step 1: Write failing auth/navigation tests**

Assert:

```dart
expect(find.byType(ProctorWorkspacePage), findsOneWidget);
expect(find.text(AppStrings.liveMonitoring), findsOneWidget); // HOST_ADMIN
expect(find.text(AppStrings.liveMonitoring), findsNothing);   // HOST_AUTHOR
```

Keep existing Host and student auth-gate expectations unchanged.

- [ ] **Step 2: Write failing capability widget tests**

In controller mode, assert `FORCE_SUBMIT`, `EXTEND_TIME`, and flag-violation
controls exist. In read-only mode, assert none exist. Both modes render
connection status, session identity, violation timeline, queued command event,
failure, and retry.

- [ ] **Step 3: Verify widget tests fail**

```powershell
flutter test test/widget/app_auth_gate_test.dart test/widget/features/live_proctor test/widget/features/scheduling/session_pages_test.dart
```

Expected: FAIL because routing/pages are absent.

- [ ] **Step 4: Register feature-owned entry composition**

`LiveProctorEntryPage` creates its own `LiveProctorBloc`. Scheduling imports
only this public page and passes `sessionPublicId` plus
`LiveConsoleCapability.readOnly`. Root auth routing uses a pure role predicate
to enter `ProctorWorkspacePage`; it does not construct transport objects.

- [ ] **Step 5: Implement confirmations and mounted/dispose safety**

Both commands require a dialog. `EXTEND_TIME` validates a positive integer.
After awaited dialogs/navigation, check `mounted`. Dispose every controller;
BLoC close owns transport and timer teardown.

- [ ] **Step 6: Run Flutter gates**

```powershell
dart format lib/features/live_proctor lib/app.dart lib/main.dart lib/features/host_console/domain/host_access_policy.dart lib/features/scheduling/presentation/pages/session_detail_page.dart lib/core/constants/app_strings.dart test/unit/features/live_proctor test/widget/features/live_proctor test/widget/app_auth_gate_test.dart test/widget/features/scheduling/session_pages_test.dart
flutter test test/unit/features/live_proctor test/widget/features/live_proctor test/widget/app_auth_gate_test.dart test/widget/features/scheduling/session_pages_test.dart
flutter analyze
flutter test --reporter compact
flutter build windows --debug
```

Expected: focused tests, full suite, analysis, and Windows build pass.

- [ ] **Step 7: Commit the UI slice**

```powershell
git add lib/features/live_proctor lib/app.dart lib/main.dart lib/features/host_console/domain/host_access_policy.dart lib/features/scheduling/presentation/pages/session_detail_page.dart lib/core/constants/app_strings.dart test/unit/features/live_proctor test/widget/features/live_proctor test/widget/app_auth_gate_test.dart test/widget/features/scheduling/session_pages_test.dart
git commit -m "feat(proctor): add role-aware live console"
```

---

### Task 8: Runtime Contract Gate

**Files:**
- Create: `pte-app/tool/live_proctor_runtime_probe.dart`
- Update evidence only after recording actual command output

**Interfaces:**
- Consumes: gateway, IAM, scheduling, proctor, PostgreSQL, Redis, Kafka, and authenticated role fixtures
- Produces: runtime proof or an exact blocked-state record

- [ ] **Step 1: Check stack availability**

```powershell
docker compose ps
```

Expected before runtime testing: gateway, IAM, scheduling, proctor, and their
infrastructure report healthy/running. If application services are absent from
compose, record that exact prerequisite and do not claim runtime success.

- [ ] **Step 2: Add a sanitized runtime probe**

The probe reads these process environment variables and throws before opening a
socket when any is absent:

```text
PTE_PROCTOR_TOKEN
PTE_HOST_ADMIN_TOKEN
PTE_HOST_AUTHOR_TOKEN
PTE_WRONG_TENANT_TOKEN
PTE_UNASSIGNED_PROCTOR_TOKEN
PTE_SESSION_PUBLIC_ID
PTE_ATTEMPT_PUBLIC_ID
```

It constructs the production STOMP adapter directly, executes the authorization
matrix, sends one violation from the assigned Proctor, disconnects/reconnects,
and prints one JSON object containing boolean outcomes, stable denial codes,
received event IDs, and snapshot IDs. It never prints or serializes tokens.

- [ ] **Step 3: Run the real authorization/event probe**

Set the seven environment values only in the current PowerShell process, then
run:

```powershell
dart run tool/live_proctor_runtime_probe.dart
```

Expected JSON assertions:

```json
{
  "assignedProctorSubscribed": true,
  "sameTenantHostAdminSubscribed": true,
  "hostAdminCommandDenied": "STOMP_COMMAND_FORBIDDEN",
  "hostAuthorDenied": "STOMP_SUBSCRIPTION_FORBIDDEN",
  "wrongTenantDenied": "STOMP_SUBSCRIPTION_FORBIDDEN",
  "unassignedProctorDenied": "STOMP_SUBSCRIPTION_FORBIDDEN",
  "violationReceivedByBoth": true,
  "reconnectSnapshotDuplicateCount": 1
}
```

Capture the sanitized JSON only. Clear the seven environment variables after
the run.

- [ ] **Step 4: Re-run final gates**

```powershell
.\mvnw.cmd -pl services/scheduling,services/proctor -am package
flutter analyze
flutter test --reporter compact
flutter build windows --debug
```

Expected: every deterministic command exits zero.

- [ ] **Step 5: Commit the reusable probe without credentials**

```powershell
git add tool/live_proctor_runtime_probe.dart
git commit -m "test(proctor): add live runtime contract probe"
```

Before committing, run `rg -n "Bearer |eyJ" tool/live_proctor_runtime_probe.dart`
and require no match.

---

### Task 9: Phase Evidence and Handoff

**Files:**
- Update: `pte-doc/projects/plans/hung-host-mini-console/phase-08-live-proctor-console.md`
- Update: `pte-doc/projects/plans/hung-host-mini-console/plan.md`
- Create: `pte-doc/projects/plans/hung-host-mini-console/tests/phase-08-live-proctor-console-test-report.json`
- Create: `pte-doc/projects/plans/hung-host-mini-console/quality/phase-08-live-proctor-console-quality-report.json`
- Create: `pte-app/plans/hung-host-mini-console/quality/phase-08-live-proctor-console-quality-report.json`
- Create: `pte-app/plans/hung-host-mini-console/quality/phase-08-live-proctor-console-receipt.json`
- Create: `pte-api/plans/hung-host-mini-console/quality/phase-08-live-proctor-console-quality-report.json`
- Create: `pte-api/plans/hung-host-mini-console/quality/phase-08-live-proctor-console-receipt.json`

**Interfaces:**
- Consumes: exact test, build, runtime, and static-review outputs
- Produces: canonical Phase-08 status and per-implementation-repository receipts

- [ ] **Step 1: Run the architecture/static review**

Verify no direct Dio construction, cross-feature BLoC/repository imports,
hardcoded UI copy/colors, unclosed subscription/timer/controller, Dart file over
300 lines, or direct client-side tenant override exists.

- [ ] **Step 2: Write evidence with the truthful verdict**

Use `APPROVED` only if Task 8 runtime cases pass. Otherwise use:

```json
{
  "verdict": "IMPLEMENTED_AWAITING_RUNTIME_VERIFICATION",
  "open_blocking_source_findings": 0,
  "runtime_gate": "BLOCKED_NO_RUNNING_STACK"
}
```

Include every command, exit code, test count, blocked prerequisite, source
finding, resolution, and residual impact.

- [ ] **Step 3: Verify final diffs**

Run in `pte-app`, `pte-api`, and `pte-doc`:

```powershell
git status --short
git diff --stat
git diff --check
```

Expected: only approved Phase-08 evidence changes remain after source commits.

- [ ] **Step 4: Commit evidence per repository**

In `pte-app`:

```powershell
git add plans/hung-host-mini-console/quality/phase-08-live-proctor-console-quality-report.json plans/hung-host-mini-console/quality/phase-08-live-proctor-console-receipt.json
git commit -m "docs(proctor): record phase 08 app evidence"
```

In `pte-api`:

```powershell
git add plans/hung-host-mini-console/quality/phase-08-live-proctor-console-quality-report.json plans/hung-host-mini-console/quality/phase-08-live-proctor-console-receipt.json
git commit -m "docs(proctor): record phase 08 backend evidence"
```

In `pte-doc`:

```powershell
git add projects/plans/hung-host-mini-console/phase-08-live-proctor-console.md projects/plans/hung-host-mini-console/plan.md projects/plans/hung-host-mini-console/tests/phase-08-live-proctor-console-test-report.json projects/plans/hung-host-mini-console/quality/phase-08-live-proctor-console-quality-report.json
git commit -m "docs(proctor): complete phase 08 verification"
```

Do not push or merge.

- [ ] **Step 5: Present the handoff**

Report role policy, backend endpoints/destinations, commits, focused/full test
counts, Windows build result, runtime result or blocker, and clean/remaining
working-tree status. Do not mark Phase 09 runtime complete unless its required
login-to-audit path was also demonstrated.
