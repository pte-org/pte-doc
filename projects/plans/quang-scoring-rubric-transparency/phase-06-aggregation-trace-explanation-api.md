# Phase 6: Vết tổng hợp, snapshot v2, API giải thích điểm (Host/Examiner), tính lại không gọi AI

## Mục tiêu

Làm cho **mọi con số từ điểm tiêu chí đến điểm 10-90** giải thích được và khớp tuyệt đối báo cáo đã publish: thêm vết vào `ScoreAggregationService`, nâng snapshot lên `schemaVersion 2`, mở **API giải thích một lượt thi cho `HOST_ADMIN` (tenant mình) và `EXAMINER` (lượt thi được phân công)**,
kèm dịch vụ tính lại điểm câu từ điểm tiêu chí đã lưu (0 lời gọi AI). Vendor không có đường đọc dữ liệu lượt thi.

## Stories/FR covered

- S3 (giải thích khớp chính xác, chênh lệch 0); FR-02 (snapshot ghi phiên bản), FR-05 (tính lại không gọi AI), FR-07 (chuỗi giải thích theo kỹ năng và Overall)

## Files to read first

- `D:\GitHub\pte-org\docs\CODING_STANDARDS_API.md`, `API_RESPONSE_SETUP.md`, `COMMON_EXCEPTION_SETUP.md`, `TEST_SCENARIOS_IAM.md`
- `pte-api/app/src/main/java/com/pte/reporting/internal/service/ScoreAggregationService.java` (`aggregate`, `aggregateFromInputs`, `aggregateProvisional`, `aggregateBatchFromInputs`, `averageScoresByTaskType` (blank = expected − rows), `computeWeighted` (`SCALE_FLOOR 10`, `SCALE_SPAN 80`, HALF_UP))
- `.../reporting/internal/service/ReportSnapshot.java`, `ReportSnapshotScoreInput.java`, `ReportSnapshotCodec.java` (`SCHEMA_VERSION = 1`, `decode` từ chối khác 1), `AttemptScoreSummary.java`, `SkillScore.java`, `ReportScoreAggregation.java`, `ReportPublishService.java`, `ReportService.java`
- `.../reporting/internal/controller/ReportController.java` (`/api/v1/reports/attempts/{attemptPublicId}`, role hiện `HOST_ADMIN`/`PLATFORM_ADMIN`; kiểm tra tenant ở `ReportService`) — **không** mở rộng controller này; tạo controller riêng cho giải thích
- `.../reporting/internal/dto/response/ReportResponse.java`, `SkillScoreResponse.java`
- Cách ly giám khảo: `pte-api/app/src/main/java/com/pte/scoring/ScoringService.java` (`isAttemptAssignedToExaminer`, dòng ~95), `.../scoring/internal/service/examiner/ExaminerWorkQueryService.java` (`isAssignedToExaminer`, dòng ~44, dùng `GradingAssignmentRepository.existsByTenantIdAndSessionPublicIdAndAttemptPublicIdAndExaminerPublicId`).
  Lưu ý `ExaminerWorkGuard` là package-private trong `service/examiner` (không dùng trực tiếp từ `reporting`); `reporting` gọi qua `ScoringService.isAttemptAssignedToExaminer` (cần xác minh chữ ký, cần `sessionPublicId` của lượt thi từ `AttemptService`).
- `.../scoring/dto/response/ReportScoringAnswerView.java`, `ScoringService.getReportScoringInputsForAttempt`; `.../attempt/dto/response/AttemptScoreContextView.java`
- Phase 1-3 và 5: `RubricScorer`, `ScoreTrace`, `RubricResolver`, `RubricVersionService`, JSON `criteria_scores_json` có `scale`

## Implementation steps

