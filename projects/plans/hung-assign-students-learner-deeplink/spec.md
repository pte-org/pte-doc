# Spec: Assign Students → Learner screen with prefill

**Date:** 2026-09-27
**Status:** Draft

---

## Problem Statement

Hiện tại, khi Host bấm nút **Assign Students** trên row class (cả `ClassesSection` ở `/host/programs/:programId` và `ClassesListView` ở `/host/classes`), nó mở `ImportOrAssignModal` ngay tại chỗ. Modal này chỉ cover việc pick existing/import/add individually trong phạm vi class — không có context nào để nhìn được student roster hiện tại trong class đó, không có search, không có link "back to class", không có cách nào xem/trước/sau enrollment.

Mong muốn: Host bấm Assign Students → navigate sang `/host/students` với filter program + class được prefill, breadcrumb quay lại class detail, modal `ManageStudentsModal` auto-open ở chế độ Add Individually để host có thể thao tác trên cùng một learner roster context.

---

## User Stories

<!-- P1 = MVP (must ship), P2 = nice-to-have, P3 = future/out-of-scope -->

- **[P1]** As a Host, when I click **Assign Students** on a class row, I want to be taken to the Students page with that class's program + class pre-selected in the filters so that I don't have to re-pick filters I've already committed to.
  Accepted when: Click `Assign Students` → URL trở thành `/host/students?organizationPublicId={orgId}&programPublicId={programId}&classPublicId={classId}`. Page render với 3 Select filter khớp URL, breadcrumb `← Back to P.304` xuất hiện ở đầu.

- **[P1]** As a Host, when the Students page opens with a pre-filled class, I want the Add Student modal to auto-open in "Add Individually" mode so that I can start adding students right away.
  Accepted when: `ManageStudentsModal` mount với `initialMode="add"` (Add Individually tab), backdrop + form fields visible ngay sau page load ≤ 200ms sau khi URL parsed.

- **[P1]** As a Host, when a class is INACTIVE/SUSPENDED, I want the prefill to be blocked with an inline error so I don't accidentally add students to a class that's not accepting them.
  Accepted when: Class ở URL có status ≠ ACTIVE → page không auto-open modal, hiển thị inline Alert tone="warning" ngay dưới PageHeader: `Class {className} is {status}. Activate it from the Program detail before assigning students.`, plus breadcrumb vẫn show để user có đường quay lại.

- **[P1]** As a Host, when I cancel the auto-opened modal, I want the filter lock + a banner telling me how to clear it so I don't accidentally keep the locked filter and add students to the wrong class.
  Accepted when: After cancel modal → `programPublicId` + `classPublicId` locked ở current values (không cho đổi qua Select dropdown), banner xuất hiện: `Showing students for {className}. Clear filter to add to other classes.` Banner có nút `Clear filter` → unlock + refresh table với tất cả students.

- **[P1]** As a Host, when I'm done adding students, I want a back link to return to the class detail page where I came from so I can continue managing that class.
  Accepted when: Breadcrumb `← Back to {className}` luôn visible ở đầu page (kể cả khi chưa có params), click → `/host/programs/:programId/classes/:classId?organizationPublicId=...`.

- **[P1]** As a Host, when students already in this class collide with new import, I want silent dedupe so the workflow doesn't break on partial duplicates.
  Accepted when: Khi tạo students mới mà email đã tồn tại trong organization → server không tạo duplicate, không hiển thị error UI trong modal. Roster table reload sau khi modal đóng.

- **[P2]** As a Host, when I refresh the Students page after navigating from Assign Students, I want the same prefill + auto-modal to re-apply so I can recover from accidental refresh.
  Accepted when: Refresh page trên URL có params → vẫn prefill + auto-open modal. Cần accept minor UX cost (modal mở lại) để được consistent URL behavior.

