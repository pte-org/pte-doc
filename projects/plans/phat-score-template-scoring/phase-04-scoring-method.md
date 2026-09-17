# Phase 4: Scoring đọc scoringMethod từ template đã pin, xóa AiScoringTaskCatalog

Covers phần scoring của spec FR-07 ("Xóa `AiScoringTaskCatalog`... Luồng chấm đọc `scoringMethod`... từ template đã pin của snapshot").

## Requirements

Quyết định một answer được chấm khách quan, chấm AI (giọng nói hay văn bản), hay không chấm, đến từ `scoringMethod` của đúng dòng template đã pin cho attempt đó — không còn 2 tập hardcode song song (`AiScoringTaskCatalog` + tập ẩn trong `ObjectiveScoringService`). Hành vi chấm điểm thực tế của từng dạng (thuật toán trong `ObjectiveScoringService.score()`, vendor AI trong `AiScoringWorker`) không đổi.

## Files

**Sửa**
- `pte-api/app/src/main/java/com/pte/scoring/domain/ScoringAnswer.java` — thêm cột `scoreTemplatePublicId` (copy 1 lần lúc ingest, giống cách `taskType`/`payload`/`correctAnswerText` đã được copy).
- `pte-api/app/src/main/java/com/pte/scoring/internal/service/ScoringIngestService.java` — điền `scoreTemplatePublicId` từ `SubmittedAnswerView.scoreTemplatePublicId()` (đã có từ Phase 3) khi tạo `ScoringAnswer` mới.
- `pte-api/app/src/main/java/com/pte/scoring/internal/service/AiScoringDispatcher.java` — bỏ gọi `AiScoringTaskCatalog.supports`; thay bằng tra `scoringMethod` qua `ScoreTemplateService.getByPublicId(answer.getScoreTemplatePublicId())` + `taskType`; `dispatch()` nhúng `scoringMethod` (hoặc modality SPEECH/TEXT suy ra từ nó) vào `AiScoringJob` để `AiScoringWorker` không phải tra lại.
- `pte-api/app/src/main/java/com/pte/scoring/internal/messaging/job/AiScoringJob.java` — thêm field modality (vd `String scoringMethod` hoặc `boolean speech`) được set lúc dispatch.
- `pte-api/app/src/main/java/com/pte/scoring/internal/messaging/consumer/AiScoringWorker.java` — đổi `callVendor()` để switch theo field modality mới trên `job`, không còn import `AiScoringTaskCatalog`.
- `pte-api/app/src/main/java/com/pte/scoring/internal/service/ObjectiveScoringService.java` — đổi `supports(String taskType)` thành `supports(ScoringAnswer answer)` (hoặc nhận thêm `scoringMethod` đã tra sẵn) để cổng vào dựa trên `scoringMethod == OBJECTIVE` từ template thay vì tập `SUPPORTED_TASK_TYPES` hardcode; **giữ nguyên** switch thuật toán chấm trong `score()` (không đổi luật chấm từng dạng, chỉ đổi cổng vào).
- `pte-api/app/src/main/java/com/pte/scoring/internal/service/ScoringCommandService.java` — đổi vòng lặp `requestScoring()`: tra `scoringMethod` một lần cho mỗi answer (qua một service tra cứu mới, có cache theo `scoreTemplatePublicId` trong request-scope hoặc field-level `Map` để không gọi facade N lần cho N answer cùng session/cùng template), rồi rẽ nhánh OBJECTIVE/AI_SPEECH/AI_TEXT/UNSCORED (UNSCORED và "không có trong template" đều giữ nguyên `PENDING`, không coi là lỗi).
- `pte-api/app/src/main/resources/db/migration/V17__scoring_score_template_pin.sql` — `ALTER TABLE scoring_answers ADD COLUMN score_template_public_id UUID NOT NULL` (xác nhận `V16` là mới nhất trước khi đặt tên `V17`).

**Xóa**
- `pte-api/app/src/main/java/com/pte/scoring/internal/service/AiScoringTaskCatalog.java`.
- `pte-api/app/src/test/java/com/pte/scoring/internal/service/AiScoringTaskCatalogTest.java`.

## Steps

