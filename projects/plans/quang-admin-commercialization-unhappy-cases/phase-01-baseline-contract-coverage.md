# Phase 01 — Baseline, contracts, 45-case ownership

Status: completed; backend baseline repaired and the isolated PostgreSQL migration/lifecycle checkpoint passed on 2026-10-05. Stories: US-06 [P1], contract prerequisites for US-01..05. Dependency: authoritative implementation-spec.md. Exit unlocks02/03 after the recorded HARD confirmation.

## Design Constraints

Preserve dirty worktrees and historical receipts. Only inventory and contract decisions in this phase until cook is authorized. No blanket fixes for baseline failures. No second lock framework, no global BaseEntity version, no new policy. Main agent owns research/coverage documents; planner does not create them.

Preflight: inspected shared DomainException/GlobalExceptionHandler, PagedResult/PageMeta and identity UserProvisioningHelper outside implementation scope. Follow constructor DI, module public surfaces, owning constants and existing ApiResponse; no global version/exception rewrite. Current Plan price precision19/scale2, BaseEntity already supplies deleted; V77 specifically adds question publication provenance, not Plan deletion columns. Java24 was shell default; compile/test explicitly used installed Java21.0.5 via process-local JAVA_HOME. No global environment change. Source HEADs remain API f070e38/web eafe3c8, clean.

## Detailed tasks and exact files

1. Record fresh HEAD/status for pte-api, pte-web, pte-doc; identify existing lifecycle diff ownership. Review `pte-api/app/src/main/java/com/pte/billing/internal/service/PlanService.java`, `LicenseCodePersistenceService.java`, `LicenseCodeService.java`, `TenantApplicationService.java`, corresponding repositories, and `pte-web/apps/vendor-web/features/commercialization/components/PlanCatalogView.tsx`. Explicitly preserve guarded draft Delete and pending-modal behaviors.
2. Confirm schema lengths/index names in `pte-api/app/src/main/resources/db/migration/`, plus `billing/domain/{Plan,TenantApplication,LicenseCode}.java`, `tenancy/domain/Tenant.java`, and tenancy creation service. Choose new migration suffixes at cook after maximum-version inspection; preserve V77.
3. Map every matrix ID to plan.md primary phase, owning acceptance/test, and residual disposition in the main-agent-owned coverage artifact. Validate 45 unique IDs; execution starts Not run. APP-07 remains Partial; capacity compensation and durable mail Deferred; retained lifecycle behavior still needs new regression evidence.
4. Contract review files: `pte-api/app/src/main/java/com/pte/billing/internal/controller/{TenantApplicationController,PlanController,LicenseCodeController,LicenseCodeRedeemController}.java`, `shared/web/{ApiResponse,PagedResult,PageMeta}.java`; `pte-web/packages/api-client/src/{types/billing/index.ts,requests/billing/applications.ts,requests/billing/plans.ts,requests/billing/licenseCodes.ts,index.ts}`. Inventory all callers, including tenant commerce, before DTO changes.
5. Freeze fingerprint, mandatory version/key/preview validation, admin namespace, and safe response types from plan.md. List exact existing DomainException mapping and add future messages/codes only in `billing/internal/constant/BillingConstants.java`; identity/session constants remain owner-specific.
6. Verify JDK21, Maven test profile and isolated PostgreSQL availability. Establish fresh full-suite baseline on current HEAD (planning source f070e38/eafe3c8); the earlier 11 failures on906345c are historical only until reclassified by current results. Compare prior logs or isolated checkout if needed, never reset user work. A fresh baseline failure blocks release readiness and goes to the main agent for a separate resolution decision; no automatic fixes.

## Proposed HTTP contract freeze

| Surface | Proposal |
|---|---|
| Applications | existing detail GET200/404, approve/reject one committed decision; conflict409; DTO400/business422 |
| Plan edit/transitions | existing PUT/activation/archive paths require expectedVersion; missing400/stale409; response exposes persisted version |
| Issue | admin POST with Idempotency-Key UUID; created201, safe replay200, mismatch409; retained mapping/no cleanup/no expired-key reuse |
| Admin reads | additive bounded `ApiResponse<PagedResult<AdminLicenseCodeSummary>>`; existing legacy GET remains `ApiResponse<List<...>>` |
| Secret lookup/reveal | POST bodies or publicId route; no raw token in path/query; reveal no-store |
| Revoke | UUID preview then POST reason + expected state/subscription/tenant/impact + acknowledgement; changed material scope409; effective expired410 |
| Old routes | mandatory-key safe issue; legacy token revoke fails closed409; old GET410 at controlled cutover without changing successful array shape; beforehand raw authorized legacy read is no-store/redacted and LIC-15 Partial |

