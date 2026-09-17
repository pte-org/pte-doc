# Phase 3: Session — Tạo kỳ thi bằng chọn skill (all-or-nothing) + bỏ `SessionComposition`

Covers phần wiring của FR-08/FR-13 (host gọi API tạo kỳ thi bằng skill, không còn `snapshotPublicId` thủ công) và phần `SessionComposition` của FR-15 ("bỏ hẳn luồng cũ phía host"). Không đụng blueprint thủ công phía platform (Phase 5), không đụng assign Class (Phase 4).

## Requirements

`POST /sessions` nhận `{name, skills, opensAt, closesAt, examMode, lockdownMode, capacity}` thay vì `snapshotPublicId`, gọi `AssessmentService.generateAndPublish(...)` rồi tạo `ExamSession` trong cùng transaction — lỗi ở bước sinh đề không để lại session mồ côi. `SessionComposition` bị xóa hoàn toàn khỏi domain/API; attempt pin toàn bộ item của snapshot (không còn subset).

## Files

**Sửa**
- `pte-api/app/src/main/java/com/pte/session/internal/dto/request/CreateSessionRequest.java` — bỏ `snapshotPublicId`, thêm `Set<String> skills` (`@NotEmpty @Size(min=1, max=4)`).
- `pte-api/app/src/main/java/com/pte/session/internal/service/SessionLifecycleService.java` — `create()` gọi `assessmentService.generateAndPublish(request.name(), request.skills(), caller)` thay vì `getSummary(snapshotPublicId)`, dùng `snapshot.publicId()` trả về để set `ExamSession.snapshotPublicId`.
- `pte-api/app/src/main/java/com/pte/session/domain/ExamSession.java` — bỏ field `composition`/`addCompositionItem()`.
- `pte-api/app/src/main/java/com/pte/session/internal/dto/response/SessionResponse.java` — bỏ field `composition`.
- `pte-api/app/src/main/java/com/pte/session/internal/mapper/SessionMapper.java` — bỏ `toItem()`/mapping `composition`.
- `pte-api/app/src/main/java/com/pte/session/internal/controller/SessionController.java` — bỏ endpoint `PUT /{publicId}/composition`, bỏ inject `CompositionService`.
- `pte-api/app/src/main/java/com/pte/session/dto/response/EntitlementResponse.java` — bỏ field `composition`.
- `pte-api/app/src/main/java/com/pte/session/internal/service/EntitlementService.java` — `checkEntitlement()` không còn build `composition`; `checkProctorAssignment()` (dòng ~59) cũng đang gọi `sessionRepository.findWithCompositionByPublicId` — đổi sang query phẳng tương ứng.
- `pte-api/app/src/main/java/com/pte/session/internal/repository/ExamSessionRepository.java` — bỏ `@EntityGraph(attributePaths = "composition")` khỏi mọi query (dùng `findByPublicIdAndTenantId` sẵn có thay cho `findWithCompositionByPublicIdAndTenantId`, tương tự cho biến thể không tenant).
- `pte-api/app/src/main/java/com/pte/session/internal/constant/SessionConstants.java` — bỏ hằng số không còn dùng (`TASK_TYPE_NOT_IN_SNAPSHOT`, `SNAPSHOT_REFERENCE_REQUIRED`, `COMPOSITION_ITEMS_REQUIRED`, `TASK_TYPE_REQUIRED`, `SECTION_REQUIRED`, `TIMING_OVERRIDE_POSITIVE`, `MAX_PLAY_COUNT_POSITIVE`), thêm hằng số validate `skills`.
- `pte-api/app/src/main/java/com/pte/attempt/internal/service/SnapshotPinService.java` — `pin()` bỏ 3 map lọc (`includedTaskTypes`, `responseOverrideByTaskType`, `maxPlayCountByTaskType`), pin **toàn bộ** `content.items()` theo `orderIndex` gốc; `toPinnedItem()` không còn tham số override, `PinnedItem.maxPlayCountOverride` luôn để `null`.

**Xóa**
- `pte-api/app/src/main/java/com/pte/session/domain/SessionComposition.java`
- `pte-api/app/src/main/java/com/pte/session/internal/service/CompositionService.java`
- `pte-api/app/src/main/java/com/pte/session/internal/dto/request/SetCompositionRequest.java`
- `pte-api/app/src/main/java/com/pte/session/internal/dto/request/CompositionItemRequest.java`
- `pte-api/app/src/main/java/com/pte/session/dto/response/CompositionItemResponse.java`
- `pte-api/app/src/main/java/com/pte/session/internal/exception/TaskTypeNotInSnapshotException.java`
- `pte-api/app/src/test/java/com/pte/session/internal/service/CompositionServiceTest.java`

**Thêm**
- `pte-api/app/src/main/resources/db/migration/V19__session_drop_composition.sql` — `DROP TABLE session_compositions` (xác nhận lại `V18` là migration mới nhất trước khi đặt tên `V19`).

