# Phase 04 — Build / lint / typecheck gate

**No source files edited in this phase.** This phase runs the full quality gate and captures the build receipt.

---

## Design Constraints

This phase is a pure verification gate. No design decisions are made here.

The commands must pass in a fresh environment (no pre-existing build cache assumed).

---

## Quality and Testing State

### What to verify

1. **`pnpm --filter tenant-web build` passes** — production build succeeds end-to-end.

2. **`tsc --noEmit` passes** — no TypeScript errors across the entire `tenant-web` package.

3. **ESLint passes** — no lint errors in the new and modified files:
   - `features/classes/utils/assignStudentsUrl.ts`
   - `features/studentSearch/constants/index.ts`
   - `features/classes/components/ClassesSection.tsx`
   - `features/programs/components/ProgramDetailView.tsx`
   - `features/classes/components/ClassesListView.tsx`
   - `app/(dashboard)/host/classes/page.tsx`
   - `app/(dashboard)/host/students/page.tsx`
   - `features/studentSearch/components/StudentSearchView.tsx`
   - `features/studentSearch/components/BreadcrumbBackToClass.tsx`
   - `features/studentSearch/components/LockedFilterBanner.tsx`
   - `features/studentSearch/components/ClassBlockedAlert.tsx`

4. **File size targets:**
   | File | Target | Notes |
   |------|--------|-------|
   | `StudentSearchView.tsx` | ≤ 600 lines | Currently 485; ~40 net lines added = ~525 final |
   | `ClassesSection.tsx` | ≤ 300 lines | Currently 289; `ImportOrAssignModal` removal saves ~20 lines = ~268 final |
   | `ClassesListView.tsx` | ≤ 300 lines | Currently 294; no changes in Phase 02 = 294 final (slightly over; acceptable) |

5. **Success criteria from spec are met:**
   - Click Assign Students from row → URL becomes `/host/students?organizationPublicId=...&programPublicId=...&classPublicId=...&modal=add`
   - `ManageStudentsModal` auto-opens with `initialMode="add"`
   - `← Back to {className}` visible from page load, links to class detail
   - Close modal → banner appears + Program + Class selectors disabled
   - "Clear filter" → unlock + refresh + URL becomes `/host/students`
   - INACTIVE/SUSPENDED class → warning alert, no modal, breadcrumb visible
   - `pnpm --filter tenant-web build` PASS, `tsc --noEmit` clean, `eslint` clean

### Cook pipeline checks

| Check | Command | Expected |
|-------|---------|----------|
| TypeScript | `pnpm --filter tenant-web exec tsc --noEmit` | No errors |
| ESLint | `pnpm --filter tenant-web exec eslint apps/tenant-web/` | No errors |
| Build | `pnpm --filter tenant-web build` | Pass |

**Build gate:**
- `pnpm --filter tenant-web exec tsc --noEmit` — exit 0, no output
- `pnpm exec eslint features/studentSearch/components/StudentSearchView.tsx useAssignStudentsDeeplink.ts BreadcrumbBackToClass.tsx LockedFilterBanner.tsx ClassBlockedAlert.tsx 'app/(dashboard)/host/students/page.tsx'` — exit 0, no warnings
- `pnpm --filter tenant-web build` — PASS in 15.7s. `/host/students` route compiled.

**File size targets met:**
| File | Target | Actual |
|------|--------|--------|
| `StudentSearchView.tsx` | ≤ 600 | 575 ✅ |
| `ClassesSection.tsx` | ≤ 300 | 285 ✅ |
| `ClassesListView.tsx` | ≤ 300 | 293 ✅ |
| `BreadcrumbBackToClass.tsx` | small | 27 ✅ |
| `LockedFilterBanner.tsx` | small | 32 ✅ |
| `ClassBlockedAlert.tsx` | small | 20 ✅ |
| `useAssignStudentsDeeplink.ts` | small | 100 ✅ |

**Quality:** skipped_by_user; decision: user_confirmed_skip
**Testing:** not_started; user declined
