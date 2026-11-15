# Phase 4: Editor vendor-web — helper text và kiểm tra phía client

Status: Completed

## Requirements

- Ô "Correct answer text" có helper text theo task type, kèm ví dụ:
  - Type-in: `["London", "ecosystem"]`
  - Highlight Incorrect Words: `[3, 8, 14]` (vị trí từ tính từ 0)
  - ASQ: `thermometer / a thermometer`
- Bấm Lưu với định dạng sai thì báo lỗi ngay, không gọi API.

## Design Constraints

- Cùng quy tắc với phase 3, viết thành hàm thuần để test.
- Chuỗi hiển thị nằm trong `constants.ts`, không hardcode trong JSX.
- Chỉ thêm helper text và kiểm tra, không thay ô nhập bằng component mới.

## Related files

- `pte-web/apps/vendor-web/features/questionbank/correctAnswerFormat.ts` (mới)
- `pte-web/apps/vendor-web/features/questionbank/constants.ts`
- `pte-web/apps/vendor-web/features/questionbank/components/QuestionEditorForm.tsx`
- Test: `correctAnswerFormat.test.ts` trong `pte-web/apps/vendor-web/tests/unit/features/questionbank/`

## Steps

1. `correctAnswerFormatError(taskKey, text)` và `correctAnswerHint(taskKey)`.
2. Thêm chuỗi `CORRECT_ANSWER_FORMAT_*` vào `constants.ts`.
3. `QuestionEditorForm`: truyền `helperText` cho `Input`, kiểm tra trong `submit`.
4. Test hàm thuần.

## Quality/Testing State

- Test đơn vị mới; `tsc` cho vendor-web.
