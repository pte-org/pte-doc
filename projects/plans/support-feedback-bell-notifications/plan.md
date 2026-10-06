# Plan: Support feedback bell notifications

Status: Phase 04 partially verified; authenticated/runtime handoff blocked
Date: 2026-10-04
Mode: Hard
Scope: `pte-api` + `pte-web` + `pte-doc`
Spec: [spec.md](spec.md)
Test mode: Default in this plan; `--tdd` is recommended for cook
Created by: Codex

## Scope challenge

### Exists?

The support-ticket workflow already exists in both portals and in the
modular-monolith backend. The web bell already calls the
`/api/v1/notification-inbox` contract. The newly pulled API branch now contains
the inbox foundation, read API, delivery-intent store, worker, and generic
notification request contract. It still has no support-ticket notification
types or support event listener. Outbound email history remains separate in
`notification_logs` and `/api/v1/notifications`.

### Minimum implementation

Reuse the existing inbox capability and implement only the missing feedback
integration:

1. reconcile the duplicate Flyway V71 migration before adding new migrations;
2. add three support notification types, the support category, and support-ticket target mapping;
3. publish support events and map them to the existing durable inbox intent;
4. notify platform admins on submission and the submitter on note/status changes; and
5. add support target/type/category mappings in the two portals.

Announcements, email delivery, push/WebSocket delivery, assignment, tenant
replies, session reminders, commercial triggers, and the rest of the older
tenant/admin notification proposal remain out of scope.

### Complexity

**Hard.** This crosses the notification, identity, support, database,
api-client, tenant-web, and vendor-web boundaries. It also needs recipient
isolation, transaction consistency, database idempotency, and read-all
concurrency semantics.

## Current baseline and research

Two research tracks were compared:

### Primary: reuse the existing inbox contract and notification ownership

- `pte-web/packages/api-client/src/requests/notification/inbox.ts` already
  defines list, unread-count, detail, read, and read-all calls.
- Both portal adapters already poll unread count every 30 seconds while the tab
  is visible and scope React Query keys by user and tenant.
- `pte-web/packages/api-client/src/types/notification/index.ts` already models
  snapshot tokens, stream sequence numbers, read revisions, and typed targets.
- `pte-api` now has `InboxController`, `InboxReadService`,
  `InboxAppendService`, `InboxRequestListener`, `InboxDeliveryStore`,
  `InboxRecipientEligibility`, `V71__support_ticket.sql`, and the notification
  migrations currently numbered V71-V74.
- The pulled tree has two V71 migrations. Phase 01 preserves the support
  migration from `dev` at V71 and shifts the notification chain to V72-V75;
  any real applied-history mismatch remains a release-blocking verification.
- The existing `pte-doc/projects/plans/quang-tenant-admin-notifications`
  blueprint remains useful as architecture context, but the current API source
  is now the implementation baseline.

**Verdict:** reuse the notification-owned inbox foundation already present in
the pulled API branch, reconcile its migration chain, and add feedback as a
source-module event. Keep the frontend contract stable.

### Alternative: frontend-only, email-log reuse, or direct support-to-email coupling

- A frontend-only toast/cache update misses actions made in another browser and
  can display a notification for a rolled-back mutation.
- `notification_logs` has email delivery state, not per-user unread/read state,
  bell targets, stream ordering, or read-all semantics.
- Calling notification internals directly from `SupportTicketService` would
  couple source business logic to notification persistence and make event
  idempotency/ownership harder to enforce.

**Verdict:** reject all three. Support publishes public events; notification
consumes them through its own listener and append service.

## Selected architecture

1. Keep `NotificationLog`, `NotificationDispatchService`, RabbitMQ email jobs,
   and `/api/v1/notifications` unchanged.
2. Reuse the current `InboxNotificationRequested` contract,
   `InboxAppendService`, `InboxDeliveryStore`, `InboxDeliveryWorker`, and
   `InboxReadService`. Do not create a second inbox store or API.
3. Use `ApplicationEventPublisher` in `SupportTicketService` and public event
   records under `com.pte.support.dto.event`.
4. Consume support events with a support-owned
   `@TransactionalEventListener(phase = BEFORE_COMMIT,
   fallbackExecution = false)` that creates an `InboxNotificationRequested`
   and calls the existing append service. The source transaction durably stores
   the delivery intent; the worker later materializes the recipient item and
   retries failed delivery.
5. Resolve recipients through the existing `IdentityService` public role
   projections. New feedback fans out to active, non-deleted
   `PLATFORM_ADMIN` users with `tenantId IS NULL`; notes and status changes
   target only the ticket submitter.
6. Extend the existing typed mapping and recipient eligibility rules for the
   support event families. Use allowlisted `SUPPORT_TICKET` targets and route them in each portal:
   `/admin/support-tickets/{publicId}` for vendor admin and
   `/host/support-tickets/{publicId}` for tenant host.
7. Use safe generic notification copy. Include category/status context, but do
   not copy raw descriptions or admin-note content into the bell body.

## Feedback event and recipient matrix

