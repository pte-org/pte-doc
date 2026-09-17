# Phase 1: Score Template module — entity, migration V14 + seed V5, admin API

Covers spec FR-01, FR-02, FR-03, FR-04, FR-05, FR-06. Story P1 #1 ("xem template V5 ACTIVE") và P1 #2 ("tạo version mới, sửa DRAFT, kích hoạt") — phần backend; UI ở Phase 6.

## Requirements

Một module Spring Modulith mới `com.pte.scoretemplate` lưu `ScoreTemplate`/`ScoreTemplateItem` versioned (DRAFT/ACTIVE/RETIRED), luôn có đúng 1 bản ACTIVE, migration seed sẵn template APEUNI V5 ở trạng thái ACTIVE với đủ 22 dòng khớp bảng spec, và API cho platform admin tạo/sửa/kích hoạt (host/module khác chỉ đọc).

## Files

**Tạo mới**
- `pte-api/app/src/main/java/com/pte/scoretemplate/package-info.java` — `@ApplicationModule(displayName = "ScoreTemplate")`.
- `pte-api/app/src/main/java/com/pte/scoretemplate/ScoreTemplateService.java` — facade công khai duy nhất, chỉ `getActive()` và `getByPublicId(UUID)` (dùng bởi assessment/attempt/scoring/reporting ở các phase sau).
- `pte-api/app/src/main/java/com/pte/scoretemplate/domain/ScoreTemplate.java` — extends `BaseEntity`; `code`, `version`, `name`, `status`.
- `pte-api/app/src/main/java/com/pte/scoretemplate/domain/ScoreTemplateItem.java` — extends `BaseEntity`; `taskType`, `section`, `sequence`, `minCount`, `maxCount`, `prepSeconds`, `responseSeconds`, `timingMode`, `scoringMethod`, `overallWeight`, `speakingWeight`, `writingWeight`, `readingWeight`, `listeningWeight` (`BigDecimal`, `NUMERIC(5,2)`); `@ManyToOne` về `ScoreTemplate` (cascade ALL từ phía template, mirror `ExamSnapshot`/`SnapshotItem`).
- `pte-api/app/src/main/java/com/pte/scoretemplate/domain/enums/ScoreTemplateStatus.java` — `DRAFT, ACTIVE, RETIRED`.
- `pte-api/app/src/main/java/com/pte/scoretemplate/domain/enums/TimingMode.java` — `FIXED, RECOMMENDED`.
- `pte-api/app/src/main/java/com/pte/scoretemplate/domain/enums/ScoringMethod.java` — `AI_SPEECH, AI_TEXT, OBJECTIVE, UNSCORED`.
- `pte-api/app/src/main/java/com/pte/scoretemplate/dto/response/ScoreTemplateResponse.java`, `ScoreTemplateItemResponse.java`.
- `pte-api/app/src/main/java/com/pte/scoretemplate/dto/request/ReplaceScoreTemplateItemsRequest.java` (sửa DRAFT — thay toàn bộ danh sách item + tên) và `ScoreTemplateItemRequest.java`.
- `pte-api/app/src/main/java/com/pte/scoretemplate/internal/repository/ScoreTemplateRepository.java` — `findWithItemsByPublicId`, `findByStatus(ACTIVE)`, `findMaxVersionByCode`, `findAllByCodeForUpdate(code)` (`@Lock(PESSIMISTIC_WRITE)`, dùng cho activate/clone).
- `pte-api/app/src/main/java/com/pte/scoretemplate/internal/service/ScoreTemplateAdminService.java` — `listAll`, `getForEdit`, `cloneToDraft(sourcePublicId, caller)`, `replaceItems(draftPublicId, request, caller)`, `activate(publicId, caller)`.
- `pte-api/app/src/main/java/com/pte/scoretemplate/internal/service/ScoreTemplateActivationValidator.java` — FR-05 (đủ 22 task type scored, `0 ≤ min ≤ max`, `max ≥ 1`, weight ≥ 0, tổng weight mỗi skill > 0).
- `pte-api/app/src/main/java/com/pte/scoretemplate/internal/controller/ScoreTemplateController.java`.
- `pte-api/app/src/main/java/com/pte/scoretemplate/internal/mapper/ScoreTemplateMapper.java`.
- `pte-api/app/src/main/java/com/pte/scoretemplate/internal/exception/ScoreTemplateNotFoundException.java`, `NoActiveScoreTemplateException.java`, `ScoreTemplateNotDraftException.java` (sửa template không phải DRAFT; Plan A không có API xóa), `ScoreTemplateConcurrentModificationException.java` (409, xem Steps #2), `ScoreTemplateValidationException.java`.
- `pte-api/app/src/main/java/com/pte/scoretemplate/internal/constant/ScoreTemplateConstants.java`.
- `pte-api/app/src/main/resources/db/migration/V14__score_template.sql` — bảng `score_templates`, `score_template_items` (cột như trên, style giống `V7__assessment.sql`: `id/public_id/created_at/updated_at/deleted` chuẩn `BaseEntity`), unique index thường trên `(code, version)`, **partial unique index** `WHERE status = 'ACTIVE'` đảm bảo tối đa 1 ACTIVE ở tầng DB, và `INSERT` seed 22 dòng V5 ở `status = 'ACTIVE'` (bảng seed đầy đủ bên dưới).

**Sửa**
- `pte-api/app/src/test/java/com/pte/ModuleStructureTest.java` — thêm `"scoretemplate"` vào `containsExactlyInAnyOrder(...)` (13 module nghiệp vụ + `shared`), nếu không test này fail ngay khi module mới xuất hiện.

## Bảng seed V5 (22 dòng, dùng cho migration + test)

| Seq | taskType | section | min | max | prep | resp | timingMode | scoringMethod | overall | speaking | writing | reading | listening |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | READ_ALOUD | SPEAKING | 6 | 7 | 35 | 40 | FIXED | AI_SPEECH | 4 | 9 | 0 | 0 | 0 |
| 2 | REPEAT_SENTENCE | SPEAKING | 10 | 12 | 3 | 15 | FIXED | AI_SPEECH | 7 | 16 | 0 | 0 | 17 |
| 3 | DESCRIBE_IMAGE | SPEAKING | 5 | 6 | 25 | 40 | FIXED | AI_SPEECH | 15 | 31 | 0 | 0 | 0 |
| 4 | RE_TELL_LECTURE | SPEAKING | 2 | 3 | 10 | 40 | FIXED | AI_SPEECH | 6 | 13 | 0 | 0 | 13 |
| 5 | ANSWER_SHORT_QUESTION | SPEAKING | 5 | 6 | 3 | 10 | FIXED | AI_SPEECH | 2 | 0 | 0 | 0 | 4 |
| 6 | SUMMARIZE_GROUP_DISCUSSION | SPEAKING | 2 | 3 | 10 | 120 | FIXED | AI_SPEECH | 9 | 19 | 0 | 0 | 20 |
| 7 | RESPOND_TO_A_SITUATION | SPEAKING | 2 | 3 | 10 | 40 | FIXED | AI_SPEECH | 6 | 13 | 0 | 0 | 0 |
| 8 | SUMMARIZE_WRITTEN_TEXT | WRITING | 2 | 2 | 0 | 600 | FIXED | AI_TEXT | 7 | 0 | 28 | 23 | 0 |
| 9 | WRITE_ESSAY | WRITING | 1 | 1 | 0 | 1200 | FIXED | AI_TEXT | 7 | 0 | 31 | 0 | 0 |
| 10 | FILL_BLANKS_READING_WRITING | READING | 5 | 6 | 0 | 90 | RECOMMENDED | OBJECTIVE | 7 | 0 | 0 | 25 | 0 |
| 11 | MC_READING_MULTIPLE | READING | 2 | 3 | 0 | 90 | RECOMMENDED | OBJECTIVE | 1 | 0 | 0 | 5 | 0 |
| 12 | RE_ORDER_PARAGRAPHS | READING | 2 | 3 | 0 | 75 | RECOMMENDED | OBJECTIVE | 3 | 0 | 0 | 9 | 0 |
| 13 | FILL_BLANKS_READING | READING | 4 | 5 | 0 | 90 | RECOMMENDED | OBJECTIVE | 6 | 0 | 0 | 20 | 0 |
| 14 | MC_READING_SINGLE | READING | 2 | 3 | 0 | 60 | RECOMMENDED | OBJECTIVE | 0.5 | 0 | 0 | 3 | 0 |
| 15 | SUMMARIZE_SPOKEN_TEXT | LISTENING | 1 | 1 | 0 | 600 | FIXED | AI_TEXT | 4 | 0 | 18 | 0 | 10 |
| 16 | MC_LISTENING_MULTIPLE | LISTENING | 2 | 3 | 0 | 20 | RECOMMENDED | OBJECTIVE | 1 | 0 | 0 | 0 | 3 |
| 17 | FILL_BLANKS_LISTENING | LISTENING | 2 | 3 | 0 | 60 | RECOMMENDED | OBJECTIVE | 3 | 0 | 0 | 0 | 8 |
| 18 | HIGHLIGHT_CORRECT_SUMMARY | LISTENING | 2 | 3 | 0 | 20 | RECOMMENDED | OBJECTIVE | 0.5 | 0 | 0 | 3 | 2 |
| 19 | MC_LISTENING_SINGLE | LISTENING | 2 | 3 | 0 | 20 | RECOMMENDED | OBJECTIVE | 0.5 | 0 | 0 | 0 | 2 |
| 20 | SELECT_MISSING_WORD | LISTENING | 1 | 2 | 0 | 20 | RECOMMENDED | OBJECTIVE | 1 | 0 | 0 | 0 | 1 |
| 21 | HIGHLIGHT_INCORRECT_WORDS | LISTENING | 2 | 3 | 0 | 30 | RECOMMENDED | OBJECTIVE | 4 | 0 | 0 | 13 | 8 |
| 22 | WRITE_FROM_DICTATION | LISTENING | 3 | 4 | 0 | 120 | FIXED | OBJECTIVE | 5 | 0 | 23 | 0 | 13 |

Ghi chú quy ước: cột `prep` của 5 dòng audio-prompt (REPEAT_SENTENCE, RE_TELL_LECTURE, ANSWER_SHORT_QUESTION, RESPOND_TO_A_SITUATION, SUMMARIZE_GROUP_DISCUSSION) lưu **preRecordSeconds** theo quy ước spec (RS/ASQ ép về 3 dù bảng gốc ghi "No preparation"); giá trị này trùng khớp với `preRecordSeconds` hiện có trong `task-timing.json` — dùng để đối chiếu chéo khi viết test. "<1%" trong bảng spec = `0.50`.

**Cột `resp` của 11 dòng RECOMMENDED lấy nguyên giá trị `responseSeconds` hiện có trong `task-timing.json`** (spec: "giữ giá trị hiện tại làm giới hạn per-question, con số V5 chỉ hiển thị tham khảo") — không đổi hành vi Reading/Listening. Riêng `WRITE_FROM_DICTATION` là FIXED 120s theo V5 ("2 minutes per question"), khác 30s hiện tại — thay đổi có chủ đích theo spec.

## Steps

1. Dựng entity + enum + migration `V14__score_template.sql` (bảng + 2 unique index + seed 22 dòng ở trên), khớp chính xác cột Hibernate sẽ derive từ entity (để `ddl-auto: validate` pass).
2. Viết `ScoreTemplateActivationValidator` theo đúng FR-05 (không bắt tổng = 100), và `ScoreTemplateAdminService` cho 4 nghiệp vụ: liệt kê, clone-sang-DRAFT (copy toàn bộ item, `version` = max hiện có của `code` + 1), thay toàn bộ item của một DRAFT, kích hoạt (trong 1 `@Transactional`: validate → set ACTIVE cũ hiện tại về RETIRED → set bản mới ACTIVE).
   - **Chống race:** `activate` và `cloneToDraft` lấy pessimistic write lock (`@Lock(PESSIMISTIC_WRITE)`, theo pattern `findOwnedWithLock` của session) trên các template cùng `code` trước khi đọc ACTIVE / tính `max(version)`; và bắt `DataIntegrityViolationException` (partial unique index ACTIVE hoặc unique `(code, version)`) → ném `ScoreTemplateConcurrentModificationException` (409), không để lọt 500.
3. Chặn sửa mọi template không ở trạng thái DRAFT (immutability — FR không cho sửa bản đã ACTIVE/đã bị snapshot tham chiếu).
4. Viết `ScoreTemplateController` + facade `ScoreTemplateService`: **mọi** endpoint HTTP (`GET` list, `GET` active, `GET` theo publicId, clone, sửa item, kích hoạt) chỉ `PLATFORM_ADMIN` trong Plan A — list/get-by-id trả được DRAFT/RETIRED nên tuyệt đối không mở cho host. Host chỉ cần template ACTIVE ở Plan B (sinh đề), khi đó mới mở riêng `GET active`. Các module khác đọc qua facade Java, không qua HTTP.
5. Thêm `"scoretemplate"` vào `ModuleStructureTest`, chạy `ApplicationModules.verify()` để chắc module mới không vi phạm boundary (chỉ phụ thuộc `shared`; kiểm tra có cần khai báo `allowedDependencies` tới `itembank` không nếu tái dùng `PteTaskType`/`PteSection` — nếu Modulith cảnh báo, khai `taskType`/`section` trong `ScoreTemplateItem` là `String` thay vì import enum của `itembank`, giữ module hoàn toàn độc lập).
6. Viết test tự-động parse `V14__score_template.sql` (đọc file classpath bằng regex/tách theo dấu phẩy trên các dòng `INSERT ... VALUES (...)`) và so từng ô với bảng 22 dòng ở trên — không cần DB thật.
7. Chạy `docker compose --env-file .env.local -f docker-compose.yml up` + khởi động `app` một lần thủ công, xác nhận log Flyway áp `V14` thành công và Hibernate `validate` không lỗi (đặc biệt cú pháp partial unique index Postgres) — bước xác minh thủ công, không tự động hoá trong CI ở phase này.

## Tests

- `ScoreTemplateActivationValidatorTest` (JUnit + AssertJ, không Spring context): đủ 22 task type / thiếu 1 loại / `minCount > maxCount` / `maxCount = 0` / weight âm / tổng weight 1 skill = 0 → mỗi case đúng exception hoặc pass.
- `ScoreTemplateAdminServiceTest` (Mockito, mirror style `SnapshotPublishServiceTest`): kích hoạt set ACTIVE cũ → RETIRED trong cùng lần gọi; kích hoạt template không hợp lệ → không đổi trạng thái gì; sửa item trên template không phải DRAFT → ném `ScoreTemplateNotDraftException`; clone copy đúng số item và tăng `version`; repository ném `DataIntegrityViolationException` khi activate/clone → service ném `ScoreTemplateConcurrentModificationException`.
- Controller security test (mirror test phân quyền controller hiện có): role host gọi bất kỳ endpoint template nào → 403.
- `ScoreTemplateServiceTest` (facade): `getActive()` không tìm thấy ACTIVE → `NoActiveScoreTemplateException`; `getByPublicId()` trả về template dù đang RETIRED (không lọc theo status).
- `ScoreTemplateSeedMigrationTest` (parse file SQL, mô tả ở Steps #6) — so khớp 22×13 giá trị.
- Chạy toàn bộ: `./mvnw test -pl app` (hoặc `mvnw.cmd test` trên PowerShell) từ `pte-api/`.

## Success Criteria

- `mvnw test` xanh, gồm cả `ModuleStructureTest` với `"scoretemplate"` trong danh sách 14 module.
- `ScoreTemplateSeedMigrationTest` xác nhận 22 item khớp bảng V5 — thỏa trực tiếp success criterion đầu tiên của spec.
- `ScoreTemplateService.getActive()` (gọi qua test) trả về đúng template APEUNI V5 ACTIVE ngay sau khi migration chạy.
- Kích hoạt một template khác qua `ScoreTemplateAdminService.activate` → template ACTIVE cũ chuyển RETIRED, không bao giờ có 2 bản ACTIVE cùng lúc (unit test + partial unique index ở DB thật).
- Xác minh thủ công: `docker compose up` khởi động sạch, Flyway log "Successfully applied 1 migration to schema... (V14)", không có `SchemaManagementException`.

## Risks

- Partial unique index Postgres không tương đương gì trong H2 `create-drop` (test profile) — mitigation: không viết test dựa vào index này ở tầng repository; coi service-level transactional retire-then-activate là nguồn đảm bảo chính, index chỉ là lưới an toàn cho race condition thật trên Postgres, xác minh thủ công.
- Nếu `ScoreTemplateItem.taskType`/`section` import thẳng enum của `itembank` (`PteTaskType`, `PteSection`) mà không khai `allowedDependencies`, `ModuleStructureTest` có thể fail hoặc cảnh báo phụ thuộc ẩn — mitigation: ưu tiên dùng `String` (giống cách `PinnedItem`/`ScoringAnswer` đã làm với `taskType`/`section` xuyên module), tránh phụ thuộc cứng vào `itembank`.
- Seed 22 dòng dễ gõ sai một ô (đặc biiệt cột weight) — mitigation: test parse-and-compare ở Steps #6 là bắt buộc, không được bỏ qua.
