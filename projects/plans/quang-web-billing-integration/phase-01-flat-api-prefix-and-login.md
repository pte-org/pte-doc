# Phase 1: Versioned REST API, Nginx edge và login username

Status: 🟡 In progress — implementing the approved REST/Nginx contract

## Requirements

## Confirmed decisions

- Breaking migration: callers must move to `/api/v1/...`; no legacy `/api/...`
  compatibility alias is required.
- Nginx replaces Caddy in the production and local Compose topology; the
  migration does not preserve a Caddy rollback path.
- PayOS webhook target is `https://<public-domain>/api/v1/webhooks/payos`,
  forwarded unchanged to `app:8091`.

Phase này thay thế bản triển khai cũ dùng Caddy handle_path. Backend, frontend, script và edge phải nhìn thấy cùng một contract:

~~~text
POST /api/v1/auth/login
GET  /api/v1/plans
POST /api/v1/orders
~~~

Spring Boot tự expose /api/v1; Nginx chỉ proxy nguyên path. Không đặt server.servlet.context-path, không strip prefix, không để tên microservice xuất hiện trong public URL.

Login đồng thời dùng payload { username, password } trên cả vendor-web và tenant-web.

Không dựng lại UI ngoài việc cập nhật hai LoginView để nhập username.

Maps to: [spec.md](spec.md) · [ADR-007](../../architecture/ADR-007-student-identity-and-login.md) · [ADR-008](../../architecture/ADR-008-modulith-reconciliation.md)

## Design Constraints

Preflight: Spring Boot 4 modular monolith uses class/method Spring MVC mappings,
the frontend centralizes paths in `packages/api-client`, and the current edge
uses Caddy `handle_path` to hide the backend's bare paths. This phase changes
the public contract at all three boundaries together. Internal controllers under
`/internal/**` and the STOMP transport endpoint `/ws` remain outside the public
REST prefix. Existing package/module names are retained; only public URLs,
edge configuration, and login field semantics change.

