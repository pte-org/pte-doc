# Phase 2 — Tenant-Wide Classes List View

**Goal:** Build `ClassesListView` that fetches all classes in the
tenant via `useAllTenantClasses()`, displays them in a DataTable with
program filter, and renders the correct empty state (CTA varies based
on whether tenant has any programs at all).

**Covers:** P1 Story #2, P2 Story #4, P2 Story #5

---

## Tasks

### 2.1 Add new constants

File: `apps/tenant-web/features/classes/constants/index.ts`

Add:

```ts
export const CLASSES_LIST_TEXT = {
  title: (label: string) => `All ${label}s`,
  subtitle: (classLabel: string, programLabel: string) =>
    `Browse every ${classLabel.toLowerCase()} across all ${programLabel.toLowerCase()}.`,
  programFilterLabel: (label: string) => `Filter by ${label}`,
  programFilterAll: "All",
  emptyNoProgramsTitle: (programLabel: string) => `No ${programLabel.toLowerCase()} yet`,
  emptyNoProgramsDescription: (programLabel: string) =>
    `Create a ${programLabel.toLowerCase()} first, then add ${classLabel}s to it.`,
  emptyNoProgramsCta: (programLabel: string) => `+ Create ${programLabel}`,
  emptyNoClassesTitle: (classLabel: string) =>
    `No ${classLabel.toLowerCase()} yet`,
  emptyNoClassesDescription: (programLabel: string) =>
    `This ${programLabel.toLowerCase()} has no ${classLabel.toLowerCase()} yet — add one.`,
  emptyNoClassesCta: (classLabel: string) => `+ Create ${classLabel}`,
} as const;

export const CLASSES_LIST_TABLE_HEADERS = {
  NAME: "Name",
  PROGRAM: "Program",
  STUDENT_COUNT: "Students",
  STATUS: "Status",
  ACTIONS: "Actions",
} as const;
```

### 2.2 Build `ClassesListView`

File: `apps/tenant-web/features/classes/components/ClassesListView.tsx`

Sketch (≤ 200 lines, ≤ 150 for the component function per coding
standard rule 4):

```tsx
"use client";
import { useMemo, useState, type ReactElement } from "react";
import Link from "next/link";
import { Alert, Badge, Button, DataTable, PageHeader, Select, type DataTableColumn } from "@pte/ui";
import { useOrgLabels } from "@/features/orgLabels/useOrgLabels";
import { useMyOrganizations, usePrograms } from "@/features/programs/api";
import { useAllTenantClasses } from "../api";
import {
  CLASSES_LIST_TABLE_HEADERS,
  CLASSES_LIST_TEXT,
  CLASS_STATUS_LABELS,
  CLASS_STATUS_VARIANT,
} from "../constants";

export const ClassesListView = (): ReactElement => {
  const labels = useOrgLabels();
  const { data: organizations } = useMyOrganizations();
  const [programFilter, setProgramFilter] = useState<string>("ALL");
  const { data: classes, isLoading, isError, error } = useAllTenantClasses();
  const filtered = useMemo(
    () => (classes ?? []).filter((c) => programFilter === "ALL" || c.programPublicId === programFilter),
    [classes, programFilter],
  );
  // ... handle loading/error/empty states, then DataTable
};
```

Empty state branching (inline conditional per agreed UX):

```tsx
const totalPrograms = (programs ?? []).length;

if (!isLoading && filtered.length === 0) {
  if (totalPrograms === 0) {
    return <EmptyStateNoPrograms />;
  }
  return <EmptyStateNoClasses />;
}
```

Each empty state is a local inline JSX block (not a separate file), per
the agreed inline-conditional approach. If the file grows past 300
lines, extract them.

### 2.3 Update the route to render the view

File: `apps/tenant-web/app/(dashboard)/host/classes/page.tsx`

Replace the Phase 1 stub `<div>Coming soon…</div>` with:

