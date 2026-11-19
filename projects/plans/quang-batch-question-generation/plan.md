# Plan: Batch AI question generation
Status: 📝 Draft (rev 2: red-team + user decisions applied)
Date: 2026-11-17
Mode: Hard (test flag: default)

Builds on [quang-ai-question-generation](../quang-ai-question-generation/plan.md) (single job, 1–10 items).
Code root: `pte-api/app/src/main/java/com/pte/itembank/internal/generation` (below: `generation/`).

## Overview

Authors (`PLATFORM_ADMIN`, `ACADEMIC_MANAGER`, `ACADEMIC_STAFF`, `PLATFORM_AUTHOR` — `GenerationAccessPolicy.AUTHOR_ROLES`)
submit **one batch** of up to N questions (default 50) for one pool, made of rows
`{taskType, cefrLevel, count, topicHints[], imageKind}` (stored as JSONB on the batch). The backend splits each row into
**child jobs** of ≤ 10 items, creates every child and item upfront (seq 0 `QUEUED`, rest `PENDING`), and runs children
**one after another** through the existing worker (`QuestionGenerationWorker` → `JobLeaseService` → `GenerationJobRunner`).
v1 = create / get / list / cancel a batch + bulk-delete its drafts.

```
POST /api/v1/question-generation/batches  (QUESTION_GEN_BATCH_ENABLED)
  └─ QuestionGenerationBatchService.submit  [pg_advisory_xact_lock(SUBMIT_ADVISORY_LOCK_KEY)]
QuestionGenerationWorker.tick → JobLeaseService.claimNext  [claim lock, cap on live leases, previews first]
  └─ GenerationJobRunner.run(child) → JobLeaseService.finish
       └─ lock batch row → guarded job finish → BatchChainingService.onChildTerminal (promote | stop | close)
BatchReconciler (@Scheduled) — closes any open batch that has no open child (safety net)
```

## Decisions (binding)

| # | Decision | Rejected alternative → reason |
|---|---|---|
| D1 | Table `question_generation_batches` with `rows JSONB`; jobs get nullable `batch_id` FK, `batch_seq`, `batch_row_index` | `batch_id` only on jobs → nowhere for cancel flag / progress / unique open batch. Separate rows table → not needed in v1 (retry-by-row deferred) |
| D2 | Batch status `QUEUED, RUNNING, CANCELLING, COMPLETED, PARTIALLY_COMPLETED, FAILED, CANCELLED`, terminal status recomputed from children/items | Counter increments → drift |
| D3 | `JobStatus.PENDING`; `ACTIVE` keeps its meaning; explicit sets `OPEN`, `LEASED`, `TERMINAL` | PENDING in `ACTIVE` → breaks index mirror + cap count |
| D4 | Children + items created upfront; quota reserved via `sumRequestedSince*` | Lazy children → second quota source |
| D5 | One open **saving** unit per user (standalone saving job = batch of one); mirrored by partial unique indexes | Parallel batches per user → starvation |
| D6 | Queue instead of reject: cap enforced at claim on live leases, claims serialized by advisory lock | RabbitMQ → second source of truth for a DB-lease worker |
| D7 | Chaining in the job's terminal transaction; **lock order: batch row first, then job rows** everywhere | Separate promoter → latency + races |
| D8 | Fatal = `failureCode ∈ FATAL_FAILURE_CODES` (`GENERATION_PROVIDER_AUTH`, `GENERATION_PROVIDER_UNAVAILABLE`, `GENERATION_REQUESTER_NOT_ALLOWED`) **regardless of job status** → remaining children cancelled | Keep running → every child fails the same way |
| D9 | Batch children always `saveQuestions = true`; live view reuses `/jobs/{id}/live` via `currentJobPublicId` | Batch SSE multiplexer → out of scope |
| D10 | Codes/messages in `generation/constant/BatchGenerationConstants`; audit on batch create / cancel / bulk delete | Inline strings |
| U1 | **Preview priority**: claim order `(batch_id is not null), created_at, batch_seq, id` → standalone/preview jobs before batch children. Preview jobs (`save_questions = false`) are **exempt** from the one-open rule: V53 recreates `uk_qgen_jobs_one_active_per_requester` with `AND save_questions` | FIFO only → a 50-item batch blocks the question-form preview for an hour |
| U2 | **Quota refund**: jobs `CANCELLED` with `started_at IS NULL` are excluded from `sumRequestedSince*` (children cancelled before start by user cancel or fatal stop). Items that ran, even failed, count. Also refunds standalone queued-then-cancelled jobs (accepted behaviour change) | No refund → cancel locks users out for the day |
| U3 | **PICTURE gate**: config flag `itembank.generation.picture-enabled` (`QUESTION_GEN_PICTURE_ENABLED`, default `false` until the image provider is fixed). Submit rejects rows with `imageKind=PICTURE` (batch and standalone) with `GENERATION_PICTURE_DISABLED`. Other fatal codes still stop the whole batch (D8) | Health signal from recent failures → more code, flaky; chosen flag is simplest. Note: `AUTO` resolving to picture must also respect the flag (`ImageKind.resolve`) |
| U4 | **v1 scope = core** (phases 1–5 below). Everything else in "Deferred (v2)" | – |
| M1 | Ordering relies on `created_at` (`@CreationTimestamp`, not settable), `batch_seq`, `id`; no explicit createdAt | – |
| M7 | Rollout: migration first, then app; batch creation behind `QUESTION_GEN_BATCH_ENABLED` (default false) until all instances run the new code | – |

