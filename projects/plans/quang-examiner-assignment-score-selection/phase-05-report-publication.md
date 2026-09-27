# Phase 05 — Readiness, report aggregation và publish snapshot

**Plan:** [plan.md](plan.md) · **Spec:** [spec.md](spec.md)  
**Covers:** P1 Host approval và Student report; FR-12, FR-15–18.  
**Depends on:** Phase 01–04.  
**Outcome:** Host chỉ publish cohort có đủ score hợp lệ; report lấy selected scores + pinned weights, và Student thấy snapshot ổn định sau publication.

## Mục tiêu

Khép vòng từ Host approval tới Student report. Reporting không còn aggregate `rawScore` trực tiếp cho answer AI-eligible; objective scoring hiện có giữ nguyên. Publish không tạo report một phần và report đã hiển thị không thay đổi do scoring/source update sau này.

## Backend work

1. **Readiness/preflight contract**
   - Reporting gọi scoring public facade cho tập submitted attempts thuộc session/cohort và nhận selected score + publishability, không đọc scoring repositories.
   - AI-eligible answer cần selected source và score tồn tại/complete/range-valid/provider-valid; Examiner source cần submitted score hợp lệ.
   - Trả structured blocking summary: attempt/answer-safe reference, section/task type, reason (no source, missing score, stub/nonpublishable); không publish bất kỳ report nào khi có blocker.
   - Objective answers vẫn lấy objective score theo cách cũ; UNSCORED không đóng góp.

2. **Selected-source aggregation**
   - Điều chỉnh `ScoreAggregationService` để resolve score per answer từ selected source trước khi group/average theo task type.
   - Áp dụng template weights/revision đã pin; không dùng active/current template mới hơn.
   - Giữ nguyên scale/rounding và objective semantics hiện hành; thêm test golden values cho mixed objective + AI-selected.
   - Không để report query re-run aggregation từ mutable live scores sau khi đã published.

3. **Approval và publication state machine**
   - Host command preflight → lấy version/lock → xác nhận toàn cohort vẫn đủ score/source → tạo snapshot → publish visibility barrier.
   - Audit approver, timestamp, cohort/version, score source decisions và kết quả publish; đảm bảo thao tác idempotent khi retry.
   - Concurrent score submit/source change không được chen vào giữa preflight và snapshot; dùng session/cohort lock hoặc compare-and-set versions, revalidate ngay trước commit.
   - Chặn source/score mutations sau khi publish cho các answers được snapshot; không làm report Student đổi dù có lỗi mutation ngoài luồng.
   - Nếu batch snapshot staging nhiều transaction, trạng thái session phải remain non-visible cho tới khi mọi report snapshot hoàn tất; retry tiếp tục hoặc rollback staging. Không expose partial reports.

4. **Stable report snapshot**
   - Lưu dữ liệu report cần cho Student một cách bất biến: overall/section scores, template revision, cohort/publication version và selected per-answer inputs hoặc snapshot đủ tái tạo/audit.
   - Chốt với `AttemptReport`/report read model hiện hành cách thêm snapshot không phá API tương thích; report reads của Student dùng snapshot đã publish, không gọi live aggregation.
   - Ngăn duplicate report/publication races bằng unique keys và state transition có transaction semantics.
   - Giữ tương thích với report đã `published` trước V62 nhưng chưa có snapshot: tiếp tục đọc theo raw-score aggregation legacy và trả `immutableSnapshot=false`; UI phải cảnh báo đây là kết quả cũ chưa được freeze. Report publish qua workflow mới luôn phải có snapshot.

5. **Host/Student UI integration**
   - Host review panel nhận readiness summary, nút approve/publish chỉ bật khi đủ điều kiện, confirmation nêu cohort count và version/cutoff.
   - Publish failure trả actionable missing answer summary; không báo thành công giả hoặc publish một phần.
   - Student report visibility tiếp tục ẩn trước Host publish; sau publish hiển thị snapshot. Không expose source/provenance nội bộ cho Student trừ khi API đã có yêu cầu rõ.

## Publication cutoff — quyết định đã chốt

- **Phương án A (2026-09-23):** chỉ publish sau khi session ở trạng thái `CLOSED`.
- Backend khóa session ở trạng thái đóng trước khi xác định cohort, sau đó thiết lập publication barrier và snapshot toàn bộ submitted attempts đủ điều kiện trong cùng transaction.
- Nếu có blocker, toàn bộ lệnh publish thất bại; Student không thấy snapshot một phần. Sau khi barrier đã được thiết lập, score/source mutations không được làm thay đổi kết quả đã publish.
- UI hiển thị trạng thái đóng, readiness, cohort count và xác nhận publish; trạng thái UI không thay thế backend invariant.

## Kiểm chứng và acceptance