1. **Mở rộng đầu vào báo cáo**: `ReportScoringAnswerView` (`com.pte.scoring.dto.response`, `@NamedInterface`) thêm `traitScores`, `rubricVersionPublicId`, nguồn điểm chọn (AI/EXAMINER). `ScoringService.getReportScoringInputsForAttempt` đọc `criteria_scores_json` (chỉ dòng `scale = PEARSON_V1`) và `rubric_version_public_id`.
   Dòng cũ (không `scale`) hoặc câu khách quan: `traitScores` rỗng, vết = mô tả quy tắc khách quan + điểm thô, hoặc "dữ liệu cũ, không có vết".
2. **Dịch vụ tính lại** `RubricRescoreService` (`internal/rubric/service`, công khai qua `ScoringService`): nhận `(answer, rubricVersionPublicId của câu)` -> điểm câu và `ScoreTrace` **chỉ từ điểm tiêu chí đã lưu + tham số đọc từ hàng phiên bản + `RubricScorer`**, không client vendor nào; RA dùng N đã lưu. Dùng cho lượt thi chưa publish.
   Tính lại luôn dùng **phiên bản ghim của câu**; không có tham số chọn phiên bản khác (HIGH-2: **bỏ `compareRubricVersion` hoàn toàn**).
3. **Vết tổng hợp** (FR-07): thêm vết vào `ScoreAggregationService` mà **không đổi kết quả số**: refactor `averageScoresByTaskType` và `computeWeighted` để cùng một lõi tính ra `TaskTypeAverageStep` (số câu có điểm, số câu bỏ trống, tổng, trung bình), `SkillTermStep` (task type, trọng số từ mẫu đề ghim, trung bình, `w × avg / 100`, cờ loại khỏi Σw),
   `SkillTrace` (Σ, Σw, tỉ lệ, `10 + 80 × tỉ lệ`, HALF_UP, cờ không đủ dữ liệu) và `OverallTrace` (cột `overallWeight`; null khi chưa đủ 4 kỹ năng). Thêm `aggregateWithTrace(...)`; các hàm `aggregate*` cùng gọi lõi đó (test bảo vệ). Tách helper nếu file > 300 dòng.
4. **Snapshot v2**: `SCHEMA_VERSION = 2`; `ReportSnapshot` thêm `rubricVersionPublicId` và vết tổng hợp; `ReportSnapshotScoreInput` thêm `traitScores`, `rubricVersionPublicId`, vết điểm câu. `decode` chấp nhận **1 và 2** (v1: trường mới null, `traceAvailable=false`); phiên bản khác vẫn `SNAPSHOT_VERSION_UNSUPPORTED`. `ReportPublishService` ghi v2 bằng `aggregateWithTrace`.
5. **API giải thích** (controller mới `ScoreExplanationController` trong `reporting/internal/controller`): `GET /api/v1/reports/attempts/{attemptPublicId}/score-explanation`, `@PreAuthorize("hasAnyRole('HOST_ADMIN','EXAMINER')")` — **không PLATFORM_ADMIN, không role vendor nào**. Kiểm tra truy cập (service `ScoreExplanationService`, ném lỗi chuẩn 403/404 không rò tồn tại):
   - `HOST_ADMIN`: lượt thi phải thuộc `tenantId` của người gọi (cùng cơ chế `ReportService`).
   - `EXAMINER`: cùng tenant **và** được phân công cho lượt thi đó (`ScoringService.isAttemptAssignedToExaminer(tenantId, sessionPublicId, attemptPublicId, examinerPublicId)`); giám khảo không được phân công nhận từ chối.
   Phản hồi `ScoreExplanationResponse`: mẫu đề và phiên bản rubric ghim; **`rubricParameters`: tham số của phiên bản ghim cho các task type có trong lượt thi (trọng số tiêu chí, Form band, cờ cổng, phiên bản bảng Azure + cờ `calibrated=false` kèm nhãn "chưa hiệu chỉnh với dữ liệu người chấm")**, chỉ khi phiên bản ở trạng thái ACTIVE hoặc RETIRED
   (không bao giờ DRAFT/PENDING/REJECTED: kiểm tra và test); danh sách câu (task type, nguồn điểm, điểm tiêu chí, `ScoreTrace`, điểm câu); trung bình task type (kèm số câu bỏ trống); trọng số kỹ năng theo mẫu đề; vết từng kỹ năng và Overall; `published`, `traceAvailable`, `schemaVersion`.
   Đã publish -> đọc snapshot (không tính lại); chưa publish -> `RubricRescoreService` + `aggregateWithTrace` với cùng đầu vào như màn hình Host. Không trả transcript, bài làm hay dữ liệu cá nhân học viên ngoài mã định danh cần thiết. p95 < 800 ms, không gọi AI.
