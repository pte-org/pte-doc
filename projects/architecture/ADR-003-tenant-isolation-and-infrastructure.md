# ADR-003: Tenant Isolation & Infrastructure Stack

**Date:** 2026-07-24
**Status:** Accepted
**Depends on:** ADR-001, ADR-002
**Context:** Nhiều host chung 1 authoring-service instance. Hệ đòi hỏi bảo mật + performance cao.

---

## Tenant isolation — 3 lớp độc lập (đừng trộn)

Nhiều host chung 1 service KHÔNG phải vấn đề nếu xử lý đúng 3 lớp. "Cùng service" ≠ "cùng số phận".

### Lớp 1 — Data isolation (rò dữ liệu chéo tenant — nghiêm trọng nhất)
- Model: **shared DB, shared schema**, `tenant_id` mỗi bảng (mặc định cho authoring). DB-per-tenant chỉ cho host enterprise yêu cầu cách ly vật lý.
- **Ép ở tầng DB, không tin tầng app:** Postgres **Row-Level Security** — set `app.current_tenant` mỗi connection từ JWT claim, policy `USING (tenant_id = current_setting('app.current_tenant'))`. Quên WHERE → DB vẫn chặn.
- Global content (admin tạo, `tenant_id=NULL`): host **đọc**, chỉ `PLATFORM_AUTHOR` **ghi**.

### Lớp 2 — Resource isolation (noisy neighbor: host A làm chậm host B)
- **Per-tenant rate-limit/quota** ở gateway (token bucket theo `tenant_id`).
- **Bulk-import async:** không chạy inline trên request thread → đẩy RabbitMQ, worker pool concurrency cap per-tenant.
- Connection pool đủ lớn + **statement timeout**.
- KHÔNG giải bằng tách service theo tenant (vô nghĩa với hàng trăm host).

### Lớp 3 — Fault/blast-radius (host A crash service → host B mất dịch vụ)
- Nhiều **replica stateless** sau load balancer.
- Input validation cứng + payload size cap (chặn poison request).
- Circuit breaker giữa authoring và dependency.

**Lưu ý:** multi-tenant chung service OK cho **data plane (authoring)** vì downtime chịu được. **exam-delivery vẫn tách** — blast radius ở đó là student đang thi, không chấp nhận được.

---

## Infrastructure stack