- **[P3]** _(out of scope)_
  - Thêm tab "Pick Existing" vào ManageStudentsModal (chỉ có "add" + "import" mode)
  - URL sync hai chiều (filter changes → replace URL)
  - Multi-org cross-class bulk add
  - Drag-drop file from desktop
  - Keyboard shortcut "Add Student" từ page

---

## Functional Requirements

1. **FR-01**: 2 row action sources có `onAssignStudents` handler thay đổi từ `setImportClassId(...)` sang `navigateToAssignStudents(organizationPublicId, programPublicId, classPublicId, className)`.
   - `ClassesSection.tsx` (`ClassRowActions.props.onAssignStudents`)
   - `ClassesListView.tsx` (`ClassRowActions.props.onAssignStudents`)

2. **FR-02**: New helper `buildAssignStudentsUrl(...)` ở `features/classes/utils/assignStudentsUrl.ts` — returns `/host/students?organizationPublicId={o}&programPublicId={p}&classPublicId={c}`. Dùng `URLSearchParams` để avoid manual encoding.

3. **FR-03**: `StudentSearchView` đọc 3 search params qua `useSearchParams()` hook (Next.js App Router). Khi `searchParams.classPublicId` có value:
   - Set `selectedOrganizationPublicId = searchParams.organizationPublicId`
   - Set `programPublicId = searchParams.programPublicId`
   - Set `classPublicId = searchParams.classPublicId`
   - Trigger useEffect để fetch class → check status
   - Nếu status === "ACTIVE" → set `manageMode = "add"` (modal auto-open)
   - Nếu status !== "ACTIVE" → set `classBlockedReason = status` (show inline warning, no modal)

4. **FR-04**: Khi `manageMode` đã set từ prefill, render breadcrumb **above** `PageHeader`:
   ```tsx
   {prefilledClassName && (
     <Link href={`/host/programs/${programPublicId}/classes/${classPublicId}?organizationPublicId=${organizationPublicId}`}>
       ← Back to {prefilledClassName}
     </Link>
   )}
   ```
   Style như `text-action underline text-sm font-medium`.

5. **FR-05**: Khi user cancel `ManageStudentsModal` (close handler hoặc backdrop click) **and** classPrefilled=true → set `classFilterLocked = true`. Select dropdowns Program + Class bị disabled. Banner render ở top của filter row:
   ```
   <Alert tone="info">
     Showing students for {className}. Clear filter to add to other classes.
     <button onClick={clearLockedFilter}>Clear filter</button>
   </Alert>
   ```

6. **FR-06**: `clearLockedFilter()`:
   - Set `classFilterLocked = false`
   - Clear `programPublicId`, `classPublicId`
   - Call `resetPage()`
   - Clear `searchParams` qua `router.replace('/host/students')` để URL không còn prefill

7. **FR-07**: Inline error/warning khi class INACTIVE/SUSPENDED + prefill có classId:
   ```tsx
   <Alert tone="warning">
     Class {className} is {status}. Activate it from the Program detail before assigning students.
   </Alert>
   ```
   Render cùng vị trí với banner (top of filter row). Vẫn giữ breadcrumb `← Back to {className}`.

8. **FR-08**: 2 source components (ClassesSection + ClassesListView) wrap `onAssignStudents` để build URL + navigate bằng `next/navigation` `useRouter().push(...)`. Row `ClassRowActions` chỉ nhận callback signature `(className: string) => void` — parent quyết định URL chi tiết.

9. **FR-09**: Constants ở `features/studentSearch/constants/index.ts` thêm:
   ```ts
   ASSIGN_DEEPLINK_TEXT = {
     backToClass: (name: string) => `← Back to ${name}`,
     lockedFilterBanner: (name: string) =>
       `Showing students for ${name}. Clear filter to add to other classes.`,
     clearFilter: "Clear filter",
     classBlocked: (status: string, name: string) =>
       `Class ${name} is ${status}. Activate it from the Program detail before assigning students.`,
   }
   ```

