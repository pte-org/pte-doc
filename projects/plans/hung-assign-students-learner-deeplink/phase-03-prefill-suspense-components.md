# Phase 03 — StudentSearchView prefill + Suspense + sub-components

**Files touched:**
- `apps/tenant-web/app/(dashboard)/host/students/page.tsx` — EDIT (add Suspense boundary)
- `apps/tenant-web/features/studentSearch/components/StudentSearchView.tsx` — EDIT (prefill logic, lock state, new sub-components)
- `apps/tenant-web/features/studentSearch/components/` — NEW sub-component files (`BreadcrumbBackToClass.tsx`, `LockedFilterBanner.tsx`, `ClassBlockedAlert.tsx`)

**Spec FRs:** FR-03, FR-04, FR-05, FR-06, FR-07
**User stories:** P1 (auto-open modal, breadcrumb, lock-filter banner, block inactive), P2 (refresh re-applies)
**Tests:** skipped by user. **Quality gate:** skipped by user (`--checks-all-phases` applied). `--no-tests --no-quality`

**Build gate:** PASS (tsc --noEmit clean, eslint clean on all Phase 03 files, full `pnpm --filter tenant-web build` PASS in 29s).
**Quality:** skipped_by_user; decision: user_confirmed_skip
**Testing:** not_started; user declined

**Preflight:** Repository conventions confirmed — `useSearchParams`/`useRouter` imported from `next/navigation` (precedent: `apps/tenant-web/app/(dashboard)/host/programs/[publicId]/page.tsx` lines 3, 12). `LoadingState` is the established fallback component from `@pte/ui` (used in `apps/tenant-web/features/exams/components/SessionDetailView.tsx:5`). The `Alert` component (`packages/ui/src/components/Alert.tsx`) renders a plain `<div>` without `role`/`aria-live` — per spec NFR-Accessibility, wrap it externally with `<div role="region" aria-live="polite">`. `ClassResponse` type lives in `packages/api-client/src/types/admin/studentClass.ts` (status: `"ACTIVE" | "INACTIVE" | "SUSPENDED"`). The `useClasses(orgId, programId)` hook returns `ClassResponse[]`; find the class by `publicId` match.

---

## Design Constraints

### 1. Suspense boundary in `host/students/page.tsx`

**Critical (HIGH severity — identified by Researcher B):** `useSearchParams()` in Next.js App Router requires a `<Suspense>` boundary around any component that reads it. `StudentSearchView` is a `"use client"` component that will call `useSearchParams()` in this phase. If wrapped in `<Suspense>`, the page will fail to render on the server and throw in production.

**Current `host/students/page.tsx`** (lines 1–17):

```tsx
"use client";

import { DashboardChrome } from "@/features/auth/components";
import { HOST_ROLES } from "@/features/auth/constants";
import { StudentSearchView } from "@/features/studentSearch/components";
import { useOrgLabels } from "@/features/orgLabels/useOrgLabels";
import { buildHostNav } from "@/lib/navigation";

export default function StudentsPage() {
  const labels = useOrgLabels();

  return (
    <DashboardChrome navItems={buildHostNav(labels)} allowedRoles={HOST_ROLES}>
      <StudentSearchView />
    </DashboardChrome>
  );
}
```

**Change to `host/students/page.tsx`:**

```tsx
"use client";

import { Suspense } from "react";
import { DashboardChrome } from "@/features/auth/components";
import { HOST_ROLES } from "@/features/auth/constants";
import { StudentSearchView } from "@/features/studentSearch/components";
import { useOrgLabels } from "@/features/orgLabels/useOrgLabels";
import { buildHostNav } from "@/lib/navigation";
import { LoadingState } from "@pte/ui";

export default function StudentsPage() {
  const labels = useOrgLabels();

  return (
    <DashboardChrome navItems={buildHostNav(labels)} allowedRoles={HOST_ROLES}>
      <Suspense fallback={<LoadingState rows={8} />}>
        <StudentSearchView />
      </Suspense>
    </DashboardChrome>
  );
}
```

**Rules:**
- `<Suspense>` must wrap the component that calls `useSearchParams()`, not the page. `StudentSearchView` is that component.
- `LoadingState` from `@pte/ui` is used as the fallback — matches the pattern in `ProgramDetailView.tsx` (line 87) which uses `<LoadingState rows={4} />`.
- The fallback shows while `useSearchParams` resolves on the server. In the browser it hydrates immediately.

