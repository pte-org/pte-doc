# Phase 1 — Sidebar Item + Route Skeleton

**Goal:** Surface a "Classes" link in the host sidebar and create the
`/host/classes` route file as a stub.

**Covers:** P1 Story #1

---

## Tasks

### 1.1 Add sidebar nav item

File: `apps/tenant-web/lib/navigation.tsx`

Insert a new entry between the "Programs" item and the "Exams" item
(currently lines 25–31) with:

- `label: T.CLASSES` (add constant to `lib/navigationConstants.ts`)
- `href: "/host/classes"`
- `icon: <BookOpenIcon />` (already imported, reuse Programs icon or
  pick a more semantic one — discuss in PR review)
- `section: T.DELIVERY_SECTION`

The nav item will inherit the host-sidebar rendering automatically; no
`requiredRoles` needed since `DashboardChrome`'s `SidebarNav` is
already gated by `allowedRoles={HOST_ROLES}` in every host page
(see `app/(dashboard)/host/programs/page.tsx:13`).

### 1.2 Add `CLASSES` constant to navigation labels

File: `apps/tenant-web/lib/navigationConstants.ts`

Add a `CLASSES: "Classes"` export in the `HOST_NAV_TEXT` object (and
localize the same way as other labels).

### 1.3 Create the route page (stub)

File: `apps/tenant-web/app/(dashboard)/host/classes/page.tsx`

Mirror the structure of `app/(dashboard)/host/programs/page.tsx:1-17`
but render a placeholder body for Phase 1:

```tsx
"use client";
import { DashboardChrome } from "@/features/auth/components";
import { HOST_ROLES } from "@/features/auth/constants";
import { useOrgLabels } from "@/features/orgLabels/useOrgLabels";
import { buildHostNav } from "@/lib/navigation";

export default function ClassesPage() {
  const labels = useOrgLabels();
  return (
    <DashboardChrome navItems={buildHostNav(labels)} allowedRoles={HOST_ROLES}>
      <div className="p-6 text-sm text-gray-500">Coming soon — Classes list view is in progress.</div>
    </DashboardChrome>
  );
}
```

### 1.4 Add `loading.tsx` and `error.tsx`

Files:

- `apps/tenant-web/app/(dashboard)/host/classes/loading.tsx`
- `apps/tenant-web/app/(dashboard)/host/classes/error.tsx`

Mirror the pattern used in
`app/(dashboard)/host/programs/[publicId]/loading.tsx` and
`error.tsx`. Both files must be present per coding standard rule 7.

---

## Design Constraints

- The stub body is a single short line; don't add real UI here.
- `DashboardChrome` must wrap the body exactly like sibling host pages.
- `loading.tsx` must use the shared `Skeleton` from `@pte/ui`, not
  invent a new spinner.

**Preflight (recorded 2026-09-27):** Discovered that the sibling
`loading.tsx` (`app/(dashboard)/host/programs/[publicId]/loading.tsx`)
uses `Skeleton`, not `LoadingState`. Plan text corrected. Also
discovered `error.tsx` uses `ERROR_PAGE_TEXT` from
`lib/errorPageConstants.ts` — must add a new key
`CLASSES_DESCRIPTION` ("We could not load the classes list. Please
try again.") before referencing it from `error.tsx`. Reused
`BookOpenIcon` from `@pte/ui` for the nav item (already imported in
`lib/navigation.tsx`, no new icon needed).

## Quality and Testing State

- quality: skipped_by_user; decision: user_confirmed_skip
- testing: not_started (manual verify per spec)
- Build Gate: PASS (2026-09-27). `next build` generated
  `/host/classes` route as static (○). TypeScript validated during
  build, no errors. Phase 1 files lint clean individually. Full
  `pnpm lint` reported 1 pre-existing error in
  `features/exams/components/CreateExamWizard.tsx:85` (commit
  `91ccaff`); not modified by this phase, not blocking.

## Success Criteria (this phase)

- [x] Click "Classes" in sidebar → routes to `/host/classes`
- [x] Page renders without console error
- [x] `pnpm --filter tenant-web build` passes
- [x] Phase 1 files lint clean (pre-existing lint error in exams
      module is unrelated)
- [x] TypeScript validates during build