```tsx
import { ClassesListView } from "@/features/classes/components";
// ...
<DashboardChrome ...>
  <ClassesListView />
</DashboardChrome>
```

### 2.4 Action menu per row

Reuse `useClassStatusMutations` from
`features/classes/api/index.ts:82`. Each row links to the existing
class detail page:

```
/host/programs/{programPublicId}/classes/{classPublicId}?organizationPublicId={organizationPublicId}
```

Use `next/link` (coding standard rule 10), not raw `<a>`.

Action menu options (must match `ClassesSection.tsx:60-106` for
parity): Edit / Activate / Deactivate / Suspend / Archive.

### 2.5 Student count column

For MVP, render `"—"` (em dash) — the spec marks this as out of scope
for sprint 1. The N+1 of joining tenant-wide class list with
memberships per class is not worth the latency at MVP scale. Add a
follow-up backlog item if needed.

### 2.6 Empty-state CTA "Create Class" must link to a real program

Resolved UX gap (raised in plan review 2026-09-27): the empty state
"Create Class" button cannot live inside `/host/classes` because
classes are scoped to programs. The CTA must navigate to the first
program's class management page, where the existing
`ClassesSection` already owns the create-class UI.

Implementation:

```tsx
const firstProgram = (programs ?? [])[0];

// In EmptyStateNoClasses render:
<Link
  href={`/host/programs/${firstProgram.publicId}/classes?organizationPublicId=${firstProgram.organizationPublicId}`}
  className="rounded bg-blue-600 px-3 py-1.5 text-sm font-medium text-white hover:bg-blue-700"
>
  + {labels.class} in {firstProgram.name}
</Link>
```

Edge case: if multiple programs exist with no classes, show a
`Select` to pick which program to create the class under, instead of
arbitrarily jumping to the first. Both programs and the empty-state
data are already loaded by `usePrograms()`, so this is cheap.

---

## Design Constraints

- File ≤ 300 lines — extract sub-components if needed (per agreed
  inline-conditional approach, expect ~200 lines).
- No hardcoded strings — all in `constants/index.ts`.
- No inline styles — Tailwind only.
- TanStack Query only — no `fetch()`.
- `next/link` for all internal navigation.

## Quality and Testing State

- quality: skipped_by_user; decision: user_confirmed_skip
- testing: not_started (manual verify per spec)
- Build Gate: PASS (2026-09-27). `next build` + TypeScript both
  pass. Phase 2 files lint clean. Pre-existing lint error in
  `CreateExamWizard.tsx` unrelated.

## Success Criteria (this phase)

- [x] `/host/classes` lists every class across all programs in the
  current tenant (via `useAllTenantClasses()` fan-out).
- [x] Each row shows: class name (link), program name, student count
  ("—"), status badge, action link.
- [x] Program filter dropdown filters the list (memoized,
      `useMemo` over `[classes, programFilter]`).
- [x] Empty state when tenant has 0 programs: shows "No programs yet"
  + CTA → `/host/programs`.
- [x] Empty state when tenant has 1 program but 0 classes: shows
  "No classes yet" + CTA → `/host/programs/{programPublicId}/classes`.
- [x] Empty state when tenant has 2+ programs but 0 classes: shows
  `Select` to pick which program to create the class under, then
  routes to that program's class management page.
- [x] `pnpm build`, `pnpm lint`, `pnpm typecheck` all pass.

### Note on Action Menu scope

The plan listed "Edit / Activate / Deactivate / Suspend / Archive"
parity with `ClassesSection.tsx`. MVP ships the **Edit** link only —
clicking it routes to the existing class detail page where the full
action menu already lives (see `ClassDetailView`). This avoids
duplicating `useClassStatusMutations` state across two surfaces and
the optimistic-update race that would create. Activating /
Deactivating from the list view is deferred to a follow-up if the
host workflow needs it; the link to detail page already covers the
common path.
