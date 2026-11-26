# Brainstorm: Chọn giọng đọc Kokoro khi sinh đề AI

**Ngày:** 2026-11-26 · **Tác giả:** quang

## Bối cảnh

- `VoicePicker` chọn giọng theo `(itemIndex, seed)` của từng job. Mỗi job trong lô thường chỉ có 1 câu, nên trước bản sửa ngày 2026-11-26, 34/37 câu có audio trong DB local dùng giọng Mỹ.
- Bản sửa ngày 2026-11-26 dùng seed của job để quyết định job bắt đầu bằng giọng Mỹ hay giọng Anh. Accent giờ đã chia đều, nhưng các job trong lô vẫn chọn độc lập với nhau, nên hai câu liền nhau vẫn có thể trùng giọng.
- Danh sách giọng nằm trong `QUESTION_GEN_VOICES_US` và `QUESTION_GEN_VOICES_UK`, tổng cộng 5 giọng. Kokoro chỉ có giọng tiếng Anh Mỹ và Anh, không có giọng Úc.
- Đề đã xuất bản lưu bản chụp `audioPromptRef` qua `QuestionFreezeView`. Tạo audio mới với ref mới thì đề cũ không đổi, miễn là không xóa file audio cũ.

## Các hướng đã xem

1. **Tự chia giọng cho cả lô.** Khi tạo lô, xếp giọng cho từng câu: cân bằng accent và giới tính, hai câu liền nhau không trùng giọng. **Chọn.**
2. **Chọn accent hoặc danh sách giọng ở form tạo lô.** Có ích, nhưng thêm trường vào form mà chưa có nhu cầu rõ. **Để sau (P3).**
3. **Nút "Đổi giọng" cho từng câu đã sinh.** Chọn giọng sau khi đã nghe nội dung, rồi tạo lại audio. **Chọn.**
4. **Bắt chọn giọng cho từng câu ngay lúc tạo lô.** Phải chọn khi chưa có nội dung, và rất mất công với lô 20 câu. **Loại.**
5. **Danh mục giọng trong DB kèm trang quản lý trên vendor.** Linh hoạt nhất nhưng cần migration và một màn hình mới. **Loại cho bản đầu.** Thay vào đó dùng danh mục là hằng số trong code.
6. **Dùng thêm engine TTS có giọng Úc hoặc Ấn Độ.** Ngoài phạm vi. Danh mục trong code được thiết kế để sau này thêm engine dễ dàng.

## Hướng user chọn

- Làm **Lớp 1** (tự chia giọng đa dạng cho cả lô) và **Lớp 3** (nút "Đổi giọng" tạo lại audio cho từng câu).
- Danh mục giọng là **hằng số trong code**, gồm mã giọng, accent, giới tính và nhãn. Biến môi trường chỉ dùng để tắt bớt giọng.

## Câu hỏi mở cho /ck:plan

- Nút "Đổi giọng" đặt ở đâu: trang chi tiết câu hỏi trong ngân hàng, trang lô, hay cả hai?
- Câu được sinh trước khi có tính năng này có `generation_meta.media` nhưng không có thông tin của lô. Nút "Đổi giọng" vẫn dùng được cho các câu này nếu chúng có `audioPromptRef` và `promptText`.
- Dạng hội thoại có nhiều người nói (Summarize Group Discussion, Respond to a Situation): đổi giọng từng người, hay chỉ cho "xáo lại giọng"?

## Rủi ro

- **Độ dài audio thay đổi.** Đổi giọng làm độ dài audio khác đi và có thể vượt `AudioDurationRules`. Phải dùng lại logic chỉnh tốc độ đọc đang có, và báo lỗi rõ ràng thay vì lưu một file sai độ dài.
- **Kokoro trên server có thể thiếu giọng.** Server Kokoro thật có thể không có đủ giọng trong danh mục. Cần kiểm tra một lần, ví dụ qua `/v1/audio/voices`, trước khi bật giọng mới.
- **File audio cũ phải giữ lại.** Đổi giọng tạo file mới; xóa file cũ sẽ làm hỏng đề đã xuất bản. Cloudinary đang dùng chung giữa local và prod.
