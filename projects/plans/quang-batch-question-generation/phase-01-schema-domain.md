# Phase 1: Schema + domain

## Goal
Additive V53, batch entity (rows as JSONB), `JobStatus.PENDING` + explicit sets, preview exemption in the active-job
index, feature flags. No behaviour change for existing jobs.

## Files
Create
- `pte-api/app/src/main/resources/db/migration/V53__question_generation_batches.sql`
- `generation/domain/BatchStatus.java`, `generation/domain/QuestionGenerationBatch.java`, `generation/domain/BatchRow.java` (record, JSON element)
- `generation/repository/GenerationBatchRepository.java`

Change
- `generation/domain/JobStatus.java`, `generation/domain/QuestionGenerationJob.java` (`batchId`, `batchSeq`, `batchRowIndex`, nullable, `updatable = false`)
- `com/pte/billing/QuestionGenerationLimit.java` — `ITEMS_PER_BATCH("question_generation_max_items_per_batch", 50, 1, 500, "questions", "Questions one generation batch may ask for")`
- `generation/config/QuestionGenerationProperties.java` — `Limits.maxItemsPerBatch = 50`, `batchEnabled = false` (`QUESTION_GEN_BATCH_ENABLED`), `pictureEnabled = false` (`QUESTION_GEN_PICTURE_ENABLED`); `application.yml` keys; `QuestionGenerationPropertiesValidator` bounds
- `generation/config/GenerationLimits.java` — `maxItemsPerBatch()`

## Steps
1. Pre-deploy check (runbook, phase 6): `select conname, pg_get_constraintdef(oid) from pg_constraint where conrelid='question_generation_jobs'::regclass and contype='c';`
2. V53:
   ```sql
   CREATE TABLE question_generation_batches (
     id BIGSERIAL PRIMARY KEY, public_id UUID NOT NULL UNIQUE,
     created_at TIMESTAMPTZ NOT NULL, updated_at TIMESTAMPTZ NOT NULL, deleted BOOLEAN NOT NULL DEFAULT FALSE,
     requested_by_user_public_id UUID NOT NULL, pool VARCHAR(16) NOT NULL,
     rows JSONB NOT NULL,                                   -- [{taskType,cefrLevel,count,topicHints[],imageKind}]
     total_requested INT NOT NULL CHECK (total_requested BETWEEN 1 AND 500),
     status VARCHAR(24) NOT NULL CHECK (status IN ('QUEUED','RUNNING','CANCELLING','COMPLETED',
            'PARTIALLY_COMPLETED','FAILED','CANCELLED')),
     succeeded_count INT NOT NULL DEFAULT 0, failed_count INT NOT NULL DEFAULT 0, cancelled_count INT NOT NULL DEFAULT 0,
     cancel_requested BOOLEAN NOT NULL DEFAULT FALSE, failure_code VARCHAR(64),
     started_at TIMESTAMPTZ, finished_at TIMESTAMPTZ);
   CREATE UNIQUE INDEX uk_qgen_batches_one_open_per_requester ON question_generation_batches (requested_by_user_public_id)
     WHERE status IN ('QUEUED','RUNNING','CANCELLING');
   CREATE INDEX ix_qgen_batches_requester_created ON question_generation_batches (requested_by_user_public_id, created_at DESC);
   CREATE INDEX ix_qgen_batches_open ON question_generation_batches (status) WHERE status IN ('QUEUED','RUNNING','CANCELLING');

   ALTER TABLE question_generation_jobs
     ADD COLUMN batch_id BIGINT REFERENCES question_generation_batches (id),
     ADD COLUMN batch_seq INT, ADD COLUMN batch_row_index INT,
     ADD CONSTRAINT ck_qgen_jobs_batch_fields CHECK ((batch_id IS NULL) = (batch_seq IS NULL)
                                                 AND (batch_id IS NULL) = (batch_row_index IS NULL));
   CREATE UNIQUE INDEX uk_qgen_jobs_batch_seq ON question_generation_jobs (batch_id, batch_seq) WHERE batch_id IS NOT NULL;
   CREATE INDEX ix_qgen_jobs_batch ON question_generation_jobs (batch_id) WHERE batch_id IS NOT NULL;

   -- M8: drop the inline status CHECK by definition, not by name
   DO $$ DECLARE c text; BEGIN
     FOR c IN SELECT conname FROM pg_constraint
              WHERE conrelid = 'question_generation_jobs'::regclass AND contype = 'c'
                AND pg_get_constraintdef(oid) LIKE '%status%' AND pg_get_constraintdef(oid) LIKE '%CANCELLING%'
     LOOP EXECUTE format('ALTER TABLE question_generation_jobs DROP CONSTRAINT %I', c); END LOOP; END $$;
   ALTER TABLE question_generation_jobs ADD CONSTRAINT ck_qgen_jobs_status
     CHECK (status IN ('PENDING','QUEUED','RUNNING','CANCELLING','COMPLETED','FAILED','CANCELLED'));

   -- U1: preview jobs (save_questions = false, V40) are exempt from the one-active rule
   DROP INDEX uk_qgen_jobs_one_active_per_requester;            -- V34; V40 did not touch it (verified)
   CREATE UNIQUE INDEX uk_qgen_jobs_one_active_per_requester ON question_generation_jobs (requested_by_user_public_id)
     WHERE status IN ('QUEUED','RUNNING','CANCELLING') AND save_questions;

   -- ITEMS_PER_BATCH platform setting: INSERT ... WHERE NOT EXISTS, same shape as V45
   ```
   PENDING stays outside the index; only one child per batch is QUEUED/RUNNING/CANCELLING at a time (phase 4).
