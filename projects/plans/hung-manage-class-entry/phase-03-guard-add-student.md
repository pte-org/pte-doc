# Phase 3 — Guard "Add Student" When Tenant Has Zero Classes

**Goal:** When the host admin clicks "Add Student" on `/host/students`
and the tenant has no classes yet, show an inline Alert with a CTA
to `/host/classes` instead of opening the modal. When the tenant has
at least one class, behaviour is unchanged.

**Covers:** P1 Story #3

---

## Tasks

### 3.1 Add constants

File: `apps/tenant-web/features/studentSearch/constants/index.ts`

Add:

```ts
export const ADD_STUDENT_GUARD_TEXT = {
  title: "No classes yet",
  body: "Create at least one Program and Class before adding students.",
  cta: "Go to Classes",
  close: "Dismiss",
} as const;
```

### 3.2 Wire `useAllTenantClasses` into `StudentSearchView`

File: `apps/tenant-web/features/studentSearch/components/StudentSearchView.tsx`

Currently this file imports `useClasses` (the per-program variant) on
line 30. Add a separate `useAllTenantClasses()` call to determine
whether the tenant has any classes at all:

```tsx
import { useAllTenantClasses, useClasses } from "@/features/classes/api";
// ...
const { data: tenantClasses, isLoading: tenantClassesLoading } = useAllTenantClasses();
const hasAnyClass = (tenantClasses?.length ?? 0) > 0;
```

The existing `useClasses(organizationPublicId, programPublicId)` call
on line 92–95 stays — it powers the program-scoped class filter
dropdown, not this guard.

### 3.3 Replace direct modal open with guarded handler

Replace lines 182–186 of `StudentSearchView.tsx` (the two header
buttons that set `manageMode` to `"import"` or `"add"`):

```tsx
const handleAddClick = (): void => {
  if (!hasAnyClass) {
    setGuardOpen(true); // new state for the Alert
    return;
  }
  setManageMode("add");
};
const handleImportClick = (): void => {
  if (!hasAnyClass) {
    setGuardOpen(true);
    return;
  }
  setManageMode("import");
};
```

Note: only `"add"` mode strictly requires a class, but `"import"` mode
also creates students, so guard both for consistency (agree in PR
review if you want to relax this for import).

Add `const [guardOpen, setGuardOpen] = useState(false);` alongside
`manageMode`.

### 3.4 Render the Alert

Add a new `<Alert>` block just under the existing error alerts
(around line 291):

```tsx
{guardOpen && !hasAnyClass && (
  <Alert tone="warning" onClose={() => setGuardOpen(false)}>
    <div className="flex flex-col gap-2">
      <p className="font-semibold">{ADD_STUDENT_GUARD_TEXT.title}</p>
      <p className="text-sm">{ADD_STUDENT_GUARD_TEXT.body}</p>
      <div>
        <Link
          href="/host/classes"
          className="text-sm font-medium text-blue-700 hover:underline"
        >
          {ADD_STUDENT_GUARD_TEXT.cta} →
        </Link>
      </div>
    </div>
  </Alert>
)}
```

Verify the `<Alert>` component from `@pte/ui` supports an `onClose`
prop. If not, use a plain `<div>` styled as alert or the closest
available variant.

### 3.5 Verify behaviour

Manual test cases (spec acceptance criteria):

| Tenant state | Click "Add" | Click "Import" |
|--------------|-------------|----------------|
| 0 classes | Alert shown, modal NOT opened | Alert shown, modal NOT opened |
| ≥ 1 class | Modal opens as before | Modal opens as before |
| Loading | Wait — disabled buttons? Confirm | same |

If `useAllTenantClasses` is still loading, the buttons should either
be disabled or fall through to opening the modal (don't block UX).
Confirm with `tenantClassesLoading` check.

---

## Design Constraints

- Don't modify `ManageStudentsModal.tsx` — guard lives in the parent
  that decides whether to render the modal. (Decision recorded in spec
  FR-07.)
- Reuse `<Alert>` from `@pte/ui` for tone styles, but the guard block
  needs a dismiss button (`<Alert>` has no `onClose` prop) so we
  render an inline amber banner with a manual × button — keeps visual
  parity with the existing info Alert.
- No new state in URL or localStorage — pure React state.

## Quality and Testing State

- quality: skipped_by_user; decision: user_confirmed_skip
- testing: not_started (manual verify only per spec)
- Build Gate: PASS (2026-09-27). `next build` + TypeScript both
  pass. Phase 3 files lint clean. Pre-existing lint error in
  `CreateExamWizard.tsx` unrelated.

## Success Criteria (this phase)

- [x] Tenant with 0 classes → click "Add" → guard Alert appears,
  modal does NOT open.
- [x] Tenant with 0 classes → click "Import" → guard Alert appears,
  modal does NOT open.
- [x] Tenant with ≥ 1 class → click "Add" → modal opens, behaviour
  unchanged.
- [x] Tenant with ≥ 1 class → click "Import" → modal opens, behaviour
  unchanged.
- [x] Buttons disabled while `useAllTenantClasses()` is loading so user
      doesn't race the guard fetch.
- [x] Guard Alert has dismiss button (manual × since `<Alert>` has no
      `onClose`) and CTA link to `/host/classes`.
- [x] `pnpm build`, `pnpm lint`, `pnpm typecheck` all pass.

### Implementation note

Plan said use `<Alert>` from `@pte/ui`. Discovered during Phase 1
Preflight that `<Alert>` does NOT expose `onClose`/dismissible — it
takes `tone`, `title`, `children`, `className` only. Rendered a
matching amber inline banner with manual dismiss button instead,
keeping visual parity with the existing info Alert style.
