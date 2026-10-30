# Brainstorm: Study-Pack theo kỹ năng và Luyện đề (Full Mock Test)

**Ngày:** 2026-10-25

## Các hướng đã xem xét
- **Nguồn đề = ExamBlueprint:** blueprint là danh sách câu chọn tay (`questionPublicId`), dành cho thi thật; local chưa có blueprint nào; dùng cho luyện đề có nguy cơ lộ câu thi. Loại.
- **Nguồn đề = đề do admin soạn tay (bảng riêng):** chính xác nhưng cần UI admin ở pte-web. Để sau (P3).
- **Nguồn đề = tự ghép theo Score Template + pool PRACTICE, ghim câu:** template active có tổng minCount = 65, khớp "65 câu" của ảnh tham chiếu. Chọn.
- **Chấm:** chỉ điểm từng câu (đơn giản) vs thêm ước lượng 4 kỹ năng theo trọng số template. Chọn ước lượng, gắn nhãn "tham khảo".
- **Giờ:** đồng hồ tổng 2h15m liên tục vs TIMED từng câu + lưu/tiếp tục. Chọn TIMED từng câu.
- **Study-Pack:** nút Luyện tập mở dialog chế độ cho cả kỹ năng; session nhiều dạng bài đã được API start hỗ trợ một phần (`taskTypeCodes`).

## Hướng của Hung
- Gộp Study-Pack và Luyện đề vào một plan, Study-Pack làm trước.
- Đề tự ghép theo Score Template, pool PRACTICE; điểm từng câu + ước lượng kỹ năng; TIMED từng câu, lưu và tiếp tục.
- Số đề hiển thị = tổng số đề đã được tạo ("cái đó là tổng số đề được tạo ra mà").

## Câu hỏi còn mở (cho /ck-plan)
- Ai tạo đề và khi nào: đề xuất endpoint admin generate + seed script (D5 trong spec).
- Công thức ước lượng điểm kỹ năng (bản đầu: trung bình có trọng số quy về 10–90).
- Ngân hàng PRACTICE local hiện ≤ 3 câu mỗi dạng; cần seed `-PerTask 12` để ghép nhiều đề không trùng.

## Rủi ro
- Ước lượng điểm bị hiểu nhầm là điểm chính thức → nhãn rõ ràng, không lưu vào báo cáo chính thức.
- Phiên 65 câu dài: lỗi upload/ghi âm giữa chừng làm mất tiến độ → dựa vào cơ chế lưu từng câu và tiếp tục đã có.
- Thay Score Template sau khi tạo đề → đề cũ giữ cấu trúc cũ (đã ghim), cần ghi `template_version` để giải thích.
