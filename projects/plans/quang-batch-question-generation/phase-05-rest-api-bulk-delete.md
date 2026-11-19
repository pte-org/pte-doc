# Phase 5: REST API (create/get/list/cancel) + bulk draft delete

## Goal
Expose v1 batch endpoints, bulk soft-delete of a batch's drafts with per-item results, and hide batch children from
`/jobs` by default.

## Files
Create
- `generation/controller/QuestionGenerationBatchController.java` — `@RequestMapping("/api/v1/question-generation/batches")`, `@PreAuthorize("hasAnyRole('PLATFORM_ADMIN','ACADEMIC_MANAGER','ACADEMIC_STAFF','PLATFORM_AUTHOR')")`
- `generation/batch/QuestionGenerationBatchQueryService.java`
- `generation/batch/BatchDraftDeletionService.java` + `generation/batch/BatchDraftDeleteExecutor.java` (`@Transactional(propagation = REQUIRES_NEW)` per question; separate bean for the proxy)
- `generation/batch/dto/GenerationBatchResponse.java`, `GenerationBatchChildResponse.java`, `BatchDraftDeleteRequest.java`, `BatchDraftDeleteResponse.java`
- `generation/exception/GenerationBatchNotFoundException.java` (`DomainException`, 404)

Change
- `generation/job/GenerationAccessPolicy.java` — `requireAccess(CurrentUser, QuestionGenerationBatch)`
- `generation/controller/QuestionGenerationController.java` — `GET /jobs?includeBatchChildren=false`
- `generation/job/QuestionGenerationQueryService.java` + `GenerationJobRepository` — list filters `batchId is null` unless flag
- `generation/dto/GenerationJobResponse.java` — additive `UUID batchPublicId`, `Integer batchSeq`
- `generation/repository/GenerationJobItemRepository.java` — `findSavedQuestionPublicIdsByBatch(batchId)`
- `pte-api/.../itembank/internal/repository/QuestionRepository.java` — `findDraftPublicIdsIn(Collection<UUID>)` (`status = DRAFT and deleted = false`)

## Endpoints
| Method | Path | Success |
|---|---|---|
| POST | `/batches` (`SubmitGenerationBatchRequest`) | 202 `GenerationBatchResponse` |
| GET | `/batches/{publicId}` | 200 |
| GET | `/batches?page&size&mine` | 200 `PagedResult<GenerationBatchResponse>` without `children`; staff always own (H5) |
| POST | `/batches/{publicId}/cancel` | 200 (idempotent) |
| POST | `/batches/{publicId}/drafts/delete` | 200 `BatchDraftDeleteResponse` |

## Steps
1. `GenerationBatchResponse(publicId, pool, status, totalRequested, succeededCount, failedCount, cancelledCount, openCount, cancelRequested, failureCode, currentJobPublicId, createdAt, startedAt, finishedAt, rows, children)`; child = `jobPublicId, batchSeq, rowIndex, taskType, topicHint, requestedCount, status, succeededCount, failedCount, failureCode, startedAt, finishedAt`. `currentJobPublicId` = LEASED child, else QUEUED child, else null. Batch + children + one grouped count query (no N+1).
2. Access (H5): every read/action loads the batch then `GenerationAccessPolicy.requireAccess` (404 when hidden). List: `seesAllJobs(caller) && !mine` → all; otherwise own only.
3. Bulk delete (H2): body `{ "questionPublicIds": [...] }` ≤ 200.
   - ids given → must be in `findSavedQuestionPublicIdsByBatch`; others → `not_in_batch` (untouched).
   - empty/absent → batch's saved questions filtered by `findDraftPublicIdsIn` (DRAFT, not deleted), first 200.
   - per id: `QuestionDeletionService.deleteDraft(id, caller)` in REQUIRES_NEW; map success → `deleted`, `QuestionDeletionException` (`QUESTION_DELETE_NOT_ALLOWED`) → `skipped_not_draft`, `AccessDeniedException` → `forbidden`, `QuestionNotFoundException` → `not_found`.
   - response `{processed, deleted, remaining, items[]}` where `remaining` = DRAFT & not deleted questions of the batch after the call (FE loops while > 0).
   - batch-level audit `BATCH_DRAFTS_DELETED`; per-question audit + media cleanup reused from `QuestionDeletionService`.
4. M9: `/jobs` list hides children by default; `PATCH /jobs/{id}/status CANCEL` on a child → 409 `GENERATION_JOB_PART_OF_BATCH`; `GET /jobs/{id}` still works for children (FE detail/live).