6. **Bộ dựng fixture (LOW-2)**: lớp test `ExplanationFixtureBuilder` dựng được lượt thi (và snapshot) phủ **22 task type**, câu bỏ trống, câu nguồn EXAMINER (điểm tổng cũ và, sau Phase 10, điểm tiêu chí), giải mã snapshot v1 (fixture JSON), các độ dài Read Aloud (N = 1, 30, 80), câu cổng kích hoạt; dùng chung cho test aggregation, codec, giải thích, và Phase 10.
7. **Test**: aggregation giữ nguyên mọi ca cũ (kết quả số không đổi) + kiểm tra vết (blank, loại khỏi Σw, Σw = 0, Overall null); codec (v1 giải mã, v2 round-trip, phiên bản lạ bị từ chối); **tính lại == vết lưu trong snapshot với chênh lệch 0 trên toàn bộ fixture**; đổi phiên bản ACTIVE giả lập không đổi giải thích của báo cáo đã publish;
   tính lại 0 lời gọi vendor (`verifyNoInteractions`); **cách ly tenant** (Host tenant A không đọc lượt thi tenant B -> 403/404; Examiner tenant khác bị từ chối); **giám khảo không được phân công bị từ chối** và được phân công thì đọc được; `PLATFORM_ADMIN` và role vendor nhận 403; không bao giờ trả tham số của bản nháp; không có tham số `compareRubricVersion` (bị bỏ qua/không tồn tại);
   cập nhật `ApiInventoryExportTest`.
8. **Hợp đồng FE**: DTO record ổn định để Phase 7 sinh kiểu cho tenant-web.

## Acceptance criteria

- Mọi con số trên API giải thích khớp snapshot đã publish (chênh lệch 0) và khớp `ReportResponse` trên toàn bộ fixture (phủ 22 task type).
- Chỉ `HOST_ADMIN` (đúng tenant) và `EXAMINER` (đúng tenant và được phân công) gọi được; mọi role khác (kể cả `PLATFORM_ADMIN`, role vendor) nhận 403; test cách ly tenant và giám khảo không được phân công đều xanh.
- Không có tham số so sánh phiên bản; tính lại luôn dùng phiên bản ghim của câu; phản hồi chứa tham số phiên bản ghim (ACTIVE/RETIRED) và nhãn chưa hiệu chỉnh, không bao giờ chứa bản nháp.
- Đổi phiên bản ACTIVE không đổi báo cáo đã publish; tính lại 0 lời gọi vendor; snapshot v1 vẫn giải mã được, v2 chứa điểm tiêu chí, phiên bản rubric và vết.
- Kết quả số của tổng hợp 10-90 không đổi so với trước phase.
- p95 giải thích < 800 ms trên fixture, không gọi AI.

## Validation commands

```powershell
cd D:\GitHub\pte-org\pte-api
.\mvnw.cmd -pl app -DskipTests compile
.\mvnw.cmd -pl app test -Dtest="ScoreAggregationService*Test,ReportSnapshotCodec*Test,ReportPublishService*Test,RubricRescoreServiceTest,ScoreExplanation*Test"
.\mvnw.cmd -pl app test -Dtest="PackageDensityTest,SourceFileSizeTest,NoDirectClockAccessTest,ModuleStructureTest,ApiInventoryExportTest"
.\mvnw.cmd -pl app test      # toàn suite; báo cáo test đỏ không liên quan
```

## Design Constraints