- Public REST path luôn bắt đầu /api/v1/; route UI /admin/* không phải API route.
- Resource path dùng plural kebab-case và stable public identifier.
- CRUD dùng HTTP method chuẩn. State transition nghiệp vụ được phép dùng action sub-resource nhưng phải có lý do, idempotency và status code trong route catalog.
- Mọi mapping phải được kiểm bằng route inventory trước khi sửa; không thay chuỗi máy móc theo tên thư mục cũ.
- Nginx chuyển tiếp nguyên path đến app:8091; không dùng rewrite, proxy_pass có URI suffix hoặc cơ chế tương đương làm đổi path.
- /actuator/health và /ws là endpoint hạ tầng/transport riêng, không ép vào /api/v1.
- MinIO media domain giữ nguyên Host và object path để SigV4 presigned URL không hỏng.
- Production chỉ public Nginx 80/443; app/web/minio không bind public ports trên VPS.
- Certbot/webroot phải có bootstrap, renew và rollback rõ ràng; Nginx không tự xin certificate.
- Tất cả user-facing validation/error messages mới tuân theo constants của module sở hữu.

## Steps

### Part A — Route inventory và contract

1. Quét toàn bộ @RestController và mapping ở cả class/method level. Phân loại:
   - public REST resource;
   - explicit public integration (/webhooks/payos);
   - WebSocket /ws;
   - actuator;
   - internal/legacy endpoint không được public qua Nginx.
2. Tạo route catalog có controller, method, current path, target path, auth role, request/response, status code và migration owner.
3. Chốt target path cho toàn bộ public controller:
   - thêm /api/v1 vào backend mapping;
   - bỏ iam, scheduling, authoring, exam-delivery, proctor, scoring, reporting, notification, media khỏi public path;
   - bỏ /admin khỏi API path khi đó chỉ là namespace quyền, giữ quyền ở Spring Security;
   - giữ /auth, /applications, /plans, /orders, /subscriptions, /license-codes, /settings như resource/action roots;
   - đổi các path không theo resource convention sau khi catalog được review.
4. Chốt các action exceptions. Ví dụ:
   - POST /api/v1/auth/login;
   - POST /api/v1/applications/{publicId}/approval;
   - POST /api/v1/plans/{publicId}/activation;
   - POST /api/v1/webhooks/payos.
   Không tự biến mọi động từ nghiệp vụ thành POST nếu có thể biểu diễn đúng bằng PATCH/DELETE.

### Part B — Backend route refactor

5. Refactor tất cả public controller về target mapping /api/v1/..., không chỉ tám controller từng hardcode /api.
6. Tách hoặc chặn các endpoint internal khỏi public surface. Không để internal/* được Nginx route nhầm vào API công khai.
7. Chuẩn hoá response status:
   - collection GET → 200;
   - create POST → 201 khi tạo resource;
   - update PUT/PATCH → 200;
   - delete → 204 nếu không trả body;
   - validation 400/422, unauthenticated 401, forbidden 403, conflict 409, rate limit 429.
8. Giữ envelope lỗi machine-readable hiện có; bổ sung code/details nếu route mới cần, đặt constants ở package sở hữu.
9. Cập nhật SecurityConfig cho các public path `/api/v1/auth/*`, `/api/v1/webhooks/payos`, `/actuator/health` và `/ws`; không để path cũ rơi vào `authenticated()` ngoài ý muốn.
10. Cập nhật key override của RateLimitFilter theo `request.getRequestURI()` mới, đặc biệt endpoint redeem và các endpoint public; test cả status 401/403/429.
11. Kiểm tra route collision sau khi đổi /students/import/preview, nested enrollment và toàn bộ literal/path-variable mappings.

### Part C — Nginx local và production

12. Xoá service/config/volume Caddy khỏi Compose và deployment runbook sau khi Nginx có parity.
13. Thêm Nginx container/config:
    - local HTTP :8080;
    - production :80 redirect sang :443, server names cho tenant/admin/media;
    - /api/v1/ proxy đến app:8091 không rewrite;
    - /actuator/health route theo policy healthcheck;
    - /ws proxy với Upgrade/Connection;
    - UI fallback đến đúng Next.js container;
    - media proxy giữ Host, path và streaming headers.
14. Thêm Certbot/webroot và named certificate volume. Chạy bootstrap một lần, certbot renew --dry-run, rồi reload Nginx không downtime.
15. Thêm nginx -t, container healthcheck, config validation và rollback procedure. Không commit certificate/private key.
16. Cập nhật .env.example, deploy README, CI/CD và seed script; API base URL production/local phải trỏ đến Nginx hoặc app trực tiếp theo môi trường, không trỏ Caddy.

### Part D — api-client và login

17. Đổi toàn bộ endpoint constants trong pte-web/packages/api-client sang target /api/v1/...; giữ tên thư mục cũ cho đến một migration riêng.
18. Đổi LoginRequest và các request login sang { username, password }; bỏ mapping vòng username → email.
19. Cập nhật hardcode refresh trong createSessionApiClient.ts.
20. Cập nhật hai LoginView và constants: label/placeholder username, không dùng type=email.
21. Cập nhật seed-e2e.ps1, PayOS webhook URL và mọi tài liệu/curl example.

### Part E — Tests và rollout

22. Mở rộng RouteContractTest để fail khi:
    - public mapping thiếu /api/v1;
    - còn legacy service segment;
    - có /admin chỉ vì role namespace;
    - method/path target không khớp route catalog.
23. FE contract tests kiểm tra mọi endpoint bắt đầu /api/v1 và login gửi username, không gửi email.
24. Test Nginx với direct backend và proxied request: status, body envelope, auth, multipart upload, webhook, WebSocket 101, presigned media URL.
25. Chạy build/test backend + FE, nginx -t, Certbot dry-run; sau đó smoke test đăng nhập thật và nghiệp vụ billing.
26. Rollout theo thứ tự: deploy config Nginx, verify health, switch DNS/ports if needed, verify all public domains, retain rollback snapshot.

## Success Criteria

- [ ] 100% public controller mappings bắt đầu /api/v1; zero legacy service-name segment trong backend public mapping và api-client.
- [ ] Direct http://localhost:8091/api/v1/... và proxied http://localhost:8080/api/v1/... resolve cùng controller trong local.
- [ ] Nginx production pass nginx -t; only 80/443 public; Caddy không còn trong Compose.
- [ ] /actuator/health trả 200; WebSocket handshake trả 101; MinIO presigned URL trả đúng object; PayOS webhook nhận được.
- [ ] Login thật thành công bằng PLATFORM_ADMIN trên vendor-web và HOST_ADMIN trên tenant-web.
- [ ] Existing class/program/exam/question screens still work through the new contract.
- [ ] Certbot renewal dry-run pass và certificate monitoring cảnh báo trước 14 ngày.
- [ ] Full backend/FE contract tests pass; no regressions in existing suite.

## Quality and Testing State

- Decision checkpoint: unit tests = yes; quality gate = yes.
- Current state: implementation complete for the revised REST/Nginx contract.
- Build: PASSED — backend compile; tenant-web and vendor-web production builds; merged Compose validation.
- Testing: PASSED — backend 576/576 tests; api-client 170/170 tests; frontend typecheck and lint.
- Quality gate: APPROVED — no blocking findings; runtime smoke checks remain pending because Docker Linux engine was unavailable.

## Session Notes

## Cook result — 2026-09-17

- Implementation and source-level quality gate: `APPROVED`.
- Backend compile/tests, frontend typecheck/lint/build, route contract checks, and merged Compose validation pass.
- Runtime smoke checks are explicitly pending because the local Docker Linux engine was unavailable.

2026-09-17 — Người dùng chốt production dùng Nginx trước; managed load balancer để phase tương lai. Phase 1 cũ phải được chạy lại vì backend route trần và Caddy handle_path không còn phù hợp với contract REST độc lập.
