# Phase 3: Trang chủ, Luyện đề, Study-Pack

Status: Not started · Tasks: 6, 7, 14 (áp gate vào Trang chủ, Luyện đề; khoá nút khi xử lý) · Design §4.1–4.3, §6.4

## Requirements
- Trang chủ theo ảnh mẫu Pearson: thẻ đầu (logo, Ngày thi, 2×2 thẻ thiết bị, dải gợi ý), "Đề xuất cho bạn" trượt ngang, "Kỹ năng" theo nhóm có huy hiệu điểm.
- Luyện đề, Study-Pack dùng cùng kiểu thẻ.

## Design Constraints
- Bước đầu: liệt kê component cần (thẻ, chip, carousel, ring, badge) và nguồn (common / port @pte/ui / mới).
- Không thêm thư viện carousel (CSS scroll-snap).
- Không cuộn ngang ở 390px.

## Steps
Task 6 → 7 → áp Task 14 vào `HomeView`, `MockTestListView`.

## Success Criteria
- `buildRecommendations` test PASS; tsc/eslint/vitest xanh.

## Quality and Testing State
- Quality: not evaluated
- Testing: not started
