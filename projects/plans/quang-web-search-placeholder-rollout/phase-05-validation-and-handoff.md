# Phase 05 — Validation, Edge Cases, and Handoff

## Goal

Verify every audited search surface in the real browser and close the plan with evidence that copy, behavior, pagination, and responsive layout agree.

## Scope

- Question Bank field/copy mismatch.
- Unused tenant filter component and dead table definitions.
- All enabled and intentionally hidden search surfaces.
- Tenant and admin route smoke checks.
- Regression checks for existing student-detail worktree changes.

## Implementation steps

1. Run static inventory and confirm zero audited enabled tables use the generic fallback.
2. Test each search family with a known match, partial match, whitespace input, no result, clear action, and page transition.
3. Probe representative authenticated routes at 375, 768, 1024, 1280, and desktop widths.
4. Check that long placeholders do not create horizontal overflow or obscure clear/search affordances.
5. Run tenant/vendor lint, typecheck, tests, relevant API-client tests, and build checks.
6. Run `git diff --check` and confirm only intended plan/source files changed.
7. Record any endpoint that remains intentionally without search and why.

## Definition of done

- No misleading generic placeholder remains in the audited business tables.
- No paginated table presents a local-only search as if it were global.
- Search visibility is intentional for every table.
- Browser verification covers desktop and 375px behavior.
- All quality/test outputs are recorded with limitations.

## Design Constraints

- Use the project’s existing probe/browser tooling; do not add Playwright to the product dependencies solely for this task.
- Do not change data fixtures or production records while testing.
- Preserve unrelated worktree changes and do not commit/push unless separately requested.

## Quality and Testing State

- **Quality:** approved with two noted limitations — the final inventory is clean for all visible surfaces, route smoke returned HTTP 200 for representative tenant/admin routes, and the manifest records the legacy/dead definition and license safety boundary. The full pte-api run still reports unrelated `ModuleStructureTest` failures for the pre-existing `examstaff` module/cycle state. Report: `pte-doc/projects/plans/quang-web-search-placeholder-rollout/quality/phase-05-validation-and-handoff-quality-report.json`.
- **Testing:** passed with two explicit limitations — scoped checks, both production builds, route smoke, and `git diff --check` passed; authenticated interactive browser/responsive-width automation was not available because the repo has no browser probe/Playwright harness, and the full app suite ended at 1356 tests with 1 unrelated failure and 1 unrelated error in `ModuleStructureTest`. Report: `pte-doc/projects/plans/quang-web-search-placeholder-rollout/tests/phase-05-validation-and-handoff-test-report.json`.
- Planned checks: completed; the remaining browser limitation is handed off for the user's one-pass visual review.

Phase status: completed with the browser-tooling limitation documented for review.