### Backbone (bắt buộc)
- **RabbitMQ** — event backbone (outbox-relay, `AbstractOutboxRelay` polling `SELECT ... FOR UPDATE SKIP LOCKED`, ADR-002 — **Kafka/Redpanda + Debezium bị bỏ, xem ADR-002's "Superseded-in-part" note**) **+** work queue (fan-out AI job, bulk-import, transcode, email) + load-leveling WRITE — cả hai vai chạy trên cùng broker, exchange/queue tách biệt (ADR-002).
- **Redis** — xem vai bên dưới.

### Redis — nhiều vai, phân biệt rõ (KHÔNG bao giờ source-of-truth bài thi)
| Vai | Dùng cho |
|---|---|
| Cache | Đề (immutable snapshot), JWKS, tenant status |
| Rate-limit per-tenant | Token bucket (Lớp 2) |
| Idempotency dedup | Key `answerId` đã xử lý → skip |
| Single-flight lock | Chống cache stampede khi miss key nóng |
| Timer hot-cache | Đọc nhanh timer state (SoT vẫn ở Postgres, snapshot xuống DB định kỳ) |

### Bảo mật
- **Vault** — DB credential (dynamic short-lived), JWT signing key, AI vendor key + rotation. Bỏ secret khỏi `application.properties`.
- **Keycloak** — OIDC/OAuth2, MFA cho admin/host, JWKS. iam giữ service mỏng map role nội bộ.
- **Linkerd** (service mesh) — mTLS tự động giữa service.
- **Kong/APISIX** (gateway) — authN biên, per-tenant rate-limit, WAF plugin.
- **Field-level encryption** — nội dung đề chưa publish + PII student, key từ Vault.
- **Signed/short-TTL presigned URL** cho media. Watermark động theo `attemptId`. exam-delivery có DB credential **read-only** trên snapshot đã pin.
- **Tamper-evident audit** (proctor) — hash-chain / append-only WORM.

### Performance
- **Cloudflare CDN** — media tĩnh (audio đề, ảnh) + DDoS protection.
- **MinIO / S3** — object storage (service `media`), không nhét blob vào Postgres.
- **PgBouncer** — connection pooler, cap READ đồng thời chạm Postgres.
- **Read replica** — reporting đọc từ replica, không đè write path.
- **OpenSearch** — full-text search question bank. **HOÃN** đến khi có nhu cầu thật.

### Observability (bắt buộc với distributed)
- **Prometheus + Grafana** — metrics per-service, alert (submit latency, scoring queue depth).
- **OpenTelemetry + Jaeger/Tempo** — distributed tracing xuyên saga.
- **Loki / ELK** — log tập trung, correlate theo `attemptId`.

---

## Phòng thủ DB đúng bài — nhiều lớp, mỗi lớp một van

> **Đây là phase hạ tầng LÀM TRƯỚC.** Phần stack bảo mật (Vault/Keycloak/Linkerd) + performance nâng cao (CDN/OpenSearch) ở trên **defer** — chưa cần vội.

```
1. Gateway rate-limit per-tenant     → từ chối/làm chậm sớm
2. Redis cache (đề immutable, warm)  → hấp thụ phần lớn READ
3. Single-flight lock                → chống stampede khi miss key nóng
4. PgBouncer bounded pool            → cap READ đồng thời (van của READ, sync)
5. Read replica                      → tách read nặng khỏi primary
6. RabbitMQ load-leveling            → điều tiết WRITE spike (van của WRITE, async)
```

**Thứ tự triển khai (không dàn hàng ngang — khác độ ưu tiên):**
- **#2 + #3 (Redis warm cache + single-flight)** — làm trước nhất. ĐÂY là trải nghiệm student nạp đề. Đi cùng nhau. Đề immutable → TTL vô hạn, không invalidation, không stampede-do-write.
- **#4 (PgBouncer)** — làm sớm, rẻ nhất, chỉ là config trước Postgres.
- **#1 (gateway rate-limit)** — sau khi có gateway; dùng chính Redis làm counter.
- **#6 (RabbitMQ)** — khi có write nặng thật (bulk-import). Đừng dựng broker trống.
- **#5 (read replica)** — cuối, khi đo được read đè write primary.

**Lưu ý scoring (tránh nhầm):** 6 van này thuộc **read path + write-spike leveling**, KHÔNG dính scoring. Nộp bài ≠ chấm ngay — điểm chỉ ráp ở report cuối sau `AttemptSubmitted` (xem ADR-002). Van #6 điều tiết *ghi bài nộp / bulk-import*, không phải "chấm khi nộp".

**Chốt:** READ điều tiết bằng **PgBouncer pool size** (sync); WRITE điều tiết bằng **RabbitMQ consumer concurrency** (async). Hai van khác tầng. RabbitMQ KHÔNG dùng để gate read đồng bộ (student chờ response → queue chỉ thêm latency).

**Cache warming đề:** chủ động — background job trigger theo cửa sổ session (từ `scheduling`) đẩy ExamSnapshot vào Redis TRƯỚC khi student vào → guaranteed cache hit. Snapshot immutable → TTL vô hạn, không invalidation, không stampede do write.

---

## Consequences

~15 thành phần hạ tầng. Triển khai **theo lớp**, không cùng lúc:
- **Nền không thể thiếu:** RabbitMQ + Redis + Vault + Keycloak + Linkerd mTLS + CDN + PgBouncer. (Kafka + Debezium bị bỏ — xem ADR-002's "Superseded-in-part" note, 2026-07-31.)
- **Thêm khi có bằng chứng cần:** OpenSearch, read-replica, RabbitMQ priority routing, WAF nâng cao.

"Đến chốn" = mỗi thứ có một lý do không thể thay thế, KHÔNG phải dùng nhiều nhất. Mỗi component thêm = một thứ phải deploy, secure, monitor, patch.
