# Phase 2: Lưu trữ rubric (tham số đầy đủ), migration V32, ghim vào mẫu đề, API đọc

## Mục tiêu

Lưu **phiên bản rubric với tham số số học ĐẦY ĐỦ** (không dùng `'{}'` nghĩa "theo code") trong DB, seed phiên bản 1 theo Score Guide 2025, ghim phiên bản vào mẫu đề
(`exam_definitions`) giống cách ghim trọng số, tạo bảng audit kích hoạt, và mở **API đọc** để vendor-web dựng trang luật chấm (màn A). Mọi phép tính lại và giải thích sau này đọc tham số từ hàng phiên bản.

## Stories/FR covered

- S1 (backend: dữ liệu luật chấm 22 task type), nền cho S5
- FR-02 (rubric có phiên bản; mẫu đề ghim), FR-11 (migration tạo bảng và seed)

## Files to read first

- `D:\GitHub\pte-org\docs\CODING_STANDARDS_API.md`, `docs\API_RESPONSE_SETUP.md`, `docs\COMMON_EXCEPTION_SETUP.md`, `docs\TEST_SCENARIOS_IAM.md`
- `pte-api/app/src/main/resources/db/migration/` (V1..V31, V12 không tồn tại; **V32** cho phase này, kiểm tra lại số cao nhất ngay trước khi tạo file). `V1__baseline.sql` quanh dòng 316 (`exam_definitions`), 2013 (`ux_exam_definitions_single_active`),
  2139 (seed mẫu chuẩn)
- `pte-api/app/src/main/java/com/pte/assessment/domain/ExamDefinition.java`, `.../internal/service/definition/ExamDefinitionCommandService.java` (`createDraft` ~46, `cloneToDraft` ~69), `HostExamTemplateService.java` (~127, ~239),
  `ExamDefinitionAdminService.java`, `.../assessment/ExamDefinitionService.java`, `dto/response/ExamDefinitionResponse.java`, `internal/controller/ExamDefinitionController.java`
- `pte-api/app/src/main/java/com/pte/attempt/dto/response/AttemptScoreContextView.java`
- `pte-api/app/src/main/java/com/pte/scoring/domain/AiEvaluation.java`, `AnswerEvaluation.java` (`answer_evaluations` SINGLE_TABLE)
- `pte-api/app/src/main/java/com/pte/scoring/internal/messaging/consumer/AiScoringWorker.java` (job resolve rubric lúc thực thi)
- `pte-api/app/src/test/java/com/pte/ModuleStructureTest.java`; runbook Postgres `pte-doc/projects/plans/quang-entity-consolidation/local-dev-runbook.md`
- Phase 1 (`RubricCatalog.defaultParameters`, `EffectiveRubric`, `RubricConstants`)

## Implementation steps

1. **Migration `V32__scoring_rubric_versions.sql`** (additive; chạy được trên DB hiện có và DB trống; reset DB chỉ là tùy chọn):
   - `scoring_rubric_versions`: `id`, `public_id` (uuid duy nhất), cột `BaseEntity` (`created_at/updated_at/deleted/lock_version`), `version_no` (int duy nhất), `status` (CHECK `DRAFT|PENDING|ACTIVE|REJECTED|RETIRED`),
     `parameters` (`jsonb` NOT NULL: **toàn bộ** tham số hiệu lực cho 22 task type: trọng số từng tiêu chí, Form band, cờ cổng, `azureBandMappingVersion`), `catalog_version` (int), `author_user_public_id`, `approver_user_public_id`,
     `rejection_reason` (<= 1000), `submitted_at`, `decided_at`, `activated_at`, `retired_at`. Chỉ mục duy nhất từng phần đúng một ACTIVE (mẫu `ux_exam_definitions_single_active`).
   - `scoring_rubric_activation_audits`: một dòng cho mỗi lần ACTIVATE (`id`, `public_id`, `version_public_id`, `previous_active_public_id`, `actor_user_public_id`, `activated_at`, `diff_summary` text/jsonb). Bảng chỉ INSERT (trigger chặn UPDATE/DELETE).
   - **Trigger bất biến chính xác**: với hàng có `status IN ('ACTIVE','RETIRED')` trước khi UPDATE: cho phép **duy nhất** chuyển `ACTIVE -> RETIRED` kèm đổi `status`, `retired_at`, `updated_at`, `lock_version`; mọi UPDATE khác
     (đặc biệt `parameters`, `catalog_version`, `version_no`, `author_user_public_id`, `approver_user_public_id`, `activated_at`) bị từ chối; `RETIRED` không đổi nữa; DELETE bị từ chối. Chuyển `DRAFT/PENDING/REJECTED -> ACTIVE` được phép (đặt `activated_at`, `approver_user_public_id`).
   - Seed phiên bản 1: `ACTIVE`, `catalog_version = 1`, `parameters` được sinh **đầy đủ** từ `RubricCatalog.defaultParameters` (trọng số mặc định = điểm tối đa Pearson; Form band mặc định; cổng bật; `azureBandMappingVersion = 1`) — viết bằng SQL/JSON tĩnh trong migration, không phụ thuộc mã lúc chạy;
     test đối chiếu JSON seed với `defaultParameters` hiện tại (nếu catalog đổi, test nhắc tạo phiên bản mới thay vì sửa seed).
   - `exam_definitions.rubric_version_public_id uuid` **NULLABLE ở mức DB** (an toàn cho DB hiện có và thao tác khác); backfill dòng hiện có về phiên bản 1. **Bắt buộc khác null ở service** cho mẫu đề mới (createDraft/cloneToDraft).
   - `answer_evaluations.rubric_version_public_id uuid` (null được: câu khách quan và dữ liệu cũ).