3. `JobStatus`:
   ```java
   PENDING, QUEUED, RUNNING, CANCELLING, COMPLETED, FAILED, CANCELLED;
   public static final Set<JobStatus> ACTIVE  = EnumSet.of(QUEUED, RUNNING, CANCELLING); // mirrors the unique index
   public static final Set<JobStatus> OPEN    = EnumSet.of(PENDING, QUEUED, RUNNING, CANCELLING);
   public static final Set<JobStatus> LEASED  = EnumSet.of(RUNNING, CANCELLING);          // cap counts these (live lease)
   public static final Set<JobStatus> TERMINAL = EnumSet.of(COMPLETED, FAILED, CANCELLED);
   ```
   `BatchStatus.OPEN = {QUEUED, RUNNING, CANCELLING}`.
4. Usage audit (record result in PR):
   | Usage | After |
   |---|---|
   | `QuestionGenerationJobService.checkCaps` `existsByRequestedByUserPublicIdAndStatusIn(..., ACTIVE)` | saving jobs only: `existsBy...AndSaveQuestionsTrueAndStatusIn(user, OPEN)` + open batch (phase 3); preview submits skip it |
   | `checkCaps` `countByStatusIn(ACTIVE) >= maxConcurrentJobs` | removed (phase 2) |
   | `lockNextClaimable` (native `'QUEUED'`) | PENDING never claimable (phase 2 rewrites query) |
   | `markRunning` guard `QUEUED, RUNNING` | unchanged |
   | `cancelQueued` guard `QUEUED` | `PENDING, QUEUED` (phase 4) |
   | `JobLeaseService`, `GeneratedQuestionWriter.save`, `GenerationItemStateService.cancelRequested` | CANCELLING checks unchanged |
   | `AiOverviewService`, `GenerationStatsService` / `GenerationJobItemRepository.countOutcomesBetween` | stage-based (`SAVED`,`FAILED`) — PENDING items (stage `QUEUED`) excluded; test (L4) |
   | `GenerationJobResponse.status` | may be `PENDING` → FE contract |
5. `QuestionGenerationBatch extends BaseEntity` (`rows` as `List<BatchRow>` with `@JdbcTypeCode(SqlTypes.JSON)` — copy the mapping style used for `Question.generationMeta`); status changes only via guarded bulk updates.
6. `GenerationBatchRepository`: `findByPublicIdAndDeletedFalse`, `existsByRequestedByUserPublicIdAndStatusIn`, paged list (all / by requester), `@Lock(PESSIMISTIC_WRITE) findByIdForUpdate`, `findOpenIdsWithoutOpenChild()` (reconciler, phase 4).