## Design Constraints
- Thin controller; `ApiResponse` / `PagedResult` envelopes as in `QuestionGenerationController`.
- Soft delete only; outer bulk call not transactional; one failure never undoes others.
- `/jobs` changes additive except default hiding of children (documented).
- Coding standards (`pte-api/docs/CODING_STANDARDS_API.md`, see plan.md "Coding standards"): files ≤ 300 lines, services ≤ 5 public methods, `internal/**` packages ≤ 15 direct classes, injected `Clock` as last ctor arg (entities receive `Instant now`), `@Transactional` only on services (`readOnly = true` for queries), codes/messages/numbers in `*Constants`, `ApiResponse<T>`, domain exceptions + global `@ControllerAdvice` (no controller try-catch), `@Valid` + Bean Validation on DTOs, no `@Data` on entities, DTOs never expose entities, comments explain WHY; `app/src/test/java/com/pte/architecture` tests green, allowlists only shrink.
- Controller only delegates, returns `ApiResponse<T>`/`PagedResult`; `GenerationBatchNotFoundException extends DomainException` (404) handled by the global advice. Per-item exception mapping in bulk delete lives in `BatchDraftDeletionService` (service layer, intended per-item result), never in the controller. Query service methods `@Transactional(readOnly = true)`. Result strings and `MAX_BULK_ITEMS = 200` in `BatchGenerationConstants`. `generation/batch` ends with 9 classes, `generation/batch/dto` 5 (≥ 3, ≤ 15).
- Preflight: `QuestionGenerationBatchQueryService`, `GenerationBatchNotFoundException`, `GenerationBatchResponse`/`GenerationBatchChildResponse` and `GenerationAccessPolicy.requireAccess(caller, batch)` already exist from phase 4 (cancel needed them). `QuestionDeletionService.deleteDraft` is `@Transactional` (REQUIRED) and throws `AccessDeniedException` / `QuestionNotFoundException` / `QuestionDeletionException` (`QUESTION_DELETE_NOT_ALLOWED`, 409) and returns silently for an already-deleted draft; it joins the executor's REQUIRES_NEW tx. `QuestionRepository` 254 lines (+1 query OK). `QuestionGenerationController` 100 lines; `controller` package 3→4. `QuestionGenerationControllerTest` (MockMvc standalone pattern) is the template for the new controller test.

## Quality and Testing State
- quality: skipped_by_user (decision: user_confirmed_skip)
- testing: passed — 810 run / 0 failed / 33 skipped (generation + itembank Question* incl. QuestionDeletionServiceTest + billing + architecture + ModuleStructureTest). New: QuestionGenerationBatchControllerTest 7 (MockMvc: 202 create with contract jsonPath names, 400 empty rows, 400 >200 ids, 503 GENERATION_BATCH_DISABLED, 403 non-author, 404 hidden get/cancel, list/cancel/bulk-delete envelopes, class-level @PreAuthorize only), QuestionGenerationBatchQueryServiceTest 3 (current child LEASED>QUEUED>null + live counters, H5 staff B → 404 / manager OK, staff list forced own with mine=false), BatchDraftDeletionServiceTest 4 (mixed outcomes deleted/skipped_not_draft/not_in_batch/not_found/forbidden, ids outside batch untouched, empty list → live DRAFTs only, remaining, H5 404 nothing deleted), QuestionGenerationQueryServiceTest 3 (children hidden by default for admin and staff, includeBatchChildren shows batchPublicId/batchSeq, GET child keeps batch). QuestionGenerationControllerTest updated (record + includeBatchChildren).
- integration: Postgres ITs run 2026-11-18 on a throwaway postgres:17 container (DB pte_lifecycle_test; host :5432 is a native Postgres, not pte-postgres, so a separate container on 127.0.0.1:55440 was used, then removed): 22 run / 0 failed / 0 skipped, stable over 3 runs (opt-in: -Dlifecycle.test.db.url/.user/.password, -DargLine=-Duser.timezone=UTC); without the property all 20 skip, subset 535 run / 0 failed / 29 skipped. No production bug found. Submit → sequential run → COMPLETED covered at the service level by BatchSubmitRunPostgresIntegrationTest; HTTP endpoints remain covered by MockMvc only.

## Tests
- `controller/QuestionGenerationBatchControllerTest` (MockMvc): 202 create, 403 non-author role, 400 validation, 404 hidden, > 200 ids → 400.
- Unit `QuestionGenerationBatchQueryServiceTest`: current child selection; staff list forced own even with `mine=false`.
- Unit `BatchDraftDeletionServiceTest`: mixed outcomes; ids outside batch untouched; empty list selects only DRAFT not-deleted; `remaining` correct.
- H5 test: staff A cannot get / cancel / bulk-delete staff B's batch (404).
- Unit `QuestionGenerationQueryServiceTest`: children hidden unless `includeBatchChildren=true`.

## Acceptance criteria
- Five endpoints work end to end with the stub generator; bulk delete never touches non-drafts or other batches.

## Risks
- 200 synchronous deletions with after-commit media cleanup — cap kept at 200.