2. **Entity và repository**: `ScoringRubricVersion` và `ScoringRubricActivationAudit` ở `com.pte.scoring.domain`; repository ở gói mới `com.pte.scoring.internal.rubric.repository` (KHÔNG thêm vào `internal/repository`, đang 14 file).
   Thêm `rubricVersionPublicId` vào `ExamDefinition`, `ExamDefinitionResponse` (+mapper) và `AiEvaluation`.
3. **Cổng ghim (tránh vòng phụ thuộc)**: interface `ActiveRubricVersionPin` ở gói công khai `com.pte.assessment`; `scoring` hiện thực. `ExamDefinitionCommandService.createDraft` và vendor `cloneToDraft` ghim bản ACTIVE hiện hành;
   `HostExamTemplateService` sao chép ghim mẫu gốc; mẫu ACTIVE/RETIRED không đổi ghim. Không có hành động ghim lại mẫu DRAFT (LOW-4). Chạy `ModuleStructureTest`.
4. **Đọc rubric hiệu lực**: `RubricVersionService` dựng `EffectiveRubric` cho `(taskType, versionPublicId)` **chỉ từ hàng phiên bản** (`parameters`) kết hợp mô tả/cấu trúc catalog; `RubricResolver` resolve theo `examDefinitionPublicId` hoặc "ACTIVE" (practice).
   Quy tắc `catalog_version`: tạo phiên bản mới với `catalog_version` khác bản code chỉ bị **từ chối khi cấu trúc khác** (khóa hoặc thang tiêu chí trong `parameters` không khớp catalog code); khác chỉ ở văn bản mô tả thì cho phép (mô tả luôn hiển thị theo code, kèm `catalog_version` của hàng).
   `RubricParametersValidator` kiểm tra: khóa lạ, tiêu chí lạ, trọng số số nguyên 0-10, tiêu chí cổng > 0, tổng trọng số mỗi task type > 0, Form band không chồng lấn và có band tối đa, phiên bản bảng Azure tồn tại, **kích thước JSON <= giới hạn trong `RubricConstants`** (LOW-3), kiểm tra trước khi lưu.
   **Job đang chạy**: worker resolve rubric theo mẫu đề ghim **tại thời điểm thực thi** (ghi vào Javadoc `RubricResolver`); không có thủ tục triển khai riêng.
5. **API đọc** (`com.pte.scoring.internal.rubric.controller`, `/api/v1/scoring-rubrics`): `GET /task-types?versionId=`, `GET /task-types/{taskType}?versionId=` (tiêu chí, thang, mô tả mức, nguồn, trang, cổng, Form band hiệu lực, trọng số hiệu lực từ hàng, quy tắc khách quan, bảng Azure kèm cờ `calibrated=false` và nhãn "chưa hiệu chỉnh với dữ liệu người chấm", `catalogVersion`, `versionNo`),
   `GET /versions`, `GET /versions/{publicId}`. Mặc định phiên bản ACTIVE. Quyền: `PLATFORM_ADMIN`, `ACADEMIC_MANAGER`, `ACADEMIC_STAFF`, `PLATFORM_AUTHOR`. Vendor-only: Host không có endpoint này (Host thấy tham số trong phản hồi giải thích ở Phase 6). DTO record trong `internal/rubric/dto`, `ApiResponse`, lỗi chuẩn.
