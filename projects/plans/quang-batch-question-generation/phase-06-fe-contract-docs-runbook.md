# Phase 6: FE contract, docs, rollout/rollback runbook

## Goal
Freeze the v1 contract (verified against controller tests), update generation docs, and write the rollout/rollback runbook (M7).

## Files
Create
- `pte-doc/projects/plans/quang-batch-question-generation/reports/fe-api-contract.md` (section below, verified)
- `pte-doc/projects/runbooks/batch-question-generation-rollout.md`
Change
- `pte-doc/plans/reports/261111-ai-question-generation-flow-report.md` — batch flow (submit → chain → close, preview priority, queue-at-claim)

## FE API contract (v1)
Base `/api/v1/question-generation`; roles `PLATFORM_ADMIN, ACADEMIC_MANAGER, ACADEMIC_STAFF, PLATFORM_AUTHOR`.

> Superseded in part by [flexible AI generation](../quang-flexible-ai-generation/fe-contract-and-runbook.md): quota gains `remaining`/`unlimited`/`scope`/`maxItemsPerBatch`, new `GET /presets`, and the batch list / create pages are removed (the editor popup is the only entry point; batch detail page kept).
Envelope `{ success, data, message, code?, userMessage? }` — switch on `code`, show `userMessage`.

**POST /batches** → 202
```json
{ "pool": "PRACTICE",
  "rows": [ { "taskType": "READ_ALOUD", "cefrLevel": "B2", "count": 25, "topicHints": ["climate", "urban life"], "imageKind": null },
            { "taskType": "DESCRIBE_IMAGE", "cefrLevel": "B1", "count": 5, "topicHints": [], "imageKind": "CHART" } ] }
```
Response `GenerationBatchResponse`:
```json
{ "publicId": "uuid", "pool": "PRACTICE", "status": "QUEUED", "totalRequested": 30,
  "succeededCount": 0, "failedCount": 0, "cancelledCount": 0, "openCount": 30, "cancelRequested": false,
  "failureCode": null, "currentJobPublicId": "uuid", "createdAt": "…", "startedAt": null, "finishedAt": null,
  "rows": [ { "taskType": "READ_ALOUD", "cefrLevel": "B2", "count": 25, "topicHints": ["climate","urban life"], "imageKind": "AUTO" } ],
  "children": [ { "jobPublicId": "uuid", "batchSeq": 0, "rowIndex": 0, "taskType": "READ_ALOUD", "topicHint": "climate",
                  "requestedCount": 9, "status": "QUEUED", "succeededCount": 0, "failedCount": 0, "failureCode": null,
                  "startedAt": null, "finishedAt": null } ] }
```
- **GET /batches/{id}** same shape. **GET /batches?page=0&size=20&mine=true** → `PagedResult`, no `children`; staff always see only their own.
- **POST /batches/{id}/cancel** → 200; status `CANCELLING` while the running child stops, then `CANCELLED`; repeat calls are no-ops.
- **POST /batches/{id}/drafts/delete** `{ "questionPublicIds": [] }` (≤ 200; empty = the batch's DRAFT questions) →
  `{ "processed": 3, "deleted": 2, "remaining": 0, "items": [ { "questionPublicId": "uuid", "result": "skipped_not_draft", "code": "QUESTION_DELETE_NOT_ALLOWED" } ] }`;
  results `deleted | skipped_not_draft | forbidden | not_found | not_in_batch`; loop while `remaining > 0`.
- Jobs: `GET /jobs` hides batch children unless `includeBatchChildren=true`; job `status` may be **`PENDING`** (waiting its turn);
  job responses add `batchPublicId`, `batchSeq`; cancelling a child via `/jobs/{id}/status` → 409 `GENERATION_JOB_PART_OF_BATCH`;
  `POST /jobs` never returns `GENERATION_TOO_MANY_JOBS` any more (busy system → job stays `QUEUED`); preview jobs (form) run before batch children and are allowed while a batch is open.
- Statuses — batch `QUEUED → RUNNING → (CANCELLING) → COMPLETED | PARTIALLY_COMPLETED | FAILED | CANCELLED`; job `PENDING → QUEUED → RUNNING → (CANCELLING) → COMPLETED | FAILED | CANCELLED`; item stages unchanged.

| Code | HTTP | When |
|---|---|---|
| `GENERATION_BATCH_SIZE_OUT_OF_RANGE`, `GENERATION_BATCH_ROWS_OUT_OF_RANGE`, `GENERATION_BATCH_TOPIC_HINTS_OUT_OF_RANGE` | 400 | size/rows/hints |
| `GENERATION_TASK_TYPE_UNSUPPORTED`, `GENERATION_CEFR_INVALID`, `GENERATION_POOL_INVALID`, `GENERATION_IMAGE_KIND_INVALID`, `GENERATION_COUNT_OUT_OF_RANGE` | 400 | row field |
| `GENERATION_PICTURE_DISABLED` | 400 | PICTURE row while image provider disabled |
| `GENERATION_DAILY_LIMIT_REACHED`, `GENERATION_GLOBAL_LIMIT_REACHED` | 429 | whole batch counted at submit; never-started cancelled children refunded |
| `GENERATION_JOB_ALREADY_RUNNING` | 409 | open saving job or batch exists |
| `GENERATION_BATCH_NOT_CANCELLABLE`, `GENERATION_JOB_PART_OF_BATCH` | 409 | state |
| `GENERATION_BATCH_NOT_FOUND` | 404 | unknown / not yours |
| `GENERATION_DISABLED`, `GENERATION_BATCH_DISABLED` | 503 | feature flags |
Batch/child `failureCode`: e.g. `GENERATION_PROVIDER_AUTH`, `GENERATION_PROVIDER_UNAVAILABLE`, `GENERATION_REQUESTER_NOT_ALLOWED`.

**Polling/live:** poll `GET /batches/{id}` every 5 s while open (15 s when tab hidden, stop at terminal); re-fetch `/quota` after cancel; for live detail open SSE `GET /jobs/{currentJobPublicId}/live`, and on stream end re-read the batch and reconnect to the new `currentJobPublicId`. No ETA in v1.

## Runbook (M7)
1. Pre-deploy: run the `pg_constraint` query (phase 1 step 1); confirm one status CHECK.
2. Deploy migration V53 (Flyway on startup of the first new instance is acceptable — old instances keep working: no PENDING rows exist while `QUESTION_GEN_BATCH_ENABLED=false`).
3. Roll out the app to all instances with `QUESTION_GEN_BATCH_ENABLED=false`, `QUESTION_GEN_PICTURE_ENABLED=false`.
4. Enable `QUESTION_GEN_BATCH_ENABLED=true` once every instance runs the new version.
5. Rollback: set `QUESTION_GEN_BATCH_ENABLED=false`; then
   ```sql
   UPDATE question_generation_job_items SET stage='CANCELLED', updated_at=now()
     WHERE job_id IN (SELECT id FROM question_generation_jobs WHERE status='PENDING');
   UPDATE question_generation_jobs SET status='CANCELLED', finished_at=now() WHERE status='PENDING';
   UPDATE question_generation_batches SET status='CANCELLED', cancel_requested=true, finished_at=now()
     WHERE status IN ('QUEUED','RUNNING','CANCELLING')
       AND NOT EXISTS (SELECT 1 FROM question_generation_jobs j WHERE j.batch_id = question_generation_batches.id
                       AND j.status IN ('QUEUED','RUNNING','CANCELLING'));
   ```
   then redeploy the old app (schema stays; V53 is backward compatible for old code once no PENDING rows remain).

## Design Constraints
- Contract additive for `/jobs` except default hiding of children and PENDING status (both documented).
- No secrets/provider URLs in docs.
- Coding standards (`pte-api/docs/CODING_STANDARDS_API.md`, see plan.md "Coding standards"): files ≤ 300 lines, services ≤ 5 public methods, `internal/**` packages ≤ 15 direct classes, injected `Clock` as last ctor arg (entities receive `Instant now`), `@Transactional` only on services (`readOnly = true` for queries), codes/messages/numbers in `*Constants`, `ApiResponse<T>`, domain exceptions + global `@ControllerAdvice` (no controller try-catch), `@Valid` + Bean Validation on DTOs, no `@Data` on entities, DTOs never expose entities, comments explain WHY; `app/src/test/java/com/pte/architecture` tests green, allowlists only shrink.
- Preflight: contract checked against the implemented controllers/DTOs/constants (field names asserted by `QuestionGenerationBatchControllerTest` jsonPath), `GlobalExceptionHandler` (`VALIDATION_ERROR` for Bean Validation), `ItembankConstants` (`QUESTION_NOT_FOUND`, `QUESTION_DELETE_NOT_ALLOWED`), `SharedConstants.ACCESS_DENIED`; flow report is Vietnamese → batch section appended in Vietnamese. `docker-compose.services.yml` did not pass `QUESTION_GEN_BATCH_ENABLED`/`PICTURE_ENABLED`/`MAX_ITEMS_PER_BATCH` to the app → added (defaults false/false/50), needed for the runbook and the local smoke.

## Quality and Testing State
- quality: skipped_by_user (decision: user_confirmed_skip)
- testing: passed — contract field names asserted by QuestionGenerationBatchControllerTest (jsonPath); full app suite 5517 run / 1 failed / 82 skipped, the failure was ApiInventoryExportTest (route inventory missing the 5 new batch routes) → test updated, rerun 1/1 green. Local boot: app rebuilt, health 200, Flyway applied V53. Live smoke (QUESTION_GEN_BATCH_ENABLED=true via git-ignored .env.local, real AI gateway): batch c1ed9c83-4f8e-46b6-9264-2c6cbf40ea8c (MC_READING_SINGLE B2 x2 + WRITE_ESSAY B2 x1) → 2 children run sequentially (child0 finished 16:51:02, child1 started 16:51:04) → COMPLETED 3/3; second batch → 409; PICTURE → 400 GENERATION_PICTURE_DISABLED; batch 5684fc55-2a9f-478a-b6ba-d651ecba090e cancelled while child0 ran → CANCELLING (child1 CANCELLED, started_at null) → CANCELLED, re-cancel 200 no-op, quota refund of the never-started child (7→8 for 2 requested), cancel of COMPLETED batch → 409; bulk delete of batch 1: foreign id → not_in_batch, empty body → 3 deleted, remaining 0, repeat → processed 0; /jobs hides children by default, includeBatchChildren=true shows them with batchSeq. Rollback SQL dry-run on a staging copy not done (no staging access).

## Tests
- Controller tests (phase 5) assert the JSON field names used here (`jsonPath`); rollback SQL dry-run on a staging copy.

## Acceptance criteria
- FE can build batch form, progress tray and bulk delete without reading backend code; runbook reviewed by ops.

## Risks
- Contract drift — this phase runs last and is verified against tests.
