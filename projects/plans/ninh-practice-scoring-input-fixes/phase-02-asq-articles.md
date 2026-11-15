# Phase 2: ASQ bỏ mạo từ đầu câu

Status: Completed

## Requirements

- Key `thermometer` nhận "a thermometer", "the thermometer", "An thermometer" (không phân biệt hoa thường).
- Key có mạo từ ("a thermometer") nhận "thermometer".
- Mạo từ ở giữa câu giữ nguyên.
- Key chỉ gồm mạo từ ("a") không bị rỗng đi.

## Design Constraints

- Chỉ đổi so khớp của `AnswerKey`, không đổi `TokenAlignment.normalize` vì lớp đó còn dùng cho các dạng bài khác.
- `acceptedAnswers()` vẫn trả bản gốc người soạn viết.
- Chỉ bỏ **một** mạo từ ở đầu, và chỉ khi sau nó còn ít nhất một từ.

## Related files

- `pte-api/app/src/main/java/com/pte/scoring/internal/vendor/speech/AnswerKey.java`
- Test: `AnswerKeyTest` trong `pte-api/app/src/test/java/com/pte/scoring/internal/vendor/speech/`

## Steps

1. Thêm `matchTokens(String)` trong `AnswerKey`: `TokenAlignment.normalize` rồi bỏ mạo từ đầu nếu còn từ khác.
2. Dùng nó cho `parse` (tokens của key) và `match` (tokens câu nói).
3. Thêm test cho từng yêu cầu ở trên.

## Quality/Testing State

- Test đơn vị mới trong `AnswerKeyTest` (tạo mới nếu chưa có).
