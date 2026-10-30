# Phase 5: Nội dung B — ExamDefinition & ExamVersion

## Requirements

> **Quyết định khi cook phase 5 (2026-10-24):** (1) `ScoreTemplate`+items được chuyển nguyên vào module `assessment` thành `ExamDefinition` (+ `ExamDefinitionItem` embeddable, bảng con `exam_definition_items`); module `scoretemplate` bị xoá; `/api/v1/score-templates/**` đổi thành `/api/v1/exam-definitions/**`; **không** tạo `ScoreConfigFacade` vì consumer gọi thẳng `ExamDefinitionService` (API công khai của assessment). (2) `ExamSnapshot`+`SnapshotItem` thành `ExamVersion` + `ExamVersionItem` embeddable (`exam_version_items`, mỗi item có `publicId` ổn định); câu hỏi examiner đọc qua `ExamVersionRepository.findItemsForTenant`. (3) `BlueprintItem` thành embeddable; **`ExamBlueprint` được giữ** làm aggregate riêng vì là quy trình soạn đề tay có duyệt theo tenant, khác với đề cương cấu trúc của ExamDefinition — hợp nhất thêm chỉ đổi chỗ khái niệm; số aggregate đích của phase 5 là 3 (ExamDefinition, ExamBlueprint, ExamVersion) thay vì 2. (4) **Trọng số kỹ năng KHÔNG chuyển sang `QuestionType`** (giữ trên item của ExamDefinition) vì ExamVersion ghim definition theo version: trọng số nằm trên QuestionType (sửa được) sẽ làm điểm của đề đã publish bị trôi (FR-13). (5) `TemplatePolicy`/CUSTOM, `ScoringMethod` trùng, jsonb items và việc dựng ExamVersion đồng bộ (bỏ ExamForm/job) KHÔNG làm ở phase này: làm ở phase 7–8 khi attempt/session được viết lại. (6a) Hoãn có chủ đích: cột `runtime_*` vẫn nằm trên `ExamDefinitionItem` (mục tiêu "chỉ ở QuestionType và ExamVersion" đạt ở phase 8 khi attempt/scoring chuyển sang ExamVersion); chuyển kiểm tra runtime/section từ `SnapshotPinService` sang publish làm ở phase 8; `itemPublicId` của `ExamVersionItem` đã lưu và truy vấn được (`findItemsForTenant`) nhưng chưa lộ ra DTO, việc lộ ra và `AssessmentService.getExaminerPrompts` là scaffolding cho phase 8; `ExamDefinition` có `lockVersion` (@Version) để hai lần thay items chồng nhau không nhân đôi dòng; form nội bộ tenant-web giữ tên `templatePublicId` và ánh xạ tại biên API; nợ: `ExamDefinitionAdminService` (735 dòng) tách ở phase 7–8, hai file *Constants trong assessment gộp ở phase 10. (6) Đổi tên JSON tại biên HTTP assessment/session: `templatePublicId`→`examDefinitionPublicId` (draft/patch/session), `scoreTemplatePublicId/Version`→`examDefinitionPublicId/Version` (snapshot), `ExamPreflightResponse.template`→`examDefinition`; các view nội bộ và DTO attempt/scoring/reporting giữ `scoreTemplate*` cho tới phase 8–10 (nợ trong bảng spec).


> **Nhận từ phase 4:** `ScoreConfigFacade`, repoint 13 consumer của `com.pte.scoretemplate`, hợp nhất `ScoringMethod`/`TaskTypeScoringMethods` và chuyển trọng số overall/speaking/writing/reading/listening từ ScoreTemplateItem sang `QuestionType` được làm ở phase này (xem phase 4).


`ExamBlueprint` + `BlueprintItem` + phần số câu/thời gian/scoringMethod của ScoreTemplate thành `ExamDefinition`; `ExamSnapshot` + `SnapshotItem` thành `ExamVersion` đóng băng. Gỡ module `scoretemplate` và `/api/v1/score-templates/**`. Đáp ứng story P1 nội dung đóng băng và FR-03 (sinh version đồng bộ).

## Design Constraints

- Đọc đầy đủ `docs/CODING_STANDARDS_API.md`, `docs/API_RESPONSE_SETUP.md`, `docs/COMMON_EXCEPTION_SETUP.md`, `docs/CODING_STANDARDS_WEB.md` (sửa client wizard). Ghi standards-read note vào progress update đầu tiên.
- Items ExamVersion: jsonb đọc nguyên khối (nội dung, options, runtime contract, prep/response seconds, scoringMethod, `audioDurationSeconds`, timing); mỗi item có `itemPublicId` ổn định (phase 8 map `pinnedItemPublicId == examVersionItemPublicId`). Cột lọc (`organizationId`, `status`, `examDefinitionId`) là cột thật.
- ExamVersion bất biến sau publish; presign URL/expiry không đóng băng.
- Kiểm tra runtime/section (hiện ở `attempt/internal/service/SnapshotPinService`) chuyển sang publish; lỗi publish giữ mã/message.
- `ExamFormProvisioningService` KHÔNG viết lại ở phase này (xoá ở phase 7): public DTO của `AssessmentService` giữ ổn định để nó compile nguyên trạng.
- `ScoreConfigFacade` (assessment) chuyển nguồn từ scoretemplate sang ExamDefinition/ExamVersion, vẫn sống tới phase 10.

## Steps

