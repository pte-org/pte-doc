# ADR-003: Tenant Isolation & Infrastructure Stack

**Date:** 2026-07-24
**Status:** Accepted — **phần Infrastructure stack lệch nhiều nhất so với as-built**, đối chiếu 2026-09-14 ở cuối file. Đọc mục đó trước khi dùng ADR này làm căn cứ.
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

---

## As-built reconciliation — 2026-09-14

ADR này kê ~15 component. **Thực tế deploy 8.** Phần lớn khoảng cách là defer có chủ đích và đúng với nguyên tắc "triển khai theo lớp" ở trên — nhưng mục `Consequences` đang gọi Vault/Keycloak/Linkerd/CDN là "nền không thể thiếu", và đó là câu **sai** cần sửa: hệ đang chạy được mà không có chúng.

### Đang chạy thật (`docker-compose.yml` + `docker-compose.deploy.yml`)

| Component | As-built | Khác gì so với ADR |
|---|---|---|
| RabbitMQ | `rabbitmq:3-management` | Đúng — outbox-relay + work queue, exchange tách biệt |
| Redis | `redis:7-alpine` | Đúng, nhưng chỉ dùng **2/5 vai** — xem bảng Redis bên dưới |
| Postgres | 4 instance (`pg-core`/`pg-exam`/`pg-live`/`pg-async`) | ADR không mô tả mô hình cell — nay ghi ở ADR-001 + ADR-005 |
| MinIO | `RELEASE.2025-09-07` | Đúng |
| Jaeger + OTel | `jaegertracing/all-in-one`, OTLP `http://jaeger:4318` | Đúng phần tracing |
| Gateway | **Spring Cloud Gateway (WebFlux)**, module `gateway/` trong chính mono-repo | ADR ghi **Kong/APISIX** — không dùng. Xem bên dưới |
| Caddy | TLS/ACME + same-origin routing (`deploy/Caddyfile`) | ADR không có edge/TLS layer nào |
| Mailpit | SMTP sink cho dev | ADR không nhắc (dev-only) |

### Chưa deploy (ADR liệt kê, code không có)

`Vault` · `Keycloak` · `Linkerd` · `PgBouncer` · `Cloudflare CDN` · `read replica` · `Prometheus/Grafana` · `Loki/ELK` · `OpenSearch` (đã HOÃN từ đầu).

Từng cái, thay bằng gì:

- **Vault → biến môi trường `.env`.** Mọi credential (DB user/password per-service, `RABBITMQ_*`, `MINIO_*`, `internal.service-key`, PEM key mã hoá đáp án) nạp qua env, compose bắt buộc phải set (`${X:?...}`) nên không có default rỗng lọt production. Chưa có rotation.
- **Keycloak → iam tự làm auth server.** iam ký RS256 bằng `RsaKeyProvider` của chính nó, expose `JwksController`; các service validate local bằng JWKS. Không OIDC provider ngoài, chưa có MFA. Đây là **đơn giản hoá hợp lý với quy mô** — Keycloak sẽ thêm một hệ thống phải vận hành để đổi lấy tính năng chưa dùng.
- **Linkerd mTLS → `InternalServiceAuth` header key.** Mọi call nội bộ mang `X-Internal-Service-Key`, gác bằng `InternalApiKeyFilter`; đường bootstrap rebuild cần thêm `X-Internal-Bootstrap-Key` (2 key cùng lúc). Comment trong `InternalClientConfig` ghi đúng bản chất: "ADR-003 mTLS placeholder". Đủ khi mọi service nằm chung một Docker network; **không đủ nếu tách VPS** — key tĩnh đi qua mạng giữa host.
- **PgBouncer → budget connection theo cell.** Van #4 ("cap READ đồng thời") as-built được thực hiện bằng `max_connections` đặt riêng mỗi cell (120/100/50/50) cộng Hikari pool mặc định mỗi service, thay vì một pooler đứng trước. Khác biệt quan trọng: cách này cap **theo cell**, không cap **theo service trong cùng cell** — 7 service trong `pg-core` vẫn có thể giành connection của nhau.
- **CDN / read replica / Prometheus / Loki → chưa có.** Không có `micrometer-registry-prometheus` trong bất kỳ `pom.xml` nào; observability hiện là tracing-only (Jaeger), không có metrics store và không có log aggregation. Đây là **lỗ hổng thật**, không phải defer hợp lý: 10 service phân tán mà không có metrics thì mọi câu hỏi "chậm ở đâu" đều phải trả lời bằng trace thủ công.

### Gateway: Kong/APISIX → Spring Cloud Gateway

Đổi trong quá trình build, chưa từng ghi lại. As-built `gateway/` là Spring Cloud Gateway WebFlux + `spring-boot-starter-oauth2-resource-server` + `data-redis-reactive`. **Van #1 (per-tenant rate-limit) đã có thật:** `RateLimitConfig.tenantKeyResolver()` key token bucket theo claim `tenant_id`, fallback `"anonymous"`. Lý do đổi (suy ra từ as-built, không phải ghi chép gốc): giữ gateway trong cùng mono-repo/cùng ngôn ngữ, dùng lại `pte-common` cho JWT claim, bớt một hệ thống ngoài phải vận hành. Chi phí: gateway giờ là một Java service phải deploy như mọi service khác, không phải một binary edge độc lập.

### Redis — 5 vai thiết kế, 2 vai as-built

