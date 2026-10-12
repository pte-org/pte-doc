# Examiner plan — red-team review

Date: 2026-10-11. Verdict: **WARN**, with the bounded edits below; no new product/lifecycle blocker found.
Read-only review of spec, both research reports, master and all five phases. Source checks included Examiner entity/controller/repository, session coordination, cohort scheduler/evaluator and actual test paths. No product changes, test execution, deployment or performance claim.

## Findings

1. **MEDIUM — Request identity can remain on the immutable score.** Initial Phase01/02 draft creates a separate receipt despite the selected minimal architecture. Existing `ExaminerAnswerScore` already supplies one creation-only decision per answer. Exact edit: store requestPublicId/fingerprint/expectedReviewVersion and reviewed AI metadata on that row; add partial unique `(tenant_id, examiner_public_id, request_public_id)` and a tenant/actor/request repository lookup. Replay lookup must detect cross-answer reuse; different intent conflicts. Cross-session uniqueness collisions must roll back the losing transaction before querying/reconciling from a supported outer boundary; never continue in a rollback-only transaction. Update master and all receipt wording consistently. Root has already requested this planner revision.

2. **MEDIUM — Research still proposes runtime legacy alignment.** Primary research's persistence section says Host freeze invokes alignment for legacy cohorts. Phase03 deliberately selects SQL-only migration/remediation, with no freeze-time repair. Exact edit: replace the research instruction with a note that it was superseded by Phase03: cohort-less legacy rows require explicit cohort creation followed by operator-reviewed versioned SQL; runtime reads/freeze/finalize/publication never invent or update immutable legacy metadata. Retain the fail-closed blocker until remediation. This is a documentation contradiction, not a request for another legacy workflow.

3. **LOW — Include teacher-score and read-projection regressions in the focused commands.** Phase02/03/05 change `ScoringReviewService` and `ScoringReviewReadQueryService`, but their test classes are absent from those command lists. Exact edit: add `ScoringReviewServiceTest` and `ScoringReviewReadQueryServiceTest` to the relevant optional focused command. Keep `ScoreSourceSelectionServiceTest`: fresh file inventory confirms it exists at `app/src/test/java/com/pte/scoring/internal/service/ScoreSourceSelectionServiceTest.java`. These remain planned checks, subject to the user's Examiner test choice.

4. **LOW — Do not re-ask approved decisions.** Master validation currently re-asks lifecycle and immutability already included in the approved v2 design. Exact edit: record them as approved design constraints and limit outstanding validation to check choices, legacy-data presence/remediation prerequisites and available smoke-check environment/release boundaries. The plan does not need another design approval cycle.

5. **MEDIUM — Publication has no existing expected-version protocol.** Root's additional finding is confirmed against `ReportPublishController` and `packages/api-client/src/requests/reporting/reports.ts`: preflight is POST, publish is a separate bodyless POST, and there is no expectedVersion payload. Exact edit: replace Phase05's "existing preview/version/finalize flow" with existing preflight followed by publish and locked authoritative server revalidation; refresh real conflicts/readiness. Apply the same clarification to spec FR09 and Phase03 version/preview wording. Keep cohort/source-selection preview versions distinct. Do not add a publication-version mutation protocol solely to match inaccurate plan wording.

## Verified architecture conclusions

- Actual `SessionLifecycleService.lockForScoreReviewMutation` locks tenant/session without requiring CLOSED, so it is usable by pending AI/assignment/Examiner operations. Publication and cohort freeze retain their additional CLOSED checks.
- Session-first coordination must cover AI success/failure, objective ingest, teacher writes, assignment confirmation, cohort freeze/reconcile, Examiner and publication. The proposed separate per-session proxied scheduler worker fixes the current multi-session transactional sweep and BEFORE_COMMIT lock graph.
- FROZEN MANUAL membership, not COMPLETED, gates new decisions; otherwise first-score completion becomes circular. Published access is checked before replay, preventing old requests from restoring Examiner access.
- Publication re-evaluates all frozen nonexcluded pinned coverage and matching assignment-owned EXAMINER score pointers under the mutex. This prevents both AI fallback and live-submitted inventory drift. AI_ONLY/objective old behavior outside the manual barrier is deliberately preserved.
- AI availability uses real provenance/range/status, and AI and review hashes exclude media URLs. Unknown client outcome retains exact intent; an equal score alone is not proof of the request's commit.
- Legacy SQL excludes published/AI_ONLY/excluded/ambiguous rows and does not fabricate viewed AI. Cohort-less leftovers are explicitly operational blockers, not silent conversion.

No SLA, load result, database concurrency success or browser verification is asserted. Phase01 must settle concrete DTO enum/field/error serialization before implementation consumes it; this is already an explicit deliverable and needs no additional scope gate.

## Root adjudication

F1–F5 ACCEPTED and edited in master/phase/spec/research files. Original WARN preserved as review history; no BLOCK was returned. Scope remains the approved five phases. Root also corrected AI placeholder category naming to actual STUB, not MOCK. Final artifact checks cover phase sections, links and real test filenames; no product verification has run.
