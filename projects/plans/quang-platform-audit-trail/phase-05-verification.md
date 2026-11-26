# Phase 05: Kiểm thử, kiểm tra và báo cáo

Repo: `pte-api`, `pte-web`, `pte-doc`. Trạng thái: **xong (2026-11-25)**. Phụ thuộc: phase 01–04.

## Việc cần làm

1. Backend: `.\mvnw.cmd -pl app -DskipTests compile`, rồi `.\mvnw.cmd -pl app test`; báo số test, lỗi và skip.
2. Web: `tsc --noEmit`, `eslint`, `vitest run` cho vendor-web và `packages/api-client`.
3. Local: rebuild container `app`; nếu phase 01 có migration index mà local chạy `local-schema` thì áp tay.
4. Kịch bản tay (người dùng tự chạy trên trình duyệt):
   - Sửa đáp án một câu hỏi nháp → tab Lịch sử hiện diff option `correct`.
   - Sửa item template → diff item.
   - Từ màn nhân sự chọn "Xem lịch sử thao tác" → màn audit lọc đúng người.
   - Tài khoản tenant gọi endpoint chi tiết → 403.
5. Đo kích thước: số byte trung bình `before_state + after_state` cho câu hỏi và template sau kịch bản trên.
6. Báo cáo `pte-doc/plans/reports/YYMMDD-platform-audit-trail-verification.md`.
7. Cập nhật snapshot trong `AGENTS.md` (số endpoint, migration mới nếu có).
