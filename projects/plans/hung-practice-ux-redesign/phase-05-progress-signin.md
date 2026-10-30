# Phase 5: Tiến trình, Đăng nhập, đề trống

Status: Not started · Tasks: 10, 11, 18, 14 (áp gate vào Tiến trình, Ngày thi; khoá nút lưu ngày thi) · Design §4.7–4.8, §7.4–7.5, §8.4

## Requirements
- Tiến trình: 4 ô số (có Điểm TB), tab kỹ năng theo dạng bài, lịch sử tên rõ + Tiếp tục/Xem lại.
- Đăng nhập: lỗi dưới ô, trim, khoá nút, Enter gửi, bỏ "Confidence" trong minh hoạ.
- Danh sách đề trống nói rõ lý do.

## Design Constraints
- Tái sử dụng trước (tabs, field error) — kiểm `@pte/ui` (`Tabs`, `FormField`…) trước khi tạo mới.

## Steps
Task 10 → 11 → 18 → áp Task 14 vào `ProgressView`, `ExamDateLine`.

## Success Criteria
- `progressMetrics` test PASS; tsc/eslint/vitest xanh.

## Quality and Testing State
- Quality: not evaluated
- Testing: not started
