# Phase 8: Live Proctor Console (Stretch)

## Requirements

Verify and expose the existing proctor WebSocket/STOMP path as a live,
session-scoped Host/proctor monitoring console only after all required Phase
0–7 capabilities pass.

Maps to: **P3 Story #9 (live proctor console) | Stretch scope**

## Design Constraints

- This phase is optional and cannot block the required Member 3 handoff.
- Inspect and runtime-verify the existing gateway upgrade route, endpoint,
  destination/topic names, JWT handshake method, session assignment checks, and
  event payload before writing Flutter transport code.
- Do not invent event fields or action commands from service class names. The
  running broker/gateway contract is the source of truth.
- Keep live monitoring in a dedicated feature flow; do not add STOMP state to
  scheduling or audit BLoCs.
- The initial console is read-only unless existing, verified backend commands
  are separately approved. No force-submit/extend/broadcast UI is inferred from
  “proctor console.”
- Reconnect uses bounded exponential backoff, cancels on logout/page disposal,
  re-authenticates, and reloads current REST state before applying new events so
  missed messages do not create a false dashboard.
- Subscription must be scoped to the assigned/authorized session; client topic
  filtering is not a substitute for broker/server authorization.
- A WebSocket package may be added only after compatibility with the pinned
  Dart/Flutter SDK and Windows target is verified.

## Steps

1. Inspect proctor WebSocket configuration, security interceptors, destinations,
   event DTOs, gateway routing, and assignment validation in `pte-api/main`.
2. Start the required local gateway/proctor/broker dependencies and capture a
   successful authenticated connection/subscription plus one real event; if this
   cannot be reproduced, record the block and end the stretch phase without
   speculative Flutter code.
3. Select the smallest compatible STOMP/WebSocket dependency only after the
   runtime contract is confirmed; record dependency rationale and Windows
   compatibility.
4. Define immutable live-proctor event/status domain types and a transport
   interface independent of the selected package.
5. Implement authenticated connect, session-scoped subscribe, payload mapping,
   disconnect, bounded reconnect, and cancellation.
6. Build a live-proctor BLoC with disconnected/connecting/connected/reconnecting/
   failure states and deterministic event-to-view-state reduction.
7. Build a read-only dashboard for verified backend fields only, with connection
   status, retry, session identity, and current monitored entities.
8. On reconnect, reload current authoritative REST state before consuming the
   resumed stream; test missed-event recovery and duplicate-event handling.
9. Add transport unit tests with a fake client, BLoC/widget tests, logout/dispose
   cancellation tests, and an authenticated runtime event demonstration.
10. Run all required Host regressions, analysis, full suite, and Windows live
    connection verification.

## Success Criteria

- [ ] Runtime gateway/proctor STOMP connection and one real authorized
      session-scoped event are demonstrated before Flutter implementation.
- [ ] Unauthorized/unassigned session subscription is denied by the backend,
      not merely hidden by the client.
- [ ] Dashboard reflects only verified event fields and exposes no unapproved
      mutation actions.
- [ ] Disconnect/reconnect is bounded, cancelable, and restores authoritative
      current state before applying new deltas.
- [ ] Logout/page disposal leaves no active subscription or reconnect timer.
- [ ] Phase-8 tests, all required regressions, analysis, full suite, and Windows
      runtime demonstration pass; otherwise this stretch phase remains
      incomplete without blocking Phase 0–7 delivery.

## Quality and Testing State

- Quality gate: not run. Planned report:
  `quality/phase-08-live-proctor-console-quality-report.json`.
- Testing: not run. Planned evidence:
  `tests/phase-08-live-proctor-console-test-report.json`, with runtime proof
  required before feature completion.

## Risks

- **HIGH:** Source code may exist while local broker/gateway WebSocket routing is
  non-operational. Mitigation: runtime proof is Step 2 and a hard prerequisite.
- **HIGH:** Session subscription authorization defects could leak live
  cross-tenant data. Mitigation: explicitly test unauthorized assignment at the
  backend connection/subscription boundary.
- **MEDIUM:** Reconnect without state reload can permanently miss transitions.
  Mitigation: restore a REST snapshot before resuming deltas.
- **LOW:** Adding a STOMP dependency increases desktop packaging risk for an
  optional feature. Mitigation: keep the phase stretch-only and dependency
  addition conditional on verified runtime value.
