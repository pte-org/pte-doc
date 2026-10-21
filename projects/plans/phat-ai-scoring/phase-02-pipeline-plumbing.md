# Phase 2: Pipeline plumbing

Covers: P1-1, P1-5, FR-01, FR-02, FR-03, FR-08, FR-11

## Requirements
- Bản ghi chấm của mỗi câu mang đủ dữ liệu đề lấy từ snapshot.
- Kết quả AI chi tiết được lưu trong bảng riêng.
- Lượng request tới provider bị giới hạn.
- Câu `SCORING_FAILED`, hoặc câu kẹt `AI_SCORING` vì mất message, chấm lại được và không bị message cũ ghi đè.
- Thời điểm chấm vẫn do host kích hoạt theo ADR-002.

## Steps
1. **Đưa dữ liệu đề vào bản ghi chấm.**
   - Mở rộng view câu trả lời đã nộp mà module attempt cung cấp qua API public. View lấy thêm `promptText`, `referenceAnswerText`, `imagePromptRef`, `min/maxWordCount` từ pinned item. Scoring không đọc repository của attempt.
   - Lưu các trường này trên bản ghi chấm của answer (migration từ V92).
   - Bản ghi đã ingest trước đây mà thiếu dữ liệu thì được bổ sung lại từ attempt khi host bấm chấm. Dữ liệu chỉ có ở local nên ghi đè được.
   - Ảnh DI lấy từ `imagePromptRef` qua `media`. Không dùng URL ảnh đã resolve sẵn trong pinned item vì URL đó đã hết hạn.
2. **Thu gọn message và thêm dispatch token.**
   - Message chỉ mang định danh và một dispatch token. Worker đọc nội dung đề và bài làm từ bản ghi chấm, nên bài làm không còn nằm trong message, DLQ hay log lỗi của listener.
   - Mỗi lần dispatch tăng token lưu trên bản ghi. Worker, bước ghi điểm và bước đánh dấu lỗi chỉ chấp nhận message có token khớp.
   - Message cũ không có token hoặc token lệch bị bỏ qua an toàn.
3. **Chỉ gửi message sau khi transaction commit.**
   - Message của lệnh chấm chỉ được gửi sau khi transaction commit. Nếu gửi giữa transaction như hiện tại, worker có thể đọc trạng thái cũ (`SCORING_FAILED`), bỏ qua message, và câu kẹt ở `AI_SCORING`.
   - Nếu transaction của host bị rollback vì xung đột version thì không có message nào bị gửi đi.
4. **Bảng 1:1 cho chi tiết AI.**
   - Unique theo answer, ghi kiểu upsert.
   - Gồm: điểm từng tiêu chí, feedback, transcript, JSON chi tiết, cờ fallback, mã lý do lỗi.
   - Chấm thành công thì xoá mã lỗi cũ.
   - Ghi cùng transaction và cùng thứ tự lock (answer, rồi publication) với persistence hiện có.
   - Mã lỗi chỉ là giá trị enum, không lưu body lỗi của provider.
   - Mở rộng kết quả vendor hiện có thay vì tạo một kiểu song song.
5. **Giới hạn tải và xử lý lỗi.**
   - Worker chạy concurrency 2, prefetch 1. Listener DLQ dùng container riêng, không retry.
   - Lỗi tạm thời (429, 503, timeout) dùng một chính sách retry duy nhất: số lần có giới hạn, tôn trọng `retryDelay`. Mỗi job có ngân sách thời gian tổng.
   - Phân loại bằng `AiProviderException.isTransient()`, lấy độ trễ từ `getRetryAfter()` (Phase 1). Nếu retry hint vượt phần ngân sách còn lại thì fail ngay, không ngủ chờ.
   - Circuit breaker theo provider: sau K lỗi tạm thời liên tiếp, các job tiếp theo fail nhanh với `PROVIDER_UNAVAILABLE` trong một khoảng thời gian.
   - Lỗi vĩnh viễn fail ngay.
   - Worker hoặc recoverer ghi thẳng `SCORING_FAILED` kèm mã lý do và token. DLQ chỉ là lưới an toàn.
