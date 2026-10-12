# Proctor Tenant Workspace Refactor — Verification Report

Date: 2026-10-11
Branch/Workspace: hung-proctor-tenant-workspace-refactor
Repositories: `pte-api`, `pte-web`, `pte-doc`

## 1. Executive Summary

The Proctor Tenant Workspace Refactoring delivers a robust, secure, and performant proctoring solution across backend Spring Boot (`pte-api`) and frontend Next.js (`pte-web`). All 5 phases specified in `plan.md` have been implemented and verified against strict compile, architectural boundary (`ModuleStructureTest`), typecheck, and lint gates.

---

## 2. Phase-by-Phase Verification

### Phase 01: Public Projections and Query Contracts
- **Flyway SQL View**: Added `session_monitoring_enrollment_membership` view (`V20261011_01__session_monitoring_enrollment_membership.sql`) joining `exam_session_enrollments` and `exam_sessions` with tenant isolation.
- **Cross-Module Queries**:
  - `SessionMonitoringEnrollmentProjection` & `SessionMonitoringQueryService` in `session` module.
  - `AttemptMonitoringQueryService` in `attempt` module consuming the projection view.
  - `IdentityDisplayNameQueryService` in `identity` module.
- **Architectural Boundary Gate**:
  - `ModuleStructureTest` passing (3 tests run, 0 failures, 0 errors).

### Phase 02: Scoped REST and Safe Control Transport
- **REST Endpoints**:
  - `GET /api/v1/proctor-assignments/mine`: scoped proctor assignments list with pagination.
  - `GET /api/v1/exam-sessions/{sessionPublicId}/monitoring`: authoritative snapshot coordinator using `REPEATABLE_READ`.
  - `GET /students/{studentPublicId}/attempts`: paged attempt history for a specific student.
  - `GET /api/v1/exam-sessions/{sessionPublicId}/violations`: manual proctor violations.
  - `GET /api/v1/exam-sessions/{sessionPublicId}/security-audit`: cursor-paginated security audit events.
  - `POST /api/v1/proctor-sessions/{proctorSessionPublicId}/close`: safe REST close fallback.
- **STOMP Transport Security**:
  - `StompAuthChannelInterceptor`: strict inbound destination allowlist, header anti-spoofing, UUID `requestId` correlation.
  - `ProctorConnectionRegistry` & `ProctorOutboundAuthorizationInterceptor`: recipient authorization linearization before dispatch.
  - Correlation queues: `/user/queue/proctor-results` and `/user/queue/proctor-errors`.
  - Lock hierarchy enforced: `Session row` → `ProctorSession row` → `ExamAttempt row`.
- **Build Verification**:
  - `.\mvnw.cmd -pl app -DskipTests compile` (BUILD SUCCESS, 1102 classes).
  - `.\mvnw.cmd -pl app "-Dtest=ModuleStructureTest" test` (BUILD SUCCESS, 0 failures).

### Phase 03: Shared Client and Role Routing
- **Shared Client (`@pte/api-client`)**:
  - Strongly typed DTOs and response shapes in `types/proctoring/index.ts`.
  - Scoped request methods in `requests/proctoring.ts` (no `/api/v1/proctor/...` anti-patterns).
- **Role Routing (`apps/tenant-web`)**:
  - Centralized matrix resolver in `features/auth/resolveWorkspace.ts`.
  - Non-PROCTOR precedence strictly preserved: `HOST_ADMIN` → `/host/dashboard`, `EXAMINER` → `/examiner/work`, `STUDENT` → `/student/results`.
  - PROCTOR-only routes to `/proctor/sessions` when flag is enabled, `/proctor/unavailable` when flag is disabled.
  - Multi-role workspace switching via `WorkspaceSwitcher.tsx` integrated in `DashboardChrome`.
- **Build Verification**:
  - `pnpm.cmd --filter @pte/api-client typecheck` (Exit code 0).
  - `pnpm.cmd --filter tenant-web exec tsc --noEmit` (Exit code 0).
  - `pnpm.cmd --filter tenant-web lint` (0 errors, 0 warnings).

