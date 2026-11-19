# Phase 3: Batch submit, quota (with refund), PICTURE gate, split

## Goal
`QuestionGenerationBatchService.submit` creates batch + all children (seq 0 `QUEUED`, rest `PENDING`) + all items in ONE
transaction behind the existing submit advisory lock. Quota refunds never-started cancelled jobs (U2). PICTURE rows are
rejected while `pictureEnabled=false` (U3).

## Files
Create (package `generation/batch`, `generation/batch/dto`)
- `generation/batch/QuestionGenerationBatchService.java` — submit (cancel added in phase 4)
- `generation/batch/BatchSplitter.java` — pure
- `generation/batch/BatchRequestValidator.java`
- `generation/batch/dto/SubmitGenerationBatchRequest.java` — `record(@NotBlank String pool, @NotNull @Size(min = 1, max = 20) List<@Valid @NotNull Row> rows)`; `Row(@NotBlank String taskType, @NotBlank String cefrLevel, @NotNull Integer count, @Size(max = 10) List<@NotBlank String> topicHints, String imageKind)`
- `generation/constant/BatchGenerationConstants.java`

Change
- `generation/repository/GenerationJobRepository.java` — `sumRequestedSince`, `sumRequestedSinceByUser` refund clause; `existsByRequestedByUserPublicIdAndSaveQuestionsTrueAndStatusIn`
- `generation/job/QuestionGenerationJobService.java` — one-open rule for saving jobs incl. open batch; preview exempt; PICTURE gate
- `generation/domain/ImageKind.java` (or caller) — PICTURE gate also for `AUTO` resolving to `PICTURE` (gate in pipeline: `AUTO` resolves to `CHART` when picture disabled)

## Steps
1. Validation (before lock; `GenerationRequestInvalidException` with constant codes; M3):
   - `rows` non-null, 1..20; each row non-null (`@Valid` nested + service re-check for null lists → treat `topicHints null` as empty)
   - each `count` in `[1, maxItemsPerBatch]`; `long total = sum(count)`; `total ≤ maxItemsPerBatch` → else `GENERATION_BATCH_SIZE_OUT_OF_RANGE`
   - task type via `GenerationTaskTypeCatalog.find`, CEFR (`CefrLevel.parseOrNull`), pool (`QuestionPool`), `ImageKind.parse`
   - `imageKind == PICTURE && !properties.isPictureEnabled()` → `GENERATION_PICTURE_DISABLED` (also in standalone submit)
   - topic hints ≤ 10 per row, each via `TopicHintPolicy.normalize`, blanks/duplicates dropped
   - `properties.isBatchEnabled()` else `GENERATION_BATCH_DISABLED` (503); `properties.isEnabled()`; `GenerationAccessPolicy.requireAuthor`
2. Lock: `jobs.lockSubmissions(SUBMIT_ADVISORY_LOCK_KEY)` (shared with standalone).
3. One open unit (D5): open batch (`BatchStatus.OPEN`) or open saving job (`existsBy...AndSaveQuestionsTrueAndStatusIn(user, JobStatus.OPEN)`) → `GENERATION_JOB_ALREADY_RUNNING` (409). Standalone saving submit applies the same two checks; preview submits (`saveQuestions=false`) skip both (U1).
4. Quota (U2) — new JPQL for both sums:
   ```
   select coalesce(sum(j.requestedCount), 0) from JOB j where j.createdAt >= :since [and j.requestedByUserPublicId = :user]
     and not (j.status = CANCELLED and j.startedAt is null)
   ```
   Effect: children cancelled before start (user cancel or fatal stop) and standalone jobs cancelled while `QUEUED` are refunded; jobs that started count fully even if items failed or were cancelled mid-run. `/quota` (`QuestionGenerationQueryService.quota`) uses the same query automatically.
   Check `user + total ≤ maxItemsPerUserPerDay`, `global + total ≤ maxItemsPerDayGlobal` (UTC day, `Clock`).
5. Split (`BatchSplitter`): `perJob = min(limits.maxItemsPerJob(), MAX_ITEMS_PER_JOB_HARD_LIMIT)` (V34 CHECK 1..10). Per row distribute `count` round-robin over hints (or one `null` group) → chunk each group ≤ perJob. 25 items, hints [a,b,c] → 9/8/8 → 3 children. `batch_seq` 0..n-1 across rows in row order; `batch_row_index` = row.
6. Persist: batch (`QUEUED`, rows JSON, total) → children (`saveQuestions=true`, `status = seq==0 ? QUEUED : PENDING`) → items stage `QUEUED` (`saveAll`). `DataIntegrityViolationException` → `GENERATION_JOB_ALREADY_RUNNING`. No explicit `createdAt` (M1: `@CreationTimestamp`).
7. Audit `AuditLogService.record(caller, BATCH_AGGREGATE, publicId, BATCH_CREATED, "rows=..,items=..")`.

