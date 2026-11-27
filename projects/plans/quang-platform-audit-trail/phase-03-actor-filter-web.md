# Phase 03: Lọc theo người ở màn audit và lối vào từ màn nhân sự

Repo: `pte-web` (vendor-web, `packages/api-client`). Trạng thái: **xong (2026-11-25)**. Phụ thuộc: phase 01.

## Việc cần làm

1. `packages/api-client`: thêm `actorId`, `aggregateId` vào params của request platform audit; thêm `actorRole`, `hasStateChange`
   vào type; thêm request + type cho `GET /platform/audit-logs/{publicId}`.
2. `features/auditLog` (`PlatformAuditLogView`):
   - Ô lọc **Người thực hiện** dùng `GET /api/v1/platform-users/directory`, có tìm kiếm.
   - Đọc/ghi `actorId` trên URL (`?actorId=`) để link chia sẻ được và mở từ màn khác.
   - Cột người thực hiện hiện tên (directory), vai trò lúc thao tác (`actorRole`).
   - Dòng có `hasStateChange` có nút **Xem thay đổi** mở drawer diff (dùng chung component của phase 04).
3. `features/platformUsers` (`_PlatformUserRowActions`): thêm mục **Xem lịch sử thao tác** (icon lịch sử), link tới
   `/admin/audit-log?actorId={publicId}`. Hiện cả với tài khoản được bảo vệ (đây là thao tác chỉ đọc), nên tách khỏi nhánh
   `isProtected` đang trả badge.
4. Chuỗi hiển thị vào `constants.ts` của feature, bản dịch vào `features/i18n/adminCopy.ts`.

## Tiêu chí hoàn thành

- `tsc`, `eslint`, vitest của `auditLog`, `platformUsers` xanh.
- Unit test: mapping params có `actorId`; URL `?actorId=` khởi tạo bộ lọc.
- Không kiểm tra bằng trình duyệt (người dùng tự kiểm).
