# Phase 01 — Inventory and Search Contract

## Goal

Turn the existing audit into an implementation manifest: every search surface is classified as a primary list, a contextual/nested table, a review table, or a custom input. Each enabled surface gets a field-level search contract before UI/API changes begin.

## Scope

- Reconfirm all 44 `DataTable` call sites in tenant-web and vendor-web.
- Include custom inputs in `ExistingStudentAssignmentModal`, `AudienceStep`, and tenancy filters.
- Mark the four intentional `showSearch={false}` tables.
- Identify the unused `_TenantFilters` path and the unused `ExamStaffTable` definition so they are not mistaken for visible routes.
- Create a mapping of screen, searchable fields, placeholder key, search mode, pagination mode, and owner API hook.

## Implementation steps

1. Compare the source inventory with current route imports and remove dead components from the visible-screen count.
2. For each table, inspect `filterAccessor`, rendered cell text, controlled search props, and pagination props.
3. For each paginated table, inspect the corresponding `@pte/api-client` request and pte-api endpoint before selecting server fields.
4. Decide one of: explicit client placeholder, controlled server search, or explicit `showSearch={false}`.
5. Record unresolved backend fields as implementation blockers rather than guessing copy.

## Deliverables

- A complete screen-to-search-field mapping used by later phases.
- Final list of the nine paginated search candidates and their API owners.
- Final list of contextual tables that should hide search.

## Design Constraints

- **Preflight:** Next.js 16/Tailwind v4 monorepo; `@pte/ui` owns `DataTable` and search visuals; feature copy belongs in feature constants/i18n; API access stays in feature hooks backed by `@pte/api-client`; `StudentSearchView`, `ExamStaffView`, and `PlatformUsersView` are the server-search conventions; no common visual defaults are changed in this phase.
- Do not change production behavior in this phase unless needed to correct the inventory.
- Use existing common components and current project terminology.
- Keep global page navigation search out of the entity-search contract.
- Preserve all unrelated worktree changes.

## Quality and Testing State

- **Quality:** approved — no blocking or advisory findings for the phase manifest and preflight contract. Report: `pte-doc/projects/plans/quang-web-search-placeholder-rollout/quality/phase-01-inventory-and-contract-quality-report.json`.
- **Testing:** passed — tenant tests 37/37 and api-client tests 435/435. Report: `pte-doc/projects/plans/quang-web-search-placeholder-rollout/tests/phase-01-inventory-and-contract-test-report.json`.
- Build gate: tenant/vendor lint passed; tenant/vendor/@pte-ui typecheck passed; `git diff --check` passed with pre-existing LF/CRLF warnings only.

Phase status: completed after explicit user approval to continue through all phases.