1. Thiết kế `ExamDefinition` trong `assessment` (thay `ExamBlueprint`, `BlueprintItem`, và dữ liệu số câu min/max, prep/response seconds, scoringMethod của `ScoreTemplate`/`ScoreTemplateItem`): `BlueprintController`, `AssessmentService`; thêm endpoint quản lý cấu hình tương đương score-templates trên ExamDefinition.
2. Thiết kế `ExamVersion` thay `ExamSnapshot`/`SnapshotItem` và chuyển `SnapshotPublishService`, `SnapshotController`, `InternalSnapshotController`, `SnapshotPromptQueryService` sang đọc/ghi ExamVersion; sinh item `itemPublicId` ổn định.
3. Chuyển `ExamGenerationService` (`assessment/internal/service`) thành bộ dựng ExamVersion đồng bộ; `POST /sessions/{id}/generate` giữ path và response shape, `GET /sessions/{id}/generation` trả trạng thái suy ra từ ExamSession/ExamVersion (cập nhật `SessionController`, `ExamOrchestrationService`).
4. Chuyển kiểm tra runtime/section từ `SnapshotPinService` sang bước publish ExamVersion; `SnapshotPinService` tạm đọc ExamVersion qua `AssessmentService` DTO (xoá ở phase 8).
5. Gỡ module `scoretemplate` (entity, `ScoreTemplateController`, `ScoreTemplateAdminService`, `ScoreTemplateService`); feasibility tính từ ExamDefinition qua DTO của facade; chuyển nguồn `ScoreConfigFacade` sang ExamDefinition. Cập nhật danh sách module mong đợi trong `app/src/test/java/com/pte/ModuleStructureTest.java` (`all_sixteen_business_modules_plus_shared_are_detected`, bỏ `"scoretemplate"` và đổi tên test theo số module mới) trước khi chạy gate.
6. Đổi DTO `templatePublicId`/`scoreTemplatePublicId` → `examDefinitionPublicId` trong `CreateExamDraftRequest`, `PatchExamDraftRequest`, `SessionResponse`, `SnapshotResponse`, `SnapshotContentResponse`; field `ExamPreflightResponse.template` (kiểu `ScoreTemplateFeasibilityResponse`, đã xác minh) đổi thành feasibility của ExamDefinition; `POST /sessions/drafts` nhận `examDefinitionPublicId`.
7. Sửa client cùng phase: `pte-web/packages/api-client/src/requests/scoretemplate/index.ts` + `types/scoretemplate/index.ts` (gỡ/thay), `types/scheduling/index.ts`, `requests/scheduling/examOrchestration.test.ts`, `apps/tenant-web/features/exams/{hooks/useCreateExamWizardForm.ts,utils/validateCreateExamWorkflow.ts,utils/createExamWizard.ts,types/index.ts,api/index.ts}` và UI vendor dùng score-templates; chạy lint/typecheck/build theo `CODING_STANDARDS_WEB.md`; grep `score-templates`/`templatePublicId` trong client trả 0 (phần attempt/scoring/reporting xử lý ở phase 8–10, ghi nợ).
8. Seed V1: exam definition mẫu publish được qua validation; test ExamVersion bất biến, đóng băng `audioDurationSeconds`/scoringMethod, validation publish, builder đồng bộ; cập nhật `V1__baseline.sql`; chạy compile, test toàn app, `ModuleStructureTest`, gate Postgres.

## Success Criteria

- Publish tạo ExamVersion đóng băng đủ nội dung + runtime + scoringMethod + `audioDurationSeconds` với `itemPublicId` ổn định; sửa Question nguồn sau đó không đổi ExamVersion (test).
- `POST /sessions/{id}/generate` dựng ExamVersion đồng bộ cùng response shape; seed publish qua validation.
- Không còn `ExamBlueprint`, `BlueprintItem`, `ExamSnapshot`, `SnapshotItem`, module `scoretemplate`; `runtime*` chỉ ở QuestionType và items ExamVersion.
- `grep -r "com.pte.scoretemplate" app/src` trả 0 (cả main và test); `ModuleStructureTest` đã cập nhật danh sách module và xanh.
- Gate dev DB (profile `local-schema`): từ `D:\GitHub\pte-org\pte-api`, DB `pte` trống trên Docker Postgres 17; `APP_SPRING_PROFILES=local-schema` trong `.env.local`; `docker compose --env-file .env.local -f docker-compose.yml -f docker-compose.services.yml up -d --no-deps --build app` khởi động (health UP) với Hibernate dựng schema, `db/dev-seed/*.sql` chạy xong, và `POST /api/v1/auth/login` thành công với `admin@test.local` và `host.e2e@test.local`. Ràng buộc chỉ Postgres phải có trong `db/dev-seed/000-postgres-objects.sql`. Không chạy được thì ghi "not verified", không bỏ qua im lặng.
- `.\mvnw.cmd -pl app -DskipTests compile`, `.\mvnw.cmd -pl app test`, `ModuleStructureTest` xanh; ghi số `@Entity` và số bảng do Hibernate dựng.

## Quality and Testing State

- Quality gate: approved (xem quality/phase-05-...-quality-report.json)
- Testing: passed (xem tests/phase-05-...-test-report.json)

## Risks

- jsonb items lớn làm chậm `next-task`: cache theo versionId (phase 8) và so sánh query count với baseline phase 1.
- Hai nguồn sự thật giữa `SnapshotPinService` và ExamVersion tới phase 8: adapter chỉ đọc ExamVersion.
- Đổi tên field DTO làm vỡ attempt/scoring client nếu sót: các DTO đó đổi ở phase 8–10, ghi nợ rõ trong bảng spec.