## Design Constraints
- One transaction; lock taken after validation. `BatchSplitter` has no Spring/DB dependency.
- No `GenerationQuotaGuard` extraction in v1 (deferred); the two services call the same repository methods.
- Constants for codes/messages; files ≤ 300 lines.
- Coding standards (`pte-api/docs/CODING_STANDARDS_API.md`, see plan.md "Coding standards"): files ≤ 300 lines, services ≤ 5 public methods, `internal/**` packages ≤ 15 direct classes, injected `Clock` as last ctor arg (entities receive `Instant now`), `@Transactional` only on services (`readOnly = true` for queries), codes/messages/numbers in `*Constants`, `ApiResponse<T>`, domain exceptions + global `@ControllerAdvice` (no controller try-catch), `@Valid` + Bean Validation on DTOs, no `@Data` on entities, DTOs never expose entities, comments explain WHY; `app/src/test/java/com/pte/architecture` tests green, allowlists only shrink.
- `QuestionGenerationBatchService` public methods: `submit`, `cancel` (≤ 5); validation in `BatchRequestValidator`, split in `BatchSplitter` so the service stays well under 300 lines. `QuestionGenerationJobService` (191 lines) only gains the open-batch/PICTURE checks — if it would pass 300, move checks to a package-private helper. CQS: `submit` returns the created response like the existing `QuestionGenerationJobService.submit` (accepted existing pattern; no new `xAndReturn` methods). Limits 20 rows / 10 hints as constants.
- Preflight: read `QuestionGenerationJobService` (now 188 lines; submit/cancel), `GenerationJobRepository` sums (no refund clause yet), `GenerationTaskTypeCatalog.find`, `TopicHintPolicy.normalize`, `ImageKind.resolve` (only caller `GenerationPipeline` line 101, file at 300 lines → change in place, no new lines), `AuditLogService.record(caller, aggregate, id, action, summary)`, `GenerationDisabledException` (503; gains a (code,message) ctor for `GENERATION_BATCH_DISABLED` instead of a new class). `GenerationBatchResponse` is created here (submit returns it); phase 5 only adds the query side. New package `generation/batch` + `generation/batch/dto`.

## Quality and Testing State
- quality: skipped_by_user (decision: user_confirmed_skip)
- testing: passed — 760 run / 0 failed / 33 skipped (generation + itembank Question* + billing + architecture + ModuleStructureTest). New: BatchSplitterTest 6 (1; 10; 11→[10,1]; 25+3 hints→[9,8,8]; setting 50 clamped to 10; continuous seq), BatchRequestValidatorTest 8 (count 0/>cap/null, sum overflow incl. Integer.MAX_VALUE, null rows/list, 21 rows, 11 hints, injection hint, PICTURE disabled, unknown fields, flags/role), QuestionGenerationBatchServiceTest 7 (children QUEUED/PENDING, lock order, open saving job blocks batch, open batch blocks batch, user/global quota for whole batch, unique-index race → 409); QuestionGenerationJobServiceTest +2 (open batch blocks saving job, preview allowed; PICTURE gate); ImageKindTest +1 (AUTO→CHART when pictures off); GenerationRepositoryQueriesTest +1 (H2 refund: queued-then-cancelled refunded, started-then-cancelled counted). Postgres quota ITs (batch of 30 cancel/fatal) not written: need dedicated DB + phase 4 cancel; covered by H2 refund test + phase 4 unit tests.
- integration: Postgres ITs run 2026-11-18 on a throwaway postgres:17 container (DB pte_lifecycle_test; host :5432 is a native Postgres, not pte-postgres, so a separate container on 127.0.0.1:55440 was used, then removed): 22 run / 0 failed / 0 skipped, stable over 3 runs (opt-in: -Dlifecycle.test.db.url/.user/.password, -DargLine=-Duser.timezone=UTC); without the property all 20 skip, subset 535 run / 0 failed / 29 skipped. No production bug found. BatchQuotaReconcilePostgresIntegrationTest: cancel after child 0 ran and failed → used = 2 of 6 (user and global sums); fatal REQUESTER_NOT_ALLOWED (child CANCELLED), PROVIDER_AUTH, PROVIDER_UNAVAILABLE → remaining children CANCELLED with started_at null + code, batch FAILED, used = only the child that ran. BatchSubmitRunPostgresIntegrationTest: second submit while open → 409.

## Tests
- Unit `BatchSplitterTest`: 1; 10; 11 → [10,1]; 25 + 3 hints → [9,8,8]; setting 50 clamped to 10; seq continuous.
- Unit `BatchRequestValidatorTest`: count 0 / > cap / null row / null hints / sum overflow (`Integer.MAX_VALUE` rows) / PICTURE disabled / injection hints.
- Unit `QuestionGenerationBatchServiceTest`: open saving job blocks batch; open batch blocks standalone saving job; preview allowed beside open batch; quota user/global; flag off → 503.
- Quota tests (U2, Postgres IT): batch of 30 → user cancels while child 0 runs → used = 10 (children 1–2 refunded); fatal stop on child 0 → used = 10; standalone QUEUED then cancelled → used = 0; child that ran and failed → still counted.

## Acceptance criteria
- 50-item / 3-row batch → 1 batch, ≥ 5 children, 50 items, only seq 0 claimable; `/quota` reflects the whole batch at once and the refund after cancel.

## Risks
- Refund clause changes standalone semantics (accepted, U2); FE quota display must re-fetch after cancel.