6. **Mở rộng lệnh chấm của host.**
   - Reset câu `SCORING_FAILED` về `PENDING` rồi dispatch cùng các câu `PENDING`.
   - Dispatch lại câu `AI_SCORING` quá N phút (message bị mất).
   - Câu `SCORED` không bao giờ bị chấm lại.
   - Xác định rõ và test hành vi khi grading cohort đã finalize hoặc đã đủ điều kiện hoàn tất, và khi host đã chọn nguồn `EXAMINER`. Thông báo hoàn tất chấm không được gửi hai lần.
7. **Cấu hình log.** Lỗi của listener và của retry không in payload. Transcript và bài viết không được log ở bất kỳ mức nào.
8. **Test.**
   - Ingest và bổ sung dữ liệu đề.
   - Race: worker nhận message trước khi transaction của host commit.
   - Message mang token cũ (DLQ đến trễ, message gửi trùng).
   - Ghi đè từ FAILED sang SCORED xoá mã lỗi.
   - Circuit breaker.
   - Rescore khi đã chọn `EXAMINER` hoặc cohort đã finalize.
   - Worker ghi điểm đồng thời với lúc host bấm chấm.
   - Test hiện có của module scoring pass.

## Success Criteria
- Migration mới (từ V92) chạy sạch trên DB local qua Flyway. Không dùng `docker compose down -v`.
- Test xác nhận bản ghi chấm của câu RS, RL, ASQ, DI, SWT có đủ trường đề tương ứng. Câu ingest trước đây thiếu dữ liệu được bổ sung khi bấm chấm.
- Test race: rescore một câu `SCORING_FAILED` kết thúc ở `SCORED` (dùng stub), không kẹt `AI_SCORING`.
- Test xác nhận message mang token cũ không đổi trạng thái hay điểm của câu đã được dispatch lại.
- Với vendor giả lập:
  - Trả 503 rồi thành công thì câu thành `SCORED`.
  - Sai key thì mọi câu thành `SCORING_FAILED` kèm mã lý do trong ≤ 3 phút.
  - Mất kết nối thì circuit breaker mở và mọi câu thành `SCORING_FAILED` trong ≤ 3 phút.
- Câu chuyển từ FAILED sang SCORED không còn mã lỗi trong bảng chi tiết.
- Chấm lại lần hai đưa câu `SCORING_FAILED` và câu `AI_SCORING` quá hạn về hàng đợi, không đụng câu `SCORED`. Lựa chọn nguồn `EXAMINER` được giữ nguyên.
- Toàn bộ test hiện có của module scoring pass.

## Risks
- Sai thứ tự lock gây deadlock với publish: dùng lại đúng thứ tự lock của persistence hiện có và có test chạy đồng thời.
- Thu gọn message làm vỡ message cũ còn trong queue: dữ liệu chỉ có ở local. Message cũ bị bỏ qua an toàn nhờ token, câu liên quan được chấm lại bằng lệnh chấm.
- Backoff giữ consumer lâu: đã có ngân sách thời gian mỗi job và circuit breaker. Ở quy mô demo, giữ thread trong listener là chấp nhận được.
- Thứ tự deploy: Flyway chạy khi app khởi động. Migration chỉ thêm bảng và cột nên app cũ vẫn chạy được, nhưng không hiểu mã lý do lỗi mới.

## Execution Log
<!-- Filled by /ck:cook at the end of this phase — leave placeholders when planning -->