| Event key | Source condition | Recipient | Type/category | Target |
| --- | --- | --- | --- | --- |
| `support-ticket:{ticket}:submitted` | Ticket save succeeds in the source transaction | Every active `PLATFORM_ADMIN` | `SUPPORT_TICKET_SUBMITTED` / `SUPPORT` | Ticket public ID |
| `support-ticket:{ticket}:note:{note}` | Note save succeeds | Ticket submitter only | `SUPPORT_TICKET_NOTE_ADDED` / `SUPPORT` | Ticket public ID |
| `support-ticket:{ticket}:status:{from}:{to}` | `OPEN -> IN_PROGRESS` or `IN_PROGRESS -> RESOLVED` succeeds | Ticket submitter only | `SUPPORT_TICKET_STATUS_CHANGED` / `SUPPORT` | Ticket public ID |

All feedback notifications use `INFO` importance initially. Copy should remain
English and safe until the project has a localized notification-copy policy.

## Phase dependency graph

| Phase | Scope | Prerequisite | Stories |
| --- | --- | --- | --- |
| 01 | Migration reconciliation and inbox-foundation verification | Current API inbox foundation | P1 read/route and worker prerequisites |
| 02 | Support types, events, recipients, and durable delivery intents | 01 | P1 submitted/note/status stories; P2 copy |
| 03 | API-client unions, filters, and portal target routing | 01, 02 contracts | P1 route story; P2 copy |
| 04 | Worker rollout, regression, browser, and deployment-boundary validation | 01-03 | All P1/P2 success criteria |

## Cross-cutting design constraints

- Use `ApiResponse`, `PagedResult`, `PageMeta`, `CurrentUserContext`, existing
  `GlobalExceptionHandler`, and existing `ApiClient`; do not create parallel
  envelopes, auth, error, or transport layers.
- Notification list/count/detail/read operations are bound to the authenticated
  user ID. A platform admin's null tenant must never mean "all platform inboxes".
  A host query must bind the authenticated tenant.
- Foreign or missing inbox items must not reveal whether another user owns the
  item. Preserve the existing 401/403/404 handling conventions.
- Page size is capped at 100; default list size is 20 and bell size is 5.
  `UNREAD` membership remains live while an `ALL` page uses its server snapshot.
- The read-all operation locks the recipient stream, captures a committed
  watermark, and updates only that recipient's rows at or below the watermark.
  New arrivals must remain unread.
- Existing notification storage owns idempotency: `event_key` and payload hash
  identify one immutable content event, while `(content_public_id,
  recipient_user_public_id)` deduplicates each delivery. Do not add a second
  support-specific uniqueness scheme.
- `deliveredAt` is assigned when the existing worker materializes the inbox
  item, not when the support transaction creates the delivery intent.
- No notification body may contain credentials, tokens, signed URLs, raw
  exception text, or unrelated tenant content.
- Keep all changes uncommitted. Do not dispatch production deployment or change
  the existing email behavior as part of this plan.

## Red-team review

The plan was checked against the current branches and the existing broader
notification blueprint. Findings and dispositions:

| Finding | Disposition |
| --- | --- |
| Historical blueprint assumes V71/V72 inbox migrations | Resolved locally by preserving dev's V71 support migration and shifting the notification chain to V72-V75; applied-history verification remains required |
| Existing web bell has no backend implementation on this branch | Resolved by the pulled API branch; Phase 01 verifies the existing foundation |
| `PLATFORM_ADMIN` users have null tenant IDs | Accepted; identity query and every inbox query bind recipient ID separately from ticket tenant scope |
| `notification_logs` looks reusable by name | Rejected; it is email delivery history and has no read/target semantics |
| AFTER_COMMIT-only delivery can lose a notification after a source commit | Rejected; the existing foundation stores intent in BEFORE_COMMIT and retries item delivery through its worker |
| Raw feedback/note text could leak secrets into the bell | Accepted; notification copy uses category/status and directs the user to the authorized ticket detail |
| The current admin note placeholder says notes are admin-only | Accepted as a small Phase 03 copy correction because the tenant API already exposes notes |

## Verification boundary

The plan is based on source inspection plus targeted API/web verification. API
Phase 01-02 implementation and tests are present in commits `3d7d069` and
`1d26664` on `quang/feat/notifiaction`; the API repo now has three uncommitted
Phase 04 boundary fixes (support named interfaces and module inventory test).
Web Phase 03 implementation is on `quang/feat/notifiction` at `874cb88`; Phase 04 also
corrects the endpoint regression guard so the valid `/api/v1/admin/...`
namespace is not treated as a retired service segment. The current Phase 04
receipt records successful Java 21/PostgreSQL migration and transaction
checks, targeted backend checks, and complete web package gates. The full
backend suite still has the known assessment/attempt baseline failures;
authenticated browser CRUD and a controlled worker-enabled runtime remain
unverified.

## Resolved execution decisions

- Use the existing hybrid durability model: failure while appending the intent
  rolls back the source transaction; failure after commit is retried by the
  existing inbox worker. The worker must be enabled for the item to reach the
  bell.
- Use safe category/status copy only. The ticket detail page remains the place
  to read the full description or note.
- Keep support notifications at `INFO` for the normal bell MVP.

## Handoff

Recommended execution command for the implementation handoff:

```text
/ck:cook --hard --tdd pte-doc/projects/plans/support-feedback-bell-notifications/plan.md
```
