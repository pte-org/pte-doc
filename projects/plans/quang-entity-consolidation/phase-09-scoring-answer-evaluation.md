# Phase 9: Chấm điểm A — AnswerEvaluation

## Requirements

Gộp `ScoringAnswer`, `ScoringAnswerAiDetail`, `ExaminerAnswerDraft`, `ExaminerAnswerScore` thành `AnswerEvaluation`; điểm nguồn được chọn nằm trên `AttemptAnswer`; thay `ExaminerGradingCommand`/`Event`/`ScoreSourceAudit` bằng `IdempotencyKey` + `AuditLog`. Đáp ứng story P1 "≤ 1 AI và ≤ 1 EXAMINER SUBMITTED; chọn nguồn chỉ cập nhật AttemptAnswer" và FR-08.

## Design Constraints

- Đọc đầy đủ `docs/CODING_STANDARDS_API.md`, `docs/API_RESPONSE_SETUP.md`, `docs/COMMON_EXCEPTION_SETUP.md`, `docs/CODING_STANDARDS_WEB.md` (client examiner). Ghi standards-read note vào progress update đầu tiên.
- `AnswerEvaluation` PHẢI giữ trạng thái dispatch AI từ `ScoringAnswer` (token dispatch, stale-retry, thời điểm, số lần thử) để `findScoringWork` (`ScoringAnswerRepository`, `ScoringCommandService`) hoạt động như cũ.
- Chi tiết AI và transcript jsonb; `attemptAnswerId`, `source`, `status`, `score`, `organizationId` là cột thật; unique (attemptAnswerId, source) và partial unique ≤ 1 EXAMINER SUBMITTED trong V1 (kèm kiểm tra service cho H2).
- `ScoringMethodResolver` thay bằng đọc `scoringMethod` từ item ExamVersion; không tra `scoreTemplatePublicId`.
- Hành vi giữ: `GET /examiner/work/{s}/{a}/commands/{requestPublicId}` lấy receipt từ `IdempotencyKey` (retention ≥ closesAt + 90 ngày); `GET /examiner/work/history` và `/{s}/{a}/history` từ `AuditLog` + `AnswerEvaluation`; `source-selection/preview` stateless; audit chọn nguồn → `AuditLog` (actor, role, before/after, requestPublicId).
- Teacher-score legacy và objective scoring giữ kết quả cũ.

## Steps

1. Thiết kế `AnswerEvaluation` trong `scoring` thay các entity trên; thêm vào `AttemptAnswer` nguồn điểm được chọn + điểm cuối (ghi qua public API theo ranh giới module).
2. Chuyển pipeline AI: `ScoringIngestService`, `ScoringCommandService`, `AiScoringResultPersistenceService`, `AiScoreDetailQueryService`, phần dùng chung của `PracticeAiScoringService`; giữ dispatch token + stale-retry; RabbitMQ giữ nguyên.
3. Thay `ScoringMethodResolver` bằng đọc ExamVersion item trong `ScoringEligibilityQueryService`, `ObjectiveScoringService`, `AnswerPayloadDecoder`; scoring chuyển consumer `ScoreConfigFacade` sang ExamVersion/QuestionType.
4. Chuyển luồng examiner draft/submit (`ExaminerDraftCommandService`, `ExaminerScoringService`, `ExaminerReviewVersionService`, `ExaminerWorkflowCommandService`/`QueryService`, `ExaminerWorkspaceQueryService`, `ExaminerWorkQueryService`) và xoá `ExaminerGradingCommand`/`Event` bằng `IdempotencyKey` + `AuditLog`; giữ `ExaminerWorkController`, `ScoringReviewController`, `HostScoreReviewController`.
5. Chuyển `ScoreSourceSelectionService`: chọn nguồn chỉ cập nhật `AttemptAnswer`, `ScoreSourceAudit` → `AuditLog`.
6. Cập nhật consumer: `ScoredAnswerQueryService`, `ScoringAttemptReviewService`, `ScoringReviewService`, `ScoringReviewReadQueryService`; `ExaminerGradingWork`/Assignment/Issue, các lớp cohort `GradingCompletionEvaluator`, `GradingCohortService`, `ScorePublicationLockService` và `reporting` đọc `AnswerEvaluation` qua adapter nội bộ (đến phase 10, nơi chúng được viết lại/xoá); grep `ScoringAnswer` trong `app/src/main` phải trả 0 cuối phase này.
7. Đổi field `templatePublicId` → `examDefinitionPublicId` trong `ReportScoringAnswerView`, `ExaminerGuidelinesResponse` (`AiEligibleAttemptView` đã xác minh không có field template, chỉ đổi cách đếm pool sang scoringMethod của ExamVersion); sửa client examiner/scoring requests trong `pte-web` (xác định bằng grep), lint/typecheck/build theo `CODING_STANDARDS_WEB.md`; cập nhật `seed-local-exam-ready.ps1` bước chấm.
8. Test: AI dispatch/stale-retry/đồng thời hai worker, objective, examiner draft/submit, ràng buộc ≤ 1 AI / ≤ 1 EXAMINER SUBMITTED, chọn nguồn chỉ cập nhật AttemptAnswer, receipt/history; flow test chấm AI + examiner (stub provider). Cập nhật `V1__baseline.sql` (`answer_evaluation`, cột chọn điểm, partial unique); chạy compile, test toàn app, `ModuleStructureTest`, gate Postgres.

## Success Criteria

- Mỗi `AttemptAnswer` có ≤ 1 AI và ≤ 1 EXAMINER SUBMITTED; chọn nguồn chỉ cập nhật `AttemptAnswer`; dispatch + stale-retry hoạt động với stub (test).
- Không còn `ScoringAnswer`, `ScoringAnswerAiDetail`, `ExaminerAnswerDraft`, `ExaminerAnswerScore`, `ExaminerGradingCommand/Event`, `ScoreSourceAudit`, `ScoringMethodResolver`.
- Gate dev DB (profile `local-schema`): từ `D:\GitHub\pte-org\pte-api`, DB `pte` trống trên Docker Postgres 17; `APP_SPRING_PROFILES=local-schema` trong `.env.local`; `docker compose --env-file .env.local -f docker-compose.yml -f docker-compose.services.yml up -d --no-deps --build app` khởi động (health UP) với Hibernate dựng schema, `db/dev-seed/*.sql` chạy xong, và `POST /api/v1/auth/login` thành công với `admin@test.local` và `host.e2e@test.local`. Ràng buộc chỉ Postgres (partial unique index của AnswerEvaluation) phải có trong `db/dev-seed/000-postgres-objects.sql`. Không chạy được thì ghi "not verified", không bỏ qua im lặng.
- `.\mvnw.cmd -pl app -DskipTests compile`, `.\mvnw.cmd -pl app test`, `ModuleStructureTest` xanh; ghi số `@Entity` và số bảng do Hibernate dựng.

## Quality and Testing State

- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementing this phase)
- Testing: not started

## Risks

- Module `scoring` 264 file dễ trượt: ưu tiên giữ test hành vi trước, xoá entity sau; chia commit nội bộ theo bước 2, 4, 5.
- Mất dispatch state gây chấm trùng/kẹt: test stale-retry và đồng thời trước khi xoá `ScoringAnswer`.
- Ranh giới với phase 10: `GradingAssignment`/cohort còn sống, adapter nội bộ phải rõ chủ.
