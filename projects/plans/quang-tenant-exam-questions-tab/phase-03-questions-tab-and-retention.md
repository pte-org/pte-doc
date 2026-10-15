# Phase 03: Add the dedicated Questions tab

**Status:** Completed after hard-mode confirmation  
**Stories:** P1 Questions, P2 responsive seven-tab navigation  
**Unit tests:** yes (default hard-mode testing; no TDD)  
**Quality gate:** yes (hard-mode default)  
**Dependencies:** Phase 02 reusable preview surface

## Goal / outcome

Add a dedicated read-only Questions tab that loads the existing generated snapshot only
on first visit, shows local loading/empty/error/content states, retains its content after
navigation, and does not introduce page-level loading or horizontal overflow.

## Exact files owned

### Create

- `pte-web/apps/tenant-web/features/exams/components/ExamQuestionsTab.tsx`
  - Tab-level composition for snapshot availability, shared preview surface, accessible
    labels, and read-only Questions presentation.
- `tests/phase-03-questions-contract.json`
  - Evidence receipt for the target tab order, query gating, state branches, and
    instance-local report ownership.

### Modify

- `pte-web/apps/tenant-web/features/exams/components/ExamDetailTabs.tsx`
  - Add the `questions` ID, place it second, render `ExamQuestionsTab`, and include it in
    visited/retained panel behavior without changing existing participant modal wiring.

### Read-only

- `pte-web/apps/tenant-web/features/exams/components/ExamPreviewSurface.tsx`
- `pte-web/apps/tenant-web/features/exams/components/ExamPreviewContent.tsx`
- `tests/phase-01-contract-check.ps1`
- `pte-web/apps/tenant-web/features/exams/api/index.ts`
- `pte-web/apps/tenant-web/features/exams/types/index.ts`
- `pte-web/packages/ui/src/components/Tabs.tsx`
- `pte-web/packages/ui/src/components/LoadingState.tsx`
- `pte-web/packages/ui/src/i18n/LocaleProvider.tsx` (protected)
- Existing tab components under `features/exams/components` for prop/retention parity

### Never modify

- Query implementation/query keys, API client, backend, auth/role files, `/examiner/work`,
  vendor-web, protected locale provider, and old decomposition plan.

## Implementation steps

1. Add `questions` to the feature-local tab union and `TAB_IDS`; place it directly after
   `overview`. Keep invalid query values falling back to Overview.
2. Add the localized Questions tab label and accessible tablist label through the
   existing locale contract. Consume only keys confirmed by
   `tests/phase-01-locale-handoff.json`; if the handoff is blocked, stop rather than
   shipping a raw English label or editing the protected provider.
3. Render `ExamQuestionsTab` inside a `TabPanel` with `keepMounted` after first visit.
   Preserve the existing `visitedTabs` strategy and participant modal close-on-tab-change.
4. Pass `Boolean(session.snapshotPublicId)` as availability/enabled state. The tab must
   not call the preview query when the snapshot is absent.
5. Use the shared surface for local skeleton, successful-empty, error, unavailable, and
   grouped content states. Do not show a global `LoadingState` or route transition when
   selecting a tab. The successful-empty branch must be distinct from no snapshot and
   from a request error.
6. Keep the preview read-only. A report-ticket button may remain, but it must delegate
   to `ExamPreviewSurface`; the tab owns no report state, mutation, toast, or modal and
   no question mutation or answer-key metadata may be added.
7. Validate `?tab=questions`, direct entry, browser back/forward, keyboard Arrow/Home/End,
   tab focus, light/dark tokens, VI/EN labels after locale handoff, and 390px horizontal
   behavior.

## Acceptance checks

- The tab strip contains exactly seven IDs in the approved order.
- Direct `?tab=questions` opens Questions without a full page navigation; invalid tab
  values still resolve to Overview.
- Questions is lazy on first visit, retained after visit, and does not blank the global
  shell or refetch solely because the user returns to the tab.
- No preview request occurs when `snapshotPublicId` is null/empty.
- Loading, successful-empty, unavailable/no-snapshot, error, and content states are
  locally visible and accessible; empty is verified with a successful response whose
  `items` array is empty.
- Grouped snapshot content remains answer-key-free and source ordered.
- Questions delegates any Report Question affordance to `ExamPreviewSurface`; it owns no
  report state, mutation, toast, or modal. Cross-entry state sharing is intentionally not
  required: the modal and tab use the same surface implementation with instance-local
  state, and Phase 04 removes the legacy modal from the detail shell.
- Existing settings, participants, submissions, examiner, results, and modal actions remain
  reachable.
- Shared Tabs semantics and keyboard behavior remain intact; 390px has no document
  horizontal overflow.
- Focused static checks assert the seven-tab order, no-query-without-snapshot, the
  successful-empty branch, and locale-key usage. Browser smoke covers loading, empty,
  error, content, and no-snapshot using controlled responses/intercepts.
- The reusable Phase 01 contract-check script is run in `questions` mode and the
  `tests/phase-03-questions-contract.json` receipt records the result.
- Typecheck/lint and the controlled browser checks pass, or each unavailable state is
  recorded as `unverified` with the reason rather than being treated as pass.

## Design Constraints

- `ExamDetailTabs` owns navigation/retention composition; it must not become a second API
  or lifecycle owner.
- `ExamQuestionsTab` owns only Questions presentation wiring and may not create a new
  preview query or mutation.
- Use `min-w-0` for content and the existing shrink-0/overflow-x-auto Tabs behavior.
- Do not keep every panel mounted by default; retain only after first visit according to
  the existing strategy.
- Do not alter route semantics or convert query-state changes into Next full navigation.

## Quality and Testing State

- **Quality:** APPROVED. The independent gate found zero blocking or advisory findings;
  receipt: quality/phase-03-questions-tab-and-retention-receipt.json.
- **Testing:** PASSED. The Questions contract, invalid-tab history contract, tenant
  typecheck, scoped lint, production build, quality receipt verification, and code-review
  follow-up passed. Browser smoke was skipped because no authenticated tenant browser
  session/server intercept suite was available. Report: tests/phase-03-test-report.json.

## Cook State

- **Phase:** 03 completed
- **Unit tests:** yes (hard-mode default)
- **Quality gate:** yes (hard-mode default)
- **TDD:** not enabled
- **Current step:** handed off to Phase 04 after user checkpoint

## Concurrent-agent safety

- Verify protected hashes before changing `ExamDetailTabs.tsx`.
- Do not modify `LocaleProvider.tsx`; wait for/consume the locale-owner handoff.
- Do not start this phase while the Phase 01 locale handoff is blocked or while required
  Questions keys are absent.
- Do not touch existing tab components unless explicitly listed as read-only; preserve the
  other agent's vendor/package changes.

## Handoff state

Phase 03 hands off when a direct Questions URL and tab click both work, the local states
are visible, visited content is retained, and all six pre-existing panels still render
under the new order. Phase 04 may then relocate lifecycle presentation.
