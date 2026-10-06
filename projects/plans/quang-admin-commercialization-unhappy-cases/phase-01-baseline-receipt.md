# Phase01 baseline receipt

Date: 2026-10-05, Asia/Bangkok. User authorized ck:cook --hard; tests=yes/quality=yes for phase01, no TDD. The initial baseline status below was BLOCKED; the completion update at the end records the later isolated PostgreSQL checkpoint and HARD confirmation. API f070e38/web eafe3c8 were clean before and after checks; documentation from planning was already dirty and preserved. No application/migration edits, commit, push or deployment.

## Fresh commands and outcomes

Backend commands from pte-api, explicitly using installed `C:/Program Files/Java/jdk-21` through process-local JAVA_HOME/Path (shell default was Java24):

- `./mvnw.cmd -pl app -DskipTests compile`: exit0, BUILD SUCCESS,2.248s; incremental compile reported classes up to date, not a clean rebuild.
- `./mvnw.cmd -pl app test`: exit1, BUILD FAILURE,1m14s. Surefire XML and console agree:1124 tests,4 failures,7 errors,26 skipped;1087 passed.
- From pte-web: `pnpm --filter @pte/api-client test`: exit0,16 files/381 tests passed; `pnpm --filter @pte/api-client typecheck`: exit0.
- `docker version`/`docker ps`: Docker engine reachable, existing local stack running. No container restart, existing DB connection or business-data mutation performed.

Backend raw machine receipts remain under `pte-api/app/target/surefire-reports/`; do not export raw bodies/stack traces containing fixture secrets. The sanitized JSON lists every failed test without raw payloads.

## Failed baseline groups

| Suite | Failures | Errors | Evidence / boundary |
|---|---:|---:|---|
| ExamGenerationServiceTest |1|0|generation ordering assertion |
| AttemptLifecycleCapabilityTest |1|1|capability expectation and unnecessary stubbing |
| AttemptLifecycleServicePlayAudioTest |2|5|replay/expiry assertions and NOT_CURRENT_TASK |
| ModuleStructureTest |0|1|notification listener uses non-exposed support events/enums |

All were observed before any production/test source change. The current11 failure/error total matches the historical count, but matching counts do not prove identical root causes or authorize fixes. Current XML is the fresh baseline; no historical evidence was relabeled as this run.

Skipped: ArchiveLifecyclePostgresIntegrationTest11, QuestionPublicationMigrationPostgresTest1, InboxAnnouncementStorePostgresIntegrationTest1, InboxDeliveryStorePostgresIntegrationTest11, InboxReadStorePostgresIntegrationTest2. Archive test requires explicit dedicated URL/schema; it was not supplied. No clean/legacy migration rehearsal, committed PostgreSQL race or authenticated browser evidence exists for this phase yet. Existing local postgres is NOT an isolated test target.

## Source/contract inventory

Existing lifecycle Plan guard/soft Delete and locked inner issuance remain unchanged. BaseEntity.deleted already exists in original tables; V77__question_publication_provenance adds monotonic question history, not Plan tombstone columns. Current maximum migration is77; allocate future numbers afresh, never rewrite V77.

Application detail GET already exists at `/api/v1/applications/{publicId}`, but api-client currently exports no getApplication wrapper. Phase02 adds client wiring rather than a duplicate backend route. Current application review response/atomicity and schema lengths are inventoried, not assumed fixed.

Current schema: organization name/type/email/phone255, requestedCode32, rejectReason500; tax schema255 while DTO existing max64 is intentionally retained. Plans price NUMERIC(19,2), name/description255, currency3; license code32/revokeReason255. Current Plan has no version. Reuse existing DomainException mapping: DTO/malformed400, owning domain status, auth403, optimistic conflict409, unexpected sanitized500. New missing-header/query-validation mappings must be explicit owning contracts, not generic500.

Freeze future choices to the approved master: Plan expectedVersion mandatory; admin license namespace with safe metadata, UUID keys retained and replay before dynamic expiry/eligibility; sorted exact SCHEDULED scope digest bound to actor/resource with5-minute lifetime and locked recomputation; old writers fail closed and old raw GET410 at controlled cutover; PagedResult inner data/meta with page0/default25/max100. These are future contracts, not available endpoints. New codes/messages go in owning Constants, never this phase's source edits.

Caller inventory: vendor commercialization/api.ts owns Plan edit/activation/archive and license list/issue/revoke. Tenant redemption uses existing POST body token contract and must remain compatible. Shared client endpoint inventory tests currently include legacy routes; additive new paths require new fixtures in later phases. Do not expose token URL/cache during compatibility cutover.

## Stop and resume

The initial checkpoint did not allow phase02 to begin while phase01 dependencies were incomplete. Baseline repair and isolated PostgreSQL setup were not silently waived. The separate repair was authorized, the complete backend baseline was rerun, and the relevant PostgreSQL gates were rerun below. The API-client pass is not full backend/release proof.

## Completion update

The dedicated container `codex-archive-lifecycle-pg` was started on `127.0.0.1:55439`; the application's `pte-postgres` database was not used. With Java 21, the following command passed 12 tests with 0 failures, errors, or skips:

`./mvnw.cmd -pl app '-Dtest=ArchiveLifecyclePostgresIntegrationTest,QuestionPublicationMigrationPostgresTest' '-Dlifecycle.test.db.url=jdbc:postgresql://127.0.0.1:55439/lifecycle_test?currentSchema=migration_clean' test`

The result covers V1-V77 migration validation, legacy publication provenance, committed tombstone/audit behavior, rollback, lock serialization and 10-repetition lifecycle races. The user's request to continue to the next phase is the recorded HARD-mode confirmation. Phase01 is complete and phase02 is now eligible for activation. No application data, commit, push or deployment was performed.
