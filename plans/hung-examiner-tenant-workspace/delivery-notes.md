# Delivery Notes — Examiner Tenant Workspace & Manual Marking Authority

## Executive Summary
This document provides delivery notes, architectural changes, schema additions, co-release procedures, and operational boundaries for the Examiner Tenant Workspace implementation across `pte-api` and `pte-web`.

---

## 1. Scope of Delivered Changes

### 1.1 Backend (`pte-api`)
- **Schema Migrations**:
  - `V93__examiner_decision_contracts_and_receipts.sql`: Adds `decision_kind`, `reviewed_ai_score`, `reviewed_ai_version`, `expected_review_version`, `request_public_id`, and `request_fingerprint` to table `examiner_answer_scores`. Creates partial unique index `uq_examiner_score_receipt` on `examiner_answer_scores(tenant_id, examiner_public_id, request_public_id)` and lookup index `idx_examiner_score_request` for idempotency and receipt tracking.
  - `V94__align_legacy_manual_examiner_scores.sql`: Safe bounded backfill setting `decision_kind = 'LEGACY_IMPORTED'` for manual examiner answers in unpublished cohorts and aligning `scoring_answers.selected_score_source` to `EXAMINER`.
- **Domain & Services**:
  - `ExaminerDecisionKind` enum: `CONFIRM_AI`, `MANUAL`, `LEGACY_IMPORTED`.
  - `ScoringReviewVersionService`: Canonical length-prefixed SHA-256 calculation for per-answer review hashes and session review versions.
  - `ScoreSourceSelectionService`: Guarded by `assertNotManualExaminer` to prevent Host overrides on manual cohorts.
  - `ScoringReviewService`: Enforces session-first mutex before locks; blocks `submitTeacherScore` when cohort is `MANUAL_EXAMINER`.
  - `AiScoringResultPersistenceService`: Acquires session-first mutex to serialize concurrent AI callbacks against human score commits.
  - `ExaminerAssignmentService`: Blocks assignment to `AI_ONLY` sessions or excluded cohort members.
  - `ExaminerScoringService`: Strictly requires `MANUAL_EXAMINER` cohort, validates review version freshness, records immutable decision audit + receipt, and atomically selects `ScoreSource.EXAMINER`.
  - `GradingCohortService`: Scheduled reconciler runner with Spring-managed transaction boundary and session mutex.
  - `GradingCompletionEvaluator`: Strictly checks manual assignment ownership and valid score pointer.
  - `ReportPublishService`: Uses `resolveCohortAttempts` under session mutex to consume only required submitted attempts and block unsubmitted required members.
- **Diagnostic Tool**:
  - `pte-api/scripts/diagnose-examiner-finalization-legacy.sql`: SQL queries to identify unaligned or orphan attempts before final publication.

### 1.2 Frontend & Shared Packages (`pte-web`)
- **Shared API Client (`@pte/api-client`)**:
  - Extracted shared workflow types to `packages/api-client/src/types/scoring/examiner.ts` and re-exported in `index.ts`.
  - Added modern request/response contracts (`ExaminerDecisionKind`, `ExaminerAiAvailability`, `ExaminerAiReferenceResponse`, `ExaminerDecisionResponse`, `SubmitExaminerScoreRequest`, `ExaminerScoreSubmissionResponse`).
  - Added `markingMode`, `cohortStatus`, `canSelectScoreSource` to `HostScoreReviewResponse`.
- **Examiner Tenant Workspace (`apps/tenant-web/features/examiner`)**:
  - `ExaminerQueueView.tsx`: Queue list with server-side pagination, status filters, and progress indicator.
  - `ExaminerAttemptDetailView.tsx`: Deep-linkable attempt marking workspace with in-memory draft state, question navigator, and beforeunload guard.
  - `AnswerContentRenderer.tsx`: Content renderers for all 6 answer kinds (AUDIO, TEXT, SELECTION, POSITIONAL_SELECTION, WORD_INDICES, UNRECOGNIZED) with native audio playback (no autoplay).
  - `AiReferencePanel.tsx`: Truthful display of AI status (`AVAILABLE`, `PENDING`, `FAILED`, `UNAVAILABLE`) with "Use AI Score" fill action.
  - `DecisionPanel.tsx`: Score input (0..100 integer validation), diff vs AI display, stale version detection, blocking reason display, and submit trigger.
  - `ConfirmDecisionDialog.tsx`: Confirmation modal showing target, score, decision kind, request UUID, and review version.
- **Dynamic Routing**:
  - Added `apps/tenant-web/app/(dashboard)/examiner/work/[sessionPublicId]/[attemptPublicId]/{page,loading,error}.tsx`.
  - Added session dynamic segment loading and error boundaries.
- **Host Scoring Controls (`apps/tenant-web/features/exams`)**:
  - `HostScoreReviewPanel.tsx`: Respects `canSelectScoreSource` and `markingMode`; disables bulk score-source overrides and displays policy alerts when cohort is `MANUAL_EXAMINER`.
  - `GradingCohortSection.tsx`: Explains the `MANUAL_EXAMINER` cohort workflow and displays finalized marking mode badges.

---

## 2. Co-Release & Operational Procedures

1. **Deploy Migration First**: Run Flyway migrations V93 and V94. V93 adds columns and partial indexes without locking active tables; V94 updates legacy rows in unpublished manual cohorts.
2. **Deploy Backend API**: Deploy updated `pte-api` build. The backend enforces session mutexes and rejects legacy manual score writes without required metadata.
3. **Deploy Web Applications**: Deploy `tenant-web` with new examiner routes and updated host panels.
4. **Diagnostic Check**: Run `pte-api/scripts/diagnose-examiner-finalization-legacy.sql` to verify cohort alignment across existing sessions.

---

## 3. Rollback Boundaries

- **Additive Schema**: The new columns in V93 are nullable with default values; existing queries and `AI_ONLY` workflows remain fully backward-compatible.
- **Immutable Decisions**: Examiner score decisions recorded under V93 are immutable. In the event of a backend rollback, old code will ignore the new decision columns. However, manual scores committed with V93 will retain their `ScoreSource.EXAMINER` pointers in `scoring_answers`.
