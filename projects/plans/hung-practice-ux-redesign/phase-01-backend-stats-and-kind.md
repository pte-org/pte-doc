# Phase 1: Backend — thống kê theo dạng bài + loại phiên

Status: Not started · Tasks: 1, 2 (xem [tasks.md](./tasks.md)) · Design §4.1, §4.7, §6.1, §6.6

## Requirements
- Catalog student: mỗi task type thêm `answeredQuestionCount`, `averageScore` (null khi chưa có điểm).
- Progress entry + session response: thêm `kind`, `skillCode`, `taskCode`, (`mockTestPublicId` cho progress).

## Design Constraints
- Chỉ thêm trường (constructor tương thích cũ); không API mới; một truy vấn GROUP BY cho điểm TB; không N+1 khi lấy mock test của trang progress.
- `ModuleStructureTest` phải xanh.

## Steps
Theo Task 1 → Task 2 trong `tasks.md`.

## Success Criteria
- Test mới của Task 1, 2 PASS; full suite BE xanh trước khi sang Phase 2.

## Quality and Testing State
- Quality: not evaluated
- Testing: not started
