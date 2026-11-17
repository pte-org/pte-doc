# Phase 3: Phiên đã hoàn thành chỉ đọc

Status: Completed

## Requirements

- Khi `session.status === "COMPLETED"` và học viên xem lại một câu chưa chấm (đã Bỏ qua) từ lịch sử: ô nhập bị khóa, không có nút Nộp
  và Bỏ qua, chỉ còn Prev và Next.
- Phiên đang chạy giữ nguyên: câu đã Bỏ qua vẫn trả lời lại được.

## Design Constraints

- Thêm prop `readOnly` cho `SessionTaskView` (khóa renderer), không dùng `isSubmitted` vì nó kéo theo hiển thị kết quả.
- Điều kiện chỉ xét ở nhánh "xem lịch sử, câu chưa chấm" của `PracticeSessionView`.

## Related files

- `pte-practice/features/practice/PracticeSessionView.tsx`
- `pte-practice/features/practice/session/SessionTaskView.tsx`

## Steps

1. `SessionTaskView`: prop `readOnly?: boolean`, thêm vào `disabled` của renderer.
2. `PracticeSessionView`: tính `completedReadOnly = viewingHistoryIndex !== null && !isItemScored && session.status === "COMPLETED"`;
   khi đó `showSubmit = false`, `showSkip = false`, `showNext = true`; truyền `readOnly`.

## Quality/Testing State

- Không có test component cho `PracticeSessionView`; kiểm bằng `tsc`, eslint và bộ test hiện có.
