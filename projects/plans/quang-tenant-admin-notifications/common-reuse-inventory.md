# Common-first inventory

Date: 2026-10-03. Source paths are relative to workspace root. Existing symbols are reusable; proposed additions are explicitly marked. Recheck paths/contracts before implementation.

## Backend common

| Existing source/symbol | Required reuse | Missing capability / justified extension |
| --- | --- | --- |
| pte-api/app/src/main/java/com/pte/shared/domain/BaseEntity.java | Entity identity, timestamps, public UUID conventions | Notification content/intent/inbox entities remain notification-owned |
| shared/web/ApiResponse.java | Standard success/error envelope | No notification envelope |
| shared/web/PagedResult.java and PageMeta.java | Paged lists and metadata | Add snapshot token as documented notification DTO field, not incompatible global pagination change |
| shared/security/CurrentUser.java and CurrentUserContext.java | Authenticated recipient/tenant/roles | Never accept recipient or tenant overrides from request |
| shared/exception/DomainException.java and GlobalExceptionHandler.java | Module exceptions and HTTP mapping | Notification exception subclasses and centralized codes only |
| shared/audit/AuditLogService.java | Draft/publish/retry audit joining transaction | Audit is not notification delivery storage |
| shared/constant/SharedConstants.java | Shared validation/error conventions | Domain-specific notification constants in owning module |

Search for an existing injectable Clock and scheduler configuration before adding time configuration. If absent, justify one injectable UTC Clock contract; use fake clocks in tests, not Thread.sleep.

## Public module boundaries

Reuse IdentityService, TenancyService, BillingService, SessionService, AttemptService, ScoringService and AssessmentService. Extend narrow bulk contracts for active recipients/tenants, exact commercial targets, schedule revalidation, frozen attempt coverage and grading readiness. Own entity repositories stay inside their modules.

Existing NotificationLog, NotificationDispatchService, EmailWorker and email listeners remain operational email history. Do not reinterpret email SENT as inbox delivered/read. No shared durable outbox surfaced in research: verify once more, then add a notification-owned intent/lease worker instead of a generic event-platform rewrite.

Reuse session lifecycle row serialization and existing scoring answer-to-state lock order. Existing per-examiner queue completion and ReportPublishService readiness are NOT reusable full-session grading predicates.

## Frontend common

| Existing package/symbol | Intended use |
| --- | --- |
| @pte/api-client: ApiClient, RequestOptions, PagedResult, PageMeta, ApiError | Typed notification requests through existing transport |
| getUserFacingApiErrorMessage | Approved error copy/fallbacks, never raw API diagnostic messages |
| decodeAccessTokenClaims | Identity cache scope from existing authenticated session |
| @pte/ui: BellIcon, Badge, Button | Accessible bell and real unread state |
| PageHeader, DataTable, PaginationControls | Inbox/admin history |
| EmptyState, LoadingState, ErrorState, Alert, Skeleton | Loading/empty/retry/stale data |
| FormField, TextInput, Textarea, Select, FormActions | Announcement draft form |
| Modal, ConfirmDialog, ActionMenu, useToast | Preview, confirmation, draft actions and feedback |
| DashboardShell.headerActions | Integrate bell without replacing shell |
| createSessionApiClient, useSessionManager, useTokenManager | Existing authentication/session pipeline |
| App QueryClientProvider and lib/apiClient.ts | Existing query/transport composition |

DEFAULT_PAGE_SIZE currently equals 10; explicitly request 20 for inbox history instead of globally changing unrelated lists. Existing Dropdown is action-item oriented: a rich notification panel with focus management is a justified new presentational shared component, not a duplicate dropdown API client. Audit Modal focus behavior before reuse.

Read pte-web/AGENTS.md and installed Next.js guides before code changes. Hooks require a client boundary. Shared UI must not import app-specific auth/routes or notification repositories.

## Reuse evidence required during cook

For each new file record: existing candidates inspected, chosen symbol, unchanged/extended/new decision, compatibility impact, and owner. Missing source or unsuitable semantics requires a reason, not an invented common capability. Final quality review rejects duplicate response/error/auth/transport/UI infrastructure.

## Phase 01 implementation reuse record (2026-10-03)

