# Phase 1: Remove `timingMode` (backend + migration + tests + vendor-web)

## Requirements

The `scoretemplate` module and its vendor-web admin UI no longer have any trace of `timingMode`/`TimingMode` — not in the entity, DTOs, admin API responses, database schema, or the admin score-template table — while all existing exam-taking/scoring behavior stays unchanged (this field was never read at runtime).

## Files

**Deleted**
- `pte-api/app/src/main/java/com/pte/scoretemplate/domain/enums/TimingMode.java` — the enum itself.

**Backend — edited**
- `pte-api/app/src/main/java/com/pte/scoretemplate/domain/ScoreTemplateItem.java` — remove the `timingMode` field, its `@Column` annotation, and the now-unused `TimingMode` import.
- `pte-api/app/src/main/java/com/pte/scoretemplate/dto/request/ScoreTemplateItemRequest.java` — remove `timingMode` from the request record.
- `pte-api/app/src/main/java/com/pte/scoretemplate/dto/response/ScoreTemplateItemResponse.java` — remove `timingMode` from the response record.
- `pte-api/app/src/main/java/com/pte/scoretemplate/internal/mapper/ScoreTemplateMapper.java` — drop the `item.getTimingMode().name()` argument from `toItemResponse`, keeping remaining constructor arguments in order.
- `pte-api/app/src/main/java/com/pte/scoretemplate/internal/service/ScoreTemplateAdminService.java` — remove the clone-to-draft copy line (`copy.setTimingMode(source.getTimingMode())`) and the create/update parse line (`item.setTimingMode(parseEnum(TimingMode.class, request.timingMode(), request.taskType()))`); remove the now-unused `TimingMode` import; leave the shared `parseEnum` helper and its `ScoringMethod` call site untouched.

**Database — new file**
- `pte-api/app/src/main/resources/db/migration/V39__drop_score_template_timing_mode.sql` — `ALTER TABLE score_template_items DROP COLUMN timing_mode;` (re-verify immediately before creating this file that `V38__student_roster_account_metadata.sql` is still the latest migration on disk; renumber if a newer one has landed).

**Backend tests — edited**
- `pte-api/app/src/test/java/com/pte/scoretemplate/internal/service/ScoreTemplateActivationValidatorTest.java` — remove the `item.setTimingMode(TimingMode.FIXED)` line and the now-unused `TimingMode` import.
- `pte-api/app/src/test/java/com/pte/scoretemplate/internal/service/ScoreTemplateSeedMigrationTest.java` — remove all `timing_mode`/`TimingMode` column parsing and per-row assertions tied to the V14 seed table (read the whole file first — this test does column-position based parsing of the seed `INSERT`, so removing one column may shift how remaining columns are read/compared).
- `pte-api/app/src/test/java/com/pte/scoretemplate/internal/service/ScoreTemplateAdminServiceTest.java` — remove any `timingMode`/`TimingMode` usage in request/entity test fixtures.

**Frontend — edited**
- `pte-web/packages/api-client/src/types/scoretemplate/index.ts` — remove `timingMode` from the type(s) mirroring the item request/response.
- `pte-web/apps/vendor-web/features/scoretemplate/types.ts` — remove `timingMode` from the local feature type(s).
- `pte-web/apps/vendor-web/features/scoretemplate/components/_ScoreTemplateItemTable.tsx` — remove the TIMING column definition and its cell rendering.

**Docs — no action required**
- `pte-doc/projects/plans/phat-score-template-scoring/*.md` and `pte-doc/projects/plans/phat-score-template-exam-generation/spec.md` will become stale references to `timingMode`; this repo does not rewrite historical plan docs after the fact, so leave them as-is.

## Steps

1. Re-confirm `V38__student_roster_account_metadata.sql` is still the latest migration file, then add `V39__drop_score_template_timing_mode.sql` dropping the `timing_mode` column from `score_template_items`.
2. Remove the `TimingMode` enum, the entity field/annotation, and both DTO fields (request + response), fixing up imports.
3. Remove the two `ScoreTemplateAdminService` call sites (clone-copy, create/update parse) and the mapper argument, without touching the shared `parseEnum` helper or the `ScoringMethod` call site.
4. Update the three affected backend test files to compile and pass without any `timingMode`/`TimingMode` reference, paying special attention to `ScoreTemplateSeedMigrationTest`'s column-position parsing of the seed data.
5. Remove `timingMode` from the two vendor-web type files and delete the TIMING column from the admin score-template table component.
6. Run a repo-wide case-sensitive grep for `timingMode` and `TimingMode` across `pte-api` and `pte-web` (excluding `pte-doc`) and confirm zero remaining hits.

## Tests

- `./mvnw test -pl app` (from `pte-api/`) — full backend suite green, including `ScoreTemplateActivationValidatorTest`, `ScoreTemplateSeedMigrationTest`, `ScoreTemplateAdminServiceTest`, and `ModuleStructureTest`.
- Manual/automated check that Flyway applies `V39` cleanly against the dev database (`ddl-auto: validate` must not fail after the column drop matches the entity change).
- Vendor-web: run the existing scoretemplate feature's type-check/build (e.g. `tsc`/build step covering `pte-web/apps/vendor-web`) to confirm no leftover reference to a removed `timingMode` type field breaks compilation.
- Final repo-wide grep for `timingMode`/`TimingMode` across `pte-api` and `pte-web` returns no matches.

## Success Criteria

- `./mvnw test -pl app` passes with no test referencing `timingMode`/`TimingMode`.
- `timingMode`/`TimingMode` no longer appears anywhere in `pte-api` or `pte-web` (grep-verified), excluding historical docs under `pte-doc`.
- The vendor-web admin score-template item table no longer renders a TIMING column.
- Flyway successfully applies `V39__drop_score_template_timing_mode.sql` and Hibernate schema validation passes on startup.

## Risks

- `ScoreTemplateSeedMigrationTest` likely parses the V14 seed SQL by column position and asserts values per column per row (22 rows × 13 columns) — removing one column requires re-checking every remaining column index, not just deleting a line. Mitigation: read the full test file before editing and re-run it locally after the change.
- A newer migration may have landed after `V38` since this plan was written, which would make `V39` collide. Mitigation: re-check the migration directory immediately before creating the new file and renumber if needed.
- `parseEnum` in `ScoreTemplateAdminService` is shared with `ScoringMethod`; an overly broad find-and-remove could delete the helper itself. Mitigation: remove only the `TimingMode` call site and its now-unused import, verified to be the only other usage of the helper is `ScoringMethod`.
