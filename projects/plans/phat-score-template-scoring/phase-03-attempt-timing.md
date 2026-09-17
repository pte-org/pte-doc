# Phase 3: Attempt lấy timing từ template đã pin

Covers spec FR-14. Thay nguồn `prepSeconds`/`responseSeconds` của `SnapshotPinService` từ `task-timing.json` sang template đã pin của snapshot; giữ nguyên cơ chế tính `prepSeconds` động cho 5 dạng audio-prompt Speaking.

## Requirements

Khi một attempt được pin, mọi `PinnedItem` có mặt trong `ScoreTemplate` đã pin lấy `prepSeconds`/`responseSeconds` từ đúng dòng template khớp `taskType`; 5 dạng audio-prompt Speaking tiếp tục tính `prepSeconds` động (`preListenSeconds` + độ dài audio thật + `preRecordSeconds`) như hiện tại, chỉ đổi nguồn `preRecordSeconds` sang `template.prepSeconds`. `PERSONAL_INTRODUCTION` (không có trong 22 dòng template) và bất kỳ `taskType` nào không có trong template tiếp tục dùng cấu hình tĩnh cũ (fallback), để luồng blueprint thủ công hiện có (Plan A giữ nguyên) không bị vỡ khi tác giả chèn câu PI thủ công.

## Files

**Sửa**
- `pte-api/app/src/main/java/com/pte/attempt/internal/service/SnapshotPinService.java` — inject `ScoreTemplateService`; trong `pin()`, gọi `getByPublicId(content.scoreTemplatePublicId())` một lần, dựng map `taskType → item`; trong `toPinnedItem()`, ưu tiên đọc `prepSeconds`/`responseSeconds` từ map đó, chỉ fallback về `taskTimingConfig.timingFor(taskType)` khi map không có `taskType` đó. Với 5 dạng audio-prompt (nhận diện qua `taskTimingConfig` vẫn còn `preListenSeconds` khác null cho `taskType` đó — giữ đúng cơ chế "config hiện diện quyết định nhánh" đang có), `preRecordSeconds` lấy từ template item thay vì từ `task-timing.json`.
- `pte-api/app/src/main/java/com/pte/attempt/domain/PinnedExamSnapshot.java` — thêm cột `scoreTemplatePublicId` (copy 1 lần lúc pin, dùng bởi Phase 4/5 qua `AttemptService`).
- `pte-api/app/src/main/resources/config/task-timing.json` — rút gọn: chỉ giữ `PERSONAL_INTRODUCTION` (`prepSeconds`/`responseSeconds` như hiện tại — dạng UNSCORED, không có trong template) và 5 dạng audio-prompt Speaking (chỉ giữ `preListenSeconds`, bỏ `prepSeconds`/`responseSeconds`/`preRecordSeconds` vì nay đọc từ template). Đổi tên comment `_comment` đầu file phản ánh đúng vai trò thu hẹp này.
- `pte-api/app/src/main/java/com/pte/attempt/internal/config/TaskTimingConfig.java` — không đổi logic parse (giữ nguyên record `Timing`), chỉ cần chấp nhận các trường `prepSeconds`/`responseSeconds`/`preRecordSeconds` vắng mặt trong JSON của 5 dạng audio-prompt (mặc định `0`, không được đọc nữa nên vô hại) — nếu code hiện tại đã dùng `.asInt()` (mặc định 0 khi thiếu key) thì không cần sửa gì, chỉ cần xác nhận lại.
- `pte-api/app/src/main/java/com/pte/attempt/dto/response/SubmittedAnswerView.java` — thêm `scoreTemplatePublicId` (dùng ở Phase 4).
- `pte-api/app/src/main/java/com/pte/attempt/internal/service/SubmittedAnswerQueryService.java` — set `scoreTemplatePublicId` từ `answer.getPinnedItem().getPinnedSnapshot().getScoreTemplatePublicId()`.
- `pte-api/app/src/main/java/com/pte/attempt/AttemptService.java` + `pte-api/app/src/main/java/com/pte/attempt/internal/service/AttemptSummaryQueryService.java` — thêm phương thức `getScoreContext(UUID attemptPublicId)` trả về `scoreTemplatePublicId` + tập `section` phân biệt của mọi `PinnedItem` thuộc attempt đó (dùng bởi `reporting` ở Phase 5 để biết "tested skills" mà không cần đụng `assessment`).
- `pte-api/app/src/main/java/com/pte/attempt/dto/response/AttemptScoreContextView.java` — record mới `(UUID scoreTemplatePublicId, Set<String> testedSections)`.
- `pte-api/app/src/main/java/com/pte/attempt/internal/repository/ExamAttemptRepository.java` — thêm query method fetch `pinnedSnapshot` + `pinnedSnapshot.items` theo `publicId` (mirror `findWithPinnedByPublicIdAndStudentPublicId` nhưng không lọc theo `studentPublicId`, dùng cho caller nội bộ đáng tin như `reporting`).
- `pte-api/app/src/main/resources/db/migration/V16__attempt_score_template_pin.sql` — `ALTER TABLE pinned_exam_snapshots ADD COLUMN score_template_public_id UUID NOT NULL`, `ALTER TABLE scoring_answers`... (KHÔNG — cột `scoring_answers` thuộc Phase 4, giữ trong migration riêng `V17`). Xác nhận `V15` là mới nhất trước khi đặt tên `V16`.