- Readiness tests cho thiếu selected source, missing AI/Examiner score, stub, invalid score, zero hợp lệ, và đủ dữ liệu.
- Publish bị reject toàn bộ khi có blocker; không có `AttemptReport` Student-visible nào mới/partial.
- Aggregation golden tests: AI selected, Examiner selected, mixed source trong cùng task type, pinned template weights, objective unchanged, UNSCORED excluded.
- Snapshot stability: sau publish cố thay raw AI score, Examiner score hoặc selected source thì Student API vẫn trả snapshot cũ; mutation bị reject hoặc không ảnh hưởng snapshot.
- Transaction/race tests: Host publish song song với examiner submit/source apply hoặc attempt submission; chỉ một consistent publication wins, retry idempotent.
- Student report hidden pre-publish, visible post-publish; session multi-attempt publish có visibility barrier; host audit ghi actor/time/cohort/count.
- E2E P1: host assignment → examiner grading → source selection → readiness → approval/publish → student report.

**Acceptance:** report chỉ publish khi toàn cohort theo cutoff có selected publishable score cho mỗi AI-eligible answer; aggregate đúng template đã pin và Student-visible report không drift.

## Design Constraints

- Bắt buộc session `CLOSED` trước khi publish theo quyết định product A; backend xác minh và khóa trạng thái session.
- Readiness là backend invariant, không phải FE-only disable state.
- Publish không partial; snapshot visibility chỉ bật sau khi toàn cohort snapshot thành công.
- Report dùng selected score per answer và pinned template weights; objective/UNSCORED semantics không đổi.
- Student read path đọc immutable snapshot; report không được tính lại từ mutable scores.
- Các report đã publish trước V62 không có snapshot được giữ nguyên khả năng truy cập bằng aggregation legacy, có cờ `immutableSnapshot=false` và warning UI; đây là compatibility exception, không áp dụng cho report publish mới.
- Lock/version coordination giữa source selection, Examiner submission và publication phải được kiểm thử concurrent.

## Files

