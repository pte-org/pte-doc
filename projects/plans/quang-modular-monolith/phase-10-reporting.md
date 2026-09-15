# Phase 10 — Reporting

**Plan:** [plan.md](plan.md) · [kế hoạch tổng hợp](remaining-modules-refactor-plan.md) · **Spec:** [spec.md](spec.md)
**Covers:** Attempt report, score aggregation, publish visibility
**Nguồn:** `services/reporting` (43 file)
**Đích:** `com.pte.reporting`

---

## Mục tiêu

Đưa reporting vào monolith và thay toàn bộ `AnswerProjection` bằng truy vấn dữ
liệu canonical từ `attempt` và `scoring`. Báo cáo không còn phụ thuộc vào việc
consumer có chạy kịp hay rebuild projection có thành công hay không.

---

## Design Constraints

- Dependency: `reporting → attempt`, `reporting → scoring`, qua public API.
- `AttemptReport` là record nghiệp vụ của reporting, không phải bản sao toàn bộ
  attempt; chỉ lưu lifecycle/visibility cần cho report.
- Scoring aggregate/query phải đọc `ScoringAnswer` canonical; reporting không mở
  `ScoringAnswerRepository`.
- Giữ task → skill mapping, raw score 0–100, scale 10–90, insufficient-data và
  overall communicative score.
- Student chỉ xem report đã publish và own attempt; host chỉ xem tenant của mình;
  platform bypass đúng rule source.
- Denial trả 404/no-existence-leak như source.
- Attempt submitted có thể phát application event để tạo `AttemptReport`; event
  không dựng answer projection.
- Host publish gọi reporting public service trực tiếp; report-published event dùng
  cho notification.
- Không port `AnswerProjection`, `AttemptProjectionService`,
  `AnswerScoreService`, mọi projection consumer, rebuild/export controller,
  outbox hoặc `ProcessedEvent`.

---

## Việc cần làm

1. **Port report aggregate**
   - Port `AttemptReport`, skill enum, response, mapper, exception và report
     controller/service.
   - Giữ tenant, student, session, attempt, published/publishedAt và timestamps.
   - Tạo report record idempotently khi attempt submitted.

2. **Port score aggregation**
   - Port `TaskSkillMappingConfig`, `ScoreAggregationService`,
     `AttemptScoreSummary`, `SkillScore`.
   - Thay repository projection bằng public scoring query/aggregate.
   - Nếu cần attempt metadata, gọi public attempt query; không truy cập bảng chéo.

3. **Port publish flow**
   - Port host publish command và student/host visibility.
   - Sau publish phát application event cho notification; không ghi outbox.
   - Giữ authorization và 404 behavior.

4. **Xóa read-model cũ khỏi bản port**
   - Không chuyển `RebuildOrchestrationService`,
     `InternalRebuildController`, export clients hoặc projection consumers.
   - Không tạo migration cho `answer_projections`.
   - Rà source import để reporting chỉ dùng public APIs.

5. **Flyway**
   - Viết `V13__reporting.sql` chỉ cho bảng canonical `AttemptReport` và index
     cần thiết.
   - Validate từ database monolith trống sau V1–V12.

---

## Tests to Write First

- Attempt submitted tạo report record đúng một lần.
- Student chưa publish/khác attempt bị 404; host cross-tenant bị 404.
- Publish chuyển visibility đúng và phát application event.
- Objective + AI score aggregate đúng; raw score mixed cùng thang 0–100.
- Skill không có dữ liệu trả insufficient-data, overall không fabricate.
- Reporting đọc scored answers canonical sau khi scoring update, không cần projection.
- Scan không có `AnswerProjection`, rebuild/export, outbox/processed event.
- Modulith chặn reporting truy cập repository nội bộ module khác.

---

## Acceptance

- [x] Report chạy từ dữ liệu attempt/scoring canonical (`ScoreAggregationService`
      gọi `ScoringService.getScoredAnswersForAttempt` mỗi lần, không cache local).
- [x] Không còn bảng/code `AnswerProjection` trong app (grep xác nhận, `V13`
      chỉ tạo `attempt_reports`).