All admin operations require platform scope and PLATFORM_ADMIN; tenant redemption retains HOST_ADMIN + tenant ownership. Enumerate machine codes at contract review without changing established external text unnecessarily. Open technical choices have concrete defaults in plan.md; do not reopen approved policies.

## Verification planned after consent

Unit/HTTP: confirm envelope, error classifications, unsupported/missing headers/DTO fields, route binding UUID versus legacy String, and authorization. No production calls.

PostgreSQL: baseline clean migrations and legacy fixtures; name/code/tax uniqueness; timestamp precision; inspect actual SELECT FOR UPDATE SQL and query indexes. Commit and read in new transactions; identify lock hierarchy for create/open/change/revoke before changes.

Browser: record current Applications/Plan/License loading/error/pending states with sanitized fixtures; preserve lifecycle/pending-modal baseline. Main agent may reuse existing screenshots only as historical evidence, never as new execution.

## Exit, rollback and dependencies

Exit: signed contract decisions and primary coverage ownership, runtime/migration baseline, known failure list, and exact verification commands. If DB/runtime absent, mark evidence Blocked and continue only independent design; no atomicity claims. Documentation rollback is removal of these new artifacts only if requested; baseline checks change no business data. Do not modify existing evidence/spec or code to make baseline green.

## Quality and Testing State

Checkpoint 2026-10-05: user invoked ck:cook --hard. Unit tests=yes; quality gate=yes (mode defaults for phase01 only). TDD not enabled; no --checks-all-phases supplied. Quality: approved for phase01 reporting artifacts only, following independent documentation audit; [report](quality/phase-01-baseline-contract-coverage-quality-report.json), [receipt](quality/phase-01-baseline-contract-coverage-receipt.json). This does not approve an implementation or satisfy failed runtime gates. Testing: failed fresh backend baseline (1124 tests:1087 passed,4 failures,7 errors,26 skipped). API-client381/381 passed; typecheck passed. Compile passed under Java21. No test/source edits or assertions weakened. PostgreSQL opt-in suites were skipped; Docker available is not migration/race evidence. See [baseline receipt](phase-01-baseline-receipt.md) and [test report](tests/phase-01-baseline-contract-coverage-test-report.json). Phase remains blocked; no phase02 activation, no automatic unrelated fixes and no release-ready claim.

Subsequent authorized baseline repair: [repair report](../quang-admin-baseline-repair/repair-report.md) and [fresh full test receipt](../quang-admin-baseline-repair/tests/baseline-repair-test-report.json). Testing: backend baseline passed1127 tests (1101 passed,0 failures/errors,26 skipped); targeted31 passed. Three stricter fixture tests added; no business-service behavior changed, support public-interface declarations corrected. Original failed receipt above is historical only. At that checkpoint PostgreSQL migration/race evidence remained pending. Updating that checkpoint invalidated the earlier reporting fingerprint; the reporting-state verification was [replacement report](../quang-admin-baseline-repair/quality/phase-01-baseline-contract-coverage-quality-report.json) and [replacement receipt](../quang-admin-baseline-repair/quality/phase-01-baseline-contract-coverage-receipt.json), documentation scope only.

Completion checkpoint (2026-10-05, Asia/Bangkok): the dedicated container `codex-archive-lifecycle-pg` was started on loopback port `55439`, isolated from the application stack. With Java 21, `./mvnw.cmd -pl app '-Dtest=ArchiveLifecyclePostgresIntegrationTest,QuestionPublicationMigrationPostgresTest' '-Dlifecycle.test.db.url=jdbc:postgresql://127.0.0.1:55439/lifecycle_test?currentSchema=migration_clean' test` passed 12 tests with 0 failures, errors, or skips. The evidence covers the migrated V1-V77 schema, legacy publication provenance, committed tombstones/audits, rollback, lock serialization and the repeated lifecycle races. The user's request to continue to the next phase is recorded as the HARD-mode confirmation after the selected checks. Phase01 is complete; phase02 and phase03 are unlocked. No application data, commit, push or deployment was performed.