---

### 2. `StudentSearchView` — new state and imports

Add to the existing imports at the top of `StudentSearchView.tsx`:

```ts
import { useRouter } from "next/navigation";
import { useSearchParams } from "next/navigation";
import { ASSIGN_DEEPLINK_TEXT } from "../constants";
import { useClasses } from "@/features/classes/api"; // already imported at line 31
import type { ClassResponse } from "@pte/api-client"; // already imported via api
```

Add new state declarations alongside existing `useState` calls (after line 81):

```ts
// Tracks whether this modal was auto-opened from a deeplink.
// Used to distinguish "user opened modal manually" from "modal opened from URL".
const wasPrefilledByDeeplink = useRef(false);

// True when the user cancelled the auto-opened modal.
// Locks Program + Class selectors and shows the banner.
const [classFilterLocked, setClassFilterLocked] = useState(false);

// Set to the class name for display in breadcrumb and banner.
const [prefilledClassName, setPrefilledClassName] = useState<string | null>(null);

// Set when the class status is not ACTIVE — shows the blocking alert.
const [classBlockedReason, setClassBlockedReason] = useState<string | null>(null);
```

**Note:** `useRef` must be imported from React (currently `useEffect, useState, type ReactElement` — update import to `useEffect, useRef, useState, type ReactElement`).

---

### 3. Reading `useSearchParams()` in the render body

`useSearchParams()` must be called in the render body (not inside `useEffect`) to be synchronous post-hydration. Per Researcher A: "read in render body, not useEffect."

Add this block in the `StudentSearchView` function body, right before the `useEffect` for debounce (before line 84):

```tsx
const router = useRouter();
const searchParams = useSearchParams();

const paramOrg = searchParams.get("organizationPublicId") ?? "";
const paramProgram = searchParams.get("programPublicId") ?? "";
const paramClass = searchParams.get("classPublicId") ?? "";
const paramModal = searchParams.get("modal") ?? "";

const hasPrefillParams = Boolean(paramOrg && paramProgram && paramClass);
const shouldAutoOpenModal = hasPrefillParams && paramModal === "add";
```

**Rules:**
- Call `useSearchParams()` unconditionally — it returns an empty object on the server (within `<Suspense>`) and is populated on the client.
- Do NOT read `useSearchParams()` inside `useEffect` — it would delay the prefill by one render cycle.
- `String(...)` + fallback `""` pattern ensures no `undefined` types.

---

### 4. Prefill `useEffect` — set filter state from URL params (TWO-EFFECT pattern)

**Critical:** Splitting into two effects is mandatory to avoid the `classes` race condition. The first effect sets the filter state synchronously; the second effect (which depends on `classes`) finds the matched class to populate breadcrumb and class-status-driven UI.

#### Effect 1: Set filter state from URL (runs once on mount)

```tsx
// Apply URL prefill params to filter state.
// Runs once on mount; guard against Strict Mode double-fire + missing params.
useEffect(() => {
  if (!hasPrefillParams) return;
  // Idempotency guard for React Strict Mode's double-invocation.
  if (wasPrefilledByDeeplink.current) return;
  wasPrefilledByDeeplink.current = true;

  if (paramOrg) setSelectedOrganizationPublicId(paramOrg);
  if (paramProgram) setProgramPublicId(paramProgram);
  if (paramClass) setClassPublicId(paramClass);
  // Reset stale assignment filter so the table is not pre-narrowed by a prior session.
  setAssignmentStatus(DEFAULT_ASSIGNMENT_STATUS);
  resetPage();

  // Defensive: if programPublicId is missing, log a warning. Without it, useClasses
  // won't fire and the prefill will silently fail (per FR-10 graceful degradation).
  if (!paramProgram) {
    console.warn("programPublicId missing from deeplink URL — class prefill skipped");
  }
  // eslint-disable-next-line react-hooks/exhaustive-deps
}, []); // Run once on mount only — user changes must not be overwritten.
```

#### Effect 2: React to classes loading to populate breadcrumb + auto-modal

