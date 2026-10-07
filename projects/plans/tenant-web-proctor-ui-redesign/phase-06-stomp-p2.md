# Phase 06 — STOMP-based live monitoring (P2, separate plan)

**Workstream:** pte-web
**Blocks:** none (P2 follow-up)
**Spec:** FE-FR-02 (alternative implementation)
**Test mode:** standard (no-tdd)
**Risk:** MEDIUM — adds new external package, can be deferred indefinitely

## Goal

Replace the 3s REST polling from Phase 02 with STOMP-based live
monitoring, using a shared `@stomp/stompjs` wrapper in
`packages/api-client`.

This phase is **P2** and ships in a separate plan. Phase 01-05 are
the P1 release; Phase 06 is an enhancement once we have P1 in
production and want to reduce polling load.

## Why this is deferred

1. **P1 (Phase 02) ships polling** — same behavior as the deleted
   branch. Users see live data. Just less efficient.
2. **STOMP adds 2 risk axes** — new external package, new wrapper
   code. Best to ship P1, watch production, then add STOMP.
4. **Spec S5 (core) forbids new packages until Phase 04** — Phase 06
   adds `@stomp/stompjs` (peer-dep pattern).

## Detailed description (high level only)

### Files

- `packages/api-client/src/realtime/stompClient.ts` (~150 lines)
  (one wrapper; future live-monitoring features share it).
- `packages/api-client/src/realtime/stompClient.test.ts` (8 vitest cases).
- `packages/api-client/src/realtime/index.ts` (barrel export).
- `features/proctor/hooks/useProctorLiveSession.ts` (~120 lines).
- `features/proctor/components/LiveMonitoringView.tsx` — replace
  `useExamSessionAttempts` (Phase 02 polling) with
  `useProctorLiveSession` (Phase 06 STOMP).

### Risks specific to Phase 06

1. **STOMP 401-refresh** — backend REST client has tryRefresh;
   STOMP doesn't. Document as known limitation; if a JWT expires
   mid-session, pro must sign in again.
2. **Subscription order** — `/user/queue/errors` must be subscribed
   BEFORE any command, or errors are silently dropped.
3. **Component budget** — STOMP hook is 1 file; view file from
   Phase 02 unchanged. Total components still ≤ 6.
4. **External package** — `@stomp/stompjs` added to BOTH
   `packages/api-client/package.json` (peer-dep pattern, see
   v3 risk note) and `apps/tenant-web/package.json`.
5. **Lockfile churn** — modifies `pnpm-lock.yaml`. Coordinate with
   any other branch in flight.

### Acceptance criteria

- Same as Phase 02, but with `<500ms` frame-to-UI latency instead of
  3s polling latency.
- STOMP reconnects automatically (3 retries with exponential
  backoff); surfaces `ERROR` state to UI on persistent failure.
- Page load `/proctor/sessions/{id}` still works without STOMP
  (initial REST snapshot fills the table; STOMP frames update
  thereafter).

## Out of scope for Phase 06

- SockJS fallback (`@stomp/stompjs` is the only transport).
- Reconnect resilience beyond 3 retries.
- Token rotation triggered by REST's tryRefresh.

## Quality and Testing State

- Quality: not evaluated
- Testing: not started