# Phase 11: Notification — Fan-out Email

## Requirements

A terminal fan-out consumer: no other service depends on notification's output, so it never publishes its own domain events (matches `media`'s precedent — a service can be legitimately consumer-only, no outbox). Consumes `UserCreated` (iam) to build its own local email directory, `StudentEnrolled` (scheduling), `AttemptPublished` (reporting), and `ViolationDetected` (proctor, Phase 10) to send email. Unlike Phase 9's AI vendor, email has no vendor-lock/paywall blocker — SMTP is a commodity protocol, so this phase ships a REAL send path against a self-hosted SMTP capture server, no stub needed.

## Design Constraints

- `com.pte.notification`, DB `notification` (role/DB pre-provisioned in Phase 0), uniform layout.
- **No outbox** — notification is the end of every chain it participates in; nothing in Milestone 1 consumes a notification-emitted event. Confirmed precedent: `media` also ships with no outbox.
- **Own local email directory, not a sync call to iam**: `UserDirectoryEntry` (userPublicId, email, fullName, tenantId, roles) is built by consuming iam's `UserCreated` (topic `outbox.event.User`) — the same denormalize-via-event pattern as every other cross-service reference in this codebase (reporting's projections, scheduling's `SnapshotRef`). iam's `UserCreatedEvent` javadoc already says "consumed by notification, etc." — this was the intended design since Phase 1.
- **Real SMTP, no vendor stub**: Mailpit (self-hosted SMTP capture server + web UI) added to `docker-compose.yml` — zero external account, zero API key, genuinely sends and captures real SMTP traffic. `spring-boot-starter-mail` / `JavaMailSender` talks to it directly. This is NOT the Phase 9 pattern (real infra, stubbed vendor call) — here the vendor call itself is real, because SMTP isn't gated behind a paid account the way an LLM API is.
- **RabbitMQ work queue for the actual send** (reuses Phase 9's `AiScoringWorker` pattern exactly): a Kafka consumer never sends email inline — it resolves the recipient, writes a `NotificationLog` row (`PENDING`), and enqueues an `EmailJob`. `EmailWorker` (RabbitMQ listener) does the actual `JavaMailSender` call, with the same bounded retry+backoff+DLQ (`RetryOperationsInterceptor`, dead-letter exchange) as scoring's AI vendor queue — email delivery is exactly the "slow/unreliable external call" ADR-002 designed the Kafka/RabbitMQ split around.
- **Violation recipient is resolved, not carried on the event**: `ViolationDetectedEvent` only has `tenantId`/`attemptPublicId`/`sessionPublicId` — no specific recipient. Notification fans out to every `HOST_ADMIN` in that tenant (`UserDirectoryEntry.roles` contains `HOST_ADMIN`, filtered by `tenantId`), one `NotificationLog`+`EmailJob` per recipient. `StudentEnrolled`/`AttemptPublished` resolve directly via the event's own `studentPublicId`.
- **Known, accepted gap**: if a notification-triggering event is consumed before its recipient's `UserCreated` has been (cross-topic Kafka delivery has no ordering guarantee across different source services), the directory lookup misses and the notification is silently skipped — no retry/replay mechanism for this specific race. In practice this can't happen (a user must exist before being enrolled/scored/flagged), so it's a documented theoretical gap, not built around.

## Steps

1. `notification` module (12th service): `UserDirectoryEntry` (userPublicId unique, email, fullName, tenantId, roles as `@ElementCollection`), `NotificationLog` (recipientUserPublicId, recipientEmail, notificationType, subject, body, status PENDING/SENT/FAILED, sentAt), `ProcessedEvent`. Flyway `V1__notification.sql`. No `OutboxEntry`.
2. docker-compose: `mailpit` service (`axllent/mailpit`, SMTP :1025, web UI :8025).
3. `UserDirectoryConsumer` (topic `outbox.event.User`) — `UserCreated` → upsert `UserDirectoryEntry`.
4. `NotificationDispatchService.dispatch(type, recipientUserPublicId, tenantId, subject, body)` — shared by the other 3 consumers: looks up the directory entry (skip if missing — the documented gap above), saves `NotificationLog` (`PENDING`), publishes `EmailJob` to RabbitMQ.
5. `EnrollmentNotificationConsumer` (topic `outbox.event.ExamSession`, filters `eventType=StudentEnrolled` — shared topic with `ScoringRequested`/`PublishRequested`/`SessionScheduled`), `AttemptPublishedConsumer` (topic `outbox.event.AttemptReport`), `ViolationNotificationConsumer` (topic `outbox.event.ViolationEvent`, fans out to every tenant `HOST_ADMIN`).
6. RabbitMQ: `notification.email-jobs` queue + DLQ, `RabbitMqConfig` (same retry/backoff/DLX shape as scoring's Phase 9 `RabbitMqConfig`). `EmailWorker.onEmailJob` sends via `JavaMailSender`, marks `NotificationLog` `SENT`; `onDeadLettered` marks `FAILED`.
7. `NotificationLogController` — `GET /notifications` (HOST_ADMIN/HOST_AUTHOR, tenant-scoped) for delivery-status audit review.

## Success Criteria

- A new user's `UserCreated` event populates `UserDirectoryEntry` before any notification needs it (normal ordering).
- `StudentEnrolled` results in an email captured by Mailpit, addressed to the enrolled student.
- `AttemptPublished` results in an email to the student whose report just became visible.
- `ViolationDetected` results in one email per `HOST_ADMIN` in the violation's tenant.
- A forced SMTP failure (Mailpit stopped) retries with backoff, then lands in the DLQ and the `NotificationLog` row shows `FAILED` — never retried forever.
- No component makes a synchronous call to iam/scheduling/reporting/proctor — confirmed by code inspection (Kafka consumers + one outbound SMTP call only).

## Quality and Testing State

- Quality gate: **APPROVED** (`ck:quality --gate`). 1 MEDIUM blocking finding, fixed and verified:
  - QUAL-001 (MEDIUM): `ViolationNotificationConsumer`'s host-admin fan-out loop caused an N+1 — it re-fetched each already-loaded `UserDirectoryEntry` via `dispatchService.dispatch(userPublicId, ...)`. Fixed by adding `NotificationDispatchService.dispatchTo(type, UserDirectoryEntry, ...)`, taking the already-loaded entry directly.
  - QUAL-002 (NOTED, pre-existing, not introduced by this phase): while building this phase, a **latent bug from Phase 9** surfaced — `RejectAndDontRequeueRecoverer` implements AMQP's `MessageRecoverer`, not Spring Retry's `MethodInvocationRecoverer` that `RetryInterceptorBuilder.recoverer(...)` actually requires. A stale compiled `.class` file had silently masked this compile error in `scoring` since Phase 9; it only surfaced when a genuinely clean `rm -rf */target && mvn install` ran this phase. Fixed in both `scoring/.../RabbitMqConfig.java` and `notification/.../RabbitMqConfig.java` with a `MethodInvocationRecoverer<Object>` lambda that throws `AmqpRejectAndDontRequeueException` once retries are exhausted — functionally equivalent to the original intent (NACK-without-requeue → DLX → DLQ). Full clean reactor build verified green across all 12 modules after the fix.
- Testing: skipped by user direction (quality-only cook mode).

## Risks

- **LOW: directory-miss race** (see Design Constraints) — theoretical, not observed possible under normal enrollment/scoring/violation flows since a user must pre-exist. Documented, not mitigated.
- **LOW: Mailpit is dev/thesis-scale only** — not a production SMTP relay (no real delivery to external inboxes, no DKIM/SPF). Fine for Milestone 1 demo; a real relay (SES/SendGrid/etc.) is a config change (`spring.mail.host`), not a code change, when that matters.
