# Phase 4 (Track 1): Real-Time Proctor Alert Delivery

**Track:** 1 — Exam Integrity & Anti-Cheat
**Covers:** FR-11 · User story: P1 (proctor real-time alert)
**Depends on:** Track 4 Phase 1 (audit log — this phase reads from it), Track 1 Phases 2-3 (event producers).

---

## Design Constraints

- **Short-poll (2s interval), not WebSocket** — decision from research synthesis: simpler to operate for a 4-person team, no mobile background-lifecycle concerns since the proctor dashboard is web-only (Next.js). Meets the 2s alert target.
- Endpoint: `GET /api/admin/exam-sessions?since=<timestamp>` — returns new anti-cheat/multi-device events since the given timestamp, scoped to exams the proctor is authorized to monitor.
- If polling latency proves insufficient once real proctors use it, the upgrade path is WebSocket (`@EnableWebSocketMessageBroker`/STOMP) — note this explicitly in code comments/README so a future phase doesn't have to rediscover the tradeoff.
- Only `MULTI_DEVICE_BLOCKED` and `TAMPER_ATTEMPT` events should surface as high-priority proctor alerts; `BLUR_EVENT` can be lower-priority/informational (avoid alert fatigue from ordinary tab switches).

## Files to Touch

- `aptis-api/src/main/java/com/aptis/modules/examdelivery/controller/` — new `ProctorController` with `GET /api/admin/exam-sessions`.
- `aptis-api/src/main/java/com/aptis/common/audit/AuditLogRepository.java` — add query method `findByCreatedAtAfterAndEventTypeIn(...)`.
- `aptis-web/apps/vendor-web/` (or wherever proctor/admin UI lives) — new `ProctorDashboard` component polling the endpoint every 2s, rendering alerts by priority.

## Implementation Steps

1. Implement `GET /api/admin/exam-sessions?since=<timestamp>` returning new audit events (filtered to alert-worthy types) for exams the authenticated proctor/admin can see.
2. Add authorization check — proctor can only see sessions for exams/tenants they're scoped to.
3. Build the Next.js polling hook (2s interval via `setInterval` or TanStack Query's `refetchInterval`), rendering `MULTI_DEVICE_BLOCKED`/`TAMPER_ATTEMPT` as high-priority, `BLUR_EVENT` as informational.
4. Add a manual "acknowledge" action for proctors reviewing an alert (optional, P2 — don't block phase completion on this).
5. Tests: endpoint returns only new events since the given timestamp; unauthorized proctor cannot see other tenants' events; end-to-end timing test confirms alert visible within 2s of the triggering event.

## Acceptance Criteria

- [ ] Proctor dashboard receives a multi-device/anti-cheat alert within 2s of server-side detection, verified by test.
- [ ] Proctor cannot see events for exams/tenants outside their scope.
- [ ] Maps to spec success criterion: "Proctor dashboard receives a multi-device/anti-cheat alert within 2s of server-side detection, verified by test."

## Quality and Testing State

- Quality: not evaluated
- Testing: not started
