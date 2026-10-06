# Unhappy Case Survey — Programs / Classes / Learners (tenant-web)

> **Scope**: `apps/tenant-web` (frontend only). Branch: `hung/feat/classes-entry`.  
> **Method**: Quick static scan — read entry views, list/create/edit/status mutation flows, and learner assignment flows. No browser test yet.  
> **Status**: DRAFT for team discussion — please verify each item against backend behavior + business rules before we code fixes.

## Legend
- **Sev** = severity: `H` (high) / `M` (medium) / `L` (low) / `?` (need backend check)
- **Likely real bug?** = `yes` / `maybe` / `?` (need data)
- **Surface** = where the user sees it

---

## 1. Programs

| # | Case | Repro | Expected | Actual | Sev | Surface | Likely bug? | Notes |
|---|------|-------|----------|--------|-----|---------|-------------|-------|
| P1 | Create program with start date **after** end date | Form: pick 2026-12-01 → 2026-11-01, submit | Blocked with end-before-start error | ✅ Validator blocks it (`validateCreateProgram.ts:20`) | L | Modal | No | But: only checks date, not time-of-day if start==end at midnight |
| P2 | Create program with same start == end date | Pick identical dates, submit | Probably allowed (single-day program) | Allowed — but no warning. `new Date(endDate) <= new Date(startDate)` is strict, so end == start blocks it (`validateCreateProgram.ts:20`) | M | Modal | yes | Off-by-one: same-day program can't be created |
| P3 | Create program with only end date (no start) | Leave start empty, set end | Either auto-default or block with clear message | Blocked ("Start date is required") — OK if backend treats `null/null` as always-active | L | Modal | No | But UX could surface "leave empty for always-active" hint, since `isProgramCurrentlyActive` permits both null |
| P4 | Create program with both dates null | Leave both empty | Allowed (always-active) | **Frontend blocks** with "start/end required" — but backend may accept null/null. Inconsistent with `isProgramCurrentlyActive` semantics | H | Modal | yes | Code path: `validateCreateProgram` requires both fields; backend may not. Needs backend contract check |
| P5 | Create program, dates pick order wrong (end set first, then start after end) | Set end=2026-12-01, then start=2026-12-15. The `min` attribute on end input only constrains end → start; if user changes start after end, end may not auto-clear | End auto-clears or form re-validates | No re-validation on start change — stale end date may stay | M | Modal | yes | `CreateProgramModal.tsx:97` only sets `min` on end input; doesn't re-validate when start changes after end is set |
| P6 | Activate a program whose status was set to **SUSPENDED** then immediately re-suspended | Click suspend → click suspend again (rapid double-click) | Second click is no-op or shows toast | Possible double toast / double mutation request. The `lifecyclePending` guard should block but only if React commits between mutations | M | Detail page | maybe | `ProgramDetailView.tsx:117` disables button while `lifecyclePending`; need to verify race across back-to-back clicks |
| P7 | Archive a program that still has **classes with students** | Open Program → Archive (no warning that classes exist) | Confirm dialog should warn "this program has N classes and M students" | `PROGRAM_DETAIL_TEXT.confirmArchiveDescription` only names the program; **no mention of class/student count** | H | Detail page | yes | High-impact: silently archives a Program with active classes |
| P8 | Archive a Program then navigate via stale URL | Open program detail, archive → redirected to list. Reopen same URL (browser history) | Should show "archived, no access" error | Relies on `useProgram` returning 404 → renders `Alert`. OK if backend 404s archived programs | L | Detail page | maybe | Need to check what backend returns for archived program GET |
| P9 | Switch organization while on Programs page with one selected | Select org A (1 program), select org B (3 programs), back to A | List updates without leftover state | `selectedOrganizationPublicId` switches, `usePrograms` refetches by new orgPublicId. Looks OK but… if user has any URL deep-link `?organizationPublicId=...`, org switch via `Select` overwrites state without URL sync | L | List page | maybe | Side-effect: refresh keeps state, share-URL may mislead |
| P10 | Edit program dates to put end before start | No edit modal exists | N/A | No update flow in UI — only `useUpdateProgram` API. Probably pending work | L | API only | no | Confirm whether Edit Program is in scope |
| P11 | Filter/sort by status when Program is **INACTIVE** with null dates | List view | Should still appear | Renders row; status badge `neutral`. OK | L | List | no | |
| P12 | Program name with **leading/trailing whitespace only** | Enter "   " in name field | Blocked with "name required" | `.trim()` then check empty → blocked. OK | L | Modal | no | |
| P13 | Program name longer than typical DB limit | Enter 1000+ chars | Server validation | No client-side max-length. Server may 400. Modal shows generic error | L | Modal | no | Low — server-side rejection |

