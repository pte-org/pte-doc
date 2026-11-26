# Spec: Giọng đọc đa dạng và đổi giọng từng câu

**Ngày:** 2026-11-26 · **Tác giả:** quang
**Trạng thái:** Draft
**Nguồn:** [brainstorm.md](brainstorm.md)

---

## Vấn đề

Audio do AI sinh gần như chỉ dùng vài giọng Mỹ. Lý do là mỗi job tự chọn giọng, không biết các job khác trong lô. Người tạo đề cũng không có cách nào đổi giọng của một câu đã sinh. Đề PTE thật dùng nhiều giọng nam và nữ, nhiều accent khác nhau.

---

## User Stories

- **[P1]** Là người tạo đề, khi sinh một lô có audio, tôi muốn các câu tự dùng nhiều giọng khác nhau giống đề thật.
  Đạt khi: với lô ≥ 6 câu audio, mỗi accent (Mỹ/Anh) chiếm 40–60%; mỗi giới tính (nam/nữ) chiếm 30–70%; không có hai câu liền nhau trong lô (theo `batchSeq`) dùng cùng một giọng.

- **[P1]** Là người tạo đề, tôi muốn đổi giọng của một câu đã sinh, có nghe thử trước khi chọn.
  Đạt khi: chọn giọng xong thì câu có `audioPromptRef` mới, `generation_meta.media.voice` mới, độ dài audio vẫn đúng luật của dạng bài. Đề đã xuất bản vẫn phát audio cũ.

- **[P2]** Là người tạo đề, với câu dạng hội thoại, tôi muốn xáo lại giọng của các người nói.
  Đạt khi: các người nói vẫn mang giọng khác nhau và audio được tạo lại.

- **[P3]** _(ngoài phạm vi)_ Chọn accent hoặc danh sách giọng ở form tạo lô; quản lý danh mục giọng trên trang vendor; giọng Úc hoặc Ấn Độ từ engine TTS khác.

---

## Yêu cầu chức năng

1. **FR-01:** Danh mục giọng là hằng số trong code (`KokoroVoiceCatalog`). Mỗi giọng gồm: mã Kokoro, accent (`US`/`UK`), giới tính (`F`/`M`), nhãn hiển thị. Danh mục có ít nhất 6 giọng Mỹ và 4 giọng Anh.
2. **FR-02:** Biến môi trường `QUESTION_GEN_VOICES_DISABLED` (tùy chọn, CSV) tắt bớt giọng trong danh mục. Mã không có trong danh mục thì bỏ qua và ghi log cảnh báo một lần. `QUESTION_GEN_VOICES_US` và `QUESTION_GEN_VOICES_UK` bị bỏ.
3. **FR-03:** Lô chia giọng theo vị trí của câu trong lô (`batchSeq`, rồi đến index trong job): xáo danh mục bằng seed của lô, xen kẽ accent và giới tính, xoay vòng giọng. Kết quả lặp lại được với cùng một seed.
4. **FR-04:** Job đứng riêng (không thuộc lô) giữ cách chọn hiện tại của `VoicePicker`.
5. **FR-05:** Endpoint `POST /api/v1/questions/{publicId}/audio/voice`, body `{ voice }`, chỉ vendor có quyền sửa câu hỏi được gọi.
   - Kiểm tra: `voice` có trong danh mục và đang bật; dạng bài có audio đọc từ text.
   - Xử lý: tạo audio, chỉnh tốc độ đọc theo `AudioDurationRules`, lưu thành file mới, cập nhật `audioPromptRef` và `generation_meta.media`, ghi audit.
   - Giữ file audio cũ.
6. **FR-06:** Lỗi có mã trong `*Constants.java`, gồm: `GENERATION_VOICE_UNKNOWN`, `GENERATION_VOICE_NOT_SUPPORTED_FOR_TASK`, cùng các mã media/độ dài đang có.
7. **FR-07:** Endpoint `GET` trả danh mục giọng đang bật (mã, accent, giới tính, nhãn) cho giao diện.
8. **FR-08:** Giao diện có nút "Đổi giọng" trên trang chi tiết câu hỏi (không đặt ở trang lô). Bấm vào mở hộp chọn giọng nhóm theo accent, có nút nghe thử mẫu, xác nhận thì gọi FR-05 và hiển thị lại audio mới.
9. **FR-09:** Nghe thử dùng một câu mẫu cố định cho mỗi giọng. Mẫu được tạo một lần rồi lưu cache, không gọi Kokoro mỗi lần mở hộp chọn giọng.

---

## Yêu cầu phi chức năng

- **Hiệu năng:** đổi giọng một câu Repeat Sentence hoặc Read Aloud mất < 15 giây (p95, với Kokoro đang chạy). Câu bài giảng dài (Re-tell Lecture, Summarize Spoken Text) mất < 90 giây. Giao diện hiện trạng thái đang xử lý.
- **Bảo mật:** chỉ vendor được sửa câu hỏi. Log không ghi text của đề hay API key.
- **Dữ liệu:** không xóa file audio cũ (Cloudinary dùng chung giữa local và prod).

---

## Tiêu chí thành công

- [ ] Một lô 10 câu Repeat Sentence: giọng Mỹ và giọng Anh mỗi bên 4–6 câu; có cả giọng nam và nữ; 0 cặp câu liền nhau trùng giọng.
- [ ] Đổi giọng một câu đã sinh: câu nhận ref audio mới; đề đã xuất bản dùng câu đó vẫn trỏ ref cũ.
- [ ] Unit test cho thuật toán chia giọng của lô và cho FR-05 (giọng không hợp lệ, độ dài audio vượt luật).
- [ ] `./mvnw.cmd -pl app test` và các kiểm tra tsc/eslint/vitest của vendor-web đều qua.

---

## Ngoài phạm vi

- Chọn accent hoặc giọng ở form tạo lô.
- Bảng giọng trong DB và trang quản lý giọng.
- Giọng không phải tiếng Anh Mỹ hoặc Anh.
- Tạo lại audio hàng loạt cho các câu cũ.

---

## Giả định

- Server Kokoro thật có đủ các giọng trong danh mục. Nếu không đủ, FR-02 dùng để tắt những giọng thiếu.
- Mỗi job biết lô của mình và `batchSeq` khi chạy pipeline. Cần xác nhận lúc làm plan.

---

## Đã chốt (2026-11-26)

- Nút "Đổi giọng" chỉ đặt ở trang chi tiết câu hỏi.
- Dạng hội thoại: bản đầu chỉ có "xáo lại giọng" (P2), không chọn giọng cho từng người nói.
