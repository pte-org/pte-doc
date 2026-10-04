# Phase 04: Commercial hooks and exact targets

Status: completed. Priority: P1 only. Date: 2026-10-03.

## Scope and dependencies

Mapping: FR-14, FR-17, FR-22; P1 commercial outcomes/expiry/revocation.

Prerequisites: Phases 01–02. Phase owner is the implementer for the owning modules below; final quality review is independent. Do not advance past unmet schema/security/transaction prerequisites.

## Design Constraints

Mandatory common-first: inspect [inventory](common-reuse-inventory.md), reuse existing symbols, extend public contracts minimally, justify any new capability in the phase log. No duplicate common response, pagination, errors, security, transport or UI primitives. No cross-module internal repository imports. Existing email audit/listeners remain separate. All errors use module constants plus shared safe HTTP handling; 400 invalid input, 401 unauthenticated, 403 wrong role, 404 foreign/missing personal target, 409 lifecycle/version conflict.

Preflight: reuse the existing billing services, domain events, repositories, `ApiResponse`, tenant-scoped `CurrentUserContext`, `IdentityService`, `TenancyService`, notification `InboxAppendService`, `InboxNotificationRequested`, and existing frontend `@pte/api-client`/React Query transport. New public billing event records are justified to keep billing authoritative while notification maps them to inbox contracts. Exact order/subscription reads extend existing billing ownership boundaries; no notification or cross-module internal repository access is introduced. Tests follow existing Mockito unit tests and random-schema PostgreSQL integration tests; `Clock` remains injectable where time is under test. Decisions: unit/integration tests=yes via `--hard --tdd`; quality gate=yes via `--hard`.

Use transaction-scoped intent persistence, database-enforced idempotency and bounded recoverable work. Preserve user changes and existing business side effects. No new violation/submission/per-examiner completion notification; no automatic score publication or force submission. P2/P3 work is deferred.

## Implementation steps

1. Inspect SubscriptionPersistenceService.save REQUIRES_NEW. Repair narrowly so entitlement insert/access or quota grant, payment PAID/redemption linkage and success intent share the authoritative transaction. Preserve intended unique activation keys; retry conflicts around the full transaction rather than swallowing partial failure.
2. Add metadata-rich public billing transition events consumed BEFORE_COMMIT by notification. Do not couple BillingService directly to notification internal implementation. Record EXAM_PACKAGE versus STUDENT_CAPACITY outcome and payment/license source.
3. Successful verified payment or redemption emits one combined outcome per committed business transition and eligible tenant host. No separate payment and activation notices; failed verification, late rejected webhook and rolled-back activation produce none.
4. Make order expiry and payment mutually consistent via existing owning lock or conditional transition. Provider cancellation failure leaves order pending and emits no expiry. Only committed expiry emits ORDER_EXPIRED; ensure concurrent payment cannot create contradictory success/expiry outcomes.
5. Revocation event includes authoritative tenant/subscription public IDs and safe reason context. Notify only an actual committed entitlement transition, not repeated revoke calls.
6. Add tenant-owned exact order and active/inactive subscription detail contracts. Replace PaymentStatusView first-100-orders lookup and orders[0] fallback with exact named lookup. Unauthorized/missing is 404 and explicit unavailable UI. License-only activation can target exact entitlement; capacity outcome targets quota/history without inventing a subscription.
7. Preserve billing/email behavior and public response conventions. Document narrow migration/transaction compatibility before changing propagation.

## Concrete file targets and ownership

billing/internal/service/SubscriptionPersistenceService.java, SubscriptionActivationService.java, PayOsWebhookService.java, LicenseCodeService.java, OrderPersistenceService.java, OrderExpirationService.java; billing public events/controllers/facade; tenant PaymentStatusView.tsx and api-client billing detail requests.

File names for new types are proposed; confirm existing equivalents first. Migration numbering must be resolved from current repository, not guessed.

## Permissions, failures, concurrency and recovery

Bind principal/tenant on every personal operation. Sanitize display errors and logs; never include passwords, signed media, answers or provider secrets. Retry only committed logical work with original identity. Recover expired leases and missed evaluator wake-ups; do not retry invalid authorization/business transitions as delivery successes. Document lock ordering and transactional boundaries for this phase and test overlaps, not just sequential happy paths.

## Tests and acceptance evidence

Outer rollback after entitlement insert leaves no access/success intent; duplicate verified webhooks and license retries create one outcome; capacity rollback; payment-versus-expiry barrier race; provider cancellation failure; repeat revocation; exact target outside first 100; foreign inactive subscription hidden.

## Exit criteria

Commercial atomicity verified on PostgreSQL; no orphan access after rollback; no unrelated-order fallback; exact inactive target usable; one combined success notice only.

## Quality and Testing State

- Implementation: code complete; Phase 04 is complete after the confirmed hard-mode human checkpoint.
- Common-first evidence: recorded in `common-reuse-inventory.md`; billing owns transitions/events, notification owns inbox mapping, and exact billing reads remain billing-owned.
- Unit/integration testing: selected=yes via hard-mode TDD; TDD verify passed 32/32 prepared tests; supplemental targeted suite passed 42/42 including route and module-boundary checks.
- PostgreSQL/browser/performance checks: real PostgreSQL notification persistence/lease integration passed 14/14; browser/HTTP authorization and host-scale performance evidence remain pending for the later validation phase. A dedicated billing Spring/PostgreSQL transaction scenario is a noted follow-up.
- Full regression boundary: backend full run covered 1034 tests but reported 4 failures and 7 errors in pre-existing assessment/attempt tests; no Phase 04 failure remains in the current targeted suite.
- Quality gate: APPROVED with 0 blocking findings and 4 NOTED follow-ups; report is `quality/phase-04-commercial-hooks-exact-targets-quality-report.json`, receipt is `quality/phase-04-commercial-hooks-exact-targets-receipt.json`.
- Findings/fixes/reverification: fixed the Modulith public-event boundary, moved order-expiry event publication into the locked transaction, removed Payment Status first-page fallback, and reran compile, TDD, targeted, PostgreSQL, frontend, and receipt verification.
- Hard-mode checkpoint: user confirmed completion on 2026-10-03; Phase 04 is complete.
