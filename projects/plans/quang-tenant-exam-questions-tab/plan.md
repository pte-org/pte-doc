# Plan: Tenant Exam Questions tab and Overview lifecycle actions

**Spec:** [spec.md](spec.md)  
**Mode:** Hard  
**Test:** default (TDD not enabled)  
**Scope:** `pte-web` tenant Exam detail presentation only  
**Status:** Phase 05 verification complete; post-feedback locale fix verified; awaiting explicit final hard-mode checkpoint

## Scope challenge

- **Exists?** Yes. The tenant Exam detail route, six-tab composition, lifecycle hooks,
  preview modal, shared Tabs/TabPanel, loading state, and locale contract already exist.
- **Minimum:** Add one Questions tab, move existing lifecycle/status presentation into
  Overview, and extract only the preview presentation needed to share the immutable
  snapshot surface. Reuse every existing query, mutation, API contract, and role guard.
- **Complexity:** Hard. The change crosses tab state, lazy/retained panels, an existing
  preview modal, lifecycle action ownership, locale/theme/responsive behavior, and a
  protected concurrent-agent file.
- **Historical-plan boundary:** This is a follow-up plan. Do not edit or reinterpret
  `quang-tenant-exam-ui-decomposition/`; that older plan remains the historical six-tab
  decomposition and is already in progress.

## Goals

1. Expose exactly seven detail tabs in the approved order:
   `Overview -> Questions -> Exam settings -> Participants & proctors -> Submissions ->
   Examiner -> Results & publication`.
2. Make Overview the single surface for status, schedule/capacity context, and valid
   Open/Close/Cancel actions.
3. Make Questions a read-only, answer-key-safe snapshot preview grouped by section,
   task type, and question order.
4. Keep the header focused on identity/back navigation, with optional compact overflow;
   remove the duplicated lifecycle rail and standalone View Exam action.
5. Preserve local loading, visited-tab retention, URL tab state, modal reachability,
   light/dark tokens, Vietnamese default, English switch, keyboard access, and 390px
   behavior.

## Non-negotiable invariants

1. `SessionDetailView` remains the owner of `useOpenSession`, `useCloseSession`, and
   `useCancelSession`, their confirmation behavior, pending state, error handling, and
   invalidation.
2. `useSessionExamPreview`, `EXAM_PREVIEW_QUERY_KEY`,
   `GET /api/v1/sessions/{publicId}/exam-preview`, and the API-client/backend contracts
   remain unchanged.
3. Questions never edit, reorder, delete, import, score, or expose answer keys. The
   existing Report Question path may remain only as a support-ticket action.
4. Host detail remains separate from `/examiner/work`; no Examiner role boundary is
   widened and no scoring behavior is moved.
5. Existing routes, authentication, authorization, session status guards, submission,
   examiner, result/publication, and participant workflows remain reachable.
6. Reuse `@pte/ui` Tabs, TabPanel, LoadingState, Modal, semantic theme tokens, and the
   existing locale contract. Add a shared primitive only if a concrete gap is proven.
7. `packages/ui/src/i18n/LocaleProvider.tsx` and other concurrent-agent files are
   protected. This plan never edits them while another agent owns them; locale-key
   coordination and handoff are explicit gates. The required key list, owner, hash
   evidence, handoff time, and permission to consume the keys are recorded in the
   Phase 01 locale-handoff artifact. Phases 02-04 cannot start until that artifact
   says `keys-already-available` or records an explicit owner handoff.
8. No changes are made to `pte-api`, `packages/api-client`, vendor-web, the old
   decomposition plan, or unrelated worktree changes.

## Phase map

| Phase | Outcome | Primary owned area |
|---|---|---|
| 01 | Baseline, ownership ledger, locale handoff, and contract lock | Read-only audit and plan artifacts |
| 02 | Reusable answer-key-free preview surface with modal compatibility | `features/exams/components` preview files |
| 03 | Lazy retained Questions tab with grouped snapshot states | `features/exams/components/ExamQuestionsTab.tsx`, tab integration |
| 04 | Overview-owned lifecycle presentation and clean header | `SessionDetailView.tsx`, `ExamDetailTabs.tsx`, `ExamOverviewTab.tsx` |
| 05 | Full seven-tab integration, browser verification, and handoff | Verification only plus narrowly scoped fixes |

## Dependency graph

