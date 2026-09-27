# Spec: REST API versioning và Nginx edge

**Date:** 2026-09-17
**Status:** Approved

**Confirmed decisions (2026-09-17):** This is a breaking migration to
`/api/v1/...`; the old `/api/...` contract will not be retained. Production uses
Nginx instead of Caddy, with no Caddy rollback path. PayOS uses
`https://<public-domain>/api/v1/webhooks/payos` and Nginx forwards it unchanged.

## Problem Statement

API hiện phụ thuộc vào việc Caddy cắt prefix: frontend gọi `/api/...` nhưng Spring Boot chỉ thấy route trần. Điều này tạo ra contract không nhất quán khi gọi trực tiếp, khó thay edge và làm route migration dễ gãy.

## User Stories

- **[P1]** As a frontend client, I want to call a stable versioned REST API so that the client contract is independent of the reverse proxy.
  Accepted when: all public API requests use `/api/v1/...`, and direct calls to `app:8091` and proxied calls through Nginx use the same path.

- **[P1]** As a deployment operator, I want Nginx to route traffic without rewriting API paths so that replacing Nginx with a load balancer later does not require an API refactor.
  Accepted when: Nginx config passes `nginx -t`, `/api/v1/*` is proxied unchanged, and UI/API/media routes work on all three production domains.

- **[P1]** As an API consumer, I want predictable REST resource URLs, methods, status codes, and errors so that new UI features do not depend on service-name paths or ad-hoc routing.
  Accepted when: the route inventory maps every public controller to a plural resource under `/api/v1`, action endpoints are explicitly documented exceptions, and contract tests cover method plus path.

- **[P2]** As an operator, I want automated certificate renewal and observable edge health so that Nginx does not become a manual production burden.
  Accepted when: Certbot renewal dry-run passes and Nginx/app health checks are available without exposing secrets.

- **[P3]** As a platform owner, I want to move from one Nginx edge to a managed load balancer later so that horizontal scaling can be added without changing API URLs.
  Accepted when: the public contract contains no Nginx-specific path rewrite or container hostname.

## Functional Requirements

1. FR-01: Every public Spring controller is versioned under `/api/v1`; actuator remains at `/actuator/health`.
2. FR-02: Resource paths use plural kebab-case nouns, stable public identifiers, and HTTP methods according to CRUD semantics.
3. FR-03: Authentication and explicit domain commands use documented action sub-resources, for example `/api/v1/auth/login` and `/api/v1/orders/{id}/payment`.
4. FR-04: Remove legacy service segments (`iam`, `scheduling`, `authoring`, and similar) from public paths and from `api-client` endpoint constants.
5. FR-05: Nginx forwards `/api/v1/*` to `app:8091` without stripping, adding, or translating path segments.
6. FR-06: Nginx routes tenant UI, vendor UI, API, actuator, media, and WebSocket traffic; MinIO `Host` and presigned URL semantics remain valid.
7. FR-07: Local development can run the frontend against the backend directly; production retains same-origin UI/API routing through Nginx.
8. FR-08: Route contract tests cover class-level and method-level mappings, direct backend paths, Nginx proxy paths, and the login payload `{ username, password }`.

## Non-Functional Requirements

- Performance: Nginx proxy overhead is measured against direct app access; p95 overhead target is at most 20 ms in the smoke-load scenario.
- Security: production exposes only Nginx ports `80`/`443`; TLS is enforced, CORS is an explicit allow-list, and login/public endpoints remain rate-limited.
- Availability: Nginx has restart policy and a passing config/health check; certificate renewal dry-run passes before production cutover.

## Success Criteria

- [ ] 100% of public controller mappings are under `/api/v1`; zero legacy service-name path segments remain in public `api-client` requests.
- [ ] 100% of critical API smoke requests return the same status through direct app access and Nginx, aside from intentionally different TLS/host handling.
- [ ] `nginx -t`, app healthcheck, login for `PLATFORM_ADMIN` and `HOST_ADMIN`, PayOS webhook, WebSocket handshake, and MinIO presigned URL checks pass.
- [ ] Certbot renewal dry-run passes and no production certificate is within 14 days of expiry after deployment.
- [ ] Replacing Nginx with a future load balancer requires no frontend or backend URL rewrite.

## Out of Scope

- Managed load balancer, multiple app replicas, autoscaling, and multi-region deployment.
- Redesigning business workflows or rebuilding existing frontend screens.
- Changing JWT/session semantics beyond the existing username login contract.

## Assumptions

- The current three public domains remain: tenant, vendor/admin, and media.
- Nginx runs as the production edge on the current single VPS; Certbot owns certificate issuance/renewal.
- The backend remains a single Spring Boot modular monolith and listens internally on `8091`.
