# ADR-005: Deployment Topology — Single-Host Cells & Edge Layer

**Date:** 2026-09-14
**Status:** Accepted (ghi lại as-built — quyết định đã thực hiện dần trong 2026-08/09, chưa từng có ADR)
**Depends on:** ADR-001 (service boundaries), ADR-003 (infrastructure stack)

**Context:** ADR-001 chốt *logical* boundary (service nào own dữ liệu gì). ADR-003 kê *component* hạ tầng. Không ADR nào nói **những thứ đó chạy ở đâu** — kết quả là mọi thảo luận về availability đều phải suy ngược từ file compose. ADR này ghi lại topology thật và nói rõ cái gì đang được cô lập, cái gì thì không.

---

## Decision

**Một host duy nhất, cô lập bằng container + cell Postgres + giới hạn RAM per-container.** Không phải một host vì chưa nghĩ tới chuyện tách, mà vì ở quy mô hiện tại failure domain đáng lo nhất **nằm bên trong host** (một service ăn hết connection / RAM), không phải chuyện mất cả host.

Ba lớp, từ ngoài vào:

```
Internet
  └─ Caddy (:80/:443)  — TLS/ACME, same-origin routing theo domain
       ├─ {TENANT_DOMAIN} /api/*   → gateway
       ├─ {TENANT_DOMAIN} /*       → web-tenant   (Next.js)
       ├─ {ADMIN_DOMAIN}  /api/*   → gateway
       ├─ {ADMIN_DOMAIN}  /*       → web-vendor   (Next.js)
       └─ {MEDIA_DOMAIN}           → minio
            └─ gateway (Spring Cloud Gateway) — JWT, per-tenant rate-limit
                 └─ 10 service container ── 4 Postgres cell + redis + rabbitmq + minio + jaeger
```

Tất cả nằm trên một Docker network `pte-network`, một máy.

---

## Vì sao same-origin (không phải API subdomain riêng)

Mỗi app có **một origin phục vụ cả UI lẫn API** → trình duyệt không bao giờ phát cross-origin request: không CORS preflight, không mixed content, và STOMP socket của proctor đi chung host với `wss://`. `CORS_ALLOWED_ORIGINS` trên gateway vẫn giữ — làm fallback cho client không được serve từ hai host đó (Flutter app, curl, Postman).

Đổi lấy: Caddy trở thành thành phần duy nhất mà **mọi** request phải đi qua. Xem mục SPOF.

---

## Cell Postgres — cô lập theo profile tải, không theo service

| Cell | DB | `max_connections` | `mem_limit` |
|---|---|---|---|
| `pg-core` | iam, admin, authoring, scheduling, reporting, notification, media | 120 | 1g |
| `pg-exam` | exam_delivery | 100 | 512m |
| `pg-live` | proctor | 50 | 512m |
| `pg-async` | scoring | 50 | 512m |

Mỗi DB có **user + password riêng** (`${SERVICE}_DB_USER` / `_DB_PASSWORD`), tạo bởi `docker/postgres/init-{cell}/01-create-databases.sql`. Ownership của ADR-001 được giữ nguyên: không query chéo DB, cross-service reference bằng `publicId` UUID.

**Vì sao gom thành cell thay vì 10 instance:** 10 tiến trình Postgres trên một host là 10 lần overhead bộ nhớ/WAL/checkpoint để đổi lấy cô lập mà ở 7 service low-traffic không ai cần. Cell gom theo **profile**: critical path (`pg-exam`), WebSocket long-lived (`pg-live`), burst theo queue (`pg-async`), phần còn lại (`pg-core`).

**Tách ra sau không phải sửa code** — mỗi service đã trỏ DB qua biến `*_DB_URL` riêng. Tách một DB khỏi cell = dựng instance mới, dump/restore, đổi một biến môi trường.

