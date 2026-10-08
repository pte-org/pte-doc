# Phase 01: Baseline, ownership, and contract lock

**Status:** Completed  
**Stories:** P1 Questions, P1 Overview actions, P2 responsive tabs, P3 out-of-scope boundary  
**Unit tests:** yes (default hard-mode testing; no TDD)  
**Quality gate:** yes (hard-mode default)  
**Dependencies:** Approved `spec.md`; no production implementation dependency

## Goal / outcome

Create an evidence-backed baseline for the existing six-tab Exam detail, lock the seven-
tab and lifecycle contracts, and establish safe ownership boundaries before any source
write. Resolve locale coordination as a gate, not by editing the protected provider.

## Exact files owned

### Create or modify

- No production source files are created or modified.
- Create only phase evidence under this plan directory:
  - `tests/phase-01-baseline.json`
  - `tests/phase-01-contract-check.json`
  - `tests/phase-01-contract-check.ps1`
  - `tests/phase-01-locale-handoff.json`
  - `tests/phase-01-test-report.json`
  - `quality/phase-01-baseline-ownership-and-contract-quality-report.json`
  - `quality/phase-01-baseline-ownership-and-contract-receipt.json`

### Read-only

- `pte-web/apps/tenant-web/features/exams/components/ExamDetailTabs.tsx`
- `pte-web/apps/tenant-web/features/exams/components/SessionDetailView.tsx`
- `pte-web/apps/tenant-web/features/exams/components/ExamPreviewModal.tsx`
- `pte-web/apps/tenant-web/features/exams/components/ExamOverviewTab.tsx`
- `pte-web/apps/tenant-web/features/exams/api/index.ts`
- `pte-web/apps/tenant-web/features/exams/constants/index.ts`
- `pte-web/apps/tenant-web/features/exams/types/index.ts`
- `pte-web/packages/ui/src/components/Tabs.tsx`
- `pte-web/packages/ui/src/components/LoadingState.tsx`
- `pte-web/packages/ui/src/i18n/LocaleProvider.tsx` (protected concurrent-agent file)
- `pte-web/packages/api-client/src/types/scheduling/index.ts`
- `pte-web/packages/api-client/src/requests/scheduling/sessions.ts`
- `pte-api/app/src/main/java/com/pte/session/internal/service/SessionExamPreviewService.java`
- `pte-api/app/src/main/java/com/pte/session/internal/dto/response/ExamPreviewResponse.java`
- `pte-api/app/src/main/java/com/pte/session/internal/controller/SessionController.java`
- `pte-api/app/src/main/java/com/pte/session/internal/service/SessionLifecycleService.java`
- `pte-api/app/src/main/java/com/pte/session/internal/service/ExamOrchestrationService.java`
- `pte-api/app/src/main/java/com/pte/session/domain/ExamSession.java`
- `pte-web/apps/tenant-web/features/exams/components/AnswerDetailModal.tsx`
- `pte-doc/projects/plans/quang-tenant-exam-ui-decomposition/plan.md` (historical context only)

### Protected / never owned by this plan

- `pte-web/apps/vendor-web/**`
- `pte-web/packages/ui/src/hooks/**`
- `pte-web/packages/ui/src/i18n/LocaleProvider.tsx` while its concurrent agent is active
- `pte-api/**` and `pte-web/packages/api-client/**` except read-only inspection above
- The existing decomposition plan directory

## Implementation steps

1. Record baseline hashes and worktree status for all files that later phases may own.
2. Record protected concurrent-agent hashes, including `LocaleProvider.tsx`, and define
   the rule that a changed protected hash is not overwritten or normalized by this plan.
3. Record the observed baseline separately from the target: the current source has six
   tabs (`overview`, `settings`, `participants`, `submissions`, `examiner`, `results`),
   while the target contract has seven tabs with `questions` second. Phase 01 must not
   report the target as already implemented.
4. Verify current tab URL parsing, `pushState`, `visitedTabs`, `TabPanel` retention,
   and keyboard/horizontal behavior as baseline evidence; store the seven-tab target
   order only as a future contract for Phase 03.
5. Verify current lifecycle guards, mutation hook ownership, confirmation text, pending
   state, invalidation, error path, and authorization evidence. Confirm from the listed
   backend sources that the controller is `HOST_ADMIN`, lookup is tenant-scoped, and
   Open/Close/Cancel guards match the target contract.
6. Verify the preview response is immutable/answer-key-free and document the fields used
   for section/task/order grouping.
7. Create `tests/phase-01-locale-handoff.json` with the locale owner/agent, handoff
   status, observed-before and observed-after hashes, handoff timestamp, and permission
   to consume the keys. The required key set is:
   `tenant.examTabs.questions`, `tenant.examQuestions.title`,
   `tenant.examQuestions.answerKeyNotice`, `tenant.examQuestions.itemCount`,
   `tenant.examQuestions.options`, `tenant.examQuestions.audio`,
   `tenant.examQuestions.wordCount`, `tenant.examQuestions.imageAlt`,
   `tenant.examQuestions.report`, `tenant.examQuestions.reported`,
   `tenant.examQuestions.unavailable`, `tenant.examQuestions.empty`,
   `tenant.examQuestions.error`, `tenant.examOverview.back`,
   `tenant.examOverview.status`, `tenant.examOverview.open`,
   `tenant.examOverview.close`, `tenant.examOverview.cancel`,
   `tenant.examOverview.closeConfirm`, `tenant.examOverview.cancelConfirm`,
   `tenant.examOverview.lifecycleError`, the exact status-label keys
   `tenant.examStatus.draft`, `tenant.examStatus.preparing`,
   `tenant.examStatus.ready`, `tenant.examStatus.scheduled`, `tenant.examStatus.open`,
   `tenant.examStatus.closed`, `tenant.examStatus.cancelled`, and the retained support
   labels `tenant.support.reportQuestion.title`,
   `tenant.support.reportQuestion.cancel`,
   `tenant.support.reportQuestion.submit`,
   `tenant.support.reportQuestion.submitting`,
   `tenant.support.reportQuestion.description`,
   `tenant.support.reportQuestion.placeholder`, and
   `tenant.support.reportQuestion.successToast`.
   The artifact must say `keys-already-available` or record an explicit owner handoff;
   otherwise Phase 01 stops before Phase 02 writes. This plan never edits the provider.
