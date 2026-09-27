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
- `loading.tsx` must use the shared `LoadingState` from `@pte/ui`, not
  invent a new spinner.

## Quality and Testing State

- quality: not evaluated
- testing: not started (manual click sidebar → routes to `/host/classes`
  without console error, then verify route renders the stub)

## Success Criteria (this phase)

- [ ] Click "Classes" in sidebar → routes to `/host/classes`
- [ ] Page renders without console error
- [ ] `pnpm --filter @pte/tenant-web build` passes
- [ ] `pnpm --filter @pte/tenant-web lint` passes
- [ ] `pnpm --filter @pte/tenant-web typecheck` passes
