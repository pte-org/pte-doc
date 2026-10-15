# Phase 05: Final integration, regression verification, and handoff

**Status:** Verification complete; post-feedback locale fix verified; awaiting explicit final hard-mode checkpoint  
**Stories:** P1/P2 all in-scope stories; P3 boundary verification  
**Unit tests:** yes (default hard-mode testing; no TDD)  
**Quality gate:** yes (hard-mode default)  
**Dependencies:** Phases 01-04 implementation gates passed and locale handoff complete

## Goal / outcome

Prove the complete refinement in the local tenant-web app: seven-tab order, Questions
read-only preview, Overview lifecycle actions, clean header, no global loading flash,
retention/deep-link behavior, locale/theme/accessibility/responsive behavior, and safe
concurrent-agent boundaries.

## Exact files owned

### Create

- `tests/phase-05-integration-test-report.json`
- `quality/phase-05-integration-quality-report.json`
- `quality/phase-05-integration-receipt.json`
- Temporary browser smoke script outside the repository plan directory, if the selected
  Playwright workflow requires one; remove only that temporary artifact after use.

### Modify

- No planned production modification. A narrowly scoped fix is allowed only if a failed
  acceptance check identifies an issue in a Phase 02-04 owned file; record the reason,
  update the relevant phase evidence, and rerun all affected checks.

### Read-only

- All Phase 02-04 owned production files.
- `tests/phase-01-contract-check.ps1` and all Phase 01-04 evidence receipts.
- `pte-web/packages/ui/src/i18n/LocaleProvider.tsx` and all protected concurrent files.
- `pte-web/package.json`, `pte-web/pnpm-lock.yaml`, and tenant-web scripts/config needed
  to run the documented checks.
- Local API/backend only as a runtime dependency; no source changes.

## Implementation steps

1. Recompute the Phase 01 baseline/protected hashes and inspect `git status`; classify
   every protected-path delta as pre-existing, concurrent-agent, plan-introduced, or
   untriaged. Confirm this plan introduced no forbidden-path change and no unrelated
   worktree change was staged, reset, overwritten, or normalized.
2. Run `powershell -NoProfile -ExecutionPolicy Bypass -File tests/phase-01-contract-check.ps1 -Stage final`
   (or `pwsh` when installed) plus the phase
   receipts for exact tab order, header action absence, lifecycle guard parity, preview
   query enablement, answer-key field exclusion, and no new API/backend files.
3. Run `@pte/ui` and tenant-web typecheck/lint/build sequentially as required by the
   repository's resource constraints; run `git diff --check`.
4. Start/use the local tenant-web server and run browser smoke for:
   - Vietnamese default and English switch;
   - light/dark mode;
   - seven-tab order and keyboard Arrow/Home/End navigation;
   - `?tab=questions`, refresh, back/forward, and visited-tab retention;
   - Questions loading, successful-empty, error, and content states using controlled
     Playwright network interception/mock responses for the exact preview endpoint;
   - Questions no-snapshot state using a controlled session-detail response with
     `snapshotPublicId: null` (and an assertion that the preview endpoint is not called),
     because preview-endpoint interception alone cannot create that branch;
     do not skip a state merely because seeded data does not provide it;
   - answer-key absence and no question mutation controls;
   - Overview lifecycle actions/disabled state for available statuses;
   - header absence of View/Open/Close/Cancel/status duplicates;
   - modal reachability, submission/examiner/results/participant paths;
   - 390px layout with no document-level horizontal overflow.
5. Record browser console/network evidence, especially no full-page transition, no
   preview request when no snapshot exists, the exact intercepted state fixtures, and the
   absence of duplicate lifecycle errors/actions.
6. Run independent quality and code-review gates against the final diff. Fix only findings
   within this plan's owned files; rerun the full affected verification after each fix.
7. Produce the final test/quality reports and leave the master plan ready for explicit
   human checkpoint before marking the plan complete.

## Acceptance checks

- Exactly seven approved tabs and labels exist in both VI and EN, in the approved order.
- Header has no duplicate lifecycle status/actions and no standalone View Exam.
- Overview has one status/action area and lifecycle behavior matches the Phase 01 guards.
- Questions is grouped, read-only, answer-key-safe, lazy/retained, and uses local states.
- All existing workflows remain reachable and no global loading flash appears on tab switch.
- URL/deep-link, browser history, keyboard semantics, modal state, theme, locale, and
  responsive checks pass.
- Typecheck, lint, build, focused contracts, controlled browser smoke, diff check, quality
  review, and protected-hash audit all pass or are explicitly reported with a blocker.
  If a state cannot be exercised even with controlled interception, record that state as
  `unverified` with the concrete limitation; never convert it to a generic pass.
- No production changes are introduced outside the exact Phase 02-04 ownership lists and
  no forbidden repository (backend/API-client/vendor/protected locale/old plan) is
  modified by this plan. Pre-existing or concurrent protected changes are listed
  separately from plan-introduced changes.

## Design Constraints

- Verification must distinguish static proof from runtime browser proof; do not claim one
  based on the other.
- Runtime state coverage must use deterministic fixture/intercept cases for loading,
  successful-empty, error, content, and no-snapshot; local seed availability is not a
  reason to omit a required state.
- Do not weaken a failing check by deleting it or changing the acceptance criterion.
- Do not modify protected concurrent files to make the build pass.
- Do not add test-only production branching, fake answer-key data, or a new API endpoint.
- If local data cannot exercise a lifecycle state, report it as unverified rather than
  claiming runtime coverage.

## Quality and Testing State

- **Quality:** APPROVED; quality receipt is valid and final code review is APPROVED with
  no blocking findings. One pre-existing MEDIUM advisory and one pre-existing LOW
  observation remain explicitly out of scope.
- **Testing:** PASSED; static contracts, typecheck/lint/build, controlled browser state
  smoke, workflow reachability, console/network health, and responsive checks passed.
- **TDD:** not enabled; no new production unit test was required for this verification
  phase.

## Cook State

- **Phase:** 05 verification complete; awaiting explicit final human checkpoint
- **Unit tests:** yes (hard-mode default)
- **Quality gate:** yes (hard-mode default)
- **TDD:** not enabled
- **Current step:** explicit human checkpoint before closing the plan; post-feedback
  `Examiner` locale regression is verified

## Concurrent-agent safety

- Capture protected hashes before and after every verification run.
- Treat any concurrent change as user-owned. Do not reset, stash, checkout, overwrite, or
  reformat it.
- `LocaleProvider.tsx` remains read-only for this plan; final locale evidence must cite
  the external owner handoff if that file changed.
- Keep reports and receipts inside this plan directory only.

## Handoff state

Phase 05 hands off a complete evidence bundle and a clear status: verification passed,
quality approved, and awaiting the user's final checkpoint. The plan is not marked
complete merely because checks pass; the explicit hard-mode human confirmation is
required before the cook closes the plan.
