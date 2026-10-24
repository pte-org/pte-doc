# Phase 4: Nội dung A — QuestionType, Question

> **Cập nhật sau merge `dev` (PR #82/#83, 2026-10-24):** partner đã gỡ module `rubric` (RubricRevision/Criterion/CriterionLevel, `RubricController`) và tính năng giải thích AI của practice (PracticeExplanation/Job/Outbox, `PracticeExplanationController`, `PracticeRubricBindingService`); practice nay chấm qua module scoring (`PracticeScoringRequest/Route`, `PracticeScoringDispatcher/Worker`) với trạng thái chấm nằm trên `PracticeSessionItem` (migration V130/V131). Hệ quả: Phase 4 bỏ Rubric; Phase 11 không còn explanation/job/outbox; số aggregate đích 25 → 24; các ngưỡng `@Entity` ≤ 45 và bảng ≤ 55 giữ nguyên.

## Requirements

> **Quyết định khi cook phase 4 (2026-10-24):** `TaskRuntimeProfile` và `TaskRuntimeContract` chỉ nhân bản bảng allowlist đã nằm trong code (`TaskRuntimeProfileRegistry`, một phiên bản, luôn ACTIVE) nên bỏ bảng và để service đọc thẳng registry; `TaskTypePublicationUsage` thay bằng hai cột sẵn có `firstPublishedAt`/`runtimeLockedAt` của `QuestionType`, được ghi qua `QuestionTypeService.recordPublishedUse` khi kích hoạt score template. `QuestionOption` thành `@Embeddable` trong bảng con `question_options` (giữ `publicId` của từng option). `ScoreConfigFacade` và việc chuyển trọng số ScoreTemplate sang `QuestionType` **dời sang phase 5**: nó chỉ có người dùng khi `scoretemplate` bị xoá, nên repoint 13 file một lần ở đó thay vì hai lần.


Gộp `QuestionTypeDefinition` + `TaskRuntimeProfile` + `TaskRuntimeContract` + `TaskTypePublicationUsage` + trọng số ScoreTemplate thành `QuestionType`; `Question` + `QuestionOption` thành `Question`. Rubric đã bị gỡ ở dev nên không thuộc phase này. Đáp ứng story P2 (CRUD QuestionType kèm runtime config).

## Design Constraints

- Đọc đầy đủ `docs/CODING_STANDARDS_API.md`, `docs/API_RESPONSE_SETUP.md`, `docs/COMMON_EXCEPTION_SETUP.md`; sửa client thì đọc `docs/CODING_STANDARDS_WEB.md`. Ghi standards-read note vào progress update đầu tiên.
- Phase này KHÔNG xoá module `scoretemplate`: nó vẫn phục vụ số câu/thời gian/scoringMethod cho assessment/session cho đến phase 5.
- Cột `runtime*` chỉ ở `QuestionType`; runtime config là jsonb đọc nguyên khối (`@JdbcTypeCode(SqlTypes.JSON)`, không `columnDefinition`). Options Question: jsonb nếu chỉ đọc nguyên khối, bảng con nếu `QuestionDeletionService`/practice lọc theo option.
- Trọng số overall/speaking/writing/reading/listening là cột thật của QuestionType; `taskType` và `organizationId` là cột lọc thật.

## Steps

1. Thiết kế `QuestionType` trong `itembank` (thay `QuestionTypeDefinition`, `TaskRuntimeProfile`, `TaskRuntimeContract`, `TaskTypePublicationUsage`); cập nhật `QuestionTypeController`, `TaskTypeController`, `TaskRuntimeProfileService`, `TaskTypePublicationUsageService` (dùng truy vấn ExamVersion ở phase 5, tạm adapter), thêm trọng số vào QuestionType (thay đổi additive cho client).
2. Hợp nhất enum `ScoringMethod` trùng (`scoring/domain/enums/ScoringMethod.java` và `scoretemplate/domain/enums/ScoringMethod.java`) về một enum trong `itembank`; chuyển `TaskTypeScoringMethods` (`scoretemplate/internal/service`) sang `itembank` dựa trên QuestionType; cập nhật mọi import.
3. (Dời sang phase 5, xem quyết định ở đầu file) Tạo `ScoreConfigFacade` trong module `assessment` (chủ sở hữu ExamDefinition, nằm trên itembank nên không vòng phụ thuộc) với public API đọc trọng số (từ QuestionType), scoringMethod và timing (tạm đọc từ `ScoreTemplateService` của scoretemplate). Liệt kê consumer và phase chuyển: assessment/session → phase 5; attempt (`SnapshotPinService`) → phase 8; scoring (`ScoringMethodResolver`) → phase 9; reporting/`ScoreAggregationService` → phase 10 (xoá facade ở phase 10).
4. Thiết kế `Question` (+options, đáp án, media refs qua `MediaAsset`, revision): cập nhật `QuestionController`, `QuestionDeletionService`, validation; giữ DTO.
5. (Bỏ) Rubric đã bị gỡ ở dev; grep lại `com.pte.rubric` khi cook để chắc không còn tham chiếu.
6. (Dời sang phase 5) Repoint mọi import `com.pte.scoretemplate` ngoài module đó sang `ScoreConfigFacade` (13 file đã grep 2026-10-24): assessment `SnapshotPublishService`, `ExamGenerationService`, `BlueprintService`, `AssessmentService`; session `ExamOrchestrationService`, `ExamPreflightResponse`; attempt `SnapshotPinService`; scoring `ScoringMethodResolver`, `ExaminerWorkflowQueryService`, `ExaminerGuidelinesResponse`; reporting `ScoreAggregationService` (grep lại khi cook để bắt file mới). Facade cung cấp DTO thay thế trong `assessment/dto` cho `ScoreTemplateItemResponse` và `ScoreTemplateFeasibilityResponse` để public DTO của session/scoring không còn mang kiểu scoretemplate. Cập nhật consumer khác (practice) qua public API; chuyển test itembank, bảo toàn test hành vi CRUD.
7. Seed V1 (dựng dần): task types PTE đầy đủ với trọng số + runtime, question mẫu; sửa client additive (`pte-web` requests/types của question type) nếu thêm field; chạy lint/typecheck/build theo `CODING_STANDARDS_WEB.md`.
8. Cập nhật `V1__baseline.sql` (`question_type`, `question`, `question_option` nếu bảng con), chạy compile, test toàn app, `ModuleStructureTest`, gate Postgres.

## Success Criteria

- CRUD QuestionType kèm runtime + trọng số không cần entity runtime/contract riêng (test).
- (Phase 5) Chỉ còn một enum `ScoringMethod`; `ScoreConfigFacade` tồn tại với danh sách consumer/phase được ghi trong javadoc/phase notes.
- (Phase 5) `grep -r "com.pte.scoretemplate" app/src/main/java --include=*.java` ngoài thư mục `scoretemplate/` chỉ còn khớp trong `ScoreConfigFacade` (và class nội bộ của nó).
- Không còn `QuestionTypeDefinition`, `TaskRuntimeProfile`, `TaskRuntimeContract`, `TaskTypePublicationUsage`; `scoretemplate` vẫn còn.
- Gate dev DB (profile `local-schema`): từ `D:\GitHub\pte-org\pte-api`, DB `pte` trống trên Docker Postgres 17; `APP_SPRING_PROFILES=local-schema` trong `.env.local`; `docker compose --env-file .env.local -f docker-compose.yml -f docker-compose.services.yml up -d --no-deps --build app` khởi động (health UP) với Hibernate dựng schema, `db/dev-seed/*.sql` chạy xong, và `POST /api/v1/auth/login` thành công với `admin@test.local` và `host.e2e@test.local`. Ràng buộc chỉ Postgres phải có trong `db/dev-seed/000-postgres-objects.sql`. Không chạy được thì ghi "not verified", không bỏ qua im lặng.
- `.\mvnw.cmd -pl app -DskipTests compile`, `.\mvnw.cmd -pl app test`, `ModuleStructureTest` xanh; ghi số `@Entity` và số bảng do Hibernate dựng.

## Quality and Testing State

- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementing this phase)
- Testing: not started

## Risks

- Facade trở thành chỗ trú vĩnh viễn: ghi phase xoá (10) trong phase notes và kiểm ở phase 10.
- Seed question phải qua validation publish ở phase 5: dùng dữ liệu đủ runtime ngay từ đây.