### Errors Encountered
- Red run (TDD) `./mvnw -q -pl app test -Dtest='com.pte.scoring.**'` → exit 1, `COMPILATION ERROR` ở `testCompile` (24 dòng lỗi).
- Đọc `app/src/test/java/com/pte/scoring/messaging/job/AiScoringJobTest.java` → file không tồn tại.
- Tổng hợp surefire trên toàn bộ `TEST-*.xml` ra `tests=1498`, không khớp với suite scoring.
- Code review (code-reviewer, APPROVED 8.5/10, không có CRITICAL/HIGH) nêu 4 mục MEDIUM:
  1. Backfill dữ liệu đề trong `ingestForSession` chạy cả khi grading cohort reconcile, tức là ghi vào bản ghi chấm trong commit của worker và giữ lock cohort. Có nguy cơ deadlock với host.
  2. Adapter OpenAI-compatible mất retry vì không đi qua `ProviderGuard`.
  3. Lỗi xảy ra sau khi ngân sách job đã hết vẫn được tính vào circuit breaker.
  4. Thiếu test: cohort đã COMPLETED, lựa chọn EXAMINER sau rescore, lỗi vendor ở mức worker.

### Root Cause
- Test được viết trước khi có `dispatchToken`, `ScoringAnswerAiDetail`, `ProviderGuard`, `AiJobBudget`… nên chưa compile được. Đây là red mong đợi.
- Package `messaging` của scoring nằm dưới `internal`.
- `target/surefire-reports` còn report cũ của các package khác từ những lần chạy trước.
- Review 1: một phương thức ingest duy nhất vừa chèn vừa cập nhật, nên đường reconcile (giữ lock cohort, chạy trong commit của worker) cũng ghi vào hàng mà worker khác có thể đang lock.
- Review 2: lúc thêm `ProviderGuard` chỉ Azure và Gemini được nối vào, adapter OpenAI-compatible bị bỏ sót.
- Review 3: `ProviderGuard` đếm mọi lỗi tạm thời, kể cả lỗi chỉ vì job đã hết thời gian (`VendorHttp.send` fail `PROVIDER_TIMEOUT` khi ngân sách bằng 0). Điều đó không nói gì về tình trạng provider.
- Review 4: test viết cho các đường chính, chưa phủ các tổ hợp trạng thái trên.

### Resolution
- Implement đến khi green. File chính:
  - Migration `V92__scoring_answer_question_content.sql`, `V93__ai_scoring_dispatch_and_detail.sql`.
  - `ScoringAnswer` (`dispatchToken`, `aiDispatchedAt`, `markAiDispatched`, `isAwaitingAiResult`), `ScoringAnswerAiDetail` + repository, enum `AiFailureReason`.
  - `AiScoringJob` (6 trường, chỉ định danh và `dispatchToken`), `AiScoringWorker`, `AiScoringDispatcher` (gửi sau commit), `AiScoringResultPersistenceService`, `ScoringCommandService`, `ScoringIngestService`.
  - `ScoringRabbitMqConfig` (2 consumer, prefetch 1, không requeue, container DLQ riêng), `ProviderGuard`, `AiJobBudget`, `VendorHttp`, `AzureGeminiProviderConfig`.
  - Phía attempt: `SubmittedAnswerView` và `SubmittedAnswerQueryService` thêm dữ liệu đề từ pinned item.
- Sửa theo review (TDD: test đỏ trước, `COMPILATION ERROR` vì thiếu `ingestForScoring` và constructor 4 tham số của `OpenAiCompatibleChatClient`):
  - `ScoringIngestService` tách hai phương thức: `ingestForSession` chỉ chèn hàng mới (dùng bởi cohort reconcile), `ingestForScoring` chèn và bổ sung dữ liệu đề cho hàng cũ (chỉ `ScoringCommandService`, đang giữ lock session). Trạng thái, payload và điểm không bị đụng.
  - `ProviderGuard` không tính lỗi vào breaker khi ngân sách job đã hết (`budgetSpent()`), chỉ ném lại lỗi.
  - `OpenAiCompatibleChatClient` đi qua `ProviderGuard.standard("OPENAI_COMPATIBLE", clock)`. Lỗi HTTP được phân loại bằng `VendorHttp.classifyStatus` kèm `Retry-After` (hàm mới `VendorHttp.retryAfter(String)`, null-safe). Lỗi transport không mang body hay cause.
  - Test mới: `ProviderGuardTest` (ngân sách hết không mở breaker), `ScoringIngestServiceTest` (3 test: không ghi lại hàng đã ingest, backfill, không ghi lại hàng đã đủ dữ liệu), `GradingCohortServiceTest` (cohort COMPLETED không báo hoàn tất lần nữa và không ghi lại bản ghi), `OpenAiCompatibleChatClientTest` (2 test, `MockRestServiceServer`). Test EXAMINER được giữ qua rescore đã có sẵn ở `ScoringAnswerWorkflowTest`.
  - Dọn hằng số `ScoringConstants.AI_PROVIDER_REQUEST_FAILED` không còn ai dùng.
