# Phase 02: Extract the reusable answer-key-free preview surface

**Status:** Completed  
**Stories:** P1 Questions; P3 authoring/mutation boundary  
**Unit tests:** yes (default hard-mode testing; no TDD)  
**Quality gate:** yes (hard-mode default)  
**Dependencies:** Phase 01 baseline and locale/ownership gate passed

## Goal / outcome

Separate preview presentation from the existing modal so the same immutable snapshot
surface can render inside a future Questions tab without duplicating item rendering,
query semantics, answer-key safety, or Report Question support behavior.

## Exact files owned

### Create

- `pte-web/apps/tenant-web/features/exams/components/ExamPreviewContent.tsx`
  - Reusable answer-key-free content/presentation for metadata, grouped items, prompt,
    image, audio, options, order, and optional Report Question callback. It is a pure
    renderer: it does not own the preview query, report mutation, or report modal.
- `pte-web/apps/tenant-web/features/exams/components/ExamPreviewSurface.tsx`
  - Shared query/state composition for loading, empty, error, unavailable, and content
    states; owns report-selection/report-success state for every mounted preview surface,
    so the modal wrapper and Questions tab use one implementation instead of duplicating
    report logic, and reuses the existing preview hook and ReportQuestionModal mutation.

### Modify

- `pte-web/apps/tenant-web/features/exams/components/ExamPreviewModal.tsx`
  - Keep the modal wrapper and compatibility entry point; delegate preview body/state to
    the reusable surface and pass the session's `snapshotPublicId` availability through.
- `pte-web/apps/tenant-web/features/exams/components/SessionDetailView.tsx`
  - Make only the caller-side contract change needed by the compatibility modal:
    pass `snapshotPublicId={session.snapshotPublicId}`. Do not move lifecycle hooks or
    change header behavior in this phase; Phase 04 owns that composition change.
- `pte-web/apps/tenant-web/features/supportTickets/components/ReportQuestionModal.tsx`
  - Presentation-only locale wiring for the existing report mutation; do not alter its
    request, validation, success callback, or error behavior.

### Read-only

- `pte-web/apps/tenant-web/features/exams/api/index.ts`
- `pte-web/apps/tenant-web/features/exams/constants/index.ts`
- `pte-web/apps/tenant-web/features/exams/types/index.ts`
- `pte-web/apps/tenant-web/features/supportTickets/constants/index.ts`
- `pte-web/packages/api-client/src/types/scheduling/index.ts`
- `pte-web/packages/ui/src/components/Modal.tsx`
- `pte-web/packages/ui/src/components/LoadingState.tsx`
- `pte-web/packages/ui/src/i18n/LocaleProvider.tsx` (protected)

### Never modify

- `pte-api/**`, `pte-web/packages/api-client/**`, `LocaleProvider.tsx`, vendor-web, old
  decomposition plan, and any files outside the exact create/modify list.

## Implementation steps

1. Extract the current preview item rendering into `ExamPreviewContent` without changing
   the `ExamPreviewItem` field contract or semantic light/dark classes.
2. Group content by section and then task type while sorting/rendering each item by its
   existing `orderIndex`; do not mutate the source snapshot or invent a new DTO.
3. Keep prompt text, title, image, audio, options, word count, and report affordance
   behavior. Ensure `option.correct` or any answer-key field is never read/rendered.
   Give the report button an explicit localized `aria-label` and preserve a visible
   reported/disabled state.
4. Add `ExamPreviewSurface` as the shared query/state owner. Its contract includes
   `sessionPublicId`, `snapshotPublicId: string | null`, `enabled: boolean`, and an
   optional `showReportAction` flag. It passes a single `onReport(questionPublicId)` /
   `isReported(questionPublicId)` contract to `ExamPreviewContent`, owns
   `reportingQuestionId` and `reportedQuestionIds`, and renders one
   `ReportQuestionModal` plus the existing success toast. `ExamPreviewModal` and
   `ExamQuestionsTab` both consume this surface; neither creates a second report state,
   report mutation, or report modal. The plan deliberately does not require state sharing
   between two simultaneously mounted surface instances: each active surface instance
   owns local selection state through the same shared implementation. After Phase 04 the
   legacy modal is removed from the detail shell, so the tab is the sole generated-preview
   entry point.
5. Make the surface accept an explicit `enabled` flag and snapshot condition so no preview
   query runs without a `snapshotPublicId`.
6. Keep `useSessionExamPreview(publicId, enabled)`, its query key, stale time, and error
   formatter unchanged. Do not add a query or mutation.
