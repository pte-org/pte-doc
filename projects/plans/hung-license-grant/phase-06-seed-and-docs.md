# Phase 6: Seed script + tài liệu

**Status:** Not started · **Repo:** pte-api, pte-doc

## Việc cần làm

1. **`pte-api/scripts/seed-local-exam-ready.ps1:331-398`:** thay chuỗi phát mã → hiện mã → redeem bằng một lần gọi `POST /api/v1/admin/license-grants` (Idempotency-Key cố định cho seed, `contractReference = "SEED-LOCAL"`). Cập nhật chú thích `:502-505`: gói chạy từ `startsAt` (mặc định là lúc cấp).
2. **ADR-006 (`pte-doc/projects/architecture/ADR-006-commercialization-and-exam-templates.md`):** thêm mục cập nhật §7:
   - Đường B nay là *Admin cấp gói* (mã gắn tổ chức, kích hoạt ngay, có `startsAt`).
   - Mã không gắn tổ chức vẫn được nhận để tương thích.
   - PayOS không gia hạn nối tiếp.
   - Hạn của gói tính từ `startsAt`, không còn tính từ lúc redeem.
3. **Report 03/04** (`report/report03/03-functional-requirements.md` FR-PACKAGE-004, `report04/01-system-design.md` §1.6 Payment): sửa một câu mô tả luồng cấp gói.
4. **Đề xuất gốc** `projects/plans/reports/261029-hung-license-grant-renewal.md`: đổi trạng thái thành "Đã tách: phần cấp gói → plan 261029-hung-license-grant; gia hạn PayOS bỏ; thu hồi/nhắc hạn để sau".

## Design Constraints

- Tài liệu viết tiếng Việt nghiệp vụ, đúng giọng các file hiện có.
- Seed script chạy được trên DB mới (`docker compose up` + seed) mà không cần sửa tay.

## Tests

- Chạy `seed-local-exam-ready.ps1` trên DB sạch: có Subscription ACTIVE, tạo được kỳ thi.

## Quality and Testing State

- Quality: not evaluated
- Testing: not started
