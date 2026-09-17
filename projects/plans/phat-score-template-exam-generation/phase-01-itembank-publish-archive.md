# Phase 1: Itembank — Publish/Archive/Unarchive câu hỏi (chỉ platform) + facade random/count PUBLISHED+SHARED

Bổ sung bắt buộc theo User Decision 1 (không có trong FR gốc nhưng không có nó thì FR-10 "chỉ lấy câu PUBLISHED" luôn trả về 0 câu). **Cập nhật 2026-09-17:** theo quyết định mới nhất của user ("Chỉ có platform mới được quyền thao tác với question bank, host không có quyền thêm, chỉnh sửa, xem question bank"), phase này cũng rút quyền HOST khỏi toàn bộ `QuestionController` — không còn ma trận quyền SHARED/PRIVATE×platform/host, chỉ còn "platform hay không". Đồng thời dựng 2 method facade chỉ-đọc mà `assessment` (Phase 2) cần để sinh đề mà không load toàn bộ bank vào memory — sinh đề chỉ random trong pool PUBLISHED+SHARED, không còn khái niệm "theo tenant của host".

## Requirements

Chỉ `PLATFORM_ADMIN`/`PLATFORM_AUTHOR` được list/xem/tạo/publish/archive/unarchive câu hỏi — host (`HOST_ADMIN`/`HOST_AUTHOR`) không còn endpoint nào trong `QuestionController` gọi được. Publish (DRAFT→PUBLISHED, có validate đủ field), archive (DRAFT/PUBLISHED→ARCHIVED), unarchive (ARCHIVED→DRAFT) hoạt động đúng bảng chuyển trạng thái. `assessment` có 2 method facade để đếm và random câu PUBLISHED+SHARED theo `taskType` bằng query DB, không load cả bảng, không cần biết caller là ai.

## Files

**Sửa**
- `pte-api/app/src/main/java/com/pte/itembank/ItembankService.java` — thêm `publish(publicId, caller)`, `archive(publicId, caller)`, `unarchive(publicId, caller)` (chỉ kiểm tra `caller.isPlatformUser()`, không còn nhánh ownership PRIVATE-theo-tenant); thêm `countPublishedByTaskTypes(Set<PteTaskType>)`, `randomPublishedQuestionIds(PteTaskType, int)` — **không nhận `CurrentUser`/tenant**.
- `pte-api/app/src/main/java/com/pte/itembank/internal/controller/QuestionController.java` — đổi `@PreAuthorize` cấp lớp từ 4 role xuống còn `hasAnyRole('PLATFORM_ADMIN','PLATFORM_AUTHOR')` (áp dụng cho `list`/`get`/`create` sẵn có lẫn 3 endpoint publish/archive/unarchive mới thêm ở phase này); thêm `POST /questions/{publicId}/publish`, `POST /questions/{publicId}/archive`, `POST /questions/{publicId}/unarchive`.
- `pte-api/app/src/main/java/com/pte/itembank/internal/repository/QuestionRepository.java` — thêm 2 query native: gộp đếm theo `pte_task_type` (`WHERE status='PUBLISHED' AND visibility='SHARED' AND pte_task_type IN (...) GROUP BY pte_task_type`), random N `publicId` theo `pte_task_type` cùng điều kiện lọc (`ORDER BY random() LIMIT`) — cả 2 đều là literal `visibility='SHARED'`, không có tham số tenant.
- `pte-api/app/src/main/java/com/pte/itembank/internal/constant/ItembankConstants.java` — thêm mã lỗi cho transition không hợp lệ.

**Thêm**
- `pte-api/app/src/main/java/com/pte/itembank/internal/exception/InvalidQuestionStatusTransitionException.java` — 409 khi publish câu ARCHIVED, hoặc unarchive câu không phải ARCHIVED.
- `pte-api/app/src/main/java/com/pte/itembank/internal/repository/TaskTypeCountProjection.java` — interface projection `(String getTaskType(), long getCount())` cho query đếm gộp.
- `pte-api/app/src/main/resources/db/migration/V18__itembank_generation_index.sql` — composite index trên `questions (pte_task_type, status, visibility)` (đổi từ `tenant_id` sang `visibility` vì query sinh đề giờ lọc theo `visibility='SHARED'` literal, không còn theo tenant — xác nhận lại `V17` là migration mới nhất trước khi đặt tên `V18`).
- `pte-api/app/src/test/java/com/pte/itembank/internal/controller/QuestionControllerSecurityTest.java` — test role cấp controller (theo mẫu `ScoreTemplateControllerSecurityTest` của Plan A).

## Steps

1. `publish()`: load câu hỏi, kiểm tra `caller.isPlatformUser()` (không phân biệt SHARED/PRIVATE nữa — mọi câu hỏi giờ chỉ còn platform ghi được); **chỉ cho phép từ DRAFT** (PUBLISHED → no-op idempotent trả lại response; ARCHIVED → từ chối 409 bằng `InvalidQuestionStatusTransitionException`); chạy `QuestionValidationHelper.validate()` — câu thiếu field bị chặn (ném lại `QuestionValidationException` có sẵn), chỉ đổi `status` sang PUBLISHED khi validate qua.
2. `archive()`: cùng kiểm tra `caller.isPlatformUser()`, không cần validate lại; DRAFT hoặc PUBLISHED → ARCHIVED; ARCHIVED → no-op idempotent.
3. `unarchive()`: cùng kiểm tra `caller.isPlatformUser()`; **chỉ** ARCHIVED → DRAFT (không nhảy thẳng về PUBLISHED); trạng thái khác → từ chối 409 `InvalidQuestionStatusTransitionException`. Câu phải được publish lại (có validate) mới quay lại pool random.

   Bảng chuyển trạng thái cuối cùng: DRAFT→PUBLISHED (publish, validate), DRAFT/PUBLISHED→ARCHIVED (archive), ARCHIVED→DRAFT (unarchive). Mọi chuyển khác bị từ chối.
