# Phase 3: Verification, Review Fixes and Handoff

Status: Complete for targeted verification; full release gate still pending

## Commands and results

### Backend

Run from `pte-api`:

```powershell
.\mvnw.cmd -pl app "-Dtest=QuestionTypeServiceTest,QuestionTypeControllerSecurityTest" test
```

Result: BUILD SUCCESS; 10 tests passed.

The targeted tests cover:

- persisted catalog listing;
- all 23 supported task codes and representative Section/scored metadata;
- canonical metadata derivation on create;
- Section mismatch rejection;
- malformed Section rejection as `INVALID_QUESTION_TYPE`;
- deleted-row metadata lookup;
- soft delete behavior;
- controller role guard coverage.

The score-template admin service tests were also updated for empty-DRAFT creation, full replacement of a DRAFT and DRAFT-only deletion. A full backend suite was not run for this final change set.

### Frontend

Run from `pte-web`:

```powershell
corepack pnpm --filter vendor-web build
corepack pnpm --filter @pte/api-client typecheck
corepack pnpm --filter @pte/ui typecheck
corepack pnpm --filter vendor-web lint
corepack pnpm exec prettier --check <scope files>
git diff --check
```

Results:

- `vendor-web build`: passed, including TypeScript and static generation.
- `@pte/api-client` typecheck: passed.
- `@pte/ui` typecheck: passed.
- `vendor-web lint`: 0 errors; two existing warnings outside this feature.
- Targeted Prettier check: passed.
- `git diff --check`: no whitespace errors; Git only reported normal LF/CRLF conversion warnings.

An API-client Vitest run was attempted during review but could not start because Windows denied Vitest's attempt to create a temporary `ssr` directory (`EPERM`). It produced no feature test result and is not counted as a pass.

## Code-review findings addressed

The focused review found and the implementation corrected three issues:

1. **Deleted metadata lookup:** soft deleting a Question Type originally made runtime validation unable to find its requirements. `findDefinitionByCode` now includes deleted rows; new authoring still checks non-deleted active rows.
2. **Malformed Section response:** using an enum directly in the create request caused malformed JSON to fail before domain handling and could become a 500. The request now accepts a string and the service maps invalid values to the domain 400 error.
3. **Flyway checksum safety:** `V37__question_type_catalog.sql` was restored to its committed content. No applied migration was edited to add seed data.

## Known limitations and follow-up

- No real authenticated browser walkthrough was run against a running full local stack.
- No full backend regression suite or successful API-client Vitest suite was recorded for this change.
- The 23 standard rows are not automatically present in a fresh local catalog. They must be created through the Question Types UI, as explicitly required by the no-seed/no-direct-import workflow.
- Backend score-template activation still has its existing fixed standard-task validation; the new Section filtering is enforced in the admin UI and Question Type catalog. A future domain consolidation could make activation validation consume the catalog through a cross-module contract.
- Existing unrelated dirty files were not reset, reformatted wholesale or included in this feature record.

## Handoff

Recommended manual acceptance flow:

1. Sign in as `PLATFORM_ADMIN` or `PLATFORM_AUTHOR`.
2. Open Question Types and create at least one type per required Section.
3. Confirm Edit and soft Delete behavior; confirm deleted types disappear from active selectors.
4. Open Question Templates, create a DRAFT, choose a Section, verify the task dropdown is filtered, add several types and save.
5. Reopen the DRAFT, edit a row, delete the DRAFT, then clone an existing template and verify ACTIVE/RETIRED rows are not deletable.
6. Confirm no Import JSON button or file picker remains; confirm Export JSON still works if needed.