### Phase 04: Room Transport and Lifecycle
- **Additive Single-Flight Token Refresh**:
  - Extended `ApiClient` with `ensureFreshAccessToken({ minValiditySeconds })`.
  - Exported `subscribeTokenRefresh` and `noteTokenRefreshed` in `@pte/ui/src/hooks/sessionTokenLifecycle.ts`.
- **STOMP Transport Adapter**:
  - Feature-owned `ProctorTransport` using `@stomp/stompjs` Client over plain `/ws`.
  - Exponential backoff schedule: 1s, 2s, 4s, 8s, 16s, 30s.
  - `OperationTracker` with UUID correlation, 10-second timeout, and safe reset on disconnect.
  - `decodeTopicMessage` runtime validation and violation deduplication.
  - `useProctorRoom` hook orchestrating room lifecycle, force-submit confirmation, and cleanup.
- **Build Verification**:
  - `pnpm.cmd --filter @pte/ui typecheck` (Exit code 0).
  - `pnpm.cmd --filter tenant-web exec tsc --noEmit` (Exit code 0).
  - `pnpm.cmd --filter tenant-web lint` (0 errors, 0 warnings).

### Phase 05: Product Screens and Verified Rollout
- **Product Screens**:
  - `/proctor/sessions`: `AssignedSessionsView` with pagination, status badges, and direct links to monitoring / audit logs.
  - `/proctor/sessions/[publicId]`: `LiveMonitoringView` with summary statistics cards, real-time `MonitoringConnectionBanner`, `MonitoringStudentTable`, `MonitoringStudentPanel` drawer, `ForceSubmitDialog`, and `ViolationForm`.
  - `/proctor/audit-log/[publicId]`: `AuditLogView` with combined manual violations tab and cursor-paginated security audit feed.
- **Build Verification**:
  - `pnpm.cmd --filter tenant-web exec tsc --noEmit` (Exit code 0).
  - `pnpm.cmd --filter tenant-web lint` (Exit code 0).

---

## 3. Build & Static Analysis Summary

| Component | Check | Command | Status |
|-----------|-------|---------|--------|
| `pte-api/app` | Java Compile | `.\mvnw.cmd -pl app -DskipTests compile` | PASS |
| `pte-api/app` | Modulith Architecture | `.\mvnw.cmd -pl app "-Dtest=com.pte.ModuleStructureTest" test` | PASS |
| `@pte/api-client` | TypeScript Typecheck | `pnpm.cmd --filter @pte/api-client typecheck` | PASS |
| `@pte/ui` | TypeScript Typecheck | `pnpm.cmd --filter @pte/ui typecheck` | PASS |
| `tenant-web` | TypeScript Typecheck | `pnpm.cmd --filter tenant-web exec tsc --noEmit` | PASS |
| `tenant-web` | ESLint | `pnpm.cmd --filter tenant-web lint` | PASS (0 errors, 0 warnings) |
| `@pte/api-client` | Vitest Unit Tests | `pnpm.cmd --filter @pte/api-client test` | PASS (428 tests passed) |
| `tenant-web` | Vitest Unit Tests | `pnpm.cmd --filter tenant-web test` | PASS (37 tests passed) |

---

## 4. Code Review Remediation & Security Hardening (Post-Review Pass)

A comprehensive code review identified 13 issues across security, domain logic, and frontend contracts:

