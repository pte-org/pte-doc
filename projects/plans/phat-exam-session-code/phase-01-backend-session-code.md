# Phase 1: Backend — session code column, generator, creation hooks

Repo: pte-api (`d:\FPT\9thSemester\pte\pte-api`). Java root: `app/src/main/java/com/pte/`.

## Requirements
Every new `ExamSession` gets a unique, immutable `sessionCode` at creation through both creation paths, existing rows are backfilled by migration V72, and the code is returned in `SessionResponse`.

## Steps
1. Write the V72 migration: add a nullable `session_code` column, backfill existing rows, re-randomize any duplicates until none remain, then set NOT NULL and add the UNIQUE constraint (see Migration Notes).
2. Add `sessionCode` to the `ExamSession` entity as non-null, unique, non-updatable, length 24.
3. Add a code generator in the session module that builds tenant part, date part via `opensAt.atZone(ZoneId.of("Asia/Ho_Chi_Minh"))` formatted `yyMMdd`, and a secure-random 4-char suffix, with a package-private constructor taking a `SecureRandom` for tests (same pattern as `LicenseKeyGenerator`).
4. Add an existence lookup on the session repository, and make the generator pre-check it in a loop of at most 5 attempts before failing with `IllegalStateException`.
5. Call the generator in both creation paths (draft creation in `ExamOrchestrationService`, direct creation in `SessionLifecycleService`) immediately before the save — in `SessionLifecycleService` that is after the snapshot generation (`generateAndPublish`, ~line 101), so all validation has passed first. Leave `updateDraft` untouched so the code never changes.
6. Add `sessionCode` to `SessionResponse` (keeping the legacy 10-arg constructor compiling) and to `SessionMapper.toResponse`.
7. Update existing tests that construct the two services or the response, then write the new tests below.

## Files to Create or Modify

| File (relative to `app/src/`) | Action |
|---|---|
| `main/resources/db/migration/V72__exam_session_code.sql` | Create |
| `main/java/com/pte/session/domain/ExamSession.java` | Modify — add `sessionCode` field |
| `main/java/com/pte/session/internal/service/SessionCodeGenerator.java` | Create — `@Component`, depends on `TenancyService` and `ExamSessionRepository`, package-private `SecureRandom` constructor |
| `main/java/com/pte/session/internal/repository/ExamSessionRepository.java` | Modify — add `existsBySessionCode` |
| `main/java/com/pte/session/internal/service/ExamOrchestrationService.java` | Modify — set code in `createDraft` (before `saveAndFlush`, ~line 178); do NOT touch `updateDraft` (~line 262) |
| `main/java/com/pte/session/internal/service/SessionLifecycleService.java` | Modify — set code in the create method (~line 103, before save at ~129); stays inside the existing `DataIntegrityViolationException -> translateOverlap` try |
| `main/java/com/pte/session/internal/dto/response/SessionResponse.java` | Modify — add `sessionCode` component; legacy constructor passes `null` |
| `main/java/com/pte/session/internal/mapper/SessionMapper.java` | Modify — pass `session.getSessionCode()` |
| `test/java/com/pte/session/internal/service/SessionCodeGeneratorTest.java` | Create |
| `test/java/com/pte/session/internal/service/ExamOrchestrationServiceTest.java` | Modify — new constructor arg (line ~105) + code assertions |
| `test/java/com/pte/session/internal/service/SessionLifecycleServiceTest.java` | Modify — new constructor arg (line ~91) + code assertion |

`new SessionResponse(` call sites (main + test): only `SessionMapper.toResponse` (`SessionMapper.java:19`, the full-argument form). No test or other main class calls it; the legacy 10-arg constructor currently has zero callers but must still compile. Re-grep before editing in case the tree moved. Also re-check places that mock or build `ExamSession` in tests (`ProctorSessionServiceTest`, `EntitlementServiceTest`, `EnrollmentServiceTest`, `SessionClassAssignmentServiceTest`, `SessionExamPreviewServiceTest`) — they do not need a code unless they go through the mapper.