## Steps

1. Thêm cột `scoreTemplatePublicId` vào `PinnedExamSnapshot` + migration `V16` (cùng lưu ý reset DB dev cục bộ như Phase 2 vì `NOT NULL` không default).
2. Sửa `SnapshotPinService.pin()`: sau khi có `content` (đã có `scoreTemplatePublicId` từ Phase 2), gọi `scoreTemplateService.getByPublicId(...)` một lần, set lên `PinnedExamSnapshot`, và truyền map `taskType → item` xuống `toPinnedItem()`.
3. Sửa `toPinnedItem()`: nếu map có `taskType` này → dùng `item.responseSeconds()` (vẫn tôn trọng `responseOverrideByTaskType` từ composition như hiện tại) và `item.prepSeconds()` làm giá trị `prepSeconds` tĩnh HOẶC làm `preRecordSeconds` nếu đây là 1 trong 5 dạng audio-prompt; nếu map không có `taskType` này (vd `PERSONAL_INTRODUCTION`) → giữ nguyên logic cũ đọc từ `taskTimingConfig`.
4. Rút gọn `task-timing.json` xuống chỉ còn `PERSONAL_INTRODUCTION` + `preListenSeconds` của 5 dạng audio-prompt; xoá các key khác đã dời sang template.
5. Thêm `scoreTemplatePublicId` vào `SubmittedAnswerView`, cập nhật `SubmittedAnswerQueryService` để điền từ `PinnedExamSnapshot` qua `PinnedItem`.
6. Thêm `AttemptService.getScoreContext()` + `AttemptSummaryQueryService` + repository method mới, trả `testedSections` = tập `section` phân biệt của mọi `PinnedItem` trong attempt.
7. Chạy lại toàn bộ test hiện có của `attempt` (đặc biệt `SnapshotPinServiceTest`) — thêm mock `ScoreTemplateService`, xác nhận không phá vỡ nhánh presign audio/image hiện có.

## Tests

- Sửa `SnapshotPinServiceTest` (file có sẵn, dùng Mockito): thêm mock `ScoreTemplateService`, viết case timing đọc từ template (số khác với `taskTimingConfig`) để chứng minh nguồn ưu tiên đúng thứ tự; giữ nguyên mọi test presign/audio-duration hiện có (đổi `taskTimingConfig` stub để chỉ còn `preListenSeconds`, dời phần `prepSeconds`/`responseSeconds` sang stub `ScoreTemplateService`).
- Test mới: `toPinnedItem_taskTypeNotInTemplate_fallsBackToTaskTimingConfig` — dùng `PERSONAL_INTRODUCTION`.
- Test mới cho `AttemptSummaryQueryService.getScoreContext` (hoặc test tương đương ở `AttemptService`): trả đúng `scoreTemplatePublicId` + tập section phân biệt từ danh sách `PinnedItem` giả lập.
- `./mvnw test -pl app`.

## Success Criteria

- Một attempt được pin từ snapshot dùng template V5 có `prepSeconds`/`responseSeconds` của mọi `PinnedItem` khớp đúng cột tương ứng trong bảng seed Phase 1 (test tích hợp mức service, dùng Mockito thay vì DB thật).
- 5 dạng audio-prompt Speaking vẫn tính `prepSeconds` động đúng công thức cũ (`preListenSeconds + audioDurationSeconds + preRecordSeconds`), chỉ đổi nguồn `preRecordSeconds`.
- `PERSONAL_INTRODUCTION` vẫn pin được bình thường (không ném `TaskTimingNotConfiguredException`) dù không có trong template.
- `mvnw test` xanh.

## Risks

- Seed giữ nguyên `responseSeconds` hiện có cho 11 dạng RECOMMENDED (không đổi hành vi). Thay đổi thời gian duy nhất: `WRITE_FROM_DICTATION` 30s → 120s (FIXED theo V5) — test phải cập nhật kỳ vọng này.
- Nếu quên xoá `NOT NULL` an toàn trên `pinned_exam_snapshots`, và DB dev đã có attempt cũ, `V16` sẽ fail — cùng lưu ý reset DB như Phase 2.
- `getScoreContext` mới thêm là API nội bộ dùng riêng cho Phase 5; nếu thiết kế field không đủ cho `ScoreAggregationService` (vd cần thêm `taskType` thay vì chỉ `section`), phải quay lại sửa record này — giữ nó dạng record đơn giản, dễ mở rộng không phá chữ ký cũ.
