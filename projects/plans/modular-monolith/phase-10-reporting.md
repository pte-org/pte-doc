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

- [ ] Report chạy từ dữ liệu attempt/scoring canonical.
- [ ] Không còn bảng/code `AnswerProjection` trong app.
- [ ] Student/host/platform visibility và tenant isolation giữ nguyên.
- [ ] Score aggregation giữ đúng mapping và scale 10–90.
- [ ] Report publish tạo notification application event.
- [ ] `V13__reporting.sql` không tạo projection table.
- [ ] Test reporting nguồn và test app xanh.
- [ ] `ApplicationModules.verify()` pass.

---

## Quality and Testing State

Chưa thực thi. Đây là phase chặn trước cutover vì phải chứng minh read-model
projection đã được loại bỏ hoàn toàn.
