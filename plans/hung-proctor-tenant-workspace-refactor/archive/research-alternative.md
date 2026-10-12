# Alternative research: Proctor implementation with the least moving parts

Date: 2026-10-11. Read-only research against the approved spec and current repositories. No implementation or test execution in this report.

## Recommendation

Use bounded REST snapshots as authoritative roster state, the existing STOMP transport for open/commands/manual violations, and a fresh authorization check before each sensitive outbound delivery. Do not add a presence/progress event platform, an authorization cache, an assignment-revocation event bus, or an operator audit store for this MVP.

## Alternatives and tradeoffs

| Decision | Lowest-complexity choice | Alternative | Why |
| --- | --- | --- | --- |
| State synchronization | Poll monitoring every 5 seconds, pause hidden tabs, invalidate on topic messages/reconnect | WebSocket-first progress/presence projections | Current topic only emits commands/manual violations; snapshots already required for authoritative FORCE_SUBMIT results. |
| Subscription revocation | Recheck tenant/assignment at outbound recipient delivery | Explicitly evict every socket on assignment-change events | Eviction requires publishing after-commit events, tracking all subscriptions and handling races across instances. A fresh delivery gate directly covers subscriptions created before revocation. |
| STOMP client | Add `@stomp/stompjs` to tenant-web; small feature-owned adapter | Handwritten STOMP frames or SockJS | Plain `/ws` is already deployed. Handwriting heartbeat/frame parsing adds avoidable lifecycle work; SockJS is unsupported and unnecessary. |
| Data composition | Public batch projections in session/attempt/identity; coordinator in proctoring | Cross-module repository joins or a new durable monitoring read model | Preserve Modulith ownership with bounded queries. A durable projection introduces event ordering/rebuild work without a measured need. |
| Audit | Existing security-audit cursor, explicit refresh/load-more | Infinite polling from the last cursor or new actor/action history | `nextCursor=null` at the tail is not a tail-feed token. Existing data does not contain durable command actor/results. |

### Outbound authorization details

