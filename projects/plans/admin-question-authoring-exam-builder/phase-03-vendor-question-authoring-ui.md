# Phase 3: Vendor Question Bank UI

## Goal

Thay `QuestionEditorForm` placeholder bằng editor schema-driven cho 23 PTE task types, có Cloudinary media upload, preview, draft/submit/approve/archive/restore và revision flow.

## Steps

1. Chuẩn hóa `types.ts`, constants và mapper theo backend enum `APPROVED`; không map APPROVED thành draft.
2. Bổ sung `PLATFORM_AUTHOR` vào vendor route/nav guard cho các trang content.
3. Tạo task schema/renderer với các nhóm:
   - Speaking audio response/prompt;
   - image prompt;
   - free text/reference answer/word count;
   - single/multiple choice;
   - ordering;
   - fill blanks/gap indexes;
   - token/highlight selection.
4. Chia form thành component nhỏ dưới `features/questionbank/components/task-forms/`; field metadata lấy từ `/question-types` khi phù hợp.
5. Tạo `MediaUploader` dùng request signature → upload trực tiếp Cloudinary → confirm → preview URL; có progress, retry, cancel và cleanup warning.
6. Tạo `QuestionPreview` hiển thị đúng task layout, không hiển thị answer key ở chế độ candidate preview.
7. Thêm routes:
   - `/admin/questions`;
   - `/admin/questions/new`;
   - `/admin/questions/[publicId]/edit`.
8. Nối Add/Edit/Archive/Restore/Submit approval từ `QuestionBankView` và table; Admin có thêm Approve/Reject; confirmation cho destructive-looking actions.
9. Với APPROVED question, nút Edit gọi create revision rồi mở draft ID; không mutate ID cũ.
10. Hiển thị backend field errors, 409 conflict, shortage/permission errors và trạng thái save.

## Design Constraints

- Form không tự gửi `status`, `visibility` hoặc field không được backend contract hỗ trợ.
- UI validation chỉ cải thiện UX; backend vẫn là authority.
- Không disable Save vì placeholder; disable chỉ khi đang submit/invalid theo rule đã biết.
- “Delete” trên UI gọi archive; Restore gọi unarchive về DRAFT.
- Author chỉ thấy Submit for approval; Approve/Reject chỉ hiển thị cho Admin.

## Files / ownership

- `pte-web/apps/vendor-web/features/questionbank/components/QuestionEditorForm.tsx`
- `QuestionBankView.tsx`, `_QuestionTable.tsx`, `types.ts`, `constants.ts`, `api.ts`
- new `task-forms/*`, `MediaUploader.tsx`, `QuestionPreview.tsx`
- `pte-web/apps/vendor-web/app/(dashboard)/admin/questions/*`
- `pte-web/packages/api-client/src/requests/question/index.ts`
- new `requests/media/*`, `types/media/*`, question DTO mappers

## Quality and Testing State

- Chưa chạy cho phase này.
- Theo quyết định hiện tại, không bắt buộc test/quality audit ở từng phase. Component, Cloudinary upload và approval cases là checklist tùy chọn.
- Preflight: frontend build passed at final gate; quality audit and tests skipped by user decision (`quality: skipped_by_user; decision: user_confirmed_skip`).

## Acceptance Criteria

- Add question mở editor thật; Save tạo DRAFT.
- Tất cả task type có field layout tương ứng hoặc bị chặn có thông báo rõ nếu chưa được backend hỗ trợ.
- Audio/image upload và preview hoạt động qua API thật.
- Preview candidate không lộ đáp án; author preview có thể xem answer key ở chế độ riêng.
- Submit/approve/reject/archive/restore và edit revision hoạt động không làm đổi snapshot cũ.
