# Phase 2: Vào màn xem lại khi bản ghi im lặng hoặc quá ngắn

Status: Completed

## Requirements

- Chế độ không tính giờ: bản ghi im lặng hoặc quá ngắn không được lưu ngay; học viên thấy cảnh báo, nghe lại được,
  và chọn Ghi lại hoặc Giữ bản ghi.
- Chọn Giữ thì lưu như bình thường (nút Nộp xuất hiện). Chọn Ghi lại thì xóa bản ghi tạm, về trạng thái ban đầu.
- Chế độ tính giờ giữ nguyên: lưu mọi thứ đã ghi, nhịp thi không chờ.
- Bản ghi bình thường không đổi hành vi.

## Design Constraints

- Trong `review`, không gọi `onChange`, nên câu trả lời chưa có bản ghi và nút Nộp chưa hiện cho đến khi học viên quyết định.
- `onActivityChange` chỉ coi `recording` và `uploading` là bận; `review` không chặn thoát trang.
- Dòng cảnh báo cũ cho `recorded` thành mã không còn đến được, nên bỏ đi; sau khi Giữ, không hiện lại cảnh báo.

## Related files

- `pte-practice/features/practice/renderers/SpeakingRecorder.tsx`

## Steps

1. `stopRecording`: nếu `found !== null` thì `setState("review")` và dừng, không gọi `saveRecording`.
2. Nút Giữ bản ghi gọi `setIssue(null)` trước `saveRecording`.
3. Bỏ dòng cảnh báo `issue && state === "recorded"`.

## Quality/Testing State

- Không có test component cho `SpeakingRecorder` (cần Web Audio); kiểm bằng `tsc`, eslint và bộ test hiện có.
