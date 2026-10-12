# Independent red-team review

Date: 2026-10-11. Current verdict: **PASS** after focused re-review. Initial verdict was BLOCK on the two security contract gaps preserved below. Review only; no product code or tests changed/executed.

## Ranked findings

### 1. HIGH — Outbound authorization and revocation have no explicit linearization boundary

**Where:** master Architecture Decision 7; phase 02 Design Constraints and Steps 5–6; spec FR-11/security NFR.

The plan chooses a fresh database authorization check in `ExecutorChannelInterceptor.beforeHandle`, but does not coordinate that read/decision with the actual socket handler dispatch and assignment-removal commit. A revocation can commit after the check and before dispatch. The existing delayed-executor test (hold before the check, revoke, release) does not exercise this second race. Master wording narrows the guarantee to “no new dispatch authorized after its commit,” while spec promises zero new topic delivery after revocation; the only stated exception is bytes already sent. These are materially different contracts.

**Required fix:** explicitly define the authorization/dispatch linearization point and the in-flight exception. Either specify a shared revocation/dispatch coordination mechanism, including its lifetime through handler completion and multi-instance/transaction behavior, or consistently declare that a dispatch authorized before revocation may complete afterward. Preserve fail-closed fresh recipient checks for decisions after the committed revoke. Add a deterministic concurrent test that pauses *after successful authorization but before the handler*, commits revocation, and asserts the chosen contract. Do not claim an interceptor callback alone supplies atomic check-and-send.

### 2. HIGH — Exact inbound allowlist/header trust rules are referenced but absent from the plan

**Where:** phase 02 Step 5 (“from master”); master Architecture Decision 7.

Research names the three SEND patterns and four own-user queues, but neither master nor phase defines the complete decision table. The plan denies foreign destinations but does not say how client-supplied native `simpUser`, `simpSessionId`, `user`, destination/subscription spoofing or duplicated native requestId headers are handled. Current `StompAuthChannelInterceptor` only authenticates CONNECT, and current controller trusts the framework principal. Moving to a custom registry/private socket targeting makes trusted transport headers versus arbitrary native headers an important security boundary.

**Required fix:** add the precise SEND/SUBSCRIBE table (three application patterns, assigned exam topic, four own-user queues), reject every other MESSAGE destination, and state that actor/session/subscription ownership comes exclusively from server-generated transport metadata plus the authenticated registry. Never copy native `simp*`/user/session headers into trusted message headers. Define CONNECT/DISCONNECT/UNSUBSCRIBE/heartbeat handling and reject client MESSAGE/CONNECTED or unsupported commands. Require exactly one bounded canonical UUID requestId when present; safe transport rejection must resolve or terminate pending requests. Add spoofed-header/direct-broker/wildcard/foreign-user negative tests.

### 3. MEDIUM — Shared refresh ownership needs its actual package seam documented

**Where:** phase 04 Files/Steps 1 and 7.

`packages/api-client/src/client/client.ts` owns `refreshingPromise` and private `tryRefresh`; `ApiClient` currently exposes no refresh operation. `packages/ui/src/hooks/createSessionApiClient.ts` only supplies refresh callbacks. A feature/shared-UI `ensureFreshAccessToken` cannot join that private promise without deliberately changing the client seam or relocating ownership. The intended behavior is correct, but the actual owning source/tests are omitted from phase 04.

**Required fix:** include the api-client client/type/tests in the change surface and choose an additive generation-safe refresh seam backed by the existing instance promise, or explicitly move shared ownership with equivalent regression tests. Verify request/upload/download retry paths remain on the same coordinator. This is a planning clarification, not an additional feature.

## Accepted without additional requirements

- Exported membership view is an explicit, narrow Session-owned SQL boundary; current phase 01 requires same-tenant, nondeleted session/enrollment predicates, excludes orphan membership and avoids raw cross-module table access.
- Highest immutable attemptNumber, nullable no-attempt state, enrolled-latest aggregates, paged histories and actual enums/roles are correctly defined.
- Mutation lock order, target scope, after-commit receipts/publication, immutable legacy topic payloads and origin-only correlated private responses are correctly required.
- Closed/scheduled pages render read-only without opening monitoring; auth flag-off routing and preservation of existing no-PROCTOR behavior are explicit.
- Dedicated opt-in PostgreSQL/unique-schema tests must actually run; skipped/native-query mocks are not passing evidence. Browser smoke is explicitly distinct from real authenticated integration.
- Every implementation phase has design constraints and truthful quality/testing states. TDD requires new behavioral RED evidence, not class absence or compilation failure. Skill receipt/interpreter preflight is explicit.

## Re-review condition

Re-read the revised master/spec and phases 02/04 for the three fixes. No broad research or extra P2 scope is needed.

## Focused re-review — PASS

All three findings have been addressed in the read-back versions of master plan, spec and phases 02/04:

1. **ACCEPTED and resolved:** master Decision 7, spec FR-11/security NFR and phase 02 explicitly choose the independent READ_COMMITTED recipient authorization query snapshot as the boundary. Authorization after revoke commit denies; a dispatch authorized earlier may complete afterward. No claim of atomic check-and-send or DB locks across socket writes remains. Phase 02 Step 6 includes both before-check and after-check deterministic races. This is a clear, implementable in-flight exception; execution must preserve the stated independent fresh-query semantics.
2. **ACCEPTED and resolved:** the master now has the exact inbound command/destination table, server-owned identity/session/subscription rules, native-header spoofing rejection, bounded single UUID requestId, explicit unsupported-command rejection and sanitized transport-error behavior. Phase 02 adds corresponding negative tests. Broker-resolved private queues are mapped through the trusted recipient/subscription registry rather than producer identity.
3. **ACCEPTED and resolved:** phase 04 includes `packages/api-client/src/client/client.ts` and its regression tests, specifies the public additive refresh seam on the same instance-owned promise, and retains all request/upload/download retry paths on the coordinator. UI/WS use the tenant HTTP client instance, with generation safety and token-only notification.

No important planning blocker remains. Passing this review means the implementation plan is coherent; it is not evidence that any product code, concurrency test, live integration or rollout gate has passed.