## Steps

1. Đổi `CreateSessionRequest` sang nhận `skills` thay vì `snapshotPublicId`; sửa `SessionLifecycleService.create()` gọi `assessmentService.generateAndPublish(...)` **trước** khi tạo entity `ExamSession` — để `InsufficientQuestionBankException`/`InvalidSectionException` (Phase 2) lan truyền ra ngoài trước khi có bất kỳ `save()` nào phía `session`.
2. Xóa toàn bộ domain/DTO/service liên quan `SessionComposition` liệt kê ở "Files > Xóa"; xóa field `composition` khỏi `ExamSession`/`SessionResponse`/`EntitlementResponse`, xóa mapping tương ứng trong `SessionMapper`.
3. Đơn giản hóa `ExamSessionRepository`: bỏ `@EntityGraph(attributePaths = "composition")` (không còn association này), gộp lại dùng các query `findByPublicIdAndTenantId`/`findByPublicId` phẳng đã có sẵn.
4. Sửa `SnapshotPinService.pin()`: bỏ hoàn toàn 3 map lọc theo composition, pin thẳng mọi item của `content.items()` theo `orderIndex`; `toPinnedItem()` bỏ tham số `responseOverrideByTaskType`/`maxPlayCountByTaskType`, luôn dùng `templateItem.responseSeconds()`/`jsonTiming.responseSeconds()` làm `responseSeconds` (không còn override), không set `maxPlayCountOverride`.
5. Thêm migration xóa bảng `session_compositions`; verify tay trên Postgres thật (áp nối tiếp từ V1).
6. Chạy lại toàn bộ test hiện có đang dựng `SessionComposition`/`CompositionItemRequest`/`SetCompositionRequest` (`SessionLifecycleServiceTest`, `SnapshotPinServiceTest`, mapper test khác) và sửa theo hợp đồng mới — đây là hệ quả biên dịch bắt buộc, không phải phạm vi mới.

## Tests

- `SessionLifecycleServiceTest`:
  - `create_delegatesToAssessmentGenerateAndPublish_usesReturnedSnapshotPublicId`.
  - `create_generationFails_noSessionSaved` — `assessmentService.generateAndPublish()` ném lỗi → `sessionRepository.save()` không bao giờ được gọi (Mockito `verifyNoInteractions`).
  - `create_invalidSkillCount_rejectedByValidation` (0 hoặc >4 skill).
- `SnapshotPinServiceTest`:
  - `pin_pinsAllSnapshotItemsInOriginalOrder_noCompositionFilter` — snapshot có N item bất kỳ (không filter theo taskType) → `PinnedExamSnapshot` có đúng N `PinnedItem`, đúng `orderIndex` gốc.
  - `pin_responseSecondsAlwaysFromTemplateOrJson_neverOverridden` — không còn nhánh override, `responseSeconds` luôn bằng giá trị template/json.
  - `pin_maxPlayCountOverrideAlwaysNull`.
- `EntitlementServiceTest`: `checkEntitlement` không còn field `composition` trong response (compile-level, không cần test hành vi riêng).
- `mvn test -pl app` xanh toàn bộ (không chỉ module `session`/`attempt`).

## Success Criteria

- Tạo kỳ thi bằng `skills` thành công tạo đúng 1 `ExamSession` trỏ tới snapshot vừa sinh; lỗi sinh đề (thiếu bank/skill không hợp lệ) không để lại session nào.
- `grep -r "SessionComposition\|SetCompositionRequest\|CompositionItemRequest\|CompositionItemResponse\|CompositionService" pte-api/app/src` → 0 kết quả.
- Attempt pin toàn bộ item của snapshot — số `PinnedItem` luôn bằng số item của snapshot nguồn, không còn khái niệm subset.
- Migration `V19` verify thành công trên Postgres thật, bảng `session_compositions` không còn tồn tại.

## Risks

- HIGH: `SnapshotPinService.pin()` là code chấm điểm cốt lõi đã có coverage dày từ Plan A Phase 3 — sửa sai nhánh timing (không chỉ bỏ filter) sẽ âm thầm phá logic dynamic-prep của 5 dạng audio-prompt Speaking; mitigation: chỉ xóa đúng 3 map lọc + tham số liên quan, không đụng nhánh tính `prepSeconds`/`preRecordSeconds`/`preListenSeconds`, chạy lại nguyên bộ `SnapshotPinServiceTest` cũ trước khi thêm test mới.
- MEDIUM: Xóa cột/entity có thể để sót tham chiếu trong test khác module (`attempt`, đã ghi nhận ở Plan A là nơi từng phải sửa kèm) — mitigation: `grep` toàn repo trước khi coi phase xong, không chỉ dừng ở hết lỗi biên dịch.
