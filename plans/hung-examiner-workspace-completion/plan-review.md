# Examiner completion — independent plan review

Date: 2026-10-12. Reviewer: examiner_completion_redteam. Scope: spec, codebase audit, two research reports, master plan and all five phases; source cross-check of actual scoring entities/services/repositories, V95 constraints, session guards and existing frontend submission hook. Source review only: no production edits, database inventory, build or tests executed.

## Verdict

**READY FOR IMPLEMENTATION.** R1 was accepted, incorporated into Phase3, and rechecked by this reviewer. No unresolved HIGH/BLOCKER findings. No further business clarification is required: Q1–Q4 are confirmed. This is a design review, not implementation acceptance or evidence of runtime correctness. Required tests remain outstanding.

## R1 — HIGH — Bulk finalization must not reuse its parent request UUID on every final-score row

**Disposition: ACCEPTED and addressed by root.** Reviewer verified the Phase3 child UUID/manifest/fingerprint/compatibility task and multi-answer test requirements. Reviewer has not edited production or phase files.

Evidence: `pte-api/app/src/main/resources/db/migration/V95__examiner_decision_contracts_and_receipts.sql:47–49` has a partial unique index on `(tenant_id, examiner_public_id, request_public_id)`. `ExaminerScoringService.submitScore` explicitly rejects cross-answer reuse at lines392–401. Modern `ExaminerAnswerScore` requires request UUID, fingerprint and expected review version. The pre-review Phase3 proposed extracting the final-score primitive and committing many immutable score rows without compatible row receipt identities; the reviewed amendment now explicitly defines them.

Scenario: two required answers are finalized together. Copying the aggregate command UUID into both modern rows violates V95 uniqueness; the transaction rolls back and cannot complete an ordinary multi-answer assignment. Removing the index or nulling modern metadata would instead compromise legacy receipt/immutability semantics.

Required amendment: parent request UUID belongs only to the aggregate command receipt. Use deterministic, versioned per-answer child UUIDs derived from parent UUID + answer UUID by one fixed algorithm, retain a parent-to-child manifest, and generate compatible child fingerprints from each captured score intent. Preserve existing final rows and their receipt metadata. Old per-answer API must remain blocked for atomic-mode assignments, including use of bulk child UUIDs. Do not change V95 or its uniqueness rule.

Required verification: finalize at least two missing answers; replay the same parent after completion/publication; change manifest with the same parent; overlap a legacy partial final; assert one aggregate receipt/event, distinct child identities, no duplicate score rows and rollback after a forced late failure.

## Implementation advisories (not additional blockers)

### R2 — MEDIUM — Revalidation applies to new drafts, not immutable historical decisions

The current `ExaminerReviewVersionService.computeReviewVersion` includes live AI version, cohort/member and publication context. When finalizing an attempt with legacy partial scores, do not demand a new AI/review version or draft for those already-finalized rows. Phase3 already requires preserving them; make the implementation/tests distinguish the immutable-final subset from the missing-draft subset. Recheck ownership/actual required pool, but never regrade an old final because AI subsequently changes. Test a partial legacy final with changed AI plus a valid remaining draft.

### R3 — MEDIUM — Missing work rows need explicit read semantics during additive rollout

Phase1 correctly requires real-data inventory/backfill and Phase2 correct queue predicates. Until backfill has completed, reads must derive missing-row legacy state from the real pinned eligible answer set without writing on GET, or refuse atomic enablement for those assignments. The present CTE treats zero eligible answers as Completed and filters every published assignment out (`ExaminerWorkspaceReadRepository:38–43,97`); both behaviors must be replaced consistently in active and fallback repositories. Never assume persisted `eligibleAnswerCount` alone proves exact all-final coverage. The existing planned zero-pool, partial/all-final and published fixtures cover this advisory when executed against actual SQL.

## Already adequately covered

- Atomic scope derives from immutable backend assignment; current model is one Examiner per whole attempt, with no unapproved partial/multi-rater expansion.
- Draft revisions and finalize manifest protect two-tab edits; save does not select EXAMINER or affect publication.
- Session mutex precedes work/draft and ordered answer locks; current `lockForScoreReviewMutation` is a lock-only primitive and does not itself reject publication/lifecycle before receipt lookup.
- Receipt read authorization precedes disclosure, while exact authorized replay precedes mutable lifecycle/AI/version checks.
- Published Completed/history use separate read-only projections; mutable detail guards stay intact.
- Host readiness and locked publication must check aggregate assignment completion; old per-answer bypass remains server-blocked.
- Immutable legacy scores/report snapshots, truthful timestamps, pinned guidelines, no invented rubric, no reopen, owner-scoped issue/history and safe rollback are explicit.
- Mandatory meaningful authorization/concurrency/migration/frontend checks are retained; Node Vitest versus DOM tooling is acknowledged.

## Handoff

Root can proceed to cook: R1 is recorded in the Phase3 implementation task and test requirements. Keep R2/R3 in implementation review notes and test cases; they do not require another user decision. Preserve attendance/navigation/lockfile work. Deployment/live migration/inventory remain environment-scoped actions, not consequences of this plan review.

