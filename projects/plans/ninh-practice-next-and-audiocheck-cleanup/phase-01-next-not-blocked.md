# Phase 1: Nút Tiếp theo không phụ thuộc `unsupported`

Status: Completed

## Requirements

- Ở câu `unsupported` được xem lại từ lịch sử, nút Tiếp theo bấm được; Nộp vẫn bị khóa.
- Các điều kiện khóa khác của Next (đang bận, đang ghi âm, cờ do trang truyền xuống) giữ nguyên.

## Design Constraints

- Khóa Nộp khi `unsupported` hoặc thiếu audio là đúng; chỉ Next (chuyển câu) không được phụ thuộc vào việc câu có làm được hay không.
- Quy tắc khóa nằm ở hàm thuần để test, `SessionTaskView` chỉ gọi.

## Related files

- `pte-practice/features/practice/session/footer-actions.ts`
- `pte-practice/features/practice/session/SessionTaskView.tsx`
- `pte-practice/tests/unit/features/practice/session/footer-actions.test.ts`

## Steps

1. `footerDisabled({ locked, unsupported, audioUnavailable, recorderBusy, prevDisabled, submitDisabled, nextDisabled })`
   trả `{ prev, skip, submit, next }`.
2. `SessionTaskView` dùng nó cho `prevDisabled`, `skipDisabled`, `submitDisabled`, `nextDisabled`.
3. Test: `unsupported` khóa Nộp nhưng không khóa Next; `audioUnavailable` khóa Nộp; `locked` và `recorderBusy` khóa theo như cũ.

## Quality/Testing State

- Test đơn vị mới; `tsc`, eslint và toàn bộ test `pte-practice`.