- `InboxContent`, `InboxAnnouncement`, `InboxDeliveryIntent`, `InboxItem`, `InboxRecipientStream`: reuse `BaseEntity` identity/timestamps/deleted and existing JPA/Lombok conventions; new mappings are justified because outbound `NotificationLog` cannot represent personal read state or durable inbox intent.
- `InboxNotificationException`: extends existing `DomainException`; safe response mapping stays in `GlobalExceptionHandler`. `InboxConstants` owns codes/copy without duplicating shared errors or email constants.
- `IdentityService.lockActiveRoleMember`: extends the public facade and reuses `UserRepository.findWithLockByPublicId`; exact nullable tenant matching, live active/nondeleted status and role are checked while held. No new identity repository abstraction.
- `TenancyService.lockActiveTenant`: extends the public facade and reuses `TenantRepository.findWithLockByPublicId`; notification never imports either module's internal repository.
- `ClockConfig`: search found no existing injectable clock; one replaceable UTC `Clock` bean is the only new shared capability. Notification services inject it instead of changing unrelated static time calls.
- `InboxRequestListener`/`InboxAppendService`: reuse synchronous Spring transaction events and MANDATORY propagation. Business hooks remain deferred; business modules will publish their own events rather than importing the notification-owned request.
- `InboxDeliveryStore`: a new owning-module repository is justified for PostgreSQL ON CONFLICT, SKIP LOCKED, immutable audience fingerprint, lease fencing and stream commit serialization. Reuses the existing datasource/transaction infrastructure; no generic outbox framework or new production dependency.
- `InboxDeliveryService`/`InboxDeliveryWorker`/properties/config: reuse scheduling already enabled by `PteApplication`, Spring validated configuration and existing Micrometer infrastructure. Worker is opt-in; email worker/config remains untouched.
- V71 is the next migration after inspected V70. Migration is additive; rollback disables the worker and retains records. `.env.example` documents only the new rollout controls.

## Phase 02 implementation reuse record (2026-10-03)

- `InboxController`/`InboxReadService`: reuse `CurrentUserContext`, `@PreAuthorize`, `ApiResponse`, `PagedResult`, `PageMeta` and `GlobalExceptionHandler`; no separate transport/security/error layer was created.
- `InboxReadStore`: extend the notification-owned JDBC boundary created in Phase 01 for V72 snapshot/read queries; PostgreSQL stream locks and null-safe tenant predicates remain in the owning module.
- `InboxReadFilter` and inbox DTOs: new notification-owned contracts are justified because existing `NotificationLog` responses model outbound email delivery, not recipient-owned read state or anchored snapshots.
- V72 is additive after V71 and stores only opaque recipient-bound snapshot tokens; no user/tenant request override or cross-module internal repository import was added.

## Phase 03 implementation reuse record (2026-10-03)

- `AnnouncementController`/`AnnouncementService`: reuse `CurrentUserContext`, `@PreAuthorize`, `ApiResponse`, `PagedResult`, `PageMeta`, `InboxNotificationException`, `InboxConstants`, and `AuditLogService`; no parallel response, security, transport, error, or audit layer was created.
- `IdentityService.findActiveRoleMembers` and `TenancyService.findActiveTenantIds`: extend the existing public module facades with minimal bulk eligibility projections; notification does not import identity/tenancy internal repositories.
- `InboxAnnouncementStore`: new notification-owned JDBC repository is justified for draft optimistic version updates, publication row locks, aggregate delivery/read counts, and PostgreSQL-specific status queries over the V71 tables.
- `InboxAppendService.append` now returns the existing immutable content public ID while retaining the Phase 01 MANDATORY transaction boundary; existing callers remain source-compatible and announcement publication can bind the publication row to the durable content.
- `TenantApplicationInboxNotificationListener`: adds a separate BEFORE_COMMIT inbox listener for the existing public `TenantApplicationSubmittedEvent`; the existing applicant email listener and email audit remain unchanged.
- V73 adds only announcement-management/content-summary indexes after inspecting V71/V72; no generic outbox, new transport, or external delivery path was introduced.

## Phase 04 implementation reuse record (2026-10-03)

