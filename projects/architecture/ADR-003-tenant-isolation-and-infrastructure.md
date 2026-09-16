# ADR-003: Tenant Isolation & Infrastructure Stack

**Date:** 2026-07-24 · **Viết lại 2026-09-16** theo hạ tầng thực tế
**Status:** Accepted
**Depends on:** [ADR-001](ADR-001-module-boundaries.md), [ADR-002](ADR-002-communication-and-scoring-lifecycle.md)
**Context:** Nhiều trung tâm dùng chung một ứng dụng, một database. Bản gốc kê một stack tham vọng (Vault, Keycloak, Linkerd, Kong, PgBouncer, Cloudflare, Prometheus, OpenSearch) — **phần lớn chưa bao giờ được triển khai**. File này ghi cái đang chạy thật và nói rõ cái gì còn thiếu.

---

## Tenant isolation — 3 lớp độc lập (đừng trộn)

Nhiều tenant chung một ứng dụng **không** phải vấn đề nếu xử lý đúng ba lớp. "Cùng ứng dụng" ≠ "cùng số phận".

### Lớp 1 — Cô lập dữ liệu (rò dữ liệu chéo tenant — nghiêm trọng nhất)

- Mô hình: **shared DB, shared schema**, cột `tenant_id` trên mọi bảng thuộc tenant.
- **Hiện trạng: ép ở tầng application.** `tenantId` lấy từ JWT claim, đưa vào điều kiện ở repository/service. Quên một `WHERE` là rò dữ liệu, và không có lớp nào đỡ.
- **Postgres Row-Level Security vẫn là mục tiêu, vẫn chưa có.** Không có `CREATE POLICY` nào trong repo. Đây là **lỗ hổng lớn nhất còn lại** của kiến trúc.
- Nội dung global (admin tạo, `tenant_id = NULL`): host **đọc**, chỉ `PLATFORM_AUTHOR` **ghi**.

> RLS bây giờ khả thi hơn lúc viết ADR gốc: Flyway đang chạy nên viết được `CREATE POLICY` trong migration. Và nó **cấp bách hơn** — [ADR-006](ADR-006-commercialization-and-exam-templates.md)/[ADR-007](ADR-007-student-identity-and-login.md) thêm `subscription_id`, `license_key`, `tenant.code`; càng nhiều cột tenant-scoped thì càng nhiều chỗ quên `WHERE`.

### Lớp 2 — Cô lập tài nguyên (hàng xóm ồn ào)

- **Rate limit per-tenant** — `shared/web/RateLimitFilter` + `RateLimitConfig`, token bucket đếm trên Redis. **Có thật, đang chạy.**
- **Bulk import chạy đồng bộ trên request thread** — chưa đẩy ra queue. Đây là lỗ hổng lớp 2 đã biết: một trung tâm import 5.000 dòng ăn thẳng vào connection pool dùng chung với bài thi.
- **Chưa có statement timeout** trên Postgres. Một query chạy loạn không có gì cắt.

> Sau khi thu gọn về monolith, lớp 2 **yếu hơn hẳn** so với kiến trúc cũ — trước đây `exam-delivery` có pool và cell DB riêng, nay dùng chung tất cả. Xem [ADR-008](ADR-008-modulith-reconciliation.md).

### Lớp 3 — Blast radius

- **Một replica.** Không có load balancer, không có replica dự phòng. `app` sập là toàn hệ dừng.
- Validate input + giới hạn kích thước payload — chặn poison request.
- Không cần circuit breaker: không còn lời gọi mạng nội bộ nào.

---

## Hạ tầng đang chạy

