# Brainstorm: Programs / Classes / Learners — Destructive UX + Form/Import Hygiene

**Date**: 2026-10-02
**Slug**: `tenant-programs-classes-learners`

## Ideas Explored

Three angles were compared during brainstorm:

### A — Silent destructive actions
- **A1**: Add `ConfirmDialog` with counts (already a pattern for Program
  archive). Extend to Class archive + status changes + Unassign.
- **A2**: Generic `<DestructiveAction>` wrapper component. — Dismissed: too
  generic for 5 call sites.
- **A3**: Browser `confirm()`. — Dismissed: ugly, no counts.

### B — Form / validator hygiene
- **B1**: Local validator per modal (current pattern, e.g.
  `validateCreateProgram`, `validateCreateLecturer`). — **Chosen**: extract a
  shared `validateClassName` for Create/Edit/Split; loosen program date
  validator; add `validateAddStudentInput`.
- **B2**: Single root `useForm` hook. — Dismissed: rewrite too invasive for a
  survey-driven phase.

### C — Excel import edge cases
- **C1**: Surface skipped rows more. — Existing `SkippedRowsReport` already does
  this.
- **C2**: Surface className-override behavior. — **Chosen**: add a one-line
  help text. Backend routing left as question.
- **C3**: Pre-validate rows client-side. — Dismissed: parser already runs;
  rule-engine belongs in backend.

### D — UI dead states
- **D1**: Populate student count column. — Dismissed: requires N+1 dashboard
  calls.
- **D2**: Drop the always-"—" column. — **Chosen**.

## User's Direction

Per AskQuestion in this turn, scope is "**Critical + quick wins**" — fix the
high-severity destructive-silent-data-loss items (P7, C7, C8, C13, C14, C19) +
the form/import quick wins + the one obvious dead column.

User also chose:

- **Archive scope** = *all status-changing actions*, not only archive.
- **Target-status guard (C13/C14)** = *warn + typed-name confirm*, not block.
- **Date plumbing (P2/P4)** = *both-null allowed AND same-day allowed*.

## Open Questions (handed to /ck:plan → backend)

See `spec.md` §7 (Q1–Q5). These are blockers for AC7/AC9/AC4/AC5/L4.

## Risks

1. Adding `ConfirmDialog` around every status change may slow power-user
   cleanup flows.
2. Typed-name confirmation for transfer/merge to SUSPENDED classes adds 2
   clicks in a common pattern (mitigated: only for non-ACTIVE targets).
3. Friendly error messages for `409 DUPLICATE_CLASS_NAME` depend on backend
   error code contract (Q1).
4. Auto-clearing `endDate` (P5) was avoided in favor of inline error to avoid
   surprising the user.