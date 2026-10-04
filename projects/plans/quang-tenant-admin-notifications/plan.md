---
title: Tenant and admin notifications
date: 2026-10-03
status: in-progress
mode: hard
implementation: phase-07-validation-in-progress
tests: phase-07-partial-not-verified
quality: phase-07-quality-approved-boundaries
---

# Detailed implementation plan

## Scope and minimum implementation

Extend the existing notification module, not create a parallel messaging platform. Its existing email audit is not a personal inbox. P1 adds persisted recipient inboxes, immediate global announcements, seven approved trigger families, and recoverable database delivery. Polling is sufficient; RabbitMQ, WebSocket, push, student notifications, and new reminder emails are unnecessary for P1.

This bundle began as implementation planning. Phases 01 through 06 have recorded implementation, test, quality, and hard-mode checkpoint evidence. Phase 07 validation has now produced targeted green evidence and an approved architecture/code-quality receipt, but remains active because full regression, authenticated runtime, PostgreSQL and performance gates are not verified.

## Mandatory common-first rule

For EVERY phase and proposed class/component:

1. Search the owning module and common/shared packages for the capability.
2. Record the existing symbol and source path in the phase work log.
3. Reuse it unchanged when its contract fits.
4. Extend its public contract minimally when that preserves ownership and existing consumers.
5. Create a new abstraction only after documenting the missing capability, why existing code cannot serve it, and its owning module.

Do not duplicate ApiResponse, PagedResult/PageMeta, DomainException, GlobalExceptionHandler, principal extraction, authentication/token handling, API transport, error parsing, audit infrastructure, or UI primitives. Do not move notification domain logic into shared solely to reuse it. See [common inventory](common-reuse-inventory.md).

## P1 trigger and destination matrix

| Type | Recipient | Authoritative condition | Destination |
| --- | --- | --- | --- |
| APPLICATION_SUBMITTED | Eligible PLATFORM_ADMIN | Organization application commits | /admin/applications/{publicId} |
| PLATFORM_ANNOUNCEMENT | Eligible HOST_ADMIN snapshot | Admin publishes immutable content | Own notification detail |
| SESSION_CLOSING_SOON | Eligible tenant hosts | OPEN session within closing window | /host/exams/{publicId} |
| SESSION_GRADING_COMPLETED | Eligible tenant hosts | Finalized entire grading cohort complete | /host/exams/{publicId} |
| COMMERCIAL_OUTCOME_CONFIRMED | Eligible tenant hosts | Payment/redemption and access/quota commit together | Exact order, subscription, or quota outcome |
| ORDER_EXPIRED | Eligible tenant hosts | PENDING-to-expired transition commits | Exact order |
| SUBSCRIPTION_REVOKED | Eligible tenant hosts | Exam entitlement revocation commits | Authorized inactive subscription detail |

Commercial success is ONE notification: exam access activated OR roster slots added. Payment and activation are not separate notices. A failed webhook is not an invented FAILED order.

P2 retains subscription-expiry/capacity reminders, staff assignment notices, scheduled publication and selected tenants. P3 retains push/student inbox/preferences. Explicitly exclude violations, submitted attempts, individual answers, individual AI results, and individual examiner completion.

## Confirmed product rules and planning mechanisms (2026-10-03)

- One reminder 15 minutes before closesAt; server-side configurable threshold, not per-student timer.
- Immediate global publication in P1; scheduled publication remains P2.
- Visible authenticated tabs poll unread count every 30 seconds; focus refresh; recent 5/history 20/max page 100.
- Completion requires CLOSED and a frozen cohort including all submitted retries. HOST_ADMIN previews/finalizes all SUBMITTED papers; outstanding CREATED/IN_PROGRESS attempts require reasoned audited cohort-only exclusion, without changing attempt status. Unacknowledged outstanding work blocks finalization, not session closing. No force-submit.
- Reuse explicit session marking mode; if absent add a narrow versioned mode contract, not broad policy UI. Manual mode requires examiner marking across the whole subjective cohort, never inferred from assignment presence. Objective scores are required; optional AI comparison does not block; required AI/AI-only needs valid REAL/nonstub results, independently of publication source.
- Reopening finalized grading is unsupported in P1 unless an explicit versioned invalidation workflow is implemented and validated. No silent cohort reset/new completion notice.