- Dùng đúng đường dẫn `app/src/test/java/com/pte/scoring/internal/messaging/job/AiScoringJobTest.java`.
- Chỉ tổng hợp `TEST-com.pte.scoring*.xml` và kiểm tra cả 44 file đều mới (cùng giờ chạy).
- Simplify (Step 3.S) đã áp dụng:
  - `AiJobBudget` đọc deadline bằng chính `Clock` đã đặt nó. `ProviderGuard.standard` nhận `Clock` được inject.
  - `VendorHttp.send` cắt thời gian chờ theo phần ngân sách còn lại, và fail `PROVIDER_TIMEOUT` mà không gửi khi ngân sách đã hết.
  - Lỗi chưa phân loại của `AiProviderException` là `INTERNAL_ERROR` và không retry.
  - Worker và persistence dùng chung `ScoringAnswer.isAwaitingAiResult(tenant, session, attempt, token)`. Ghi điểm và ghi lỗi đi qua một helper `applyIfAwaiting`.
  - Tập câu cần chấm lấy bằng một query `ScoringAnswerRepository.findScoringWork` (PENDING, SCORING_FAILED, AI_SCORING quá hạn hoặc chưa có `aiDispatchedAt`). Dispatcher cung cấp `staleBefore()`.
- Lệch so với plan (đã chốt khi làm):
  - Câu `SCORING_FAILED` không reset về `PENDING`; nó chuyển thẳng sang `AI_SCORING` với token mới.
  - V93 gộp hai migration dự kiến (V93 và V94) làm một.
  - Retry nằm ở từng HTTP call trong `ProviderGuard` (chỉ retry chunk lỗi), không retry cả job ở container.
- Rủi ro còn lại (chấp nhận ở quy mô demo):
  - Message xếp hàng từ trước bản này (không có token) bị bỏ. Câu tương ứng là `AI_SCORING` với `aiDispatchedAt` null và được dispatch lại ở lần host bấm chấm tiếp theo.
  - Broker sập đúng lúc `afterCommit` thì câu nằm ở `AI_SCORING` đến khi quá hạn, rồi được dispatch lại.
  - Chưa có test mức worker với vendor giả trả 503 hoặc sai key đi hết đường ống. Hành vi đó được phủ riêng ở `ProviderGuardTest`, `OpenAiCompatibleChatClientTest` và `AiScoringWorkerTest`.
  - Hàng `failureReason` cũ vẫn nằm trong bảng chi tiết đến khi kết quả mới về (không xoá lúc dispatch lại).
  - Lỗi vĩnh viễn (vd. `PROVIDER_AUTH_FAILED`) vẫn được chấm lại khi host bấm chấm, để sửa key xong thì chấm lại được. Mỗi lần bấm sẽ tốn thêm lượt gọi Azure/Gemini.

### Test Results After Fix
- `./mvnw -q -pl app test -Dtest='com.pte.scoring.**' -Dsurefire.failIfNoSpecifiedTests=false` → exit 0, 323 tests, 0 failures, 0 errors, 4 skipped (chạy sau khi sửa theo review; trước đó 318). Baseline trước phase là 265.
- Chưa kiểm được trên host:
  - Flyway V92/V93 trên Postgres.
  - Spring context đầy đủ: bean mới, container factory, `Clock` inject vào `AzureGeminiProviderConfig`, JPQL `findScoringWork` trên Postgres.
  - Hai mục này chỉ xác nhận được khi user chạy compose local.