| Thành phần | Vai trò | Trạng thái |
|---|---|---|
| **Postgres** | Nguồn sự thật duy nhất. Schema quản lý bằng Flyway (`V1..V13`), `ddl-auto: validate` | Chạy |
| **Redis** | Cache snapshot đã pin (`PinnedSnapshotCacheService`) + đếm rate limit | Chạy |
| **RabbitMQ** | Work-queue: job chấm AI, gửi email. **Không** phải event backbone | Chạy |
| **MinIO** | Object storage cho audio/ảnh — không nhét blob vào Postgres | Chạy |
| **Jaeger** | Tracing qua OpenTelemetry (`micrometer-tracing-bridge-otel` + OTLP) | Chạy |
| **Mailpit** | SMTP giả lập cho môi trường dev | Chạy (dev) |
| **Caddy** | TLS/ACME, reverse proxy edge | Chạy |

### Redis — nhiều vai, phân biệt rõ

**Không bao giờ là nguồn sự thật của bài thi.**

| Vai | Dùng cho | Trạng thái |
|---|---|---|
| Cache | Snapshot đề đã pin — bất biến nên TTL dài, không cần invalidation | Có |
| Rate limit | Token bucket theo tenant | Có |
| Single-flight lock | Chống cache stampede khi miss key nóng | Có |
| Idempotency dedup | — | **Không dùng.** Dedup phải bền và atomic với business write; Redis không đảm bảo được. Worker chấm dedup bằng trạng thái trong Postgres |

---

## Chưa có — ghi ra để không nhầm là đã có

| Thứ | Vì sao vẫn cần |
|---|---|
| **Row-Level Security** | Lỗ hổng cô lập tenant lớn nhất. Ưu tiên số một |
| **Metrics + alerting** (Prometheus/Grafana) | Chỉ có tracing. Không đo được thì mọi quyết định về tải đều là đoán — và đây là điều kiện tiên quyết để xét tách lại theo ADR-005 |
| **Log tập trung** (Loki/ELK) | Log hiện nằm trong container |
| **Statement timeout** | Van cuối cho query chạy loạn |
| **Bulk import async** | Lỗ hổng lớp 2 đã biết |
| **Vault** | Secret nằm trong biến môi trường. Chấp nhận được ở quy mô này, không chấp nhận được khi có dữ liệu thật của nhiều trung tâm |

Một số thứ trong ADR gốc **bị bỏ có chủ đích, không phải nợ**: Keycloak (tự làm auth trong `identity`), Linkerd mTLS (không còn lời gọi giữa service), Kong/APISIX (không còn gateway), PgBouncer (một app, pool của nó là van rồi), read replica (chưa đo được read đè write), OpenSearch (chưa có nhu cầu thật), Cloudflare CDN (chưa cần).

---

## Phòng thủ DB — các van còn lại

Kiến trúc cũ liệt kê 6 van. Sau khi thu gọn còn 4, và thứ tự ưu tiên đổi:

```
1. Rate limit per-tenant (Redis)      → từ chối sớm           ✅ có
2. Redis cache snapshot + single-flight → hấp thụ phần lớn READ ✅ có
3. Connection pool của app            → cap READ đồng thời     ✅ có (thay PgBouncer)
4. RabbitMQ                           → chỉ điều tiết chấm AI  ⚠️ không còn điều tiết write spike
```

**Van đã mất:** RabbitMQ từng đứng giữa hấp thụ write spike (bulk import, nộp bài hàng loạt). Nay bulk import chạy đồng bộ và nộp bài ghi thẳng — 500 sinh viên nộp cùng lúc đập trực tiếp vào Postgres.

**Cache warming:** snapshot đề bất biến → TTL dài, không invalidation, không stampede do write. Hiện là warm-on-pin (nạp lúc tạo attempt) chứ không phải job chủ động nạp trước theo cửa sổ kỳ thi — nghĩa là sinh viên đầu tiên của mỗi kỳ thi vẫn chịu một lần cache miss.

**Chốt:** READ điều tiết bằng pool size (đồng bộ); WRITE hiện **không có van nào**. RabbitMQ không dùng để gate read đồng bộ — sinh viên đang chờ response thì queue chỉ thêm độ trễ.
