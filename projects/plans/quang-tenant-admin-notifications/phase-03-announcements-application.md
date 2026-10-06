# Phase 03: Announcements and application notices

Status: completed. Priority: P1 only. Date: 2026-10-03.

## Scope and dependencies

Mapping: FR-01–06, FR-13–18; P1 global notices/admin application.

Prerequisites: Phases 01–02. Phase owner is the implementer for the owning modules below; final quality review is independent. Do not advance past unmet schema/security/transaction prerequisites.

## Design Constraints

Mandatory common-first: inspect [inventory](common-reuse-inventory.md), reuse existing symbols, extend public contracts minimally, justify any new capability in the phase log. No duplicate common response, pagination, errors, security, transport or UI primitives. No cross-module internal repository imports. Existing email audit/listeners remain separate. All errors use module constants plus shared safe HTTP handling; 400 invalid input, 401 unauthenticated, 403 wrong role, 404 foreign/missing personal target, 409 lifecycle/version conflict.

Use transaction-scoped intent persistence, database-enforced idempotency and bounded recoverable work. Preserve user changes and existing business side effects. No new violation/submission/per-examiner completion notification; no automatic score publication or force submission. P2/P3 work is deferred.

## Implementation steps

1. Add PLATFORM_ADMIN-only draft list/create/detail/update/delete/preview/publish/retry endpoints. PLATFORM_AUTHOR remains forbidden even when it shares the admin shell.
2. Validate title <=150, body <=5000 plain-text characters, enumerated category/importance and end later than start. Draft version uses optimistic locking; stale mutation 409. Published content is immutable; corrections create new linked drafts.
3. Extend public IdentityService/TenancyService bulk eligibility contracts: active nondeleted role users in active tenants. Application recipients are eligible active PLATFORM_ADMIN accounts, not applicant email recipients.
4. Publication locks draft; snapshot content/version and final eligible audience and persist all intents in one transaction. Repeated publish returns original publication, even with concurrent requests. Preview counts are advisory and publication counts final. Zero audience is a successful recorded publication.
5. Worker revalidates active membership; suppress deactivated recipients without replacing the frozen audience. Track pending/delivered/failed/suppressed counts and aggregate read count, not individual-host read disclosure beyond agreed admin management scope.
6. Consume TenantApplicationSubmittedEvent synchronously before commit, with safe event metadata/public ID and active-admin audience resolution. Keep applicant acknowledgment listener/email separate. No new event on attempted/rolled-back submission.
7. Inspect application detail list-only lookup. Add authorized exact application detail query/API if necessary; notification action must find the named application outside the first page, or show missing state. Reuse existing application review UI.
8. Audit create/edit/delete/publish/retry/correction with identifiers and safe metadata, not sensitive duplicated body. Management retry resets only eligible failed delivery records without changing publication identity.

## Concrete file targets and ownership

### First publication version check (R6)

First publish requires expectedDraftVersion, checked under the draft row lock before snapshot/content/intent creation. Stale preview/version returns centralized 409 and creates no intents. If publication already committed, a replay returns the original immutable publication even if its submitted version is old: lost-response retries are idempotent. Test concurrent draft edit versus first publish and committed publish response loss.

notification announcement entities/controller/service/constants; identity/IdentityService.java; tenancy/TenancyService.java; billing TenantApplicationSubmittedEvent/service/controller public details; existing admin application view later consumed by phase 06.

File names for new types are proposed; confirm existing equivalents first. Migration numbering must be resolved from current repository, not guessed.

## Permissions, failures, concurrency and recovery

Bind principal/tenant on every personal operation. Sanitize display errors and logs; never include passwords, signed media, answers or provider secrets. Retry only committed logical work with original identity. Recover expired leases and missed evaluator wake-ups; do not retry invalid authorization/business transitions as delivery successes. Document lock ordering and transactional boundaries for this phase and test overlaps, not just sequential happy paths.

## Tests and acceptance evidence

Ten simultaneous publish requests -> one publication/item per recipient; optimistic conflict; global eligibility edge cases; preview audience changes before publish; zero hosts; deactivation suppression; failed-delivery retry; app rollback vs commit; exact application outside first page; published mutation 409.

## Exit criteria

Atomic audience/intents measured at 1000 hosts with target <=1s; application target exact and authorized; delivery counts reconcile to snapshot total; existing applicant mail preserved.

## Quality and Testing State

- Implementation: completed; announcement draft/publish management, active audience resolution, admin application inbox mapping, and exact application lookup are implemented.
- Common-first evidence: recorded in `common-reuse-inventory.md`; existing response/security/audit/transaction boundaries were reused or minimally extended.
- Unit/integration testing: TDD RED_READY was recorded before production; the final targeted/regression suite is green at 121 tests, with real PostgreSQL coverage for V71-V73 announcement persistence.
- PostgreSQL/browser/performance checks: PostgreSQL integration executed; browser and 1000-host performance evidence remain pending for later validation.
- Quality gate: APPROVED with 0 blocking findings and 2 NOTED follow-ups; receipt is `quality/phase-03-announcements-application-receipt.json`.
- Findings/fixes/reverification: initial fixture-order/ID issues were corrected without weakening assertions; build, targeted/regression tests, quality report, and receipt were rerun/current before the hard-mode checkpoint.
- Hard-mode checkpoint: user confirmed completion on 2026-10-03; Phase 03 transition is recorded before activating Phase 04.