The user confirmed 15 minutes, CLOSED/frozen cohort and manual/AI required lanes on 2026-10-03. Scheduling stays P2. Reasoned outstanding-attempt dispositions, delivery suppression, polling and pagination are proposed engineering mechanisms, not additional user-confirmed rules. No further question from the three-question product validation is outstanding.

## Architecture and transaction contract

Notification owns immutable content, publication audience, per-recipient delivery intent, inbox/read state, and delivery recovery. Source modules own business transitions and expose narrow public contracts. No notification imports of identity/billing/session/scoring internal repositories.

For small events, persist intent through synchronous BEFORE_COMMIT listeners consuming metadata-rich public business events, with fallback execution disabled. Prove active originating transactions and acyclic module boundaries with ModuleStructureTest. Source modules do not import NotificationService where notification depends on their facades. AFTER_COMMIT alone is not durable; append failure rolls back the source transition.

Global publication locks the draft, fixes content/version, bulk-resolves eligible recipients, and inserts audience/intents atomically. The worker claims bounded batches through PostgreSQL locking/leases, atomically inserts inbox records and marks delivered, and recovers expired claims. No external delivery inside publication.

Use database uniqueness for logical event + recipient, publication + recipient, and grading transition + cohort version. Globally unique recipient UUID permits a non-null event/recipient unique key without nullable tenant weakening PostgreSQL uniqueness. Admin queries remain null-safe tenant AND recipient scoped. Audience requires active/nondeleted exact HOST_ADMIN and active tenant; preview is advisory.

A publication with zero eligible recipients succeeds with zero final counts. At delivery, deactivated recipients are suppressed, not redirected; retain snapshot history and expose suppressed counts separately from failed delivery. Delivered items remain stored, but disabled accounts cannot authenticate.

## Ordered phases and dependencies

Current hard-mode state: Phase 05 completion was confirmed by the user on 2026-10-04, and Phase 06 completion was confirmed by “tiếp tục” on 2026-10-04. Phase 07 is now active; the phase table row below is retained as the original planning baseline and the frontmatter/current-state note is authoritative during cook.

Active transition ledger:
- Phase 03: Completed; tests passed, quality approved; hard-mode checkpoint confirmed.
- Phase 04: Completed; implementation complete, tests passed, quality approved; hard-mode checkpoint confirmed.
- Phase 05: Completed; implementation complete, targeted tests passed, quality gate approved; hard-mode checkpoint confirmed on 2026-10-04.
- Phase 06: Completed; TDD RED/green evidence, quality approval, and hard-mode checkpoint confirmed on 2026-10-04.
- Phase 07: Active; targeted P1/web checks and quality review recorded, while full regression/runtime/performance gates remain pending.

| Phase | Scope | Prerequisites | State |
| --- | --- | --- | --- |
| [01](phase-01-common-first-durable-foundation.md) | Common inventory, schema, durable append/worker | None | Completed; tests passed, quality approved |
| [02](phase-02-personal-inbox-security-api.md) | Recipient APIs, read watermark, access | 01 | Completed; tests passed, quality approved |
| [03](phase-03-announcements-application.md) | Draft/publish/audience/admin application | 01–02 | Completed; tests passed, quality approved |
| [04](phase-04-commercial-hooks-exact-targets.md) | Atomic commerce and exact targets | 01–02 | Completed; tests passed, quality approved |
| [05](phase-05-session-reminders-grading.md) | Reminders, stable full-session completion | 01–02; product defaults validated | Completed; tests passed, quality approved; checkpoint confirmed |
| [06](phase-06-shared-frontend-portals.md) | Shared UI/client, host/admin surfaces | 02–05 contracts | Completed; tests passed, quality approved; checkpoint confirmed |
| [07](phase-07-validation-tests-quality.md) | Regression, PostgreSQL/restart/browser/performance | 01–06 | In progress; runtime gates pending |

