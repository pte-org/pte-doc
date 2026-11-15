# Plan: Ngày thi trong khoảng hợp lệ, dọn timer kiểm tra micro, phiên đã hoàn thành chỉ đọc

Status: Ready
Date: 2026-11-15
Mode: Fast
Test: default
Owner/slug: Ninh — `ninh-practice-date-devicecheck-completed`
Scope: `pte-practice`, `pte-doc`
Related: [ninh-practice-timing-and-recording-review](../ninh-practice-timing-and-recording-review/plan.md)

## Mục tiêu

Ba điểm đã đối chiếu là đúng trong đợt review `pte-practice`:

1. Date picker ngày thi: ô gõ tay và danh sách năm cho phép ngày ngoài khoảng mà backend chấp nhận
   (hôm nay đến +2 năm), nút Lưu không kiểm tra, API trả 422 và học viên chỉ thấy toast chung.
2. `DeviceCheckDialog` (kiểm tra micro): `setTimeout` 5 giây không lưu id, không bị hủy khi đóng dialog;
   timer vẫn chạy, gọi `URL.createObjectURL` sau khi đã unmount nên blob không được giải phóng.
3. Phiên `COMPLETED`: học viên vẫn gõ và nộp được câu đã Bỏ qua khi xem lại lịch sử, backend từ chối vì
   `answer()` yêu cầu phiên `IN_PROGRESS`.

Không làm: câu chữ thông báo khi câu nghe không có audio (đã kiểm tra: `PromptMedia` đã có cảnh báo).

## Scope challenge

### Đã có gì?

- `examDateBounds()` và `buildCalendarDays` (khóa ngày ngoài khoảng ở lưới ngày) trong `exam-date.ts`, có test.
- `startWavRecording` + `recorder.current?.cancel()` ở cleanup của `MicCheck`.
- Nhánh "xem lịch sử, câu chưa chấm" trong `PracticeSessionView` và `SessionTaskView` nhận `isSubmitted`, `showSubmit`, `disabled`.
- Backend chủ ý cho trả lời lại câu `SKIPPED` khi phiên còn `IN_PROGRESS`; chỉ phiên `COMPLETED` bị khóa.

### Tối thiểu là gì?

- Hai hàm thuần trong `exam-date.ts` (`isExamDateInBounds`, `examDateYears`) và một khóa i18n cho thông báo ngoài khoảng.
- Một ref cho timer trong `MicCheck`.
- Một prop `readOnly` cho `SessionTaskView`, bật khi phiên `COMPLETED` và đang xem lịch sử.

### Độ phức tạp

Fast. Phase 3 chạm nhánh hiển thị phức tạp nhất của `PracticeSessionView`, nên giữ thay đổi nhỏ và chỉ ảnh hưởng phiên đã hoàn thành.

## Phases

- [x] Phase 1: Ngày thi trong khoảng hợp lệ — [phase-01-exam-date-bounds.md](./phase-01-exam-date-bounds.md)
- [x] Phase 2: Hủy timer kiểm tra micro khi đóng dialog — [phase-02-devicecheck-timer.md](./phase-02-devicecheck-timer.md)
- [x] Phase 3: Phiên đã hoàn thành chỉ đọc — [phase-03-completed-read-only.md](./phase-03-completed-read-only.md)

## Kết quả thực hiện (2026-11-15)

- Phase 1: `isExamDateInBounds` và `examDateYears` trong `exam-date.ts`; `ExamDateLine` dùng chúng cho danh sách năm, ô gõ tay,
  chọn năm và nút Lưu. Ngày gõ tay ngoài khoảng không được giữ làm ngày đã chọn và hiện `examDate.outOfRange` (EN, VI).
  Thêm lớp CSS `exam-calendar-field-error`. 2 test mới.
- Phase 2: `DeviceCheckDialog` lưu id timer vào ref; cleanup khi unmount hủy timer, hủy bản ghi và đặt `recorder.current = null`;
  cờ `unmounted` chặn `createObjectURL` nếu dialog đóng đúng lúc `stop()` đang chờ (cờ được đặt lại khi mount để StrictMode không làm hỏng).
- Phase 3: `SessionTaskView.readOnly`; `PracticeSessionView` tính `completedReadOnly` (xem lịch sử, câu chưa chấm, phiên `COMPLETED`)
  để ẩn Nộp và Bỏ qua, chỉ còn Prev và Next, và khóa ô nhập.

Kiểm chứng: `pte-practice` tsc sạch, 803 test qua, eslint không lỗi (một cảnh báo `locale` không dùng đã có sẵn ở `DeviceCheckDialog`).

Chưa làm: thử trên giao diện, test component cho `MicCheck` và `PracticeSessionView` (cần mock Web Audio), commit.

## Test bổ sung (2026-11-15)

`pte-practice` chưa có jsdom hay Testing Library, nên thay vì thêm dependency, phần logic của ba thay đổi được tách thành hàm thuần rồi test:

- `session/footer-actions.ts` (`footerActions`): toàn bộ logic nút Nộp, Bỏ qua, Next, Prev của footer, thay cho chuỗi if trong `PracticeSessionView`;
  8 test, gồm phiên COMPLETED chỉ đọc, phiên đang chạy vẫn trả lời lại được câu đã bỏ qua, câu đã chấm không bị coi là chỉ đọc.
- `deviceCheck/one-shot-timer.ts` (`createOneShotTimer`): timer hủy được, dùng trong `MicCheck`; 4 test với fake timers
  (chạy một lần, hủy thì không chạy, khởi động lại thay lần chờ cũ).
- `home/exam-date.ts` (`parseManualExamDate`): đọc ngày gõ tay thành `valid`, `outOfRange` hoặc `incomplete`, thay logic trong `ExamDateLine`; 3 test.
- `answer-checks.ts` (`recordingReviewIssue`): quyết định bản ghi nào phải vào màn xem lại (chỉ chế độ không tính giờ); 2 test.

Kiểm chứng: `pte-practice` tsc sạch, 105 file và 820 test qua, eslint không lỗi (còn một cảnh báo `locale` không dùng đã có sẵn).

Chưa có: test render thật cho `MicCheck`, `SpeakingRecorder`, `PracticeSessionView`, `ExamDateLine` (cần thêm `jsdom` và `@testing-library/react` vào devDependencies).