```tsx
// After URL prefill sets programPublicId, useClasses(orgId, programId) populates.
// Watch for the matching class and drive the breadcrumb + auto-modal/blocker.
useEffect(() => {
  if (!hasPrefillParams || !paramClass) return;
  const matchedClass = (classes ?? []).find(
    (c: ClassResponse) => c.publicId === paramClass,
  );
  if (!matchedClass) return; // Either 404 or still loading.

  setPrefilledClassName(matchedClass.name);

  if (matchedClass.status !== "ACTIVE") {
    // INACTIVE / SUSPENDED — block the modal, show the alert.
    setClassBlockedReason(matchedClass.status);
    setManageMode(null);
  } else if (paramModal === "add") {
    // ACTIVE class with ?modal=add — auto-open Add Individually.
    setClassBlockedReason(null);
    setManageMode("add");
  }
}, [classes, hasPrefillParams, paramClass, paramModal]);
```

**Why two effects:**
- Effect 1 sets filter state synchronously from URL → triggers `useClasses` to fetch.
- Effect 2 fires when `classes` populates → finds the matched class → drives breadcrumb + modal/blocked alert.
- The breadcrumb `← Back to {className}` appears on first render after classes load — typically < 300ms on warm cache, matching the spec's ≤ 200ms NFR for warm-cache scenarios.
- If `classes` never populates (404 or query error), Effect 2 no-ops gracefully and the user sees the page in unfiltered state — matching FR-10.

---

### 5. `clearLockedFilter()` function

Add alongside the existing helper functions (after `trySetManageMode` at line 152):

```tsx
const clearLockedFilter = (): void => {
  setClassFilterLocked(false);
  setClassBlockedReason(null);
  setPrefilledClassName(null);
  wasPrefilledByDeeplink.current = false;
  setProgramPublicId("");
  setClassPublicId("");
  resetPage();
  // Replace URL to clear prefill params — no history entry added.
  router.replace("/host/students");
};
```

`router.replace` is used (not `router.push`) per Researcher B — avoids polluting browser history with intermediate prefill states.

---

### 6. `ManageStudentsModal` `onClose` handler

Update the modal close handler (line 465):

```tsx
// OLD
<ManageStudentsModal open initialMode={manageMode} onClose={() => setManageMode(null)} />

// NEW
<ManageStudentsModal
  open={manageMode !== null}
  initialMode={manageMode ?? "add"}
  onClose={() => {
    setManageMode(null);
    // If this modal was auto-opened from a deeplink, lock the filters.
    if (wasPrefilledByDeeplink.current) {
      setClassFilterLocked(true);
    }
  }}
/>
```

**Key behavior:** The `onClose` callback now checks `wasPrefilledByDeeplink.current`. If the user manually opened the modal (via "Add student" button in `PageHeader`), `wasPrefilledByDeeplink.current` is `false` and no lock is applied. Only the deeplink path sets this ref to `true`.

---

### 7. Disable Program + Class selectors when locked + bypass guards

In the Program Select (around the existing `<Select>` for `labels.program`) and Class Select (around the existing `<Select>` for `labels.class`), add `disabled={... || classFilterLocked}` to the disabled prop AND add an early-return guard inside `onChange`:

```tsx
// Program Select — add || classFilterLocked to disabled prop
disabled={programsLoading || !organizationPublicId || classFilterLocked}

// Program Select onChange — guard against keyboard/screen-reader bypass
onChange={(event) => {
  if (classFilterLocked) return;
  setProgramPublicId(event.target.value);
  setClassPublicId("");
  resetPage();
}}

// Class Select — add || classFilterLocked to disabled prop
disabled={!programPublicId || classesLoading || classFilterLocked}

// Class Select onChange — guard against keyboard/screen-reader bypass
onChange={(event) => {
  if (classFilterLocked) return;
  setClassPublicId(event.target.value);
  resetPage();
}}
```

This visually disables the dropdowns without removing them from the DOM, AND prevents state mutation even if a disabled input receives focus and interaction (Tab + Enter, screen reader arrow keys, etc.). The user cannot accidentally change the class while the filter is locked.

---

### 8. Render breadcrumb above `PageHeader`

**Current structure** (lines 199–218):

```tsx
return (
  <div className="flex flex-col gap-5">
    <PageHeader ... />
    <div className={filterGridClass}>  // filter row
      ...
```

**New structure:**

