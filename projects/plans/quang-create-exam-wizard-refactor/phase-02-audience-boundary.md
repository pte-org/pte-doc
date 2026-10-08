# Phase 02 — Audience query and selection boundary

**Status:** Completed after human checkpoint
**Unit tests:** yes (hard-mode default; deterministic fallback required because tenant-web has no test runner)
**Quality gate:** yes (hard-mode default)

**Depends on:** Phase 01 implementation, baseline, and test/quality artifacts

## Goal

Move audience query composition and source-selection behavior into one hook without changing server calls, query enablement, filtering, labels, search, or the form's single `sources` source of truth.

## Files owned by this phase

Create:

- `apps/tenant-web/features/exams/hooks/useCreateExamAudience.ts`
- Focused hook tests only when an existing test runner supports them.

Read-only dependencies:

- `apps/tenant-web/features/classes/api/index.ts`
- `apps/tenant-web/features/examoperations/api.ts`
- `apps/tenant-web/features/programs/api/index.ts`
- `apps/tenant-web/features/exams/types/index.ts`
- `apps/tenant-web/features/exams/constants/index.ts`
- `apps/tenant-web/features/exams/hooks/useCreateExamWizardForm.ts` from Phase 01

Do not edit vendor-web, packages/ui, API-client, or backend files.

## Implementation steps

Re-run the ownership checkpoint and protected-file hash comparison before writing.

1. Move subscription/plan, class, student, organization, and program query composition behind `useCreateExamAudience`.
2. Preserve `open`-controlled query enablement and organization-to-program dependency.
3. Keep ACTIVE filtering and current display-label fallback behavior.
4. Keep source type, search text, selected source, add, duplicate protection, remove, loading, and empty states in one boundary.
5. Return presentation-ready options and selected-source labels to Phase 03 without copying or independently owning `form.sources`.

The exact hook boundary is: `useCreateExamAudience({ open, sources,
onSourcesChange, onSourcesError })`. `sources` is read-only input from the form
hook; `onSourcesChange(nextSources)` is the only write path; transient source type,
search text, and selected source may be local to this hook. It must not maintain a
second `sources` store. Testing is mandatory: use focused hook tests when available,
otherwise record deterministic duplicate/add/remove/query-enable checks with exact
inputs, expected outputs, command and result.

## Acceptance checks

- Each existing query is invoked with the same arguments and enablement conditions.
- Switching source type clears only the transient source selection/search state as before.
- Duplicate `(sourceType, sourcePublicId)` entries are rejected with the existing error.
- Adding/removing sources updates the form hook's single `sources` value.
- Audience hook contains no JSX and no mutation/API contract changes.

## Design Constraints

- Do not introduce a second audience state store.
- Do not move business validation into the audience hook; it reports selection errors through the existing form error boundary.
- Do not modify API modules or cache keys.
- Keep locale mapping at the UI boundary; domain source types remain enum values.

## Quality and Testing State

- Quality: APPROVED. Report: `quality/phase-02-audience-boundary-quality-report.json`. Receipt: `quality/phase-02-audience-boundary-receipt.json` (pending refresh after this status update).
- Testing: PASSED. Report: `tests/phase-02-test-report.json`. Deterministic fallback artifact: `tests/phase-02-audience-contract-fallback.json`.
- Required before phase completion: explicit human checkpoint after the hard-mode quality/testing gates.
- Gate: `ck:quality --gate` must report no BLOCKER/HIGH/current-change MEDIUM findings.