### Coding standards (binding: `pte-api/docs/CODING_STANDARDS_API.md`)
- Core principles: DRY (extract at 3rd repetition), KISS, YAGNI (v2 items stay deferred), Fail Fast (`@Valid` at controller), Law of Demeter, CQS — commands return `void` except the existing accepted pattern of submit/cancel returning the resource response (as `QuestionGenerationJobService.submit/cancel` do today).
- File ≤ 300 lines; service ≤ 5 public methods → pre-split: `QuestionGenerationBatchService` (submit, cancel), `BatchRequestValidator`, `BatchSplitter`, `BatchChainingService`, `BatchStatusCalculator`, `BatchReconciler`, `QuestionGenerationBatchQueryService`, `BatchDraftDeletionService`, `BatchDraftDeleteExecutor`. Current sizes checked: `JobLeaseService` 99, `QuestionGenerationJobService` 191, `GenerationJobRepository` 110, `QuestionGenerationController` 100, `QuestionQueryService` 287 (not touched in v1).
- Package density (`internal/**` ≤ 15 direct classes, sub-package ≥ 3): new `generation/batch` (9) and `generation/batch/dto` (5); after v1 `domain` 11, `repository` 4, `constant` 4, `exception` 10, `controller` 4, `worker` 5–6, `dto` 11 (unchanged).
- Time only via injected `Clock` (last constructor parameter); entities get `Instant now` from services; one `@Autowired` constructor when several exist.
- `@Transactional` only on services; `readOnly = true` for queries; `REQUIRES_NEW` only via a separate bean (no self-invocation).
- No hardcoded strings/numbers: new `generation/constant/BatchGenerationConstants` (codes, messages, audit actions, result strings, limits, lock keys) next to `QuestionGenerationConstants`.
- Responses wrapped in `ApiResponse<T>`; errors are `DomainException` subclasses handled by the global `@ControllerAdvice`; no try-catch in controllers.
- DTOs are records with Bean Validation and never expose entities; entities use Lombok getters/setters, never `@Data`.
- Comments explain WHY. Architecture tests in `app/src/test/java/com/pte/architecture` (`PackageDensityTest`, `SourceFileSizeTest`, `ModuleStructureTest`, …) must pass; allowlists only shrink, never grow.

### Tenancy and access (H5)
Batches are platform-bank only (`questions.tenant_id` null; same as current generation). Every batch read/action goes
through `GenerationAccessPolicy.requireAccess(caller, batch)` (overload added). `ACADEMIC_STAFF` see only their own
batches: the list endpoint forces `requestedBy = caller` for them regardless of params; another author's batch answers 404.
Test: staff A cannot get / cancel / bulk-delete staff B's batch.

### Cross-module note (L5)
Adds `ITEMS_PER_BATCH` to `com.pte.billing.QuestionGenerationLimit` (billing module, public API used by `GenerationLimits`).
Run `ModuleStructureTest` and `PackageDensityTest`/`SourceFileSizeTest` in every phase.