- `CommercialOutcomeConfirmedEvent`, `OrderExpiredEvent`, and the expanded `SubscriptionRevokedEvent` are billing-owned public transition contracts. Billing publishes them; notification maps them through `CommercialNotificationListener` to the existing `InboxNotificationRequested`/`InboxAppendService` path, so billing does not import notification internals.
- `SubscriptionPersistenceService.save` now joins the caller transaction instead of opening `REQUIRES_NEW`; existing JPA repository and transaction infrastructure remain the persistence boundary. License-key uniqueness is still database-enforced and a conflict aborts the complete activation transition for a safe full-operation retry.
- `IdentityService` and `TenancyService` received narrow active-role/active-tenant read contracts. The notification listener reuses `CurrentUser`-independent public projections and existing tenant/identity ownership rather than importing internal repositories.
- `OrderService` and `BillingService` own exact tenant-scoped order/subscription reads. `OrderController`/`SubscriptionController` expose those contracts with existing `ApiResponse` and role guards; no notification repository or duplicate authorization layer was added.
- Tenant Payment Status reuses the existing React Query/API client transport and billing types. The status view now requires an order public ID and uses an exact `/orders/{publicId}` request; checkout may still list pending orders to route the user to that exact ID, while missing foreign targets show explicit unavailable state instead of falling back to the first 100 orders.
- Order expiry keeps PayOS cancellation outside the database transaction, then uses `OrderPersistenceService.expireIfPending` with a pessimistic row lock and publishes `OrderExpiredEvent` inside that transition. Existing `BEFORE_COMMIT` inbox delivery therefore remains atomic without holding a DB lock across the provider call.

## Phase 05 implementation reuse record (2026-10-04)

- `SessionClosingSoonReminderWorker` reuses the public `SessionService`/`SessionLifecycleService` schedule and row-lock contracts, `InboxDeliveryStore` claim/suppression primitives, `InboxAppendService`, `IdentityService`, `TenancyService`, and the existing UTC `Clock`; it does not create a notification-owned session repository or timer per student.
- Stale reminder recovery extends the notification-owned delivery query with a bounded pending-session projection and keeps event-key idempotency in the existing delivery store. Revalidation is performed through the session-owned lock before append/suppression, so reschedules and closed/elapsed sessions do not leak stale notices.
- Grading coverage reuses the public `AttemptService` facade and pinned attempt/answer projections. The new `AttemptGradingQueryService` is justified because the existing attempt views did not expose immutable expected-item coverage needed by the scoring predicate; scoring does not import attempt internal repositories.
- `GradingCohortService` reuses existing scoring answer/state, examiner-assignment, AI-result, transaction-event, and session-lock infrastructure. New cohort entities/repositories are justified for immutable whole-session membership, versioned marking mode, outstanding dispositions, and completion idempotency; the completion listener routes through the existing inbox append contract.
- Session reminder and grading-completion configuration extends existing validated `application.yml`/`.env.example` conventions. No new transport, response envelope, security layer, scheduler framework, or generic outbox was introduced.

## Phase 06 implementation reuse record (2026-10-04)

- `packages/api-client` notification and grading requests reuse the existing `ApiClient`, `ApiError`, `PagedResult`, `PageMeta`, URLSearchParams conventions, request barrels, and hand-written DTO type barrels. No direct `fetch`, token parsing, response envelope, or error formatter was added to a feature.
- `packages/ui/NotificationCenter.tsx` is the only new shared presentation capability. It reuses `BellIcon`, `Badge`, `Button`, `LoadingState`, `EmptyState`, and `ErrorState`; the existing `Dropdown` was inspected and is action-only, so it cannot own the required notification rich-popover focus, Escape, outside-click, and return-focus behavior. The component owns no auth, route, or transport decision.
- Vendor and tenant notification adapters reuse each app's existing `lib/apiClient`, `useCurrentUser`, `QueryClient`, `useToast`, and session pipeline. Their query keys bind user public ID plus tenant ID; 401 handling clears protected query cache; the app-specific adapters differ only at the portal route/role boundary.
- Admin announcement pages reuse `DashboardChrome`, `RequireAuth`, `ADMIN_NAV`, `PageHeader`, `DataTable`, `ActionMenu`, `Modal`, form primitives, `ConfirmDialog` behavior, `PaginationControls`, and `getUserFacingApiErrorMessage`. Announcement CRUD stays on the existing PLATFORM_ADMIN-only backend contract; PLATFORM_AUTHOR is not broadened.
- Host grading cohort UI reuses the existing `SessionDetailView`, `useSession`, `DashboardChrome`, shared API transport, `ConfirmDialog`, `Alert`, `Badge`, `Button`, and `Select`; the new adapter only maps the already implemented session-scoped preview/finalize contract and never changes attempt status or excludes submitted work.
- No new dependency, persistence schema, auth mechanism, arbitrary redirect URL, or HTML rendering path was introduced in Phase 06. Route targets are allowlisted by `InboxTargetType` and missing targets fall back to a readable notification detail route.
