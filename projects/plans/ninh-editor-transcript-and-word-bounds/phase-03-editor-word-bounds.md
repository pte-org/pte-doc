# Phase 3: Editor kiểm tra giới hạn số từ ở client

Status: Completed

## Requirements

- Bấm Lưu với min hoặc max âm, không phải số nguyên, hoặc `min > max` thì báo lỗi ngay, không gọi API.
- Chỉ kiểm tra những ô có nhập; ô trống do kiểm tra `WORD_COUNTS_REQUIRED` hiện có xử lý.

## Design Constraints

- Quy tắc trùng với backend (phase 2), viết thành hàm thuần để test.
- Chuỗi lỗi nằm trong `constants.ts`.

## Related files

- `pte-web/apps/vendor-web/features/questionbank/wordCountBounds.ts` (mới)
- `pte-web/apps/vendor-web/features/questionbank/constants.ts`
- `pte-web/apps/vendor-web/features/questionbank/components/QuestionEditorForm.tsx`
- `pte-web/apps/vendor-web/tests/unit/features/questionbank/wordCountBounds.test.ts`

## Steps

1. `wordCountBoundsError(min: string, max: string): string | null`.
2. Thêm `WORD_COUNTS_INVALID` vào `QUESTION_EDITOR_ERRORS`.
3. Gọi trong `submit` sau kiểm tra `WORD_COUNTS_REQUIRED`.
4. Test hàm thuần.

## Quality/Testing State

- Test đơn vị mới; `tsc` cho vendor-web.
