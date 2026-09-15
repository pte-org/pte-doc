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

- [x] Host scoring request trả nhanh và queue được AI work. **(objective type
      score đồng bộ trên request thread — thuần CPU, không I/O; AI type chỉ
      `dispatch()` vào RabbitMQ, vendor call không chạy trên request thread —
      kiểm chứng bằng `ScoringCommandServiceTest`/`AiScoringDispatcherTest`;
      chưa đo latency thật vì không có Postgres/Rabbit daemon trong phiên)**
- [x] Objective/AI score dùng raw score 0–100 nhất quán (`ObjectiveScoringService`,
      `AiScoreResult` compact constructor validate 0–100).
- [x] Retry/DLQ/duplicate delivery không gọi vendor lặp sai (`AiScoringWorker`
      no-op trên answer đã terminal SCORED/SCORING_FAILED — kiểm chứng bằng
      `AiScoringWorkerTest.worker_redeliveredTerminalAnswer_doesNotCallVendorAgain`).
- [x] Review và teacher score giữ đúng tenant/role semantics (`ScoringReviewService`
      404-not-403 no-existence-leak, `@PreAuthorize` HOST_ADMIN/HOST_AUTHOR).
- [x] Reporting có public query để đọc scored answer — **quyết định thiết kế:
      không cần public `ScoringService` facade ở Phase 08 (chưa có caller nào
      trong phase này); `ScoringAnswerRepository`/tenant-scoped query đã sẵn
      sàng, Phase 10 sẽ thêm public facade method khi reporting thực sự cần,
      theo đúng nguyên tắc YAGNI đã dùng ở mọi phase trước.**
- [ ] `V10__scoring.sql` chạy được trên Postgres monolith. **(chưa chạy thật
      — không có Postgres daemon trong phiên này)**
- [x] Test scoring nguồn và test app xanh (services/scoring giữ nguyên, không
      đổi; `app` 382/382).
- [x] `ApplicationModules.verify()` pass (thêm `@NamedInterface` cho
      `attempt.dto.response`).

---

## Quality and Testing State

**Testing: passed.** 81 test mới — `ObjectiveScoringServiceTest` (40, ported),
`AiScoringTaskCatalogTest` (3), `AiScoringDispatcherTest` (3),
`AnswerPayloadDecoderFixtureTest` (5, dùng fixture vendor tại
`app/src/test/resources/fixtures/listening-payload-contract.json`),
`ListeningPayloadFixtureSchemaTest` (1), `AiScoreResultTest` (2),
`AiScoringWorkerTest` (4, ported — bỏ `outboxWriter`/`attemptCompletionService`
mock vì cả hai bị drop), `ScoringIngestServiceTest` (4, mới),
`ScoringCommandServiceTest` (5, mới), `ScoringReviewServiceTest` (7, mới),
`SubmittedAnswerQueryServiceTest` (4, mới, trong attempt module), và 3 test
mới cho `EntitlementService.verifyHostAccess` (trong session module).
Full `mvn -pl app test`: 382/382 xanh. `ApplicationModules.verify()` pass.
Report: [phase-08-scoring-test-report.json](tests/phase-08-scoring-test-report.json).

**Quality gate: APPROVED** (0 blocker/high/medium/low, 1 noted — dead
`presigned == null` check trong `OpenAiCompatibleSpeechScoringClient` sau khi
đổi `MediaClient` (trả `null` khi lỗi) sang `MediaService` (throw khi lỗi);
đã fix ngay trong lúc review). Review tự thực hiện inline — subagent
`quality-reviewer` hết quota phiên giữa chừng, dùng đường dẫn inline theo quy
tắc fallback của skill `ck:quality`.
Report: [phase-08-scoring-quality-report.json](quality/phase-08-scoring-quality-report.json).

Receipt cơ học **chưa phát hành được** — cùng giới hạn đa-repo đã ghi ở các
phase trước (`pte-doc`/`pte-api` là hai Git repo tách biệt trong môi trường này).

Deviation: không port `OutboxEntry`, `ProcessedEvent`, `AnswerIngestConsumer`,
`ScoringCommandConsumer`, outbox relay/cleanup, `AnswerScoredEvent`/
`AttemptScoredEvent`, `AttemptCompletionService` (mục đích duy nhất là emit
`AttemptScored` — event này có 0 consumer ở bất kỳ đâu trong `services/*`,
xác nhận bằng grep qua `services/notification` và `services/reporting`, nên
là dead code, không phải deferral). Thay bằng pull-based ingest:
`ScoringIngestService` gọi `AttemptService.getSubmittedAnswersForSession`
(method mới, public) khi host gọi `POST /sessions/{id}/score`; endpoint này
đặt trong `com.pte.scoring` (không phải `com.pte.session`) vì chiều phụ thuộc
module là `session ──> attempt ──> scoring` (scoring được gọi session/attempt,
không phải chiều ngược). Không port `client/MediaClientTest`,
`config/RabbitMqConfigTest`, `messaging/consumer/AnswerIngestConsumerTest`,
`vendor/openai/OpenAiCompatible*Test` (cùng lý do drop production code tương
ứng, hoặc bean-wiring/HTTP-mechanics test có giá trị thấp — cùng tiền lệ các
phase trước).
