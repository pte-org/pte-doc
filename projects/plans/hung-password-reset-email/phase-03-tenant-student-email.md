# Phase 03 — tenant-web: Send password via email cho học viên

**Stories:** P1 #1 (UI) · **FR:** 03, 04
**Status:** [ ]
**Depends on:** contract của Phase 01

## Overview

Thêm mục **Send password via email** vào `ActionMenu` của học viên trong danh sách học viên, giữa "Generate password" và "Suspend".

## Files

- `apps/tenant-web/features/studentSearch/components/StudentSearchView.tsx`: thêm mục menu và hộp xác nhận.
- `apps/tenant-web/features/studentSearch/constants/index.ts`: chuỗi mới (`sendPasswordEmail`, tiêu đề/mô tả xác nhận, toast thành công, tooltip khi thiếu email, thông báo 409).
- Chuỗi i18n `tenant.students.*` (VI/EN) ở nơi các key `tenant.students.generatePassword` đang được định nghĩa.
- Tái dùng hook `useSendCredentialsEmail` (hoặc tên tương đương) trong `features/userManagement/api.ts`, đang gọi `sendCredentialsEmail` của `@pte/api-client`. Không tạo hook trùng.

## Steps

1. Thêm mục menu. `disabled` khi học viên không có email, kèm tooltip "Học viên chưa có email". Ẩn mục khi học viên SUSPENDED, giống cách "Generate password" đang xử lý.
2. Bấm → `ConfirmDialog` (component `@pte/ui` mà Suspend đang dùng). Nội dung nêu rõ mật khẩu hiện tại sẽ mất hiệu lực và học viên phải đổi ở lần đăng nhập đầu.
3. Thành công → toast "Đã gửi mật khẩu tạm tới {email}". **Không** hiện mật khẩu, khác với `GeneratedCredentialsModal`.
4. Lỗi 409 `STUDENT_ATTEMPT_IN_PROGRESS` → toast thông báo thân thiện. Áp dụng cả cho "Generate password" đang có.
5. Kiểm tra màn hình chi tiết học viên (`features/studentDetail`): nếu có nút Generate password ở đó thì thêm nút này tương ứng.

## Design Constraints

- Tuân theo `pte-web/CLAUDE.md` và `AGENTS.md`: không hardcode chuỗi trong JSX, dùng `ActionMenu`/`ConfirmDialog` của `@pte/ui` mà không đổi style, file ≤ 300 dòng (`StudentSearchView.tsx` gần ngưỡng thì tách hook menu ra file riêng), gọi API qua TanStack Query.

## Tests

- Vitest: menu có mục mới; disabled khi không có email; xác nhận gọi mutation đúng `publicId`; 409 hiện đúng thông báo.

## Quality and Testing State

- Quality: not evaluated
- Testing: not started
