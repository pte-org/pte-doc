# Phase 02 — Scoped REST and safe control transport

Status: completed. Dependency: 01 completed. Coverage: all P1 read/control/security; FR-02–11.

## Design Constraints

- Caller tenant + current PROCTOR identity membership + assignment enforced server-side. HOST_ADMIN management endpoints remain unchanged in role scope.
- Read-assigned permits scheduled/closed states; control requires OPEN/window, owned ACTIVE monitoring. Close-owned remains possible after revoke/close, granting no read/control privileges.
- Single lock order Session → owned monitoring → target attempt; revoke locks same Session. Publication/private positive receipts occur after successful commit.
- Outbound authorization is per recipient at beforeHandle, fresh READ_COMMITTED query snapshot, no positive cache; preserve exact legacy mixed topic/error payloads. Follow master Inbound STOMP Contract table and header trust rules. Dispatch authorized before revoke commits may finish after commit; a fresh authorization read after commit denies. Never claim check-and-send atomicity. Register only authenticated transport sessions; expiration/drop cleanup bounded.
- Preflight: conventions verified against SessionService, ProctorSessionService, WebSocketConfig, StompAuthChannelInterceptor, and ViolationService; lock hierarchy Session -> ProctorSession -> ExamAttempt; recipient outbound authorization on clientOutboundChannel with ExecutorChannelInterceptor.beforeHandle; REST endpoints follow ApiResponse<T> with PagedResult<T> envelopes under /api/v1; CurrentUser from security context supplies tenantId and user publicId.

## Files

Paths relative to pte-api.

Existing:

- `app/src/main/java/com/pte/session/internal/service/EnrollmentService.java`
- `app/src/main/java/com/pte/session/internal/repository/ExamSessionRepository.java`
- `app/src/main/java/com/pte/session/SessionService.java`
- `app/src/main/java/com/pte/attempt/internal/service/ProctorCommandService.java`
- `app/src/main/java/com/pte/attempt/internal/repository/ExamAttemptRepository.java`
- `app/src/main/java/com/pte/proctoring/internal/service/{ProctorSessionService,ProctorCommandDispatchService,ViolationService,SecurityAuditQueryService}.java`
- `app/src/main/java/com/pte/proctoring/internal/repository/{ProctorSessionRepository,ViolationEventRepository}.java`
- `app/src/main/java/com/pte/proctoring/internal/config/{WebSocketConfig,StompAuthChannelInterceptor}.java`
- `app/src/main/java/com/pte/proctoring/internal/controller/{ProctorStompController,ProctorSessionController}.java`

Proposed:

- `app/src/main/java/com/pte/session/internal/controller/ProctorAssignmentQueryController.java`
- `app/src/main/java/com/pte/session/internal/dto/response/AssignedProctorSessionResponse.java`
- `app/src/main/java/com/pte/proctoring/internal/controller/MonitoringController.java`
- `app/src/main/java/com/pte/proctoring/internal/service/MonitoringQueryService.java`
- `app/src/main/java/com/pte/proctoring/internal/policy/ProctorAccessPolicy.java`
- `app/src/main/java/com/pte/proctoring/internal/config/{ProctorConnectionRegistry,ProctorOutboundAuthorizationInterceptor}.java`
- `app/src/main/java/com/pte/proctoring/internal/dto/response/{MonitoringSnapshotResponse,MonitoringStudentResponse,MonitoringSummaryResponse,ProctorOperationResultResponse,ProctorOperationErrorResponse}.java`
- `app/src/test/java/com/pte/proctoring/internal/{controller/MonitoringControllerTest,config/ProctorOutboundAuthorizationInterceptorTest,config/ProctorTransportSecurityIntegrationTest,service/ProctorOperationRaceIntegrationTest}.java`

## Steps

