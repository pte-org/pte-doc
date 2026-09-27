# Phase 2: Assessment — `ExamGenerationService` sinh đề ngẫu nhiên theo template

Covers FR-08→FR-12 và phần "sinh đề" của FR-13 (phần "pin template" của FR-13 đã xong ở Plan A). Không đụng `session`/`SessionComposition` (Phase 3) hay UI (Phase 6/7/8) — chỉ dựng đúng 1 facade method `AssessmentService.generateAndPublish(...)` mà Phase 3 sẽ gọi. **Cập nhật 2026-09-17:** theo quyết định "chỉ platform thao tác question bank" (Phase 1), pool sinh đề là `PUBLISHED AND visibility='SHARED'` — `ItembankService.countPublishedByTaskTypes()`/`randomPublishedQuestionIds()` không còn nhận `CurrentUser`/tenant; `caller` vẫn được truyền vào `ExamGenerationService`/`generateAndPublish()` (dùng để set `tenantId` của `ExamBlueprint`), chỉ không còn forward xuống 2 lời gọi `ItembankService`.

## Requirements

Cho một tập 1–4 skill và caller (host), hệ thống resolve `ScoreTemplate` ACTIVE, roll số câu ngẫu nhiên trong `[minCount, maxCount]` cho mỗi dạng thuộc các skill đã chọn (kèm PERSONAL_INTRODUCTION nếu có SPEAKING), kiểm tra đủ câu PUBLISHED+SHARED cho **toàn bộ** dạng trước khi ghi gì, rồi build blueprint + publish snapshot trong một transaction — thiếu bất kỳ dạng nào thì không tạo blueprint/snapshot nào cả và báo đủ mọi dạng thiếu.

## Files

**Thêm**
- `pte-api/app/src/main/java/com/pte/assessment/internal/service/ExamGenerationService.java`
- `pte-api/app/src/main/java/com/pte/assessment/internal/exception/InsufficientQuestionBankException.java` — 422, mang `List<Shortage(String taskType, int required, int available)>`.

**Sửa**
- `pte-api/app/src/main/java/com/pte/assessment/AssessmentService.java` — thêm facade `generateAndPublish(String name, Set<String> skills, CurrentUser caller)` trả `SnapshotResponse`.
- `pte-api/app/src/main/java/com/pte/assessment/internal/constant/AssessmentConstants.java` — thêm mã lỗi cho shortage/invalid skill selection.
- `pte-api/app/src/main/java/com/pte/shared/exception/GlobalExceptionHandler.java` — thêm **một** `@ExceptionHandler(InsufficientQuestionBankException.class)` trả `ApiResponse<List<Shortage>>` (data = danh sách shortage có cấu trúc) — không đổi handler `DomainException` chung.

## Steps

1. Parse `skills` (chuỗi) sang `PteSection`, dùng lại `InvalidSectionException` có sẵn cho chuỗi không hợp lệ; validate 1–4 phần tử phân biệt (Set tự dedupe, chỉ cần validate size).
2. Lấy `ScoreTemplateService.getActive()`, lọc các `ScoreTemplateItem` có `section` thuộc `skills`; nếu `skills` chứa SPEAKING, thêm một yêu cầu PERSONAL_INTRODUCTION (n=1, không có dòng trong template) đứng đầu danh sách yêu cầu của SPEAKING.
3. Với mỗi yêu cầu, roll `n = random trong [minCount, maxCount]` bằng Java `Random` (PERSONAL_INTRODUCTION cố định n=1) — tập hợp thành danh sách `(taskType, n)`.
4. Gọi `ItembankService.countPublishedByTaskTypes(taskTypes)` **một lần** cho toàn bộ taskType trong danh sách yêu cầu (không truyền caller — pool luôn là PUBLISHED+SHARED, không phụ thuộc host nào đang gọi); so từng `n` với count có sẵn, gom **toàn bộ** dạng thiếu (`available < required`) vào một danh sách; nếu danh sách shortage không rỗng, ném `InsufficientQuestionBankException` ngay — chưa có `save()` nào chạy trước điểm này.
5. Nếu đủ câu: với mỗi `(taskType, n)` theo đúng thứ tự SPEAKING(PI trước)→WRITING→READING→LISTENING rồi theo `sequence` của template, gọi `ItembankService.randomPublishedQuestionIds(taskType, n)` (không truyền caller), gom thành danh sách `questionPublicId` theo thứ tự cuối cùng của đề. **Guard bắt buộc (red-team TOCTOU):** sau mỗi lời gọi, kiểm tra `returned.size() == n`; nếu ít hơn (câu bị archive đồng thời giữa bước 4 và bước 5 dưới READ COMMITTED) → ném `InsufficientQuestionBankException` cho dạng đó, trước bất kỳ `save()` nào — không bao giờ publish snapshot thiếu câu so với `[min,max]`.
6. Build một `ExamBlueprint` mới (`tenantId = caller.tenantId()`, `name`) + `BlueprintItem` cho mỗi `questionPublicId` (section từ template item hoặc `PteTaskType.PERSONAL_INTRODUCTION.getSection()`, `orderIndex` tuần tự) — lưu qua `ExamBlueprintRepository` trực tiếp (không qua `BlueprintService.create()`, vì mỗi câu đã được lọc PUBLISHED+SHARED ngay trong query, không cần validate lại từng câu, và `BlueprintService.create()` gọi `itembankService.get(id, caller)` vốn giờ chỉ platform mới đọc được — host-caller sẽ bị chặn nếu đi qua đường đó, đúng như thiết kế bỏ qua nó hoàn toàn).
7. Gọi `SnapshotPublishService.publish(blueprint.getPublicId(), caller)` sẵn có, trong cùng transaction Spring (`@Transactional` mặc định REQUIRED) — trả thẳng `SnapshotResponse` của nó ra ngoài.
8. Expose `AssessmentService.generateAndPublish(...)` gọi `ExamGenerationService` — đây là method duy nhất `session` (Phase 3) gọi.

