# Phase 05: Session reminders and full grading completion

Status: in progress. Priority: P1 only. Date: 2026-10-03.

## Scope and dependencies

Mapping: FR-09–12, FR-19–21; P1 session milestones.

Prerequisites: Phases 01–02; confirmed product decisions 2026-10-03. Phase owner is the implementer for the owning modules below; final quality review is independent. Do not advance past unmet schema/security/transaction prerequisites.

## Design Constraints

Mandatory common-first: inspect [inventory](common-reuse-inventory.md), reuse existing symbols, extend public contracts minimally, justify any new capability in the phase log. No duplicate common response, pagination, errors, security, transport or UI primitives. No cross-module internal repository imports. Existing email audit/listeners remain separate. All errors use module constants plus shared safe HTTP handling; 400 invalid input, 401 unauthenticated, 403 wrong role, 404 foreign/missing personal target, 409 lifecycle/version conflict.

Use transaction-scoped intent persistence, database-enforced idempotency and bounded recoverable work. Preserve user changes and existing business side effects. No new violation/submission/per-examiner completion notification; no automatic score publication or force submission. P2/P3 work is deferred.

## Implementation steps

1. Implement public session schedule query/revalidation contracts. Poll due OPEN sessions at <=60-second tick with configurable 15-minute threshold, opensAt <=now<closesAt. Session owner serializes schedule/state checks with row locking.
2. Deduplicate recipient/tenant/session/schedule identity/threshold. Before inserting reminder inbox, recheck current state/closing time under session-owned lock in the same delivery transaction. Suppress stale pending reminders on reschedule, cancellation, CLOSED, or elapsed closesAt. New schedule allows one new valid reminder; never auto-close/force-submit.
3. Proposed engineering mechanism: add authorized HOST_ADMIN cohort preview/finalize after CLOSED. Preview all SUBMITTED attempts/retries plus CREATED/IN_PROGRESS outstanding attempts. CLOSED/frozen completion is confirmed; the reasoned disposition mechanism is a planning design, not a separately approved exclusion policy. Close remains backward compatible. AttemptStatus has no abandoned enum; ProctorCommandService forceSubmit requires OPEN. No post-close force submit.
4. Finalization obligatorily includes EVERY submitted paper. Outstanding attempts require explicit reasoned audited exclusion from this grading cohort only, acknowledged by host; persist dispositions without mutating attempt status. Host cannot exclude submitted required papers. Unacknowledged outstanding work returns 409 with safe counts. Lock session and validate preview/version before atomically persisting membership, dispositions and marking mode/version.
5. Reuse existing session marking configuration. When manual assignment workflow is configured, examiner-required applies to the whole cohort's subjective eligible items, regardless of whether an individual paper has an assignment. A class subset allocation cannot allow other unassigned papers to pass via AI. If no explicit session mode exists, add a narrow versioned mode contract; do not create a broad grading-policy UI in this notification project.
6. Attempt/Assessment public coverage contracts expose immutable pinned expected item identities and canonical answers, not only existing answer/score rows. Evaluator owned by scoring checks nonempty frozen cohort/nonempty required work, every expected answer/input, valid objective scores, committed assignments and submitted valid examiner scores for required manual items.
7. AI comparison is optional unless explicitly configured as required. AI-only mode requires valid successful REAL/nonstub AI scoring. Failed/pending optional AI does not block submitted required examiner work; failed/pending required AI blocks. Only explicit UNSCORED items excluded; unresolved methods/templates block.
8. Persist incomplete-to-complete transition and notification intent atomically, unique tenant/session/cohort version. Event-driven wake-ups plus periodic reconciliation recover missed wake-ups. Reuse answer->scoring-state lock ordering; document whole lock acquisition chain and barrier tests against score writes/publication. No new state->answer inversion.
9. P1 rejects reopening finalized cohorts with 409; repeated finalize returns same membership/policy when unchanged. No silent policy reset. Any future reopening requires explicit invalidation/version/audit and separate agreed notice semantics.
10. Expose safe blocked counts/reasons to host session review. Notice completion does not select AI/examiner source, approve, publish, or imply ReportPublishService readiness.

## Concrete file targets and ownership

### Finalization versus assignment race (R5)

Assignment confirmation, mode selection and cohort finalization acquire the same session-owned serialization lock. Under that lock freeze policy/version; reject AI-only selection if manual workflow is already committed, and reject mode changes after finalization with centralized 409. Supplemental examiner assignments may fill frozen manual requirements but cannot remove/change them. Add PostgreSQL barrier tests for finalize-versus-assignment confirmation and concurrent mode changes; no assignment-presence inference.

session/SessionService.java and SessionLifecycleService.java; attempt/AttemptService.java, AttemptStatus.java and proctor ProctorCommandService.java as reviewed dependencies; assessment/AssessmentService.java; scoring public facade/internal evaluator and completion state; ScorePublicationLockService.java; notification reminder/transition listener.

File names for new types are proposed; confirm existing equivalents first. Migration numbering must be resolved from current repository, not guessed.

## Permissions, failures, concurrency and recovery

Bind principal/tenant on every personal operation. Sanitize display errors and logs; never include passwords, signed media, answers or provider secrets. Retry only committed logical work with original identity. Recover expired leases and missed evaluator wake-ups; do not retry invalid authorization/business transitions as delivery successes. Document lock ordering and transactional boundaries for this phase and test overlaps, not just sequential happy paths.

## Tests and acceptance evidence

40 papers/2 examiners: first 20 no notice, all 40 exactly one; subset allocation/unassigned blocks; missing pinned answer/input/objective score; AI stub/failed required result; optional AI failure with completed human work; zero papers; submitted retries; outstanding disposition and immutable status; stale finalize preview; concurrent last scores; reminder reschedule/cancel/restart boundary; no publication side effect.

## Exit criteria

Runnable post-CLOSED finalization without force submits; whole-cohort manual policy explicit; coverage not row-count-only; lock ordering and reconciliation verified; one completion transition per finalized version.

## Quality and Testing State

- Implementation: implemented in the session, notification, attempt, scoring, migration, configuration, and test targets above; hard-mode completion checkpoint is still pending.
- Common-first evidence: Phase 05 reuse decisions are recorded in [common-reuse-inventory.md](common-reuse-inventory.md), including the justification for the new grading-cohort and attempt-coverage contracts.
- TDD: RED_READY compile failure was recorded before production implementation. The prepared reminder and evaluator assertions remain intact; the evaluator byte hash was reconciled after a supplemental assignment-coverage case was extracted into a separate test class.
- Targeted unit/service tests: passed, 55 tests, 0 failures/errors. The exact command and supplemental test list are recorded in `tests/phase-05-session-reminders-grading-test-report.json`.
- Build gate: `mvnw -pl app -DskipTests compile` passed after the final source/configuration patches.
- PostgreSQL/browser/performance checks: PostgreSQL integration was not run because Docker Desktop was unavailable; browser and performance evidence are deferred to Phase 07.
- Full regression: the 1,043-test suite retained pre-existing out-of-scope assessment/attempt failures; Phase 05 targeted tests remained green. Details are recorded in the test report.
- Quality gate: Phase 05 report and receipt are produced separately; no hard-mode checkpoint has been claimed.
- Findings/fixes/reverification: stale pending reminder suppression, closed-session ordering, soft-deleted coverage filtering, and finalization re-evaluation were fixed and reverified by the targeted suite.
