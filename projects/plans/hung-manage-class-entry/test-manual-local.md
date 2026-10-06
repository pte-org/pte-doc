# Manual Test Plan — hung-manage-class-entry

Feature: Tenant-wide Classes list at `/host/classes` + "Add Student" guard at `/host/students`.

Scope: All 3 phases (sidebar/route, list view, guard).
Mode: Manual verification only — spec FR-04 states e2e tests are out of scope.
Tested against: dev server at `http://localhost:3000` with running backend.

---

## Pre-flight

### 1. Start the stack

```powershell
# Terminal 1 — backend (adjust to your local setup)
cd D:\GitHub\PTE-org\pte-api
./mvnw spring-boot:run

# Terminal 2 — tenant-web
cd D:\GitHub\PTE-org\pte-web
pnpm --filter tenant-web dev
```

Wait for:
- Backend: `Started PteApiApplication`
- Frontend: `Ready in ...` printed by Next.js

If the frontend was previously built, force a fresh Turbopack root to avoid caching surprises:
```powershell
Remove-Item -Recurse -Force apps\tenant-web\.next -ErrorAction SilentlyContinue
```

### 2. Confirm a host account exists

Use one of the seed users from `pte-api/scripts/seed-local-template-and-question-bank.ps1`, or any account that has role `HOST_ADMIN` / `HOST_STAFF`. Open `http://localhost:3000/login` and sign in.

Expected: `DashboardChrome` renders with the existing sidebar items (Overview, Learners, Exam Staff, …, Exams, …).

---

## Phase 1 — Sidebar nav item + route skeleton

### Test 1.1 — Sidebar shows "Classes" link
1. Sign in as host user.
2. Look at the host sidebar (between `Programs`/`Delivery` and `Exams`).

**Expected:**
- A `Classes` link is visible in the `Delivery` section.
- It is **not** duplicated and **not** missing.
- Hovering shows the same hover style as `Programs` / `Exams`.

### Test 1.2 — Navigation route + render
1. Click the `Classes` link in the sidebar.