6. **Trọng số kỹ năng theo mẫu đề**: không nhân đôi dữ liệu; FE lấy từ `ExamDefinitionResponse.items` và nối theo task type (Phase 7). `ExamDefinitionResponse` thêm `rubricVersionPublicId` (nullable).
7. **Hợp đồng API và phân quyền**: cập nhật `ApiInventoryExportTest` (cần xác minh cách khẳng định số lượng) và test phân quyền theo `TEST_SCENARIOS_IAM.md`.
8. **Test**: unit `RubricParametersValidator`, `RubricVersionService`; test **"đổi mặc định trong code không đổi rubric hiệu lực của phiên bản đã có"** (thay `defaultParameters` giả lập, dựng lại rubric của phiên bản 1: không đổi); Postgres IT: V32 trên DB đã ở V31, chỉ mục ACTIVE duy nhất,
   trigger (cho phép đúng ACTIVE->RETIRED; chặn mọi UPDATE/DELETE khác trên ACTIVE/RETIRED; audit chỉ INSERT), **ca thứ tự flush**: kích hoạt bản mới khi bản cũ chưa retire phải thất bại, và quy trình đúng (native update retire + flush rồi activate; mô tả đầy đủ ở Phase 9) thành công trong một giao dịch;
   backfill; tạo mẫu đề mới ghim ACTIVE (service từ chối null); clone host giữ ghim; controller (22 task type, 404 cho mã lạ).

## Acceptance criteria

- V32 áp được trên DB đã ở V31 và DB trống; `ddl-auto: validate` không lệch; `exam_definitions.rubric_version_public_id` nullable ở DB nhưng service từ chối mẫu đề mới thiếu ghim.
- Tối đa một ACTIVE; seed `parameters` đầy đủ cho 22 task type; trigger đúng đặc tả; audit chỉ INSERT.
- Đổi mặc định trong code không đổi rubric hiệu lực của phiên bản đã có (test).
- Tạo phiên bản với `catalog_version` khác code: bị từ chối khi cấu trúc khác, cho phép khi chỉ khác mô tả (test cả hai).
- `GET /api/v1/scoring-rubrics/task-types` trả 22 task type; chi tiết đủ tiêu chí/mô tả/trang/cổng/Form band/nhãn chưa hiệu chỉnh; role ngoài danh sách nhận 403; Host không truy cập được.
- `ModuleStructureTest` và `PackageDensityTest` xanh.

## Validation commands

```powershell
cd D:\GitHub\pte-org\pte-api
.\mvnw.cmd -pl app -DskipTests compile
.\mvnw.cmd -pl app test -Dtest="RubricParametersValidatorTest,RubricVersionServiceTest,RubricReadControllerTest,RubricSeedParityTest,ExamDefinition*Test"
.\mvnw.cmd -pl app test -Dtest="RubricVersionMigrationIT,ModuleStructureTest,PackageDensityTest,SourceFileSizeTest,ApiInventoryExportTest"
```

## Design Constraints