10. **FR-10**: Tests: nếu URL có `classPublicId` không trỏ tới class hợp lệ (server returns 404 hoặc empty) → page gracefully degrade về unfiltered state (không crash).

---

## Non-Functional Requirements

- **Performance**: Prefill + auto-open modal phải xảy ra ≤ 200ms sau khi page paint đầu tiên. Sử dụng `useEffect` synchronous đọc `useSearchParams`, không qua fetch bất đồng bộ để khởi tạo state.
- **Accessibility**: Breadcrumb là nav landmark (`<nav aria-label="Back to class">`). Banner có `role="region"` + `aria-live="polite"`. Filter lock chỉ là visual disabled, không phải hard block — screen reader vẫn có thể dùng arrow keys để thay đổi, nhưng button click được disable.
- **Type safety**: `searchParams` parse với `String(...)` + fallback `""` để tránh undefined types. Type `SearchParams = { organizationPublicId?: string; programPublicId?: string; classPublicId?: string }`.
- **i18n**: Tất cả user-facing strings (banner, alert, breadcrumb) qua constants. Không hardcode.
- **Build**: `pnpm --filter tenant-web build` PASS, `tsc --noEmit` clean, `eslint` clean.

---

## Success Criteria

- [ ] **Prefill**: Click Assign Students từ row P.304 → page render với Program = "Toeic Program A", Class = "P.304" đã chọn trong ≤ 500ms.
- [ ] **Auto-modal**: `ManageStudentsModal` auto-open `initialMode="add"` modal xuất hiện (không phải import, không phải pick existing).
- [ ] **Breadcrumb**: `← Back to P.304` visible từ lúc page load, link về program detail.
- [ ] **Cancel → lock**: Close modal → banner xuất hiện + 2 Select Program + Class bị disabled.
- [ ] **Clear filter**: Click `Clear filter` trong banner → unlock + clear filter + refresh table + URL trở về `/host/students` không params.
- [ ] **Block inactive**: Class INACTIVE/SUSPENDED + URL có classId → page render Alert warning + KHÔNG auto-open modal. Breadcrumb vẫn hiện.
- [ ] **Build**: `pnpm --filter tenant-web build` PASS, `tsc --noEmit` clean, `eslint` clean.
- [ ] **File size**: `StudentSearchView.tsx` ≤ 600 dòng (currently 485), `ClassesSection.tsx` ≤ 300 (currently 288), `ClassesListView.tsx` ≤ 300 (currently 293).

---

## Out of Scope

- Thêm tab "Pick Existing" vào ManageStudentsModal
- Server-side enforcement của prefill params (chỉ client UX, server đã có validation riêng qua `enrollment.create`)
- URL-based browser history navigation (không push state khi user thay đổi filter)
- Pre-fill cho **Import** mode (chỉ auto-open Add Individually; Import phải chọn file)
- Program/Class filter từ breadcrumb deep nav trong modal (hiện chỉ trên page level)

---

## Assumptions

- `useSearchParams` từ `next/navigation` hoạt động ở Client Component boundary của StudentSearchView (đã là `"use client"` — verified).
- `useRouter().replace(...)` để clear URL khi unlock filter an toàn với App Router (không push history entry).
- `useMyOrganizations()` returns sync khi page mount (cache warm) — set `selectedOrganizationPublicId` qua useEffect khi URL param có value.
- Server cho phép query `useClasses(orgId, programId)` khi `programId` chỉ định → sẽ fetch single class metadata bao gồm status. Nếu endpoint không return status cho class, fallback dùng `useClasses` list để find class object.
- Tenant ràng buộc "must have ACTIVE class to add students" đã có guard ở `StudentSearchView` (see `trySetManageMode`). Prefill sẽ re-use guard.

---

## [NEEDS CLARIFICATION]

_(Section trống — tất cả đã chốt trong brainstorm)_
