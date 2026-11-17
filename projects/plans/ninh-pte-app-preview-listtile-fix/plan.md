# Plan: Sửa lỗi ListTile trong màn xem trước Re-order Paragraphs của `pte-app`

Status: Ready
Date: 2026-11-15
Mode: Fast
Test: default
Owner/slug: Ninh — `ninh-pte-app-preview-listtile-fix`
Scope: `pte-app`, `pte-doc`

## Mục tiêu

`flutter test test/widget/features/exam_attempt/exam_body_layouts_test.dart` đang lỗi 2 test
(`all task bodies render at desktop width 1440.0` và `800.0`) với assertion của Flutter:
"ListTile background color or ink splashes may be invisible. The ListTile is wrapped in a DecoratedBox that has a
background color". Nguyên nhân: `ExamUiPreviewResponse` render `RE_ORDER_PARAGRAPHS` bằng
`ListTile(tileColor: AppColors.surfaceSubtle)` nằm trực tiếp trong khung `ExamTaskFrame` có nền
(`DecoratedBox`), không có `Material` riêng.

Lỗi chỉ ở màn `dev` (xem trước giao diện thi), không phải màn thi thật.

Không làm: `CountdownTimer`/`WritingTaskHeader` (mã chết, không ai dùng), `TextEditorToolbar.didUpdateWidget` (chưa có đường chạy thật).

## Phases

- [x] Phase 1: Bọc `ListTile` trong `Material` — [phase-01-material-wrapper.md](./phase-01-material-wrapper.md)

## Kết quả thực hiện (2026-11-15)

- Phase 1: nhánh `ordering` của `exam_ui_preview_response.dart` bọc mỗi `ListTile` trong `Material(color: AppColors.surfaceSubtle)`,
  bỏ `tileColor`.

Kiểm chứng: `exam_body_layouts_test` 8/8 qua (trước đó lỗi 2 test độ rộng 1440 và 800); toàn bộ `flutter test` 721/721 qua;
`flutter analyze` thư mục `dev` không có vấn đề.

Chưa làm: commit. Bug 2 (`CountdownTimer`, mã chết), bug 3 (`TextEditorToolbar.didUpdateWidget`) và vấn đề 4 (`InTextSelect` vẫn đang được dùng) không sửa.
