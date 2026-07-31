# ADR-002: Inter-Service Communication & Exam-Submission Saga

**Date:** 2026-07-24
**Status:** Accepted — communication/event-backbone sections superseded-in-part 2026-07-31 (see note below)
**Depends on:** ADR-001

---

> ## ⚠️ Superseded-in-part (2026-07-31)
>
> The **event backbone** described in this ADR — Kafka + Debezium WAL-tail CDC + Schema Registry — was replaced with **RabbitMQ + an application-level polling outbox relay**. The team judged Kafka/Debezium/Schema-Registry operationally too costly for this project's scale (final-year student team, not high-throughput production traffic).
>
> - **Full migration record:** [`pte-doc/projects/plans/rabbitmq-outbox-migration/plan.md`](../plans/rabbitmq-outbox-migration/plan.md) — 11 phases, every implementation decision and deviation logged in its Session Notes.
> - **Original rationale for the switch:** [`personal-docs/rabbitmq_pollingoutbox.md`](../../../personal-docs/rabbitmq_pollingoutbox.md).
> - **What did NOT change:** the **Scoring lifecycle (host-gated)** and **saga state model** sections below are UNCHANGED in substance — this migration replaced *transport* (how an outbox row reaches a broker), not the saga's business semantics (host-gated scoring, submit-never-triggers-scoring, publish-is-a-gate). The one line inside that section referencing Debezium/Kafka is corrected below; everything else in it is verbatim.
> - Sections below are rewritten in place to describe the **as-built** architecture, not a hypothetical — this is not a new ADR because the *decisions* (async-first, outbox pattern, host-gated scoring, choreography not 2PC) are unchanged; only the *broker* changed.

---

## Decision

