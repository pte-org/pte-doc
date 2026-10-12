# Phase 6: Demo data, kiểm chứng end-to-end và ADR-002

Covers: toàn bộ Success Criteria của spec, Assumptions (dữ liệu SGD), cập nhật ADR-002

## Requirements
Có 1–2 câu SGD để demo, một attempt đủ 10 dạng được chấm end-to-end bằng provider thật, kết quả đối chiếu với POC, và ADR-002 ghi nhận thay đổi về lưu chi tiết AI và examiner thấy điểm AI.

## Steps
0. (XONG, 2026-10-11) Kiểm tra lúc soạn đề: câu Repeat Sentence (RS) phải có `referenceAnswerText` không rỗng. Hiện thiếu text này chỉ lộ ra lúc chấm dưới dạng `INTERNAL_ERROR`. Viết test trước, chặn ở bước tạo/sửa câu RS (API trả lỗi 400 rõ lý do), rồi hiện lỗi đó trên form soạn câu hỏi của web nếu form có sẵn chỗ hiện lỗi. Không ghi DB; với dữ liệu RS cũ đang thiếu text chỉ báo cho user, không tự sửa.
1. Chuẩn bị 1–2 câu SGD từ fixture `samples/remaining/group_discussion/source_labeled.txt` (transcript có nhãn speaker) cùng audio mẫu; đưa ra nội dung dự kiến cho user duyệt.
2. HỎI USER TRƯỚC KHI GHI DB: chỉ sau khi user đồng ý mới tạo câu SGD (import hoặc seed theo quy trình có sẵn của dự án); không ghi DB nếu chưa có xác nhận.
3. Tạo (hoặc yêu cầu user tạo) session demo và một attempt có đủ 10 dạng, bao gồm câu DI ở cả nhánh có ảnh và nhánh fallback nếu khả thi.
4. Chạy end-to-end. Trước khi chạy, báo user số câu nói, số phút audio và chi phí Azure ước tính cho cả bước 4 và 5 (khoảng 30 phút audio), chờ user đồng ý; chạy xong ghi số phút thực tế vào Execution Log.
   - Host bấm chấm. Theo dõi trạng thái, đo thời gian (≤ 10 phút cho ~36–44 câu) và số lời gọi đồng thời.
   - Mô phỏng sai key, sau đó mô phỏng mất mạng. Xác nhận mọi câu sang `SCORING_FAILED` trong ≤ 3 phút (nhờ circuit breaker).
   - Sửa lỗi rồi bấm chấm lại, xác nhận các câu đó sang `SCORED`.
5. So kết quả với POC trên mẫu `ai-research/samples`: ASQ và alignment RS khớp, RA lệch <= 5 điểm và đúng thứ tự, dạng có Gemini xếp good > mediocre > bad; tổng hợp bảng so sánh vào Execution Log.
6. Rà soát bảo mật nhanh: không log audio/transcript/bài viết đầy đủ ở INFO, key chỉ từ env, presigned URL dùng TTL ngắn.
7. Thêm ghi chú amendment vào `ADR-002-communication-and-scoring-lifecycle.md`. Nội dung:
   - Chi tiết AI lưu trong bảng riêng.
   - Message chỉ gửi sau khi commit, có dispatch token.
   - Rescore câu `SCORING_FAILED` và câu `AI_SCORING` quá hạn.
   - Examiner luôn thấy điểm AI. Ghi rõ hạn chế: examiner có thể bị điểm AI ảnh hưởng (anchoring), làm tín hiệu "lệch ≥ 20" yếu đi.
   - Nhấn mạnh thời điểm chấm không đổi.
8. Cập nhật `plan.md` (tick các phase) và nhờ user tự kiểm UI trên attempt demo.
9. Nhờ user deploy lên VPS (implementer không tự deploy), kèm ước tính chi phí của attempt kiểm tra (khoảng 4 phút audio). User host-chấm một attempt ngắn có RA, DI, SGD và WE trên VPS và kiểm tra:
   - Các câu sang `SCORED`, nghĩa là container gọi được Azure và Gemini từ VPS.
   - Container `app` không bị restart vì OOM.

