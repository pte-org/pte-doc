# Batch AI question generation — rollout and rollback runbook

Plan: `pte-doc/projects/plans/quang-batch-question-generation/`. FE contract:
`pte-doc/projects/plans/quang-batch-question-generation/reports/fe-api-contract.md`.

This runbook is a checklist; it does not authorize production data changes or deployments on its own.

## What changes

- Migration `V53__question_generation_batches.sql` (additive): table `question_generation_batches`, job columns
  `batch_id`, `batch_seq`, `batch_row_index`, job status `PENDING`, claim-order index `ix_qgen_jobs_queued`, platform
  setting `question_generation_max_items_per_batch` (50). It recreates two objects of `question_generation_jobs`:
  the status CHECK (found by definition, renamed `ck_qgen_jobs_status`) and `uk_qgen_jobs_one_active_per_requester`
  (now only for saving jobs, so the question-form preview may run beside a batch).
- Behaviour for existing single jobs: no more `GENERATION_TOO_MANY_JOBS` (jobs wait `QUEUED`; the cap is enforced by
  the worker), quota refund for jobs cancelled before they started, `/jobs` hides batch children.

## Flags (deployment env, passed by `docker-compose.services.yml`)

| Env | Default | Meaning |
|---|---|---|
| `QUESTION_GEN_BATCH_ENABLED` | `false` | `POST /batches` allowed. Keep `false` until every instance runs the new version. |
| `QUESTION_GEN_PICTURE_ENABLED` | `false` | AI-painted pictures. Off: `PICTURE` refused at submit, `AUTO` becomes a chart. |
| `QUESTION_GEN_MAX_ITEMS_PER_BATCH` | `50` | Fallback of the platform setting `question_generation_max_items_per_batch`. |
| `itembank.generation.batch.reconcile-delay-ms` | `300000` | Reconciler period (property, no env mapping by default). |

## Rollout

1. **Pre-deploy check** (read-only) — exactly one status CHECK must mention `CANCELLING`:
   ```sql
   select conname, pg_get_constraintdef(oid) from pg_constraint
   where conrelid = 'question_generation_jobs'::regclass and contype = 'c';
   ```
2. **Migrate**: V53 runs with Flyway on startup of the first new instance. Old instances keep working: with
   `QUESTION_GEN_BATCH_ENABLED=false` no `PENDING` row exists, and old code never reads the new columns.
3. **Roll out** the app to all instances with `QUESTION_GEN_BATCH_ENABLED=false`, `QUESTION_GEN_PICTURE_ENABLED=false`.
4. **Verify**: `GET /actuator/health` = 200 on every instance; Flyway history shows V53 `success`:
   ```sql
   select version, success from flyway_schema_history where version = '53';
   ```
5. **Enable** `QUESTION_GEN_BATCH_ENABLED=true` once every instance runs the new version; restart.
6. **Smoke**: submit a tiny batch (2 rows, ≤ 3 questions, text-only task types), poll `GET /batches/{id}` until terminal,
   check children ran one after another (`startedAt` of each child ≥ `finishedAt` of the previous one), cancel a second
   tiny batch, bulk-delete the drafts of the first.

## Monitoring

- Log `Batch chaining failed: batchId=…` (WARN) and Micrometer counter `generation.batch.hook.failures`: a child's
  terminal transaction was rolled back; the job is resumed after its lease expires.
- Log `Batch repaired, …` (WARN): the reconciler closed or re-promoted a batch — investigate the missed path.
- Open batches older than a few hours:
  ```sql
  select public_id, status, created_at from question_generation_batches
  where status in ('QUEUED','RUNNING','CANCELLING') and created_at < now() - interval '3 hours';
  ```

## Rollback

1. Set `QUESTION_GEN_BATCH_ENABLED=false` and restart (no new batches).
2. Close waiting work so old code never meets a `PENDING` row (old code has no `PENDING` enum value):
   ```sql
   BEGIN;
   UPDATE question_generation_job_items SET stage = 'CANCELLED', updated_at = now()
     WHERE job_id IN (SELECT id FROM question_generation_jobs WHERE status = 'PENDING')
       AND stage NOT IN ('READY', 'SAVED', 'FAILED', 'CANCELLED');
   UPDATE question_generation_jobs SET status = 'CANCELLED', finished_at = now() WHERE status = 'PENDING';
   UPDATE question_generation_batches SET status = 'CANCELLED', cancel_requested = true, finished_at = now(),
          updated_at = now()
     WHERE status IN ('QUEUED', 'RUNNING', 'CANCELLING')
       AND NOT EXISTS (SELECT 1 FROM question_generation_jobs j WHERE j.batch_id = question_generation_batches.id
                       AND j.status IN ('QUEUED', 'RUNNING', 'CANCELLING'));
   COMMIT;
   ```
   A batch whose child was still `QUEUED`/`RUNNING` stays open; that child finishes normally under the old code. Run
   the last `UPDATE` again once it has finished (old code has no reconciler), or leave it to the reconciler after a
   later upgrade.
3. Redeploy the old app. The schema stays: V53 is backward compatible for old code once no `PENDING` rows remain.
   Note: the old app answers `GENERATION_TOO_MANY_JOBS` again and counts refunded jobs in the quota again.
4. Do not revert V53 manually; a forward migration is the only supported schema change.
