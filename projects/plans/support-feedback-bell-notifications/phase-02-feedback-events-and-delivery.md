# Phase 02: Support types, events, recipients, and durable delivery intents

**Status:** Completed  
**Priority:** P1  
**Prerequisites:** Phase 01 migration/foundation verification  
**Stories:** P1 submitted/note/status notifications; P2 contextual copy

## Design Constraints

- Preflight: support services publish public records through
  `ApplicationEventPublisher`; notification listeners consume module events
  with `BEFORE_COMMIT` and append through `InboxAppendService`. Existing
  listeners fan out through `IdentityService` role projections and use
  `InboxConstants` for copy/event limits. Support tests construct
  `SupportTicketService` directly, so its new publisher dependency must be
  wired into those fixtures without changing domain behavior.
- Support owns ticket transitions; notification owns inbox persistence and copy.
  Support must not import notification internals.
- Events are public source-module contracts under the support public package.
  Notification may consume those contracts through a listener.
- The listener uses `BEFORE_COMMIT` with fallback execution disabled and calls
  the existing `InboxAppendService` with an `InboxNotificationRequested`.
  The source transaction durably stores content and delivery intent; the
  existing worker materializes inbox items after commit and retries failures.
- A failure while creating the intent rolls back the support mutation. A worker
  failure after commit does not roll back the support mutation; it remains
  recoverable through the existing delivery lease/retry path.
- Notification text contains category/status context only. Do not put the raw
  ticket description, note content, admin email, or tenant name in the bell
  body.
- Reuse `IdentityService.findActiveRoleMembers(Role.PLATFORM_ADMIN)` and its
  `IdentityRoleMember` projection. Do not add a second identity lookup or query
  `UserRepository` from notification.

## Implementation steps

1. Extend the existing notification enums and request validation:
   - `InboxNotificationType` with `SUPPORT_TICKET_SUBMITTED`,
     `SUPPORT_TICKET_NOTE_ADDED`, and `SUPPORT_TICKET_STATUS_CHANGED`;
   - `InboxCategory` with `SUPPORT`; and
   - `InboxTargetType` with `SUPPORT_TICKET`.
   Update `InboxNotificationRequested.validMapping` and its platform-vs-host
   recipient scope rule. A submitted support event accepts null-tenant platform
   recipients; note/status events require the submitter's tenant scope.
2. Add a migration after the reconciled inbox chain to widen the database check
   constraints for the three support types, `SUPPORT`, and `SUPPORT_TICKET`.
   Do not edit an already-applied V71 migration in place.
3. Add public support event records, for example:
   - `SupportTicketSubmittedEvent(ticketPublicId, tenantId,
      submitterUserPublicId, category)`;
   - `SupportTicketNoteAddedEvent(ticketPublicId, tenantId,
     submitterUserPublicId, notePublicId, category)`; and
   - `SupportTicketStatusChangedEvent(ticketPublicId, tenantId,
     submitterUserPublicId, category, previousStatus, newStatus)`.
4. Inject `ApplicationEventPublisher` into `SupportTicketService` and publish:
   - after the ticket is saved and before the submit transaction returns;
   - after a note is saved, using the persisted note public ID; and
   - after a valid status method changes the domain status, capturing the old
     status before mutation.
   Do not publish on validation failure, invalid transition, or a path that
   throws before the source transaction can commit.
5. Add a support notification listener that maps each event to a safe immutable
   `InboxNotificationRequested` and calls the existing `InboxAppendService`.
   The generic inbox request listener/store/worker remains unchanged.
6. Map each event to a safe immutable copy:

   | Event | Title/body policy |
   | --- | --- |
   | Submitted | Tell admins that new feedback was received and include the category |
   | Note added | Tell the submitter an admin responded and include the category |
   | Status changed | Tell the submitter the new status and include the category |

7. Use these event keys:
   - `support-ticket:{ticketPublicId}:submitted`;
   - `support-ticket:{ticketPublicId}:note:{notePublicId}`; and
   - `support-ticket:{ticketPublicId}:status:{previous}:{next}`.
   Create one request per logical event with target type `SUPPORT_TICKET`, target
   public ID equal to the ticket public ID, category `SUPPORT`, and the matching
   notification type. Let the existing content payload hash and delivery
   uniqueness enforce replay safety.
8. Fan out submission events to every active platform admin from
   `findActiveRoleMembers(Role.PLATFORM_ADMIN)`, filtered to `tenantId == null`,
   in deterministic public-ID order. Request note/status delivery only for the
   submitter with the ticket tenant ID. A missing or no-longer-eligible
   recipient must not redirect the item to another user; the existing worker
   suppresses ineligible deliveries.
9. Update `InboxRecipientEligibility` so support submission uses the platform
   admin/null-tenant path while support note/status use the active tenant
   host-admin path.
10. Preserve the existing audit records and support response payloads. The
   notification listener must not change ticket status rules, tenant scoping,
   note visibility, or entity-reference validation.

## Concrete file targets

- `pte-api/app/src/main/java/com/pte/support/dto/event/SupportTicket*Event.java`;
- `pte-api/app/src/main/java/com/pte/support/internal/service/SupportTicketService.java`;
- `pte-api/app/src/main/java/com/pte/notification/domain/enums/InboxNotificationType.java`;
- `pte-api/app/src/main/java/com/pte/notification/domain/enums/InboxCategory.java`;
- `pte-api/app/src/main/java/com/pte/notification/domain/enums/InboxTargetType.java`;
- `pte-api/app/src/main/java/com/pte/notification/InboxNotificationRequested.java`;
- `pte-api/app/src/main/java/com/pte/notification/internal/service/InboxRecipientEligibility.java`;
- `pte-api/app/src/main/java/com/pte/notification/internal/listener/SupportTicketInboxNotificationListener.java`;
- `pte-api/app/src/main/resources/db/migration/V76__support_feedback_inbox.sql`
  or the next version if applied-history verification requires a different
  release-safe number;
- notification copy/constants and existing append-service contracts; and
- existing support, inbox-request, eligibility, delivery-store, and new
  notification listener/service tests.

## Acceptance and tests

- A committed submission creates one durable content/delivery intent for every
  active platform admin and no intent for the submitter or unrelated tenant
  users.
- A committed note creates one durable intent for the submitter and no intent
  for other hosts, platform admins, or other tenants.
- Each valid status transition creates one submitter intent; invalid
  transitions create none.
- Replaying the same logical event cannot create duplicate content or delivery
  records, while two distinct notes and the two valid transitions each create
  their own event key.
- A rolled-back submit/note/status transaction leaves no inbox content or
  delivery intent.
- A worker-disabled or worker-failed delivery remains observable as pending or
  retryable intent and does not create a false read item.
- Existing support audit events, response data, and ticket authorization tests
  continue to pass.

## Exit criteria

All three support event families are source-owned, transaction-bound, recipient
scoped, and idempotent. The backend can create durable intents that the
existing worker materializes into inbox rows whose target and contract values
are understood by the current web client after Phase 03.

## Quality and Testing State

- Quality: approved. Report:
  `pte-doc/projects/plans/support-feedback-bell-notifications/quality/phase-02-feedback-events-and-delivery-quality-report.json`;
  receipt:
  `pte-doc/projects/plans/support-feedback-bell-notifications/quality/phase-02-feedback-events-and-delivery-receipt.json`.
- Testing: passed through TDD RED/GREEN. Support contract, listener recipient
  scope, service publication, migration-content, and inbox regression tests
  passed 86/86 with no skips. Real PostgreSQL transaction/fan-out behavior is
  deferred to Phase 04.