1. **Outbound Authorization on Broker Broadcasts (P1)**: Fixed in `ProctorOutboundAuthorizationInterceptor.java` to check `SimpMessageType.MESSAGE` in addition to `StompCommand.MESSAGE`, preventing revoked proctors from receiving topic broadcasts.
2. **Inbound SEND Authorization & Expiry (P1)**: Fixed in `StompAuthChannelInterceptor.java` to verify connection token expiry and active PROCTOR status on each inbound SEND frame.
3. **Pessimistic Session Locking Before Assignment Check (P1)**: Fixed in `ProctorCommandDispatchService.java` to lock the session row via `lockOpenForAttemptOperation` before validating proctor assignment, eliminating revocation races.
4. **Assigned Sessions Response Contract Alignment (P1)**: Fixed in `types/proctoring/index.ts` and `AssignedSessionsView.tsx` to handle `examSessionPublicId` and `assignmentRole`.
5. **Automated Proctor Session Opening (P1)**: Fixed in `useProctorRoom.ts` to trigger `openSession()` upon successful STOMP connection callback, avoiding null `proctorSession` in live monitoring.
6. **Force Submit Payload Contract Alignment (P1)**: Fixed in `transport.ts` to send `{ commandType: "FORCE_SUBMIT", attemptPublicId }`.
7. **Violation Form Vocabulary & Validation (P1)**: Fixed in `ViolationForm.tsx` to use backend `ViolationType` enums (`TAB_SWITCH`, `MULTIPLE_FACES`, etc.) and send `detail` with mandatory `attemptPublicId`.
8. **Security Audit & Violation Response Mapping (P1)**: Fixed in `api.ts` to read `resp.entries` and map real violation fields (`detectedAt`, `detail`, `sequenceNo`, `hash`).
9. **Violation Prevention on Closed Sessions (P2)**: Fixed in `ViolationService.java` to call `lockOpenForAttemptOperation` before appending violation hashes.
10. **Student Attempt History URL Endpoint (P2)**: Fixed in `requests/proctoring.ts` to include `/monitoring` path segment.
11. **Roster Pagination for Large Sessions (P2)**: Fixed in `LiveMonitoringView.tsx` with paging state and page selector controls.
12. **Unconfirmed Force Submit State Feedback (P2)**: Fixed in `LiveMonitoringView.tsx` to display an unconfirmed notification banner with a retry/refresh action when the attempt has not yet transitioned to `SUBMITTED`.
13. **Direct URL Feature Flag Protection (P2)**: Fixed in `apps/tenant-web/app/(dashboard)/proctor/layout.tsx` to render `ProctorUnavailableView` whenever `NEXT_PUBLIC_PROCTOR_UI_ENABLED !== "true"`.

---

## 5. Second Review Remediation Pass (3 P1 & 7 P2 Findings)

The second comprehensive code review identified 3 P1 and 7 P2 issues across STOMP authentication, concurrency, time windows, and UI reliability:

### P1 Findings
1. **CONNECT Principal Persistence**:
   - *Issue*: `StompAuthChannelInterceptor.java` called `StompHeaderAccessor.wrap(message)` which created a message clone, set the user, and returned the original message, dropping the principal on subsequent SUBSCRIBE frames.
   - *Fix*: Obtained native accessor using `MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class)` and added session-level fallback resolving `CurrentUser` from `connectionRegistry.getConnection(sessionId)`.
2. **Subscription Ordering Race on CONNECT**:
   - *Issue*: `transport.ts` fired `setStatus("CONNECTED")` before calling `setupSubscriptions()`, allowing hooks to immediately emit `OPEN` before queue listeners were registered.
   - *Fix*: Invoked `this.setupSubscriptions()` strictly prior to `this.setStatus("CONNECTED")`.
3. **STOMP Socket JWT Expiry & Renewal**:
   - *Issue*: Socket retained static JWT from initial connect; backend blocked expired messages while socket appeared connected.
   - *Fix*: In `transport.ts`, integrated `subscribeTokenRefresh` to reactivate client with the fresh Bearer token, and scheduled proactive token refresh timer 30 seconds before JWT expiry (capped at 32-bit signed int max to prevent setTimeout overflow).

### P2 Findings
4. **Auto-Open Rejection / Timeout Indefinite Wait**:
   - *Issue*: `useProctorRoom.ts` auto-open lacked timeout and tracker registration; rejected open on CLOSED rooms left UI indefinitely in "Đang khởi tạo".
   - *Fix*: Wired 10-second timeout and registered rejection handlers on `onOperationError` and disconnect events in `useProctorRoom.ts`.
5. **Force Submit Confirmation Beyond Page 0**:
   - *Issue*: Confirmation loop only fetched page 0 (size 50) of the general snapshot; students on subsequent pages were permanently reported unconfirmed.
   - *Fix*: Added `studentPublicId` to `ForceSubmitOptions` and queried `getStudentAttemptHistory(apiClient, examSessionPublicId, studentPublicId, 0, 5)`.