8. Write `tests/phase-01-contract-check.ps1` with explicit `baseline`, `questions`, and
   `final` modes. Baseline mode asserts the observed six-tab source; questions mode is
   rerun after Phase 03 and asserts the seven-tab order, no-query-without-snapshot,
   answer-key-safe renderer, and Questions state branches; final mode is rerun after
   Phase 04 and additionally asserts the single lifecycle-error surface. The script must
   fail if the baseline/implementation-stage distinction, protected ownership assumptions,
   authorization evidence,
   or locale handoff state is missing. Run it from the plan directory as
   `powershell -NoProfile -ExecutionPolicy Bypass -File tests/phase-01-contract-check.ps1 -Stage baseline`
   (or `pwsh` when installed) in this phase; later phases rerun the same file with
   `-Stage questions` or `-Stage final`.

## Acceptance checks

- Baseline evidence names every later-owned source file and every protected path.
- Contract check confirms current query key/hook and lifecycle hooks; it does not modify
  them.
- Contract check lists both the observed six-tab baseline and the exact seven-tab target
  order with the required `questions` URL ID; it does not claim the target is implemented.
- Answer-key safety evidence confirms `ExamPreviewResponse` has no correctness field and
  `AnswerDetailModal` is not an allowed Questions renderer.
- Locale coordination is explicitly recorded with owner, key list, hashes, timestamp, and
  handoff permission; no production locale file is modified.
- Authorization evidence covers `SessionController`, `SessionLifecycleService`,
  `ExamOrchestrationService`, and `ExamSession`, including HOST_ADMIN, tenant scope, and
  lifecycle status guards.
- No production source, API client, backend, vendor, or old-plan file is changed.
- Test and quality artifacts exist, but status remains phase-gate evidence only until the
  cook run evaluates them.
- The contract-check script has a documented execution mode and is reusable by later
  phases; no ad-hoc unowned static assertion is accepted.

## Design Constraints

- This phase is audit/contract work, not an implementation phase.
- Do not “fix” current six-tab behavior here; later phases own source changes.
- Do not infer a locale fallback as completion if the locale contract lacks required keys.
- Do not start Phase 02 or later until `phase-01-locale-handoff.json` records available
  keys or an explicit owner handoff. New UI must consume the existing `useLocale().t`
  contract rather than importing raw English preview/status constants.
- Hashes are evidence, not permission to overwrite a concurrent file.
- The old decomposition plan is historical input only and must remain byte-for-byte
  untouched.
- Preflight: tenant Exam detail uses feature-local composition with `@pte/ui` Tabs,
  TabPanel, LoadingState, DashboardCard, Badge, and `useLocale().t`; tab URL state is
  client-side `pushState`, and existing lifecycle mutations stay in the detail shell.

## Quality and Testing State

- **Quality:** not evaluated at plan creation. Hard-mode cook must run an independent
  ownership/architecture review.
- **Testing:** not started at plan creation. Default testing should run static contract
  assertions and worktree/hash checks; no TDD tests are requested.

## Cook State

- **Phase:** 01 active
- **Unit tests:** yes (hard-mode default)
- **Quality gate:** yes (hard-mode default)
- **TDD:** not enabled
- **Current step:** baseline audit, contract script, and locale handoff evidence

## Cook Result

- **Contract:** passed (`powershell -NoProfile -ExecutionPolicy Bypass -File tests/phase-01-contract-check.ps1 -Stage baseline`)
- **Testing:** passed (`ck:test --unit` equivalent audit; 4 passed, 0 failed)
- **Quality:** approved; receipt verified at
  `quality/phase-01-baseline-ownership-and-contract-receipt.json`
- **Handoff:** passed. LocaleProvider has 35 available required keys,
  `permissionToConsumeKeys=true`, status `owner-handoff-confirmed`, and the recorded
  current hash matches.
- **Next action:** Phase 02 is active after explicit human confirmation. The plan still
  preserves all concurrent-agent drift classifications.

## Concurrent-agent safety

- Before and after the phase, recheck protected hashes and `git status`. A protected hash
  already changed at baseline is recorded as pre-existing; an after-phase difference is
  classified as plan-introduced, concurrent, or untriaged rather than treated as a clean
  worktree failure.
- Do not edit `LocaleProvider.tsx`; obtain a written/recorded handoff from its owner
  before any later phase depends on new keys.
- If a protected file changes externally, preserve it and update only plan evidence after
  inspecting the new contract.

## Handoff state

Phase 01 hands off only when baseline artifacts are recorded, locale ownership is clear,
and the source ownership ledger allows Phase 02 to write only preview files. If locale
coordination is unresolved, handoff is blocked and no implementation phase starts.