7. Preserve Report Question as a support-ticket action only. Keep its existing success
   toast and mutation path; do not couple it to question editing or snapshot mutation.
8. Resolve all user-visible preview labels through the existing `useLocale().t` contract
   and the Phase 01 handoff keys. Do not render raw `EXAM_PREVIEW_TEXT` English labels
   in the new surface; use localized fallbacks only for keys confirmed by the handoff.
9. Update `ReportQuestionModal` to use the handed-off support keys for title, description,
   placeholder, cancel, submit, submitting, and success feedback while preserving its
   current mutation, validation, callbacks, and error behavior.
10. Update `ExamPreviewModal` to accept and pass `snapshotPublicId` to the surface and to
   remain the modal wrapper and compatibility entry point;
   it delegates title/body/state/report ownership to the shared surface and preserves
   modal size, close behavior, loading/error/unavailable/empty states, and existing
   callers.

## Acceptance checks

- Existing modal behavior is visually and functionally reachable with no new API call.
- Shared surface has distinct loading, successful-empty (`items.length === 0`), error,
  unavailable (`snapshotPublicId` absent), and content branches.
- Grouping is deterministic: section -> task type -> ascending `orderIndex`.
- No answer key, correctness, teacher score, edit, reorder, delete, or import control is
  present in rendered Questions-compatible content.
- `snapshotPublicId` absence produces an unavailable state and zero preview request.
- Report Question remains the only permitted interactive support action, if retained, and
  exactly one shared-surface implementation owns selection, success, toast, and modal
  wiring; neither entry wrapper duplicates it.
- The retained Report Question modal's user-visible labels use the handed-off VI/EN keys;
  no new raw English support labels are introduced, and its presentation uses existing
  semantic theme tokens rather than light-only gray/white text assumptions.
- The Questions content exposes semantic section/task grouping, a heading/title for the
  preview, an explicit accessible name for Report Question, and accessible labels for
  audio/media; no icon-only `title`-only control is accepted.
- Light/dark semantic tokens and VI/EN locale keys confirmed in Phase 01 are used; no
  white-only text or background assumptions are introduced.
- Typecheck/lint and focused preview contract checks pass.

## Design Constraints

- The extracted files are feature-level composition, not new generic `@pte/ui` primitives.
- Keep query ownership in the shared surface so modal and tab cannot drift in query keys or
  state handling.
- Keep Report Question selection/report-success ownership in the shared surface. The
  content component only receives callbacks; the modal wrapper and Questions tab never
  duplicate `reportingQuestionId`, reported-ID state, toast, or mutation wiring.
- Do not use `AnswerDetailModal`; it can expose correctness and teacher-score controls.
- Preserve source item identity and order; grouping is presentation-only.
- Any locale key missing from the protected provider must remain a coordination blocker,
  not be silently replaced by hard-coded English in a new namespace.
- Preflight: existing tenant preview code uses client components, `useSessionExamPreview`,
  `@pte/ui` `Alert`/`Badge`/`LoadingState`/`Modal`, semantic `var(--*)` tokens, and
  feature-local constants; the new surface must preserve those conventions while routing
  all new visible labels through `useLocale().t`.

## Quality and Testing State

- **Quality:** APPROVED. The independent gate found zero blocking or advisory findings;
  receipt: quality/phase-02-preview-surface-extraction-receipt.json.
- **Testing:** PASSED. The focused preview contract, tenant typecheck, scoped lint,
  production build, and quality-receipt verification passed. Browser smoke was skipped
  because no authenticated tenant browser session/server smoke was run in this extraction
  phase; no TDD tests were requested. Report: tests/phase-02-test-report.json.

## Cook State

- **Phase:** 02 active
- **Unit tests:** yes (hard-mode default)
- **Quality gate:** yes (hard-mode default)
- **TDD:** not enabled
- **Current step:** extract content/surface, preserve modal compatibility, localize report modal

## Concurrent-agent safety

- Recheck Phase 01 protected hashes before editing `ExamPreviewModal.tsx`.
- Do not touch `LocaleProvider.tsx`; consume only keys confirmed by the locale owner.
- Do not begin this phase if the Phase 01 locale handoff artifact is blocked or untriaged.
- Limit the diff to the two new preview files, the existing modal, its caller-side
  snapshot prop, and presentation-only report-modal locale wiring. Preserve unrelated
  worktree changes and do not format neighboring files globally.

## Handoff state

Phase 02 hands off when the modal delegates to a tested shared answer-key-free surface,
the preview contract remains unchanged, and Phase 03 can render the surface without
duplicating query or item logic.