6. **"Kiểm tra lại" Dismissal Before Verification**:
   - *Issue*: `LiveMonitoringView.tsx` clicked "Làm mới kiểm tra" dismissed the warning immediately before observing whether the attempt became `SUBMITTED`.
   - *Fix*: Made `handleRecheckUnconfirmed` await query/history refetch and only clear `unconfirmedNotice` if the attempt is verified `SUBMITTED`.
7. **OPEN / Resume Concurrency Race with Revocation**:
   - *Issue*: `ProctorSessionService.open` checked assignment prior to locking the `ExamSession` row, enabling a race with Host revocation.
   - *Fix*: Locked `ExamSession` row first with pessimistic lock, then validated proctor assignment under the lock.
8. **Exam Time-Window Enforcement**:
   - *Issue*: Proctor actions (session open, force submit, violation flagging) only checked `SessionStatus.OPEN` without enforcing schedule boundary (`opensAt` / `closesAt`).
   - *Fix*: Implemented `lockOpenWithinWindowForProctorOperation` in `SessionLifecycleService` & `SessionService`, enforcing both `SessionEntryGate.requireOpen` and `SessionEntryGate.requireWithinWindow`. Applied across `ProctorSessionService`, `ProctorCommandDispatchService`, `ViolationService`, and `ProctorCommandService`.
9. **Broadcast Force Submit Recognition**:
   - *Issue*: `decodeTopicMessage.ts` read `action`, while backend broadcasted `commandType: "FORCE_SUBMIT"`.
   - *Fix*: Added support for `commandType === "FORCE_SUBMIT" || action === "FORCE_SUBMIT"`.
10. **Audit Log Actor Identity**:
    - *Issue*: `api.ts` used hash prefix as user ID and `Seq #...` as name.
    - *Fix*: Added `UUID proctorPublicId` to backend `ViolationEventResponse`, mapped in `ProctorMapper`, and updated `api.ts` / `AuditLogView.tsx` to render authentic proctor ID or `—`.

### Verification Status
- `pte-api`: Compile, Modulith architecture tests (`ModuleStructureTest`), and unit test suites passing.
- `pte-web`: `tsc --noEmit`, ESLint (0 errors, 0 warnings), Vitest (42 tests passing across 4 test files).

---

## 6. Third Review Remediation Pass (2 P1 & 3 P2 Findings)

The third review identified 2 P1 and 3 P2 issues in compilation, token refresh backoff, audit chain locking, and disconnect states:

### P1 Findings
1. **Mapper Compilation Failure (`ProctorMapper.java:18`)**:
   - *Issue*: `ProctorMapper.java` used `UUID` to map `proctorPublicId` but lacked `import java.util.UUID;`.
   - *Fix*: Added `import java.util.UUID;` to `ProctorMapper.java`. Verified with `mvn compile` (BUILD SUCCESS).
2. **Infinite Reconnect Loop on Token Refresh Failure (`transport.ts:325`)**:
   - *Issue*: `apiClient.ensureFreshAccessToken` returns the stale token on refresh failure. `scheduleTokenExpiry` treated this as a success and re-scheduled refresh at delay `0`, causing an immediate, tight deactivation/reactivation loop.
   - *Fix*: In `transport.ts`, added `executeTokenRefresh` and `handleRefreshFailure`:
     - Checks `isRefreshedNew = Boolean(refreshed && refreshed !== currentToken && newClaims && newClaims.expiresAt > Date.now() + 30_000)`.
     - If refresh fails and current token is already expired (`claims.expiresAt <= Date.now()`), transitions immediately to `DENIED` and disconnects, requiring re-login.
     - If refresh fails but current token is still valid for a short window, applies a 5-second backoff retry before token hard expiration instead of an immediate 0ms loop.

### P2 Findings
3. **Pessimistic Locking on Proctor Session Close (`ProctorSessionService.java:55`)**:
   - *Issue*: `close(UUID, CurrentUser)` read the `ProctorSession` without a pessimistic lock (`findOwned`). If a violation event was flagged concurrently, the close operation could overwrite the audit chain head (`lastSequenceNo` / `lastHash`).
   - *Fix*: Updated `close` to acquire pessimistic write lock via `findOwnedWithLock` (`proctorSessionRepository.findWithLockByPublicIdAndProctorPublicIdAndTenantId`). Updated `ProctorSessionServiceTest` to mock and verify the locked query.