```text
P01 baseline/ownership/locale gate
  |
  v
P02 preview content + reusable surface
  |
  v
P03 Questions tab + lazy/retained integration
  |
  v
P04 Overview lifecycle relocation + header cleanup
  |
  v
P05 end-to-end integration and verification
```

Phase 04 may consume the Questions tab from Phase 03. Phase 05 is the only phase that
may make small integration corrections across already-owned files; it must not broaden
the feature or touch protected concurrent files.

## Cross-phase acceptance gates

- Exactly seven tab IDs exist and are ordered as specified; `?tab=questions` is handled
  through client-side history without a full route navigation.
- Header has no standalone View Exam action, no status badge duplicate, and no lifecycle
  action duplicate.
- Overview has one state-aware lifecycle area and keeps existing guards:
  `SCHEDULED -> Open`, `OPEN -> Close`, and `DRAFT/PREPARING/READY/SCHEDULED -> Cancel`.
- Questions never calls preview when `snapshotPublicId` is absent; it provides local
  loading, empty, error, and content states when appropriate.
- Snapshot items retain their source order and are grouped by section/task type without
  correctness metadata.
- Switching all tabs keeps the shell mounted, avoids a global loading flash, retains
  visited content, and preserves existing modal entry points.
- VI is the default locale; EN switch, light/dark mode, keyboard tab navigation, and
  390px no-page-overflow checks pass. This claim is valid only after the Phase 01
  locale handoff confirms every new Questions/lifecycle label key; a hard-coded
  English fallback is not evidence of Vietnamese support.
- No backend/API-client/authentication/role-boundary files change. Protected-file
  acceptance is measured against the Phase 01 baseline: pre-existing or later
  concurrent-agent changes are reported separately and are never overwritten by this
  plan.

## Hard-mode quality and testing policy

- Every phase records quality and testing state in its phase file. At plan time both are
  `not evaluated` / `not started`; `ck:cook --hard` must ask for the phase test and
  quality choices before implementation.
- Default testing is enabled, but no TDD workflow is requested. Use existing static
  checks, typecheck/lint/build, focused contract assertions, and browser smoke where the
  phase requires behavior.
- Quality review must inspect abstraction ownership, query/mutation preservation,
  answer-key safety, locale/theme safety, responsive behavior, and concurrent-agent
  boundaries. A passing build alone is not a quality approval.
- Before any completion claim, run the repository's relevant checks, read the output,
  run `git diff --check`, verify protected-file hashes, and perform the code-review gate.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| LocaleProvider is concurrently modified | Treat it as protected read-only; coordinate key ownership and consume only after handoff/hash confirmation. |
| Preview content is duplicated between modal and tab | Extract one reusable preview surface/content path; keep modal as a wrapper/compatibility entry point. |
| Preview accidentally exposes correctness | Use only `ExamPreviewResponse`/`ExamPreviewItem` fields already returned by the answer-key-free endpoint; never reuse `AnswerDetailModal`. |
| Questions query runs too early | Enable only after the Questions surface is visited and only when `snapshotPublicId` exists. |
| Tab switching resets filters/modals or causes flash | Preserve `visitedTabs`, use `TabPanel keepMounted`, and retain current client-side `pushState` behavior. |
| Lifecycle behavior changes while moving buttons | Keep hooks and status guards in `SessionDetailView`; pass a view-model/callbacks to Overview. |
| Seven tabs overflow on mobile | Reuse shared horizontal Tabs behavior, keep tab buttons shrink-0, and constrain content with min-w-0. |
| Existing agent work is overwritten | Establish Phase 01 hashes/ownership and recheck protected paths before every write phase. |

## Out of scope

- Any question authoring or question-bank mutation from tenant detail.
- Snapshot generation, answer-key rules, scoring, analytics, audit APIs, or result logic.
- Backend/API-client/authentication/route changes.
- Moving Examiner blind marking from `/examiner/work`.
- Editing the old decomposition plan or any vendor/package concurrent-agent file.

## Plan handoff

Before cooking, confirm:

1. The current concurrent agent has either added the required locale keys or explicitly
   handed off the protected locale file for this feature. The handoff must be recorded
   in `tests/phase-01-locale-handoff.json`; otherwise Phase 01 stops at its coordination
   gate and no implementation phase starts.
2. The local seeded Host Exam/session is available for browser smoke, including a case
   with and without `snapshotPublicId` if possible.
3. The operator accepts the five-phase order and default non-TDD testing policy.

## Ready to cook

```text
/ck:cook --hard pte-doc/projects/plans/quang-tenant-exam-questions-tab/plan.md
```
