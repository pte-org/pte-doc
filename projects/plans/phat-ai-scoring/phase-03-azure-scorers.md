# Phase 3: Scorer dùng Azure (RA, RS, ASQ)

Covers: P1-2, FR-04 (RA, RS, ASQ), FR-05, FR-07 (alias/alignment)

## Requirements
Ba dạng Read Aloud, Repeat Sentence, Answer Short Question được chấm theo đúng logic POC, kèm tiêu chí và transcript lưu vào bảng chi tiết AI.

## Steps
1. Khung chọn scorer: chỉ là một bảng ánh xạ từ dạng bài sang scorer, không làm registry hay plugin.
   - Contract chấm mới nhận đủ ngữ cảnh đề đọc từ bản ghi chấm (Phase 2), thay cho hai interface cũ vốn chỉ có media và reference.
   - Stub cũng triển khai contract này, và vẫn là mặc định.
   - Adapter OpenAI-compatible cũ vẫn chạy khi được cấu hình.
   - Gắn đúng loại provider: REAL cho Azure/Gemini, STUB cho stub, vì chỉ điểm REAL mới được publish.
   - Đặt tên provider và model cho kết quả kết hợp Azure + Gemini, nằm trong giới hạn độ dài hiện có.
   - Test: kết quả stub không publish được, kết quả thật publish được.
2. Port phần căn token giữ thứ tự và chuẩn hoá văn bản từ `common.py` của POC. Tính omission, insertion và completeness ở backend bằng cách căn transcript lượt 1 (chỉ nhận dạng, `AzureSpeechAssessor.transcribe`) với reference. Không dùng chuỗi lexical hay Completeness của lượt chấm: miscue của Azure đang tắt, nên hai giá trị đó bị ép theo reference (spike Phase 1: Completeness gần như luôn 100).
3. Scorer RA:
   - Dùng `promptText` làm reference. Gọi Azure theo cách B đã chốt ở spike Phase 1: `prepare` audio một lần, `transcribe` lấy transcript từng đoạn, cắt reference theo LCS với transcript, rồi chấm mỗi đoạn với phần reference của nó. Hiện `AzureSpeechAssessor.assess` chỉ nhận một reference chung cho mọi đoạn, nên phase này thêm hàm chấm theo reference từng đoạn (port từ `perChunkReference` trong `AzureGeminiSpikeTest`). Cách A (nguyên bài gốc mỗi đoạn) đã bị loại vì Accuracy ~54 cho mọi mẫu.
   - `rawScore` là pronunciation score tính theo công thức sample continuous của Microsoft, từ Accuracy, Fluency, Prosody đã gộp và Completeness của bước 2. Kèm danh sách lỗi từ.
   - Bản gộp phải giữ thứ tự xếp hạng và lệch <= 5 điểm so với POC.
4. Scorer RS: dùng `referenceAnswerText` làm reference, `rawScore` = trung bình của điểm căn token (F1), pronunciation và fluency theo `repeat_sentence.py`.
5. Scorer ASQ: chỉ lấy transcript từ Azure, chuẩn hoá rồi so với đáp án và alias tách từ `a / b / c`, 100 nếu đúng và 0 nếu sai; lưu transcript và đáp án khớp.
6. Chuyển kết quả sang mô hình chi tiết AI đã có ở Phase 2 (tiêu chí 0–100, feedback, transcript, JSON chi tiết) và gắn nhãn UNVALIDATED.
7. Viết unit test cho từng scorer với vendor stub, test alias ASQ, test alignment; xác nhận test hiện có pass.
8. Đối chiếu với mẫu trong `ai-research/samples` bằng Azure thật (ASQ và alignment RS khớp tuyệt đối, RA theo biên). Trước khi chạy, báo user số lời gọi, số phút audio và chi phí ước tính (khoảng 5 phút audio), chờ user đồng ý; chạy xong ghi số phút thực tế vào Execution Log.

## Success Criteria
- Mỗi scorer có unit test với vendor stub; test alias ASQ và alignment pass.
- ASQ và alignment RS cho kết quả giống hệt POC Python trên cùng mẫu.
- RA giữ đúng thứ tự xếp hạng các mẫu good/mediocre/bad và lệch <= 5 điểm so với POC.
- Mỗi câu RA/RS/ASQ có `rawScore` 0–100, tiêu chí đúng bảng FR-04 và transcript trong bảng chi tiết AI.
- Test hiện có của module scoring pass.

## Risks
- Gộp nhiều đoạn lệch so với single-shot của POC (chỉ khi audio > 28 giây): so mẫu thật, chỉnh cách gộp hoặc đổi sang cách B nếu vượt biên 5 điểm.
- Căn token khác POC do khác cách chuẩn hoá (dấu câu, số): port đúng quy tắc chuẩn hoá và test bằng cùng mẫu.
- Azure trả transcript rỗng với audio im lặng: coi là điểm thấp hợp lệ, không phải lỗi vĩnh viễn.

