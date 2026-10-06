# Phase 02: Personal inbox and security APIs

Status: completed. Priority: P1 only. Date: 2026-10-03.

## Scope and dependencies

Mapping: FR-01, FR-07, FR-08, FR-13–17; P1 admin/host inbox.

Prerequisites: Phase 01. Phase owner is the implementer for the owning modules below; final quality review is independent. Do not advance past unmet schema/security/transaction prerequisites.

## Design Constraints

Mandatory common-first: inspect [inventory](common-reuse-inventory.md), reuse existing symbols, extend public contracts minimally, justify any new capability in the phase log. No duplicate common response, pagination, errors, security, transport or UI primitives. No cross-module internal repository imports. Existing email audit/listeners remain separate. All errors use module constants plus shared safe HTTP handling; 400 invalid input, 401 unauthenticated, 403 wrong role, 404 foreign/missing personal target, 409 lifecycle/version conflict.

Preflight: inspected `ApiResponse`, `PagedResult`, `PageMeta`, `CurrentUser`, `CurrentUserContext`, `GlobalExceptionHandler`, `NotificationLogController`/`NotificationLogService`, existing `@PreAuthorize` controller conventions, and the V71 inbox schema. Reuse those shared envelopes/security/error mapping and the notification-owned JDBC store; do not repurpose `/notifications` email history. Phase 02 adds only recipient-query/read API and typed snapshot/read-revision contracts. Applicable rules: CORR, DOM, OWN, ERR, SEC, CONST, TXN, CONC, OBS and API/DB adapters. No cross-module repository imports or client-provided recipient/tenant scope.

Use transaction-scoped intent persistence, database-enforced idempotency and bounded recoverable work. Preserve user changes and existing business side effects. No new violation/submission/per-examiner completion notification; no automatic score publication or force submission. P2/P3 work is deferred.

## Implementation steps

1. Create separate /notification-inbox controllers/DTOs, never repurpose /notifications email history. Reuse ApiResponse and PagedResult/PageMeta.
2. Authenticate via CurrentUserContext; require PLATFORM_ADMIN or HOST_ADMIN. Every query/mutation binds recipient public ID and null-safe principal tenant. Request recipient/tenant overrides are unsupported. Wrong role returns 403; foreign or absent item returns indistinguishable 404.
3. Implement list, unread-count, detail and idempotent read. Detail GET has no side effect; UI explicitly invokes read when opening an item. Return only safe content/typed actions; no email delivery diagnostics.
4. Choose page-number history anchored to a server-issued recipient stream snapshot token. Order by stream sequence descending; all subsequent pages use the same upper watermark so new arrivals cannot shift page boundaries. Return existing PagedResult plus notification-specific snapshot metadata. Validate token belongs to current principal.
5. Mark-all locks the recipient stream, captures current committed watermark, and updates only own unread rows at or below it in the same transaction. New deliveries serialize after that operation and stay unread. Support idempotent replay of the same server-issued token; never trust client-provided arbitrary timestamps.
6. Define exact categories: SYSTEM_NOTICE and MAINTENANCE for announcement, SESSION, APPLICATION and BILLING. Preserve type separately from category. Cap page size 100; default 20/recent 5, reject invalid filter/token with centralized 400 codes.
7. Add authorized target resolution: typed allowlist, exact public identifiers and server-owned tenant checks. Unknown/deleted target retains readable notice with safe unavailable action, never redirects elsewhere.

## Concrete file targets and ownership

### Live unread membership (R7)

The upper watermark freezes arrival boundaries, not read-filter membership. All-history uses anchored pages; Unread is explicitly live. Return a recipient read revision with queries; reset Unread to page 1/new snapshot on local read/mark-all, cross-tab invalidation or focus refresh showing changed revision. Preserve shared PagedResult. Test reading rows on another tab and mark-all while viewing later pages; never advertise frozen Unread membership.

notification/internal/controller, dto, service and constants; shared security/envelopes unchanged; identity public recipient eligibility contract.

File names for new types are proposed; confirm existing equivalents first. Migration numbering must be resolved from current repository, not guessed.

## Permissions, failures, concurrency and recovery

Bind principal/tenant on every personal operation. Sanitize display errors and logs; never include passwords, signed media, answers or provider secrets. Retry only committed logical work with original identity. Recover expired leases and missed evaluator wake-ups; do not retry invalid authorization/business transitions as delivery successes. Document lock ordering and transactional boundaries for this phase and test overlaps, not just sequential happy paths.

## Tests and acceptance evidence

Cross-admin/cross-host/cross-tenant access and spoofed token return no data; repeated read stable; mark-all concurrent with delayed delivery commit preserves new unread; anchored pages deterministic under arrivals; count/list consistency; disabled accounts fail existing auth; invalid paging/filter 400.

## Exit criteria

Endpoint and error tables match implementation DTOs; self-only ownership enforced in SQL and service; read-all race proven on PostgreSQL; email-history API unchanged.

## Quality and Testing State

- Phase checkpoint (2026-10-03): unit tests=yes (`--tdd`); quality gate=yes (`--hard`). RED preparation must precede production changes. Hard-mode human approval is required before completion or Phase 03.
- Implementation: production implementation complete for this phase; RED_READY was recorded before implementation. Phase completion remains pending the hard-mode human checkpoint.
- Common-first evidence: inventory baseline and [reuse record](common-reuse-inventory.md) complete for Phase 02.
- Unit/integration testing: passed (`ck:test --tdd --verify`, fresh rerun 2026-10-03); 106 tests, 0 failures/errors/skips. Prepared test assertions remain unchanged. Report: [Phase 02 test report](tests/phase-02-personal-inbox-security-api-test-report.json).
- PostgreSQL/browser/performance checks: 2 Phase 02 integration tests passed on isolated PostgreSQL at 127.0.0.1:55439 with V71+V72 and random schemas; HTTP/browser/full migration-chain/performance checks were not exercised.
- Quality gate: approved in gate mode; no open blocking findings. Report: [Phase 02 quality report](quality/phase-02-personal-inbox-security-api-quality-report.json). Receipt: [Phase 02 quality receipt](quality/phase-02-personal-inbox-security-api-receipt.json).
- Findings/fixes/reverification: initial PostgreSQL `Instant` binding failure was fixed with explicit UTC `OffsetDateTime`; build and full Phase 01/02 regression rerun passed.
- Hard-mode checkpoint: approved by user on 2026-10-03; Phase 02 completion transition recorded before activating Phase 03.