Each phase defines tests without claiming execution. During cook, record unit-test and quality choices per phase; final regression does not excuse unverified intermediate invariants. TDD is recommended for ownership, retries, and grading predicates.

## API contract overview

All successful responses use shared ApiResponse; page-based resources use PagedResult. Endpoint names are planned and must be checked against existing mappings before implementation.

| Method and path under /api/v1 | Role | Contract |
| --- | --- | --- |
| GET /notification-inbox | Admin/host | Self-only; anchored arrival snapshot and read revision; Unread membership is live |
| GET /notification-inbox/unread-count | Admin/host | Self-only count and read revision |
| GET /notification-inbox/{id} | Admin/host | Self detail; no automatic read mutation |
| PUT /notification-inbox/{id}/read | Admin/host | Idempotent own-item read |
| POST /notification-inbox/read-all | Admin/host | Server-issued watermark; return affected count |
| GET/POST /announcements | PLATFORM_ADMIN | Paged management / create draft |
| GET/PATCH/DELETE /announcements/{id} | PLATFORM_ADMIN | Detail / versioned draft-only mutation |
| GET /announcements/{id}/audience-preview | PLATFORM_ADMIN | Advisory eligible tenant/user counts |
| POST /announcements/{id}/publish | PLATFORM_ADMIN | First publish requires expectedDraftVersion; successful replay returns immutable publication |
| POST /announcements/{id}/retry-delivery | PLATFORM_ADMIN | Retry failed records only, audit action |
| GET /orders/{publicId} | HOST_ADMIN | Exact tenant-owned order, if absent add contract |
| GET /subscriptions/{publicId} | HOST_ADMIN | Exact tenant-owned active/inactive detail |
| GET /sessions/{publicId}/grading-cohort/preview | HOST_ADMIN | CLOSED session: submitted inventory and outstanding attempts |
| POST /sessions/{publicId}/grading-cohort/finalize | HOST_ADMIN | All submitted included; versioned policy and audited outstanding reasons |

No change to the existing GET /notifications email-log semantics. Notification actions carry allowlisted target type/publicId, not arbitrary redirect URLs.

## Errors, operations, and measurements

Centralize notification codes and safe display copy. Invalid fields/filter/watermark: 400. No authentication: existing 401. Wrong role: 403. Foreign/missing recipient item or tenant-owned target: indistinguishable 404. Stale draft version/published mutation: 409. Unexpected failures use shared safe 500 handling; never expose SQL, provider secrets, signed media, answer content, or raw exceptions.

Measure inbox/count p95 <=500ms at 100k records/20 concurrent clients; publication including atomic audience snapshot/intents <=1s at 1k hosts; healthy delivery <=60s; scheduler tick <=60s plus visible-tab refresh <=35s. These are proposed acceptance targets, not results. If atomic publication misses the target, optimize/batch within the transaction or explicitly renegotiate: do not claim a job-only enqueue satisfies an audience already snapshotted.

Metrics: pending/failed/suppressed counts, oldest pending age, expired claims, retries, scheduler lag, grading blocked reasons, and API timings. Retain published/inbox history in P1; no destructive cleanup job until retention requirements are agreed.

## Risks and handoff

See [gap analysis](gap-analysis.md). Highest risks: orphan subscription commitment, payment/expiry races, unstable grading cohorts, deadlocks from inverted scoring locks, admin role leakage, and read-all racing newly committed inbox rows.

Do not mark a phase complete on code presence alone. Record current quality findings and exact verification evidence. PostgreSQL and browser evidence remain separate from unit tests/builds.

Implementation handoff:

`/ck:cook --hard --tdd pte-doc/projects/plans/quang-tenant-admin-notifications/plan.md`
