# Phase 1: Đặt lại đồng hồ câu khi sang câu mới

Status: Completed

## Requirements

- `timeSpentSeconds` của một câu chỉ tính từ lúc câu đó hiện ra cho học viên, không gồm thời gian đọc kết quả câu trước.

## Design Constraints

- Đặt lại ở `handleNext`, đúng chỗ ẩn kết quả cũ và hiện câu mới. `useEffect` theo `currentTaskId` giữ nguyên cho lần vào câu đầu và các đường khác (Skip, tải lại).

## Related files

- `pte-practice/features/practice/PracticeSessionView.tsx`

## Steps

1. Trong nhánh "đã nộp, đang xem kết quả" của `handleNext`, thêm `questionStartTime.current = Date.now()` cùng lúc `setCurrentAnswered(null)`.

## Quality/Testing State

- Không có test component cho `PracticeSessionView`; kiểm bằng `tsc`, eslint và bộ test hiện có.
