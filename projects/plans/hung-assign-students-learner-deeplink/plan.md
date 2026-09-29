# Plan: Assign Students → Learner screen with prefill

**Feature:** Click "Assign Students" on a class row → navigate to `/host/students` with Program + Class pre-filled, auto-open Add Individually modal, breadcrumb back to class.

---

## Summary

The feature wires two existing "Assign Students" row actions (in `ClassesSection` at `/host/programs/:programId` and `ClassesListView` at `/host/classes`) to navigate to `/host/students` with `organizationPublicId`, `programPublicId`, and `classPublicId` query params. The Students page reads those params, pre-fills the Program + Class selectors, fetches the class to verify its status, and either auto-opens the `ManageStudentsModal` in "Add Individually" mode (ACTIVE class) or shows an inline blocking alert (INACTIVE/SUSPENDED). If the user cancels the auto-opened modal, the Program + Class filters are locked with a banner; clicking "Clear filter" unlocks and resets the URL. A breadcrumb always links back to the originating class detail.

Implementation spans 4 phases: (1) URL builder utility + deeplink text constants, (2) row-action wiring with `useRouter().push()`, (3) prefill logic, Suspense boundary, and sub-component extraction inside `StudentSearchView`, and (4) build/lint gate.

---

## Phase Index

| Phase | File(s) | FRs | Status |
|-------|---------|-----|--------|
| 01 — URL builder + constants | `features/classes/utils/assignStudentsUrl.ts` (new) + `features/studentSearch/constants/index.ts` | FR-02, FR-09 | ✅ completed |
| 02 — Wire row actions to navigate | `ClassesSection.tsx`, `host/classes/page.tsx` | FR-01, FR-08 | ✅ completed |
| 03 — Prefill + Suspense + sub-components | `host/students/page.tsx`, `StudentSearchView.tsx`, 3 new sub-components | FR-03, FR-04, FR-05, FR-06, FR-07 | ✅ completed |
| 04 — Build / lint / typecheck gate | — | NFR-BUILD | ✅ completed |

---

## Cross-Phase Risks

### HIGH severity

1. **Missing `programPublicId` in URL fails prefill silently.** The prefill logic reads all 3 params; if any is absent, the Program + Class dropdowns remain unselected and the modal does not open. The URL builder always emits all 3; the risk is caller-side (future misuse). **Mitigation:** Document the required params in the utility JSDoc and add a guard in Phase 03 that logs a console warning if `?classPublicId` is present but `?programPublicId` is missing.

2. **`useSearchParams()` requires a `<Suspense>` boundary in Next.js App Router.** `StudentSearchView` is a client component that reads `useSearchParams()`. Without a `<Suspense>` boundary, Next.js will throw a build error or render null on the server. Researcher B identified this as a production-breaking issue. **Mitigation:** Phase 03 wraps `StudentSearchView` in `<Suspense>` in `host/students/page.tsx`.

### MEDIUM severity

3. **`StudentSearchView` file size risk.** Currently 485 lines; Phase 03 adds ~95 lines of prefill logic + lock-filter state + banner rendering + bypass guards, offset by ~30 lines extracted into sub-components, for a net ~65 lines. Final estimate: ~545–555 lines, within the ≤600 success criterion. If additional sub-components aren't extracted cleanly, it could approach the limit. **Mitigation:** Extract `BreadcrumbBackToClass`, `LockedFilterBanner`, and `ClassBlockedAlert` as separate component files in `features/studentSearch/components/`, keeping `StudentSearchView` ≤ 555 lines.

4. **`ManageStudentsModal` `onClose` fires for both explicit cancel and backdrop click.** The current implementation does not distinguish. Phase 03 must correctly trigger filter-lock only when `manageMode` was set from a deeplink prefill, not when the user manually opened the modal. **Mitigation:** Track a `wasPrefilledByDeeplink` ref; set to `true` in the prefill `useEffect` with Strict Mode idempotency guard (`if (wasPrefilledByDeeplink.current) return;` at the top of the effect body); only lock filter in `onClose` when this ref is `true`.

5. **`router.back()` is rejected — `router.replace()` for clear-filter.** `router.back()` navigates to an unpredictable point in the history stack. `router.replace('/host/students')` is the correct approach to clear params without adding a history entry. **Mitigation:** Phase 03 uses `router.replace('/host/students')`. Browser Back after clear returns to the source class page (verified for both `ClassesSection` and `ClassesListView` paths).

### LOW severity

6. **`ClassesListView` already passes full context in `onAssignStudents`.** Unlike `ClassesSection` which only passes `() => void`, `ClassesListView` passes `{ organizationPublicId, programPublicId, classPublicId }`. The parent `host/classes/page.tsx` currently uses this to drive `ImportOrAssignModal`. Phase 02 changes the parent to `useRouter().push(buildAssignStudentsUrl(...))` instead. **Mitigation:** No structural change needed; only the parent's callback body changes.

7. **`ProgramDetailView` is `"use client"`** — can use `useRouter()` directly without prop-drilling. Phase 02 adds `useRouter` to `ProgramDetailView` and changes `ClassesSection`'s `onAssignStudents` from `() => void` to `(input: AssignStudentsContext) => void`.

8. **`classPublicId` in URL but class is INACTIVE at render time.** A race condition: user clicks Assign Students, class becomes SUSPENDED before the page mounts. Phase 03 handles this gracefully — the `useEffect` that reads `useSearchParams` also triggers a class-status check and renders the blocking alert instead of opening the modal.

---

## Out of Scope

- "Pick Existing" tab in `ManageStudentsModal`
- Server-side enforcement of prefill params (client UX only)
- Bidirectional URL sync (filter changes → update URL)
- Multi-org cross-class bulk add
- Drag-and-drop file import
- Keyboard shortcut "Add Student" from page
- Pre-fill for Import mode (only "Add Individually" auto-opens)
- Program/Class filter pre-fill from breadcrumb deep nav within the modal

---

## User Story Mapping

| Story | Priority | Phase |
|-------|---------|-------|
| Click Assign Students → navigate to Students with pre-filled filters | P1 | 01, 02 |
| Add Student modal auto-opens in "Add Individually" mode | P1 | 03 |
| INACTIVE/SUSPENDED class → blocking alert, no modal | P1 | 03 |
| Cancel modal → filter lock + banner | P1 | 03 |
| Breadcrumb "Back to {className}" always visible | P1 | 03 |
| Silent dedupe on duplicate email (server-side) | P1 | N/A (server) |
| P2: Page refresh re-applies prefill + auto-modal | P2 | 03 (URL is source of truth — refresh naturally works) |