---

## 2. Classes

| # | Case | Repro | Expected | Actual | Sev | Surface | Likely bug? | Notes |
|---|------|-------|----------|--------|-----|---------|-------------|-------|
| C1 | Create Class with **empty name** (only spaces) | Modal: type "   " | Blocked | Blocked (`.trim()` check, `CreateClassModal.tsx:42`) | L | Modal | no | |
| C2 | Create Class with name same as existing in same Program | Type "12A1" twice | Allowed (no client-side uniqueness check) | Server may 400 with `duplicate name`. Modal shows error. **No confirm message about duplicate** | M | Modal | maybe | Check backend error code → if 409, surface friendly "name already in use" |
| C3 | Create Class when **no programs exist** tenant-wide | Open `/host/classes` as fresh tenant | Show "create a Program first" CTA | `ClassesListView` shows the "Get Started" empty state. `Create Class` button is disabled with tooltip. OK | L | List page | no | |
| C4 | Create Class while org picker has **no selection** | Single-org tenant: org auto-picked. Click `+ Create Class` | Modal opens with picker auto-set to first program | OK if `usePrograms` resolved. If org is still loading, the button is disabled — fine | L | List | no | |
| C5 | **Switch org** mid-`+ Create Class` modal | Open modal with org A, switch org in picker | Modal closes or picker resets to first program of new org | `setSelectedProgramPublicId("")` only happens in `onOrgChange` *before* modal opens. If org changes *while modal is open*, picker keeps stale program publicId. But `onOrgChange` only fires from the org `<Select>` not inside the modal, so currently not reachable. **Latent risk if UI ever exposes org-switch inside modal** | M | List+modal | maybe | |
| C6 | Edit Class name to empty | Edit modal: clear name | Blocked | Blocked by validator. OK | L | Modal | no | |
| C7 | **Archive Class with active roster** | Open class → kebab → Archive (no confirm dialog shown!) | Should show confirm with student count | `ClassRowActions.tsx:99-103`: `archive` action calls `mutations.archive.mutate()` **directly, no `ConfirmDialog`** | H | Class detail/list | yes | High-impact silent archive; same severity gap as P7 but at class level |
| C8 | **Archive Class while it has pending exam sessions/enrollments** | Archive class with students who have upcoming exams | Confirm dialog warning | No dialog at all | H | List+detail | yes | Same as C7 — silent data loss risk |
| C9 | **Suspend then Deactivate** without going through ACTIVE | State machine should be enforced by API. UI shows both options | Backend may reject or accept | UI shows both `activate`/`deactivate`/`suspend` based on current status — `ClassesSection.tsx:82-96`. Looks OK but no client-side guard. If backend enforces, fine | M | Dropdown | maybe | Verify backend state machine |
| C10 | Activate/Deactivate/Suspend/Archive fires twice on rapid double-click | Click twice fast | Second is ignored or queued | `useClassStatusMutations` doesn't track "in-flight" across buttons — only `mutations.X.isPending` for the specific mutation. **Race possible across buttons** (activate + suspend fired back-to-back) | M | Dropdown | yes | `pending` aggregates `isPending` of all four — should be safe if computed once. Need to verify |
| C11 | **Transfer student to a Class in a different Program** | TransferStudentModal lists all tenant classes | Allowed (matches `useAllTenantClasses` design) | OK by design. But **no warning** if target Class belongs to a different Program with different dates/dates rules | M | Transfer modal | maybe | Confirm with PM if cross-Program transfer is intended |
| C12 | **Transfer student who has pending enrollments** | Open transfer modal | Warning banner shown | `TransferStudentModal.tsx:91-105` shows pending enrollments banner. **But the `disabled` check on submit is only `!targetClassPublicId`** — doesn't block on pending enrollments | L | Transfer modal | no | By design (warning only); confirm with PM |
| C13 | **Transfer student to a non-ACTIVE target class** | Target pick includes INACTIVE/SUSPENDED classes | Either block or warn | No status filter on `targetOptions` — user can transfer to a SUSPENDED class | H | Transfer modal | yes | High-impact: student silently moved into unusable class |
| C14 | **Merge classes into one that is itself INACTIVE/SUSPENDED** | Merge modal: pick target = inactive class | Either block or warn | No status filter — destination can be any status | H | Merge modal | yes | Same severity as C13 |
| C15 | Merge modal: pick **only 1** class (program guard) | Select 1 class in selection mode, click Merge | Button disabled (need ≥2) | `ClassesSection.tsx:209`: `disabled={selectedKeys.size < 2}`. OK | L | List | no | |
| C16 | Merge modal: pick all classes (including target) | Pick all → no target is "other" — sources empty | Submit disabled | `MergeClassesModal.tsx:85`: `disabled={merge.isPending || sourceClasses.length === 0}`. OK | L | Modal | no | |
| C17 | **Split Class into a name that already exists in same Program** | Split modal: type existing class name | Server error or accepted? | No client-side dedup. May collide. | M | Split modal | maybe | Same as C2 |
| C18 | **Split Class with 0 selected** | Selection mode → click Split | Button disabled | `ClassRosterTable.tsx:176`: `disabled={selectedKeys.size < 1}`. OK | L | Roster | no | |
| C19 | **Unassign student who has pending enrollment** | Click Unassign on a student with upcoming exam | Block or warn | No warning, no confirm — silent removal | H | Roster | yes | Same severity as C7/C8/C13/C14 |
| C20 | Unassign during in-flight transfer of same student | Open Transfer modal A, open Transfer modal B (different student, same row) | At most one in flight | Each `RowActions` mounts its own mutation; multiple parallel mutations OK. **But stale state** — if A succeeds, B's `useClassRoster` cache invalidation may reorder rows mid-selection | L | Roster | maybe | |
| C21 | **Inactive class: Assign Students** dropdown shown disabled | Click Assign Students on INACTIVE row | Dropdown item disabled | `ClassesListView.tsx:77-80`: `disabled: assignDisabled` + tooltip. OK | L | Dropdown | no | |
| C22 | **No lecturer assigned + class becomes ACTIVE** | Create class, don't assign lecturer, activate | Should not block | No client guard. Likely intended. | L | Detail | no | |
| C23 | **Assign Lecturer email already in tenant (non-EXAMINER role)** | Create new lecturer with existing email | Backend rejects | `useCreateLecturerAccount` doesn't pre-check email uniqueness. Backend 409 will surface. **Account may be created first then assign fails** — see recovery in modal (`AssignLecturerModal.tsx:84-87`) which switches to "existing" tab and preselects. OK if account creation itself fails first. | M | Assign modal | maybe | Verify backend order of operations |
| C24 | Assign Lecturer: **tab switch after starting submit** | On "new" tab, fill form, click Submit, then click "existing" tab before mutation resolves | Two mutations may interleave | `handleTabChange` calls `assignLecturer.reset()` + `createLecturer.reset()`. OK | L | Modal | no | |
| C25 | **Reset Lecturer password (rotate) via `useGenerateStudentCredentials` only works for Student, not Lecturer** | Click "reset password" on a Lecturer row | Should rotate lecturer password | `userManagement/api.ts` only exports `useGenerateStudentCredentials` and `useSendUserCredentials`. No `useResetLecturerPassword`. Verify if missing feature or by design | M | (UI not shown in userManagement — may be elsewhere) | ? | |
| C26 | **Roster export to Excel includes archived/deleted students** | Export from a class after some unassigns | Excludes unassigned | `ClassRosterTable.tsx:144` exports `roster` which is `useClassRoster` result — server already filters. OK | L | Export | no | |
| C27 | **Bulk import Excel with rows that already exist as students** | Excel has email "x@y.com" which is already a tenant student | Backend dedup? | `bulkCreateUsers` may skip or merge; `skipped` rows are shown via `SkippedRowsReport`. **Verify backend behavior** — if deduped by email, those rows silently become re-assigned, not skipped | H | Import tab | ? | High: silent behavior — confirm with backend team |
| C28 | **Import Excel with rows assigned to a different Class (via `className` column)** | Excel row has className = "12A1" but user is in class "12A2" | Reject or warn? | `RosterRow.className` is passed to backend; backend may ignore or assign to named class. **No client warning about cross-class assignment** | H | Import tab | yes | **[fixed 2026-10-04]** — Phase 3 of `tenant-programs-classes-learners`. Added `IMPORT_HELP.classNameOverride` copy under the dropzone (via new `helperText` prop on `_RosterDropzone`). Still a copy-level warning only, not a hard block — the assign decision remains the backend's. |
| C29 | **PendingClassAssignmentBanner stale across class change** | Create accounts in Class A, switch to Class B without dismissing | Banner for A persists in B? | `pending` is per-`classPublicId` (sessionStorage keyed). **But the modal is one instance per page**; if user re-opens the modal on Class B, `loadPendingClassAssignment(classPublicId)` reads Class B's slot. OK | L | Modal | no | |
| C30 | **Dismiss pending banner but keep accounts created** | Click "Dismiss" in banner | Accounts remain unassigned, credentials retained in banner until tab refresh | Banner state is cleared from sessionStorage. **Credentials are gone from UI** (no re-download) but accounts still exist on backend. User has lost track | M | Modal | maybe | |
| C31 | **Add Individually: form fields empty, click submit** | Open Add tab → Submit | Validation errors shown | **No client-side validation** for required fields (email, fullName). Server-side error is shown | M | Add tab | yes | Should mirror `validateCreateLecturer`-style validator for student fields |
| C32 | **Pick Existing: search/filter missing for large rosters** | Tenant has 500 students | Show all in `<Select>` | `Select` renders all options; no search. UX may break at scale | M | Existing tab | maybe | Consider combobox/async search |
| C33 | **Pick Existing tab: list excludes already-assigned students** | Filter via `assignedIds` from `useClassMemberships` | Should exclude | `ImportOrAssignModal.tsx:216-219` filters correctly. OK | L | Existing tab | no | |

