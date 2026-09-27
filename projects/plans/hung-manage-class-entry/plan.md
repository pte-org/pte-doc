# Plan: Manage Class Entry Point

**Date:** 2026-09-27
**Slug:** `manage-class-entry`
**Mode:** Hard
**Spec:** `spec.md` (validated, no open questions)
**Test mode:** default (no TDD — spec explicitly says manual verify only)

---

## Goal

Add a tenant-wide "Manage Class" entry point at `/host/classes` that surfaces
all classes across all Programs in one place, blocks the "Add Student"
modal when the tenant has zero classes, and locks in the
**Program → Class → Student** flow at the UI level.

### User Stories Covered

| Phase | P1 / P2 / P3 | Stories |
|-------|--------------|---------|
| Phase 1 | P1 #1 | Sidebar shows "Classes" link |
| Phase 2 | P1 #2, P2 #4, P2 #5 | `/host/classes` lists tenant classes, filter by program, empty states |
| Phase 3 | P1 #3 | "Add Student" modal blocked when tenant has 0 classes |

---

## Architecture Overview

### Existing code reused (no rewrite)

- `useAllTenantClasses()` — `features/classes/api/index.ts:203` — fan-out
  pattern Organizations → Programs → Classes; returns `TenantClassOption[]`
  with `organizationPublicId`, `programPublicId`, `programName`,
  `classPublicId`, `className`, `status`.
- `CLASS_STATUS_LABELS` / `CLASS_STATUS_VARIANT` /
  `CLASS_TABLE_HEADERS` — `features/classes/constants/index.ts`.
- `useClassStatusMutations` — `features/classes/api/index.ts:82` — for the
  action menu (Activate / Deactivate / Suspend / Archive).
- `EditClassModal` — already exists, can be reused for inline edit.
- `HOST_ROLES` — `["HOST_ADMIN"]` from `features/auth/constants.ts`.
- `useOrgLabels()` — returns `program` / `class` labels per org type.

### New code (only what's missing)

1. `app/(dashboard)/host/classes/page.tsx` — 1 page, ~15 lines.
2. `features/classes/components/ClassesListView.tsx` — ~200 lines.
3. `features/classes/constants/index.ts` — ~30 lines of new constants
   (table headers for the tenant-wide view, empty state text, CTA
   labels).
4. `lib/navigation.tsx` — 1 nav item, ~6 lines.
5. `features/studentSearch/components/StudentSearchView.tsx` — guard +
   Alert, ~30 lines diff.

### Why no new API hook

`useAllTenantClasses()` already does the fan-out. The spec originally
assumed a `GET /api/v1/classes?tenantId=` endpoint that does not exist
(verified during spec drafting). The fan-out pattern is the established
convention for this kind of cross-program listing in this codebase
(comment in `features/classes/api/index.ts:195-202` documents the
trade-off and "accepted-unbounded-client-side" scale).

### Performance constraint

NFR says ≤ 500 classes render in < 1s p95. With fan-out at small
scale (≤ 5 orgs × ≤ 50 programs = ≤ 250 parallel listClasses calls at
worst case), React Query caching + memoization in the list view is
sufficient. We will:

- Use `useMemo` to filter by `programPublicId`.
- Render with `DataTable` (already used by `ClassesSection`).

No backend changes; risk documented in brainstorm risks section.

---

## Phases

| # | File | Scope | Story |
|---|------|-------|-------|
| 1 | `lib/navigation.tsx` + `app/(dashboard)/host/classes/page.tsx` + `loading.tsx` + `error.tsx` | Add sidebar item + route skeleton (stub `<div>` body) | P1 #1 |
| 2 | `features/classes/components/ClassesListView.tsx` + constants | Build the tenant-wide list view with table, filter, empty states (inline conditionals) | P1 #2, P2 #4, P2 #5 |
| 3 | `features/studentSearch/components/StudentSearchView.tsx` | Guard "Add Student" when tenant has 0 classes (inline Alert + CTA) | P1 #3 |

---

## Design Constraints (cross-phase)

- **No hardcoded strings** — `docs/CODING_STANDARDS_WEB.md` rule 1. Use
  constants in `features/classes/constants/index.ts`.
- **No inline styles** — rule 2. Tailwind only.
- **No `any` type** — rule 3.
- **File ≤ 300 lines** — rule 4. `ClassesListView` will extract
  sub-components (`_TableRowActions`, `_EmptyState`, etc.) if needed.
- **All API via TanStack Query** — rule 5. We use
  `useAllTenantClasses()`, not raw `fetch()`.
- **Dynamic routes have `loading.tsx` and `error.tsx`** — rule 7. The
  `/host/classes` route needs both.
- **Secrets** — rule 9. No new env vars; existing
  `NEXT_PUBLIC_API_BASE_URL` only.
- **Next.js primitives** — rule 10. Use `next/link`, not raw `<a>`.

---

## Risks

| # | Risk | Mitigation |
|---|------|------------|
| 1 | Fan-out N+1 (1 + N×M requests) hits perf ceiling | Accepted at MVP scale (≤ 50 programs). Documented in brainstorm. |
| 2 | UX regression: users used to free-text className confused by blocked modal | Empty state with explicit CTA "Tạo Program & Class trước" → 1 click recovery. |
| 3 | `useAllTenantClasses()` runs on every page mount — could trip Suspense if slow | Wrap page in `DashboardChrome` (handles auth, not Suspense). DataTable has its own `isLoading` skeleton. |
| 4 | Constant duplication risk between `ClassesSection` and `ClassesListView` | Extract shared strings to `features/classes/constants/index.ts`. Don't localize per-view. |

---

## Quality and Testing State

| Phase | Quality | Testing |
|-------|---------|---------|
| 1 | not evaluated | not started |
| 2 | not evaluated | not started |
| 3 | not evaluated | not started |

Per spec: e2e tests are out of scope. Manual verification only.

---

## Handoff

After all 3 phases pass `pnpm --filter @pte/tenant-web build` and
`pnpm --filter @pte/tenant-web lint` and `pnpm --filter @pte/tenant-web
typecheck`, run `/ck:review` for final review.
