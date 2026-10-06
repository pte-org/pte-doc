# Phase 07: Final validation, tests and quality gate

Status: in progress. Priority: P1 only. Date: 2026-10-03.

## Scope and dependencies

Mapping: All P1 stories and FR-01–22; P2/P3 exclusion regression.

Prerequisites: Phases 01–06. Phase owner is the implementer for the owning modules below; final quality review is independent. Do not advance past unmet schema/security/transaction prerequisites.

## Design Constraints

Mandatory common-first: inspect [inventory](common-reuse-inventory.md), reuse existing symbols, extend public contracts minimally, justify any new capability in the phase log. No duplicate common response, pagination, errors, security, transport or UI primitives. No cross-module internal repository imports. Existing email audit/listeners remain separate. All errors use module constants plus shared safe HTTP handling; 400 invalid input, 401 unauthenticated, 403 wrong role, 404 foreign/missing personal target, 409 lifecycle/version conflict.

Use transaction-scoped intent persistence, database-enforced idempotency and bounded recoverable work. Preserve user changes and existing business side effects. No new violation/submission/per-examiner completion notification; no automatic score publication or force submission. P2/P3 work is deferred.

## Implementation steps

1. Obtain a current preliminary APPROVED ck:quality gate before normal ck:test verification; TDD prepare is the permitted pre-implementation exception. Then build FR-to-implementation/test traceability. After fixes/tests, rerun final quality and code review with current receipts. Verify common-first evidence and centralized error constants; this sequencing avoids a quality/test gate deadlock.
2. Unit-test safe message/error mapping, recipient eligibility, all seven producers, reminder fake-clock boundaries, cohort required-lane matrix and UI composition. Do not count stub scoring as REAL verification.
3. Add an isolated PostgreSQL test harness and dependencies (e.g. Testcontainers) after common-first checks: current pom exposes H2, not an existing PostgreSQL profile. Never reset local user data. Run migrations/integration tests for null-admin uniqueness, rollback, payment/expiry races, delayed commits/read-all, lease fencing/restart, publication/final-score races. Use controlled barriers; capture sanitized lock evidence.
4. Exercise authenticated HTTP authorization for admin/author/host/foreign tenant and foreign admin. Demonstrate no user-controlled recipient/tenant/token bypass. Preserve email history and existing mail listeners.
5. Browser-test both portals: create/edit/delete/publish draft; maintenance delivery to two hosts; independent read; application exact link; all commercial targets; 15-minute reminder fixture; CLOSED finalization with reasons; 40-paper completion; no automatic publication.
6. Prove absence of excluded notices after violation, submission, individual answer/AI result, or first examiner finishing. These internal events can update reconciliation but must not emit inbox items.
7. Benchmark p95 inbox/count at 100k records/20 clients; atomic snapshot+intent publication at 1k recipients <=1s; healthy fanout <=60s; tick<=60s and visible UI<=35s. Capture dataset/hardware/sample count; do not fabricate results.
8. Perform independent ck:quality review of architecture/ownership/domain/races and final code review. Fix accepted blocker/high/current-change medium findings and rerun affected tests. Store quality and test receipts with actual dates/commands and unmet boundaries.
9. Inspect dirty worktrees; no destructive resets/DB cleanup. Plan rollout with worker toggle, additive migration, existing email compatibility and rollback to worker-disabled without deleting durable records. Record retention as unresolved operational policy, no cleanup enabled.

## Concrete file targets and ownership

pte-api/app/src/test/java/com/pte/notification and affected billing/session/scoring/ModuleStructureTest; pte-web packages test suites where runner exists; browser scripts/reports; this plan quality/ and tests/ receipts.

File names for new types are proposed; confirm existing equivalents first. Migration numbering must be resolved from current repository, not guessed.

## Permissions, failures, concurrency and recovery

Bind principal/tenant on every personal operation. Sanitize display errors and logs; never include passwords, signed media, answers or provider secrets. Retry only committed logical work with original identity. Recover expired leases and missed evaluator wake-ups; do not retry invalid authorization/business transitions as delivery successes. Document lock ordering and transactional boundaries for this phase and test overlaps, not just sequential happy paths.

## Tests and acceptance evidence

All cases specified in phases 01–06, plus full regression and measured NFRs. Use separate local test data; no external notification sends. Browser/DB/performance claims require fresh corresponding evidence.

## Exit criteria

Current quality gate approved, tests pass with explicit environment boundaries, all P1 criteria traced, deferred scope untouched, and product walkthrough recorded. If PostgreSQL/browser/performance unavailable, mark blocked/not verified rather than complete.

## Quality and Testing State

- Implementation: validation-only; no production feature changes were made during Phase 07.
- Common-first evidence: Phase 06 reuse record was reused; no duplicate notification, transport, error, auth or UI abstraction was introduced.
- Unit/integration testing: the targeted P1 backend suite passed 201 tests with 14 environment skips; the full backend run remains blocked by the known assessment/attempt baseline (4 failures, 6 errors, 14 skips). The web API-client suite passed 357 tests.
- PostgreSQL/browser/performance checks: PostgreSQL integration was not verified because `INBOX_TEST_DB_URL` and Docker Desktop were unavailable; browser smoke passed only unauthenticated login-shell rendering; performance was not run.
- Quality gate: final Phase 07 architecture/code-quality receipt is APPROVED with zero blocking findings at [receipt](quality/phase-07-validation-tests-quality-receipt.json).
- Findings/fixes/reverification: five NOTED findings remain open for the explicit runtime boundary, full-regression baseline and performance evidence. Phase 07 is not complete or release-ready until those gates are rerun or separately accepted.

## Executed validation evidence

The reproducible command set and sanitized results are recorded in [the Phase 07 test report](tests/phase-07-validation-tests-quality-test-report.json). The commands below were executed unless explicitly marked as carried forward or environment-blocked.

In pte-api:

```powershell
.\mvnw.cmd -pl app -am test
```

The full Maven regression and the targeted P1 suite were executed. `ModuleStructureTest` and `RouteContractTest` passed in the targeted run. The three PostgreSQL inbox integration classes were selected but skipped because `INBOX_TEST_DB_URL` was absent; no unsafe database reset was attempted.

In pte-web:

```powershell
pnpm --filter tenant-web lint
pnpm --filter vendor-web lint
pnpm --filter tenant-web exec tsc --noEmit
pnpm --filter vendor-web exec tsc --noEmit
pnpm --filter tenant-web build
pnpm --filter vendor-web build
pnpm --filter @pte/ui typecheck
pnpm --filter @pte/api-client typecheck
pnpm --filter @pte/api-client test
```

Tenant/vendor manifests contain lint/build but NO test script. The browser smoke script and environment boundary are recorded in the test report; it covered unauthenticated tenant/vendor rendering only. No performance claim is made because the required dataset and running stack were unavailable. `git diff --check` remains a separate final repository check.

## Phase 07 gate result

Phase 07 remains **in progress / not release-ready**. The architecture/code-quality gate is approved, and the targeted unit/web checks are green, but the exit criteria requiring full regression, authenticated HTTP/browser coverage, PostgreSQL behavior and measured performance are not satisfied.
