# Phase 8: Tài liệu + xác minh

- Báo cáo `pte-doc/plans/reports/YYMMDD-ai-question-generation-verification.md`:
  - kết quả compile và full suite `app`, vitest của vendor-web;
  - **đánh giá chất lượng thủ công**: mỗi dạng sinh 5 câu, người duyệt chấm có dùng được không (dùng ngay / sửa nhẹ / bỏ),
    tỉ lệ PASS của Reviewer, tỉ lệ người duyệt đồng ý với Reviewer. Đây là số liệu để quyết định có cần tách model reviewer khỏi `Capstone` hay không;
  - thời gian trung bình mỗi câu và lượng token (từ log), số liệu chi phí xem trên dashboard 9router.
- Cập nhật `AGENTS.md`: snapshot mới gồm migration V34, các biến env (chỉ tên), số endpoint mới, phạm vi các dạng bài.
- Cập nhật `docs/` nếu tài liệu chuẩn có danh sách module hoặc role và endpoint liên quan.
- Đánh dấu Done trong `plan.md`.

## Design Constraints
- Giữ các ratchet (300 dòng/file, 15 class/package `internal`, `Clock`, constants) và áp dụng các quyết định red-team của phase này trong plan.md.

## Quality and Testing State
- Chưa cook. Test theo mục Test của phase; cổng `ck:quality` bắt buộc trước khi đóng phase.
