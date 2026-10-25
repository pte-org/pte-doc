# Phase 5: scoring

## Requirements

> **Quyết định khi cook phase-05-scoring (2026-10-25):** scoring/internal/service gom thành examiner/ai/objective/selection/grading/review/staff (còn ScoringCommandService, ScoringIngestService ở gốc); exception gom ở phase 3. 6 file lớn tách bằng collaborator package-private tạo bằng new trong bean sở hữu (không thêm bean): ExaminerScoringService 623->201, ObjectiveScoringService 419->72, GradingCohortService 347->296, ExaminerDraftCommandService 325->254, ScoringReviewReadQueryService 306->269, ExaminerWorkspaceReadRepository 469->215 (+repository/workspace). Một số lớp được mở public tối thiểu để dùng chéo package; test chuyển cạnh lớp được test.

Tách file lớn và gom `scoring/internal/service` (38 file phẳng):

| File | Dòng |
|---|---|
| `scoring/internal/service/ExaminerScoringService.java` | 617 |
| `scoring/internal/repository/ExaminerWorkspaceReadRepository.java` | 469 |
| `scoring/internal/service/ObjectiveScoringService.java` | 419 |
| `scoring/internal/service/GradingCohortService.java` | 345 |
| `scoring/internal/service/ExaminerDraftCommandService.java` | 328 |
| `scoring/internal/service/ScoringReviewReadQueryService.java` | 302 |

## Đề xuất gom `scoring/internal/service`

| Package con | Lớp |
|---|---|
| `examiner/` | `Examiner*` (Assignment, DraftCommand, FinalizeSubmitter, ReviewVersion, Scoring, WorkQuery, WorkRecorder, WorkflowCommand, WorkflowQuery, WorkspaceQuery), `AttemptExaminerProgressReader` |
| `ai/` | `AiScoreDetailQueryService`, `AiScoringDispatcher`, `AiScoringResultPersistenceService`, `PracticeAiScoringService` |
| `objective/` | `ObjectiveScoringService`, `ScoringMethods`, `ScoringProfileRegistry`, `AnswerContentReader`, `AnswerPayloadDecoder` |
| `selection/` | `ScoreSourceSelectionService`, `ScoreSelectionReader`, `ScorePublicationLockService`, `ScoredAnswerQueryService` |
| `grading/` | `GradingCohortService`, `GradingCompletionEvaluator`, `GradingEvaluation`, `GradingReconciliationWorker`, `SessionGradingGateway` |
| `review/` | `ScoringReview*`, `ScoringAttemptReviewService` |
| `staff/` | `StaffScoringQueryService`, `StaffAttemptProgress`, `StaffSessionProgress`, `ScoringEligibilityQueryService` |
| gốc | `ScoringCommandService`, `ScoringIngestService` |

## Design Constraints

- `ExaminerScoringService` (617): tách theo luồng (nhận việc/claim, lưu nháp, finalize, đọc workspace) — phần finalize đã có `ExaminerFinalizeSubmitter`, tận dụng.
- `ExaminerWorkspaceReadRepository` (469, SQL thuần): tách theo truy vấn (danh sách việc, chi tiết attempt, tiến độ), SQL giữ nguyên từng ký tự.
- Giữ nguyên thứ tự và ranh giới giao dịch của finalize → chọn nguồn điểm → `ScoringProgressChangedEvent` (đã sửa ở đợt gộp entity, phase 10).
- Listener `@TransactionalEventListener` / `@Async` giữ nguyên phase giao dịch.

## Steps

1. Dời file vào package con (commit riêng), sửa import.
2. Tách 6 file lớn; chạy test scoring sau mỗi lớp.
3. Cập nhật allowlist.

## Success Criteria

- Sáu file ≤ 300 dòng; `scoring/internal/service` gốc ≤ 15 file.
- Suite + test Postgres xanh; Docker gate: làm bài → chấm tay (claim, nháp, finalize) → công bố → học viên xem kết quả.

## Quality and Testing State

- Quality gate: approved (xem quality/phase-05-scoring-quality-report.json)
- Testing: passed (xem tests/phase-05-scoring-test-report.json)

## Risks

- Đây là luồng nhạy nhất (đã có bug finalize không chọn nguồn EXAMINER): bắt buộc chạy lại luồng chấm tay end-to-end trên Docker.
