# Phase 03: Web contract, filters, and support-ticket routing

**Status:** Completed  
**Priority:** P1  
**Prerequisites:** Phases 01-02 API contract  
**Stories:** P1 authorized target navigation and read state; P2 support context

## Design Constraints

- Preflight: the web branch remains clean at `quang/feat/notifiction` /
  `1a61bf7`; both notification centers already use the shared inbox requests,
  30-second visible-tab polling, focus refresh, protected-cache clearing, and
  read-state invalidation. The current api-client unions do not yet accept
  `SUPPORT`, the three support notification types, or `SUPPORT_TICKET`, while
  the four portal components have local target maps that need one support case
  each. No app-level route-test harness is present, so route behavior remains a
  Phase 04 browser-validation item.
- Reuse `@pte/api-client` request transport, response types, `ApiError`, and
  existing notification hooks. Do not add direct `fetch`, token parsing, or a
  second notification query layer.
- Preserve the current 30-second visible-tab unread polling, focus refresh,
  protected-cache clearing on 401, mark-one-read, and mark-all behavior.
- Tenant and vendor routes differ and must stay in their owning applications.
  A client-side route map is only navigation; backend ticket authorization
  remains authoritative.
- Do not add a support-specific notification page. The existing generic detail
  route remains the safe fallback for unknown target types.
- Keep the current support-ticket CRUD/status UI unchanged except for copy that
  incorrectly describes admin notes as private when the tenant API exposes
  those notes.

## Implementation steps

1. Extend `pte-web/packages/api-client/src/types/notification/index.ts`:
   - `InboxCategory` with `SUPPORT`;
   - `InboxNotificationType` with
     `SUPPORT_TICKET_SUBMITTED`, `SUPPORT_TICKET_NOTE_ADDED`, and
     `SUPPORT_TICKET_STATUS_CHANGED`; and
   - `InboxTargetType` with `SUPPORT_TICKET`.
2. Add `SUPPORT` to the category filter options in both notification history
   views so a support-only history query is visible and typed.
3. Add target mapping to both bell containers and both history views:
   - tenant: `/host/support-tickets/${targetPublicId}`;
   - vendor: `/admin/support-tickets/${targetPublicId}`.
4. Keep notification detail read behavior unchanged. Selecting a support item
   marks only that user's item read, then navigates to the authorized support
   detail page.
5. Correct the vendor admin note placeholder/copy to reflect that current
   notes are visible to the tenant. Do not change note visibility or backend
   permissions in this phase.
6. Extend the existing API-client inbox tests to cover `SUPPORT` query encoding
   and keep request paths/methods unchanged. If an app-level test harness is
   introduced, unit-test both target maps; otherwise validate them through the
   browser acceptance flow in Phase 04.

## Concrete file targets

- `pte-web/packages/api-client/src/types/notification/index.ts`;
- `pte-web/packages/api-client/src/requests/notification/inbox.test.ts`;
- `pte-web/apps/tenant-web/features/notifications/components/NotificationBellContainer.tsx`;
- `pte-web/apps/tenant-web/features/notifications/components/NotificationHistoryView.tsx`;
- `pte-web/apps/vendor-web/features/notifications/components/NotificationBellContainer.tsx`;
- `pte-web/apps/vendor-web/features/notifications/components/NotificationHistoryView.tsx`;
- `pte-web/apps/vendor-web/features/supportTickets/constants/index.ts`; and
- relevant request/type barrel files only if TypeScript compilation requires it.

## Acceptance and tests

- TypeScript accepts the backend support notification values in both apps.
- The category selector can request `SUPPORT` without unsafe casts beyond the
  existing union boundary.
- Clicking a tenant support notification goes to the tenant ticket detail
  route; clicking a vendor support notification goes to the admin detail route.
- Clicking an unread item marks only the current user's item read and updates
  the existing bell count through query invalidation.
- Mark-all and visible-tab polling continue to work for support items.
- A user cannot use the UI target to bypass backend ticket authorization.

## Exit criteria

The current web bell can display support inbox items returned by the backend,
filter them as `SUPPORT`, and route them to the correct existing feedback
detail page in both portals without changing polling behavior.

## Quality and Testing State

- Quality: approved. Report:
  `pte-doc/projects/plans/support-feedback-bell-notifications/quality/phase-03-web-contract-and-routing-quality-report.json`;
  receipt:
  `pte-doc/projects/plans/support-feedback-bell-notifications/quality/phase-03-web-contract-and-routing-receipt.json`.
  One advisory remains open for Phase 04 browser validation because the
  repository has no app-level notification component test harness.
- Testing: passed through TDD RED/GREEN. The support contract test passed 3/3;
  api-client, tenant-web, and vendor-web typechecks passed; both production
  builds passed and generated the tenant/admin support-ticket routes. The full
  api-client package suite still has four out-of-scope endpoint-segment
  failures in `src/requests/endpoints.test.ts`; these are recorded in the
  Phase 03 test report and were not touched by this phase.
