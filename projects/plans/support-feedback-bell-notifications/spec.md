# Spec: Support feedback bell notifications

Status: Ready
Date: 2026-10-04
Created by: Codex

---

## Problem Statement

Tenants can submit support feedback and platform admins can change its status
or add notes, but neither side receives an in-app signal when the other side
acts. Users must manually reopen or refresh the support-ticket page to discover
changes. This feature adds durable, bell-based notifications for the existing
feedback lifecycle without introducing email or push delivery.

---

## User Stories

- **[P1]** As a platform admin, I want to receive a bell notification when a
  tenant submits feedback so that new tickets are visible without polling the
  support-ticket list manually.
  Accepted when: every eligible `PLATFORM_ADMIN` receives one unread
  notification for a committed new ticket, with a link to the admin ticket
  detail route.

- **[P1]** As a tenant feedback submitter, I want to receive a bell notification
  when an admin adds a note so that I can see the response without reopening
  the ticket repeatedly.
  Accepted when: only the ticket submitter receives one unread notification for
  the committed note, with a link to the tenant ticket detail route.

- **[P1]** As a tenant feedback submitter, I want to receive a bell notification
  when an admin changes ticket status so that I know when the issue is being
  processed or resolved.
  Accepted when: a committed `OPEN -> IN_PROGRESS` or
  `IN_PROGRESS -> RESOLVED` transition creates one unread notification for the
  submitter and identifies the new status.

- **[P1]** As a notification recipient, I want to click the notification and
  open the authorized support-ticket detail page so that I can act on the
  feedback immediately.
  Accepted when: admin notifications route to
  `/admin/support-tickets/{publicId}`, tenant notifications route to
  `/host/support-tickets/{publicId}`, and backend authorization remains
  enforced.

- **[P1]** As a notification recipient, I want to mark a feedback notification
  read or mark all notifications read so that the bell count reflects my work.
  Accepted when: read mutations update the recipient's unread count and do not
  alter another user's or tenant's notification state.

- **[P2]** As a recipient, I want notification text to include the feedback
  category and relevant status/note context so that I can triage the item from
  the bell before opening it.
  Accepted when: the title and body contain no credentials or unrelated tenant
  data and identify the support-ticket action.

- **[P3]** _(out of scope — noted for future)_ Email, browser push, WebSocket
  delivery, ticket assignment, tenant replies, and private admin-only notes.

---

## Functional Requirements

1. **FR-01:** After a support ticket is committed, publish a support-ticket
   submitted event containing the ticket public ID, tenant ID, submitter user
   public ID, category, and description summary.
2. **FR-02:** Deliver the submitted-ticket notification to every active
   `PLATFORM_ADMIN` user exactly once per ticket event.
3. **FR-03:** After an admin note is committed, publish a note-added event and
   deliver it only to the ticket submitter.
4. **FR-04:** After a valid admin status transition is committed, publish a
   status-changed event and deliver it only to the ticket submitter. Invalid or
   rolled-back transitions must not create notifications.
5. **FR-05:** Store in-app notifications with recipient user ID, tenant scope,
   notification type, category, title, body, target type `SUPPORT_TICKET`,
   target ticket public ID, creation/delivery time, read time, and an event
   deduplication key.
6. **FR-06:** Extend the notification API contract with support-ticket event
   types, the `SUPPORT` category, and the `SUPPORT_TICKET` target type.
7. **FR-07:** Extend both tenant and vendor bell target mapping to open the
   correct support-ticket detail route based on the recipient application.
8. **FR-08:** Keep notification reads user-scoped. Tenant ticket detail access
   must remain tenant-scoped, and admin ticket access must remain restricted to
   `PLATFORM_ADMIN`.
9. **FR-09:** Use the existing bell's unread/list/read-all behavior and visible
   tab polling. No email, push, or WebSocket channel is required for this MVP.
10. **FR-10:** Notification creation must occur after the support mutation is
    durable, or use an equivalent transactional/outbox guarantee, so a failed
    support mutation never produces a false notification.
11. **FR-11:** Notification retry must be idempotent per event key while still
    allowing separate notifications for later status changes and separate admin
    notes on the same ticket.
12. **FR-12:** Notification bodies must not include passwords, access tokens,
    or cross-tenant data. Feedback descriptions and note content must be
    limited to the authorized recipient scope.

---

## Non-Functional Requirements

- **Performance:** For a visible authenticated session, the existing bell
  polling must issue no more than one unread-count request per 30 seconds; the
  notification list/read endpoints should target p95 latency below 500 ms in
  the normal local/hosted deployment profile.
- **Security:** 100% of notification reads and mutations must be authorized by
  recipient identity and role on the backend; UI route guards are not the sole
  control.
- **Consistency:** A committed feedback action produces its notification within
  one polling interval (30 seconds) for a visible bell session and is available
  on the next authenticated inbox query after reconnect.
- **Reliability:** Retried event handling must not create duplicate unread rows
  for the same recipient and event key.

---

## Success Criteria

- [ ] New committed feedback creates exactly one unread notification for each
      active platform admin and zero notifications for unrelated tenant users.
- [ ] A committed admin note creates exactly one unread notification for the
      ticket submitter and opens the tenant ticket detail route from the bell.
- [ ] Each valid status transition creates exactly one submitter notification;
      invalid/rolled-back transitions create none.
- [ ] Bell unread count and mark-read/mark-all-read behavior pass for both
      tenant and vendor notification consumers.
- [ ] Backend tests cover recipient scoping, event idempotency, transaction
      failure behavior, and all three support event types.
- [ ] API-client tests cover support notification endpoint/type mappings, and
      tenant/vendor typecheck passes with no notification contract errors.

---

## Out of Scope

- Email or SMTP notifications.
- Browser push notifications or WebSocket/STOMP delivery.
- Ticket assignment, escalation, SLA reminders, or admin team routing.
- Tenant-authored replies after ticket submission.
- Private admin notes; all current admin notes remain tenant-visible.
- Replacing the existing support-ticket CRUD/status workflow.

---

## Assumptions

- `PLATFORM_ADMIN` is the recipient group for new feedback because the current
  support model has no assignment field.
- The ticket submitter is the sole recipient for admin notes and status changes.
- The existing support ticket public ID is stable and is safe to use as the
  notification target identifier.
- Existing visible-tab polling at 30 seconds is acceptable for the MVP.
- The pulled API branch already contains the notification inbox backend
  contract used by the tenant/vendor bell. Implementation planning therefore
  starts with migration-chain reconciliation and support-specific extension of
  that existing contract.