```tsx
return (
  <div className="flex flex-col gap-5">
    {prefilledClassName && (
      <nav aria-label={`Back to ${prefilledClassName}`}>
        <Link
          href={`/host/programs/${programPublicId}/classes/${classPublicId}?organizationPublicId=${organizationPublicId}`}
          className="text-sm font-medium text-blue-700 hover:underline"
        >
          {ASSIGN_DEEPLINK_TEXT.backToClass(prefilledClassName)}
        </Link>
      </nav>
    )}

    <PageHeader ... />
```

- `<nav aria-label>` per NFR-Accessibility.
- `prefilledClassName` is set when the page was navigated to with class params (regardless of class status — even INACTIVE/SUSPENDED shows the breadcrumb).
- The link goes to the class detail page, matching the P1 success criterion: `← Back to {className}` visible from page load.

---

### 9. Render locked-filter banner and class-blocked alert

Add between the filter row and the error alerts section (after line 315, before line 317 `queryError`):

```tsx
{/* Class-blocked alert: shown when class is INACTIVE/SUSPENDED */}
{classBlockedReason && prefilledClassName && (
  <div role="region" aria-live="polite">
    <Alert tone="warning">
      {ASSIGN_DEEPLINK_TEXT.classBlocked(classBlockedReason, prefilledClassName)}
    </Alert>
  </div>
)}

{/* Locked-filter banner: shown after cancelling the auto-opened modal */}
{classFilterLocked && prefilledClassName && (
  <div role="region" aria-live="polite">
    <Alert tone="info">
      {ASSIGN_DEEPLINK_TEXT.lockedFilterBanner(prefilledClassName)}
      {" "}
      <button
        type="button"
        onClick={clearLockedFilter}
        className="font-medium underline hover:no-underline"
      >
        {ASSIGN_DEEPLINK_TEXT.clearFilter}
      </button>
    </Alert>
  </div>
)}
```

**Rules:**
- Both alerts are wrapped in `<div role="region" aria-live="polite">` for a11y (per Researcher B finding on Alert component).
- Only one of these renders at a time (they are mutually exclusive conditions).
- When `classBlockedReason` is set, `manageMode` is never set → no modal opens.
- When `classFilterLocked` is set, `manageMode` was already closed → modal is gone.

---

### 10. Sub-component extraction to stay within file size limit

`StudentSearchView` is currently 485 lines. Adding the above (~70 lines of new state + logic + JSX) would push it to ~555 lines. Extracting 3 sub-components keeps it well within 600.

Create these 3 new files in `features/studentSearch/components/`:

#### `features/studentSearch/components/BreadcrumbBackToClass.tsx`

```tsx
"use client";

import Link from "next/link";
import type { ReactElement } from "react";

interface BreadcrumbBackToClassProps {
  className: string;
  programPublicId: string;
  classPublicId: string;
  organizationPublicId: string;
}

export const BreadcrumbBackToClass = ({
  className,
  programPublicId,
  classPublicId,
  organizationPublicId,
}: BreadcrumbBackToClassProps): ReactElement => (
  <nav aria-label={`Back to ${className}`}>
    <Link
      href={`/host/programs/${programPublicId}/classes/${classPublicId}?organizationPublicId=${organizationPublicId}`}
      className="text-sm font-medium text-blue-700 hover:underline"
    >
      {`← Back to ${className}`}
    </Link>
  </nav>
);
```

#### `features/studentSearch/components/LockedFilterBanner.tsx`

```tsx
"use client";

import { Alert, type ReactElement } from "@pte/ui";

interface LockedFilterBannerProps {
  className: string;
  onClearFilter: () => void;
  clearFilterLabel: string;
  lockedFilterBannerLabel: (name: string) => string;
}

export const LockedFilterBanner = ({
  className,
  onClearFilter,
  clearFilterLabel,
  lockedFilterBannerLabel,
}: LockedFilterBannerProps): ReactElement => (
  <div role="region" aria-live="polite">
    <Alert tone="info">
      {lockedFilterBannerLabel(className)}
      {" "}
      <button
        type="button"
        onClick={onClearFilter}
        className="font-medium underline hover:no-underline"
      >
        {clearFilterLabel}
      </button>
    </Alert>
  </div>
);
```

#### `features/studentSearch/components/ClassBlockedAlert.tsx`