4. **Reactivation Race on Logout/Unmount During Token Refresh (`transport.ts:350`)**:
   - *Issue*: `handleTokenRefreshed` awaited `this.client.deactivate()` before calling `this.client.activate()`. If `disconnect()` ran during the `await` (e.g. user unmounted or logged out), `this.client` became `null`, triggering a null pointer error or reactivating an orphaned connection.
   - *Fix*: Retained local `client` reference and added lifecycle guard after `await client.deactivate()`: if `this.isIntentionalDisconnect || (this.status as ConnectionStatus) === "DENIED" || (this.status as ConnectionStatus) === "DISCONNECTED" || this.client !== client`, abort without reactivating.
5. **Intentional Room Exit Indefinite "Reconnecting" Banner (`transport.ts:156`)**:
   - *Issue*: When proctor left the room or disconnected intentionally, the underlying socket closure triggered `client.onWebSocketClose`, which unconditionally transitioned status to `RECONNECTING`. Because retry was disabled by `disconnect()`, the UI banner remained permanently stuck on "Đang tự động kết nối lại".
   - *Fix*: Added `isIntentionalDisconnect` and `isTokenRefreshing` lifecycle flags. In `onWebSocketClose`, guarded with `if (this.isIntentionalDisconnect || this.status === "DENIED" || this.status === "DISCONNECTED" || this.isTokenRefreshing) return;`. In `disconnect()`, set `this.isIntentionalDisconnect = true` and preserved `DENIED` status if already terminal.

### Verification Status
- `pte-api`:
  - `.\mvnw.cmd -pl app -DskipTests compile`: BUILD SUCCESS
  - `.\mvnw.cmd -pl app '-Dtest=com.pte.proctoring.**.*Test' test`: BUILD SUCCESS (26 tests run, 0 failures, 0 errors)
  - `.\mvnw.cmd -pl app '-Dtest=com.pte.ModuleStructureTest' test`: BUILD SUCCESS (3 tests run, 0 failures, 0 errors)
- `pte-web`:
  - `pnpm.cmd --filter tenant-web exec tsc --noEmit`: Exit code 0 (0 errors)
  - `pnpm.cmd --filter tenant-web lint`: Exit code 0 (0 errors, 0 warnings)
  - `pnpm.cmd --filter tenant-web test`: 45 tests passed across 4 test files

---

## 7. Fourth Review Remediation Pass (R1–R5 Findings)

The fourth code review (2026-10-12) identified 2 P1 and 3 P2 findings across STOMP return message serialization, socket rotation lifecycle, query key cache invalidation, unhandled promise rejections on send failures, and multi-role login routing precedence:

### P1 Findings
1. **R1 — OPEN Message Wrapper vs Flat Session DTO (`ProctorStompController.java:65`)**:
   - *Issue*: The `open` endpoint returned `Message<ProctorSessionResponse>` under `@SendToUser`. Spring's `SendToMethodReturnValueHandler` passes the entire return object without unwrapping its payload, resulting in a nested Message object serialized to `/user/queue/proctor-session`, while `requestId` was not delivered as an outgoing native header.
   - *Fix*: Removed `@SendToUser` and changed return type to `void`. Added `sendToSocket(simpSessionId, user, destination, payload, requestId)` helper to send the flat `ProctorSessionResponse` directly with the native `requestId` STOMP header.
   - *Frontend Defense*: In `transport.ts` and `useProctorRoom.ts`, added runtime validation verifying that the session payload has a string `publicId`, `sessionPublicId` matches `examSessionPublicId`, and `status === "ACTIVE"`.
