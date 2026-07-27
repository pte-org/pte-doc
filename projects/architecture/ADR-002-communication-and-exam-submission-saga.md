# ADR-002: Inter-Service Communication & Exam-Submission Saga

**Date:** 2026-07-24
**Status:** Accepted
**Depends on:** ADR-001

---

## Decision

**Async-first.** Sync REST chỉ cho query đọc trực tiếp qua gateway; mọi luồng nghiệp vụ xuyên service đi qua event backbone. Submit bài thi dùng **Transactional Outbox + choreography saga**, KHÔNG distributed transaction (2PC).

---

## Communication matrix

| Từ | Tới | Kiểu | Ghi chú |
|---|---|---|---|
| authoring | (publish) | event | `ExamSnapshotPublished` |
| exam-delivery | authoring | **sync pull 1 lần** | Chỉ lúc tạo attempt, pin snapshot. Sau đó không call nữa |
| exam-delivery | (publish) | event | `AnswerSubmitted`, `AttemptSubmitted` |
| scoring | (consume/publish) | event | consume `AnswerSubmitted` → publish `AnswerScored` |
| proctor | (publish) | event/command | `ProctorCommand` → exam-delivery consume |
| reporting | (consume) | event | build read model từ stream |
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
   → advance NGAY (không chờ gì). Debezium (CDC) đẩy outbox → Kafka.
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

## Kafka vs RabbitMQ — vai tách bạch

| | Kafka | RabbitMQ |
|---|---|---|
| Dùng | Event backbone: chuyện đã xảy ra, nhiều consumer, cần replay + ordering per attempt | Work queue: việc cần làm, 1 bên xử lý, xong thì thôi |
| Trong hệ này | saga submit→score→report, rebuild read-model | fan-out job AI trong scoring; bulk-import; transcode; email |
| Load-leveling | — | Điều tiết **WRITE spike** bằng consumer prefetch/concurrency |

Lẫn hai cái là nguồn nhầm phổ biến nhất khi vận hành cả hai broker.

---

## Cross-cutting bắt buộc

- **Idempotency:** mọi consumer dedup theo event ID (Kafka at-least-once → event bị giao lại).
- **Observability:** OpenTelemetry distributed tracing — correlation ID chạy suốt saga (submit→scored→report) theo `attemptId`. Không có = không debug được 9 service.
- **Schema versioning:** event schema versioned (Avro + Schema Registry / Protobuf), backward compatible bắt buộc.
- **ShedLock** nếu còn scheduled job nào ở nhiều instance (chống chạy trùng).

---

## Consequences

**Được:** submit không bị chặn bởi scoring chậm; mất event = 0 (outbox); thêm consumer mới replay được; scoring vendor chậm/chết không ảnh hưởng luồng thi.

**Trả giá:** eventual consistency (score xuất hiện sau submit vài giây–phút); phải xây idempotency + tracing + schema registry — chi phí cố định của distributed, không tùy chọn.
