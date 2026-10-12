# Phase 04: Proctor roster, writes and reconciliation

Status pending; dependencies01–03. P1 per-student attendance; P2 filter/history. FR02–05,07–12.

## Design Constraints

No optimistic saved state, no automatic replay, no inference from attempts/heartbeat. Retain unknown command by tenant/session/enrollment/student, not the selected row. Shared UI primitives, feature messages, files<300/component<150 lines.

## Files and steps

- [x] Add exact attendance types/requests to packages/api-client following existing session/proctoring request exports; no adapter mismatch. Hook API in features/proctor/api.ts or attendance/api.ts, messages/vi.ts/en.ts and focused attendance components/hooks under features/proctor.
- [x] Cache key includes tenant+actor+role surface+session+filter/search/page; retain prefix invalidation. Disable requests until identity/permission ready; logout clears/cancels actor data. No previous-actor placeholder data. Mutation success/reconciliation invalidates roster/full summary/history and relevant Host view if observed.
- [x] Roster page: counts from whole roster, search/status/page URL state, row attendance and separate activity, server capability/block reason and time. No attempt stays visible. Page shrink clamps URL. Loading/errors never render false zeros; list and summary maintain explicitly coherent response context.
- [x] Action preflight captures student/enrollment/version/status/reason/note and request UUID; initial attendance note optional, correction/reset reason mandatory. ABSENT with known exam activity shows explicit discrepancy confirmation; never ends attempt. Same-status buttons disabled or treated as no-op result, not history spam.
- [x] Recheck row target/version/capability before confirmation; if dialog invalidates, require reread/reconfirm. No changing target through selected-row state while a frozen dialog remains open.
- [x] Handle definitive409 stale/membership change with authorized refresh and explicit re-review; denied scope stops writes. Unknown network outcome retains original payload/key; read receipt/current state, compare exact request identity, then offer only identical retry. A different newer attendance change is shown as current state, never as proof of the pending command succeeding.
- [x] Row navigation/filter changes do not erase unknown requests or unlock conflicting edits; pending state survives within mounted workspace. Leave warning covers drafts/unresolved commands and app-managed Back. No durable offline-write queue; refresh/reload recovery reads server receipts/history as available.
- [x] Manual/focus refresh; date window uses server capability and refresh at opensAt-30m/closesAt boundary while visible, defer hidden refresh to focus. No browser-clock permission, extra sockets or continuous polling. History dialog/page paginated with actor/time/reason and transition before/after.

## Acceptance evidence

Zero-attempt student,101-row roster/search beyond first page, initial absent without reason, correction/reset with reason, dialog stale rejection, timeout→row change→return retains lock, identical receipt/current distinction, two-proctor stale conflict, browser-local dates with server timing, account switch no old data.

## Quality and Testing State

Quality not evaluated; testing not started; prior skip. API-client/tenant TypeScript and scoped lint/build planned. Browser scenarios remain acceptance cases, not executed tests.