## Migration Notes (V72, PostgreSQL)
- Test DB compatibility: automated tests do NOT run Flyway. `app/src/test/resources/application.yml` disables Flyway and uses H2 with `ddl-auto=create-drop` for `@DataJpaTest`; there is no Testcontainers setup. V72 is therefore written for PostgreSQL only (as V71 and earlier are) and must be verified manually on a Postgres DB. The H2 schema is derived from the entity, so the UNIQUE/NOT NULL on the entity still exercises in repository tests.
- Backfill tenant part: LEFT JOIN `tenants` on `tenants.public_id = exam_sessions.tenant_id`; use the code with hyphens stripped, uppercased, first 8 chars; fall back to `PTE` when no tenant row exists. Date part: format `opens_at` converted to `Asia/Ho_Chi_Minh` as `YYMMDD`.
- Random suffix must be evaluated per row. `random()` is volatile and runs per row when used directly in the UPDATE's SET expression; the trap is an uncorrelated scalar subquery (e.g. `(SELECT string_agg(...) FROM generate_series(1,4))`), which Postgres evaluates once and would give every row the same suffix. Prefer a small temporary plpgsql/SQL helper `pg_temp`-style function `random_session_suffix()` called per row, built from the 32-char alphabet, and drop it at the end of the migration.
- After the first pass, a `DO` block loops: re-randomize the suffix only for rows with `row_number() OVER (PARTITION BY session_code ORDER BY id) > 1` (keep the first row of each group), repeat until none remain; cap at 20 iterations and `RAISE EXCEPTION` if exceeded.
- Only after zero duplicates: `SET NOT NULL`, then add constraint `uq_exam_sessions_session_code` UNIQUE on `session_code`.
- Rows are soft-deletable (`deleted` flag) but uniqueness covers deleted rows too — intended (globally unique).
- Verification script (CI never runs Flyway): write `verify-v72.sql` next to this plan (pte-doc, not in pte-api) with assertions that each return 0 rows/0 count: rows with NULL `session_code`; codes appearing more than once; codes not matching `^[A-Z0-9]{1,8}-[0-9]{6}-[A-HJ-NP-Z2-9]{4}$`; plus a check that `uq_exam_sessions_session_code` exists in `pg_constraint`. Exercise the dedupe loop once by running the loop body against a scratch copy where two rows are forced to the same code.

