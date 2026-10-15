# Plan: Search Placeholder and Full-Dataset Search Rollout

**Date:** 2026-10-12
**Status:** Implemented locally; validation complete with documented limitations
**Mode:** Hard
**Repository scope:** `pte-api`, `pte-web`, `pte-doc`
**Author:** quang
**Owner/slug:** `quang-web-search-placeholder-rollout`

## Scope Challenge

- **Exists?** Search already exists through the shared `@pte/ui` `DataTable` and a small number of feature-local inputs, but the current contract falls back to a generic placeholder and several server-paginated tables search only the loaded page.
- **Minimum?** Give every visible search control an explicit, localized description of the fields it searches; hide search on contextual tables where it has no user value; connect search to the server for paginated data so the result set is complete.
- **Complexity?** **Hard** — this spans 44 `DataTable` instances across tenant/admin, shared UI behavior, feature constants, TanStack Query hooks, `@pte/api-client`, and potentially pte-api contracts.
- **Mode:** Hard
- **Test:** default, with phase-specific unit/integration/browser verification.

## Baseline

- 44 `DataTable` instances were inventoried: 29 in tenant-web and 15 in vendor-web.
- 40 instances currently render search by default; 35 of those use the generic fallback from `DataTable`.
- 5 table call sites already provide a criteria-specific placeholder.
- 4 tables explicitly hide search and should remain hidden unless a product owner changes the intent.
- 9 server-paginated tables currently expose a local search that does not reach the API.
- Existing correct patterns are `StudentSearchView`, `ExamStaffView`, and `PlatformUsersView`.
- Existing worktree changes in the student-detail/UI description-list area are out of scope and must be preserved.

## User outcome

When a user sees a search field, the placeholder tells them what they can enter. When the table is paginated, a search returns matches across the full dataset rather than only the current page. Tables that are review-only or too contextual do not show a misleading search control.

## Research reports

### Primary — reuse the existing shared contract

`DataTable` already supports `searchPlaceholder`, `searchAriaLabel`, controlled `searchValue`, `onSearchChange`, `clientSideFiltering`, and external pagination. The safest implementation is to reuse those props, add feature-owned copy through existing constants/i18n, and copy the controlled server-search pattern from student search/exam staff/platform users.

### Alternative — keep search client-side or remove it

Adding only placeholders is low risk, but it leaves the nine paginated tables semantically wrong. Disabling search on all nine avoids misleading results but removes a useful workflow. This is acceptable only for endpoints where the API cannot support a meaningful search field; it is not the default solution.

### Decision

Use the primary approach. Add server-side search where the endpoint has a defensible searchable field; explicitly disable search where the data is contextual or the backend contract cannot support complete results. Do not change the shared visual styling of `DataTable`.

## Phase map

1. Inventory and define the search contract for every visible surface.
2. Apply localized placeholders and search visibility policy to tenant-web and vendor-web.
3. Connect tenant server-paginated search flows.
4. Connect vendor/admin server-paginated search flows.
5. Resolve mismatches, run browser verification, and close the quality gates.

## Cross-phase design constraints

- Reuse `DataTable`, `TableSearchControl`, `Input`, `PaginationControls`, existing tokens, and existing i18n/admin-copy mechanisms.
- Do not introduce a feature-local search component or alter common typography, sizing, colors, or trigger defaults.
- Keep route files thin and keep user-facing copy in constants/locale catalogs.
- A placeholder must describe fields actually included by `filterAccessor` or the server query; never promise an identifier that is not searchable.
- Server-side search must set `clientSideFiltering={false}` and include the query in the TanStack Query key.
- Search changes reset pagination to page 0 and use the existing debounce/controlled-input conventions.
- Preserve the seven existing uncommitted UI files and all unrelated worktree changes.

## Acceptance criteria

- No visible business table in the audited tenant/admin scope relies on the generic `Tìm kiếm trong bảng` / `Search table` fallback.
- Every enabled search has a Vietnamese/English localized placeholder and an appropriate accessible label.
- Every server-paginated search returns results across the complete server dataset, or is explicitly hidden with a documented reason.
- Empty search, no-result search, clear-search, loading, error, and page-reset states behave consistently.
- Question bank copy matches the actual searchable fields.
- The unused tenant-filter implementation is either integrated consistently or left clearly out of the visible route without conflicting copy.
- Scoped lint, typecheck, tests, build checks, and authenticated browser smoke checks pass.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| Backend endpoints differ in searchable fields | Confirm DTO/controller/repository behavior before adding each query parameter; otherwise hide search rather than fake full-dataset behavior. |
| Placeholder claims more fields than the filter actually uses | Derive copy from the final `filterAccessor`/API predicate and add request/filter tests. |
| Changing `DataTable` defaults affects unrelated consumers | Keep the fallback for compatibility; fix audited call sites explicitly and add a review checklist/static inventory. |
| Search causes excessive requests | Debounce input, cancel/stale-protect queries through TanStack Query, and reset page once per committed query. |
| Nested tables become visually noisy | Classify contextual tables in Phase 1 and explicitly set `showSearch={false}` where search has no meaningful scope. |

## Red-team review checklist

- Search on page 2 must not silently filter only page 2.
- Clearing search must restore the unfiltered total and page 0.
- A placeholder must not mention `slug`, `code`, `phone`, or `id` unless the actual predicate includes it.
- `toolbarActions` must not be mistaken for a replacement search toolbar.
- A table with zero or one meaningful row should not gain a search box merely because `DataTable` defaults to `showSearch=true`.
- The global “Tìm kiếm trang...” navigation control remains separate from entity/table search.

## Handoff

Ready to cook:

```text
/ck:cook --hard pte-doc/projects/plans/quang-web-search-placeholder-rollout/plan.md
```
