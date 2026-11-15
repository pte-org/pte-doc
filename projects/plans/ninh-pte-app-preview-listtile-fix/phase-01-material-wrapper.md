# Phase 1: Bọc `ListTile` trong `Material`

Status: Completed

## Requirements

- Mỗi dòng của Re-order Paragraphs trong màn preview vẫn có nền `AppColors.surfaceSubtle`, số thứ tự, nội dung và biểu tượng kéo.
- Hai test `exam_body_layouts_test` qua; không test nào khác bị ảnh hưởng.

## Design Constraints

- Dùng `Material(color: ...)` bao ngoài `ListTile` và bỏ `tileColor`, đúng cách Flutter khuyến nghị.
- Chỉ đổi nhánh `TaskTemplateFamily.ordering` của `exam_ui_preview_response.dart`.

## Related files

- `pte-app/lib/features/exam_attempt/dev/exam_ui_preview_response.dart`
- `pte-app/test/widget/features/exam_attempt/exam_body_layouts_test.dart`

## Steps

1. Trong nhánh `ordering`, mỗi `ListTile` được bọc `Material(color: AppColors.surfaceSubtle, child: ...)`, bỏ `tileColor`.
2. Chạy `exam_body_layouts_test`, rồi `flutter analyze` và bộ test liên quan.

## Quality/Testing State

- Dùng chính hai test đang lỗi làm kiểm chứng; không cần test mới.