## Tests

- `ExamGenerationServiceTest` (mock `ScoreTemplateService`, `ItembankService`, `ExamBlueprintRepository`, `SnapshotPublishService`):
  - `generate_fourSkills_100Runs_everyTaskTypeCountWithinTemplateRange` — chạy `generate()` 100 lần với stock "đủ vô hạn" (mock trả về đúng N id được yêu cầu), assert mỗi lần số câu mỗi `taskType` nằm trong `[minCount, maxCount]` của template V5 thật và tổng số câu nằm trong `[64, 81]`.
  - `generate_fourSkills_includesPersonalIntroductionOnceFirstInSpeaking` — assert PI luôn xuất hiện đúng 1 lần, đứng đầu section SPEAKING.
  - `generate_orderIsSpeakingWritingReadingListening_thenBySequence` — assert thứ tự `BlueprintItem` đúng section rồi đúng `sequence` template.
  - `generate_oneToThreeSkills_zeroItemsOutsideSelectedSections` — lặp qua mọi tập con kích thước 1–3 của 4 skill, assert không có item nào thuộc section không được chọn.
  - `generate_randomSelectionReturnsFewerThanN_throwsInsufficient_savesNothing` — count query báo đủ nhưng `randomPublishedQuestionIds` trả về ít hơn `n` (mô phỏng archive đồng thời) → ném `InsufficientQuestionBankException`, `blueprintRepository.save()`/`publish()` không được gọi.
  - `generate_oneShortageAmongMany_throwsWithAllShortagesListed_savesNothing` — 3 dạng thiếu câu cùng lúc → exception liệt kê đủ cả 3, `blueprintRepository.save()`/`snapshotPublishService.publish()` không bao giờ được gọi (Mockito `verifyNoInteractions`).
  - `generate_missingPersonalIntroductionStock_reportedAsShortage` — bank thiếu câu PI khi có SPEAKING → PI xuất hiện trong danh sách shortage.
  - `generate_emptyOrInvalidSkills_rejectedBeforeAnyQuery` — set rỗng, set >4 phần tử, chuỗi section không hợp lệ → ném lỗi trước khi gọi `ItembankService`.
  - `generate_neverPassesCallerToItembankFacade` — verify (Mockito `verify(itembankService).countPublishedByTaskTypes(anySet())`/`randomPublishedQuestionIds(any(), anyInt())`) rằng 2 method facade được gọi đúng chữ ký mới, không có overload nhận `CurrentUser` nào bị gọi nhầm.
- `AssessmentServiceTest`: `generateAndPublish` ủy quyền đúng cho `ExamGenerationService`, trả về đúng `SnapshotResponse`.
- `mvn test -pl app` xanh.

## Success Criteria

- Kỳ thi 4 skill: số câu mỗi dạng ∈ [min, max] của template, tổng câu ∈ [64, 81]; 100 lần sinh không lần nào vi phạm (test thống kê ở trên).
- Kỳ thi 1/2/3 skill: 0 câu thuộc section không được chọn, với mọi tổ hợp skill kích thước 1–3.
- Bank thiếu câu: 0 lời gọi `save()`/`publish()`; lỗi liệt kê **đủ mọi** dạng thiếu (không chỉ dạng đầu tiên).
- `ApiResponse` của lỗi 422 trả `data` là danh sách `{taskType, required, available}` có cấu trúc (không chỉ 1 chuỗi message).
- Sinh đề không bao giờ trả về câu PRIVATE dù host đang gọi thuộc tenant nào — pool luôn là PUBLISHED+SHARED cố định.

## Risks

- HIGH: Nếu thứ tự gọi trong `ExamGenerationService` sai (roll random-pick trước khi kiểm tra đủ shortage), một transaction có thể ghi item cho các dạng đủ câu trước khi phát hiện dạng khác thiếu — mitigation: bước 4 (đếm+shortage) phải hoàn tất và không ném lỗi mới được sang bước 5 (random-pick+ghi); test `generate_oneShortageAmongMany_...` khẳng định `save()` chưa từng được gọi.
- MEDIUM: Roll ngẫu nhiên dùng `java.util.Random` không seed — test thống kê 100 lần có xác suất rất nhỏ bị flaky nếu logic sai biên (off-by-one ở `[min, max]`); mitigation: dùng `Random` bất kỳ nhưng assert theo khoảng đóng `[min, max]` (không phải `[min, max)`), review kỹ công thức `min + random.nextInt(max - min + 1)`.
