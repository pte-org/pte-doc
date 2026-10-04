# Phase 01: Migration reconciliation and inbox-foundation verification

**Status:** Completed  
**Priority:** P1  
**Prerequisites:** API branch `e27fa8e` inbox foundation  
**Stories:** P1 notification read/route and mark-read stories

## Design Constraints

- Preflight: Flyway files use `V<number>__description.sql`; existing
  PostgreSQL tests load migrations through `ClassPathResource` and explicitly
  skip when `INBOX_TEST_DB_URL` is absent. `origin/dev` contains the support
  table as `V71`, while the pulled notification chain also starts at `V71`;
  preserve the target branch's applied history and shift only unapplied
  notification versions after verifying the real history.
- Treat the pulled API branch as the inbox implementation baseline. Do not add
  a second inbox entity/store/controller or duplicate read-state semantics.
- Resolve the two current V71 migration files against the applied Flyway
  history before renumbering or adding any migration. A local filename scan is
  not enough to prove which version is deployed.
- Keep the existing inbox foundation separate from `notification_logs`, which
  remains the outbound email audit.
- Reuse the current `InboxController`, `InboxReadService`,
  `InboxAppendService`, `InboxDeliveryStore`, `InboxDeliveryWorker`,
  `InboxRecipientEligibility`, `ApiResponse`, `PagedResult`, and principal
  scoping unchanged unless support integration exposes a precise contract gap.
- Do not implement announcements, email fan-out, push, WebSocket, or unrelated
  trigger families in this feature.

## Implementation steps

1. Confirm the current branch contains the inbox source and that the existing
   read/delivery tests remain the source of truth for the generic contract.
2. Inspect Flyway history/configuration and resolve the duplicate
   `V71__notification_inbox_foundation.sql` / `V71__support_ticket.sql` version
   before any feature migration is added. Update explicit migration fixtures in
   inbox PostgreSQL tests if versions are renumbered.
3. Decide the rollout behavior for `NOTIFICATION_INBOX_ENABLED`, currently
   false by default. The worker must be enabled only after the valid migration
   chain is applied and the worker/read smoke checks pass.
4. Verify that no change is needed to the existing self-scoped endpoints,
   snapshot tokens, read revisions, stream locks, delivery leases, or generic
   idempotency. If a support-specific change is needed, keep it in the
   notification-owned contract and add a regression test.
5. Record the reuse decision and the migration decision in the implementation
   work log before Phase 02 begins.

## Concrete file targets

Expected verification/reconciliation targets:

- `pte-api/app/src/main/resources/db/migration/V71__*.sql` through the latest
  migration and the applied Flyway schema history;
- `pte-api/app/src/main/java/com/pte/notification/InboxNotificationRequested.java`;
- `pte-api/app/src/main/java/com/pte/notification/internal/service/InboxAppendService.java`;
- `pte-api/app/src/main/java/com/pte/notification/internal/service/InboxReadService.java`;
- `pte-api/app/src/main/java/com/pte/notification/internal/service/InboxDeliveryWorker.java`;
- `pte-api/app/src/main/java/com/pte/notification/internal/repository/InboxDeliveryStore.java`;
  and `InboxReadStore`; and
- existing inbox unit/PostgreSQL integration tests and rollout configuration.

Do not modify `NotificationLogController`, `NotificationLogService`, or the
email worker. Do not duplicate inbox tables or endpoint paths.

## Acceptance and tests

- The duplicate V71 migration is resolved against real Flyway history, with no
  destructive rename of an already-applied production version.
- Existing platform-admin/host isolation, snapshot pagination, read-all race,
  delivery lease, retry, and idempotency tests remain green.
- The inbox worker can be enabled in a controlled environment and turns a
  pending intent into a readable item.
- The email-history endpoint and existing notification email tests remain
  unchanged.

## Exit criteria

The current web `inbox.ts` request functions remain compatible with the pulled
API foundation, the migration chain has one unambiguous version per migration,
and the worker rollout/configuration is understood. No new inbox foundation is
created in this feature.

## Quality and Testing State

- Quality: approved. Report:
  `pte-doc/projects/plans/support-feedback-bell-notifications/quality/phase-01-inbox-foundation-quality-report.json`;
  receipt:
  `pte-doc/projects/plans/support-feedback-bell-notifications/quality/phase-01-inbox-foundation-receipt.json`.
- Testing: passed through TDD RED/GREEN. The migration-order test went from
  RED (duplicate V71) to GREEN; the targeted inbox regression run passed 63
  tests with 14 PostgreSQL tests skipped because `INBOX_TEST_DB_URL` was not
  configured. Real database migration behavior remains a validation gap.
