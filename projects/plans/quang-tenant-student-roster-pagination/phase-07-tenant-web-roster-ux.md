# Phase 07: Tenant-web roster UX

## Goal

Make Students a usable paged directory: visible by default, newest-first,
searchable, filterable, and honest about assignment and account state.

## Work items

1. Remove the `hasQuery` gate at
   `apps/tenant-web/features/studentSearch/components/StudentSearchView.tsx:27`
   so the first page renders immediately.
2. Replace the client-side join in `features/studentSearch/api/index.ts:88`
   (`useTenantStudentSearch`) with the paged roster hook. Keep
   `useClassMemberships()` exported — `features/classes`' `ImportOrAssignModal`
   still uses it.
3. Add a sort control with English constant-backed labels:
   `Recently added`, `Full name: A–Z`, `Full name: Z–A`, `Student code: A–Z`,
   and `Student code: Z–A`.
4. Add Program and dependent Class filters plus `All`, `Assigned`, and
   `Unassigned` assignment options. Use the existing organization label
   dictionary for Program/Class terminology.
5. Expand search copy and behavior to name, email, phone, and student code. The
   current implementation matches only `fullName` and `phone`.
6. Render rows from authoritative roster fields. Show `Unassigned` when no
   membership exists; never present the IAM profile `class_name` as a real
   assignment.
7. Add a status column using the existing `StatusBadge` component from `@pte/ui`
   so suspended accounts are visibly distinct rather than hidden.
8. Add row actions for suspend and reactivate, wired to the Phase 6 mutations.
   Confirm destructive suspend through the existing `ConfirmDialog`. Neither
   action has any UI today.
9. Extend `@pte/ui`'s existing `PaginationControls` rather than writing a second
   one. It currently renders previous/next and `Page x / y`; add an optional
   page-size selector (20/50/100), optional first/last, and a total-items label.
   Every new prop is optional and defaults preserve today's rendering, because
   vendor-web consumes this component too.
10. Reset page to 0 after every search/filter/sort change. Preserve query state
    in the URL if consistent with the app's existing routing conventions;
    otherwise keep it in component state for this phase.
11. After add/import success, invalidate/refetch the roster and class-related
    queries. Because projection delivery is asynchronous, show a bounded syncing
    state and do not claim the row is available before the API returns it.
12. Keep all user-visible strings in feature constants; keep the UI in English.

## Design constraints

- No client-side full-roster fetch and no client-side pagination.
- Changes to `@pte/ui` must be additive — vendor-web must render identically
  without passing any new prop.
- No hardcoded Program/Class names and no locale-specific parsing of class names.
- Empty, loading, error, and no-match states must be distinguishable.
- A filter change must never leave a stale total count attached to new rows.
- Pagination controls disable during a pending query without dropping the
  currently displayed rows.
- Maintain current accessibility behavior: labels, keyboard-selectable controls,
  and an announced result/page state where the shared UI supports it.

## Quality and testing state

- Unit tests: not started; user preference is `unitest: ko`.
- Quality: approved with 0 findings; see `quality/phase-07-tenant-web-roster-ux-quality-report.json`.
- Required non-unit verification: `@pte/ui`, vendor-web, and tenant-web
  build/lint/typecheck; manual browser walkthrough at desktop and narrow
  viewport; visual check that vendor-web's existing pagination is unchanged.

## Acceptance criteria

- Opening `/host/students` displays page 1 without entering a search term.
- Newest student appears before older students by default.
- Search, filter, sort, and pagination combinations produce the expected request
  and visible metadata.
- An unassigned student is visible under `All` and appears under `Unassigned`.
- A student with a real membership displays the membership Class and Program.
- A suspended student is visible and badged, and can be reactivated from the row.
- Add/import success refreshes the page without a full browser reload.
- vendor-web renders unchanged after the `@pte/ui` pagination extension.

## Cook status

- Implemented and verified with tenant/vendor typecheck, tenant lint, and tenant/vendor production builds on 2026-09-15; unit tests skipped by explicit user preference.
- Authenticated browser/API acceptance passed locally, including desktop and
  narrow viewport walkthroughs; no commit or push was made.