## Execution Log
### Errors Encountered
- Bộ sinh fixture alignment làm hỏng dấu nháy cong `’` (file ra sai encoding).
- Test RA dùng đoạn mẫu 12 từ nhưng kỳ vọng completeness sai (thực tế 8/12 từ đọc đúng là 67).
- `AiScoringWorkerTest` lỗi biên dịch: `cannot find symbol setPromptText`.
- Test mới của tôi khẳng định accuracy giảm khi một đoạn giữa im lặng; sai, vì `SpeechAggregator` chỉ kéo fluency xuống (đã có `SpeechAggregatorTest.aSilentChunkLowersFluencyButNotAccuracy`).
- code-reviewer (APPROVE) nêu 1 lỗi hành vi: đoạn giữa nghe được nhưng không khớp từ nào của reference nhận reference rỗng, nên Azure chấm như unscripted và cho điểm cao cho lời nói lạc đề.

### Root Cause
- Fixture: stdout của Python trên Windows không phải UTF-8.
- Completeness: tôi tính nhầm số từ của đoạn mẫu, không phải lỗi code.
- Worker test: `ScoringAnswer` không có setter `setPromptText`, dữ liệu đề được áp qua `applyQuestionContent`.
- Assertion accuracy: hiểu sai thiết kế aggregator, không phải lỗi code.
- Reference rỗng: `ReferenceSplitter` trả `""` cho đoạn không khớp từ nào (đúng theo thiết kế), nhưng `assessScripted` chỉ bỏ qua đoạn không có tiếng, không bỏ qua đoạn có phần reference rỗng.

### Resolution
- Fixture: `sys.stdout.reconfigure(encoding="utf-8", newline="\n")`, sinh lại 71 dòng (đối chiếu lại với `common.align_tokens` của POC ở mọi dòng).
- Sửa kỳ vọng completeness thành 67; sửa worker test dùng `answer.applyQuestionContent(...)`; sửa assertion sang fluency.
- `AzureSpeechAssessor.assessScripted`: đoạn không có tiếng hoặc có phần reference trống không gửi Azure, tính 0 như `noSpeech(true)`. Có 2 test mới (đoạn giữa NoMatch; đoạn giữa lạc đề), test ASQ cho nhánh lexical ("7." với đáp án "seven"), và test wiring `AzureGeminiProviderConfigTest` (provider mặc định không có scorer; azure-gemini có đủ RA, RS, ASQ).
- Simplify: gộp phần trùng của RA và RS vào `AzureScorers.scoreScripted`, bỏ `orZero` trùng. Tracker simplify đã xoá.
- Lệch so với plan: giữ `SpeechScoringClient`/`EssayScoringClient` cũ làm đường dự phòng phía sau bảng `AiAnswerScorer` (task type → scorer), thay vì thay hẳn. Lý do: adapter OpenAI-compatible và stub vẫn chạy cho dạng bài chưa có scorer (Phase 4).
- Chưa làm (reviewer MEDIUM #1): xác thực lúc soạn đề rằng RS phải có `referenceAnswerText`; hiện câu RS thiếu reference báo `INTERNAL_ERROR` lúc chấm. Để Phase 5 (API/UI). Các LOW (giới hạn dung lượng tải audio, `uri(String)` với presigned URL, `toString` của record, `casefold`, tách đáp án ASQ theo "/") chưa xử lý.

### Test Results After Fix
Chạy thật trong phiên này: `./mvnw -pl app test -Dtest='com.pte.scoring.**'` → exit 0; tests=450, failures=0, errors=0, skipped=4 (baseline Phase 2: 323; thêm 127 test). 71 ca alignment khớp POC Python (chạy lại bằng `common.align_tokens`).

Chưa kiểm chứng (không gọi Azure thật; user chọn để dành cho lần thử qua UI ở Phase 5):
- Hành vi thật của `assessScripted` với Azure, và tiêu chí RA lệch ≤ 5 điểm + giữ thứ hạng good/mediocre/bad với POC. Mới có `PronunciationFormulaTest` tái hiện số liệu POC (Ver1–3) bằng công thức, chưa qua đường 2 lượt thật.
- RS và ASQ trên audio thật: thư mục mẫu chưa có audio của hai dạng này.
- Số phút Azure thực tế dùng ở Phase 3: 0.
- Bean wiring với toàn bộ app (worker + scorer cùng context) chưa chạy; `ApplicationContextRunner` chỉ kiểm cấu hình và scorer, worker kiểm bằng unit test.
