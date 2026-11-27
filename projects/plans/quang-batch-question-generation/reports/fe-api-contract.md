# FE API contract — batch AI question generation (v1)

Verified against `QuestionGenerationBatchController` / `QuestionGenerationController` and their MockMvc tests
(`QuestionGenerationBatchControllerTest`, `QuestionGenerationControllerTest`), plus the live smoke run on local
(see `../phase-06-fe-contract-docs-runbook.md`).

- Base path: `/api/v1/question-generation`
- Roles (all routes): `PLATFORM_ADMIN`, `ACADEMIC_MANAGER`, `ACADEMIC_STAFF`, `PLATFORM_AUTHOR`
- Envelope: `{ "success": bool, "data": T | null, "message": string, "code"?: string, "userMessage"?: string }` —
  switch on `code`, show `userMessage`.
- Feature flag: batch routes that create work answer `503 GENERATION_BATCH_DISABLED` while
  `QUESTION_GEN_BATCH_ENABLED=false` (the default). Read routes work regardless.
- Visibility: `ACADEMIC_STAFF` only ever see their own batches; another writer's batch answers `404 GENERATION_BATCH_NOT_FOUND`.
  `PLATFORM_ADMIN` and `ACADEMIC_MANAGER` see every writer's batch.

## Endpoints

| Method | Path | Body | Success |
|---|---|---|---|
| POST | `/batches` | `SubmitGenerationBatchRequest` | `202` `GenerationBatchResponse` |
| GET | `/batches/{publicId}` | – | `200` `GenerationBatchResponse` (with `children`) |
| GET | `/batches?page=0&size=20&mine=false` | – | `200` `PagedResult<GenerationBatchResponse>` (`children: []`) |
| POST | `/batches/{publicId}/cancel` | – | `200` `GenerationBatchResponse` (idempotent) |
| POST | `/batches/{publicId}/drafts/delete` | `BatchDraftDeleteRequest` (optional) | `200` `BatchDraftDeleteResponse` |

`size` is clamped to 1..50. `mine=true` narrows a reviewer's list to their own batches; staff always get only their own.

### POST /batches

```json
{
  "pool": "PRACTICE",
  "rows": [
    { "taskType": "MC_READING_SINGLE", "cefrLevel": "B2", "count": 25, "topicHints": ["climate", "urban life"], "imageKind": null },
    { "taskType": "DESCRIBE_IMAGE", "cefrLevel": "B1", "count": 5, "topicHints": [], "imageKind": "CHART" }
  ]
}
```

Rules:
- `pool`: `PRACTICE` | `EXAM` (case-insensitive).
- `rows`: 1..20 rows. `taskType` must be one of `GET /task-types`. `cefrLevel` as in the single-job form.
- `count` per row ≥ 1; the sum of all rows ≤ the per-batch limit (platform setting
  `question_generation_max_items_per_batch`, default 50, hard max 500).
- `topicHints`: up to 10 per row, each ≤ 500 chars, letters/digits/spaces and `,.;:'?!&()/-` only; blanks and
  duplicates are dropped. Questions of a row are spread evenly over its topics (25 over 3 topics → 9/8/8).
- `imageKind` (Describe Image): `AUTO` (default / null) | `CHART` | `PICTURE`. `PICTURE` is refused while AI pictures
  are off; `AUTO` then becomes a chart.
- The backend splits rows into child jobs of at most 10 questions; children run one after another. The whole batch is
  counted against the daily quota at submit.

### GenerationBatchResponse

```json
{
  "publicId": "uuid",
  "pool": "PRACTICE",
  "status": "QUEUED",
  "totalRequested": 30,
  "succeededCount": 0,
  "failedCount": 0,
  "cancelledCount": 0,
  "openCount": 30,
  "cancelRequested": false,
  "failureCode": null,
  "currentJobPublicId": "uuid",
  "createdAt": "2026-11-17T10:00:00Z",
  "startedAt": null,
  "finishedAt": null,
  "rows": [
    { "taskType": "MC_READING_SINGLE", "cefrLevel": "B2", "count": 25, "topicHints": ["climate", "urban life"], "imageKind": "AUTO" }
  ],
  "children": [
    { "jobPublicId": "uuid", "batchSeq": 0, "rowIndex": 0, "taskType": "MC_READING_SINGLE", "topicHint": "climate",
      "requestedCount": 9, "status": "QUEUED", "succeededCount": 0, "failedCount": 0, "failureCode": null,
      "startedAt": null, "finishedAt": null }
  ]
}
```

- Detail (`GET /batches/{id}`, submit, cancel): counters are live, from the items of every child
  (`succeeded` = saved questions, `openCount = totalRequested − succeeded − failed − cancelled`).
- List: counters are the stored ones (refreshed whenever a child finishes); `currentJobPublicId` is `null`, `children` `[]`.
- `currentJobPublicId`: the child a worker is running, else the child waiting to be claimed, else `null`.
- `failureCode` (batch or child): a code that stopped the batch, e.g. `GENERATION_PROVIDER_AUTH`,
  `GENERATION_PROVIDER_UNAVAILABLE`, `GENERATION_REQUESTER_NOT_ALLOWED`.
- Child counters (`succeededCount`, `failedCount`) are refreshed when the child finishes; follow the live job for
  per-item progress.

### POST /batches/{id}/cancel

