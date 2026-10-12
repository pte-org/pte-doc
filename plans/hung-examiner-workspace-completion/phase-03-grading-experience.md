# Phase 3 — Durable drafts and grading completion

Status: COMPLETED. Q1 atomic assigned-scope finalization and Q2 existing scalar scoring confirmed. Stories E03–E07. Fast mode execution.

## Tasks

- [x] Implement ExaminerDraftCommandService and DTOs. Validate active owner/tenant/assignment, started work, mutable publication/cohort state and answer belongs to pinned eligible pool using shared ExaminerGradingPolicy.
- [x] Session mutex -> work/draft lock -> deterministic answer lock where needed. Exact receipt lookup after current read authorization and before mutable validation; compare expected draft/work versions. Missing draft 0, first save1, then monotonic. Newer tab wins via explicit conflict, never silent overwrite.
- [x] Persist score/comment/decision/reviewed-AI context and bounded immutable save event/receipt. Draft may be incomplete; readiness validates required fields. Draft save does not call final-score path, select score source or modify Host publish readiness.
- [x] Detail projection merges existing immutable legacy final answers (read-only) and latest mutable drafts for remaining answers; expose revision, permissions, capability mode, pinned guidance and stable answer order.
- [x] Extract reusable eligibility/owner/AI validation from ExaminerScoringService without duplicating business logic. Reuse current normalized integer0–100 and aggregation; no new criterion rubric or formula.
- [x] Implement atomic finalize transaction: session -> work -> complete eligible answer locks in deterministic order -> publication state. Receipt replay after current read permission, before checking Completed/published/versions. Current assignment and owner still required to disclose receipt.
- [x] Revalidate cohort eligibility/membership, manual mode, unpublished state, exact pinned answer pool, nonempty pool, immutable legacy answers, captured work/draft/AI versions and unresolved approved blocking issues.
- [x] Partition the assigned pool into existing immutable finals and missing finals. Preserve the existing subset as authoritative: never require today's AI version/availability to match a legacy final decision and never recreate its score or fingerprint. Live AI/review-version validation applies only to new decisions. Test completion of a partial legacy assignment after AI has changed or become unavailable for an already-finalized answer.
- [x] Insert only missing immutable ExaminerAnswerScore rows preserving legacy scores/request metadata; select EXAMINER source for approved finalized answer set through internal shared service. Persist finalized comments/scoring context, Completed, event and immutable receipt atomically.
- [x] Respect V95 unique `(tenant_id, examiner_public_id, request_public_id)` on final-score rows and existing cross-answer reuse rejection. The bulk request UUID belongs only to the aggregate receipt. Derive a deterministic per-answer child UUID from the parent UUID + answer UUID with one fixed versioned algorithm; store the mapping in the canonical finalize manifest/receipt. Each newly inserted final score uses its distinct child UUID and the actual per-answer intent fingerprint compatible with existing receipt encoding. Never copy the parent UUID onto multiple score rows or rewrite legacy keys. Test two-or-more-answer finalize, deterministic retry mapping, collisions/reused child keys and partial-legacy preservation. Atomic-mode old endpoint must not accept child requests as a completion bypass.
- [x] Refactor internal existing final-score creation into policy/persistence primitive invoked inside outer transaction. Do not loop HTTP submits or rely on self-invoked @Transactional for atomicity.
- [x] Add aggregate assignment-completion gate in ScoringService/publication readiness and ReportPublishService under existing session lock. A Ready/draft/partial atomic assignment must block publication even if answer source state appears complete. Test legacy mode compatibility separately.
- [x] Gate old per-answer score command for atomic-mode assignments. Server/client capability agrees; feature disabled must not let old client bypass new completion semantics.
- [x] Extend request/types/hooks for save/finalize/receipt. Preserve exact unknown-outcome command UUID and captured payload per assignment outside transient dialogs; reconcile using authorized receipt GET. No new intent until committed/not-committed conflict is understood.
- [x] Split useExaminerSubmissions into focused draft/finalization controllers. Maintain local input revision counters; late ACK marks only captured revision saved and never overwrites later edits. 401 preserves unsaved input and offers re-auth;409 preserves input and shows compare/reload choice.
- [x] Add focused DraftStatus, ExaminerCommentField, GradingScoreSummary and ConfirmAttemptFinalizeDialog components; reuse prompt/media/navigator/AI panels. Previous/Next preserves edits; media retry does not reset grading state.
- [x] Add route-leave/sidebar and beforeunload dirty warnings. Saving/Saved/Failed accurate; only backend-confirmed finalization changes to Completed. Failed finalization retains drafts and exact retry command.
- [x] Summary displays each required answer, score/decision/comment/validation and legacy read-only status; frontend does not compute substitute report aggregation. Confirm AI validates current exact AI version at finalize; missing/error AI does not become0.
- [x] Completed read-only according to Q3 projection; no reopened edit UI. Keep actual finalizedAt and applied pinned context.

## Checks and acceptance

Draft integration tests: save/reload, captured-version conflicts, same key same/different payload, revoked role/assignment, invalid pool/score/comments, auth expiry, source/publication unchanged. Finalize tests: missing requirements/empty pool/changed AI/blocking issue/Host publish race reject; all updates rollback on forced failure; legacy partial preservation; two submissions produce one receipt/event/final set; retry after lifecycle change returns original authorized outcome. Frontend controller tests cover late responses, offline unknown outcome, next/previous and unsaved navigation. Run scoped checks, no claims from compile alone.

## Design Constraints

Immutable final scores remain immutable. Draft and final score have different tables/APIs. Session-first lock order shared with Host; no deadlocks from answer/work inversion. Exact receipt fingerprint includes operation and full captured manifest using existing canonical encodings. Store bounded safe audit values, no answer/audio payloads. Neither AI nor Examiner publishes final reports.

## Quality and Testing State

Quality: not evaluated. Testing: not started. Required unit/integration/controller/API checks planned. Optional TDD/ck:quality: not selected. Q1/Q2 confirmed; atomic assigned-scope completion and existing scoring rules required.
