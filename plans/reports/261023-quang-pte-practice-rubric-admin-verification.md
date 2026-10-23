# PTEPrep Practice Rubric Admin ? Verification Report

**Date:** 23 October 2026  
**Scope:** `pte-api` rubric lifecycle and Practice provenance, `pte-web` shared API client and vendor Admin Web, `pte-practice` review contract, and the related `pte-doc` plan  
**Plan:** `projects/plans/quang-pte-practice-rubric-admin/plan.md`  
**Status:** Implementation complete and ready for explicit `--hard` review confirmation; no production publish or deployment performed.

## Implemented scope

- Added the `rubric` Spring Modulith module with draft, approval, publication, retirement, override and diff operations.
- Added forward-only migrations `V122__academic_rubric_revisions.sql`, `V123__practice_explanation_contract_fields.sql`, `V124__practice_objective_results.sql` and `V125__practice_form_results.sql`. Historical Practice rows remain readable because the new provenance columns are nullable.
- Added server-side readiness validation for task mapping, task-specific required evidence, references, anchors, provenance, runtime compatibility and unsupported official/numeric score claims.
- Added server-side ownership and review separation for Academic Staff, Academic Manager, Platform Author and Platform Admin, with audit records through the shared audit service.
- Added Practice binding that pins published rubric ID, version, canonical hash, safe snapshot and runtime compatibility hash on session items. New items using a renderer not supported by the current Practice client are rejected at admission.
- Added deterministic objective and form provenance. Objective results retain evaluator version, result hash and evidence identity hash. Writing/form tasks retain word count, form status, evaluator version, result hash and evidence identity hash.
- Added a server-owned evidence manifest. It maps exact task fields to exact evidence paths; it does not advertise generic aliases, fabricated reference fields, or media that is not attached to the Gemini request. Audio/image-dependent criteria therefore remain `NOT_ASSESSABLE` until an assessor or actual model attachment is available.
- Added Gemini rubric context and provider-output allowlist checks. Provider output cannot invent criterion IDs, levels, evidence paths or numeric Writing/Speaking scores. Generic prompt/reference expansion and the inconsistent `runtimeContractVersion` alias were removed.
- Added `@pte/api-client` requests/types and vendor Admin Web routes:
  - `/admin/practice-rubrics`
  - `/admin/practice-rubrics/[publicId]`
  - `/admin/practice-rubrics/[publicId]/edit`
- Reused `@pte/ui` `DataTable`, `Modal`, `Textarea`, `Badge`, `Alert`, `Button`, `Pagination`, `Select` and shared React Query/localization patterns.
- Added readiness error visibility and disabled Submit when readiness is loading, unavailable or not ready. The backend remains the authority for direct API calls.

## Automated evidence

### Backend

Compile:

```powershell
.\mvnw.cmd -pl app clean compile
```

Result: **BUILD SUCCESS**.

Targeted rubric/provenance tests:

```powershell
.\mvnw.cmd -pl app '-Dtest=RubricDocumentValidatorTest,PracticeExplanationGeneratorContractTest,RubricMigrationVersionTest,PracticeRubricBindingServiceTest' test
```

Result: **11 tests, 0 failures, 0 errors, 0 skipped**.

The targeted set covers task-specific evidence validation, exact evidence-path rejection, unsupported Practice renderer admission, immutable rubric pinning, migration ordering and Gemini contract rejection.

Full backend regression:

```powershell
.\mvnw.cmd -pl app test -q
```

Result from `app/target/surefire-reports`: **2,645 tests, 0 failures, 0 errors, 77 skipped**.

The full suite prints existing H2 DDL warnings for PostgreSQL-specific text-array declarations and expected local Redis/RabbitMQ connection warnings; these did not fail tests.

### Shared API client

```powershell
pnpm --filter @pte/api-client typecheck
pnpm exec vitest run src/requests/practicerubric/index.test.ts
```

Result: **typecheck passed; 3 rubric request tests passed**.

The complete API-client suite was also checked: **711/712 tests passed**. One existing dashboard contract test fails because four unrelated `Student*Response` records (`StudentAttemptHistoryResponse`, `StudentDetailResponse`, `StudentPerformanceResponse`, `StudentSkillPerformanceResponse`) are not mapped by its fixture contract. This failure is outside the rubric change.

### Vendor Admin Web

```powershell
pnpm --filter vendor-web typecheck
pnpm --filter vendor-web lint
pnpm --filter vendor-web build
```

Result:

- TypeScript: passed.
- ESLint: passed with two pre-existing `@next/next/no-img-element` warnings in Question Bank files outside this change and zero errors.
- Next production build: passed and generated all three Practice Rubric routes.

### Student Practice contract

```powershell
npm run typecheck
```

Result: **passed**.

### Whitespace checks

`git diff --check` passed in `pte-api`, `pte-web`, `pte-practice` and `pte-doc`. Git reported only existing LF/CRLF normalization warnings.

## Not verified in this report

- PostgreSQL execution of V122?V125 and the partial unique-publish constraint against a live PostgreSQL instance.
- Authenticated browser interaction through Staff ? Manager ? Platform Admin override, including real permission responses.
- Real Gemini calls, media attachments, provider latency/quota, secret loading or provider availability.
- Production deployment, public routing, production data retention or publishing a real rubric revision.

These are separate verification boundaries and are not inferred from compile, mocked provider tests or the local Next build.

## Review notes

- The initial rubric revision remains a draft until an Academic Manager or Platform Admin publishes it.
- Platform Admin override uses a separate API route and requires an audit reason.
- Practice runtime rejects a missing/unpublished rubric or unsupported renderer for a new item; historical session pins remain readable.
- Writing and Speaking continue to receive qualitative rubric feedback only. AI numeric scoring is not enabled by this change.
- Media-dependent criteria are intentionally conservative: without a real attachment or approved assessor output, the provider must return `NOT_ASSESSABLE` rather than infer pronunciation, fluency or image evidence.
- The plan remains open until the user confirms the final quality-review result required by `ck:cook --hard`.
