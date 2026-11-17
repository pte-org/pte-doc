# Phase 3: Backend từ chối đáp án sai định dạng

Status: Completed

## Requirements

`correctAnswerText` phải đúng định dạng của task type, nếu không thì trả lỗi `INVALID_CORRECT_ANSWER_FORMAT`:

| Task type | Định dạng |
|---|---|
| `FILL_IN_THE_BLANKS_TYPE_IN` | JSON array chuỗi, không rỗng, phần tử không rỗng và không chứa dấu phẩy |
| `HIGHLIGHT_INCORRECT_WORDS` | JSON array số nguyên không âm, không trùng, không rỗng |
| `ANSWER_SHORT_QUESTION` | Ít nhất một đáp án có chữ sau khi tách bằng `/` |

Các task type khác không đổi.

## Design Constraints

- Quy tắc trùng với bộ parse của scorer (`ReferenceAnswerScorer.parse*`), để thứ nào lưu được thì chấm được.
- Chỉ chạy khi `correctAnswerText` có giá trị; trường rỗng vẫn do `CORRECT_ANSWER_REQUIRED` xử lý.
- Câu có sẵn không bị quét lại; chỉ chặn lúc tạo hoặc sửa.

## Related files

- `pte-api/app/src/main/java/com/pte/itembank/internal/service/QuestionValidationHelper.java`
- `pte-api/app/src/main/java/com/pte/itembank/internal/service/CorrectAnswerFormat.java` (mới)
- `pte-api/app/src/main/java/com/pte/itembank/internal/constant/ItembankConstants.java`
- Test: `CorrectAnswerFormatTest` trong `pte-api/app/src/test/java/com/pte/itembank/internal/service/`

## Steps

1. `CorrectAnswerFormat.isValid(taskKey, text)` theo bảng trên (không phụ thuộc Spring).
2. Thêm `INVALID_CORRECT_ANSWER_FORMAT` vào `ItembankConstants`.
3. Gọi trong `validateAnswers` khi không có option và có `correctAnswerText`.
4. Test hợp lệ và không hợp lệ cho cả ba task type và task type khác.

## Quality/Testing State

- Test đơn vị mới; chạy lại test itembank để chắc không câu mẫu nào bị chặn nhầm.
