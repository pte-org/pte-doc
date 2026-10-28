# Phase 4: Màn làm bài (khung pte-app), kết quả, hoàn thành, xem lại + an toàn khi làm bài

Status: Not started · Tasks: 8, 9, 15, 16, 17 · Design §4.4–4.6, §6.7–6.8, §7.1–7.3, §8.1, §8.3

## Requirements
- Trang làm bài riêng không sidebar theo ảnh phiên học Pearson: thanh trên (tên phiên, Phần/Câu, đồng hồ, "Tạm dừng phiên"), tiến độ phân đoạn, audio đề có sóng âm, toolbar Copy/Cut/Paste bài Viết, "Tiếp theo ›", hộp "Kiểm tra phát âm thanh" khi bắt đầu phiên Nghe/Nói; màu nhấn `#004787`.
- Xác nhận Thoát/Bỏ qua, cảnh báo rời trang khi đang ghi/tải, chờ upload xong rồi mới thoát.
- Kết quả từng câu, thẻ hoàn thành (điểm TB, "Luyện tiếp dạng này" chỉ TASK/SKILL), xem lại i18n.
- Xung đột 2 tab tự đồng bộ; mất mạng khoá thao tác; cảnh báo số từ bài Viết và bản ghi ngắn/im lặng.

## Design Constraints
- **Không đổi logic** `timed/*`, `TimedTaskFrame`, `SpeakingRecorder` — chỉ bọc trình bày; giữ `AudioWaveform`.
- Tái sử dụng trước: `Modal` (ConfirmDialog dựa trên Modal), `Toast`, `ProgressRing`, `CountdownTimer`; kiểm `@pte/ui` cho header/footer/banner trước khi tạo mới.
- `npx vitest run features/practice/timed` PASS không sửa test.

## Steps
Task 8 → 9 → 15 → 16 → 17 trong `tasks.md`.

## Success Criteria
- Test mới (leave guard, continueHref, isVersionConflict, answer-checks) PASS; test timed không đổi vẫn PASS; tsc/eslint xanh.

## Quality and Testing State
- Quality: not evaluated
- Testing: not started
