# Brainstorm: Manage Class — Entry Point cho luồng Program → Class → Import Student

**Date:** 2026-09-26
**Slug:** `manage-class-entry`

---

## Ideas Explored

1. **3 màn hình riêng (Program → Class → Import Student)** — user chọn, đúng tinh thần domain.
2. **Một màn Class duy nhất có phần Program thu gọn** — gọn, nhưng khó scale khi Program nhiều.
3. **Màn Class chính, drawer tạo Program lazy** — ít gọn hơn phương án 1.
4. **Giữ nguyên, chỉ thêm menu link** — không đủ, vì Modal vẫn cho nhập `className` free-text.

Đã chọn **phương án 1 + phạm vi A-only** (frontend-only, không đụng backend DTO).

## User's Direction

- Màn hình "Manage Class" phải **đứng độc lập** ở route `/host/classes`, là entry point mới.
- Khi user vào Students → bấm "Add" mà **chưa có class trong tenant** → hiện empty state + CTA sang `/host/programs`.
- Phạm vi **MVP**: chỉ frontend, **không** đụng `CreateUserRequest` / `BulkCreateUserRow`.
- Tenant-only scope (đã xác nhận ở Step 1).
- Stack đã đúng (TanStack Query + feature folder pattern) — tận dụng `features/classes/` có sẵn.

## User Stories đã chốt (xem spec.md)

- P1: Sidebar có link "Classes"
- P1: Route `/host/classes` hiển thị list tất cả class của tenant (filter theo Program)
- P1: Modal "Add Student" khóa khi tenant chưa có class nào
- P2: Search/filter Program ở màn `/host/classes`
- P2: Empty state cho Program cũng khi tenant chưa có Program

## Open Questions (cho /ck:plan)

1. **Reuse component**: `ClassDetailView` hiện nằm ở `features/classes/components/` — dùng lại luôn hay viết `ClassesListView` mới cho route `/host/classes`? Nghiêng về viết mới vì route `/host/classes` cần list all tenant classes (không phải detail của 1 class). Tuy nhiên có thể reuse pattern từ `ClassesSection.tsx` (DataTable, action buttons, status mutations).
2. ~~**Permission**: Sidebar link "Classes" cần check role gì?** → Đã xác nhận: `HOST_ROLES = ["HOST_ADMIN"]` trong `features/auth/constants.ts`. Không có STAFF/TEACHER role trong tenant-web.
3. **Existing student list**: Có cần ẩn luôn `/host/students` khỏi sidebar khi đã có entry point Classes không? Có thể KHÔNG — Students vẫn cần cho search/list toàn bộ student của tenant.

## Risks

1. **UX regression**: Những user đang quen nhập student free-text có thể bị giật. Mitigation: empty state rõ ràng + CTA 1 click.
2. **Class orphan**: Student cũ tạo bằng free-text sẽ có `className` string, không match classId nào. Mitigation: chỉ khoá modal khi tenant có 0 class; nếu có class, vẫn cho nhập free-text (MVP, không phá dữ liệu cũ).
3. ~~**API list class toàn tenant**:~~ → **Đã xác nhận: không có endpoint tenant-wide. `useAllTenantClasses()` fan-out pattern đã có sẵn. Đây không còn là risk.**
4. **Fan-out N+1**: `useAllTenantClasses()` gọi N organizations × M programs × 1 listClasses mỗi program — với MVP scale (≤ 5 orgs, ≤ 50 programs) thì OK. Nếu scale lên, cần backend endpoint tenant-wide. (Đánh dấu: accepted risk, document trong NFR.)

## Files sẽ đụng (dự kiến, sau khi verify code thật)

- `apps/tenant-web/app/(dashboard)/host/classes/page.tsx` — **mới** (không có trong code)
- `apps/tenant-web/features/classes/components/ClassesListView.tsx` — **mới** (không có trong code, pattern giống `ClassesSection.tsx`)
- `apps/tenant-web/features/classes/api/index.ts` — **không cần thêm hook** (dùng `useAllTenantClasses()` đã có)
- `apps/tenant-web/features/classes/constants/index.ts` — thêm constants cho view mới (empty state text, table headers nếu cần)
- `apps/tenant-web/lib/navigation.tsx` — thêm nav item "Classes" sau Programs
- `apps/tenant-web/features/studentSearch/components/StudentSearchView.tsx` — thêm guard `tenantClasses.length === 0` trước khi mở modal (không sửa `ManageStudentsModal.tsx`)

## Out of Scope (chốt)

- ❌ Thay `className` free-text bằng `classId` (P2 sprint sau)
- ❌ Backend DTO bắt buộc `classId`
- ❌ Đổi tên route `/host/students` hay ẩn nó
- ❌ Migrate dữ liệu student cũ sang classId
