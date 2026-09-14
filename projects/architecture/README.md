# Architecture Decision Records — PTE Platform

Kiến trúc microservice cho nền tảng mô phỏng thi PTE Academic. Chốt 2026-07-24, **đối chiếu as-built 2026-09-14**.

- [ADR-001](ADR-001-microservice-boundaries.md) — Service boundaries & data ownership (10 service, cắt theo capability không theo actor) · *reconciliation: cell DB topology, drift phạm vi `admin`*
- [ADR-002](ADR-002-communication-and-exam-submission-saga.md) — Communication (async-first) & exam-submission saga (outbox pattern; event backbone superseded-in-part 2026-07-31 — RabbitMQ polling-outbox-relay, was Kafka+Debezium) · *ADR chính xác nhất trong bộ*
- [ADR-003](ADR-003-tenant-isolation-and-infrastructure.md) — Tenant isolation (3 lớp) & infrastructure stack · ⚠️ *lệch nhiều nhất so với as-built — đọc mục reconciliation trước*
- [ADR-004](ADR-004-per-service-code-structure.md) — Cấu trúc code từng service (mono-repo, layered per-service, DB-per-service, entity/endpoint/event mỗi service) · *đã viết lại theo code thực tế*
- [ADR-005](ADR-005-deployment-topology.md) — Deployment topology: single-host, 4 cell Postgres, edge Caddy + gateway, danh sách SPOF, điều kiện để tách nhiều host

## Trạng thái đối chiếu (2026-09-14)

| | |
|---|---|
| **Giữ được** | 5/5 bất biến ADR-001. exam-delivery không call gì trong lúc thi (3 sync client bị giới hạn trong `SnapshotPinService`). Outbox + saga host-gated đúng thiết kế. Circuit breaker có thật trên 6/8 sync client. Hash-chain audit ở proctor có thật. |
| **Lệch có lý do** | Cell Postgres thay 10 instance · Spring Cloud Gateway thay Kong/APISIX · `ProcessedEvent` (Postgres) thay Redis dedup · warm-on-pin thay job pre-warm · cell connection budget thay PgBouncer · internal key thay Linkerd mTLS · iam tự làm auth server thay Keycloak. |
| **Lỗ hổng thật** | **RLS chưa có** (tenant isolation lớp 1 đang hoàn toàn ở tầng app) · **không có metrics/log aggregation** (chỉ tracing) · bulk create user của iam chạy đồng bộ trên `pg-core` · chưa có statement timeout · mỗi service 1 replica. |
| **Cần chốt** | Phạm vi `admin` đã phình thành org/program/class — giữ hay tách bounded context riêng? Chốt trước khi có consumer runtime bám vào 25 event của nó. |

Chuẩn code: [docs/CODING_STANDARDS_MICROSERVICE.md](../../../docs/CODING_STANDARDS_MICROSERVICE.md) — layered per-service + luật phân tán, kế thừa code-quality từ CODING_STANDARDS_API.md.

## Ba trụ cột quyết định

1. **Lý do chọn microservice:** cô lập tài nguyên vật lý cho critical path (exam-delivery), không phải team scaling.
2. **Nguyên tắc bất biến:** dependency chỉ đi VÀO exam-delivery qua event; snapshot immutable pin lúc tạo attempt; data ownership tuyệt đối; control plane ngoài critical path; service = capability, actor = RBAC + scope.
3. **Đến chốn ≠ nhiều nhất:** triển khai hạ tầng theo lớp, mỗi thứ một lý do không thể thay thế.
