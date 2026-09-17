# ADR-005: Deployment Topology — Single-Host, Edge Caddy

**Date:** 2026-09-14 · **Viết lại 2026-09-16** sau khi thu gọn về monolith
**Status:** Accepted
**Depends on:** [ADR-001](ADR-001-module-boundaries.md), [ADR-003](ADR-003-tenant-isolation-and-infrastructure.md)

> **Lịch sử:** bản gốc mô tả 10 service container + Spring Cloud Gateway + 4 cell Postgres. Sau khi thu gọn: **1 container ứng dụng, 1 Postgres, không gateway**.

---

## Decision

**Một host, một tiến trình ứng dụng, Caddy làm edge.** Failure domain đáng lo nhất giờ không còn nằm giữa các service — nó nằm **bên trong một JVM**.

```
Internet
  └─ Caddy (:80/:443) — TLS/ACME, same-origin routing theo domain
       ├─ {TENANT_DOMAIN} /api/*, /actuator/*  → app:8091
       ├─ {TENANT_DOMAIN} /*                   → web-tenant  (Next.js)
       ├─ {ADMIN_DOMAIN}  /api/*               → app:8091
       ├─ {ADMIN_DOMAIN}  /*                   → web-vendor  (Next.js)
       └─ {MEDIA_DOMAIN}                       → minio
            └─ app ── postgres · redis · rabbitmq · minio · jaeger
```

Tất cả trên một Docker network `pte-network`, một máy. Route API tách thành `deploy/api-routes.caddy` và `import` vào cả hai domain — một nơi khai báo, hai nơi dùng.

---

## Vì sao same-origin (không phải API subdomain riêng)

Mỗi app có **một origin phục vụ cả UI lẫn API** → trình duyệt không bao giờ phát cross-origin request: không CORS preflight, không mixed content, và WebSocket của proctor đi chung host với `wss://`. Cấu hình CORS vẫn giữ làm fallback cho client không được serve từ hai host đó (Flutter app, curl, Postman).

Đổi lấy: Caddy là thành phần duy nhất mà **mọi** request phải đi qua.

---

## Gateway bị gỡ — hai việc nó từng làm đi đâu

| Việc | Trước | Nay |
|---|---|---|
| Validate JWT | Spring Cloud Gateway | `spring-boot-starter-oauth2-resource-server` ngay trong app |
| Rate limit per-tenant | Gateway + Redis | `shared/web/RateLimitFilter` + `RateLimitConfig`, vẫn Redis |
| Định tuyến tới service | Gateway | Không còn việc gì để định tuyến — một app duy nhất |

Giữ gateway khi chỉ còn một upstream là thêm một hop mạng, một SPOF, một container 512m để đổi lấy không gì cả.

---

## Database

**Một Postgres.** Không còn cell, không còn credential per-service, không còn `*_DB_URL` riêng.

Schema quản lý bằng **Flyway** (`flyway.enabled: true`, `locations: classpath:db/migration`, `V1__init` … `V13__reporting`) với `hibernate.ddl-auto: validate` — Hibernate **không** tự sinh schema, chỉ kiểm entity có khớp schema mà Flyway đã dựng hay không. Lệch là app không khởi động được, phát hiện lúc start chứ không phải lúc chạy query đầu tiên.

Hệ quả có lợi cần biết: **viết được SQL thủ công.** Những thứ JPA không khai báo nổi — partial index, exclusion constraint (`EXCLUDE USING gist` cho ràng buộc không trùng khung giờ ở [ADR-006](ADR-006-commercialization-and-exam-templates.md)), extension, trigger — đều nằm trong tầm.

---

## Ngân sách RAM

| Container | `mem_limit` |
|---|---|
| `app` | 512m–1g |
| `postgres` | 1g |
| `rabbitmq` / `redis` / `minio` / `jaeger` | 512m / 256m / 512m / 512m |
| `web-tenant`, `web-vendor` | 512m mỗi cái |
| `caddy` | không giới hạn |

JVM chạy `-XX:MaxRAMPercentage=70` để heap co theo `mem_limit` của container thay vì theo RAM host — thiếu cờ này thì JVM tự tính heap theo RAM toàn máy và `mem_limit` biến thành cái máy chém OOM.

`restart: unless-stopped` + `start_period` dài trên healthcheck: không được đánh trượt một Spring Boot đang khởi động chậm.

---

## Single point of failure — liệt kê thẳng

| SPOF | Sập thì mất gì |
|---|---|
| **Host / Docker daemon** | Toàn bộ |
| **Caddy** | Toàn bộ traffic vào (TLS terminate ở đây) |
| **`app`** | **Toàn bộ chức năng.** Một container, một replica — đây là thay đổi lớn nhất so với kiến trúc cũ, nơi mỗi service sập riêng |
| **Postgres** | Toàn bộ. Không còn `pg-exam` riêng để bài thi sống sót |
| **Redis** | Cache snapshot (`PinnedSnapshotCacheService`) tụt về đập thẳng Postgres; rate limit mất hiệu lực |
| **RabbitMQ** | Chấm điểm và email dừng. Thi và nộp bài **không ảnh hưởng** |
| **Volume chứng chỉ Caddy** | Mất thì mỗi lần restart phải xin lại cert, đụng rate limit 5 cert/domain/tuần của Let's Encrypt → dùng named volume, không phải bind/anonymous |

**Điều phải nói thẳng:** kiến trúc cũ có một tính chất mà kiến trúc này không có — `pg-core` sập thì sinh viên **vẫn thi được**. Nay không còn bức tường nào như vậy. `app` hoặc `postgres` sập là mọi thứ dừng, kể cả bài thi đang diễn ra.

---

## Consequences

**Được:** một `docker compose up` chạy cả hệ. Deploy là thay một image. Không còn phải suy nghĩ về thứ tự khởi động 10 service, về service A gọi service B chưa sẵn sàng, về version skew giữa các service.

**Trả giá:** mọi thứ nằm trong một rổ. Mất host là mất tất cả; mất `app` cũng gần như vậy.

**Điều kiện để xét tách lại** — không phải "khi nào rảnh" mà là khi thoả:

1. **Có metrics** để biết cái gì thật sự chạm trần. Hiện chỉ có tracing (Jaeger), không có metrics aggregation — đang đoán chứ không đo.
2. **Đo được** rằng tải của một nhóm chức năng (bulk import, chấm AI, WebSocket proctor) thật sự ảnh hưởng tới độ trễ của đường thi. Nếu chưa đo được thì tách là chữa bệnh chưa chẩn đoán.
3. **Ranh giới module được ép bằng test**, không chỉ quy ước — `ApplicationModules.verify()` xanh. Tách một module đang rò rỉ phụ thuộc chỉ biến lỗi biên dịch thành lỗi runtime.

Khi tách, **đường cắt là một nhát**: `attempt` + `proctoring` + Redis tách ra thành exam plane riêng. Redis phải đi cùng — nó là read path của sinh viên, không phải hạ tầng async. Cắt nhỏ hơn thế không mua thêm availability nào đáng kể.