## Phases (v1)

| # | Phase | Goal | Depends | Status |
|---|---|---|---|---|
| 1 | [Schema + domain](phase-01-schema-domain.md) | V53, batch entity, `PENDING`, status sets, index change, flags | – | [x] [quality: skipped_by_user; decision: user_confirmed_skip] |
| 2 | [Claim: priority + concurrency](phase-02-claim-priority-concurrency.md) | Queue instead of reject, preview first, cap on live leases, no head-of-line block | 1 | [x] [quality: skipped_by_user; decision: user_confirmed_skip] |
| 3 | [Batch submit + quota](phase-03-batch-submit-quota.md) | Validate, cap, quota with refund, PICTURE gate, split | 1, 2 | [x] [quality: skipped_by_user; decision: user_confirmed_skip] |
| 4 | [Chaining, cancel, reconciler](phase-04-chaining-cancel-reconciler.md) | Promote/stop/close under batch lock; cancel; safety net | 3 | [x] [quality: skipped_by_user; decision: user_confirmed_skip] |
| 5 | [REST API + bulk draft delete](phase-05-rest-api-bulk-delete.md) | create/get/list/cancel, bulk delete drafts, `/jobs` hides children | 4 | [x] [quality: skipped_by_user; decision: user_confirmed_skip] |
| 6 | [FE contract, docs, runbook](phase-06-fe-contract-docs-runbook.md) | Contract, rollout/rollback runbook | 5 | [x] [quality: skipped_by_user; decision: user_confirmed_skip] |

## Deferred (v2) — not in this plan's execution
- **Retry-failed** (new batch from failed items per row; would need per-row lineage).
- **ETA estimator** (`estimatedSecondsRemaining` from `ESTIMATED_SECONDS_TEXT/MEDIA`).
- **Bulk SUBMIT_APPROVAL / APPROVE** by batch (+ `generationBatchId` filter on `GET /api/v1/questions`, which needs the
  `QuestionListFilter` refactor because `QuestionQueryService` is 287/300 lines).
- **Idempotency-Key** on batch submit (one-open rule already blocks double submit in v1).
- **Duplicate-race hardening**: per-hash advisory lock in `GeneratedQuestionWriter.save`, delete unused
  `generation/draft/DuplicateChecker`. Note M5: `test/.../pipeline/GenerationIntegrationTest` imports and instantiates
  `DuplicateChecker` — update that test in the same change. v1 already has the DB-backed check
  (`GeneratedQuestionWriter.isDuplicate/save` → `existsByTaskTypeKeyAndContentHashAndDeletedFalse`), which covers
  batch-wide and cross-batch duplicates because children run sequentially.
- **`GenerationQuotaGuard` extraction**: only if v2 adds a third caller; v1 duplicates two lines at most.

## Risks

| Risk | Mitigation | Phase |
|---|---|---|
| A terminal path skips the hook → batch stuck open, user blocked | Single hook from `finish` / stale-cancel / cancel; `BatchReconciler` safety net; invariant test | 4 |
| Deadlock cancel vs finish vs claim | Batch row first everywhere (B1); latch-based ITs | 2, 4 |
| Cap exceeded across instances | Claim advisory lock; two-claimer IT | 2 |
| V34 `requested_count BETWEEN 1 AND 10` vs `ITEMS_PER_JOB` setting max 50 | Splitter clamps to `MAX_ITEMS_PER_JOB_HARD_LIMIT` | 3 |
| Old app instance running during rollout sees PENDING jobs | `QUESTION_GEN_BATCH_ENABLED=false` until all instances upgraded; rollback SQL | 6 |
| Status CHECK drop by wrong name | DO block looks up `pg_constraint` by definition (M8) | 1 |
| Hook exception rolls back the job finish | Hook runs in the same tx on purpose; failure → log + metric, lease expires, job resumed/reconciler repairs (L2) | 4 |

## Open questions
- (closed U1–U4, quota refund, retry scope, `/jobs` children visibility → hidden by default (M9))
1. Default per-batch cap 50, max rows 20, max topic hints 10 per row — confirm.
2. Picture flag default `false` in all envs until provider fixed — confirm with ops.
