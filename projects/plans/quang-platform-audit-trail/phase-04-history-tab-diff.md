# Phase 04: Tab Lịch sử trên chi tiết câu hỏi và template

Repo: `pte-web` (vendor-web). Trạng thái: **xong (2026-11-25)**. Phụ thuộc: phase 01, 02.

## Việc cần làm

1. Component dùng chung `features/auditLog/components/AuditChangeDiff.tsx`:
   - Nhận `beforeState`, `afterState` (object). So sánh theo đường dẫn field; hiển thị chỉ các field đổi: tên field, giá trị cũ
     (đỏ), giá trị mới (xanh) theo token màu của design system (không mã màu thô).
   - Mảng option/item: so theo `orderIndex` (hoặc khóa ổn định), đánh dấu thêm/xóa/sửa.
   - Hiện nhãn "Đã cắt bớt" khi gặp `truncated: true`.
   - Hàm diff thuần nằm ở `features/auditLog/utils/diffAuditState.ts` để test riêng.
2. Hook `useAuditHistory(aggregateType, aggregateId)` gọi list với `aggregateId`, và `useAuditEntry(publicId)` cho chi tiết.
3. Trang `/admin/questions/[publicId]`: thêm tab **Lịch sử** gồm hai phần:
   - **Các phiên bản**: từ `GET /api/v1/questions/{publicId}/revisions` (API mới, xem phase 02 "Kết quả xác minh"), liệt kê
     revision cùng nhóm; chọn hai bản để so sánh nội dung + đáp án bằng `diffAuditState` trên hai trạng thái dựng từ chi tiết câu hỏi.
     Mặc định so bản hiện tại với bản nó thay thế (`supersedesPublicId`).
   - **Nhật ký thao tác**: dòng thời gian audit của mọi revision trong nhóm (thời gian, người, vai trò, hành động, summary,
     nút mở diff khi có trước/sau).
4. Trang `/admin/exam-template/[publicId]`: tab **Lịch sử** như trên.
5. Ẩn tab với vai trò không có quyền đọc audit nền tảng (`PLATFORM_ADMIN`, `PLATFORM_MANAGER`); kiểm tra bằng helper quyền
   hiện có trong `features/auth/permissions`.
6. Component ≤ 150 dòng, file ≤ 300 dòng; chuỗi vào constants và `adminCopy.ts`.

## Tiêu chí hoàn thành

- Unit test `diffAuditState`: field đơn, object lồng, mảng thêm/xóa/sửa, before null (tạo mới), after null (xóa), truncated.
- `tsc`, `eslint`, vitest xanh.
