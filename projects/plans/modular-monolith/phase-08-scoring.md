# Phase 08 — Scoring

**Plan:** [plan.md](plan.md) · [kế hoạch tổng hợp](remaining-modules-refactor-plan.md) · **Spec:** [spec.md](spec.md)
**Covers:** Objective scoring, AI scoring queue, host review
**Nguồn:** `services/scoring` (60 file)
**Đích:** `com.pte.scoring`

---

## Mục tiêu

Giữ scoring là module sở hữu `ScoringAnswer` và work state, nhưng bỏ event backbone
dùng để đồng bộ giữa các service. Host request trả nhanh, phần AI/vendor chạy qua
Rabbit work queue:

```text
host scoring request → objective score / AI queue → worker → scored or failed
```

---

## Design Constraints

- `scoring` được gọi public API của `attempt`/nhận application event để ingest
  answer; không chạm repository nội bộ.
- `ScoringAnswer` là dữ liệu nghiệp vụ/work state của scoring, không phải
  `AnswerProjection` dùng chung cho reporting.
- Host-gated scoring giữ nguyên: submit attempt không tự gọi vendor/scoring toàn bộ.
- Objective task xử lý theo catalog hiện có; AI task chạy Rabbit queue, có retry,
  backoff và DLQ.
- Rabbit chỉ dùng cho work scoring thật; không dùng để đồng bộ read-model giữa module.
- Job redelivery phải no-op bằng status terminal/unique business key, không tạo
  `ProcessedEvent`.
- Raw score objective và AI dùng cùng thang 0–100; completion chỉ khi mọi answer
  terminal theo semantics source.
- Teacher score độc lập với AI score; không biến review thành approval gate.
- Media review gọi public `MediaService`, truyền tenant và fail-open khi presign
  lỗi như source.

---

## Việc cần làm

1. **Port domain và scoring logic**
   - Port `ScoringAnswer`, status, answer decoder, DTO, mapper, exception.
   - Port `ObjectiveScoringService` và toàn bộ parser cho MC, reorder, fill blanks,
     highlight, dictation.
   - Giữ malformed payload/reference fail-closed và scale 0–100.

2. **Port host review**
   - Port list/detail answer, decode payload, presigned audio và teacher score.
   - Giữ tenant-scoped 404/no-existence-leak và role guard.
   - Tạo public query để Phase 10 đọc scored answers canonical.

3. **Thiết kế ingest không projection**
   - Nhận application event `AnswerSubmitted` hoặc public handoff bất biến từ
     attempt để tạo work state của scoring.
   - Giữ answer payload, correct answer/options cần cho scoring trong aggregate
     scoring; không tạo bảng/mô hình báo cáo trung gian.
   - Unique theo answer public ID để xử lý duplicate handoff.

4. **Port async worker**
   - Giữ Rabbit config cho scoring command/AI queue, retry/backoff/DLQ.
   - `ScoringRequested` tìm pending answer theo session/tenant.
   - Objective score trong worker path; AI dispatch sang queue; worker gọi
     `EssayScoringClient`/`SpeechScoringClient`.
   - Terminal `SCORED`/`SCORING_FAILED` không gọi vendor lần hai.

5. **Bỏ hạ tầng service-boundary**
   - Không port `AnswerIngestConsumer`, `ScoringCommandConsumer`,
     `ProcessedEvent`, outbox relay, export controller.
   - Có thể giữ class worker có `@RabbitListener` vì đây là scoring work queue,
     nhưng listener không phụ thuộc idempotency table.

6. **Flyway**
   - Viết `V10__scoring.sql` cho bảng scoring canonical.
   - Không tạo `answer_projections`, outbox hoặc processed-events table.

---

## Tests to Write First

- Từng nhóm objective task, malformed payload và unsupported task type.
- Host scoring request trả `202` nhanh; vendor không chạy trên request thread.
- Mixed objective + AI, retry, DLQ và duplicate job delivery.
- Completion khi tất cả answer terminal; failed không bị treo.
- Tenant review list/detail, teacher score và media presign fail-open.
- Scoring public query trả dữ liệu canonical cho reporting.
- Modulith không cho scoring chạm repository nội bộ của attempt/media.

---

## Acceptance

- [ ] Host scoring request trả nhanh và queue được AI work.
- [ ] Objective/AI score dùng raw score 0–100 nhất quán.
- [ ] Retry/DLQ/duplicate delivery không gọi vendor lặp sai.
- [ ] Review và teacher score giữ đúng tenant/role semantics.
- [ ] Reporting có public scored-answer query, không cần projection.
- [ ] `V10__scoring.sql` chạy được trên Postgres monolith.
- [ ] Test scoring nguồn và test app xanh.
- [ ] `ApplicationModules.verify()` pass.

---

## Quality and Testing State

Chưa thực thi. Cần ghi riêng kết quả queue/vendor thực tế và giới hạn môi trường
nếu chưa có Rabbit/AI provider khi quality gate chạy.
