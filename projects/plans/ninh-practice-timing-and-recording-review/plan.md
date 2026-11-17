# Plan: Thời gian làm bài của câu sau và màn xem lại bản ghi im lặng

Status: Ready
Date: 2026-11-15
Mode: Fast
Test: default
Owner/slug: Ninh — `ninh-practice-timing-and-recording-review`
Scope: `pte-practice`, `pte-doc`
Related: [ninh-practice-integrity-round3](../ninh-practice-integrity-round3/plan.md)

## Mục tiêu

Hai điểm đã đối chiếu là đúng trong đợt review `pte-practice`:

1. `timeSpentSeconds` của câu sau bị cộng thêm thời gian học viên đọc kết quả câu trước: đồng hồ câu được đặt lại khi
   `currentTaskId` đổi, nhưng `submit()` đã đổi nó ngay khi nộp, còn học viên vẫn đang xem kết quả.
2. Trạng thái `review` của `SpeakingRecorder` (nghe lại, ghi lại, giữ bản ghi) không bao giờ được vào:
   `stopRecording` tính `recordingIssue` nhưng luôn gọi `saveRecording`, nên bản ghi im lặng hoặc quá ngắn
   được lưu luôn, chỉ có một dòng cảnh báo.

Không làm: bật tính giờ cho task lẻ (thiết kế hiện tại chủ ý chỉ cho mock test), đổi `audio-recorder.ts`
(đã kiểm tra: không có tiếng vọng vì `onaudioprocess` không ghi `outputBuffer`).

## Scope challenge

### Đã có gì?

- `recordingIssue` (answer-checks.ts) đã có test; i18n `session.recording_silent/short`, `session.keepRecording` đã có.
- Toàn bộ giao diện `state === "review"` (cảnh báo, trình phát, nút Ghi lại / Giữ bản ghi) đã viết sẵn, chỉ thiếu lệnh vào trạng thái.
- `handleNext` đã là chỗ duy nhất chuyển từ kết quả sang câu mới.

### Tối thiểu là gì?

Một dòng đặt lại đồng hồ trong `handleNext`; trong `stopRecording`, vào `review` thay vì lưu khi có vấn đề (chỉ chế độ không tính giờ).

### Độ phức tạp

Fast. Rủi ro thấp; không có test giao diện cho hai component này nên kiểm bằng `tsc`, eslint và bộ test hiện có.

## Phases

- [x] Phase 1: Đặt lại đồng hồ câu khi sang câu mới — [phase-01-question-timer.md](./phase-01-question-timer.md)
- [x] Phase 2: Vào màn xem lại khi bản ghi im lặng hoặc quá ngắn — [phase-02-recording-review.md](./phase-02-recording-review.md)

## Kết quả thực hiện (2026-11-15)

- Phase 1: `handleNext` đặt `questionStartTime.current = Date.now()` khi chuyển từ màn kết quả sang câu mới.
- Phase 2: `stopRecording` vào `review` khi `recordingIssue` khác null và không tính giờ; nút Giữ bản ghi xóa cảnh báo rồi lưu;
  dòng cảnh báo cũ ở trạng thái `recorded` đã bỏ vì không còn đến được.

Kiểm chứng: `pte-practice` tsc sạch, 801 test qua, eslint sạch.

Chưa làm: thử trên giao diện (cần micro thật và một phiên Speaking), test component cho `SpeakingRecorder` và `PracticeSessionView`
(chưa có sẵn, cần mock Web Audio), commit. `pte-practice` chạy bằng dev server nên không cần rebuild container.
