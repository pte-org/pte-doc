# Phase 02: Typed API client and actor-scoped cache

Status: completed [quality: skipped_by_user; decision: user_confirmed_skip; tests: not_started_user_declined]. Dependency: 01. Covers P1 actor; FR01, FR09–10, FR12.

## Design Constraints

Follow `@pte/api-client` exports and existing envelopes. Queries disabled until valid tenant+actor identity exists; no `default` actor/tenant shared key. Overview keys independent of page/filter. Preserve query-prefix invalidation and existing monitoring/submission lifecycle. Do not use overview responses to authorize writes.
Preflight: Use existing api-client request<T> conventions with unwrap; Query keys follow tenant -> actor -> resource -> params structure; Finite staleTime (30s) without background polling; Browser timezone resolved via Intl.DateTimeFormat().resolvedOptions().timeZone; Type checks via pnpm typecheck.

## Files

In `pte-web`: `packages/api-client/src/types/proctoring/index.ts`, `packages/api-client/src/requests/proctoring.ts`, `packages/api-client/src/types/scoring/examiner.ts`, `packages/api-client/src/requests/scoring/examiner.ts`; check/re-export through `src/types/scoring/index.ts`, `src/requests/index.ts`, `src/types/index.ts` and root `src/index.ts` when new symbols are not already covered.

Tenant hooks: `apps/tenant-web/features/proctor/queryKeys.ts`, `features/proctor/api.ts`, `features/examiner/api.ts`, `features/examiner/constants.ts`; add `features/examiner/queryKeys.ts` if needed. Existing `apps/tenant-web/app/providers.tsx` session lifecycle already cancels/clears queries; preserve it and verify actual SessionManager actor field naming.

## Steps

- [x] Add exact Phase01 overview types, enum scopes/readiness fields, `getProctorWorkspaceOverview` and `getExaminerWorkspaceOverview`; use `client.request<T>` with existing API unwrapping rather than a second transport/envelope layer.
- [x] Extend Proctor list arguments compatibly: existing positional page/size retained or overload plus options `{scope, sort, timezone}`. Overview also requires timezone. Resolve browser IANA zone on client with `Intl.DateTimeFormat().resolvedOptions().timeZone`; SSR and overview/TODAY query hooks wait for resolution. Surface invalid/unavailable timezone rather than silently choosing a host default. Validate serializing optional params and retain page size20 on UI.
- [x] Add identity-scoped overview/queue/assignment keys: root → tenant → actor → resource → params. Proctor overview and TODAY keys always include resolved IANA timezone; a timezone change starts a fresh cache scope. Preserve dedicated prefix functions without undefined parameter objects.
- [x] Update affected queue/assignment query hooks and their invalidation call sites together. Do not change all unrelated monitoring resource keys for this feature. Examiner detail keys must also prevent actor reuse because deep links remain reachable on account switch.
- [x] Add overview hooks with finite staleTime (e.g.30s), focus/manual refetch, no refetchInterval. Queries are enabled only when tenant+actor+role exist; background summaries cannot bypass disabled Proctor workspace.
- [x] Re-resolve browser IANA timezone on focus before enabling/refetching time-sensitive keys. On zone change, update keys and do not reuse old-zone placeholders. While visible, schedule one boundary timeout from server dayEnd/asOf; invalidate Proctor overview and active TODAY list at local midnight, then reschedule from new response. While hidden defer to focus; cleanup on unmount/logout/zone change. This is a day-boundary update, not repeated polling. If overview fails use independent list dayEnd/asOf context. staleTime alone never triggers midnight refresh.
- [x] On successful score mutation invalidate current actor overview, queue prefix and detail prefix. Retained retry/reconciliation logic remains unchanged; successful receipt refetch refreshes overview by same success/refetch path. Do not treat HTTP409 as success or clear retained intent.
- [x] Keep list and overview status/errors independent. 401/403 cannot produce zero DTOs; errors have localized summary retry UI later. Session lifecycle cancellation/clear remains active on logout and switch; do not render previous observer's placeholder data under new identity.

## Acceptance evidence

No requests before identity resolves; actor A/B same tenant cannot share payload. Card totals unchanged by queue page key. Score success invalidates exact overview/queue/detail prefixes. Overview failure does not prevent successful list rendering. No extra websocket/media/detail requests. Client and tenant TypeScript compile after implementation.

## Quality and Testing State

Quality: not evaluated; skip under prior preference. Testing: not started; skip tests/E2E under prior preference. Planned checks: `pnpm.cmd --filter @pte/api-client typecheck` and `pnpm.cmd --filter tenant-web exec tsc --noEmit --incremental false`. Not executed during planning; no runtime cache correctness claim from typechecks.
