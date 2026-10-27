# Brainstorm: Làm đẹp UI pte-practice (layout, sóng âm, toast, dark mode)

**Date:** 2026-10-25

## Ideas Explored
- **Layout:** (a) giãn nội dung theo màn hình + chữ/thẻ to hơn; (b) giữ cột hẹp, thêm nội dung lấp chỗ trống; (c) full chiều ngang không giới hạn. Chọn (a), giới hạn ~1440px rồi canh giữa.
- **Sóng âm:** kiểu thanh xám tối giản (tham chiếu Adobe Stock "minimalist microphone icon with grey voice waveform bar"): các thanh dọc bo tròn, đối xứng quanh trục giữa, xám nhạt; phần đã phát/đang ghi đổi sang màu nhấn; mic ở giữa khi ghi.
- **Toast:** (A) port Toast của `@pte/ui` (pte-web) vào `pte-practice/common/components`, giữ cùng API; (B) thêm `@pte/ui` làm dependency. Chọn A (giống cách Modal đã port; plan trước chốt không thêm `@pte/ui`).
- **Dark mode:** VS Code/Figma, Material Dark, Slack/Notion, hoặc theo token pte-web. Chọn kiểu VS Code/Figma (nền ~#1e1e1e, thẻ ~#252526/#2d2d30), thay nền gần đen hiện tại (#0a0a0a).

## User's Direction
- "nội dung giãn rộng ra hết màn hình, cỡ chữ và thẻ to hơn"; màn rất rộng: tối đa ~1440px rồi canh giữa.
- Sóng âm dùng ở cả 4 chỗ: ghi âm trực tiếp, nghe lại bản ghi, kiểm tra mic ở Trang chủ, audio đề bài (Listening/Repeat).
- Mọi chỗ kiểu "Practice unlocked" phải dùng toast, lấy từ pte-web.
- Dark mode "không phải AMOLED mà tối kiểu Dark Gray".

## Open Questions
- Thông báo nào thành toast, thông báo nào vẫn nằm trong trang (trạng thái trống, lỗi tải trang)? Đề xuất: trạng thái tức thời (mở khoá, lưu, hết giờ, lỗi thao tác) → toast; trạng thái trống/lỗi tải cần hành động → giữ trong trang.
- "Practice unlocked" hiện ở 4 trang mỗi lần tải → toast nên chỉ hiện **một lần mỗi phiên đăng nhập**, không lặp ở từng trang.
- Sóng âm audio đề bài cần đọc file audio để tính đỉnh sóng (fetch + decode) — đề Cloudinary có thể cần CORS; nếu không đọc được thì dùng sóng giả lập theo thời lượng.

## Risks
- Phóng to toàn bộ có thể vỡ layout ở màn 1280px và mobile → cần kiểm tra 3 mốc (390, 1280, 1920).
- Port toast tạo bản sao code với `@pte/ui` → ghi rõ nguồn, giữ API giống để sau đổi import.
- Decode audio đề bài tốn bộ nhớ với file dài (Re-tell Lecture ~90s) → chỉ tính đỉnh một lần và cache theo URL.