**Async-first.** Sync REST chỉ cho query đọc trực tiếp qua gateway (**+ reporting's rebuild-only sync pull, xem mục Rebuild bên dưới**); mọi luồng nghiệp vụ xuyên service đi qua event backbone. Submit bài thi dùng **Transactional Outbox + choreography saga**, KHÔNG distributed transaction (2PC).

---

## Communication matrix

| Từ | Tới | Kiểu | Ghi chú |
|---|---|---|---|
| authoring | (publish) | event | `ExamSnapshotPublished` |
| exam-delivery | authoring | **sync pull 1 lần** | Chỉ lúc tạo attempt, pin snapshot. Sau đó không call nữa |
| exam-delivery | (publish) | event | `AnswerSubmitted`, `AttemptSubmitted` |
| scoring | (consume/publish) | event | consume `AnswerSubmitted` → publish `AnswerScored` |
| proctor | (publish) | event/command | `ProctorCommand` → exam-delivery consume |
| reporting | (consume) | event | build read model từ stream (đường chính, steady-state) |
| reporting | exam-delivery, scoring | **sync pull, rebuild-only** | Không phải đường chính — chỉ khi cần dựng lại read model từ đầu (mất data, bootstrap instance mới). Xem mục Rebuild bên dưới |
| exam-delivery ↔ media | sync | presigned URL (upload/fetch) |

**Auth:** iam ký JWT asymmetric. Các service validate **local bằng JWKS public key**, không call iam mỗi request → iam sập, token còn hạn vẫn dùng được, attempt không gián đoạn.

---

## Scoring lifecycle — HOST-GATED, không tự động

Scoring **không** tự chạy khi student nộp. Trigger là **command của host**, và có **cổng publish do host quyết định**. Hai quyết định người-trong-vòng-lặp: (1) *khi nào* chấm, (2) *có* publish cho student không. Khớp việc Pearson thêm human-review-on-top-of-AI cho 7 task type — cổng publish là chỗ human moderation sống.

### State model
```
AttemptAnswer / Attempt:
  SUBMITTED ──(host kích hoạt chấm)──> SCORING ──> SCORED ──(host publish)──> PUBLISHED
                                                     │
                                         host review/điều chỉnh ở đây
```
- **SUBMITTED:** student nộp xong, lưu, KHÔNG chấm. Không auto-trigger.
- **SCORING → SCORED:** host bấm chấm → điểm tính & lưu nội bộ, **student CHƯA thấy**.
- **PUBLISHED:** host review (nhất là 7 task cần human-check) → publish → student mới thấy report.

### Luồng
```
1. Student submit answer / submit attempt
   └─ exam-delivery: 1 local TX
      ├─ INSERT AttemptAnswer (status=SUBMITTED)
      └─ INSERT outbox row (event=AnswerSubmitted / AttemptSubmitted)   ← CÙNG transaction
   → advance NGAY (không chờ gì). Polling outbox relay (`AbstractOutboxRelay`,
     `SELECT ... FOR UPDATE SKIP LOCKED`) đẩy outbox → RabbitMQ.
     Event dùng cho reporting/audit, KHÔNG auto-trigger scoring.

2. Host (sau, chủ động) phát command "chấm session/attempt X"
   → enqueue ScoringJob vào RabbitMQ (fan-out hàng loạt attempt cho worker)

3. scoring worker (idempotent theo answerId):
   ├─ objective task  → chấm rule-based
   ├─ speaking/writing → gọi AI vendor async
   │     └─ fail → retry (exp backoff) → DLQ
   → cập nhật status = SCORED. Kết quả nội bộ, student CHƯA thấy.

4. Host review kết quả SCORED → phát command "publish"
   → status = PUBLISHED → reporting expose report cho student
```

**Nguyên tắc:**
- Submit **không bao giờ** kéo theo chấm; scoring là **host-initiated command**, không phải choreography tự động trên `AttemptSubmitted`.
- **Cổng publish thuộc quyền host.** Student không thấy điểm cho tới khi host publish — không phải "chấm xong tự hiện".
- scoring service chỉ **thực thi khi được lệnh**, không tự quyết. Endpoint phát command chấm/publish là **host-facing** (scheduling/host-side), không nằm trong scoring.
- Outbox làm "ghi answer" và "phát event" **atomic** → loại dual-write bug.
- reporting chỉ expose attempt ở trạng thái `PUBLISHED`; `SCORED`-nhưng-chưa-publish chỉ host thấy.

---

## Outbox-relay vs Work-queue — vai tách bạch (cùng chạy trên RabbitMQ)

Nguyên tắc cũ ("event backbone" khác "work queue") **vẫn đúng**, chỉ khác là giờ cả hai chạy trên **cùng một broker công nghệ** (RabbitMQ) thay vì hai broker riêng (Kafka + RabbitMQ). Đây KHÔNG phải gộp hai vai làm một — exchange/queue của outbox-relay và của work-queue **không bao giờ dùng chung** (Phase 6 của migration ghi rõ nguyên tắc này khi scoring có cả hai loại trong cùng service: AI-vendor work-queue và outbox-relay dùng 2 `RabbitMqConfig` tách biệt, 2 bộ bean tên khác nhau).

| | Outbox-relay (event backbone) | Work-queue |
|---|---|---|
| Dùng | Chuyện đã xảy ra, nhiều consumer, atomic với DB write qua outbox table | Việc cần làm, 1 bên xử lý, xong thì thôi |
| Trong hệ này | saga submit→score→report (mỗi service poll outbox riêng, `AbstractOutboxRelay` trong `pte-common`) | fan-out job AI trong scoring; bulk-import; transcode; email |
| Cơ chế đẩy | `SELECT ... FOR UPDATE SKIP LOCKED` (poll định kỳ) + publisher confirm — KHÔNG còn Debezium CDC | `RabbitTemplate.convertAndSend` trực tiếp trong code nghiệp vụ |
| Ordering | Per-attempt ordering **không còn tự động** như Kafka partition — nơi cần (exam-delivery→scoring answer ingestion, proctor→exam-delivery command) dùng single-queue + consumer concurrency=1, và ràng buộc triển khai: **relay phía producer phải chạy đúng 1 instance** | Không cần ordering |
| Replay | **Không còn** replay-from-beginning kiểu Kafka. reporting bù bằng rebuild sync-pull (xem mục dưới), không phải RabbitMQ tính năng | — |
| Load-leveling | Điều tiết qua `pte.outbox.batch-size`/`poll-interval-ms` | Điều tiết **WRITE spike** bằng consumer prefetch/concurrency |

Lẫn hai vai (dùng chung exchange/queue cho cả hai mục đích) vẫn là nguồn nhầm phổ biến nhất — kể cả khi chỉ còn một broker công nghệ, ranh giới vai trò vẫn phải giữ.

---

## Reporting read-model rebuild — sync-pull thay Kafka replay

Kafka giữ log dài hạn nên về lý thuyết cho phép replay để dựng lại read-model; RabbitMQ (queue thường) không giữ message sau khi consumer đã ack. Nhưng khi rà lại (migration Phase 9): **khả năng "replay" đó chưa từng được reporting thật sự dùng** — chỉ có 1 consumer group duy nhất, steady-state, không có endpoint/trigger rebuild nào tồn tại trong code. Nói cách khác, đây không phải mất một tính năng đang chạy, mà là **lần đầu tiên reporting có khả năng rebuild**, xây mới hoàn toàn vì cần thiết sau khi bỏ Kafka.

**Cơ chế:** 2 service reporting thực sự lấy dữ liệu (`exam-delivery`, `scoring` — đối chiếu thực tế `AttemptReport`/`AnswerProjection` chỉ cần 2 nguồn này, KHÔNG phải cả 6 service ban đầu dự tính) mỗi cái expose 1 endpoint `/internal/**` export, phân trang bằng keyset cursor `(updatedAt, publicId)`, gate bằng `InternalApiKeyFilter` sẵn có. reporting page qua từng endpoint, áp lại đúng logic upsert mà consumer steady-state dùng (`AttemptProjectionService`/`AnswerScoreService`, share code, không viết lại).

**Hai định danh gọi riêng biệt** (không được lẫn):
- **Operator, 1 tenant:** host gọi `POST /reports/rebuild` (JWT thường), reporting tự lấy `tenantId` từ JWT đó, không nhận tenantId qua tham số.
- **Bootstrap, toàn bộ tenant:** instance reporting mới, DB rỗng, không có JWT nào dẫn dắt — gọi `POST /internal/rebuild/bootstrap`, cần **2 key cùng lúc** (`X-Internal-Service-Key` + `X-Internal-Bootstrap-Key`, `InternalBootstrapKeyFilter` trong `pte-common`) — key bootstrap một mình không đủ.

**Giới hạn đã biết, ghi rõ không giấu:** `AttemptReport.published`/`publishedAt` **không rebuild được** — đây là quyết định nội bộ của reporting khi xử lý `PublishRequested`, không phải projection từ dữ liệu bên ngoài, và scheduling không lưu trạng thái "đã publish" ở đâu khác để export lại. Sau rebuild, mọi attempt về `published=false`; host phải tự publish lại nếu cần học viên thấy report.

Chi tiết implementation: [`pte-doc/projects/plans/rabbitmq-outbox-migration/phase-09-reporting-rebuild-sync-pull.md`](../plans/rabbitmq-outbox-migration/phase-09-reporting-rebuild-sync-pull.md).

---

## Cross-cutting bắt buộc

- **Idempotency:** mọi consumer dedup theo event ID (RabbitMQ tối thiểu at-least-once → event có thể bị giao lại). `eventId` giờ truyền qua AMQP `messageId` (message property), không còn Kafka record header.
- **Observability:** OpenTelemetry distributed tracing — correlation ID chạy suốt saga (submit→scored→report) theo `attemptId`. Không có = không debug được 9 service. (Không đổi.)
- **Schema versioning:** payload vẫn là **plain JSON** qua Jackson `ObjectMapper` — Avro + Schema Registry chưa từng thực sự triển khai dưới Kafka (đã deferred từ Milestone 1), migration này chỉ chính thức bỏ luôn kế hoạch đó thay vì để treo. Backward-compatible payload vẫn bắt buộc theo quy ước thường (thêm field mới nullable, không đổi/xoá field cũ).
- **SKIP LOCKED, không phải ShedLock, cho outbox relay cụ thể:** `SELECT ... FOR UPDATE SKIP LOCKED` tự cho phép nhiều instance của cùng service poll đồng thời an toàn — dùng ShedLock ở đây sẽ **sai**, vì ShedLock serialize cả job về 1 instance, triệt tiêu khả năng scale ngang của relay. Đây là quyết định **riêng cho outbox relay** — các scheduled job khác trong hệ (nếu có, cần "chỉ 1 instance chạy") vẫn dùng ShedLock bình thường, không suy rộng thành "cấm ShedLock toàn hệ".

---

## Consequences

**Được:** submit không bị chặn bởi scoring chậm; mất event = 0 (outbox); scoring vendor chậm/chết không ảnh hưởng luồng thi; **vận hành đơn giản hơn hẳn** — 1 broker công nghệ (RabbitMQ) thay vì 2 (Kafka+RabbitMQ), không cần Debezium/Schema-Registry/Kafka Connect — đúng động lực ban đầu của việc đổi (nhóm sinh viên, không phải hệ throughput cao, chi phí vận hành phân tán phải tương xứng quy mô).

**Trả giá:**
- eventual consistency (score xuất hiện sau submit vài giây–phút) — không đổi.
- phải xây idempotency + tracing — chi phí cố định của distributed, không tùy chọn (không đổi).
- **mất khả năng replay-from-beginning kiểu Kafka** — bù bằng rebuild sync-pull cho reporting (mục trên), nhưng đây là cơ chế mới xây riêng, không "miễn phí" như Kafka retention.
- **thêm consumer mới không tự động replay lại lịch sử** — nếu sau này có service mới cần dựng read-model từ đầu, phải tự xây sync-pull endpoint như reporting đã làm, không có sẵn cơ chế chung.
- **per-aggregate ordering không còn tự động** — nơi cần (2 trường hợp: proctor→exam-delivery, exam-delivery→scoring) phải tự ràng buộc single-queue + concurrency=1 + relay phía producer chạy đúng 1 instance; đây là ràng buộc triển khai phải nhớ, không phải Kafka partition lo hộ.