## Success Criteria
- Run from `d:\FPT\9thSemester\pte\pte-api`: `./mvnw -pl app test -Dtest=SessionCodeGeneratorTest,ExamOrchestrationServiceTest,SessionLifecycleServiceTest` passes.
- Full regression `./mvnw -pl app test` passes, including `ModuleStructureTest` (session -> tenancy dependency is via the public `TenancyService` facade only).
- Generated codes match `^[A-Z0-9]{1,8}-\d{6}-[A-HJ-NP-Z2-9]{4}$`.
- On a local Postgres seeded with existing sessions (several in the same tenant and same opens date), `./mvnw -pl app spring-boot:run` (or the project's usual Flyway start) applies V72, and every assertion in `verify-v72.sql` passes. Local Postgres is the agreed verification environment (no prod-copy rehearsal).
- `GET` session responses (host endpoints) include `sessionCode`.

## Tests to Write
- `SessionCodeGeneratorTest` (plain JUnit/Mockito, no Spring):
  - format regex above.
  - tenant normalization: `fpt-edu-vn` -> `FPTEDUVN`; code longer than 8 chars truncated to 8; hyphens removed.
  - timezone boundary: `opensAt = 2026-10-09T17:30:00Z` -> date part `261010`.
  - collision retry: exists check returns true for the first N calls then false -> returns the later candidate (seeded or mocked `SecureRandom`).
  - failure: exists check always true -> `IllegalStateException` after exactly 5 attempts.
- `ExamOrchestrationServiceTest`: created draft has a non-null code; after `updateDraft` changes `opensAt`, the code is unchanged.
- `SessionLifecycleServiceTest`: created session has a non-null code; overlap translation still works.
- Follow existing convention: Mockito `@ExtendWith(MockitoExtension.class)` unit tests, constructed with `new` (see `EntitlementServiceTest`).

## Risks
- Constructor change on two services breaks existing `new ...Service(...)` test setups: update both listed tests in this phase.
- Tenant lookup failure (`TenantNotFoundException`) at creation: let it propagate; do not fall back at runtime (fallback `PTE` is for backfill only).
- Date part uses `opensAt` as sent at creation; later reschedule drifts (accepted).
- Backfill failure leaves a half-applied migration: Flyway runs it in one Postgres transaction, so it rolls back. The seeded local run must cover several sessions with the same tenant and date, plus a session whose tenant row is missing (`PTE` fallback).

## Execution Log

### Errors Encountered
- Full regression `./mvnw -pl app test`: 993 run, 5 failures + 6 errors, all outside the changed code: `ModuleStructureTest.all_fourteen_business_modules_plus_shared_are_detected` (unexpected module `support`), `ExamGenerationServiceTest.generate_orderIsSpeakingWritingReadingListening_thenBySequence`, `AttemptLifecycleCapabilityTest` (assertion + `UnnecessaryStubbingException`), `AttemptLifecycleServicePlayAudioTest` (`NotCurrentTaskException: NOT_CURRENT_TASK`).
- Edge-case seed on the scratch DB: `duplicate key value violates unique constraint "uk_tenants_tax_code"`.

### Root Cause
- Pre-existing, unrelated to this phase: the module list predates the `support` module (PR #56), and the failing assessment/attempt tests touch none of the changed classes. Not re-run on a clean tree to prove it.
- The seed copied the existing tenant row including its unique `tax_code`.

### Resolution
- Left as is (out of scope); flagged to the user.
- Seed sets `tax_code = NULL` for the copied tenant (scratch script only, not part of the deliverable).

### Test Results After Fix
- `./mvnw -pl app test -Dtest=SessionCodeGeneratorTest,ExamOrchestrationServiceTest,SessionLifecycleServiceTest` -> 6 + 9 + 28 passed, 0 failed.
- `./mvnw -pl app test` -> 993 run, 11 failing (the pre-existing ones above); `ModuleStructureTest` module-dependency verification passes, only its module-count test fails.
- User's docker compose stack (`--build`, volume `pte_postgres_data_localtest`): Flyway applied V72 (`flyway_schema_history` version 72, success = t); `verify-v72.sql` on DB `pte` -> "V72 verification passed" (dedupe exercise resolved in 1 iteration); existing session became `SEEDPTEL-260929-99LA`.
- Scratch DB `pte_v72_check` (copy of `tenants` + `exam_sessions`, V72 reverted, 12 edge rows seeded, V72 re-run): `verify-v72.sql` passed and all edge assertions passed. 6 same-tenant/same-day rows got distinct codes, 17:30Z -> `261010`, 16:59:59Z -> `261009`, soft-deleted row coded, missing tenant -> `PTE-261010-GTKX`, `hanoi-university-of-tech` -> `HANOIUNI-...`. Scratch DB dropped afterwards.
- Cook Step 3 (tester) added two test files:
  - `internal/repository/ExamSessionRepositorySessionCodeTest` is a `@DataJpaTest` with 6 tests:
    - The tenant + not-deleted lookup works.
    - `existsBySessionCode` is global and includes soft-deleted rows.
    - A duplicate code across tenants throws `DataIntegrityViolationException`.
    - The `updatable = false` column holds after a flush.
  - `internal/mapper/SessionMapperTest` has 1 test, which checks that `toResponse` maps `sessionCode`.
  - The tester's first draft set the default `OFFICIAL_EXAM` mode without STRICT lockdown, so the domain rejected it. The tester fixed its own setup by switching to `PRACTICE`; this was not a production bug.
  - Full `./mvnw -pl app test`: 996 run, 11 failing, and these are exactly the pre-existing ones.
