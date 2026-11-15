# Phase 1: Chuẩn hóa đáp án chuẩn của Listening Fill in the Blanks

Status: Completed

## Requirements

- Đáp án chuẩn `["London", " Hydrogen "]` phải khớp với câu trả lời `london`, `hydrogen` của học viên.
- Tham chiếu hỏng (không phải JSON array chuỗi, phần tử rỗng hoặc chứa dấu phẩy) vẫn chấm 0.

## Design Constraints

- Dùng đúng `normalizeGapValue` cho cả hai phía để hai phía không thể lệch nhau lần nữa.
- Việc chuẩn hóa nằm trong `parseListeningFillBlankReference`, không đổi chữ ký phương thức công khai.

## Related files

- `pte-api/app/src/main/java/com/pte/scoring/internal/service/objective/ReferenceAnswerScorer.java`
- Test: `ReferenceAnswerScorerTest` trong `pte-api/app/src/test/java/com/pte/scoring/internal/service/objective/`

## Steps

1. Trong `parseListeningFillBlankReference`, trả các phần tử đã qua `normalizeGapValue` sau khi kiểm tra hợp lệ.
2. Thêm test: đáp án có chữ hoa, khoảng trắng thừa, khoảng trắng kép; câu trả lời đúng được 100.

## Quality/Testing State

- Test đơn vị mới trong `ReferenceAnswerScorerTest`.
