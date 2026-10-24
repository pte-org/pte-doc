# Phase 10: Chấm điểm B & báo cáo — GradingAssignment, ExamResult

## Requirements

Gộp `ExaminerAttemptAssignment`, `ExaminerGradingWork`, `ExaminerGradingIssue` thành `GradingAssignment`; bỏ `ExaminerAssignmentBatch`, `GradingCohort/Member`, `ScoringSessionState`; `AttemptReport` thành `ExamResult` (10–90 theo trọng số QuestionType); xoá `ScoreConfigFacade`. Đáp ứng FR-06 và luồng chấm → công bố → student xem kết quả.

## Design Constraints

- Đọc đầy đủ `docs/CODING_STANDARDS_API.md`, `docs/API_RESPONSE_SETUP.md`, `docs/COMMON_EXCEPTION_SETUP.md`, `docs/CODING_STANDARDS_WEB.md`. Ghi standards-read note vào progress update đầu tiên.
- Trạng thái chấm/công bố là field của `ExamSession`; loại trừ là `ExamResult.excluded`.
- Hành vi giữ kèm test: `grading-cohort/preview` và finalize tính từ trạng thái chấm `ExamSession` + `ExamResult.excluded`; `ScorePublicationLockService`, `GradingProgressListener` (`scoring/internal/listener`), `GradingReconciliationWorker` viết lại trên `ExamSession` (khoá công bố, tiến độ, đối soát).
- Preview phân công: gỡ `POST .../examiner-assignments/previews` và `POST .../{batchPublicId}/confirm`; giữ `GET roster`, `GET overview`, `POST /commit` với danh sách phân công đầy đủ trong request.
- Issues của GradingAssignment: bảng con `GradingIssue` (host lọc theo status trong `HostExaminerIssueController`). Điểm công bố là snapshot jsonb; điểm 4 kỹ năng + overall là cột thật.
- `organizationId` trên mọi aggregate; `ScoreConfigFacade` chỉ xoá sau khi consumer cuối đã chuyển.

## Steps

1. Thiết kế `GradingAssignment` (+ `GradingIssue`) thay ba entity cũ: `ExaminerAssignmentService`, `ExaminerAssignmentController`, `HostExaminerIssueController`, `StaffScoringService`/`StaffScoringQueryService`, `ExaminerWorkController`.
2. Đổi `ExaminerAssignmentController`: gỡ `previews` + `confirm`, `commit` nhận danh sách đầy đủ; xoá `ExaminerAssignmentBatch`.
3. Thay `GradingCohort`/`GradingCohortMember`/`ScoringSessionState` (`GradingCohortService`, `GradingCompletionEvaluator`) bằng field trên `ExamSession` (qua `SessionService`) và `ExamResult.excluded`; viết lại `ScorePublicationLockService`, `GradingProgressListener`, `GradingReconciliationWorker`.
4. Thiết kế `ExamResult` trong `reporting` thay `AttemptReport`: `ScoreAggregationService` tính 10–90 bằng trọng số QuestionType đọc trực tiếp từ itembank, `ReportService`, `ReportPublishService`, `ReportController`, `ReportPublishController`, `ReportingService`, `ReportingOverviewService`; công bố lưu snapshot; đổi field template của `ReportResponse` nếu có (xác minh khi cook).
5. Xoá `ScoreConfigFacade` (assessment) khi consumer cuối đã chuyển; xác nhận grep rỗng; cập nhật `ScoringOverviewService`, `SessionOverviewService`, `AttemptSummaryQueryService`, API student xem kết quả.
6. Sửa client cùng phase: `pte-web/packages/api-client/src/requests/scoring/assignments.ts` và UI phân công examiner (tenant-web), reporting requests; lint/typecheck/build theo `CODING_STANDARDS_WEB.md`; grep `previews`/`confirm`/`batchPublicId` trong client trả 0; cập nhật `seed-local-exam-ready.ps1` bước phân công/công bố.
7. Test: flow chấm AI + examiner → công bố → student xem kết quả (service-level, H2, stub); `excluded`, cohort preview/finalize, idempotency commit, khoá công bố đồng thời, reconciliation.
8. Cập nhật `V1__baseline.sql` (`grading_assignment`, `grading_issue`, `exam_result`, cột trạng thái trên `exam_session`); chạy compile, test toàn app, `ModuleStructureTest`, gate Postgres.

## Success Criteria

- Flow test chấm → công bố → student xem kết quả pass; cohort preview/finalize tính đúng từ `ExamSession` + `ExamResult.excluded` (test).
- Không còn `Examiner*` assignment/work/issue cũ, `ExaminerAssignmentBatch`, `GradingCohort*`, `ScoringSessionState`, `AttemptReport`, `ScoreConfigFacade`.
- Client không còn `previews`/`confirm`; build pass.
- Gate dev DB (profile `local-schema`): từ `D:\GitHub\pte-org\pte-api`, DB `pte` trống trên Docker Postgres 17; `APP_SPRING_PROFILES=local-schema` trong `.env.local`; `docker compose --env-file .env.local -f docker-compose.yml -f docker-compose.services.yml up -d --no-deps --build app` khởi động (health UP) với Hibernate dựng schema, `db/dev-seed/*.sql` chạy xong, và `POST /api/v1/auth/login` thành công với `admin@test.local` và `host.e2e@test.local`. Ràng buộc chỉ Postgres phải có trong `db/dev-seed/000-postgres-objects.sql`. Không chạy được thì ghi "not verified", không bỏ qua im lặng.
- `.\mvnw.cmd -pl app -DskipTests compile`, `.\mvnw.cmd -pl app test`, `ModuleStructureTest` xanh; ghi số `@Entity` và số bảng do Hibernate dựng.

## Quality and Testing State

- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementing this phase)
- Testing: not started

## Risks

- Mất cohort freeze: khoá trạng thái trên `ExamSession` khi công bố (đã chấp nhận).
- Công thức 10–90 đổi vì trọng số về QuestionType: so với test và seed hiện có.
- Khoá công bố/reconciliation phụ thuộc cohort: viết lại trên ExamSession và test đồng thời.
