# Phase 3: Remove Rubric and Explanation

Dependencies: Phase 2 (the new pipeline must already own scoring). Blocks Phase 5 final cleanup.

## Requirements
The rubric module, the practice explanation feature and the vendor-web practice-rubrics pages no longer exist, a migration drops their tables and columns, and the build, tests and review endpoint still work.

## Files
Backend base: `d:\FPT\9thSemester\pte\pte-api\app\src\main\java\com\pte\`.
- Delete: whole `rubric` module (`api:rubric/**`); in `practice`: `PracticeRubricBindingService`, `PracticeExplanationController`, `PracticeExplanationService`, `PracticeExplanationJobService`, `PracticeExplanationJobTransitionService`, `PracticeExplanationOutboxDispatcher`, `PracticeExplanationWorker`, `PracticeExplanationRabbitMqConfig` and their job/outbox entities, repositories, DTOs; in `scoring`: `PracticeGeminiExplanationGenerator`, `PracticeExplanationGenerator`, `PracticeAiProperties`, `PracticeGeminiConfig`; tests `PracticeExplanationGeneratorContractTest` and all rubric/explanation tests (find with Grep before deleting).
- Change: `practice/internal/domain/PracticeSessionItem.java` and mapper/DTOs (drop rubric columns and fields); move the review endpoint into the session controller (or a small review controller) keeping `PracticeReviewService` and `PracticeReviewResponse`; `src/test/java/com/pte/ModuleStructureTest.java` (remove "rubric" from the expected modules); `app\src\main\resources\application.yml` (PRACTICE_AI block near lines 19-28); `d:\FPT\9thSemester\pte\pte-api\docker-compose.services.yml` (lines ~42-50, has uncommitted user edits - edit only the PRACTICE_AI lines); `d:\FPT\9thSemester\pte\pte-api\.env.example` (lines ~72-80).
- Add: Flyway migration V131 (separate file from V130; never fold, an applied V130 fails its checksum) dropping rubric tables, explanation job/outbox tables and the rubric columns on the practice session item.
- Frontend delete: `web:apps/vendor-web` practicerubric feature and practice-rubrics routes; `web:packages/api-client` practicerubric types, requests and exports; navigation entries in `navigation.tsx` and `navigationConstants.ts`; vendor-web i18n keys used only by those pages.
- Do not touch: unrelated "rubric" wording in scoring scorers and examiner UI; pte-app has no rubric references.

## Steps
1. List every remaining reference to the rubric and explanation classes with a search, and confirm the new pipeline no longer uses any of them.
2. Move the review endpoint out of the explanation controller and keep its behavior and response unchanged.
3. Delete the backend rubric module, the practice explanation classes and the scoring-side generator and config classes together with their tests.
4. Write the migration that drops the related tables and columns, and remove the matching domain fields, mapper entries and response fields.
5. Update the module-structure test and clean the configuration keys in the application settings, the example env file and the services compose file without disturbing the user's uncommitted edits.
6. Remove the vendor-web practice-rubrics pages, api-client types and requests, navigation entries and orphaned translation keys.
7. Clean broker leftovers: delete or purge the old explanation exchange/queue/DLQ on the local RabbitMQ (removing the declarations leaves orphan queues with messages), and complete or invalidate in-flight practice sessions holding WRITE_EMAIL or rubric-bound items (V129 only invalidated legacy objective sessions); put this in V131 where it is data, and in a note to the user where it is broker state.
8. Run backend compile and tests, then the web type check and lint for both web packages. Flyway applies V131 on the first boot or context-load test, so the local DB backup from Phase 2 step 0 must already exist before this step.

## Success Criteria
- Backend compiles and the full test suite passes with the rubric module gone.
- Searching the backend for the removed class names and for the PRACTICE_AI settings returns no matches.
- The review endpoint still returns the same response shape (covered by an updated test).
- Web type check and lint pass in vendor-web and the api-client package; the practice-rubrics route no longer exists in navigation.
- The module-structure test passes without "rubric".

## Risks
- Deleting a class still referenced at runtime (reflection or config): compile plus context-load test.
- Over-deleting unrelated "rubric" text: delete by file list only, review the diff with a grep for the word afterwards.
- Destructive migration: acceptable (no production); no reverse migration is provided, rollback = restore the local backup taken before Phase 2. Between Phases 2 and 5 the pte-practice frontend is knowingly broken (answer contract changed, explanation endpoints removed); acceptable with no production, do not demo in that window.
- Overwriting the user's uncommitted compose edits: patch only the targeted lines.
- Review endpoint URL change breaks pte-practice: keep the path stable (open question 8).

## Execution Log
<!-- Filled by /ck:cook at the end of this phase — leave placeholders when planning -->

### Errors Encountered
- None blocking. `.env.example` could not be edited (privacy hook); the user removes the `PRACTICE_AI_*` lines.

### Root Cause
- n/a (removal phase).

### Resolution
- Backend: deleted `com.pte.rubric` (main + tests), all practice explanation classes, `PracticeRubricBindingService`, and the scoring-side `PracticeExplanationGenerator`, `PracticeAiProperties`, `PracticeGeminiConfig`, `PracticeGeminiExplanationGenerator` with their tests.
- Review endpoint moved into `PracticeSessionController` (same URL and response); new `PracticeSessionControllerReviewTest`.
- Trimmed `PracticeConstants`, `PracticeSessionItem` (rubric, form_* and objective hash columns), `PracticeSessionItemService` (constructor), `recordInline`, `ModuleStructureTest` ("rubric" removed), `application.yml` (`practice.ai` removed).
- `V131__drop_practice_rubric_and_explanation.sql` (destructive, NOT applied locally). Not done: cleaning in-flight WRITE_EMAIL sessions (belongs to Phase 4).
- `docker-compose.services.yml`: `PRACTICE_AI_*` replaced by `PRACTICE_SCORING_*`.
- Web: removed vendor-web `practicerubric` feature and routes, nav entry, api-client types/requests. Examiner "rubric" wording untouched.
- Leftovers for the user: `PRACTICE_AI_*` lines in `.env.example`; orphan RabbitMQ `pte.practice.explanation*` exchange/queues; DB backup before first boot (V130 + V131).

### Test Results After Fix
- Full backend suite: 2728 tests, 0 failures, 0 errors, 77 skipped (330 suites).
- api-client and vendor-web typecheck clean; vendor-web lint 0 errors (2 pre-existing `<img>` warnings).
- No matches left for removed class names or `PRACTICE_AI` in pte-api.
