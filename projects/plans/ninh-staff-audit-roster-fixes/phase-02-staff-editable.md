# Phase 2: Cờ `editable` cho tài khoản Staff và giao diện tương ứng

Status: Completed

## Requirements

- `ExamStaffAccountView` có cờ `editable`: `false` khi Staff thuộc từ 2 tổ chức trở lên (không do một tổ chức sở hữu riêng).
- Trên giao diện Host, nút "Chỉnh sửa" bị ẩn hoặc vô hiệu khi `editable = false`, kèm dòng giải thích.
- Nếu vẫn nhận lỗi 403 khi lưu, hiện thông báo riêng (không phải "Có lỗi xảy ra").

## Design Constraints

- Quy tắc quyết định `editable` đặt ở một chỗ (`ExamStaffAccountService`), dùng chung cho `update`.
- Thêm trường vào cuối record để không đổi thứ tự các trường hiện có.
- Chuỗi hiển thị nằm trong bộ `text.*` của màn staff, có cả tiếng Việt và tiếng Anh.

## Related files

- `pte-api/app/src/main/java/com/pte/identity/dto/response/ExamStaffAccountView.java`
- `pte-api/app/src/main/java/com/pte/identity/internal/service/ExamStaffAccountService.java`
- `pte-web/apps/tenant-web/features/examStaff/detail/components/StaffAccountTab.tsx`
- `pte-web/apps/tenant-web/features/examStaff/detail/hooks/useStaffAccountForm.ts`
- Các file text và kiểu dữ liệu của `examStaff` trong `tenant-web` và `@pte/api-client` (nếu có kiểu sinh sẵn)

## Steps

1. Thêm `boolean editable` vào view; `view(member)` điền từ `directory.isExclusivelyOwned(member)`.
2. `update` dùng cùng điều kiện (hành vi không đổi).
3. UI: ẩn nút Sửa khi `!account.editable`, hiện ghi chú; map lỗi `forbidden` sang chuỗi riêng.
4. Test backend cho cờ; test hook nếu có test hiện hữu.

## Quality/Testing State

- Test đơn vị backend; `tsc` và test của `tenant-web` cho `examStaff`.
