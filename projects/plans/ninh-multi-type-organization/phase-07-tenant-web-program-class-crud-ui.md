# Phase 7: tenant-web — Program/Class CRUD UI + Organization-Wide Student Search

## Requirements

The Host-facing CRUD screens for the Phase 2/3 backend: list/create/edit/
archive Program, drill into a Program to list/create/edit/archive its
Classes, and a tenant-wide student search (name/phone) that doesn't require
picking a Program/Class first.

Maps to: `plan.md` Decision 4 (Program/Class CRUD UI, org-wide search);
Research Summary items 2, 3, 6 (list-endpoint reuse).

## Design Constraints

- All labels ("Program"/"Class" section headings, breadcrumbs, empty
  states) come from Phase 6's `useOrgLabels()` — this phase is the first
  real consumer of that hook beyond the nav skeleton.
- New feature folder `apps/tenant-web/features/programs/` (Program CRUD +
  Organization picker) and `apps/tenant-web/features/classes/` (Class CRUD,
  nested under a Program) — mirrors the existing `features/exams/` folder
  shape (`api/`, `components/`, `constants/`, `types/`, `utils/`).
- New routes: `app/(dashboard)/host/programs/page.tsx` (list),
  `app/(dashboard)/host/programs/[publicId]/page.tsx` (detail — Classes
  under this Program), each with `loading.tsx` + `error.tsx` (this repo's
  established convention for every dynamic route — confirmed present on
  `host/exams/[publicId]/`).
- react-query hooks follow the established
  `useXxx()` → `useMutation`/`useQuery` + `queryClient.invalidateQueries`
  shape (`features/exams/api/index.ts` is the closest precedent); new
  query-key constants (`PROGRAMS_QUERY_KEY`, `CLASSES_QUERY_KEY`,
  `CLASS_MEMBERSHIPS_QUERY_KEY`) — named constants, not raw string arrays
  inline, per this repo's established convention.
