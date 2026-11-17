# Phase 2: Backend chặn giới hạn số từ không hợp lệ

Status: Completed

## Requirements

- `minWordCount < 0` hoặc `maxWordCount < 0` bị từ chối (`INVALID_QUESTION_FIELDS`), dù chỉ nhập một trong hai.
- `min > max` vẫn bị từ chối khi cả hai có giá trị.
- Không nhập giới hạn nào vẫn hợp lệ.

## Design Constraints

- Mọi so sánh đều kiểm tra `null` trước (không dùng `getMinWordCount() < 0` trực tiếp).
- Giữ nguyên mã lỗi hiện có, không thêm mã mới.

## Related files

- `pte-api/app/src/main/java/com/pte/itembank/internal/service/QuestionValidationHelper.java`
- `pte-api/app/src/test/java/com/pte/itembank/internal/service/QuestionValidationHelperTest.java`

## Steps

1. Mở rộng điều kiện đầu `validate`.
2. Test: min âm, max âm, min > max, min = max hợp lệ, chỉ một giá trị hợp lệ, không có giá trị.

## Quality/Testing State

- Test đơn vị mới trong `QuestionValidationHelperTest`.
