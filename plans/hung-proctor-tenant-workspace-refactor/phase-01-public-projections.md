# Phase 01 — Public projections and query contracts

Status: pending. Dependency: none. Coverage: P1 assigned-list and roster; FR-02/03/04, data bounds/performance.

## Design Constraints

- Public records/facades only across modules; scalar minimal data, explicit constructor DI, manual mapping. No controller changes before query foundations compile.
- Highest attemptNumber selects latest; nullable absence is not a new persisted enum. No pinned snapshot lazy traversal. History and page enrichment capped 100.
- Session owns explicit exported membership SQL view; Attempt consumes it read-only as documented in master, excluding removed/legacy orphan members. Require both session/enrollment deleted=false and matching tenant IDs; the view uses only Session-owned tables and Attempt must not join raw Session tables. No full-ID/history materialization.
- Cohort page/count stable by enrollment publicId; history by attemptNumber DESC then publicId; assigned sessions by opensAt ASC nulls-last then publicId. All predicates tenant and deleted=false.

## Files

Paths relative to pte-api.

Existing:

- `app/src/main/java/com/pte/session/SessionService.java`
- `app/src/main/java/com/pte/session/internal/repository/{EnrollmentRepository,ProctorAssignmentRepository,ExamSessionRepository}.java`
- `app/src/main/java/com/pte/session/internal/service/{EnrollmentService,EntitlementService}.java`
- `app/src/main/java/com/pte/session/dto/response/package-info.java`
- `app/src/main/java/com/pte/attempt/AttemptService.java`
- `app/src/main/java/com/pte/attempt/internal/repository/{ExamAttemptRepository,AttemptHeartbeatRepository}.java`
- `app/src/main/java/com/pte/attempt/dto/response/package-info.java`
- `app/src/main/java/com/pte/identity/IdentityService.java`
- `app/src/main/java/com/pte/identity/internal/repository/UserRepository.java`
- `app/src/main/java/com/pte/identity/dto/response/package-info.java`

Proposed:

- `app/src/main/java/com/pte/session/internal/service/ProctorMonitoringQueryService.java`
- `app/src/main/java/com/pte/session/dto/response/{ProctorMonitoringSessionView,MonitoringEnrollmentView}.java`
- `app/src/main/java/com/pte/attempt/internal/service/AttemptMonitoringQueryService.java`
- `app/src/main/java/com/pte/attempt/dto/response/{MonitoringAttemptView,MonitoringAttemptSummaryView}.java`
- `app/src/main/java/com/pte/identity/dto/response/StudentDisplayNameView.java`
- `app/src/main/resources/db/migration/V92__proctor_monitoring_enrollment_view.sql` (latest observed V91; recheck next unused integer before creation)
- `app/src/test/java/com/pte/session/internal/service/ProctorMonitoringQueryServiceTest.java`
- `app/src/test/java/com/pte/attempt/internal/service/AttemptMonitoringQueryServiceTest.java`
- `app/src/test/java/com/pte/attempt/internal/repository/AttemptMonitoringProjectionIntegrationTest.java`

## Steps

1. Preflight actual projection/NamedInterface conventions, migration columns and existing opt-in PostgreSQL tests. Reuse allowlisted dedicated localhost DB + unique schema + scoped cleanup pattern, opting in with `-Dpte.proctor.postgres.integration=true`; never count skipped opt-in as evidence. Capture membership view SQL contract and integrity queries before writing aggregate. No Testcontainers addition by default.
2. Export Session metadata + assignment role and minimal enrollment paging/count/membership. Caller tenant comparison is explicit; no privileged HOST_ADMIN bypass in Proctor projection.
3. Add Session-owned membership view containing only current tenant/session/student identifiers; contract excludes deleted session/enrollment. Add integrity report for duplicate memberships/tied attemptNumber; historical orphan attempts excluded and reported. Test SCHEDULED enrollment removal plus CLOSED history.
4. Add Attempt batch latest + attemptCount (page IDs only), heartbeat, bounded history and fixed-size enrolled-latest status aggregate joining exported membership view. SQL latest selection handles retries and soft-deleted attempts. Do not fetch all attempts and group in Java.
5. Add minimal Identity bulk display names for current tenant and fresh active PROCTOR membership check used next phase. Missing/deleted identity display uses safe localized UI fallback; unauthorized identity does not gain control.
6. Expose scoped Attempt control method contract for tenant + exam + target (implementation hardening in 02), compile/module-boundary checks and selected projection tests if authorized. Inspect PostgreSQL query count/EXPLAIN for 25 versus 100 students with retry history; add index only if justified.

## Success Criteria

- Counts match active enrolled students even with orphan historical attempts, removed enrollment, retries, no attempt and soft deletes; duplicate/tie integrity preflight fails explicitly.
- Enriched page uses bounded batch result sizes and query count independent of student count (25 versus 100); no pinned answers/score/email returned.
- Cross-module exports pass ModuleStructureTest; queries/stable pagination and migration verified against PostgreSQL.

## Build and Test Commands

From pte-api: `.\mvnw.cmd -pl app -DskipTests compile`. Selected authorized tests: `.\mvnw.cmd -pl app '-Dtest=ModuleStructureTest,ProctorMonitoringQueryServiceTest,AttemptMonitoringQueryServiceTest,AttemptMonitoringProjectionIntegrationTest' '-Dpte.proctor.postgres.integration=true' test` after these files and safe dedicated DB config exist. Record DB fixture actually used; H2/mock/skipped tests are not PostgreSQL migration/view evidence.

## Quality and Testing State

- Quality: not evaluated. Decision: pending user check flags. Profile: not recorded.
- Testing: not started. Decision: pending; default mode, TDD not selected.
- If TDD selected: ck:test prepares RED_READY from count/orphan/retry/tenant/pagination acceptance before implementation. These are behavioral failures, not class-existence checks.
- Risks: deliberate SQL export coupling, migration compatibility, query plan and PostgreSQL test runtime.
