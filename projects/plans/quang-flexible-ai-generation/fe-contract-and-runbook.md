# Flexible AI generation — FE contract delta and unlimited runbook

Extends the batch plan's contract ([phase 6](../quang-batch-question-generation/phase-06-fe-contract-docs-runbook.md)).
All responses use the `ApiResponse<T>` envelope (`data` shown below). All fields are additive; older clients ignore them.

## 1. `GET /api/v1/question-generation/quota` (changed)

Roles: `PLATFORM_ADMIN`, `ACADEMIC_MANAGER`, `ACADEMIC_STAFF`, `PLATFORM_AUTHOR`.

```json
{ "usedToday": 12, "dailyLimit": 100, "remaining": 88, "unlimited": false, "scope": "USER", "maxItemsPerBatch": 50 }
```
Unlimited deployment (both daily limits 0):
```json
{ "usedToday": 70, "dailyLimit": 0, "remaining": null, "unlimited": true, "scope": null, "maxItemsPerBatch": 500 }
```

| Field | Type | Meaning |
|---|---|---|
| `usedToday` | long | Questions the caller requested today (UTC day) |
| `dailyLimit` | int | Caller's own limit; **0 = unlimited** |
| `remaining` | int \| null | Left under the **binding** (tighter non-zero) limit; null when unlimited. FE must use this, never `dailyLimit - usedToday` (the global limit may bind) |
| `unlimited` | boolean | True when both the per-user and the global daily limit are 0 |
| `scope` | `"USER"` \| `"GLOBAL"` \| null | Which limit binds; null when unlimited |
| `maxItemsPerBatch` | int | Batch cap in force; a batch limit of 0 reports the hard cap 500 |

Error codes unchanged (`GENERATION_DAILY_LIMIT_REACHED`, `GENERATION_GLOBAL_LIMIT_REACHED`, `GENERATION_BATCH_SIZE_OUT_OF_RANGE`).

## 2. `GET /api/v1/question-generation/presets` (new)

Owned by the **assessment** module (the template lives there; itembank → assessment would be a module cycle), URL kept
under `/question-generation` for the author UI. Same four roles as generation; learners/tenant roles 403; anonymous 401.

```json
[ { "taskType": "READ_ALOUD", "section": "SPEAKING", "maxCount": 7 },
  { "taskType": "WRITE_ESSAY", "section": "WRITING", "maxCount": 2 } ]
```
One row per task type of the ACTIVE platform exam template, in template order; a type listed twice keeps the larger
`maxCount`; rows with `maxCount < 1` are omitted. No active template → `[]`. FE: `staleTime` 5 min, `retry: false`,
403/404 treated as "no presets"; types not in `/task-types` are skipped.

## 3. Chat quota (changed) — `GET /api/v1/student/chat/quota`, reply of `POST /api/v1/student/chat/messages`

```json
{ "used": 3, "remaining": 17, "limit": 20, "resetAt": "2026-10-29T17:00:00Z", "unlimited": false }
{ "used": 50, "remaining": null, "limit": null, "resetAt": null, "unlimited": true }
```
Reply: `{ markdown, onTopic, remaining, limit, resetAt, unlimited }` with the same nullability. The 429
`CHAT_QUOTA_EXCEEDED` payload (`resetAt`, `limit`, `remaining: 0`) only exists while a limit applies. Fixture:
`pte-api/app/src/test/resources/chat/api-contract-v1.json` (`unlimitedQuota`). pte-practice hides the notice, the
toggle badge and the client-side block when `unlimited`; a missing `unlimited` is read as `false`.

## 4. `GET /api/v1/ai/status` → `limits` (changed)

Adds `userDailyUnlimited`, `globalDailyUnlimited`, `batchUnlimited` (booleans) and `effectiveMaxItemsPerBatch` (int).
Platform settings `question_generation_max_items_per_{batch,user_per_day,day}` now accept a minimum of 0.

## 5. UI routes (vendor-web)

- The popup (`GenerationDialog`, `Modal size="full"`) in the question editor is the **only** entry point. Exactly 1 type
  × 1 item of the editor's task type (or with no type chosen yet) → `POST /question-generation/jobs` with
  `saveQuestions=false` (fills the form, unchanged); anything else → `POST /question-generation/batches` (one row per
  ticked type; rows may exceed 10, the server splits) → `/admin/questions/ai-batches/{id}`.
- Removed: batch list `/admin/questions/ai-batches`, `/ai-batches/new`, sidebar entry "Sinh đề bằng AI".
  Kept: `/admin/questions/ai-batches/[batch-id]` (its "back" link goes to `/admin/questions`).
- `GENERATION_JOB_ALREADY_RUNNING` → notice linking the caller's open batch (looked up via
  `GET /question-generation/batches?mine=true`), else the question bank. `GENERATION_BATCH_DISABLED` → notice; only
  the single flow can submit.

## 6. Runbook — switch a deployment to unlimited and back

Env names verified in `application.yml` (chat `:78`, batch flag `:300`, limits `:332–335`). The global env name is
`QUESTION_GEN_MAX_ITEMS_PER_DAY_GLOBAL`.

Enable — `.env`, then restart the API (chat limit is read only at startup):
```
QUESTION_GEN_MAX_ITEMS_PER_USER_PER_DAY=0
QUESTION_GEN_MAX_ITEMS_PER_DAY_GLOBAL=0
QUESTION_GEN_MAX_ITEMS_PER_BATCH=0
CHAT_AI_DAILY_LIMIT=0
QUESTION_GEN_BATCH_ENABLED=true
```
Platform settings override env. Check first, then update (or set 0 on the AI overview page):
```sql
SELECT setting_key, value FROM platform_settings WHERE setting_key LIKE 'question_generation_%';
UPDATE platform_settings SET value = '0', updated_at = now()
WHERE deleted = false AND setting_key IN ('question_generation_max_items_per_user_per_day',
  'question_generation_max_items_per_day', 'question_generation_max_items_per_batch');
```
Settings are cached per instance (`PlatformSettingService`); restart the API (or save through the settings page) so
the new values are read.

Rollback:
```sql
UPDATE platform_settings SET value = CASE setting_key
    WHEN 'question_generation_max_items_per_user_per_day' THEN '100'
    WHEN 'question_generation_max_items_per_day' THEN '300'
    WHEN 'question_generation_max_items_per_batch' THEN '50' END,
  updated_at = now()
WHERE deleted = false AND setting_key IN ('question_generation_max_items_per_user_per_day',
  'question_generation_max_items_per_day', 'question_generation_max_items_per_batch');
```
Remove the four limit lines from `.env` (defaults 100/300/50, chat 20 apply), keep or remove
`QUESTION_GEN_BATCH_ENABLED`, restart. A stored negative or unparsable value never means unlimited: it falls back to
the deployment value (warning logged).

Backstops that stay active when unlimited: calls per item (`question_generation_max_calls_per_item`, seeded 40),
`QUESTION_GEN_MAX_CONCURRENT_JOBS` (3), 500-item hard cap per batch, one open saving batch per user, author roles only.
