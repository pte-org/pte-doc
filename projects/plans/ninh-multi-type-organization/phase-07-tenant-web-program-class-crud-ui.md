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

- [ ] A Host can create a Program under one of its Organizations, then
      create a Class under that Program, entirely from the UI.
- [ ] Archiving a Program/Class from the UI removes it from the visible
      list without a page-level error (list query correctly excludes
      archived rows, per Phase 2/3's backend contract).
- [ ] Searching by a partial phone number or name at
      `/host/students` finds a student regardless of which Program/Class
      they're in, without navigating there first.
- [ ] Every Program/Class label on these new screens reflects the caller's
      `organizationType` bucket (verified against both a School-family and
      a Center-family seeded tenant).
- [ ] `pnpm --filter tenant-web lint`/`build` clean; new routes appear in
      the build output.

## Quality and Testing State

- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after
  implementing this phase).
- Testing: not started.

## Risks

- Client-side join of two unbounded list endpoints for search — acceptable
  at current scale per existing repo convention, flagged as a future
  pagination trigger, not treated as a blocking gap in this phase.
