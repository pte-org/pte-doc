# Plan: Nối pte-web với REST API thương mại hoá

Status: 🟡 Replanned — Phase 1 cũ đã được triển khai nhưng bị supersede bởi quyết định REST/Nginx mới
Date: 2026-09-17
Mode: Hard
Created by: Quang
Spec: [spec.md](spec.md) · Brainstorm: [260917-web-api-nginx-brainstorm.md](../reports/260917-web-api-nginx-brainstorm.md)
Related: [ADR-006](../../architecture/ADR-006-commercialization-and-exam-templates.md) · [ADR-007](../../architecture/ADR-007-student-identity-and-login.md) · [plan backend](../quang-tenant-commercialization/plan.md)

## Overview

Backend đã có các module thương mại hoá và FE đã dựng sẵn màn hình cho cả hai app, nhưng contract API còn mang dấu vết microservice và phụ thuộc vào proxy cắt path. Plan này nối FE với backend bằng một REST API versioned, đồng thời thay Caddy bằng Nginx ở edge trước mắt.

Mục tiêu không phải dựng lại UI. Mục tiêu là:

- Spring Boot tự expose contract public dưới /api/v1/...;
- Nginx chỉ reverse proxy nguyên path, không strip/rewrite;
- api-client, seed script, webhook, WebSocket và media dùng cùng contract;
- sau này thay Nginx bằng load balancer không phải đổi URL API.

## Phases

- [ ] Phase 1: API contract versioning + REST route migration + Nginx + login username (chặn tất cả)
- [ ] Phase 2: api-client module billing — types + requests, chưa đụng UI
- [ ] Phase 3: vendor-web — duyệt đơn đăng ký tổ chức
- [ ] Phase 4: vendor-web — catalog gói, tham số nền tảng, mã kích hoạt
- [ ] Phase 5: tenant-web — đăng ký tổ chức + theo dõi đơn (luồng công khai)
- [ ] Phase 6: tenant-web — mua gói qua PayOS + lịch sử đơn hàng
- [ ] Phase 7: tenant-web — nhập mã kích hoạt, gói đang có, hạn mức sinh viên

## Thứ tự và phụ thuộc

~~~text
P1 ──> P2 ──┬──> P3 ──> P4        (vendor-web)
            │
            └──> P5 ──> P6 ──> P7 (tenant-web)
~~~

P1 chặn tất cả — đây là migration contract toàn hệ thống, không chỉ là sửa một vài billing endpoint.

P2 chặn mọi phase UI — mọi request mới vẫn phải đi qua api-client và TanStack Query.

P3–P4 và P5–P7 vẫn độc lập sau khi P1/P2 hoàn thành.

## Quyết định kiến trúc đã chốt