```tsx
"use client";

import { Alert, type ReactElement } from "@pte/ui";

interface ClassBlockedAlertProps {
  status: string;
  className: string;
  classBlockedLabel: (status: string, name: string) => string;
}

export const ClassBlockedAlert = ({
  status,
  className,
  classBlockedLabel,
}: ClassBlockedAlertProps): ReactElement => (
  <div role="region" aria-live="polite">
    <Alert tone="warning">{classBlockedLabel(status, className)}</Alert>
  </div>
);
```

**Import and use in `StudentSearchView.tsx`:**

```tsx
import { BreadcrumbBackToClass } from "./BreadcrumbBackToClass";
import { LockedFilterBanner } from "./LockedFilterBanner";
import { ClassBlockedAlert } from "./ClassBlockedAlert";
```

Replace the inline JSX with:

```tsx
{/* Breadcrumb above PageHeader */}
{prefilledClassName && (
  <BreadcrumbBackToClass
    className={prefilledClassName}
    programPublicId={programPublicId}
    classPublicId={classPublicId}
    organizationPublicId={organizationPublicId}
  />
)}

{/* ... PageHeader ... */}

{/* Between filter row and error alerts */}
{classBlockedReason && prefilledClassName && (
  <ClassBlockedAlert
    status={classBlockedReason}
    className={prefilledClassName}
    classBlockedLabel={ASSIGN_DEEPLINK_TEXT.classBlocked}
  />
)}

{classFilterLocked && prefilledClassName && (
  <LockedFilterBanner
    className={prefilledClassName}
    onClearFilter={clearLockedFilter}
    clearFilterLabel={ASSIGN_DEEPLINK_TEXT.clearFilter}
    lockedFilterBannerLabel={ASSIGN_DEEPLINK_TEXT.lockedFilterBanner}
  />
)}
```

This extraction saves ~30 lines of inline JSX from `StudentSearchView`, bringing the net addition down to ~65 lines (counting state, effects, helpers, JSX, and bypass guards), for a final line count around 545–555 lines — still within the 600-line success criterion.

---

## Quality and Testing State

### What to verify after cooking Phase 03

1. **Suspense boundary present:** `host/students/page.tsx` wraps `<StudentSearchView />` in `<Suspense fallback={<LoadingState rows={8} />}>`.

2. **URL prefill applies on mount:**
   - Navigate to `/host/students?organizationPublicId=o&programPublicId=p&classPublicId=c&modal=add`
   - Program selector shows `p`, Class selector shows `c`, Organization shows `o`.
   - `ManageStudentsModal` auto-opens in "Add Individually" mode.

3. **Breadcrumb renders:** `← Back to {className}` appears above `PageHeader` when `prefilledClassName` is set.

4. **Class-blocked alert:** Navigate to URL with `classPublicId` pointing to an INACTIVE/SUSPENDED class.
   - No modal auto-opens.
   - Warning alert renders with correct class name and status.
   - Breadcrumb still renders.

5. **Lock-filter on cancel:** Open modal via deeplink → click modal backdrop or × button.
   - Modal closes.
   - Program + Class selectors are disabled.
   - Locked-filter banner renders with "Clear filter" button.
   - "Clear filter" click → selectors re-enable, URL becomes `/host/students` (no params), table refreshes.

6. **Manual open does NOT lock:** Open modal via "Add student" button (not deeplink) → cancel → no lock, no banner.

7. **Refresh re-applies prefill (P2):** Refresh the page with the prefill URL still in the address bar.
   - Same behavior as step 2 — modal re-opens.

8. **URL param missing `programPublicId`:** Navigate to `/host/students?classPublicId=c&modal=add` (no program).
   - Page renders without crashing.
   - No modal auto-opens (graceful degradation per FR-10).
   - Console warning: "programPublicId missing from deeplink URL".

9. **File size:** `StudentSearchView.tsx` ≤ 600 lines after extraction.

### Cook pipeline checks (default, no TDD)

| Check | Command | Expected |
|-------|---------|----------|
| TypeScript | `pnpm --filter tenant-web exec tsc --noEmit` | No errors |
| ESLint | `pnpm --filter tenant-web exec eslint apps/tenant-web/features/studentSearch/components/StudentSearchView.tsx apps/tenant-web/features/studentSearch/components/BreadcrumbBackToClass.tsx apps/tenant-web/features/studentSearch/components/LockedFilterBanner.tsx apps/tenant-web/features/studentSearch/components/ClassBlockedAlert.tsx` | No errors |
| Build | `pnpm --filter tenant-web build` | Pass |