**Hệ quả phải nhớ:** trong `pg-core`, 7 service dùng chung 120 connection và một tiến trình Postgres. Cô lập ở tầng service đã có; ở tầng `pg-core` thì **chưa**. Đó là lý do `exam-delivery` không nằm trong đó.

---

## Ngân sách RAM

| Nhóm | Số container | `mem_limit` mỗi cái | Tổng |
|---|---|---|---|
| Service Java + gateway | 11 | 512m | 5.5g |
| Postgres | 4 | 1g + 512m×3 | 2.5g |
| rabbitmq / redis / minio / jaeger | 4 | 512m / 256m / 512m / 512m | 1.75g |
| web-tenant, web-vendor | 2 | 512m | 1g |
| caddy | 1 | không giới hạn | — |
| | | **Tổng** | **≈ 10.75g** |

JVM chạy `-XX:MaxRAMPercentage=70` để heap co theo `mem_limit` của container thay vì theo RAM của host — thiếu cờ này thì mỗi JVM tự tính heap theo RAM toàn máy và `mem_limit` biến thành cái máy chém OOM.

`restart: unless-stopped` + `start_period: 120s` trên mọi service: healthcheck không được đánh trượt một service Spring Boot đang khởi động chậm.

---

## Single point of failure — liệt kê thẳng

Chấp nhận có chủ đích ở quy mô hiện tại, nhưng phải gọi đúng tên:

| SPOF | Sập thì mất gì |
|---|---|
| **Host / Docker daemon** | Toàn bộ |
| **Caddy** | Toàn bộ traffic vào (TLS terminate ở đây) |
| **Gateway** | Toàn bộ API (1 instance) |
| **Redis** | Read path đề (`PinnedSnapshotCacheService`) tụt về đập thẳng `pg-exam`, và rate-limit gateway mất hiệu lực |
| **RabbitMQ** | Saga dừng. Không mất dữ liệu (outbox giữ lại, relay retry), nhưng chấm/report/notification đứng |
| **`pg-core`** | 7 service. exam-delivery **vẫn thi được** — đây chính là điểm của cell |
| **Volume chứng chỉ Caddy** | Mất thì mỗi lần restart phải xin lại cert, đụng rate-limit 5 cert/domain/tuần của Let's Encrypt → dùng named volume, không phải bind/anonymous |

Mỗi service chạy **đúng 1 container**. Chưa có multi-replica, và scale ngang không phải chỉ tăng `replicas`: ADR-002 ràng buộc outbox relay của producer cần ordering phải chạy **đúng 1 instance**.

---

## Consequences

**Được:** một `docker compose up` là chạy được cả hệ; cô lập trong-host thật (container riêng, cell riêng, RAM cap riêng); giữ được đường nâng cấp — tách DB hay tách host sau này là đổi config, không sửa code.

**Trả giá:** mất cả host là mất tất cả. `InternalServiceAuth` dùng static key trong header, an toàn vì mọi service nằm chung một Docker network — **giả định này vỡ ngay khi tách host**, lúc đó cần mTLS hoặc private network có kiểm soát.

**Điều kiện để xét tách nhiều host** (không phải "khi nào rảnh", mà là khi thoả những cái này):
1. `docker stop <từng service>` trong lúc có attempt đang chạy, attempt vẫn load được đề và submit được — **cho cả 9 service còn lại**. Chưa pass bài này thì tách host chỉ biến lỗi local thành network partition.
2. Có metrics (ADR-003 ghi thiếu) để biết cell nào thật sự chạm trần, thay vì đoán.
3. Thay static internal key bằng cơ chế chịu được truyền qua mạng giữa host.

Khi tách, **đường cắt là 1 nhát**: `exam/live plane` (exam-delivery + proctor + pg-exam + pg-live + **Redis riêng**) tách khỏi phần còn lại. Redis phải đi cùng exam plane — nó là read path của student, không phải hạ tầng async. Cắt thêm giữa control plane và async plane không mua thêm availability nào: cả hai loại lỗi đó đều đã ở mức chấp nhận được.