## Success Criteria
- Tạo/sửa câu RS không có `referenceAnswerText` bị từ chối với lỗi rõ ràng (có test).
- Câu SGD chỉ xuất hiện trong DB sau khi user xác nhận; không có thao tác ghi DB nào trước đó.
- Attempt demo đủ 10 dạng: 100% câu AI kết thúc ở `SCORED` với `rawScore` và tiêu chí đúng FR-04, dạng nói có transcript.
- Thời gian chấm ~36–44 câu <= 10 phút; log cho thấy đồng thời không vượt `scoring.ai.worker.concurrency`.
- Kịch bản sai key: 100% câu sang `SCORING_FAILED` trong <= 3 phút; sau khi sửa và chấm lại, chuyển sang `SCORED`.
- Bảng so sánh với POC đạt các tiêu chí khớp ở spec (ASQ/RS alignment đúng bằng, RA <= 5 điểm, xếp hạng đúng).
- ADR-002 có ghi chú amendment; toàn bộ test module scoring pass; user xác nhận phần UI.
- User xác nhận trên VPS arm64: các câu RA, DI, SGD, WE sang `SCORED`, container `app` không restart.

## Risks
- Ghi DB ngoài ý muốn: bắt buộc hỏi và chờ xác nhận; không dùng `docker compose down -v`.
- Hết quota Gemini giữa chừng khi chạy e2e: chạy theo đợt, dùng rescore để hoàn tất; ghi nhận trong log.
- Audio SGD mẫu không khớp transcript nhãn speaker: kiểm lại fixture với POC trước khi duyệt.
- Media local 404 làm DI luôn fallback: chấp nhận và ghi rõ, hoặc nhờ user cung cấp ảnh tải được để kiểm nhánh có ảnh.

## Execution Log
<!-- Filled by /ck:cook at the end of this phase — leave placeholders when planning -->

### Errors Encountered
- (not executed yet)

### Root Cause
- (not executed yet)

### Resolution
- (not executed yet)

### Test Results After Fix
- Spike SGD thật (2026-10-11, user đã duyệt ước tính ≈ $0,02), `AzureGeminiSpikeTest#summarizeGroupDiscussionEndToEnd` trong container maven, chạy `SummarizeGroupDiscussionScorer` thật với `group_discussion_good.wav` (45,3 s) và `source_labeled.txt`:
  - Raw 92; Content 95, Fluency 92, Prosody 90; fallback = false; model `short-audio-rest+gemini-3.5-flash-lite`.
  - Transcript 106 từ, Azure nhận ra giọng nói; Gemini trả đủ 3 người nói, 7 ý đã nêu, 0 ý thiếu, 2 quan hệ giữa các ý.
  - Thời gian 16,0 s cho cả lượt (2 đoạn audio → 2 lời gọi Azure, 1 lời gọi Gemini). Test pass, exit 0.
  - Chỉ chạy 1 lần; đã dùng khoảng 0,75 phút audio Azure. Chưa thử mẫu SGD kém hay lạc đề.