- Reporting snapshot/publication and cohort aggregation: `../pte-api/app/src/main/java/com/pte/reporting/internal/service/ReportPublishService.java`, `../pte-api/app/src/main/java/com/pte/reporting/internal/service/ReportSnapshot.java`, `../pte-api/app/src/main/java/com/pte/reporting/internal/service/ReportSnapshotCodec.java`, `../pte-api/app/src/main/java/com/pte/reporting/internal/service/ReportSnapshotScoreInput.java`, `../pte-api/app/src/main/java/com/pte/reporting/internal/service/ReportService.java`, `../pte-api/app/src/main/java/com/pte/reporting/internal/service/ScoreAggregationService.java`, `../pte-api/app/src/main/java/com/pte/reporting/internal/service/ReportScoreAggregation.java`, `../pte-api/app/src/main/java/com/pte/reporting/internal/constant/ReportingConstants.java`, `../pte-api/app/src/main/java/com/pte/reporting/domain/AttemptReport.java`, `../pte-api/app/src/main/java/com/pte/reporting/domain/ReportingDomainConstants.java`.
- Batched pinned score context/template reads: `../pte-api/app/src/main/java/com/pte/attempt/AttemptService.java`, `../pte-api/app/src/main/java/com/pte/attempt/internal/service/AttemptSummaryQueryService.java`, `../pte-api/app/src/main/java/com/pte/attempt/internal/repository/ExamAttemptRepository.java`, `../pte-api/app/src/main/java/com/pte/attempt/dto/response/AttemptScoreContextView.java`, `../pte-api/app/src/main/java/com/pte/scoretemplate/ScoreTemplateService.java`, `../pte-api/app/src/main/java/com/pte/scoretemplate/internal/repository/ScoreTemplateRepository.java`.
- Reporting API/contracts/migration: `../pte-api/app/src/main/java/com/pte/reporting/internal/controller/ReportPublishController.java`, `../pte-api/app/src/main/java/com/pte/reporting/internal/controller/ReportController.java`, `../pte-api/app/src/main/java/com/pte/reporting/internal/dto/response/ReportPublicationBlockerResponse.java`, `../pte-api/app/src/main/java/com/pte/reporting/internal/dto/response/ReportPublicationReadinessResponse.java`, `../pte-api/app/src/main/java/com/pte/reporting/internal/dto/response/ReportPublicationSummaryResponse.java`, `../pte-api/app/src/main/resources/db/migration/V62__examiner_score_selection_and_report_snapshots.sql`, `../pte-api/app/src/main/resources/db/migration/V64__published_attempt_report_lookup.sql`.
- Student report projection and persistence query: `../pte-api/app/src/main/java/com/pte/reporting/internal/dto/response/ReportResponse.java`, `../pte-api/app/src/main/java/com/pte/reporting/internal/mapper/ReportMapper.java`, `../pte-api/app/src/main/java/com/pte/reporting/internal/repository/AttemptReportRepository.java`.
- Cross-module publication cutoff/score barrier: `../pte-api/app/src/main/java/com/pte/session/SessionService.java`, `../pte-api/app/src/main/java/com/pte/session/internal/service/SessionLifecycleService.java`, `../pte-api/app/src/main/java/com/pte/session/internal/constant/SessionConstants.java`, `../pte-api/app/src/main/java/com/pte/scoring/internal/service/ScorePublicationLockService.java`, `../pte-api/app/src/main/java/com/pte/scoring/internal/service/AiScoringResultPersistenceService.java`, `../pte-api/app/src/main/java/com/pte/scoring/internal/messaging/consumer/AiScoringWorker.java`, `../pte-api/app/src/main/java/com/pte/attempt/internal/service/AttemptLifecycleService.java`, `../pte-api/app/src/main/java/com/pte/attempt/internal/service/ProctorCommandService.java`.
- Scoring facade, source records, and assignment publication fence: `../pte-api/app/src/main/java/com/pte/scoring/ScoringService.java`, `../pte-api/app/src/main/java/com/pte/scoring/domain/ScoringAnswer.java`, `../pte-api/app/src/main/java/com/pte/scoring/domain/ExaminerAnswerScore.java`, `../pte-api/app/src/main/java/com/pte/scoring/domain/enums/ScoringMethod.java`, `../pte-api/app/src/main/java/com/pte/scoring/internal/service/ExaminerAssignmentService.java`.
- Backend tests: `../pte-api/app/src/test/java/com/pte/reporting/internal/service/ReportPublishServiceTest.java`, `../pte-api/app/src/test/java/com/pte/reporting/internal/service/ReportSnapshotCodecTest.java`, `../pte-api/app/src/test/java/com/pte/reporting/internal/service/ReportServiceTest.java`, `../pte-api/app/src/test/java/com/pte/reporting/internal/service/ScoreAggregationServiceTest.java`, `../pte-api/app/src/test/java/com/pte/scoring/internal/service/AiScoringResultPersistenceServiceTest.java`, `../pte-api/app/src/test/java/com/pte/scoring/internal/messaging/consumer/AiScoringWorkerTest.java`, `../pte-api/app/src/test/java/com/pte/attempt/internal/service/AttemptLifecycleServiceTest.java`, `../pte-api/app/src/test/java/com/pte/attempt/internal/service/ProctorCommandServiceTest.java`, `../pte-api/app/src/test/java/com/pte/session/internal/service/SessionLifecycleServiceTest.java`.
- API client and web: `../pte-web/packages/api-client/src/requests/reporting/reports.ts`, `../pte-web/packages/api-client/src/requests/reporting/reports.test.ts`, `../pte-web/packages/api-client/src/types/reporting/index.ts`, `../pte-web/apps/tenant-web/features/exams/components/ReportPublicationPanel.tsx`, `../pte-web/apps/tenant-web/features/exams/components/SessionDetailView.tsx`, `../pte-web/apps/tenant-web/features/reports/StudentReportsView.tsx`, `../pte-web/apps/tenant-web/app/(dashboard)/student/results/page.tsx`, `../pte-web/apps/tenant-web/lib/navigation.tsx`, `../pte-web/apps/tenant-web/lib/navigationConstants.ts`.
- Attempt/score-template exception-message constants: `../pte-api/app/src/main/java/com/pte/attempt/internal/constant/AttemptConstants.java`, `../pte-api/app/src/main/java/com/pte/attempt/domain/AttemptDomainConstants.java`, `../pte-api/app/src/main/java/com/pte/attempt/domain/PinnedItem.java`, `../pte-api/app/src/main/java/com/pte/attempt/internal/service/SnapshotPinService.java`, `../pte-api/app/src/main/java/com/pte/scoretemplate/internal/constant/ScoreTemplateConstants.java`, `../pte-api/app/src/main/java/com/pte/scoretemplate/ScoreTemplateService.java`, `../pte-api/app/src/main/java/com/pte/scoretemplate/internal/service/ScoreTemplateAdminService.java`, `../pte-api/app/src/main/java/com/pte/scoretemplate/internal/controller/ScoreTemplateController.java`.

## Phase Checkpoint

- Unit tests: yes (user confirmed for Phases 03–05 on 2026-09-23)
- `ck:quality`: yes (user confirmed for Phases 03–05 on 2026-09-23)
- Hard-mode confirmation: required after the final test/quality gates for this implementation batch.
- Preflight: cutoff A is enforced in `SessionService.lockClosedForReportPublication`; publish reads a closed session cohort, validates selected scoring inputs through the scoring facade, persists immutable report snapshots atomically, and Student reads only published snapshots. Each snapshot distinguishes the exam content snapshot from the pinned score-template public ID/version. Objective answers without a score remain excluded from aggregation without blocking publish. Scoring writes are fenced by the publication lock; AI vendor calls run outside DB transactions and are revalidated under row locks before persistence.

## Quality and Testing State

- quality: not evaluated
- testing: not started
- Kế hoạch: aggregation/report unit tests; DB migration + transaction/concurrency integration; Host/Student route tests; full end-to-end workflow.