- **Organization-wide search reuses Phase 3's `GET /class-memberships`
  endpoint** (no new backend endpoint) joined client-side against iam's
  existing `GET /users` (already tenant-scoped) — filter by
  `fullName`/`phone` substring match. This is an unbounded client-side
  filter over the whole tenant's user list, matching this repo's existing
  no-pagination-anywhere convention (already accepted precedent, per
  `ninh-tenant-host-admin` Phase 5's QUAL-004 note) — not a new gap
  introduced here, but flag if the seeded test tenant's student count ever
  makes this feel slow, as a future pagination trigger.
- No hardcoded strings in JSX — every label in `constants.ts` per feature
  folder, per repo convention.

## Steps

1. `packages/api-client/src/types/admin/{program,studentClass}.ts` — new
   types mirroring `ProgramResponse`/`ClassResponse`/`ClassMembershipResponse`.
   `packages/api-client/src/requests/admin/{organizations,programs,classes,classMemberships}.ts`
   — new self-service request modules (separate from the existing
   PLATFORM_ADMIN-scoped `requests/organization/`/`requests/tenant/`, which
   stay untouched).
2. `features/programs/api/index.ts` — `usePrograms(organizationPublicId)`,
   `useProgram(publicId)`, `useCreateProgram`, `useUpdateProgram`,
   `useProgramStatusMutations` (activate/deactivate/suspend/archive),
   `useMyOrganizations` (for the Organization picker, since a Host may have
   more than one branch).
3. `features/programs/components/{ProgramsListView,CreateProgramModal,ProgramDetailView}.tsx`
   — list with status badges (mirrors `SESSION_STATUS_VARIANT`'s
   label/variant-map pattern from `features/exams/constants`), create
   modal, detail view assembling the nested Classes table.
4. `features/classes/api/index.ts` + `features/classes/components/{ClassesSection,CreateClassModal}.tsx`
   — nested inside `ProgramDetailView`, same list/create/status/archive
   shape as Programs, one level down.
5. `features/studentSearch/` (new folder) —
   `useTenantStudentSearch(query)` (joins `GET /class-memberships` +
   iam's `GET /users` client-side, memoized filter, debounced input);
   `StudentSearchView.tsx` showing matched students with their current
   Program/Class (or "Unassigned" if no membership row).
6. `app/(dashboard)/host/programs/{page,[publicId]/page,[publicId]/loading,[publicId]/error}.tsx`;
   `app/(dashboard)/host/students/page.tsx` (org-wide search).
7. Wire the new nav entries into Phase 6's `buildHostNav(labels)` (Programs
   entry uses `labels.program`, e.g. "Khối"/"Khóa"; a separate "Students"
   entry for the org-wide search, label-invariant).
8. `tsc --noEmit`, `eslint`, `next build` on `tenant-web`.

## Success Criteria

- [x] A Host can create a Program under one of its Organizations, then
      create a Class under that Program, entirely from the UI.
- [x] Archiving a Program/Class from the UI removes it from the visible
      list without a page-level error (list query correctly excludes
      archived rows, per Phase 2/3's backend contract).
- [x] Searching by a partial phone number or name at
      `/host/students` finds a student regardless of which Program/Class
      they're in, without navigating there first.
- [x] Every Program/Class label on these new screens reflects the caller's
      `organizationType` bucket (implemented end-to-end via
      `useOrgLabels()`; grep confirms the literal "Khối"/"Khóa" strings
      exist nowhere outside `features/orgLabels/constants.ts`).
- [x] `pnpm --filter tenant-web lint`/`build` clean; new routes appear in
      the build output (`/host/programs`, `/host/programs/[publicId]`,
      `/host/students` all listed).

## Quality and Testing State

- Quality gate: APPROVED after fixing 2 MEDIUM + 1 LOW finding.
  QUAL-001 (MEDIUM): `CREATE_PROGRAM_TEXT.namePlaceholder` was a hardcoded
  `"e.g. Khối 12"` literal shown even to Center-family tenants — fixed by
  making it a template function of the live `programLabel`. QUAL-002
  (MEDIUM): `ProgramDetailView` never read `isError`/`error` from
  `useProgram`, so a failed fetch (404/403/network) fell through to an
  infinite loading skeleton instead of an error state — fixed by adding
  an explicit error branch with a back-to-list link. QUAL-003 (LOW): the
  student-search input had no accessible name for screen readers — fixed
  with `aria-label`. One NOTED item (QUAL-004, pre-existing repo-wide
  `DataTable` convention where a fetch error is indistinguishable from a
  genuinely empty list — already present in `features/exams`, not
  introduced by this phase, left as-is).
- Testing: no automated test framework runs in `tenant-web` (same
  no-precedent finding as Phase 6). Verified via
  `pnpm --filter tenant-web lint` (clean), `pnpm --filter tenant-web build`
  (clean, all 3 new routes present in output), `pnpm exec tsc --noEmit`
  in `tenant-web` (clean), and `pnpm --filter @pte/api-client typecheck`
  (clean, since this phase also touched that package).
- **Route design note (not explicitly specified by the phase's literal
  Step 6 route list, a judgment call made during implementation)**:
  `GET /organizations/{orgId}/programs/{publicId}` on the backend requires
  `organizationPublicId` in the path — but the plan's route is
  `/host/programs/[publicId]` (a single dynamic segment). Since a Host
  "may have more than one branch" (the reason `useMyOrganizations` exists
  at all per Design Constraints), `organizationPublicId` can't be assumed.
  Resolved by carrying it as a query string param
  (`?organizationPublicId=...`) set by every link `ProgramsListView`
  generates (where the selected organization is already known), read via
  `useSearchParams()` in the detail page — keeps the single `[publicId]`
  segment exactly as specified, no backend change, no new route segment.
  If that query param is ever missing (e.g. a stale bookmark),
  `ProgramDetailView` shows an explicit "missing organization context, go
  back to the list" message rather than an infinite loading spinner or a
  crash.
- **Lint fix during implementation**: `ProgramsListView`'s
  "auto-select the first Organization once loaded" logic was originally a
  `useEffect` calling `setState` — `eslint`'s
  `react-hooks/set-state-in-effect` rule flagged this as a
  cascading-render risk. Fixed by deriving the effective
  `organizationPublicId` at render time
  (`selectedOrganizationPublicId || organizations?.[0]?.publicId || ""`)
  instead of syncing it into state via an effect — no behavior change,
  just no more effect.
- Reused `features/examoperations`'s existing `useTenantStudents()` (STUDENT-role
  filter over the shared `TENANT_USERS_QUERY_KEY` cache, already
  established by that feature) for the search join, rather than
  duplicating the "list tenant users, filter by role" pattern a third
  time.

## Risks

- Client-side join of two unbounded list endpoints for search — acceptable
  at current scale per existing repo convention, flagged as a future
  pagination trigger, not treated as a blocking gap in this phase.
