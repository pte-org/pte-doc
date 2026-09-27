# Brainstorm: REST API contract và edge production bằng Nginx

**Date:** 2026-09-17

## Ideas Explored

- **Giữ Caddy và cắt `/api`:** loại bỏ. Frontend và backend nhìn thấy hai contract khác nhau; lỗi chỉ lộ khi gọi app trực tiếp.
- **Giữ Caddy nhưng chuyển tiếp nguyên path:** kỹ thuật tốt và ít thay đổi, nhưng không đáp ứng lựa chọn vận hành hiện tại của người dùng.
- **Nginx làm edge trước mắt:** được chọn. Nginx xử lý TLS, routing, WebSocket và proxy; không rewrite API path.
- **Bỏ mọi edge, expose trực tiếp từng container:** chỉ phù hợp local hoặc môi trường đặc biệt. Một VPS không thể để nhiều container cùng chiếm HTTPS `443`, và phải tự giải quyết certificate.
- **Managed load balancer:** để dành cho giai đoạn scale sau; không đưa vào MVP hiện tại.

## User's Direction

Production dùng **Nginx trước**, sau này nếu cần scale hoặc load balancing thì đánh giá phương án managed load balancer. API phải là contract REST độc lập với Nginx:

```text
/api/v1/{resource}
```

Nginx chỉ forward nguyên path đến Spring Boot. Backend tự expose `/api/v1`, không dùng `server.servlet.context-path` và không phụ thuộc vào việc proxy cắt prefix.

## Decisions Confirmed

- Đây là breaking migration: public contract dùng `/api/v1/...`, không giữ alias
  `/api/...`.
- Production dùng Nginx; Caddy được loại khỏi Compose/deployment và không cần
  rollback qua Caddy.
- PayOS webhook dùng `https://<public-domain>/api/v1/webhooks/payos` và Nginx
  forward nguyên path.
- Giữ nguyên các public domain hiện tại. Cơ chế Certbot/webroot là chi tiết
  triển khai trong Phase 1, không thay đổi contract.

## Risks

- Refactor prefix cho toàn bộ public controllers có thể làm hỏng FE, seed script, webhook và WebSocket nếu chỉ sửa một phía.
- Nginx không tự cấp certificate như Caddy; bootstrap và renew certificate phải được kiểm thử riêng.
- Các URL presigned của MinIO và header Upgrade của WebSocket phải được proxy nguyên vẹn.
