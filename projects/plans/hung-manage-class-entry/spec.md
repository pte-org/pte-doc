# Spec: Manage Class Entry Point

**Date:** 2026-09-26
**Status:** Draft
**Slug:** manage-class-entry

---

## Problem Statement

Hiện tại ở tenant-web, user có thể thêm student bằng cách nhập `className` dạng free-text ngay tại `/host/students`. Luồng đúng theo domain phải là **Program → Class → Import Student**. Màn "Manage Class" chưa có entry point độc lập nên user không thấy/quen thuộc với luồng đúng, dẫn đến dữ liệu student không gắn với classId chuẩn.

---

## User Stories

- **[P1]** As a **host admin**, I want to **see a "Classes" link in the sidebar** so that I can navigate to class management as a first-class concept.
  Accepted when: Sidebar shows "Classes" item, clicking it routes to `/host/classes` without console error.

- **[P1]** As a **host admin**, I want to **see all classes of my tenant at `/host/classes`** so that I can pick a class before adding students.
  Accepted when: Route `/host/classes` renders a list of all classes (across all programs) of the current tenant; each row shows class name, program name, student count, status.

- **[P1]** As a **host admin**, I want to **be blocked from opening "Add Student" modal when my tenant has zero classes** so that I am forced to follow the correct Program → Class → Student flow.
  Accepted when: When tenant has 0 classes, clicking "Add Student" shows an empty state with a CTA "Tạo Program & Class trước" linking to `/host/programs`. Modal không mở.

- **[P2]** As a **host admin**, I want to **filter classes by Program on `/host/classes`** so that I can quickly find classes in a large tenant.
  Accepted when: A Program filter dropdown is visible at top of `/host/classes`; selecting a program filters the list to only that program's classes.

- **[P2]** As a **host admin**, I want to **see an empty state at `/host/classes` when tenant has 0 programs** so that I know to create a program first.
  Accepted when: Empty state shows "Chưa có Program nào" + CTA "Tạo Program" linking to `/host/programs`.

- **[P3]** _(out of scope) Reuse existing `/host/programs/[publicId]/classes/[classPublicId]` flow as the only entry point. For MVP, both routes work independently._

---

## Functional Requirements

1. **FR-01**: Sidebar (file `lib/navigation.tsx`) phải có item "Classes" với route `/host/classes`, đặt ngay sau "Programs".
2. **FR-02**: Route `/host/classes/page.tsx` (Next.js App Router) render `<ClassesListView />`.
3. **FR-03**: `<ClassesListView />` gọi hook `useAllTenantClasses()` (TanStack Query, đã có sẵn tại `features/classes/api/index.ts`) để fetch toàn bộ class của tenant qua pattern fan-out `Organizations → Programs → Classes` ở client, có filter `programPublicId` optional. Hook trả về `TenantClassOption[]` đã bao gồm `programName`, `className`, `status`, `organizationPublicId`, `programPublicId`, `classPublicId`.
4. **FR-04**: Mỗi row class hiển thị: class name (link đến class detail), program name, student count (hiện tại chưa tính real-time count — hiển thị "—"), status (`ACTIVE`/`INACTIVE`/`SUSPENDED` — dùng `CLASS_STATUS_VARIANT` đã có), action menu (View / Edit / Activate / Deactivate / Archive — dùng `useClassStatusMutations` đã có).
5. **FR-05**: Empty state khi `classes.length === 0` AND tenant has 0 programs → CTA "Tạo Program".
6. **FR-06**: Empty state khi `classes.length === 0` AND tenant has programs but no classes → CTA "Tạo Class". CTA điều hướng tới `/host/programs/{programPublicId}/classes?organizationPublicId={organizationPublicId}` của **program đầu tiên** nếu tenant chỉ có 1 program; nếu ≥ 2 programs, hiển thị `Select` để user chọn program trước khi navigate. (Class scope thuộc về program, không tạo trực tiếp ở `/host/classes`.)
7. **FR-07**: Trong `StudentSearchView.tsx`: thêm check `tenantClasses.length === 0` trước khi set `manageMode` thành `"add"` — nếu tenant chưa có class nào, gọi `setManageMode(null)` và hiện Alert empty state với CTA "Tạo Program & Class trước" link đến `/host/programs`. Modal không mở. Lưu ý: `<ManageStudentsModal>` nhận prop `open: boolean` nên parent hoàn toàn kiểm soát khi nào modal render.
8. **FR-08**: Permission: link "Classes" chỉ hiển thị nếu user có role `HOST_ADMIN` (không có STAFF role trong tenant-web — dùng `HOST_ROLES = ["HOST_ADMIN"]` từ `features/auth/constants.ts`).

---

## Non-Functional Requirements

- **Performance**: List ≤ 500 class phải render dưới 1s p95 (server fetch + client render).
- **Security**: Fan-out API `Organizations → Programs → Classes` thực hiện ở client — các endpoint `listClasses` đều scoped theo `organizationPublicId` (backend enforces), nên không lộ class của tenant khác.
- **Availability**: Không đụng backend schema/DTO; chỉ dùng TanStack Query hooks đã có và endpoint `listClasses` đã có qua `useAllTenantClasses()` (fan-out pattern).

---

## Success Criteria

- [ ] Sidebar có link "Classes" xuất hiện cho đúng role.
- [ ] Navigate `/host/classes` load thành công, list đúng số class trong DB.
- [ ] Filter by program hoạt động, update list trong < 500ms.
- [ ] Mở modal "Add Student" khi tenant 0 class → hiện empty state, không có form nhập.
- [ ] Mở modal "Add Student" khi tenant có class → mở bình thường như cũ (không phá UX cũ).
- [ ] Build + lint + typecheck pass sau khi thêm code.

---

## Out of Scope

- Đổi `className` free-text → `classId` lookup ở frontend (để P2).
- Backend DTO bắt buộc `classId`.
- Migrate dữ liệu student cũ (free-text className).
- Ẩn route `/host/students` khỏi sidebar.
- Viết test e2e (chỉ manual verify cho MVP này).

---

## Assumptions

- `useAllTenantClasses()` (TanStack Query, `features/classes/api/index.ts`) đã có sẵn — fan-out pattern `Organizations → Programs → Classes` thay vì endpoint tenant-wide. Không cần viết hook mới.
- Backend **không có** endpoint `GET /api/v1/classes?tenantId=` — không cần verify nữa.
- `useSession()` hook đã có, cung cấp `tenantId` và `roles`; dùng `useOrgLabels()` cho `program`/`class` label theo org-type.

---

## [NEEDS CLARIFICATION]

- [x] ~~Backend có endpoint `GET /api/v1/classes?tenantId=` chưa, hay phải gọi nested qua programs?~~ → **Đã xác nhận: không có endpoint tenant-wide. Dùng `useAllTenantClasses()` fan-out pattern (đã có trong code).**
- [x] ~~Role guard cho nav item: hiện chỉ `HOST_ADMIN` trong `HOST_ROLES`. STAFF/TEACHER có cần thêm quyền không?~~ → **Đã xác nhận: HOST_ADMIN only. STAFF/TEACHER không có trong tenant-web hiện tại — chỉ extend khi có feature yêu cầu.**