1. Thêm cột `scoreTemplatePublicId` vào `ScoringAnswer` + migration `V17`; điền giá trị trong `ScoringIngestService` từ `SubmittedAnswerView` (đã có từ Phase 3) — không có case null vì hệ thống chưa deploy, mọi answer mới ingest đều có.
2. Viết một service tra cứu nhỏ trong `scoring.internal.service` (vd `ScoringMethodResolver`) nhận `(scoreTemplatePublicId, taskType)`, gọi `ScoreTemplateService.getByPublicId`, trả `Optional<ScoringMethod>` (rỗng nếu `taskType` không có trong template, vd `PERSONAL_INTRODUCTION`) — cache đơn giản theo `scoreTemplatePublicId` trong service (template bất biến, an toàn cache cả vòng đời JVM hoặc ít nhất trong 1 lần gọi `requestScoring`).
3. Đổi `ObjectiveScoringService.supports`/`AiScoringDispatcher.supports` để nhận `ScoringMethod` đã tra thay vì tự tra `taskType` qua tập hardcode; xoá `AiScoringTaskCatalog` và test của nó.
4. Đổi `AiScoringJob` để mang theo modality đã biết lúc dispatch; đổi `AiScoringWorker.callVendor()` để đọc field đó thay vì gọi lại `AiScoringTaskCatalog`.
5. Đổi `ScoringCommandService.requestScoring()`: với mỗi answer PENDING, tra `scoringMethod` một lần, rẽ nhánh OBJECTIVE → chấm đồng bộ, AI_SPEECH/AI_TEXT → dispatch, UNSCORED hoặc không tìm thấy trong template → giữ PENDING (không coi là lỗi, giống hành vi "unsupported type" hiện tại).
6. Grep toàn repo xác nhận không còn tham chiếu `AiScoringTaskCatalog`.

## Tests

- `ScoringMethodResolverTest` (Mockito, mock `ScoreTemplateService`): trả đúng `ScoringMethod` theo `taskType`; `taskType` không có trong template → rỗng.
- Sửa `AiScoringDispatcherTest`/viết mới nếu chưa có: `supports`/`dispatch` dựa trên `scoringMethod` đã tra, không còn phụ thuộc `AiScoringTaskCatalog`.
- Sửa `ObjectiveScoringServiceTest` (nếu có) để `supports` nhận `ScoringMethod` thay vì chuỗi `taskType`.
- Sửa `AiScoringWorkerTest` (nếu có) để dùng field modality mới trên `AiScoringJob` thay vì `AiScoringTaskCatalog.isSpeech/isText`.
- `ScoringCommandServiceTest`: case UNSCORED/không có trong template → answer giữ `PENDING`, không throw.
- Xóa `AiScoringTaskCatalogTest.java`; xác nhận không còn file nào tham chiếu class đã xóa (`grep -r AiScoringTaskCatalog pte-api/app/src` → rỗng).
- `./mvnw test -pl app`.

## Success Criteria

- `grep -r AiScoringTaskCatalog pte-api/app/src` không còn kết quả nào (khớp trực tiếp success criterion của spec).
- Một answer với `taskType` = một trong 7 dạng AI_SPEECH được dispatch đúng qua `SpeechScoringClient`; một trong 3 dạng AI_TEXT qua `EssayScoringClient` — hành vi vendor không đổi, chỉ đổi nguồn quyết định.
- Một answer với `taskType` = `PERSONAL_INTRODUCTION` (không có trong template) không bị chấm, không throw, giữ `PENDING` — giống hệt hành vi hiện tại.
- `mvnw test` xanh.

## Risks

- Nếu `ScoringMethodResolver` gọi `ScoreTemplateService.getByPublicId` cho từng answer riêng lẻ trong vòng lặp `requestScoring` mà không cache, một session nhiều chục answer sẽ gọi facade nhiều chục lần trong 1 transaction — không sai nhưng lãng phí; mitigation: cache theo `scoreTemplatePublicId` (template bất biến) ngay trong resolver, không cần thư viện cache ngoài.
- `AiScoringJob` đổi field là đổi payload RabbitMQ — nếu có message cũ còn trong queue lúc deploy (không áp dụng ở dev chưa deploy, nhưng review code cần lưu ý), việc thêm field mới phải có giá trị mặc định hợp lý để không vỡ deserialize (chấp nhận được vì record mới, không có message cũ tồn tại thật).
- Cột `scoring_answers.score_template_public_id NOT NULL` không default — cùng lưu ý reset DB dev cục bộ như các phase trước nếu đã có dữ liệu.