---

## 3. Learners (userManagement)

| # | Case | Repro | Expected | Actual | Sev | Surface | Likely bug? | Notes |
|---|------|-------|----------|--------|-----|---------|-------------|-------|
| L1 | **Send credentials to student with no email** | Student has `email = null` | Block or warn | `useSendUserCredentials` no client check; backend may reject. **No UX before send** | H | (modal) | yes | Verify backend; if no email allowed, this is dangerous |
| L2 | **Reset student password: backend generates new pw, frontend must show it once** | Click "Reset password" | Show temporary password modal | `useGenerateStudentCredentials` invalidates but doesn't show generated password — caller responsible | M | (modal) | maybe | Check `GeneratedCredentialsModal` wires this correctly |
| L3 | **Reset password while another tab also resets** | Two Host tabs both reset same student | Last write wins | Race possible — backend decides. **No client warning** | L | (modal) | no | |
| L4 | **Suspend a student account** | Click suspend on user | Should reflect status | `userManagement` only has 2 hooks (send/rotate creds). **No suspend hook** — may live elsewhere | M | (modal) | ? | Out of scope for this audit? Confirm |
| L5 | **Bulk-import-created student missing email** | Excel row with email=null | Either reject or generate synthetic email | `bulkCreateUsers` accepts `email: null` per `rosterImport.ts:51`. Student created without email. **Then can't receive credentials email later** | H | Import tab | yes | Same severity as L1 |
| L6 | **Learner screen deeplink with invalid params** | Open `/host/students?...&programPublicId=INVALID` | Render error or fall back to list | `StudentSearchView` reads search params via `useAssignStudentsDeeplink.ts`. **Verify empty/invalid handling** | M | Students page | ? | |
| L7 | **Student transferred from Class A → B; UI in A still shows them briefly** | Transfer student, navigate back to A | Should disappear after refetch | `useClassRoster` key `CLASS_MEMBERSHIPS_QUERY_KEY` invalidated on transfer. OK if cache invalidates fast | L | Roster | no | |