- `docs/CODING_STANDARDS_API.md`, `API_RESPONSE_SETUP.md`, `COMMON_EXCEPTION_SETUP.md`, `TEST_SCENARIOS_IAM.md` bắt buộc; hợp đồng `ReportResponse` không đổi; endpoint mới chỉ thêm.
- Không đổi kết quả số tổng hợp; vết chỉ quan sát lõi, không tính song song công thức thứ hai.
- Ranh giới module: `reporting` dùng API công khai của `scoring` (`ScoringService`, DTO `com.pte.scoring.dto.response`); không đọc repository/entity của `scoring`.
- Dữ liệu lượt thi **chỉ** cho Host (tenant mình) và Examiner được phân công; vendor và `PLATFORM_ADMIN` không có đường đọc; không mở đọc xuyên tenant.
- Host/Examiner chỉ thấy tham số phiên bản ACTIVE/RETIRED đã ghim; không bao giờ bản nháp/chờ duyệt/từ chối.
- Snapshot đã publish bất biến; v1 chỉ đọc. `Clock` inject; file <= 300 dòng; `reporting/internal/service` có thể sát trần: tách gói con `explain`.
- API giải thích không chứa transcript, bài làm hay dữ liệu cá nhân học viên.
- Preflight (2026-11-05): đã đọc đủ `docs/CODING_STANDARDS_API.md`, `docs/API_RESPONSE_SETUP.md`, `docs/COMMON_EXCEPTION_SETUP.md`, `docs/TEST_SCENARIOS_IAM.md` (không đụng web nên không đọc `CODING_STANDARDS_WEB.md`). Quyết định khi làm:
  - Công khai qua facade mới `com.pte.scoring.RubricTraceService` (`traceItems`, `findReadableParameters`) thay vì thêm vào `ScoringService` (đã ~20 phương thức công khai; chuẩn <= 5). Nội bộ: `internal/rubric/service/RubricRescoreService` (vết câu, cache phiên bản/rubric mỗi lần gọi, chỉ dùng phiên bản ghim của câu) và `PinnedRubricParametersService` (chỉ ACTIVE/RETIRED). DTO công khai mới trong `scoring.dto.response`: `ItemTraceKind` (RUBRIC, LEGACY_NO_TRACE, EXAMINER_SCORE, OBJECTIVE, UNSCORED, NOT_SCORED, TRACE_UNAVAILABLE), `ItemScoreTraceView`, `RubricParametersView`, `TaskTypeParametersView`.
  - `ReportScoringAnswerView` thêm `traitScores`, `rubricVersionPublicId`, `wordCount` (constructor cũ giữ). `ReportTraitReader` đọc `criteria_scores_json` (chỉ `PEARSON_V1`) và `wordCount` từ `detail_json` (RA: N; bài viết: số từ bài làm). Khóa `wordCount` thành `ScoringConstants.DETAIL_WORD_COUNT`.
  - Lõi tổng hợp `reporting/internal/service/aggregation/AggregationCore` (+ `TaskTypeAverageStep`, `SkillTermStep`, `SkillTrace`, `AggregationTrace`); mọi hàm `aggregate*` đọc `AttemptScoreSummary` từ vết. Thêm `aggregateWithTrace` (cơ sở provisional, như màn Host) và `TracedAggregation`; `ReportScoreAggregation` thêm `trace`, `rubricVersionPublicId`.
  - Snapshot v2: `ReportSnapshot` + `rubricVersionPublicId`, `aggregationTrace`; `ReportSnapshotScoreInput` + `traitScores`, `rubricVersionPublicId`, `wordCount`, `traceKind`, `objectiveRuleCode`, `itemTrace` (`ScoreTrace`). `decode` nhận 1 và 2. `ReportPublishService` ghi v2 kèm vết câu từ `RubricTraceService`.
  - API `GET /api/v1/reports/attempts/{attemptPublicId}/score-explanation` (`ScoreExplanationController`, `hasAnyRole('HOST_ADMIN','EXAMINER')`); gói `reporting/internal/service/explain` (`ScoreExplanationAccess`, `ScoreExplanationService`, `ScoreExplanationMapper`). Mọi trường hợp không được xem (không tồn tại/chưa nộp, khác tenant, giám khảo không được phân công, role khác ở tầng service) đều trả cùng 404 `REPORT_NOT_FOUND` (theo `ReportService`, không rò tồn tại); role khác bị 403 ở `@PreAuthorize`. Đã publish -> đọc snapshot, không tính lại; chưa publish -> tính lại + `aggregateWithTrace`, chỉ đọc, không ghi `ExamResult`.
  - QUAL-003 đã xử lý: `RubricVersionService.createDraft` (dùng `saveAndFlush`) và `activate` ánh xạ `DataIntegrityViolationException` thành 409 `RUBRIC_VERSION_CONCURRENT_CHANGE`.
  - Không cần migration mới (snapshot là JSON; cột cần đã có từ V32).

