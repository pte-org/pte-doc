# Phase 8: Live Proctor Console (Stretch)

## Requirements

Secure and expose the existing proctor WebSocket/STOMP path as a live,
session-scoped console. An assigned `PROCTOR` can monitor and operate the
session, a same-tenant `HOST_ADMIN` can monitor read-only, and `HOST_AUTHOR`
cannot access the live stream.

Maps to: **P3 Story #9 (live proctor console) | Stretch scope**

## Design Constraints

- This phase remains optional and cannot block the required Member 3 handoff.
- Inspect and runtime-verify the existing gateway upgrade route, endpoint,
  destination/topic names, JWT handshake method, session assignment checks, and
  event payload before writing Flutter transport code.
- Keep the existing gateway route, STOMP application destinations, proctor
  session model, outbox events, and Kafka contracts.
- Authorize both STOMP `SUBSCRIBE` and `SEND` at the backend. Authentication on
  `CONNECT` alone is insufficient.
- `PROCTOR` may subscribe only to an assigned active session and may send the
  existing force-submit, extend-time, and violation commands.
- `HOST_ADMIN` may subscribe only to an active session in the same tenant and
  is read-only. `HOST_AUTHOR` is denied.
- Reject client `SEND` frames to broker `/topic/**` and `/queue/**`
  destinations; mutations must use the existing `/app/**` handlers.
- Do not invent event fields or action commands from service class names. The
  running broker/gateway contract is the source of truth.
- Keep live monitoring in a dedicated feature flow; do not add STOMP state to
  scheduling or audit BLoCs.
- Add `GET /api/scheduling/proctor-assignments/me` so a proctor discovers only
  their own tenant-scoped assignments without sending a user or tenant
  override.
- Publish a typed STOMP-only envelope with `eventId`, `eventType`,
  `sessionPublicId`, `occurredAt`, and `data`. Keep outbox payloads unchanged.
- `COMMAND_ACCEPTED` means queued in the outbox, not completed by
  exam-delivery.
- Reconnect uses bounded exponential backoff, cancels on logout/page disposal,
  re-authenticates, and reloads current REST state before applying new events so
  missed messages do not create a false dashboard.
- Subscription must be scoped to the assigned/authorized session; client topic
  filtering is not a substitute for broker/server authorization.
- A WebSocket package may be added only after compatibility with the pinned
  Dart/Flutter SDK and Windows target is verified.

## Steps

1. Finish and commit the reviewed Phase-9 handoff diff before adding Phase-8
   source so evidence from two phases is not mixed.
2. Add the caller-derived assigned-session query in `scheduling-service` with
   repository/service tests for role, tenant, caller identity, and deterministic
   ordering.
3. Add a focused STOMP destination authorization service in `proctor-service`;
   delegate `SUBSCRIBE` and `SEND` checks from the existing inbound interceptor.
4. Add backend tests for assigned/unassigned Proctor, same/wrong-tenant Admin,
   Host Author denial, inactive session denial, malformed destinations, and
   direct broker-send rejection.
5. Wrap command acceptance and violation broadcasts in a typed live envelope
   without changing their outbox/Kafka events.
6. Add `stomp_dart_client` only after verifying the pinned Dart SDK and Windows
   build. Keep package types behind a project-owned transport interface.
7. Build `live_proctor` as a separate Flutter feature with immutable domain
   models, repository, transport adapter, BLoCs, feature module, Proctor
   workspace, and feature-owned entry page.
8. Route `PROCTOR` to its assigned-session workspace. Add a read-only Live
   Monitoring entry for `HOST_ADMIN`; expose none for `HOST_AUTHOR`.
9. Implement reconnect delays of 1, 2, 4, 8, and 15 seconds, then stable manual
   retry. Subscribe and buffer before loading the REST violation snapshot, then
   merge by event ID.
10. Add confirmations and single-flight protection for force-submit,
    extend-time, and violation commands; never retry mutations automatically.
11. Run focused backend/Flutter tests, full backend package, full Flutter suite,
    analysis, and Windows build.
12. Demonstrate the authorization matrix and one real violation through the
    gateway. If the stack is unavailable, record
    `IMPLEMENTED_AWAITING_RUNTIME_VERIFICATION`.

## Success Criteria

- [x] Unauthorized/unassigned session subscription is denied by the backend,
      not merely hidden by the client.
- [x] Assigned `PROCTOR` controls work only through existing verified commands;
      same-tenant `HOST_ADMIN` is read-only and `HOST_AUTHOR` is denied.
- [x] Proctor assignment discovery derives user and tenant from JWT and returns
      no cross-user or cross-tenant session.
- [x] Live payloads have a typed envelope and do not change outbox/Kafka
      contracts.
- [x] Disconnect/reconnect is bounded, cancelable, and restores authoritative
      current state before applying new deltas.
- [x] Logout/page disposal leaves no active subscription or reconnect timer.
- [ ] Phase-8 tests, all required regressions, analysis, full suite, and Windows
      runtime demonstration pass; otherwise this stretch phase remains
      incomplete without blocking Phase 0–7 delivery.

## Quality and Testing State

- Quality gate: **IMPLEMENTED / AWAITING RUNTIME VERIFICATION**. Destination
  authorization, caller-derived assignments, typed live envelopes, bounded
  reconnect, snapshot recovery, role-gated UI, and confirmation/single-flight
  mutations are implemented. Evidence is recorded at:
  `quality/phase-08-live-proctor-console-quality-report.json`.
- Testing: full backend reactor, Flutter analysis, 308 Flutter tests, and
  focused backend/Flutter tests pass. Windows packaging is blocked by the
  missing Visual Studio toolchain, and no Compose service is running for a real
  authenticated STOMP demonstration. Evidence:
  `tests/phase-08-live-proctor-console-test-report.json`.

## Gate Decision (2026-07-28)

Phase 8 implementation is committed on `hung/feat/host-mini-console`.
The authorization policy is enforced: assigned `PROCTOR` controls,
same-tenant `HOST_ADMIN` observes, and `HOST_AUTHOR` is denied. Automated
gates pass, but the phase remains
`IMPLEMENTED_AWAITING_RUNTIME_VERIFICATION` until the application stack and
Windows build toolchain are available.

## Risks

- **HIGH:** Source code may exist while local broker/gateway WebSocket routing is
  non-operational. Mitigation: runtime proof is Step 12 and remains an open
  completion gate.
- **HIGH:** Session subscription authorization defects could leak live
  cross-tenant data. Mitigation: explicitly test unauthorized assignment at the
  backend connection/subscription boundary.
- **MEDIUM:** Reconnect without state reload can permanently miss transitions.
  Mitigation: restore a REST snapshot before resuming deltas.
- **LOW:** Adding a STOMP dependency increases desktop packaging risk for an
  optional feature. Mitigation: keep the phase stretch-only and dependency
  addition conditional on verified runtime value.