1. Create PROCTOR-only assigned REST list, monitoring and enrolled-student history endpoints from master contracts. ApiResponse/current page envelope; default/cap 25/100. Read-only REPEATABLE_READ coordinator combines projections and batched manual event counts; DTOs contain safe metadata only.
2. Centralize read-assigned, control-open, owned-active and close-owned policy. Fix caller-tenant comparison in security-audit and legacy violation reads; preserve legitimate HOST_ADMIN audit semantics without allowing monitoring bypass by multi-role actor.
3. Add Session locked control gate and lock assignment removal on same row. Reauthorize open/resume inside transaction before reuse. Refactor force-submit exact tenant/session target + locked attempt; audit other touched submit paths for shared ordering. No-op already SUBMITTED; reject missing/foreign attempts.
4. Flag validates exact target and locks owned monitoring before hash/sequence append; concurrent flags yield unique increasing chain sequence. Broadcast and receipt use after-commit hooks; rollback publishes nothing. REST close remains owned/tenant/idempotent after revocation.
5. Add authenticated simpSessionId registry and exact inbound allowlist from master. Deny wildcard/foreign queues/direct broker writes/malformed destinations. Current identity/tenant/expiry/assignment checks at SEND/SUBSCRIBE, no thread-local auth on executors. Clean up DISCONNECT, UNSUBSCRIBE and abandoned sessions.
6. Add clientOutboundChannel ExecutorChannelInterceptor.beforeHandle recipient gate immediately before socket handler. Verify installed Spring hook semantics. Reject missing registry, revoked assignment, wrong tenant/expired token/inactive role; originating private denial replies stay possible without assignment. Test A: hold queued message before authorization, commit revoke, release: denied recipient receives nothing, authorized peer receives. Test B: pause after successful authorization before handler, commit revoke, release: existing in-flight dispatch may finish; every later fresh read denies. No network write held inside a DB lock. Add duplicate/spoofed native-header, direct broker, foreign queue, wildcard, unsupported-command tests from exact master table.
7. Add optional requestId native header and new socket-scoped results/errors. Keep open existing DTO and correlated header; preserve legacy errors/topic. Ensure validation/domain/controller errors correlate, malformed transport auth fails ERROR/disconnect safely. Bound requestId length/UUID, no stacktrace/token logs.
8. Run selected policy/controller/security/race/Modulith checks if authorized and record actual integration fixture. Do not expose feature flag until later end-to-end gate.

## Success Criteria

- All three endpoints tenant/assignment restricted; latest/count/history contracts correct and only minimal data.
- Resume after revoke, cross-session mutation, foreign close/read/subscription/direct broker send denied; close-owned cleanup remains permitted.
- Revocation/control serialization and queued outbound deny proven concurrently; concurrent flags hash-chain correct; rollback has no success publication.
- New-client socket correlation works independently for two tabs same actor; old clients retain shapes.

## Build and Test Commands

From pte-api: `.\mvnw.cmd -pl app -DskipTests compile`; authorized `.\mvnw.cmd -pl app '-Dtest=ModuleStructureTest,MonitoringControllerTest,ProctorSessionServiceTest,ProctorCommandDispatchServiceTest,ViolationServiceTest,SecurityAuditQueryServiceTest,ProctorCommandServiceTest,ProctorOutboundAuthorizationInterceptorTest,ProctorTransportSecurityIntegrationTest,ProctorOperationRaceIntegrationTest' '-Dpte.proctor.postgres.integration=true' test`. Include newly created assigned-controller tests in actual selection. Real concurrency tests reuse dedicated allowlisted PostgreSQL/unique-schema fixture and explicit transactions; don't substitute H2/mock/skipped opt-in evidence.

## Quality and Testing State

- Quality: skipped_by_user. Decision: user_confirmed_skip. Profile: recorded in Preflight.
- Testing: not_started (skipped by user via --no-tests).
- Risks: lock ordering/deadlocks, per-delivery lookup cost, interceptor exception path, socket-only user destinations and framework hook behavior.
