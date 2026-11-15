# Plan: Sửa 3 lỗi chấm điểm và nhập đáp án từ đợt review nghiệp vụ

Status: Ready
Date: 2026-11-14
Mode: Fast
Test: default
Owner/slug: Ninh — `ninh-practice-scoring-input-fixes`
Scope: `pte-api` (module `scoring`, `itembank`), `pte-web` (`vendor-web`), `pte-doc`
Related: [ninh-practice-exam-integrity-fixes](../ninh-practice-exam-integrity-fixes/plan.md)

## Mục tiêu

Sửa ba điểm đã được đối chiếu với code là đúng trong đợt review nghiệp vụ:

1. Listening Fill in the Blanks chấm 0 khi đáp án chuẩn có chữ hoa hoặc khoảng trắng thừa.
2. ASQ không nhận câu trả lời có mạo từ đầu câu ("a thermometer").
3. Ô "Correct answer text" nhận mọi chuỗi, nên người soạn dễ lưu định dạng sai và câu bị chấm 0.

Điểm "rú mic" ở `audio-recorder.ts` không được sửa vì đã kiểm tra là sai: `onaudioprocess` không ghi vào
`outputBuffer` nên không có tiếng phát ra loa.

## Scope challenge

### Đã có gì?

- `ReferenceAnswerScorer.normalizeGapValue` đã chuẩn hóa phía học viên (trim, gộp khoảng trắng, lowercase).
- `TokenAlignment.normalize` đã lowercase và tách từ cho ASQ.
- `QuestionValidationHelper.validateAnswers` đã là chỗ kiểm tra `correctAnswerText`, chỉ kiểm tra "không rỗng".
- `QuestionEditorForm.tsx` có sẵn cơ chế `setError(E.…)` và hằng chuỗi trong `constants.ts`.

### Tối thiểu là gì?

Mỗi lỗi một thay đổi nhỏ, tách phase; phase 3 và 4 dùng chung một đặc tả định dạng.

Không làm: đổi thang chấm, đổi UI nhập sang component tag hoặc click chọn từ (chỉ helper text và kiểm tra),
sửa dữ liệu câu hỏi đã có trong DB, đổi AI generator.

### Độ phức tạp

Fast: bốn thay đổi độc lập, có test đơn vị. Rủi ro chính là phase 3 từ chối dữ liệu mà trước đây vẫn lưu được.

## Phases

- [x] Phase 1: Chuẩn hóa đáp án chuẩn của Listening Fill in the Blanks — [phase-01-listening-blanks-case.md](./phase-01-listening-blanks-case.md)
- [x] Phase 2: ASQ bỏ mạo từ đầu câu — [phase-02-asq-articles.md](./phase-02-asq-articles.md)
- [x] Phase 3: Backend từ chối đáp án sai định dạng — [phase-03-backend-answer-format.md](./phase-03-backend-answer-format.md)
- [x] Phase 4: Editor vendor-web — helper text và kiểm tra phía client — [phase-04-editor-helper-and-check.md](./phase-04-editor-helper-and-check.md)

## Quyết định cần ghi nhận

- Phase 3 áp dụng cho câu mới và câu được sửa. Câu đã lưu trong DB không bị quét lại.
- Phase 2 bỏ mạo từ ở đầu câu của cả key lẫn câu nói; mạo từ ở giữa câu giữ nguyên.

## Kết quả thực hiện (2026-11-14)

- Phase 1: `ReferenceAnswerScorer.parseListeningFillBlankReference` chuẩn hóa từng đáp án bằng `normalizeGapValue`. Test mới `ReferenceAnswerScorerListeningBlanksTest`.
- Phase 2: `AnswerKey.matchTokens` bỏ một mạo từ đầu câu ở cả key và câu nói. Hai test cũ đang giả định bí danh có mạo từ là một đáp án riêng nên đã sửa: `AnswerKeyTest` (ví dụ dùng alias khác) và `ShortQuestionScorerTest` (câu "An astronomer!" giờ khớp đáp án chính `astronomer`, điểm vẫn 100).
- Phase 3: `CorrectAnswerFormat` và mã lỗi `INVALID_CORRECT_ANSWER_FORMAT` trong `QuestionValidationHelper`. Test mới `CorrectAnswerFormatTest`. Câu AI sinh ra (`jsonList(answers)` cho type-in và `[3,8]` cho HIW) đã có đúng định dạng này.
- Phase 4: `correctAnswerFormat.ts` (hàm thuần), `CORRECT_ANSWER_HINTS` và `INVALID_CORRECT_ANSWER_FORMAT` trong `constants.ts`, helper text và kiểm tra khi Lưu trong `QuestionEditorForm`. 5 test mới.

Kiểm chứng: backend 2024 test của `scoring`, `itembank`, `practice` qua (38 bị bỏ qua sẵn có); vendor-web 48 test của `questionbank` qua, tsc không lỗi mới, eslint không lỗi.

Chưa làm: thử trên giao diện vendor-web, chưa rebuild container backend, chưa commit.

Lưu ý: chuỗi lỗi/ghi chú ở editor mới chỉ có tiếng Anh vì `features/questionbank/constants.ts` hiện chỉ có một ngôn ngữ.
