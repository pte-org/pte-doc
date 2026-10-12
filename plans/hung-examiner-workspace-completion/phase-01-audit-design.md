# Phase 1 — Audit and design

Status: completed. Q1–Q4 confirmed. Stories E02–E06,E08–E11. Source audit, contracts, and V98 schema design verified. [quality: skipped_by_user; decision: user_confirmed_skip]

## Tasks

- [x] Inspect current git status in pte-api/pte-web/pte-doc; preserve attendance/navigation/lockfile changes. Read applicable AGENTS and installed Next guides.
- [x] Recheck ExaminerWorkController, ExaminerScoringService, ExaminerWorkspaceQueryService, ExaminerWorkspaceReadRepository and legacy ExaminerWorkQueueRepository; inventory current API consumers and fallback behavior.
- [x] Inspect ExaminerAttemptAssignment, ExaminerAnswerScore, ScoringEligibilityQueryService, ExaminerReviewVersionService, ScoreSourceSelectionService, ScorePublicationLockService, ScoringService and ReportPublishService. Document the actual pinned eligibility pool, read guards, selected-source readiness and shared session lock APIs.
- [x] Q1–Q4 confirmed: assigned-scope atomic completion, existing 0–100 rules, published Completed/History and same-scope Overview, Host-resolved issues without reopen. Record these in final contracts.
- [x] Produce non-mutating inventory SQL/report for unpublished/published assignments: zero/partial/all immutable finals, zero eligible answers, excluded members, cohort-less/AI_ONLY/manual sessions, orphan ownership and report snapshot references.
- [x] Define DTOs/endpoints and capability mode before migration. Proposed POST /work/{session}/{attempt}/start, PUT /work/{session}/{attempt}/answers/{answer}/draft, POST /work/{session}/{attempt}/finalize, GET /work/{session}/{attempt}/commands/{request}; bounded /history and pinned /guidelines projections.
- [x] Request contracts carry requestPublicId, expectedWorkVersion and per-answer expectedDraftVersion where relevant; draft carries nullable score/comment/decision/reviewed AI identity. Finalize carries exact work/draft/AI revision manifest. Responses expose original receipt separately from current state.
- [x] Plan new internal ExaminerWorkflowCommandService, ExaminerDraftCommandService, ExaminerWorkflowQueryService and shared ExaminerGradingPolicy; avoid enlarging existing large service or introducing cross-module entity access.
- [x] Define additive examiner_grading_work, examiner_answer_drafts and immutable examiner_grading_events/receipts with owner/assignment/answer FKs, unique receipts and bounded comments. Work references immutable assignment; unique draft per work+answer. First persisted revision 1; missing 0.
- [x] Recheck migration maximum (known V97); allocate unique next Flyway migration V98__examiner_workflow_and_drafts.sql.
- [x] Backfill legacy states using verified real evidence: zero finals Pending, partial finals In Progress, all finals Completed only with nonempty real eligibility.
- [x] Treat missing work rows as an explicit compatibility condition during additive rollout: read-only queries derive legacy effective state from the actual pinned nonempty eligible pool and immutable finals; mutation creates/locks work under the shared session mutex.
- [x] Finalize server/client capability contract and old endpoint gating. Define inventory thresholds and rollback read-only behavior before release.
- [x] Q2: pinned scoring-template/profile context only. No new criterion definitions or formula.
- [x] Q3: separate read-only authorization/projection for published Completed and finalized history; never relax mutable detail guards globally.
- [x] Q4: design new assignment-scoped issues with Host resolution/audit. Current support endpoint is HOST_ADMIN only; no unrestricted tickets/empty resource menu.

## Checks and acceptance

Review schema FK/index and lock ordering against actual source; trace each E02–E06/E08–E11 requirement to a contract/test. Baseline compiler/typecheck verified passing. All Q1–Q4 decisions and compatibility policies documented in contracts.md.

## Design Constraints

Business decisions are resolved. No invented scoring math, deadline or multi-rater state. Keep assignment/final-score immutable and publication Host-owned. Migration rollback retains written data; no destructive down migration.

## Quality and Testing State

Quality: skipped_by_user. Decision: user_confirmed_skip.
Testing: not_started (skipped by user via --fast).
Business decisions: Q1–Q4 confirmed.

Planning preflight: reuse existing scoring public DTOs/facades, ClockConfig constructor injection, SessionService session mutex, immutable V95 final-score receipt contract and @pte/ui/locale web conventions. Preserve unrelated attendance changes. Allocated V98 for upcoming schema migration.
