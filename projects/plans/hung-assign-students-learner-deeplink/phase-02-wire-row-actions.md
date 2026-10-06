# Phase 02 — Wire row actions to navigate

**Files touched:**
- `apps/tenant-web/features/classes/components/ClassesSection.tsx` — EDIT (remove ImportOrAssignModal + importClassId state, switch ClassRowActions to useRouter + buildAssignStudentsUrl)
- `apps/tenant-web/app/(dashboard)/host/classes/page.tsx` — EDIT (replace setAssignContext with router.push, remove ImportOrAssignModal)
- `apps/tenant-web/features/classes/components/ClassesListView.tsx` — no change (already passes full context)
- `apps/tenant-web/features/programs/components/ProgramDetailView.tsx` — no change (does not pass onAssignStudents to ClassesSection)

**Spec FRs:** FR-01, FR-08
**User stories:** P1 (click Assign Students → navigate to Students page with pre-fill)
**Tests:** skipped by user. **Quality gate:** skipped by user (`--checks-all-phases` applied). `--no-tests --no-quality`

**Build gate:** PASS (tsc --noEmit clean, eslint clean on both files).
**Quality:** skipped_by_user; decision: user_confirmed_skip
**Testing:** not_started; user declined

**Preflight:** Repository conventions confirmed — `useRouter` is imported from `next/navigation` (see `useSearchParams` precedent in `ProgramsDetailView.tsx`). Plan's Option B pattern (row component calls `useRouter` + `buildAssignStudentsUrl` directly using the IDs already in scope) matches the existing pattern in `ClassesListView.ClassRowActions` (lines 70-83) where the row uses a `<Link>` with IDs already in scope. `host/classes/page.tsx` (line 9) and `ClassesSection.tsx` (line 17) currently import `ImportOrAssignModal` directly — those imports will be removed. `ClassesListView` does not import `ImportOrAssignModal`, so its scope is unaffected.

---

## Design Constraints

### Current state (what we're changing from)

#### `ClassesSection.tsx` — `ClassRowActions` interface (line 26–32)

```26:32:d:\GitHub\PTE-org\pte-web\apps\tenant-web\features\classes\components\ClassesSection.tsx
interface ClassRowActionsProps {
  organizationPublicId: string;
  programPublicId: string;
  studentClass: ClassResponse;
  onEdit: () => void;
  onAssignStudents: () => void;       // ← currently zero-arg
}
```

At line 180, the callback is:
```180:d:\GitHub\PTE-org\pte-web\apps\tenant-web\features\classes\components\ClassesSection.tsx
onAssignStudents={() => setImportClassId(studentClass.publicId)}
```

This drives `importClassId` state (line 141) which opens `ImportOrAssignModal` at line 278–285. **No `useRouter` exists in this file.**

#### `ClassesListView.tsx` — `ClassRowActionsProps` (lines 48–55)

```48:55:d:\GitHub\PTE-org\pte-web\apps\tenant-web\features\classes\components\ClassesListView.tsx
interface ClassRowActionsProps {
  option: TenantClassOption;
  onAssignStudents: (input: {    // ← already passes full context
    organizationPublicId: string;
    programPublicId: string;
    classPublicId: string;
  }) => void;
}
```

The parent `host/classes/page.tsx` uses this to set `assignContext` state (lines 57–68) which controls `ImportOrAssignModal` on the page level (lines 120–127). **No `useRouter` in this file either.**

#### `ProgramDetailView.tsx` — parent of `ClassesSection` (line 160–164)

`ClassesSection` is rendered with the zero-arg `onAssignStudents={() => setImportClassId(studentClass.publicId)}` inline. `ProgramDetailView` has no `useRouter`.

---

### Changes to make

#### 1. `ClassesSection.tsx`

**Change 1a — Update `ClassRowActionsProps` interface** (line 26–32):

```ts
// OLD
onAssignStudents: () => void;

// NEW
onAssignStudents: (input: {
  organizationPublicId: string;
  programPublicId: string;
  classPublicId: string;
}) => void;
```

**Change 1b — Update the callback passed to `ClassRowActions`** (line 175–181):

```ts
// OLD (line 180)
onAssignStudents={() => setImportClassId(studentClass.publicId)}

// NEW — no longer drives ImportOrAssignModal; navigates instead
onAssignStudents={{
  organizationPublicId,
  programPublicId,
  classPublicId: studentClass.publicId,
}}
```

**Change 1c — Remove `importClassId` state and `ImportOrAssignModal` rendering.**

Delete line 141 (`const [importClassId, setImportClassId] = useState<string | null>(null);`) and the `ImportOrAssignModal` JSX block around line 278–285. Since `ClassesSection` no longer owns the assign modal, the modal is no longer needed here.

> **Note:** If `importClassId` is referenced elsewhere (e.g. for merge selection or other logic), preserve those usages. Read the full file to confirm.

**Change 1d — Add `useRouter` and `buildAssignStudentsUrl` import to `ClassesSection`.**

At the top of the component (or the inner `ClassesSection` component function), add:

```ts
import { useRouter } from "next/navigation";
import { buildAssignStudentsUrl } from "../utils/assignStudentsUrl";
```

**Change 1e — Wrap `onAssignStudents` call in `ClassRowActions` with navigation.**

In the `ClassRowActions` component, replace the `onAssignStudents` prop handler to call `router.push`:

```ts
const router = useRouter();

// inside ClassRowActions:
<Button
  onClick={() =>
    router.push(
      buildAssignStudentsUrl("/host/students", {
        organizationPublicId,
        programPublicId,
        classPublicId: studentClass.publicId,
      }),
    )
  }
>
  {CLASS_ROW_ACTIONS_TEXT.assignStudents}
</Button>
```

Since `ClassRowActions` receives the full context already, it can call `buildAssignStudentsUrl` directly.

**Pattern:** Option B from the researcher report — the parent passes the full context object (the callback now carries the three IDs), and `ClassRowActions` uses `useRouter()` internally to navigate. This is the same pattern `ClassesListView` already follows for its navigation to class detail.

#### 2. `ProgramDetailView.tsx`

**Change 2a — Add `useRouter` import.**

```ts
import { useRouter } from "next/navigation";
```

**Change 2b — Destructure `useRouter` inside `ProgramDetailContent`.**

`ProgramDetailContent` is the component that renders `ClassesSection`. Add at the top of its function body:

```ts
const router = useRouter();
```

**Change 2c — Update `ClassesSection` call site** (line 160–164):

```ts
// OLD
<ClassesSection
  organizationPublicId={organizationPublicId}
  programPublicId={programPublicId}
  classLabel={classLabel}
/>

// NEW — pass no onAssignStudents; ClassRowActions inside ClassesSection now
// calls router.push directly using the IDs it already has.
<ClassesSection
  organizationPublicId={organizationPublicId}
  programPublicId={programPublicId}
  classLabel={classLabel}
/>
```

Since `ClassRowActions` inside `ClassesSection` now calls `router.push` directly, `ProgramDetailView` no longer needs to provide any `onAssignStudents` handler.

> **Alternative (more explicit):** If keeping `onAssignStudents` as a prop is preferred for testability, pass a no-op — but the chosen pattern (Option B) lets `ClassRowActions` own navigation directly using the IDs already in scope, matching how `ClassesListView` works.

#### 3. `ClassesListView.tsx`

**No structural changes.** The `ClassRowActionsProps` interface already passes the full context. The parent `host/classes/page.tsx` will be updated to use `router.push` instead of `setAssignContext`.

#### 4. `host/classes/page.tsx`

**Change 4a — Add `useRouter` and `buildAssignStudentsUrl` imports.**

```ts
import { useRouter } from "next/navigation";
import { buildAssignStudentsUrl } from "@/features/classes/utils/assignStudentsUrl";
```

**Change 4b — Destructure `useRouter`.**

Add inside the `ClassesPage` function:
```ts
const router = useRouter();
```

**Change 4c — Update `onRequestAssignStudents` callback body** (lines 62–68):

```ts
// OLD
const onRequestAssignStudents = (input: {
  organizationPublicId: string;
  programPublicId: string;
  classPublicId: string;
}): void => {
  setAssignContext(input);
};

// NEW
const onRequestAssignStudents = (input: {
  organizationPublicId: string;
  programPublicId: string;
  classPublicId: string;
}): void => {
  router.push(buildAssignStudentsUrl("/host/students", input));
};
```

**Change 4d — Remove `assignContext` state and `ImportOrAssignModal` rendering** (lines 57–68, 120–127).

Delete:
- `const [assignContext, setAssignContext] = useState<...>(null);`
- The `onRequestAssignStudents` setter pattern (now replaced above)
- `<ImportOrAssignModal key={...} open={assignContext !== null} ... />`

Since navigation now goes to `/host/students` with the full context, the `ImportOrAssignModal` on `host/classes` is no longer needed for the assign-students flow. If the page still needs `ImportOrAssignModal` for other reasons, keep it; otherwise remove to avoid dead code.

> **If `ImportOrAssignModal` is still needed on this page** (e.g. for a different entry point), keep the state but just no longer drive it from `onRequestAssignStudents`.

---

## Quality and Testing State

### What to verify after cooking Phase 02

1. **Both surfaces navigate correctly:**
   - Click Assign Students on a `ClassesSection` row → `router.push(buildAssignStudentsUrl("/host/students", {...}))` is called with correct `{ organizationPublicId, programPublicId, classPublicId }`.
   - Click Assign Students on a `ClassesListView` row → same.
   - Verify the URL includes `organizationPublicId`, `programPublicId`, `classPublicId`, and `modal=add`.

2. **`ImportOrAssignModal` is removed from `ClassesSection`** — the file no longer imports or renders it.

3. **`ImportOrAssignModal` is removed from `host/classes/page.tsx`** (or correctly decoupled from `onRequestAssignStudents`).

4. **`useRouter` is called only inside client components** (`ClassesSection`, `ProgramDetailContent`, `host/classes/page.tsx`). No server component calls `useRouter`.

5. **File size:** `ClassesSection.tsx` ≤ 300 lines after removing `ImportOrAssignModal` (~20 lines removed, net around 268 lines — within limit).

6. **`tsc --noEmit` passes** on all edited files.

### Cook pipeline checks (default, no TDD)

| Check | Command | Expected |
|-------|---------|----------|
| TypeScript | `pnpm --filter tenant-web exec tsc --noEmit` | No errors |
| ESLint | `pnpm --filter tenant-web exec eslint apps/tenant-web/features/classes/components/ClassesSection.tsx apps/tenant-web/features/programs/components/ProgramDetailView.tsx apps/tenant-web/app/\(dashboard\)/host/classes/page.tsx` | No errors |
| Build | `pnpm --filter tenant-web build` | Pass |