- [x] Student/host/platform visibility và tenant isolation giữ nguyên
      (`ReportService.canView`; kiểm chứng kỹ nhất bởi quality gate —
      `AttemptSummaryQueryService.findSubmitted` cố tình không lọc tenant,
      `canView` là nơi check tenant thật sau đó, giống pattern
      `EntitlementService.checkEntitlement` của session).
- [x] Score aggregation giữ đúng mapping và scale 10–90 (công thức
      `round(10 + percentCorrect * 80)` port nguyên trạng, chỉ đổi nguồn dữ
      liệu).
- [x] Report publish tạo notification application event
      (`ReportPublishService` publish `AttemptPublishedEvent` sau `@Transactional`
      commit, notification's `AttemptPublishedNotificationListener` — có sẵn
      từ Phase 09, giờ mới có publisher thật — nhận qua
      `@TransactionalEventListener`).
- [x] `V13__reporting.sql` không tạo projection table.
- [x] Test reporting nguồn và test app xanh (services/reporting giữ nguyên,
      không đổi; `app` 479/479).
- [x] `ApplicationModules.verify()` pass (thêm `@NamedInterface` cho
      `reporting.dto.event`, `attempt.dto.response` mở rộng, `scoring.dto.response`
      mới — facade `ScoringService` đầu tiên, hoãn từ Phase 08 tới đúng lúc
      có caller).

---

## Quality and Testing State

**Testing: passed.** 51 test mới — `ReportServiceTest` (10), `ReportPublishServiceTest`
(6), `ScoreAggregationServiceTest` (13, xác minh công thức 10–90 với số cụ
thể), `ReportMapperTest` (6), `AttemptSummaryQueryServiceTest` (6, module
attempt), `ScoredAnswerQueryServiceTest` (7, module scoring), `ScoringServiceTest`
(3, module scoring). Cộng 1 test hiện có sửa tay
(`AttemptPublishedNotificationListenerTest`, theo field mới của event sau khi
dời sang `reporting.dto.event`). Không port trực tiếp test nguồn — test của
`services/reporting` nhắm vào data-access pattern `AnswerProjection` đã không
còn tồn tại, chỉ dùng làm tham chiếu hành vi.
Full `mvn -pl app test`: 479/479 xanh. `ApplicationModules.verify()` pass.
Report: [phase-10-reporting-test-report.json](tests/phase-10-reporting-test-report.json).

**Quality gate: APPROVED** (0 blocker/high/medium/low/noted, review độc lập —
tenant isolation trên đường lazy-create là hạng mục soi kỹ nhất, xác nhận an
toàn).
Report: [phase-10-reporting-quality-report.json](quality/phase-10-reporting-quality-report.json).

Receipt cơ học **chưa phát hành được** — cùng giới hạn đa-repo đã ghi ở các
phase trước (`pte-doc`/`pte-api` là hai Git repo tách biệt trong môi trường này).

Deviation: `AttemptReport` được tạo **lazy** (khi host/student xem report lần
đầu, hoặc khi host publish) thay vì eager tại thời điểm attempt submit qua
application event — plan gợi ý "có thể" dùng event, không bắt buộc; chọn pull
để nhất quán với pattern đã dùng ở Phase 08 (scoring pull từ attempt) thay vì
thêm một cơ chế event khác chỉ cho một record. Không port `AnswerProjection`,
`AttemptProjectionService`, `AnswerScoreService`, `AttemptIngestConsumer`,
`AnswerScoredConsumer`, `PublishConsumer`, `RebuildOrchestrationService`,
`RebuildController`, `InternalRebuildController`,
`ExamDeliveryExportClient`/`ScoringExportClient`, outbox/`ProcessedEvent`
(tất cả thuộc nhóm forbidden artifact hoặc read-model cũ, đúng mục tiêu chính
của phase này). `AttemptPublishedEvent` dời từ `com.pte.notification.dto.event`
(placeholder Phase 09, lúc đó reporting chưa tồn tại) sang
`com.pte.reporting.dto.event` (module publish sở hữu type, đúng pattern
`StudentEnrolledEvent`/`ViolationDetectedEvent`). Thêm
`AttemptService.getSubmittedAttempt`/`getSubmittedAttemptsForSession` và
`ScoringService` (public facade đầu tiên của scoring, hoãn đúng lúc từ Phase 08).