## Design Constraints
- Additive except the constraint/index recreation; existing rows unaffected (all existing jobs have `batch_id NULL`).
- `generation/domain` 8 → 11 classes, `generation/repository` 3 → 4 (≤ 15).
- `Clock` for timestamps.
- Coding standards (`pte-api/docs/CODING_STANDARDS_API.md`, see plan.md "Coding standards"): files ≤ 300 lines, services ≤ 5 public methods, `internal/**` packages ≤ 15 direct classes, injected `Clock` as last ctor arg (entities receive `Instant now`), `@Transactional` only on services (`readOnly = true` for queries), codes/messages/numbers in `*Constants`, `ApiResponse<T>`, domain exceptions + global `@ControllerAdvice` (no controller try-catch), `@Valid` + Bean Validation on DTOs, no `@Data` on entities, DTOs never expose entities, comments explain WHY; `app/src/test/java/com/pte/architecture` tests green, allowlists only shrink.
- Entities: `@Getter/@Setter/@NoArgsConstructor` like `QuestionGenerationJob` (no `@Data`); `BatchRow` is a record. Package counts after: `domain` 8→11, `repository` 3→4. Limits defaults as named constants (`BatchGenerationConstants.DEFAULT_MAX_ITEMS_PER_BATCH = 50`).

- Preflight: read V34/V40/V45 migrations, `QuestionGenerationJob` (Lombok @Getter/@Setter/@NoArgsConstructor, `BaseEntity`), `Question.generationMeta` JSON mapping, `GenerationJobRepository` (FQN JPQL constants), `QuestionGenerationProperties` (@Validated bounds) and `ImageKindTest`/`QuestionGenerationPropertiesValidatorTest`; packages after: `domain` 11, `repository` 4, `constant` 4.

## Quality and Testing State
- quality: skipped_by_user (decision: user_confirmed_skip)
- testing: passed — 437 run / 0 failed / 9 skipped (generation + architecture + settings), new `JobStatusTest` 5 + `BatchGenerationSettingsTest` 4; `ModuleStructureTest` 3/3; Postgres IT skipped by default (needs `-Dlifecycle.test.db.url`), V53 verified on local Postgres inside BEGIN/ROLLBACK
- integration: Postgres ITs run 2026-11-18 on a throwaway postgres:17 container (DB pte_lifecycle_test; host :5432 is a native Postgres, not pte-postgres, so a separate container on 127.0.0.1:55440 was used, then removed): 22 run / 0 failed / 0 skipped, stable over 3 runs (opt-in: -Dlifecycle.test.db.url/.user/.password, -DargLine=-Duser.timezone=UTC); without the property all 20 skip, subset 535 run / 0 failed / 29 skipped. No production bug found. BatchMigrationPostgresIntegrationTest 6: V52 schema with COMPLETED+RUNNING jobs upgraded to V53 (rows kept, batch fields null), PENDING accepted / unknown status rejected by ck_qgen_jobs_status, preview + saving job same author allowed and second saving job rejected, one QUEUED + two PENDING children allowed, ck_qgen_jobs_batch_fields enforced, second open batch rejected. JSONB rows round-trip in BatchSubmitRunPostgresIntegrationTest.

## Tests
- Unit `JobStatusTest`: `OPEN ∪ TERMINAL = values()`, `PENDING ∉ ACTIVE`.
- Postgres IT (`repository/QuestionGenerationPostgresIntegrationTest`, gated by `-Dlifecycle.test.db.url`; no Testcontainers in this project):
  - migration on a **V52 snapshot with existing jobs in every status** (Flyway target V52 → seed → migrate V53): rows intact, PENDING insert accepted, old CHECK gone exactly once;
  - preview job + saving job for same user both QUEUED → allowed; two saving QUEUED → rejected;
  - second open batch per user rejected; one QUEUED + two PENDING children → allowed; `ck_qgen_jobs_batch_fields` enforced.
- `ModuleStructureTest`, `PackageDensityTest`, `SourceFileSizeTest` green.

## Acceptance criteria
- App boots on DB migrated from V52; existing generation tests green; `ACTIVE` unchanged.

## Risks
- DO-block LIKE filter matching another CHECK — only the status CHECK contains `CANCELLING` on this table (verify with step 1 query).
- Index recreation briefly removes the guard → migration runs before new app (runbook); submits are serialized by the advisory lock anyway.
