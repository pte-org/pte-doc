# Proctor code review — 2026-10-12

Scope: current uncommitted Proctor backend and tenant-web implementation, shared API/token client, REST/STOMP contracts, authorization, mutation locks, monitoring queries/migration, role routing, UI, cache, and connection lifecycle. Product source was not edited by this review.

## Latest re-review — after R1–R5 fixes

All five findings below are resolved in the inspected source. Their original descriptions are retained as review history, not current outstanding findings.

| Finding | Current verification |
| --- | --- |
| R1 | OPEN now returns void and sends the flat response explicitly to the originating socket; requestId is a native outgoing header. Frontend validates publicId/status and checks the exam session id when provided. |
| R2 | onDisconnect skips the DISCONNECTED transition during token rotation. After deactivate, reactivation checks intentional shutdown, DENIED, and client ownership. |
| R3 | Session-only query keys now omit the pagination object and match all paginated queries by prefix. |
| R4 | Both mutation paths immediately attach rejection handling and cancel registration when publish throws. Hook and UI controls also guard the connection state. |
| R5 | Default routing restores legacy precedence: EXAMINER without HOST_ADMIN, then STUDENT, then HOST_ADMIN. |

No additional actionable defect was confirmed in the inspected fix paths and adjacent backend/frontend flows. This does not establish runtime or end-to-end correctness.

Fresh checks: backend offline Maven `-pl app -am -DskipTests compile` returned BUILD SUCCESS (classes reported up to date; not a clean rebuild). `pnpm.cmd --filter tenant-web exec tsc --noEmit --incremental false` exited 0. No tests, application startup, migration execution, or browser/end-to-end checks were run. Only this report was edited.

## Verification

- Backend: cached Maven 3.9.16, offline `-pl app -am -DskipTests compile`, with the existing local repository explicitly configured: BUILD SUCCESS. Compiler reported classes up to date; this was not a clean rebuild.
- Frontend: `pnpm.cmd --filter tenant-web exec tsc --noEmit --incremental false`: exit 0.
- Initial Maven wrapper failed before compilation; the cached Maven executable succeeded. Initial PowerShell pnpm shim was blocked by execution policy; pnpm.cmd succeeded.
- No tests, application startup, database migration execution, browser smoke, or end-to-end flow were run. Runtime findings below are source-level verification, including installed Spring Messaging 7.0.6, STOMP client, and TanStack Query source.

## Previous five findings

| Previous finding | Current code |
| --- | --- |
| Missing UUID import | Added in ProctorMapper; compile command succeeds. |
| Refresh failure immediate loop | executeTokenRefresh validates a changed token and handleRefreshFailure uses bounded delay or DENIED. |
| Close overwrites audit chain head | close now uses the owned pessimistic-lock query. |
| Refresh continuation dereferences null client | Captures client and checks ownership/intentional disconnect after await. |
| Intentional close shown as reconnect | Close callback now checks intentional disconnect. |

These corrections are present. They do not establish that the full feature works; successful token rotation has a separate regression below.

## Original findings — resolved in latest re-review

### R1 — P1: OPEN sends a Message wrapper instead of the flat session DTO

Location: `pte-api/app/src/main/java/com/pte/proctoring/internal/controller/ProctorStompController.java:95`.

The method returns `Message<ProctorSessionResponse>` under `@SendToUser`. Spring's SendToMethodReturnValueHandler passes the entire return object to convertAndSendToUser, which invokes conversion on that object; it does not unwrap its payload. Thus the private channel does not deliver the expected top-level publicId/status DTO, and the intended requestId is not applied as an outgoing native header.

The frontend transport parses this body directly as ProctorSessionDto, and useProctorRoom stores it without validating publicId/status. Its separate OPENED operation callback only calls the tracker, and OPEN is not registered there to establish proctorSession. Consequently the separate receipt does not repair the malformed session response: commands fail the ACTIVE guard or lack the monitoring ID.

Send the flat response explicitly to the requesting socket with actual native correlation headers, or return the flat DTO and configure headers through the supported return handling mechanism. Validate the session payload and matching exam session/request in the frontend.

### R2 — P1: Successful token rotation leaves the transport disconnected

Location: `pte-web/apps/tenant-web/features/proctor/transport.ts:411`, related lines 142–145 and 404.

handleTokenRefreshed gracefully deactivates the client. On a normal broker DISCONNECT receipt, the installed STOMP client's disposal callback calls onDisconnect before deactivation finishes. The application onDisconnect callback sets DISCONNECTED even while isTokenRefreshing is true. The post-await guard then returns before activate, so the first successful token refresh puts an active monitoring room offline until manual recovery.

Distinguish rotation from intentional shutdown in onDisconnect; guard reactivation using client ownership and intentional-disconnect state rather than the DISCONNECTED state created by the rotation itself. Existing mocked tests do not simulate the receipt callback during deactivate.

### R3 — P2: Session-wide roster invalidation does not match paginated keys

Location: `pte-web/apps/tenant-web/features/proctor/queryKeys.ts:6`.

monitoringSnapshot(sessionId) includes `{page: undefined, size: undefined}`. Active queries include numeric values. TanStack partialMatchKey compares those properties, so the session-only invalidation used after violations and submission confirmation does not match. Roster data remains stale until polling. The COMMAND handler's broader `all` invalidation compensates for that one path only.

Use a separate session prefix without a pagination object when invalidating all roster pages.

### R4 — P2: A synchronous send failure leaves an unhandled pending operation

Location: `pte-web/apps/tenant-web/features/proctor/useProctorRoom.ts:230`, also lines 312–319.

FORCE_SUBMIT and FLAG_VIOLATION register a rejecting pending promise before publishing. If the socket disconnects before publish, transport throws, and execution never awaits or cancels that registered promise. The dialog handles the send exception, but ten seconds later the abandoned promise rejects unhandled. The UI permits this scenario because it retains proctorSession ACTIVE during a connection outage.

Settle/remove registration when publish throws, attach rejection handling before send, and disable write controls while the transport is unavailable.

### R5 — P2: Default login routing changed for non-Proctor multi-role users

Location: `pte-web/apps/tenant-web/features/auth/resolveWorkspace.ts:73`.

The previous LoginView sent HOST_ADMIN + STUDENT users to studentResults. The new resolver prioritizes HOST_ADMIN and sends that same user to hostDashboard even without PROCTOR. This contradicts the resolver's stated preservation of legacy routing and the approved role-routing requirement.

Preserve the previous precedence for role combinations without PROCTOR, or explicitly adopt/document this separate behavior change.

## Limits

The review identifies verified issues in the inspected revision; it does not claim these are the final possible bugs. Compile/typecheck do not validate STOMP serialization, socket receipts, authorization races, or UI behavior against a running backend.
