# Phase 05 — Host workflow, coordinated delivery and integrated verification

Status: not started. Dependencies: Phases01–04.
Stories: P1 Host publication and end-to-end AI-assisted Examiner authority.
Requirements: FR08–10,14,16; final evidence against all P1 success criteria.

## Inputs and output paths

Web paths relative to pte-web:

- `apps/tenant-web/features/exams/components/{GradingCohortSection,HostScoreReviewPanel}.tsx` and feature-local split components if limits require.
- `apps/tenant-web/features/exams/api/{gradingCohort,index}.ts`, existing Host review/readiness hooks discovered before edits.
- Relevant shared client scoring/reporting request/type files and locale `packages/ui/src/i18n/LocaleProvider.tsx`.
- Docs `pte-doc/plans/examiner-tenant-workspace/{delivery-notes,verification-results}.md` created only as actual work/evidence accrues.
- Backend readiness/Host capability from Phase03; no new UI-only policy authority.

## Design Constraints

- Host freezes CLOSED cohort before Examiner finalization. FROZEN does not require all decisions complete; display pending work accurately.
- In MANUAL_EXAMINER, AI reference and final human source are read-only; no AI/teacher/bulk controls that backend rejects.
- AI_ONLY retains current review/selection UX. Missing policy is setup-required, not implicitly MANUAL or AI_ONLY.
- Host never finalizes on Examiner's behalf or publishes from optimistic frontend progress.
- No new flags, environment activation, deployment, external messages or automatic data remediation beyond authorized scope.

## Implementation steps

1. Read authoritative mode/capability/blocker fields from existing/additive APIs; wire shared types and hooks without guessing from assignment presence.
2. GradingCohortSection explains close→preview/dispose outstanding attempts→freeze MANUAL→assign/review→publish. Keep existing disposition choices explicit; never auto-exclude to bypass missing work.
3. Link setup-required Examiner work to appropriate Host operations without leaking Host actions into Examiner role. Avoid promising AI is automatic: current scoring is Host-triggered, manual review can proceed without available AI.
4. HostScoreReviewPanel shows AI versus human score and actual final source. Manual policy hides/locks source-selection/teacher controls with clear explanation; AI_ONLY uses existing capabilities.
5. Display actual unresolved assignment/decision/pinned coverage blockers/counts from readiness; don't derive global readiness from a paginated queue or historical COMPLETED.
6. Publication calls existing POST preflight then bodyless POST publish; server revalidates the full manual barrier under the mutex. Refresh real conflicts/readiness; no expectedVersion publish payload is currently implemented. A disabled button supplements service guards; it is not protection.
7. Co-release API/schema plus updated shared client/Examiner/Host UI. Document old manual-write explicit rejection and keep old clients from submitting until updated; no assumed environment switch.
8. Run legacy diagnostics before enabling manual writes, retain bounded counts and remediation blockers. Published/AI_ONLY rows and snapshots are excluded; unresolved pre-cohort/orphan/excluded cases require approved follow-up SQL, not runtime repair.
9. Document forward recovery/rollback constraints: immutable decisions cannot be rolled back by deleting audit or selecting AI. Stop incompatible manual writes during recovery; deployment itself remains separately authorized.
10. Collect actual verification evidence against spec checklist and lock matrix, distinguishing compile/lint, tests, database scenarios and browser checks. Mark any skipped/unavailable check explicitly.
11. Update master/phase state with actual user check choices and outcomes, touched paths, remaining blockers and release status. No success claim for unrun checks.

## Planned verification commands

From pte-api: `.\mvnw.cmd -pl app -am -DskipTests compile`.
If selected: `.\mvnw.cmd -pl app -am '-Dtest=ExaminerScoringServiceTest,GradingCohortServiceTest,GradingCompletionEvaluatorTest,GradingCompletionEvaluatorAssignmentCoverageTest,ScoreSourceSelectionServiceTest,ScoringReviewServiceTest,ScoringReviewReadQueryServiceTest,AiScoringResultPersistenceServiceTest,ReportPublishServiceTest' -Dsurefire.failIfNoSpecifiedTests=false test`.
From pte-web: `pnpm --filter @pte/api-client typecheck`; `pnpm --filter tenant-web exec tsc --noEmit`; `pnpm --filter tenant-web lint`; `pnpm --filter tenant-web build`.
If selected: `pnpm --filter @pte/api-client test`; `pnpm --filter tenant-web test`.
Broaden or rerun only for new changes/failures/unresolved concerns, not repetition after satisfactory evidence.

## Integrated acceptance scenarios

- Host freeze MANUAL→assigned Examiner uses AI→confirms→final source EXAMINER→Host publishes exact score.
- Examiner corrects AI→stored viewed snapshot unchanged→Host cannot override→report uses corrected human score.
- AI pending/fails→manual human decision succeeds when content valid→late AI cannot replace it.
- One missing decision/assignment/pinned answer/objective manual coverage blocks direct publish despite AI readiness.
- AI_ONLY current flow remains available; previously published report snapshots unchanged.
- Unknown request outcome and changed actor/AI reference do not cause duplicate/different intent or false success.
- PostgreSQL concurrent writer/reconcile/publication and bounded migration scenarios verified separately from frontend/mock unit checks if selected.

## Quality and Testing State

- Quality: not evaluated; user choice pending.
- Testing: not started; user choice pending; no --tdd selected.
- End-to-end, migration and concurrency checks are proposed; none reported as run at planning stage.
- Deployment/activation: not performed; no environment selected or flag inferred.