- `QUEUED`/`RUNNING` → waiting children are cancelled at once; a running child is asked to stop → batch `CANCELLING`,
  then `CANCELLED` when that child stops. A batch with nothing running goes to `CANCELLED` immediately.
- `CANCELLING` / `CANCELLED` → `200` with the current state (no-op).
- `COMPLETED` / `PARTIALLY_COMPLETED` / `FAILED` → `409 GENERATION_BATCH_NOT_CANCELLABLE`.
- Questions already saved stay. Children cancelled before they started are refunded → re-fetch `GET /quota`.

### POST /batches/{id}/drafts/delete

Body (optional): `{ "questionPublicIds": ["uuid", "..."] }` — at most 200 ids. Empty or absent = the batch's questions
that are still `DRAFT` and not deleted (first 200).

```json
{
  "processed": 3,
  "deleted": 2,
  "remaining": 0,
  "items": [
    { "questionPublicId": "uuid", "result": "deleted", "code": null },
    { "questionPublicId": "uuid", "result": "skipped_not_draft", "code": "QUESTION_DELETE_NOT_ALLOWED" }
  ]
}
```

- `result`: `deleted` | `skipped_not_draft` (`QUESTION_DELETE_NOT_ALLOWED`) | `forbidden` (`ACCESS_DENIED`) |
  `not_found` (`QUESTION_NOT_FOUND`) | `not_in_batch` (id not produced by this batch; untouched).
- Soft delete, one question at a time: one refusal never undoes the others.
- `remaining` = drafts of the batch still live after the call → call again while `remaining > 0`.

## Changes to the job endpoints

- `GET /jobs?page&size&includeBatchChildren=false` — batch children are **hidden by default**; pass
  `includeBatchChildren=true` to include them.
- Job responses (`GET /jobs/{id}`, list, submit, cancel) gain `batchPublicId` (uuid | null) and `batchSeq` (int | null).
  `GET /jobs/{id}` and `GET /jobs/{id}/live` keep working for batch children.
- Job `status` may now be **`PENDING`** (a batch child waiting for its turn).
- `PATCH /jobs/{id}/status {"action":"CANCEL"}` on a batch child → `409 GENERATION_JOB_PART_OF_BATCH` (cancel the batch).
- `POST /jobs` no longer returns `GENERATION_TOO_MANY_JOBS`: a busy system leaves the job `QUEUED`.
- `POST /jobs` with `imageKind: "PICTURE"` while AI pictures are off → `400 GENERATION_PICTURE_DISABLED`.
- Preview jobs (`saveQuestions: false`, question form) are allowed while a batch is open and run before batch children.
- A saving job is refused (`409 GENERATION_JOB_ALREADY_RUNNING`) while the same writer has an open batch, and vice versa.
- `GET /quota` excludes jobs cancelled before they started.

## Statuses

- Batch: `QUEUED → RUNNING → (CANCELLING) → COMPLETED | PARTIALLY_COMPLETED | FAILED | CANCELLED`
  (`COMPLETED`: every question saved; `PARTIALLY_COMPLETED`: some; `FAILED`: none; `CANCELLED`: cancel requested).
- Job: `PENDING → QUEUED → RUNNING → (CANCELLING) → COMPLETED | FAILED | CANCELLED`. Item stages unchanged.

## Error codes

| Code | HTTP | When |
|---|---|---|
| `VALIDATION_ERROR` | 400 | body shape (`rows` missing/empty/> 20, a row without `taskType`/`cefrLevel`/`count`, > 10 `topicHints`, > 200 `questionPublicIds`) |
| `GENERATION_BATCH_SIZE_OUT_OF_RANGE` | 400 | a row `count` < 1, or the batch total above the per-batch limit |
| `GENERATION_BATCH_ROWS_OUT_OF_RANGE`, `GENERATION_BATCH_TOPIC_HINTS_OUT_OF_RANGE` | 400 | same limits, when not caught by body validation |
| `GENERATION_TASK_TYPE_UNSUPPORTED`, `GENERATION_CEFR_INVALID`, `GENERATION_POOL_INVALID`, `GENERATION_IMAGE_KIND_INVALID`, `GENERATION_TOPIC_HINT_INVALID` | 400 | a row field |
| `GENERATION_PICTURE_DISABLED` | 400 | `imageKind: PICTURE` while AI pictures are off |
| `GENERATION_DAILY_LIMIT_REACHED`, `GENERATION_GLOBAL_LIMIT_REACHED` | 429 | whole batch counted at submit |
| `GENERATION_JOB_ALREADY_RUNNING` | 409 | the writer has an open batch or an open saving job |
| `GENERATION_BATCH_NOT_CANCELLABLE` | 409 | cancel of a finished batch |
| `GENERATION_JOB_PART_OF_BATCH` | 409 | job cancel on a batch child |
| `GENERATION_BATCH_NOT_FOUND` | 404 | unknown batch, or another writer's batch (staff) |
| `GENERATION_DISABLED`, `GENERATION_BATCH_DISABLED` | 503 | feature flags off |

## Polling and live view

- Poll `GET /batches/{id}` every 5 s while the batch is open (15 s when the tab is hidden); stop at a terminal status.
- Live detail: open `GET /jobs/{currentJobPublicId}/live` (SSE). When the stream ends, re-read the batch and reconnect
  to the new `currentJobPublicId`.
- After cancel, re-fetch `GET /quota` (refund of children that never started).
- No ETA in v1.
