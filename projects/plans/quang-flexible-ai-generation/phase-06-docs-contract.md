# Phase 6: Docs, FE contract, unlimited runbook

## Goal
Document changed contracts and give operators exact steps to switch a deployment to unlimited and back (U2).

## Stories covered
Operator story (FR-04/05/07); supports all.

## Files
- pte-doc FE contract for question generation (extend the batch plan's phase-6 contract): `GET /question-generation/quota` (`remaining` nullable, `unlimited`, `scope`, `maxItemsPerBatch`), `GET /question-generation/presets`, chat quota (`remaining`/`limit`/`resetAt` nullable, `unlimited`; SSE quota payload)
- pte-api runbook (ops docs folder used by the batch plan): unlimited enable / rollback below
- `pte-api/.env.example` comments for the five keys

## Runbook content
Env names verified in `pte-api/app/src/main/resources/application.yml` (:78, :300, :331–334).

Enable (VPS `.env`, then restart the API — chat limit is read only at startup, B2):
```
QUESTION_GEN_MAX_ITEMS_PER_USER_PER_DAY=0
QUESTION_GEN_MAX_ITEMS_PER_DAY_GLOBAL=0
QUESTION_GEN_MAX_ITEMS_PER_BATCH=0
CHAT_AI_DAILY_LIMIT=0
QUESTION_GEN_BATCH_ENABLED=true
```
Note: the global env name is `QUESTION_GEN_MAX_ITEMS_PER_DAY_GLOBAL` (not `…_PER_DAY`).

Platform settings override env (seeded by V45/V53; table `platform_settings`, column `value`):
```sql
UPDATE platform_settings SET value = '0', updated_at = now()
WHERE deleted = false AND setting_key IN ('question_generation_max_items_per_user_per_day',
  'question_generation_max_items_per_day', 'question_generation_max_items_per_batch');
```
(or set 0 on the AI overview settings page). Confirm keys with
`SELECT setting_key, value FROM platform_settings WHERE setting_key LIKE 'question_generation_%';` before running.

Rollback (M6):
```sql
UPDATE platform_settings SET value = CASE setting_key
    WHEN 'question_generation_max_items_per_user_per_day' THEN '100'
    WHEN 'question_generation_max_items_per_day' THEN '300'
    WHEN 'question_generation_max_items_per_batch' THEN '50' END,
  updated_at = now()
WHERE deleted = false AND setting_key IN ('question_generation_max_items_per_user_per_day',
  'question_generation_max_items_per_day', 'question_generation_max_items_per_batch');
```
Then remove the four limit lines from `.env` (code defaults 100/300/50, chat 20 apply), keep or remove
`QUESTION_GEN_BATCH_ENABLED`, restart.

Backstops that stay active when unlimited (M4): `CALLS_PER_ITEM` (setting `question_generation_max_calls_per_item`, seeded 40; env `QUESTION_GEN_MAX_CALLS_PER_ITEM` fallback 15), `QUESTION_GEN_MAX_CONCURRENT_JOBS` (3), 500-item hard cap per batch, one open saving batch per user, author roles only.

## Steps
1. `ck:docs-fe` format for endpoints; examples from real DTOs.
2. Runbook as above; verify setting keys against V45/V53 at implementation.
3. Note presets endpoint owned by the assessment module.

## Design Constraints
- Preflight: contract + runbook written to fe-contract-and-runbook.md in this plan; batch plan phase 6 links to it; SELECT dry-run on local DB `pte` done before UPDATE.
- Docs only; match existing contract structure.

## Quality and Testing State
- quality: skipped_by_user; decision: user_confirmed_skip [quality: skipped_by_user; decision: user_confirmed_skip]
- testing: n/a (docs) — runbook SELECT/UPDATE executed on local DB only; live check of quota/presets/ai status done

## Tests
- n/a; dry-run the SQL on local DB (`SELECT` first).

## Acceptance criteria
- Every changed field/endpoint documented; runbook enable + rollback reproducible on local stack.

## Risks
- Setting key names differ from assumption → `SELECT` check step.
