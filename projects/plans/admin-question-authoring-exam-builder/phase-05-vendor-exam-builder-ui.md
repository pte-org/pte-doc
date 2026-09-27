# Phase 5: Vendor curated Exam Builder UI

## Goal

Thay `ExamBuilderForm` placeholder bằng màn hình curated Exam Builder theo PTE template, có filter question bank, thứ tự mặc định và approval workflow.

## Steps

1. Thêm `features/examoperations/api.ts`, `types.ts`, `constants.ts` và assessment API client.
2. Form gồm tên đề, template PTE đang active, section/task slots và trạng thái approval.
3. Khi mở DRAFT, nạp item theo thứ tự mặc định: section order → template sequence → task type → item order.
4. Thêm filter question bank theo section, task type, status, keyword và metadata đã lưu; filter không làm thay đổi thứ tự template.
5. Cho phép Admin/Author chọn, thêm, bỏ và sắp xếp item trong DRAFT; validate item count/section/task trước khi save.
6. Author dùng Submit for approval; Admin có Approve/Reject kèm rejection reason. Sau approve hiển thị snapshot immutable.
7. Giữ màn hình random generation/availability cho flow host/platform nếu cần, nhưng không thay thế curated builder.
8. Thêm detail/preview page cho blueprint/snapshot; answer key chỉ hiện với quyền author/admin và mode author review.
9. Xử lý lỗi 400/403/409/422/5xx, retry an toàn và empty state.

## Design Constraints

- UI phải nói rõ template order mặc định và trạng thái approval.
- Không hiển thị nút Save/Approve giả hoặc thao tác update blueprint chưa có API.
- Không để host flow bị thay đổi do vendor screen; tenant session creation giữ contract riêng.
- Không render answer/reference answer trong preview không được phép.
- Author không thấy hoặc không gọi được Approve/Reject.

## Files / ownership

- `pte-web/apps/vendor-web/features/examoperations/components/ExamBuilderForm.tsx`
- new `GenerationSummary.tsx`, `BlueprintPreview.tsx`, `ExamResultPanel.tsx`
- `features/examoperations/api.ts`, `types.ts`, `constants.ts`
- `pte-web/apps/vendor-web/app/(dashboard)/admin/exams/page.tsx` và detail route nếu cần
- `pte-web/packages/api-client/src/requests/assessment/*`
- vendor nav/permission constants

## Quality and Testing State

- Chưa chạy cho phase này.
- Theo quyết định hiện tại, không bắt buộc test/quality audit ở từng phase. Template ordering, filter, drag/reorder và approval cases là checklist tùy chọn.
- Preflight: frontend build passed at final gate; quality audit and tests skipped by user decision (`quality: skipped_by_user; decision: user_confirmed_skip`).

## Acceptance Criteria

- Exam Builder không còn placeholder/API unavailable message.
- Blueprint mở ra có thứ tự mặc định đúng theo PTE template.
- User filter được question bank và chọn/sắp xếp item trong DRAFT.
- Author submit được nhưng không approve; Admin approve/reject được.
- Approve thành công hiển thị snapshot result và không làm hỏng host session flow.