- Spike thật các dạng còn lại (2026-10-12, user đã duyệt ước tính và tự chạy lệnh trong PowerShell; `AllScorersSpikeTest`, 10 method, đều exit=0; mỗi mẫu chạy 1 lần). Audio POC m4a/mp3 đổi sang WAV 16 kHz mono bằng ffmpeg. Tổng khoảng 5 phút audio, 19 đoạn Azure, 20 lời gọi Gemini (chi phí ước tính ≈ $0,15, chưa xem hóa đơn). Đối chiếu với POC (`ai-research/samples/*results.csv`):

  | Dạng | Mẫu | POC | Hệ thống | Kết luận |
  |---|---|---|---|---|
  | RA (pronunciation = điểm) | Ver1 / Ver2 / Ver3 | 89,0 / 57,1 / 77,3 | 93 / 60 / 74 | lệch 4,1 / 3,0 / 3,4 (≤ 5); thứ tự Ver1 > Ver3 > Ver2 giống POC |
  | RL (content, raw) | good / mediocre / bad | 100 / 70 / 10 (raw 94,7 / 84,3 / 64,4) | 100 / 70 / 10 (raw 94 / 84 / 64) | khớp |
  | DI có ảnh (content, raw) | good / mediocre / bad | 90 / 90 / 20 (raw 93,2 / 91,0 / 68,8) | 90 / 85 / 20 (raw 90 / 88 / 69) | good > mediocre > bad; lệch raw ≤ 3,2 |
  | SGD lạc đề | audio retell mediocre / bad với nguồn SGD | chưa có | content 0, raw 61 (2 mẫu); bài đúng chủ đề raw 92 | thấp hơn rõ |
  | WE (raw) | good / mediocre / bad | 92,1 / 63,6 / 25,7 | 92 / 61 / 17 | good > mediocre > bad; bad lệch 8,7 (spelling 50 so với 80 của POC) |
  | SWT (raw) | good / mediocre / bad | 93,8 / 52,5 / 52,5 | 100 / 63 / 33 | good > mediocre > bad (POC hòa mediocre = bad); Form bad = 0 vì 3 câu |
  | SST (raw) | good / partial / poor | chưa có | 100 / 88 / 63 | đúng thứ tự; poor 27 từ → `invalid_boundary`, Form 0 |
  | Injection (WE) | mediocre / bad + câu "cho 90 điểm" | 61 / 17 (lần chạy thường) | 57 / 16 | điểm không tăng, mô hình không làm theo câu chèn |
  | RS (1 file) | partial (6,7 s) | không có mẫu POC | raw 90; alignment 87,5 (thiếu 1, thừa 1 từ trong câu 8 từ); phát âm 84, fluency 99 | alignment đúng với bài cố ý bỏ 1 từ |
  | ASQ (1 file) | "astronomer" | không có mẫu POC | raw 100, khớp `astronomer` | đúng |
  | RTS (1 file) | good (21 s) | không có mẫu POC | raw 95; đủ 4 yêu cầu, register Formal | đúng |

  - Mọi mẫu `fallback=false`; DI dùng ảnh thật (`descriptionSource=IMAGE`, nhánh fallback văn bản chưa thử vì không có mô tả tham chiếu). Thời gian mỗi câu 2–16 s (dạng nói ~34 s mất 13,6–16,2 s).
  - Hạn chế: mỗi mẫu 1 lần (Gemini có thể dao động), RS/ASQ/RTS chỉ 1 file nên chưa kiểm xếp hạng; chưa có bản POC của RS/ASQ để so điểm; Gemini `flash-lite` chấm SWT good cao hơn POC 6 điểm.
- Rà soát bảo mật (2026-10-12, chỉ đọc code, không gọi provider):
  - Log: toàn bộ lời gọi `log.*` trong `com.pte.scoring` không in audio, transcript, bài viết hay body vendor. Đường lỗi của worker chỉ log id câu và `AiFailureReason`; `AiProviderException` chỉ mang mã phân loại; `toString` của `AiScoringRequest`/`AiScoreResult` bỏ nội dung; job RabbitMQ chỉ chứa id và token.
  - Key: Azure/Gemini chỉ đọc từ biến môi trường và đặt vào header HTTP.
  - URL presigned: TTL mặc định 120 s, `CloudinaryMediaService` giới hạn trong 1..900 s.
  - Chưa có test nào khóa việc log không lộ nội dung → thêm `AiScoringWorkerTest.worker_vendorFailureLogsOnlyTheAnswerIdAndReasonNeverTheContent` (bắt log của worker, kiểm không có nội dung payload/đề/thông điệp lỗi, không có stack trace). Test này viết sau code đã đúng nên pass ngay lần đầu (là test bảo vệ, không phải test đỏ-trước). `AiScoringWorkerTest`: 17 test, 0 lỗi, 0 fail, 0 skip (lệnh chạy thật, exit 0).
- ADR-002: đã thêm mục "Amendment 2026-10-12" vào `pte-doc/projects/architecture/ADR-002-communication-and-scoring-lifecycle.md` (5 ý: bảng chi tiết AI riêng; gửi sau commit kèm dispatch token; chấm lại `SCORING_FAILED` và `AI_SCORING` quá hạn; examiner luôn thấy điểm AI kèm hạn chế anchoring làm yếu tín hiệu "lệch ≥ 20"; thời điểm chấm không đổi) và sửa câu cũ "không có circuit breaker" cho khớp thực tế. Đối chiếu với code: token tăng mỗi lần gửi (`ScoringAnswer.markAiDispatched`), gửi trong `afterCommit` (`AiScoringDispatcher`), worker kiểm token (`isAwaitingAiResult`).
- Dữ liệu demo (2026-10-12, DB local, đã được user duyệt trước khi ghi):
  - Ngân hàng câu hỏi: giữ 1 câu EXAM cho mỗi dạng trong 10 dạng chấm AI; ẩn 35 câu còn lại bằng `deleted=true` (có thể hoàn tác bằng cách đặt lại `deleted=false`). Câu giữ lại ưu tiên câu có audio/ảnh dùng được.
  - Mẫu bài thi `PTE_AI_SCORING_TEMPLATE` v1 (CUSTOM, 10 dạng, min = max = 1): tạo bằng SQL (sao các item từ một template có sẵn), trọng số lấy từ bảng PTE thật rồi chia lại để mỗi kỹ năng cộng đúng 100. Sau đó user Submit và Approve trên vendor-web (ứng dụng chấp nhận dữ liệu tạo bằng SQL), rồi Activate ở trang Edit. Danh sách template hiện `PTE_AI_SCORING_TEMPLATE` v1 = Active, `PTE_FULL_TEMPLATE` v1 = Retired (user xác nhận bằng ảnh chụp danh sách).
  - Đường SQL không tạo bản ghi audit log.
