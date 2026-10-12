# Phase 04 — Room lifecycle and reliable operations

Status: completed. Dependency: 03 completed. Coverage: P1 control operations; FR-05–09/11–13.

## Design Constraints

- Plain /ws STOMP, stable @stomp/stompjs version verified before installing; no SockJS/custom frame parser. Token only in native CONNECT header.
- One room owner disposes timers/subscriptions/socket on unmount/logout/workspace change; connection never owns automatic exam close. Generation checks reject stale account callbacks.
- Shared single-flight HTTP refresh, separate token-only notification; no auth identity cache reset merely for token renewal. No mutation queue/replay.
- Mixed legacy messages runtime-validated; only invalidate/read state. All pending requests keyed by requestId + operation + target, and same originating socket. FORCE_SUBMIT success only actual SUBMITTED projection.

## Files

Paths relative to pte-web.

Existing:

- `apps/tenant-web/package.json`, `pnpm-lock.yaml`
- `packages/api-client/src/client/client.ts` (ApiClient interface, private tryRefresh and instance-owned refreshingPromise)
- `packages/api-client/src/client/client.test.ts` (existing request/upload/download retry/refresh regression tests)
- `packages/ui/src/hooks/{createSessionApiClient.ts,sessionStorage.ts,sessionLifecycle.ts,useSessionManager.ts}`
- `apps/tenant-web/lib/apiClient.ts`
- `apps/tenant-web/app/providers.tsx`
- `apps/tenant-web/features/proctor/api.ts`

Proposed:

- `apps/tenant-web/features/proctor/{transport.ts,transportTypes.ts,decodeTopicMessage.ts,operationState.ts,useProctorRoom.ts}`
- `apps/tenant-web/features/proctor/{decodeTopicMessage.test.ts,operationState.test.ts,transport.test.ts}`
- `packages/ui/src/hooks/sessionTokenLifecycle.ts` (separate token update channel, export per actual hook barrel)
- Shared-refresh race tests beside current shared auth/client test convention; inspect current Vitest inclusion before naming them.

## Steps

1. Inspect actual installed STOMP APIs and add stable dependency only tenant-web using declared pnpm. The coordinator is owned by `packages/api-client/src/client/client.ts`, not UI: add a public additive refresh seam to ApiClient backed by the existing instance `refreshingPromise`/`tryRefresh` and generation guard. Preserve request/upload/uploadDownload/download retry paths on this same promise. UI wrapper exposes ensureFreshAccessToken using that seam, not a second callback/promise; WS uses the same tenant apiClient instance as HTTP. Fresh-token fast path, failed/unavailable refresh and stale-generation behavior are explicit. Add token-update subscribers while retaining identity lifecycle semantics and adapter compatibility.
2. Add feature-owned transport adapter with configurable factory for controlled tests, plain socket URL without token, current token from beforeConnect, expiration-triggered renewal, bounded backoff 1/2/4/8/16/30s and terminal denied/logout state.
3. Subscribe private open/results/errors before open request; then exam topic. Only one pending open, 10-second timeout and manual retry; correlation header filters old replies. Reconnect clears old monitoring ID/control state, opens/resumes through server authorization. No commands until owned ACTIVE fresh response.
4. Decode legacy topic command/violation shapes, ignore malformed payload, dedupe violations by event UUID and invalidate query without changing attempt state. Correlate violation SAVED to originating request; unsolicited same-target events cannot satisfy pending flag.
5. Implement force confirmation state machine: confirm/send explicit target once, private receipt resolves transport acknowledgement, immediately refetch and poll authoritative projection; SUBMITTED yields confirmed, 10s yields unknown with manual refresh, denial ends pending, reconnect does not resend. Confirm historical selected target from its history projection, not unrelated latest row.
6. Implement close via REST and explicit confirmation; owned cleanup after revocation allowed. Roster polling 5s hidden pause, stale after 2 unsuccessful cycles, stop terminal 403/identity change. Topic invalidations dedupe to avoid request bursts.
7. Verify HTTP+WS simultaneous refresh uses one refresh operation and stale account results discarded; cleanup no leftover timers/subscriptions. Build shared UI and tenant; chosen tests cover transport lifecycle using controlled clocks, not an invented DOM harness.

## Success Criteria

- Refresh/reconnect uses current credential, no token logs/URLs, no refresh rotation race or old-identity callbacks; disposal deterministic.
- No automatic command/flag replay, correlated responses/errors independent across two tabs; timeout/denial never reports saved/submitted falsely.
- Historical target confirmation uses its explicit attempt status. Close affects monitoring only; read-only sessions never trigger open controls.

## Build and Test Commands

From pte-web: inspect packages/ui package scripts and run actual typecheck/build; `pnpm.cmd --filter tenant-web exec tsc --noEmit`; `pnpm.cmd --filter tenant-web lint`; authorized `pnpm.cmd --filter tenant-web test` plus actual shared UI test command after inclusion configured. Record package/version selection and shared refresh test harness accurately.

## Quality and Testing State

- Quality: skipped_by_user. Decision: user_confirmed_skip. Profile: recorded in Preflight.
- Testing: not_started (skipped by user via --no-tests).
- Risks: cross-app shared auth change, adapter disposal/reconnect race, correlation drift, expired socket and authoritative history confirmation.
