# Task-type instruction — verification report

**Date:** 2026-10-30 · **Plan:** `pte-doc/projects/plans/quang-task-type-instruction/` · **Branches:** pte-api `quang/feat/maintain-v2`, pte-web `quang/feat/maintain-v2`, pte-app `quang/maintain-v2` (uncommitted)

## Result

| Check | Result |
|---|---|
| API phase tests (itembank, assessment, attempt, session, practice, architecture) | PASS for every new/changed test; 17 pre-existing failures elsewhere (below) |
| Flyway V13 on a clean Postgres | PASS for V13 SQL; Flyway itself stops at V12 (below) |
| pte-web typecheck / lint / tests | PASS |
| pte-app analyze / tests | PASS for the feature; 3 pre-existing failures (below) |
| Manual E2E (vendor-web edit → student attempt and host preview) | NOT RUN — needs a local DB reset |

## API

- New/changed tests: `DynamicTaskTypeServiceTest` 6/6, `TaskTypeInstructionLookupTest` 2/2, `ExamItemRuntimeResolverTest` 3/3,
  `ExamItemLoaderTest` 20/20, `SessionExamPreviewServiceTest` 6/6, `HostExamPreviewReadOnlyTest` 1/1 (asserts the JSON field
  `taskTypeInstruction`), `AttemptMapperTest` 14/14.
- Module sweep: 898 tests, 7 failures + 10 errors, none in code touched by this plan:
  - `PackageDensityTest`: `billing/internal/dto/response` has 17 classes (limit 15) after the dev merge of PR #86.
  - `SessionLifecycleServiceTest`, `ExamWorkflowServicesTest`: `SESSION_SUBSCRIPTION_NOT_FOUND` / `EXAM_PREFLIGHT_FAILED`
    after commit `3a95d6fc` changed subscription rules without updating tests; `SessionSubscriptionRules.java` also has
    uncommitted edits.

## Migration

- Throwaway `postgres:17` container, schema `migration_clean`, Flyway via `LicenseIssuePostgresIntegrationTest`:
  V1–V11 applied, then **V12 failed**: `relation "public.exam_definition_items" does not exist`. V12
  (`deduplicate_exam_definition_items`, untracked) hard-codes the `public.` schema, so it breaks every non-`public` Flyway run,
  including the repository's Postgres integration tests. It works on the real `public` schema.
- V12 (with `public.` removed in a temporary copy) and V13 applied with `psql` on the same schema:
  `instruction varchar(500)` nullable; 23/23 standard task types filled; longest text 181 characters.
- Texts are identical to `pte-app` `TaskTypeMeta.instruction` (scripted comparison, 23/23). The local-schema dev-seed
  uses the same statements.
- Stale build output: `app/target/classes/db/migration` still held the pre-renumbering V9–V11 files, which makes Flyway
  report a duplicate version 9. Removed; a `mvnw clean` has the same effect.

## Web and app

- pte-web: vendor-web vitest 78/78, api-client vitest 626/626, `tsc --noEmit` clean for both, turbo lint 0 errors
  (2 pre-existing `<img>` warnings in `questionbank`).
- pte-app: new and changed tests 22/22; `exam_attempt` + `exam_preview` 482/482; full suite 746 passed, 3 failed in
  `device_check/test_mic_and_sound_screen_test.dart` (the uncommitted `lib/core/audio/volume_service.dart` change is in the
  same audio path). `flutter analyze` on touched paths: 1 pre-existing `unnecessary_cast` in
  `exam_attempt_repository_impl.dart:63`.

## Manual E2E — pending

The local `pte` database has the old Flyway numbering (V9 = preview-ready, V10 = rename, V11 = dedupe). A backend built from this
branch fails Flyway validation on it. Steps once the database is reset:

1. Drop and recreate the local `pte` database (keep Caddy/other volumes), rebuild `app`
   (`docker compose ... up -d --no-deps --build app`) and let Flyway apply V1–V13.
2. vendor-web, Task Type Catalog: edit Read Aloud (runtime-locked). The instruction field is enabled. Save new text.
3. pte-app: start a new attempt containing Read Aloud, and open a Host Preview. Both show the new text.
4. `UPDATE question_types SET instruction = NULL WHERE task_type_key = 'READ_ALOUD';` then open a new attempt. The built-in
   text "Read the text aloud as naturally as possible." is shown.

An attempt already in progress keeps the text it loaded (Redis view cache, up to 24 hours). Check step 3 with a new attempt.

## Follow-ups outside this plan

- V12: drop the `public.` prefix before committing.
- `dart format` was run across `pte-app/lib/features/exam_attempt` and `exam_preview` by mistake. 47 files that only differed by
  formatting were restored to HEAD; `listening_strings.dart` (already locally modified) keeps formatter output. Up to two of
  the restored files may have been local formatting-only edits.
