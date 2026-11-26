# Bảng chọn giờ 24 giờ cho DateTimePicker

**Trạng thái:** đã làm, chưa commit.

## Vấn đề
`DatePicker` (includeTime) dùng `<input type="time">` gốc của trình duyệt: popup không theo theme/dark mode, khác nhau giữa trình duyệt, hiển thị AM/PM.

## Đã làm (`@pte/ui`)
- `TimePicker` + `TimePickerPanel` (mới): ô gõ giờ (nhận `9`, `930`, `9:30`, `9h30`) và popup 24 giờ với 4 mốc nhanh (08:00, 09:00, 13:30, 17:00), cột Giờ và cột Phút (bước 5, giữ phút lẻ hiện tại), nút Xóa/Xong.
- `useAnchoredPanel` (mới): định vị popup (lật lên trên khi thiếu chỗ). `utils/timeValue.ts`: parse/format.
- `DatePicker` thay ô giờ gốc bằng `TimePicker`. Thêm khóa i18n `common.openTimePicker/timePlaceholder/quickTimes/hour/minute/done` (VI + EN).

## Wizard tạo kỳ thi (tenant-web)
- Mặc định "Mở từ" = giờ tròn kế tiếp, "Đóng lúc" = +3 giờ (`utils/suggestedExamWindow.ts`).
- Đổi giờ mở sang sau giờ đóng thì giờ đóng tự dời +3 giờ.
- Báo lỗi ngay dưới ô khi đóng <= mở (chỉ khi cả hai đã có giờ), không đợi bấm Tiếp tục.

## Kiểm tra
`tsc` sạch (ui + tenant-web); vitest ui 414 test, tenant-web exams 135 test; thử tay trên trình duyệt (mốc nhanh, gõ `9h30`, lỗi inline, popup lật lên trên).

## Vòng 2 (theo nhận xét review)
- Popup: thanh cuộn mảnh (`scrollbar-width: thin`, bỏ mũi tên), vạch kẻ ngăn phần mốc nhanh / hai cột / chân popup, bỏ nền xám cột và thêm vạch dọc giữa Giờ và Phút, nút Xóa chuyển màu xám.
- Ô nhập: vạch dọc giữa ngày và giờ, nửa giờ tô xanh nhạt khi đang thao tác.
- Ô "Đóng lúc" nhận `min` có giờ: cùng ngày với giờ mở thì các giờ/phút/mốc nhanh sớm hơn bị vô hiệu (`minTime`).
- Wizard: dòng chú thích dưới hai ô, ví dụ "Kỳ thi mở trong 3 giờ · Giờ địa phương (GMT+7)".
- Không làm: nút "Hiện tại" thay cho Xóa (giờ mở phải ở tương lai, "hiện tại" luôn bị từ chối; Xóa vẫn cần cho form có ô giờ tùy chọn).

## Vòng 3: lỗi chọn quá sức chứa (bước Người tham gia)
- Lỗi ở bước chọn học viên giờ nằm trong khung `Alert` đỏ (nền đỏ nhạt, tiêu đề đậm, `role="alert"`) thay cho một dòng chữ đỏ nhỏ, và tự cuộn vào tầm nhìn khi xuất hiện.
- Khi vượt sức chứa, thêm câu chi tiết có số liệu: "Bạn đã chọn 5 học viên nhưng kỳ thi chỉ nhận tối đa 3. Hãy bỏ chọn bớt 2 học viên hoặc tăng số học viên tối đa ở bước 1." (VI + EN, khóa `tenant.createExam.AUDIENCE_OVER_DETAIL`).
- Dòng "Đã chọn N học viên" đổi sang đỏ đậm khi N vượt sức chứa. `AudienceStep` nhận thêm prop `capacity`.
- Test mới `tests/unit/features/exams/AudienceStep.test.tsx`.

## Vòng 4: bước "Kiểm tra & tạo" và stepper (theo góp ý review)
- Bước 4 chia 3 nhóm khớp 3 bước trước, mỗi nhóm có nút **Sửa** nhảy về đúng bước (dữ liệu giữ nguyên):
  - Thông tin kỳ thi: Tên kỳ thi, Mẫu kỳ thi, Kỹ năng (badge màu), Độ khó.
  - Lịch thi & chính sách: Thời gian mở thi kèm thời lượng ("26/11/2026 · 13:00 → 16:00 (3 giờ)"), Câu hỏi giữa các kỳ thi.
  - Người tham gia: Học viên dự thi "1 / 1 tối đa" (gộp với sức chứa), Giám thị 0 kèm badge vàng "Chưa phân công".
- Nhãn nhỏ xám, giá trị đậm vừa; khung nền trung tính có vạch kẻ giữa các nhóm (bỏ khung xanh dương). Bỏ tiêu đề lặp "KIỂM TRA & TẠO" và "Kiểm tra trước khi tạo".
- `Stepper` (`@pte/ui`) thêm hai prop tùy chọn, mặc định tắt nên các wizard khác không đổi: `checkCompleted` (tick xanh cho bước đã qua) và `onStepSelect` (bấm thẻ bước đã qua để quay lại; chỉ quay lại, không nhảy tới trước để không bỏ qua kiểm tra). Thêm `aria-current="step"` cho bước hiện tại.
- Màu kỹ năng dùng `Chip` + `sectionTone` (`apps/tenant-web/lib/chipTones.ts`), cùng bộ màu với Ngân hàng câu hỏi và Tiêu chí: Nói xanh dương, Viết xanh lá, Đọc vàng, Nghe đỏ/hồng nhạt. Bản đầu mình tự tạo mapping riêng (Nghe bị xám) nên đã bỏ, không còn bảng màu trùng lặp.
