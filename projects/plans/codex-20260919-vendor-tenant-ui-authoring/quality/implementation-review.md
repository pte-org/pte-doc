# Implementation review

**Date:** 2026-09-19  
**Review scope:** Session changes in `pte-api`, `pte-web`, and this plan record

## Review checklist

- [x] Shared `CollapsibleSection` is exported through `@pte/ui`.
- [x] Existing statistics values remain API/query driven; the collapse control
  only changes presentation state.
- [x] Toggle state is local to each section, so one screen's section does not
  affect another screen.
- [x] Toggle semantics are exposed through `aria-expanded` and
  `aria-controls`.
- [x] All current `StatCard` usages in the web workspace are wrapped by a
  collapsible statistics section.
- [x] The question-type delete path is soft-delete based, preserving existing
  question references.
- [x] Active/retired score templates remain protected from draft-only delete
  and edit operations.
- [x] Existing unrelated working-tree changes were preserved.

## Findings

No blocking implementation issue was found during the final review.

Non-blocking notes:

1. Vendor lint retains one existing `no-img-element` warning in
   `QuestionEditorForm.tsx`.
2. The Program detail collapse interaction could not be clicked live because
   the local `host@test` environment had no seeded program. The code compiled,
   typechecked, and the component is covered by the same shared implementation.
3. Git reports LF-to-CRLF normalization warnings on existing Windows working
   copies; `git diff --check` reported no whitespace errors.