4. Đổi `@PreAuthorize` cấp lớp của `QuestionController` xuống còn `PLATFORM_ADMIN`/`PLATFORM_AUTHOR`, thêm 3 endpoint publish/archive/unarchive — quyền ghi chi tiết (bước 1–3) chỉ còn là defense-in-depth vì controller đã chặn host từ tầng ngoài.
5. Thêm `countPublishedByTaskTypes(Set<PteTaskType>)`: một query gộp `WHERE status='PUBLISHED' AND visibility='SHARED' AND pte_task_type IN (...) GROUP BY pte_task_type`, trả về map đầy đủ (task type không có câu nào trả 0, không phải thiếu key) — không nhận tham số caller/tenant.
6. Thêm `randomPublishedQuestionIds(PteTaskType, int)`: một query `ORDER BY random() LIMIT :n` cùng điều kiện `status='PUBLISHED' AND visibility='SHARED'`, trả về đúng tối đa N `publicId` (có thể ít hơn N nếu bank không đủ — caller ở Phase 2 tự quyết định coi đó là shortage).
7. Thêm migration composite index hỗ trợ 2 query trên; verify tay trên Postgres thật (áp nối tiếp từ V1) vì không có Testcontainers trong test suite hiện tại.

## Tests

- `ItembankServiceTest` (file có sẵn), thêm case:
  - `publish_incompleteQuestion_throwsAndKeepsDraft` — câu thiếu field bắt buộc theo `PteTaskType` bị chặn, `status` không đổi.
  - `publish_byPlatformCaller_succeeds`.
  - `publish_byHostCaller_forbidden` — defense-in-depth ở tầng service dù controller (bước 4) đã chặn từ ngoài.
  - `publish_archivedQuestion_rejectedWithInvalidTransition`.
  - `publish_alreadyPublished_isIdempotentNoOp`.
  - `archive_fromDraftOrPublished_succeeds`.
  - `archive_alreadyArchived_isIdempotentNoOp`.
  - `archive_byHostCaller_forbidden`.
  - `unarchive_archivedQuestion_becomesDraft_notPublished`.
  - `unarchive_draftOrPublished_rejectedWithInvalidTransition`.
  - `unarchive_byHostCaller_forbidden`.
  - `countPublishedByTaskTypes_excludesDraftArchivedAndPrivate` — dữ liệu test gồm cả câu PRIVATE (legacy/dormant) để chứng minh nó không bao giờ lọt vào kết quả dù không truyền tenant.
  - `randomPublishedQuestionIds_returnsAtMostNPublishedSharedIds` — cùng logic loại trừ PRIVATE.
- `QuestionControllerSecurityTest` (mới):
  - `hostAdmin_callsAnyQuestionEndpoint_forbidden` (list/get/create/publish/archive/unarchive).
  - `hostAuthor_callsAnyQuestionEndpoint_forbidden`.
  - `platformAdmin_callsQuestionEndpoints_allowed`.
  - `platformAuthor_callsQuestionEndpoints_allowed`.
- `mvn test -pl app` (từ `pte-api/`) xanh cho `itembank`.
- Verify tay: `docker compose up` (Postgres 17), áp Flyway tới `V18`, xác nhận log không lỗi và `ddl-auto: validate` pass lúc app khởi động.

## Success Criteria

- Publish một câu thiếu field bắt buộc bị chặn, `status` không đổi trong DB (test `publish_incompleteQuestion_throwsAndKeepsDraft`).
- Host (`HOST_ADMIN`/`HOST_AUTHOR`) gọi bất kỳ endpoint nào của `QuestionController` (kể cả `GET /questions`) đều nhận 403 — cả ở tầng controller lẫn tầng service (defense-in-depth).
- `countPublishedByTaskTypes`/`randomPublishedQuestionIds` chỉ trả về câu `PUBLISHED AND visibility='SHARED'`, loại hoàn toàn DRAFT/ARCHIVED/PRIVATE (kể cả PRIVATE legacy nếu có sẵn trong DB), không cần biết caller là ai.
- Migration `V18` verify thành công trên Postgres thật (log xác nhận, không suy đoán).

## Risks

- Query `ORDER BY random()` không kiểm chứng được bằng test tự động (không Testcontainers, không chạy Postgres trong CI) — mitigation: verify tay 1 lần trên Postgres thật; unit test chỉ phủ logic gọi/kết quả qua repository thật trong `@DataJpaTest` (H2 hỗ trợ `RAND()` khác cú pháp Postgres — nếu H2 không chạy được native query này, bỏ qua test tầng repository cho riêng query random, chỉ giữ test tầng service với repository mock).
- MEDIUM (mới): rút quyền host khỏi `QuestionController` **không được merge/deploy trước khi Phase 8 xóa xong `pte-app`'s `features/authoring`** — host console hôm nay gọi thẳng `/questions` qua module đó; xem Dependencies của `plan.md`.
- LOW: `ItembankAccessPolicy.canRead()` (dùng bởi `get()`/`listAccessible()`) vẫn còn nhánh cho host đọc PRIVATE của tenant mình — về mặt thực tế nhánh này giờ không bao giờ được thực thi nữa (không host nào còn gọi tới `QuestionController`), coi là dead code chấp nhận được, không refactor trong phase này (ngoài phạm vi, không có yêu cầu dọn).
