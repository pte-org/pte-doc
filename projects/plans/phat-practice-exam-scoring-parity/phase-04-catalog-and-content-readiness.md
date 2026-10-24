# Phase 4: Catalog and Content Readiness

Dependencies: Phase 2 (supported-type set is defined by the pipeline). Best after Phase 3. Blocks Phase 5.

## Requirements
The practice catalog lists exactly the 23 exam task types as runnable when published content exists, Write Email is gone, and students receive playable prompt audio and viewable prompt images in the task content.

## Files
Backend base: `d:\FPT\9thSemester\pte\pte-api\app\src\main\java\com\pte\`.
- Change: `practice/internal/service/PracticeCatalogService.java`, `practice/internal/mapper/PracticeCatalogTaskMapper.java`, `practice/internal/constant/PracticeConstants.java` (supported renderers and types = 23, remove Write Email), `practice/internal/service/PracticeAnswerValidationService.java`, `practice/PracticeMediaBindingService.java`, `itembank/PracticeQuestionService.java`, `itembank/internal/repository/QuestionRepository.java` (published-question query around lines 78-101), `media/MediaService.java` (use the existing presign-for-read facade; `media/internal/service/CloudinaryMediaService.java` read-only reference), task-content builder in practice that embeds question content.
- Add (deferred unless the user confirms; not core to scoring parity): a local seed or publishing script for PRACTICE-pool content under the repo's existing dev-seed location (confirm location first); optional rotation of the served question (open question 3).
- Tests add/update: catalog service test (23 runnable when content exists, non-runnable when none), mapper test, prompt-media presign test, Write Email removal test, question-selection test.

## Steps
1. Align the supported task-type and renderer set with the exam profile table so that all 23 types are recognised and Write Email is removed from constants, validation and the catalog.
2. Keep the runnable gate (allowlisted, active, server-ready, renderer supported, published practice question) and verify it with one fixture per type.
3. Presign prompt audio and prompt image references through the media facade when building the task content, with a short expiry, so students never need the owner-only preview path. Presign ONLY an explicit allowlist of prompt-media fields (prompt audio, prompt image); never walk the question content generically, because `PracticeQuestionService` also exposes reference and correct answers (model-answer audio, answer text) that must never reach the student. Add a test asserting reference/correct answers and answer-key media never appear in task content, session responses or poll responses.
4. Decide with the user how a fresh local database gets PRACTICE-pool content and, if confirmed, add the seed or publish helper; ask before any DB write.
5. If rotation is confirmed, change question selection to avoid always serving the first question; otherwise record the limitation.
6. Personal Introduction is confirmed HIDDEN: remove it from the catalog, runnable set and renderer gates (22 types visible); the Phase 1 facade still classifies it as unscored. Seed script and rotation are confirmed out of scope.
7. Add the catalog, mapper, presign and selection tests.

## Success Criteria
- Catalog tests show 23 types runnable with fixtures and none runnable without content.
- A search for Write Email in practice backend code returns nothing.
- The task content for each of the 14 prompt-media renderers contains a time-limited URL, verified by test (and by the user in Phase 6).
- Existing catalog and itembank tests still pass.

## Risks
- Presigned URLs expire mid-session: choose expiry longer than the longest task timer and refetch on the client if expired.
- Seed data in the wrong pool or status stays invisible: assert the published conditions in the seed test.
- Media facade scope: only add a student-safe wrapper if the existing presign needs owner context; do not loosen owner-only preview.
- Rollback: catalog and constant changes are code-only; revert the files. Seed data is removable by its own cleanup script.

## Execution Log
<!-- Filled by /ck:cook at the end of this phase — leave placeholders when planning -->

### Errors Encountered
- New mapper test failed with NullPointerException: `Map.of().get(null)` when an item has audio but no image (or no media at all).

### Root Cause
- Immutable maps reject a null key; a task may legitimately have no audio or no image.

### Resolution
- `PracticeConstants`: removed Write Email, REFERENCE_GAP and BLOCKED_CONTRACT constants; added `PRACTICE_HIDDEN_TASK_CODES` (Personal Introduction); renderer set widened to the 22 visible exam renderers; Personal Introduction dropped from the recording set; added `PRACTICE_PROMPT_MEDIA_TTL_SECONDS` (2x the 3600 s session timer).
- `PracticeCatalogService`: hard-coded Write Email entry removed; hidden codes skipped in both the persisted and fallback loops. Answer validation already covered all renderers (Phase 2).
- `PracticeTaskContentResponse` gained `audioUrl` / `imageUrl`. `PracticeSessionResponseMapper` presigns only the pinned prompt audio and image refs through `MediaService.presignGetAll` with the session tenant; a media failure logs a warning and leaves the URL null instead of failing the session read. Reference answer, correct answer and answer-key options are never read by the mapper.
- `V131` (still unapplied) now first discards unfinished sessions holding WRITE_EMAIL items (plain UPDATEs, H2 compatible).
- Not done by design: seed script and question rotation (out of scope; the repository still serves one published question per task type). Presigned links are resolved on every session read, so a reload refreshes an expired link.
- Risk to check in Phase 6: the media lookup accepts tenant == session tenant or tenant null; vendor-authored PRACTICE media owned by another tenant would fail to presign (URL stays null).

### Test Results After Fix
- New: `PracticeSessionResponseMapperTest` (4: presign + TTL, no answer-key leakage, no media = no facade call, presign failure tolerated); `PracticeCatalogServiceTest` +3 (22 runnable with content, none runnable without, Personal Introduction / Write Email blocked).
- Practice + scoring subset and `ModuleStructureTest`: green after the fix. Full backend suite: 2730 tests, 0 failures, 0 errors, 77 skipped (V131 loads on H2 with the new cleanup statements).