- `docs/CODING_STANDARDS_API.md`, `API_RESPONSE_SETUP.md`, `COMMON_EXCEPTION_SETUP.md`, `TEST_SCENARIOS_IAM.md` bắt buộc; chỉ thêm trường tùy chọn vào `ExamDefinitionResponse`.
- Phiên bản ACTIVE/RETIRED bất biến hai lớp (service ở Phase 9, trigger ở phase này); tham số luôn đầy đủ trong hàng, không bao giờ ngầm "theo code".
- `assessment` không import từ `scoring`; chiều phụ thuộc `scoring -> assessment`.
- `Clock` inject cho mọi dấu thời gian; không `overrides`/văn bản tự do nào vào prompt.
- Một rubric dùng chung toàn nền tảng; Host/tenant không có đường đọc ghi quản trị rubric và không bao giờ thấy bản nháp.
- Migration `V32+`, không sửa `V1__baseline.sql`.
- Preflight: slice A (2026-11-04) đã đọc đủ `CODING_STANDARDS_API.md`, `API_RESPONSE_SETUP.md`, `COMMON_EXCEPTION_SETUP.md`, `TEST_SCENARIOS_IAM.md`; V31 là migration cao nhất trước V32; dạng JSON `parameters` định nghĩa một lần trong `RubricParametersCodec` + `RubricConstants.PARAM_*` (`{"azureBandMappingVersion":1,"taskTypes":{"<TASK>":{"traitWeights":{..},"traitScales":{..},"formBands":null|[{"minWords","maxWords","band"}],"gateEnabled":{..}}}}`), seed V32, validator và resolver dùng chung.
- Preflight slice B (2026-11-05): đọc lại `CODING_STANDARDS_API.md`, `API_RESPONSE_SETUP.md`, `COMMON_EXCEPTION_SETUP.md`. Quyết định ghim: `createDraft` vendor và `cloneToDraft` vendor (kể cả clone từ mẫu ACTIVE/RETIRED, vì bản clone là phiên bản mới) ghim bản rubric ACTIVE; Host `createFromDefault` sao chép ghim của mẫu chuẩn ACTIVE, Host `cloneToDraft` sao chép ghim của mẫu nguồn; nguồn có ghim null (dữ liệu cũ) thì ghim ACTIVE. Không có ACTIVE khi cần ghim: `NoActiveRubricVersionException` (409, `ExamDefinitionConstants.NO_ACTIVE_RUBRIC_VERSION` = `SCORE_TEMPLATE_NO_ACTIVE_RUBRIC_VERSION`), không lưu gì; constructor tương thích không có cổng ghim cũng thất bại đóng. activate/retire/sửa nháp không đổi ghim. `traitScales` (số nguyên >= 1 hoặc `"PER_WORD"`) được thêm vào `parameters`; validator từ chối thang khác catalog (`RUBRIC_PARAMETERS_STRUCTURE_MISMATCH`), `RubricResolver` thất bại đóng khi thang lưu khác catalog (`RUBRIC_VERSION_SCALE_DRIFT`, 500). V32 được sửa tại chỗ vì chưa áp ở DB local (`pte` đang ở Flyway 14); DB VPS chưa được kiểm tra trực tiếp. Cột `answer_evaluations.rubric_version_public_id` nằm ở lớp gốc `AnswerEvaluation` (SINGLE_TABLE, cùng bảng): đúng, giữ nguyên; chưa có chỗ ghi giá trị (phase sau).

## Quality and Testing State

- Quality: approved (receipt: quality/phase-02-rubric-persistence-pinning-receipt.json)
- Testing: partial: slices A+B unit tests 106/106 (RubricParametersValidatorTest 35, RubricVersionServiceTest 14, RubricReadControllerTest 14, RubricReadServiceTest 9, RubricResolverTest 10, RubricSeedParityTest 6, DefaultsDoNotChangeEffectiveRubricTest 3, ExamDefinitionRubricPinTest 6, HostExamTemplateRubricPinTest 6, ExamDefinitionRubricPinMappingTest 3) sau `clean test-compile` (2026-11-05); 6 lớp phase 1 và ModuleStructureTest/PackageDensityTest/SourceFileSizeTest/NoDirectClockAccessTest/RubricScoreSingleSourceTest/ApiInventoryExportTest xanh; toàn bộ `app` 4177 test, 0 lỗi, 112 bỏ qua (gồm 266 test assessment). Postgres IT written, skipped locally (no Docker): RubricVersionMigrationPostgresTest (12 test: backfill V31->V32, seed, chỉ mục ACTIVE, trigger, thứ tự flush, audit insert-only, cột pin nullable); chưa thực thi; phần "service từ chối null ở DB thật" chưa viết.

## Risks

- Baseline có thể dùng FK thật hoặc chỉ uuid logic: xác minh theo cách `exam_definition_items` đang làm.
- Seed JSON tĩnh lệch `defaultParameters` sau này: test `RubricSeedParityTest` báo sớm; sửa bằng phiên bản mới, không sửa seed.
- Mẫu DRAFT cũ mang ghim lạc hậu: chấp nhận (đúng nghĩa "ghim"); hiển thị ở FE.
- Test Postgres cần DB throwaway: nếu chưa có, test được bỏ qua có chú thích, không xóa.
