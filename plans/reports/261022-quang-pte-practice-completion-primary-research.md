# Research: nền backend cho Practice và Gemini

Date: 2026-10-22. Method: đọc source hiện tại; không chạy product tests/live provider.

## Có thể tái sử dụng

- `pte-api/app/src/main/java/com/pte/practice/internal/service/PracticeSessionService.java`, `PracticeSessionPersistenceService.java`, `PracticeSessionItemService.java`: phiên độc lập, optimistic version và idempotent operations.
- `com/pte/identity/PracticeIdentityService.java`, practice email auth/entitlement: tiếp tục dùng nguồn identity/membership/billing chính thống.
- `com/pte/itembank/PracticeQuestionService.java`: public facade thay vì import repository nội bộ từ practice.
- `com/pte/scoring/internal/vendor/gemini/GeminiRestClient.java`, `GeminiRequest.java`: native REST, structured response và error classification; chưa là public module API.
- `com/pte/scoring/internal/service/ObjectiveScoringService.java`: khảo sát evaluator hiện có để extract public pure evaluation seam; không tạo exam attempt/report chỉ để luyện tập.
- Media binding giữ sở hữu Student/session/item; cần public read-only evidence facade sau submit.

## Khoảng thiếu phải nằm trong plan

1. `QuestionPool.EXAM/PRACTICE` hiện loại trừ nhau, không tương đương `available_for_practice` + `available_for_exam`. Cần additive migration, backfill giữ nguyên phạm vi cũ, readers/writers exam/practice chuyển theo thứ tự, giữ snapshot đã tạo. Kiểm tra mọi consumer, kể cả Windows client, trước ngừng dùng pool cũ.
2. Snapshot hiện thiếu rubric revision, source media, answer-key/reference revision và evaluator policy. Pin khi bắt đầu; phân tách safe delivery snapshot và restricted evaluation snapshot.
3. `AzureGeminiProviderConfig` chỉ tạo Gemini client khi exam provider là azure-gemini và validate cả Azure. Thêm practice capability/config riêng qua public facade/module hợp lệ; không buộc thay exam provider.
4. `GeminiRestClient` request hiện chỉ text/image, không coi đó là contract audio. Azure audio adapter phục vụ thi hiện có không tự động dùng được cho practice ownership.
5. `AiScoringDispatcher` dựa afterCommit và Host-triggered recovery chưa đủ cho Student jobs: dùng durable DB job/outbox cùng transaction với bản nộp, dispatcher định kỳ, lease/fencing token, reclaim job hết lease. Rabbit là delivery mechanism, DB là nguồn job state.
6. Media upload guard chỉ cho IN_PROGRESS/PENDING. Worker cần quyền đọc evidence đã nộp, không nới quyền ghi/upload của Student.
7. Progress hiện `COMPLETED_PENDING_SCORE`, score null. Kết quả khách quan, mức rubric và AI status phải độc lập, không coi chờ AI là chưa nộp.

## Đề xuất workflow

`Submit -> commit immutable submission + evaluation/job identity -> deterministic result -> dispatcher claims job -> Gemini structured output -> semantic/evidence validation -> atomic store immutable result -> Student reads same result`.

Unique logical key gồm owner/context, submission revision/hash, question/rubric/evaluator/prompt/schema/model config/language. Sử dụng SHA-256 của canonical JSON với rule thứ tự cho set/order-sensitive task; không hash raw JSON tùy client. Lưu requested model, actual modelVersion và config hash. Model alias không làm đủ provenance cho reproducibility.

Không bảo đảm đúng một external call: timeout/crash có thể gây gọi lại. Bảo đảm một kết quả được chấp nhận cho logical job, kiểm soát chi phí và bỏ kết quả worker cũ bằng fencing token. GET/result read không trigger gọi provider. Retry khác idempotency header cũng không tạo logical job thứ hai.

## Tài liệu Google đã đối chiếu

- [Structured outputs](https://ai.google.dev/gemini-api/docs/generate-content/structured-output): schema hỗ trợ output có cấu trúc; application vẫn cần validation nghiệp vụ.
- [API keys](https://ai.google.dev/gemini-api/docs/api-key): giữ credential tại backend.
- [Troubleshooting](https://ai.google.dev/gemini-api/docs/troubleshooting): retry bounded với backoff/jitter cho lỗi tạm thời; không retry vô hạn lỗi credential/config.
- [Rate limits](https://ai.google.dev/gemini-api/docs/rate-limits): budget phải tính cả exam và practice nếu dùng chung project/key.
- [Model parameter guide](https://ai.google.dev/gemini-api/docs/generate-content/gemini-3): không hardcode temperature=0 như lời hứa nhất quán; đọc guidance model được chọn khi triển khai.
- [Provider data terms](https://ai.google.dev/gemini-api/terms): xác minh data handling của tài khoản thực tế trước khi gửi bài thật; live smoke ban đầu dùng dữ liệu tổng hợp.

## Khuyến nghị

Gemini cho explanation sau submit, rubric được học thuật duyệt, lưu kết quả bất biến. Objective correctness thuộc evaluator; AI điểm Writing/Speaking cần calibration và approval độc lập. Không tự suy score chính thức PTE từ nhận xét hoặc lấy confidence Student làm điểm.