The custom current CONNECT interceptor authenticates only once. Add inbound destination allowlisting and assignment/tenant checks for SUBSCRIBE/SEND, then a recipient-specific outbound check. Spring Security itself does not secure `clientOutboundChannel`; the custom outbound gate is an application decision, not a claim that enabling an annotation solves revocation. [Spring Security 7 WebSocket security](https://docs.spring.io/spring-security/reference/7.0/servlet/integrations/websocket.html).

Recommended placement: `proctoring/internal/config/WebSocketConfig.java`, current `StompAuthChannelInterceptor.java`, and new feature-local security policy/connection registry/outbound interceptor. Resolve the outbound recipient using `simpSessionId`; do not assume an outbound broker MESSAGE retains the original sender's Principal or use thread-local CurrentUserContext on executor threads. Seed the registry on authenticated CONNECT, store CurrentUser plus JWT expiration rather than the raw JWT, and remove on DISCONNECT. An absent recipient, expired credential, unknown sensitive destination, invalid UUID or failed assignment lookup denies delivery. Exact allowlisting prevents wildcard subscriptions and direct client SEND to `/topic/**` or `/queue/**`.

Because broker outbound delivery may be executor-backed, put the decisive check at the per-handler delivery stage rather than merely authorizing when a message is enqueued. The exact Spring interceptor hook must be verified against the installed framework before coding. Test after assignment removal has committed and before the subsequent broadcast is processed; also test a queued message held until after revocation. Already delivered bytes cannot be recalled. Do not turn revocation into a vague promise about retroactive delivery.

A fresh assignment lookup costs a database read per delivered monitoring event, but these are currently low-volume operator actions rather than heartbeat broadcasts. This is a reasonable initial tradeoff. No positive authorization cache until invalidation is designed and measured. A future eviction event can improve cleanup/notification, but should not be the sole confidentiality gate. No special authorization tiers for LEAD_PROCTOR versus ASSISTANT_PROCTOR.

### Projection boundaries

Session owns assignment/enrollment/session metadata, attempt owns attempts/heartbeats, identity owns display names, and proctoring owns manual violations. Expose records in existing public/NamedInterface packages and public facades; keep internal repository/DTO packages private. A page of 25 or 100 students must use bulk calls, not one call per student. Latest attempt ordering must be deterministic `(createdAt, publicId)` and history commands target the selected actual attempt UUID.

Do not hide a cross-module filtering problem behind client filtering after pagination. Lowest-cost MVP can omit optional full-dataset text search/filter controls until a correct public query composition exists. If roster status/search is shipped, the plan must specify filtering before pagination, stable totals, and name lookup behavior; a batch projection of an already paged enrollment slice cannot produce correct filtered pages. Aggregate counts must describe the entire enrolled roster and latest attempts, not all historical attempts or the current page. Check enrollment removal/history semantics with tests before asserting aggregate correctness.

### Frontend adapter and lifecycle

Add the STOMP dependency only to `apps/tenant-web/package.json`. Keep transport/decoding in `apps/tenant-web/features/proctor`, raw REST requests and DTO records in `packages/api-client/src/requests` and `src/types`; do not create `apps/tenant-web/src` or restore retired `/api/v1/proctor/...` paths. Preserve existing topic payload shapes and add runtime discriminators; malformed data should not mutate UI.

The official client supports async `beforeConnect`, which can obtain a current token before every connection. Configure bounded exponential reconnect according to the chosen stable installed version; do not assume beta API properties. Resubscribe user queues before requesting open, clear stale monitoring IDs on reconnect until the server resumes/rechecks, stop on denied/logout/unmount, and do not queue or replay commands. STOMP heartbeat is transport liveness, separate from student attempt heartbeat. [Official STOMP.js usage guide](https://stomp-js.github.io/guide/stompjs/using-stompjs-v5.html).

Use existing DashboardChrome and UI components. All proposed shared UI exports are present: DataTable, PageHeader, Badge, Drawer, Modal, ConfirmDialog, ErrorState, EmptyState, ForbiddenState, ToastProvider/useToast and PaginationControls. `Toast` is not the root API name: use the exported provider/hook. Role-switch entries must be role-allowed routes; they do not change roles or grant permissions.

## Corrections to the approved spec before planning

1. The actual tenant-administrator role is **HOST_ADMIN**, not HOST. Verified in `pte-api/app/src/main/java/com/pte/shared/security/SecurityRoles.java`, session controller annotations, and `pte-web/apps/tenant-web/features/auth/constants.ts`/`components/LoginView.tsx`. Correct role matrices and routing tests; do not introduce a HOST alias.
2. Local Next docs resolve at **`pte-web/apps/tenant-web/node_modules/next/dist/docs`**, not the monorepo root. Verified guide `01-app/03-api-reference/03-file-conventions/dynamic-routes.md`: dynamic `params` are promises and client pages can use React `use(params)`, matching the existing route scaffold.
3. Tenant-web Vitest currently includes only **`features/**/*.test.ts` in a Node environment**. Use pure resolver/decoder/lifecycle tests there and real browser smoke; TSX/DOM tests require an explicit additional environment/configuration, not a fictional existing harness.

## Concrete dependency order

1. Correct spec role names/approved status; define DTO/nullability/paging and error queue correlation, latest attempt/count semantics, and destination allowlist.
2. Add session assignment/enrollment public projections and attempt/identity batch projections; implement new REST controllers/coordinator; test scope and bounded queries.
3. Harden open/resume, target session membership, command/violation/legacy reads, inbound subscriptions, outbound delivery and private error replies. Test revocation and existing payload compatibility before exposing Proctor UI.
4. Add shared DTO/raw REST requests and feature adapters/hooks, then additive role resolver/switcher/rollout-off state. Preserve existing HOST_ADMIN/STUDENT/EXAMINER routing combinations without PROCTOR.
5. Integrate assigned-list/monitoring/history/audit screens, authoritative command confirmation, connection disposal, localized states and shared components.
6. Run targeted checks, then module/full build/typecheck/lint and authenticated browser flows. Leave flag default off until real API/security/browser checks pass; never claim mocked browser results are a live integration pass.

## Freshly verified environment and runnable validation commands

Environment probes ran successfully: Node **v24.20.0**, `pnpm.cmd --version` **12.4.1**, Maven wrapper **3.9.16**, Java **21.0.12.1**. Root `pte-web/package.json` declares `pnpm@11.8.0`, so verify package-manager enforcement/approved tooling before dependency installation. Do not rewrite a lockfile merely to accommodate the globally installed version. `mvn` is not on PATH; use `mvnw.cmd`. These are command/environment probes, not passing application tests.

From `D:\GitHub\PTE-org\pte-api`:

```powershell
.\mvnw.cmd -pl app '-Dtest=ModuleStructureTest,ProctorSessionServiceTest,ProctorCommandDispatchServiceTest,ViolationServiceTest,SecurityAuditQueryServiceTest,ProctorCommandServiceTest' test
.\mvnw.cmd -pl app test
```

Existing focused classes are verified under `app/src/test/java/com/pte`, including the actual module check name **ModuleStructureTest**. New inbound/outbound/controller integration test names must be included when created. Inspect integration profiles/database dependencies before relying on a full-suite pass.

From `D:\GitHub\PTE-org\pte-web`:

```powershell
pnpm.cmd --filter @pte/api-client test
pnpm.cmd --filter @pte/api-client typecheck
pnpm.cmd --filter tenant-web test
pnpm.cmd --filter tenant-web lint
pnpm.cmd --filter tenant-web exec tsc --noEmit
pnpm.cmd --filter tenant-web build
```

These scripts/package selectors were verified from package.json; no product test command was run during planning research. No installed Playwright package was found; the lockfile mention is Next's optional peer, not an executable browser test suite. Use available browser automation for manual authenticated smoke, or deliberately add a small browser harness in the integration phase if approved; do not write commands implying an existing Playwright test setup.

## Remaining risks for the planner

- Concurrent assignment removal versus mutation needs an explicit transaction/authorization boundary; a preliminary check alone cannot prove a race-free command.
- Mixed topic payloads and private error correlation require deliberate operation IDs with backward compatibility; unrelated tabs/users must not consume each other's pending results.
- Latest-attempt summaries must count enrolled students, handle no-attempt rows, and not overcount historical attempts.
- Access removal must stop hidden-tab polling and stale socket delivery, even if the existing PROCTOR JWT remains valid until its expiry.
- External database/JWKS/backend services and real test accounts may prevent a live end-to-end run; record that precisely rather than silently turning on the rollout flag.