- Attempt demo + chấm AI thật trên UI (2026-10-12, session "Test 11", attempt 18, 10 câu):
  - Thí sinh làm trên app. Câu SST không bấm Next được vì `ManualNavigationPolicy` chỉ cho Next/Previous tay ở READING và WRITING (đúng thiết kế, không phải lỗi). Hai câu cuối (SWT, WE) **không làm qua app**: tôi chèn tay vào `attempt_answers` (SWT 46 từ, WE 207 từ), cần ghi rõ khi báo cáo.
  - Phát hiện: tab "Bài nộp" trống trước khi chấm vì bài chỉ được nhận vào `scoring_answers` khi host bấm chấm (ADR-002); tenant-web chưa có nút chấm lần đầu. Đã thêm nút "Chấm điểm AI" (`StartAiScoringButton`, có hộp xác nhận chi phí) vào tab Bài nộp, gọi `POST /sessions/{id}/score`. Chỉ kiểm bằng `tsc` + `eslint`, tenant-web chưa có test runner.
  - Lần bấm đầu chạy `SCORING_AI_PROVIDER=stub` (mặc định của compose): 10 câu SCORED trong <1 s, feedback "STUB…". Không gọi vendor, không tốn credit. Đã đặt `azure-gemini` trong `.env`, compose lại, xóa 10 dòng stub (user tự chạy) rồi bấm lại.
  - Lần chấm thật: tổng **51 s** (07:10:26 → 07:11:17), mục tiêu ≤ 10 phút đạt. 9/10 SCORED: RA 93, RS 88, DI 89, RL 88, ASQ 0 (nói "Stars.", đáp án "Source/birthplace/origin"), SGD 63, RTS 89, SWT 100, WE 92. SST `SCORING_FAILED` / `INTERNAL_ERROR`.
  - Nguyên nhân SST: câu hỏi thiếu `promptText` (transcript bài nghe); scorer báo `AI_SOURCE_TEXT_EMPTY` trước khi gọi Gemini (không tốn tiền). Lỗ hổng ở khâu soạn đề: SST không bắt buộc transcript. Đã sửa: `QuestionValidationHelper` yêu cầu `promptText` cho SST (test viết trước, 2 test đỏ → xanh; `QuestionValidationHelperTest` 11/11, itembank tests không lỗi). Dữ liệu demo của câu SST này **không sửa**, user quyết định không chấm lại.
  - Tab Bài nộp gom theo bài làm (user yêu cầu: không tách mỗi câu một dòng): mỗi attempt một dòng (tên thí sinh, lần làm, tiến độ chấm + badge lỗi/đang chấm/chờ), bấm "View answers" mới thấy từng câu của người đó. Backend: `GET /api/v1/answers/attempts?sessionPublicId=` (`ScoringAttemptReviewService`, đếm theo attempt+status qua `countByAttemptAndStatus`, tên/lần làm lấy từ `AttemptService`), thêm lọc `attemptPublicId` cho `GET /api/v1/answers`. Test viết trước: `ScoringAttemptReviewServiceTest` 3 test + 1 test lọc attempt ở `ScoringReviewAiDetailTest`, 8/8 xanh; api-client `answers.test.ts` 2/2 xanh; `tsc` + `eslint` tenant-web sạch. User compose lại và xác nhận tab Bài nộp hiển thị đúng (2026-10-12), nên câu JPQL `countByAttemptAndStatus` đã chạy được trên Postgres. Test hồi quy scoring + itembank + attempt + kiểm tra kiến trúc: 870 test, 0 lỗi, 17 skipped.
  - `/simplify` Phase 6 (4 agent: reuse, simplification, efficiency, altitude; 2026-10-12). Đã sửa: gộp 2 lần đọc attempt thành 1 (`AttemptService.getAttemptOwners` + `AttemptOwnerView`, thay `getAttemptNumbers`), đếm theo `EnumMap` thay vì stream 5 lần, `QuestionValidationHelper` dùng chung `taskKey()`, xóa nhánh chết ở `AnswersSection` (prop `attemptPublicId` giờ bắt buộc), dùng lại `ANSWERS_SECTION_TEXT.ATTEMPT_VALUE` / `ANSWER_TABLE_HEADERS`, `AttemptsSection` lưu `selectedId` + `Map` tên + chờ roster, thu hẹp invalidate theo session. Sau sửa: 911 test backend (scoring, itembank, attempt, reporting, kiến trúc) 0 lỗi; tsc, eslint sạch. Không làm (cần quyết định riêng): chuyển luật "SST cần transcript, RS cần đáp án gốc" từ code cứng sang catalog `question_type_definitions` (cần migration + cờ mới; hiện UI soạn đề của SST không biết luật này), dời route `/answers/attempts` sang `/scoring/sessions/{id}/attempts`, trả luôn `studentName` từ API, bỏ constructor null của `ScoringReviewService`, gộp `StartAiScoringButton` với `RescoreAiButton`, tách `constants/index.ts` (470 dòng), chuỗi tiếng Việt lẫn tiếng Anh, dùng chung code giữa hai spike test.
  - Luật "SST cần transcript, RS cần đáp án gốc" đã chuyển từ code cứng sang catalog (2026-10-12, TDD). Migration `V94__scoring_input_authoring_requirements.sql`: thêm cột `requires_reference_answer` vào `question_types` và `task_runtime_contracts`, bật `requires_prompt_text` cho `SUMMARIZE_SPOKEN_TEXT`, bật `requires_reference_answer` cho `REPEAT_SENTENCE` (cả hai bảng, vì hợp đồng runtime chuẩn được so khớp với `PteTaskType`). Backend: `TaskAuthoringRequirements`/`QuestionTypeDefinition`/`TaskRuntimeContract`/`QuestionTypeResponse` có cờ mới, `PteTaskType.requiresReferenceAnswer()` + SST `requiresPromptText=true` làm fallback; `QuestionValidationHelper` đọc cờ chung, bỏ `isTask`. Vendor-web: bỏ `REPEAT_SENTENCE_CODE`, form đọc `questionType.requiresReferenceAnswer`. `UpdateQuestionTypeRequest` không thêm cờ vì `QuestionTypeService.update` vốn không áp các cờ `requires*`. Test: 127 test itembank/practice 0 lỗi; vendor-web tsc, eslint (0 lỗi) sạch. Việc user: build lại app (Flyway chạy V94) và vendor-web, kiểm form soạn SST/RS.
  - Dọn nốt việc simplify còn lại (2026-10-12, user yêu cầu). Đã làm: (1) route danh sách bài nộp chuyển từ `GET /api/v1/answers/attempts?sessionPublicId=` sang `GET /api/v1/scoring/sessions/{id}/attempts` (trong `HostScoreReviewController`, có `verifyHostAccess`); (2) API trả `studentName` qua `IdentityService.findFullNames` (một truy vấn theo lô, lọc theo tenant, bỏ user đã xóa), `AttemptsSection` không còn gọi roster; (3) tách các hằng số xem bài/chấm AI sang `constants/answers.ts` (index re-export, `index.ts` 470 -> 397 dòng); (4) hai spike test dùng chung `SpikeSupport` (HTTP, JSON, endpoint, khóa env). Cố ý không làm: gộp `StartAiScoringButton` với `RescoreAiButton` (khác điều kiện hiện, khác hộp xác nhận, khác chuỗi; gộp sẽ thành một component nhiều cờ, chỉ chung hook `useRescoreSession` vốn đã dùng chung). Còn lại, chưa làm: bỏ constructor null của `ScoringReviewService`, chuỗi tiếng Việt lẫn tiếng Anh.
  - **Không thực hiện, user quyết định bỏ qua (2026-10-12):** kịch bản sai key / mất mạng và rescore câu lỗi trên vendor thật (hai việc này còn chưa được kiểm chứng end-to-end; phần retry/circuit breaker/rescore chỉ có test đơn vị từ Phase 2). Kiểm tra trên VPS thuộc về user.