| Vai (ADR) | As-built |
|---|---|
| Cache đề (immutable snapshot) | **CÓ** — `PinnedSnapshotCacheService`, TTL 24h |
| Single-flight lock | **CÓ** — cùng class, lock TTL 10s, 20 lần retry × 100ms |
| Rate-limit per-tenant | **CÓ** — `RateLimitConfig` ở gateway |
| Cache JWKS / tenant status | **KHÔNG** — JWKS cache in-JVM của `NimbusJwtDecoder` (mặc định Spring Security), không qua Redis |
| Idempotency dedup | **KHÔNG, và cố ý nên vậy** — dedup dùng bảng Postgres `ProcessedEvent` per-service (`AbstractProcessedEvent`). Dedup cần bền + atomic với business write; Redis không cho cả hai. **Sửa ADR: bỏ vai này khỏi Redis.** |
| Timer hot-cache | **KHÔNG** — timer/heartbeat là `AttemptHeartbeat` trong Postgres, không có lớp Redis |

Về **cache warming**: ADR mô tả background job theo cửa sổ session (từ `scheduling`) pre-warm trước khi student vào. As-built là **warm-on-pin** — `PinnedSnapshotCacheService.warm()` gọi ngay sau khi pin snapshot, nên read đầu tiên đã hit. Đạt cùng mục tiêu (không có cold read) rẻ hơn nhiều; không cần job pre-warm nữa trừ khi đo được pin và read cách nhau quá xa.

### Tenant isolation — 3 lớp, trạng thái thực tế

- **Lớp 1 (data):** ⚠️ **RLS chưa triển khai.** Không có `CREATE POLICY` / `ENABLE ROW LEVEL SECURITY` / `app.current_tenant` ở đâu trong repo. Scope tenant hiện ép ở tầng application (cột `tenantId` + điều kiện query). Nguyên tắc gốc của ADR — *"ép ở tầng DB, không tin tầng app"* — hiện **chưa được thoả mãn**. Một câu query thiếu điều kiện `tenantId` là rò dữ liệu chéo tenant, không có lưới an toàn nào bên dưới. Đây là khoảng cách nghiêm trọng nhất giữa ADR và as-built.
- **Lớp 2 (resource):** một phần, và có một chỗ **đi ngược ADR**. Per-tenant rate-limit ở gateway ✅. `authoring` chưa có bulk-import → van đó chưa cần. Nhưng **iam đã có bulk create user** (`UserBulkCreateWriter`) và nó chạy **đồng bộ trên request thread**, mỗi row một transaction `REQUIRES_NEW` — đúng kiểu tải mà ADR yêu cầu đẩy sang RabbitMQ. Import một lớp vài trăm student sẽ giữ connection `pg-core` trong suốt thời gian đó, và `pg-core` là cell dùng chung của 7 service. Đây là ứng viên số một cho van #6. Statement timeout chưa đặt ở đâu.
- **Lớp 3 (fault):** một phần. Circuit breaker ✅ (6 client, xem ADR-002). Multi-replica sau load balancer ❌ — mỗi service chạy đúng 1 container. Lưu ý ràng buộc ADR-002: outbox relay yêu cầu **đúng 1 instance producer** cho luồng cần ordering, nên scale ngang không phải chỉ tăng `replicas`.

### Bảo mật — as-built ngoài dự kiến ADR

**Mã hoá đáp án nộp bài** (không có trong ADR gốc, làm 2026-08/09): exam-delivery giữ keypair RSA-2048 riêng (`EncryptionKeyProvider`), tách hẳn khỏi key ký JWT của iam để exam-delivery không bao giờ phải gọi iam lấy key lúc runtime. Client nộp `EncryptedSubmissionRequest` ở mức `answerIntegrityLevel=STRICT`. Ngoài profile `dev`/`local`, thiếu PEM là **fail fast lúc khởi động** thay vì tự sinh keypair ephemeral (nếu sinh ephemeral thì mọi attempt đã pin public key sẽ hỏng sau restart). Key nạp từ env — **không phải Vault** như ADR-003 mục "Field-level encryption" mô tả.

**Tamper-evident audit (proctor)** — **đã triển khai đúng ADR.** `ViolationEvent` là bảng append-only mang `prevHash` + `hash`; `HashChainService` tính link bằng SHA-256 trên chuỗi canonical `sessionPublicId|sequenceNo|attemptPublicId|violationType|detail|detectedAt|prevHash`. Kiểm chứng bằng cách **tính lại toàn chuỗi rồi so**, không tin cột `hash` đã lưu — đúng cách. Chưa có WORM ở tầng storage, nhưng hash-chain là phần mang tính chất tamper-evident thật sự.

### Sửa trực tiếp vào ADR này

Mục `Consequences` cũ viết: *"Nền không thể thiếu: RabbitMQ + Redis + Vault + Keycloak + Linkerd mTLS + CDN + PgBouncer."* Câu này as-built đã bác bỏ. Đọc lại như sau:

- **Nền thật sự không thể thiếu (đang chạy):** RabbitMQ + Redis + Postgres (4 cell) + MinIO + Gateway + Caddy + OTel/Jaeger.
- **Lỗ hổng nên vá trước:** RLS (lớp 1) → metrics/log aggregation → statement timeout. Ba cái này đều rẻ và đều chặn một loại lỗi hiện không ai thấy được.
- **Defer đúng đắn, đừng vội:** Vault, Keycloak, Linkerd, CDN, read replica, OpenSearch, PgBouncer (cell budget đang gánh thay).