## Quality and Testing State

- Quality: skipped_by_user
- Testing: passed (2026-11-05). `.\mvnw.cmd -pl app clean test-compile` sạch; nhắm đích 108 test xanh (`ScoreAggregationServiceTest` 23 cũ không đổi + `ScoreAggregationServiceTraceTest` 5, `ReportSnapshotCodecTest` 4, `ReportPublishServiceTest` 7, `ReportServiceTest` 11, `RubricRescoreServiceTest` 9, `PinnedRubricParametersServiceTest` 6, `ReportTraitReaderTest` 3, `ScoringReviewReadQueryServiceTest` 10, `ScoreExplanationAccessTest` 13, `ScoreExplanationServiceTest` 6, `ScoreExplanationControllerTest` 11); `RubricVersionServiceTest` 18 (thêm 2 ca QUAL-003); ratchet `PackageDensityTest`, `SourceFileSizeTest`, `NoDirectClockAccessTest`, `RubricScoreSingleSourceTest` (allowlist rỗng), `ModuleStructureTest`, `ApiInventoryExportTest` (thêm khẳng định endpoint mới và quyền; bản xuất có 279 endpoint) xanh. Toàn bộ `.\mvnw.cmd -pl app clean test`: **4468 test, 0 failures, 0 errors, 137 skipped**, BUILD SUCCESS (đọc từ 510 file surefire XML; nền trước phase 4410/137, +58 test, số bỏ qua không đổi). Fixture `ExplanationFixtureBuilder` phủ 22 task type, RA N = 1/30/80, cổng, nguồn EXAMINER, dòng cũ, câu bỏ trống, câu chưa chọn nguồn, snapshot v1 (`src/test/resources/reporting/report-snapshot-v1.json`). p95 < 800 ms chỉ đo trên fixture trong bộ nhớ với mock (không DB). **Chưa kiểm chứng:** Postgres IT (không Docker), spike AI (không key), đo hiệu năng trên DB thật; "0 lời gọi vendor" chứng minh bằng kiểm tra phụ thuộc constructor bắc cầu từ `RubricTraceService` và `verifyNoMoreInteractions` trên `ScoringService`, không phải bằng mock client vendor thật.

## Risks

- Refactor `ScoreAggregationService` đổi kết quả số: giữ test cũ, so sánh trước/sau trên cùng dữ liệu; đổi lõi trước, thêm vết sau.
- Lấy `sessionPublicId` cho kiểm tra phân công giám khảo cần gọi thêm `AttemptService`: cần xác minh API công khai; nếu thiếu, thêm phương thức đọc nhỏ ở `attempt`.
- Rò thông tin tồn tại lượt thi ở lỗi 403 so với 404: thống nhất trả cùng một mã cho "không có quyền" và "không tồn tại" theo `COMMON_EXCEPTION_SETUP.md`.
- Dòng điểm tiêu chí cũ (không `scale`) bị nhầm thang: phân biệt theo `scale`; hiển thị "dữ liệu cũ, không có vết".
- Câu nguồn EXAMINER chưa có điểm tiêu chí (trước Phase 10): hiển thị "điểm giám khảo, không phân rã".