| Quyết định | Hợp đồng |
|---|---|
| API prefix | /api/v1 là prefix thật do Spring Boot expose; không dùng prefix tên service và không dùng proxy strip |
| REST URL | plural nouns, kebab-case, public identifier; GET/POST/PUT/PATCH/DELETE theo CRUD |
| Domain action | Dùng action sub-resource được ghi rõ trong route catalog, ví dụ /auth/login, /orders/{id}/payment, /applications/{id}/approval |
| Admin URL | Không dùng /admin như namespace API cho cùng một resource; phân quyền bằng Spring Security. /admin/* vẫn có thể là route UI của vendor-web |
| Edge production | Nginx trước mắt xử lý TLS, host routing, API, WebSocket và media; sau này có thể thay bằng managed load balancer |
| Path forwarding | Nginx chuyển tiếp nguyên /api/v1/... đến app:8091; không cắt, thêm hoặc đổi segment |
| Local development | Nginx local có thể chạy ở :8080; backend vẫn phải gọi trực tiếp được ở :8091/api/v1/... |
| TLS | Certbot/webroot hoặc cơ chế tương đương cấp và renew Let's Encrypt; Nginx không tự đảm nhiệm ACME |
| Actuator | Giữ /actuator/health, không đưa vào /api/v1 và không dùng server.servlet.context-path |
| Login | Payload thống nhất { username, password }; cả PLATFORM_ADMIN, HOST_ADMIN và student dùng cùng semantics |

## REST contract baseline

Các mapping cụ thể phải được chốt trong route inventory trước khi sửa code. Baseline bắt buộc:

~~~text
POST   /api/v1/auth/login
POST   /api/v1/auth/refresh
POST   /api/v1/auth/logout
GET    /api/v1/auth/me

GET    /api/v1/plans
POST   /api/v1/plans
GET    /api/v1/plans/{publicId}
PUT    /api/v1/plans/{publicId}
GET    /api/v1/orders
POST   /api/v1/orders
GET    /api/v1/subscriptions
GET    /api/v1/license-codes
POST   /api/v1/license-codes
POST   /api/v1/license-code-redemptions
POST   /api/v1/applications
GET    /api/v1/applications
POST   /api/v1/applications/{publicId}/approval
POST   /api/v1/applications/{publicId}/rejection
GET    /api/v1/settings
GET    /api/v1/settings/{key}
PUT    /api/v1/settings/{key}
POST   /api/v1/webhooks/payos
~~~

Các state transition của exam/session/class/user vẫn có thể dùng POST action sub-resource khi nghiệp vụ không phải CRUD thuần; route, idempotency và status code phải được ghi trong catalog, không tự đặt trong component.

## Dependencies

Có sẵn, tái dùng:

- packages/api-client/src/client/client.ts — refresh-token dedup, unwrap envelope, upload/download, ApiError.
- Component commercialization của cả hai app.
- @pte/ui cho bảng, modal, badge.
- Spring Security/CORS/rate-limit hiện có trong monolith.

Phải thêm hoặc refactor:

- Route inventory + contract test cho toàn bộ public controllers.
- Base mapping /api/v1 và route resource/action chuẩn trong backend.
- Nginx config cho local/production, Certbot webroot và healthcheck.
- packages/api-client endpoint constants theo /api/v1.
- packages/api-client/src/types/billing/ và requests/billing/ — P2.
- features/commercialization/api.ts cho mỗi app — P3 trở đi.

## Deployment topology

~~~text
Internet :80/:443
        │
      Nginx
        ├── /api/v1/*       → app:8091 (giữ nguyên path)
        ├── /actuator/*     → app:8091 (health policy rõ ràng)
        ├── /ws             → app:8091 (Upgrade/Connection headers)
        ├── tenant host     → web-tenant:3000
        ├── admin host      → web-vendor:3000
        └── media host      → minio:9000 (giữ Host cho SigV4)
~~~

Nginx và Certbot là thành phần deploy; app không public trực tiếp trên hosted VPS. Khi chuyển sang load balancer, chỉ thay edge/upstream discovery, giữ nguyên public URL.

## Risks and mitigations

| Rủi ro | Xử lý |
|---|---|
| Refactor route làm gãy màn hình cũ | Route inventory trước, contract test theo method + path, smoke test trực tiếp và qua Nginx |
| Còn sót tên service hoặc route root | Test fail nếu public mapping không bắt đầu /api/v1 hoặc chứa service segment |
| Nginx chạy nhưng certificate hết hạn | Certbot bootstrap, renew dry-run, alert khi cert còn dưới 14 ngày |
| WebSocket bị 400/426 | Cấu hình Upgrade headers và kiểm handshake 101 |
| MinIO SignatureDoesNotMatch | Proxy giữ Host/path, không rewrite media URL |
| CORS/auth thay đổi do tách origin | Giữ cùng origin cho browser; direct local chỉ dùng CORS allow-list explicit |
| PayOS webhook trỏ URL cũ | Cập nhật dashboard PayOS thành /api/v1/webhooks/payos và test callback thật |
| Rollback deploy không an toàn | Giữ Nginx config versioned, validate trước reload, rollback Compose cùng image/config |

## Technical debt intentionally deferred

- Managed load balancer, multi-replica app và autoscaling.
- Đổi tên toàn bộ thư mục requests/scheduling, requests/authoring, requests/scoring; path contract phải đi trước rename.
- Business workflow redesign ngoài phần cần để chuẩn hoá resource/action URL.
- Thay đổi JWT/session semantics ngoài việc thống nhất login bằng username.

## Test strategy

P1 phải có unit/contract tests và smoke test runtime:

- mọi public controller có prefix /api/v1;
- không còn legacy service segment trong backend public mapping và api-client;
- class-level và method-level mapping đều bị bắt nếu sai;
- direct app:8091/api/v1/... và Nginx /api/v1/... cùng route;
- login thật bằng PLATFORM_ADMIN và HOST_ADMIN;
- PayOS webhook, WebSocket 101, MinIO presigned URL;
- nginx -t, Certbot renew dry-run và app /actuator/health.

P2–P7 giữ các kịch bản nghiệp vụ hiện có nhưng mọi URL đều lấy từ contract /api/v1.

## Historical note

Phase 1 trước đây đã triển khai /api phẳng ở frontend và route trần ở backend, với 575 backend tests và 138 FE tests xanh. Kết quả đó được giữ làm lịch sử kiểm chứng, nhưng không còn là trạng thái đạt của plan này vì contract cũ phụ thuộc Caddy handle_path. Phase 1 phải chạy lại theo spec REST/Nginx mới.