---

## 4. Cross-cutting / API/integration

| # | Case | Repro | Expected | Actual | Sev | Likely bug? | Notes |
|---|------|-------|----------|--------|-----|-------------|-------|
| X1 | `useAllTenantClasses` fans out N×M×K requests | Tenant with 5 orgs × 5 programs × 10 classes | OK at scale, problematic at scale | Comment acknowledges this (`classes/api/index.ts:198-201`). **No upper bound, no rate limiting** | M | Transfer modal | maybe | Confirm perf at scale |
| X2 | `useProgramRoster` reads `TENANT_USERS_QUERY_KEY` cache directly | First render before users loaded | `enabled: students.data !== undefined` gates correctly | OK | L | Roster | no | |
| X3 | Query keys inconsistency | Multiple features share `TENANT_USERS_QUERY_KEY` but each defines locally | Consistent | `["tenantUsers"]` imported from `@/features/exams/constants` — odd coupling | L | API hooks | no | Code smell, not a bug |
| X4 | `errorMessage(err)` fallback strings missing | Errors without `message` | Generic fallback | `examoperations/errorMessage.ts` likely handles. OK if so | L | All | no | |
| X5 | **Tenant without any Program, then trying to add a Class via deep-link** | Bookmark `/host/classes?preselectProgram=...` | Friendly empty state | `ClassesPage` reads `usePrograms(orgPublicId)` and disables Create button when `programOptions.length === 0`. OK | L | List | no | |
| X6 | **Bulk assign after merge — old `pending` banner references merged-into source** | Merge 2 classes into A, then re-open ImportOrAssignModal | Banner should not show merged source's pending | `pending` is keyed by `classPublicId`. If merged source had pending, banner only shows on that source — but source may no longer exist. **Verify backend behavior** | M | Modal | ? | |
| X7 | **No abort/cancel on in-flight mutation when navigating away** | Start Archive Program → click "Back to Programs" mid-mutation | Should abort or queue | `useMutation` has no `AbortController` wiring. Mutation completes in background even after navigation. Toast may show on a page that's not the detail. | L | All | maybe | |
| X8 | **All classes listing `studentCount` column shows "—" placeholder** | `/host/classes` table | Should show count or hide column | `ClassesListView.tsx:184`: `cell: () => CLASSES_LIST_TEXT.studentCountPlaceholder` — placeholder hardcoded | M | List | yes | **[fixed 2026-10-04]** — Phase 3 of `tenant-programs-classes-learners`. Column removed from the `columns` array and the orphaned `CLASSES_LIST_TEXT.studentCountPlaceholder` constant deleted. `TenantClassOption` carries no count, so removal (not population) was the honest fix. |
| X9 | **Search/filter on Classes list** | Tenant has 100 classes | Filter UI | `programFilter` exists; no text search | L | List | no | |
| X10 | **`PickProgramToAddClass` per-row CTA + main `+ Create Class` button** | Empty state has row CTA, top has button too | Both lead to same modal | OK if consistent. Verify | L | List | no | |

---

## 5. Cross-check items pending backend behavior

These are flagged with `?` because they depend on backend contract:

- **P4**: can programs have both `startDate` and `endDate` null? Frontend says no, backend may say yes.
- **P8**: GET on archived program returns 404 or 200?
- **C2 / C17**: backend uniqueness on class name within program?
- **C9 / C10**: backend state machine for class status?
- **C13 / C14 / C19**: backend allows transfer/merge/unassign into INACTIVE/SUSPENDED targets?
- **C27 / C28 / X6**: backend behavior on bulk import dedup & className routing?
- **L1 / L5**: backend behavior when student has no email?
- **L4**: is learner suspend a Host capability at all?
- **C25**: where does lecturer password reset live?

---

## Suggested next step

1. Walk through this list in the team sheet.
2. Mark each item: **fix now** / **fix later** / **defer / by design** / **needs backend answer**.
3. For "fix now" items, group into a phase (e.g. Phase A: archive confirms with counts; Phase B: target status guards; Phase C: form validators).
4. Then I propose a `ck:plan` for the agreed scope.