**Expected:**
- URL becomes `http://localhost:3000/host/classes`.
- Page header shows the org-label word (e.g. `Class`).
- Body shows the list view (Phase 2 will replace the stub; during Phase 1 alone you'd see placeholder text — but since we shipped Phase 1+2+3 together, you'll see Phase 2's output).
- No 404, no console error in DevTools → Console tab.

### Test 1.3 — Loading + error boundaries render
1. Open DevTools → Network → set throttle to "Slow 3G" or block all requests to `/host/classes` (block the `classes` query path).
2. Refresh `/host/classes`.

**Expected:**
- A skeleton block (3 grey rectangles) appears while the request is in flight (this is the `loading.tsx`).
- If you artificially fail the request (e.g. stop the backend), the error page renders with: title "Something went wrong", body "We could not load the classes list. Please try again.", and a `Try again` button.

### Test 1.4 — Role gating
1. Sign out. Sign back in as an **examiner** or **student** account.

**Expected:**
- `/host/classes` is unreachable for that role — you should be redirected / bounced to the login page (this is enforced by `DashboardChrome`'s `allowedRoles={HOST_ROLES}`, same as other host pages).

---

## Phase 2 — Classes list view

Setup: you'll want at least one tenant with a mix of programs/classes. If the seed script doesn't already cover that, create them manually via the existing program/class UI first, then return to `/host/classes`.

### Test 2.1 — Multi-class happy path (tenant has ≥ 1 program with ≥ 1 class)
1. Ensure tenant has at least one program and at least one class in it.
2. Open `/host/classes`.

**Expected:**
- Page header is the org-label word (`Class`).
- Subtitle reads roughly: `Browse every class across all programs.`
- DataTable renders rows, each with: name (blue link), program name, "—" in student-count column, status badge, `Edit` link.
- If only 1 program exists: no filter dropdown visible.
- If ≥ 2 programs exist: a `Filter by Program` dropdown is shown above the table.

### Test 2.2 — Program filter
1. With ≥ 2 programs, open the filter dropdown.
2. Select a specific program.

**Expected:**
- Table updates within ~100ms (filter is `useMemo` over `[classes, filter]`).
- "All programs" option is the first entry.
- Re-select "All programs" restores the full list.
- Count label (e.g. "5 classes") updates to match the visible row count.

### Test 2.3 — Sort order
The filter dropdown's program list is sorted alphabetically by `program.name` (`localeCompare`).

**Expected:** Programs appear A → Z in the filter dropdown.

### Test 2.4 — Empty state — 0 programs in tenant
1. Create a fresh tenant (or clean the existing one) so it has 0 programs.
2. Open `/host/classes`.

**Expected:**
- No DataTable renders.
- A single block with `PageHeader`, a sentence about needing a program first, and a `+ Create Program` button styled blue/white.
- Clicking the button routes to `/host/programs`.

### Test 2.5 — Empty state — 1 program, 0 classes
1. Tenant has exactly 1 program, 0 classes.
2. Open `/host/classes`.

**Expected:**
- No table, no filter.
- Block: `PageHeader`, text `No class yet`, a single blue `+ Create Class in <programName>` link.
- Clicking routes to `/host/programs/<programPublicId>/classes` (the existing program-scoped class management view, where `ClassesSection` lives).

### Test 2.6 — Empty state — ≥ 2 programs, 0 classes
1. Tenant has ≥ 2 programs but no classes in any.
2. Open `/host/classes`.

**Expected:**
- No table, no filter.
- Block: `PageHeader`, sentence `No class yet — Pick a program to add a class to:`, a `Select` populated with program names, a `+ Create Class in <picked>` link appears once a program is chosen.
- Picking a program and clicking the link routes to `/host/programs/<pickedPublicId>/classes`.

### Test 2.7 — Row links go to class detail
1. Click a class name or `Edit` link in the DataTable.

**Expected:**
- URL becomes `/host/programs/<programPublicId>/classes/<classPublicId>?organizationPublicId=<orgPublicId>`.
- The existing ClassDetailView renders (this view was not modified by Phase 2 — sanity check that the link format matches `ClassesSection.tsx:152`).

### Test 2.8 — Status badge mapping
1. Create classes with all three statuses: ACTIVE, INACTIVE, SUSPENDED. (Archived classes are filtered upstream in `useAllTenantClasses`? — actually no, the queryFn returns whatever the backend returns; verify this is fine.)

**Expected:**
- ACTIVE → green/success badge, "Active" label.
- INACTIVE → neutral badge, "Inactive".
- SUSPENDED → amber/warning badge, "Suspended".

### Test 2.9 — Error state
1. Stop the backend mid-load on `/host/classes`.

**Expected:**
- An Alert appears with the `errorMessage(error)` text (or generic "Couldn't load …" fallback). DataTable does not render.

---

## Phase 3 — Guard "Add Student" when tenant has 0 classes

### Test 3.1 — Tenant with 0 classes: click "Add student"
1. Use a tenant that has at least one program but no classes (or zero of each).
2. Open `/host/students`.

**Expected:**
- Page renders normally (header, filters, empty roster table — `useAllTenantClasses()` is fired in the background).
- The `Add student` and `Import students` buttons are **disabled** while the guard query is loading (a quick flash; if the tenant is well-warmed via `/host/classes` already visited, query is cached so this is instant).
- After load: click `Add student`.
- Modal does NOT open. Instead, an amber banner appears just below the filter row with:
  - Title: "No classes yet"
  - Body: "Create at least one Program and Class before adding students."
  - A `Go to Classes →` link.
  - A `×` dismiss button on the right.

### Test 3.2 — Tenant with 0 classes: click "Import students"
1. Same setup as 3.1.
2. Click `Import students`.

**Expected:** Same guard banner appears, modal does not open.

### Test 3.3 — Tenant with ≥ 1 class: behaviour unchanged
1. Create at least one class in the tenant.
2. Open `/host/students`.
3. Click `Add student`.

**Expected:**
- Guard banner does NOT appear.
- Modal `ManageStudentsModal` opens as before.
- `Import students` also opens the same modal in `import` mode.

### Test 3.4 — Guard banner dismiss
1. Trigger guard (Test 3.1).
2. Click the `×` button on the amber banner.

**Expected:** Banner disappears. Page remains usable.

### Test 3.5 — Guard banner CTA link
1. Trigger guard (Test 3.1).
2. Click `Go to Classes →`.

**Expected:** Routes to `/host/classes` (where Phase 2 empty-state UI prompts the user to create a program/class).

### Test 3.6 — Warm cache path (race avoidance)
1. Open `/host/classes` first (triggers `useAllTenantClasses()` and warms the cache).
2. Then open `/host/students`.

**Expected:** Buttons are enabled immediately (no loading flash). Guard logic still works (if tenant has 0 classes, guard fires; if it has any, modal opens).

---

## Cross-cutting checks

### Test 4.1 — Console hygiene
Across all the above:
- No unhandled promise rejections in Console.
- No React key warnings.
- No `[HMR]` error overlays.

### Test 4.2 — Build artifacts
Already verified during cook phase. Last Build Gate run produced:
```
○ /(dashboard/)/host/classes   ← new
○ /host/classes                ← new
○ /host/students               ← unchanged
```
If running the production build:
```powershell
cd D:\GitHub\PTE-org\pte-web
pnpm --filter tenant-web build
```
should complete with `✓ Generating static pages using 15 workers (24/24)`.

### Test 4.3 — Lint hygiene
```powershell
cd D:\GitHub\PTE-org\pte-web\apps\tenant-web
npx eslint lib/navigation.tsx lib/errorPageConstants.ts `
  'app/(dashboard)/host/classes/page.tsx' `
  'app/(dashboard)/host/classes/loading.tsx' `
  'app/(dashboard)/host/classes/error.tsx' `
  features/classes/components/ClassesListView.tsx `
  features/classes/constants/index.ts `
  features/classes/components/index.ts `
  features/studentSearch/components/StudentSearchView.tsx `
  features/studentSearch/constants/index.ts
```
Expected: zero findings on the 10 files above.

> Note: the global `pnpm lint` reports a pre-existing error in
> `features/exams/components/CreateExamWizard.tsx:85:5`
> (`react-hooks/set-state-in-effect`). That error is from the
> `dev` branch's prior commit and **not introduced by this feature**.

---

## Rollback

If a problem is found mid-test:

```powershell
cd D:\GitHub\PTE-org\pte-web\apps\tenant-web
# Revert Phase 3 (guard)
git checkout HEAD -- features/studentSearch/components/StudentSearchView.tsx features/studentSearch/constants/index.ts
# Revert Phase 2 (list view)
git checkout HEAD -- features/classes/components/index.ts features/classes/components/ClassesListView.tsx features/classes/constants/index.ts 'app/(dashboard)/host/classes/page.tsx'
# Revert Phase 1 (sidebar + route + new constants)
git checkout HEAD -- lib/navigation.tsx lib/errorPageConstants.ts 'app/(dashboard)/host/classes/' -r
```

The plan + spec files live in `pte-doc/` — they don't affect runtime.