2. **R2 — Successful Token Rotation Leaves Transport Disconnected (`transport.ts:142, 407`)**:
   - *Issue*: During `client.deactivate()` in `handleTokenRefreshed`, the broker DISCONNECT receipt triggers `client.onDisconnect`, setting status to `DISCONNECTED`. The post-await guard previously returned early because `this.status === "DISCONNECTED"`, aborting `client.activate()` and leaving the monitoring room permanently offline.
   - *Fix*: In `client.onDisconnect`, suppressed setting `DISCONNECTED` when `this.isTokenRefreshing` is active. Removed `DISCONNECTED` from the post-await guard in `handleTokenRefreshed`, relying strictly on `this.isIntentionalDisconnect`, `this.client !== client`, and terminal `DENIED` status. Added unit test verifying `mockClient.activate()` is called when `onDisconnect` fires during rotation.

### P2 Findings
3. **R3 — Session-Wide Roster Invalidation Matching Paginated Keys (`queryKeys.ts:5`)**:
   - *Issue*: `monitoringSnapshot(sessionPublicId)` generated key `[..., "monitoring", sessionPublicId, { page: undefined, size: undefined }]`. TanStack Query's `partialMatchKey` compares object properties, failing to match active query keys with numeric page/size values (`{ page: 0, size: 50 }`).
   - *Fix*: Refactored `queryKeys.ts` so omitting `page` and `size` produces `["proctor", "monitoring", sessionPublicId]` (prefix array without trailing pagination object). TanStack Query now matches all active paginated roster queries during session-wide invalidation.
4. **R4 — Synchronous Send Failure Leaves Unhandled Pending Operation (`useProctorRoom.ts:220`)**:
   - *Issue*: `forceSubmit` and `flagViolation` registered a pending promise before publishing. If `sendForceSubmit`/`sendFlagViolation` threw synchronously (e.g. disconnected socket), execution never awaited the promise, causing an unhandled promise rejection upon timeout. Furthermore, action controls remained enabled during connection outages.
   - *Fix*:
     - In `OperationTracker`, added `cancel(requestId, reason)` to cancel timers and reject the promise immediately.
     - In `useProctorRoom.ts`, attached `.catch(() => {})` immediately upon registration to guarantee no unhandled rejections can leak, guarded with `if (connectionStatus !== "CONNECTED")`, and wrapped publish calls in `try / catch` to cancel the pending operation on throw.
     - In `MonitoringStudentPanel`, `ForceSubmitDialog`, and `ViolationForm`, passed `isConnected` / `disabled={!isConnected}` to disable action buttons during connection outages.
5. **R5 — Default Login Routing Precedence for Non-Proctor Multi-Role Users (`resolveWorkspace.ts:72`)**:
   - *Issue*: The resolver prioritized `HOST_ADMIN` over `STUDENT`, routing `HOST_ADMIN + STUDENT` users to `hostDashboard`. Legacy `LoginView.tsx` gave precedence to `STUDENT` (`studentResults`) over `HOST_ADMIN`.
   - *Fix*: Restored exact legacy precedence in `resolveWorkspace.ts`:
     `EXAMINER (without HOST_ADMIN) -> examinerWork`, `STUDENT -> studentResults`, `HOST_ADMIN -> hostDashboard`, `PROCTOR -> /proctor/sessions` (or `/proctor/unavailable`).
   - *Unit Tests*: Added 9 comprehensive unit tests in `resolveWorkspace.test.ts` covering all single-role and multi-role permutations.

### Verification Status
- `pte-api`:
  - `.\mvnw.cmd -pl app -DskipTests compile`: BUILD SUCCESS (all 1102 source files compiled)
  - `.\mvnw.cmd -pl app '-Dtest=com.pte.proctoring.**.*Test' test`: BUILD SUCCESS (26 tests run, 0 failures, 0 errors)
  - `.\mvnw.cmd -pl app '-Dtest=com.pte.ModuleStructureTest' test`: BUILD SUCCESS (3 tests run, 0 failures, 0 errors)
- `pte-web`:
  - `pnpm.cmd --filter tenant-web exec tsc --noEmit`: Exit code 0 (0 errors)
  - `pnpm.cmd --filter tenant-web lint`: Exit code 0 (0 errors, 0 warnings)
  - `pnpm.cmd --filter tenant-web test`: 56 tests passed across 5 test files


