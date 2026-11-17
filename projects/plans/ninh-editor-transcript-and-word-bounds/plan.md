# Plan: Ô transcript nhiều dòng và kiểm tra giới hạn số từ ở editor câu hỏi

Status: Ready
Date: 2026-11-15
Mode: Fast
Test: default
Owner/slug: Ninh — `ninh-editor-transcript-and-word-bounds`
Scope: `pte-api` (`itembank`), `pte-web` (`vendor-web`), `pte-doc`
Related: [ninh-practice-integrity-round3](../ninh-practice-integrity-round3/plan.md)

## Mục tiêu

Hai góp ý đã đối chiếu với code:

1. Ô `referenceAnswerText` (Audio transcript) là `<Input>` một dòng, trong khi transcript của bài nghe dài 100–300 từ
   (và vừa được bắt buộc cho Re-tell Lecture, Summarize Spoken Text, Summarize Group Discussion).
2. Giới hạn số từ: backend đã chặn `min > max` khi cả hai có giá trị, nhưng chưa chặn số âm; editor không kiểm tra
   gì ở client nên người soạn chỉ nhận lỗi chung từ server.

Không làm: ngưỡng "đúng" ≥ 60 của `InlineResultCard` (chờ quyết định sản phẩm).

## Scope challenge

### Đã có gì?

- `QuestionValidationHelper.validate` đã có kiểm tra `min > max` (có kiểm tra null) và mã `INVALID_QUESTION_FIELDS`.
- Ô `promptText` đã là `<textarea className={`${fieldClass} mt-1 min-h-28`}>`; có sẵn `fieldClass`.
- `submit` trong `QuestionEditorForm` đã có chuỗi các kiểm tra trả lỗi bằng `setError(E.…)`.
- `correctAnswerFormat.ts` (đợt trước) là mẫu cho hàm kiểm tra thuần có test.

### Tối thiểu là gì?

Đổi một thẻ, thêm điều kiện số âm ở backend, một hàm thuần `wordCountBoundsError` cho editor.

### Độ phức tạp

Fast. Rủi ro thấp: số âm trước đây lưu được nhưng vô nghĩa.

## Phases

- [x] Phase 1: Ô transcript nhiều dòng — [phase-01-transcript-textarea.md](./phase-01-transcript-textarea.md)
- [x] Phase 2: Backend chặn giới hạn số từ không hợp lệ — [phase-02-backend-word-bounds.md](./phase-02-backend-word-bounds.md)
- [x] Phase 3: Editor kiểm tra giới hạn số từ ở client — [phase-03-editor-word-bounds.md](./phase-03-editor-word-bounds.md)

## Kết quả thực hiện (2026-11-15)

- Phase 1: `referenceAnswerText` là `<textarea>` khi task type cần audio prompt hoặc reference answer; các dạng khác giữ `<Input>`.
- Phase 2: `QuestionValidationHelper` chặn số âm (kể cả khi chỉ nhập một giới hạn) và `min > max`, có kiểm tra `null`;
  mã lỗi vẫn là `INVALID_QUESTION_FIELDS`. Test mới `wordCountLimitsMustBeNonNegativeAndOrdered`.
- Phase 3: `wordCountBounds.ts` (hàm thuần), chuỗi `WORD_COUNTS_INVALID`, kiểm tra trong `submit` của `QuestionEditorForm`; 3 test mới.

Kiểm chứng: backend 558 test của `itembank` qua (9 bỏ qua sẵn có); vendor-web 51 test của `questionbank` qua, tsc không lỗi mới, eslint sạch.

Chưa làm: rebuild container backend (thay đổi backend nhỏ này chưa chạy trong container), chưa thử form trên giao diện, chưa commit.
Điểm 3.3 (ngưỡng ≥ 60 của `InlineResultCard`) cố ý không sửa.
