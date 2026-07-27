# Architecture Decision Records — PTE Platform

Kiến trúc microservice cho nền tảng mô phỏng thi PTE Academic. Chốt 2026-07-24.

- [ADR-001](ADR-001-microservice-boundaries.md) — Service boundaries & data ownership (9 service, cắt theo capability không theo actor)
- [ADR-002](ADR-002-communication-and-exam-submission-saga.md) — Communication (async-first) & exam-submission saga (outbox, Kafka vs RabbitMQ)
- [ADR-003](ADR-003-tenant-isolation-and-infrastructure.md) — Tenant isolation (3 lớp) & infrastructure stack (Redis/Kafka/Vault/Keycloak/…)
- [ADR-004](ADR-004-per-service-code-structure.md) — Cấu trúc code từng service (mono-repo, layered per-service, DB-per-service, entity/endpoint/event mỗi service)

Chuẩn code: [docs/CODING_STANDARDS_MICROSERVICE.md](../../../docs/CODING_STANDARDS_MICROSERVICE.md) — layered per-service + luật phân tán, kế thừa code-quality từ CODING_STANDARDS_API.md.

## Ba trụ cột quyết định

1. **Lý do chọn microservice:** cô lập tài nguyên vật lý cho critical path (exam-delivery), không phải team scaling.
2. **Nguyên tắc bất biến:** dependency chỉ đi VÀO exam-delivery qua event; snapshot immutable pin lúc tạo attempt; data ownership tuyệt đối; control plane ngoài critical path; service = capability, actor = RBAC + scope.
3. **Đến chốn ≠ nhiều nhất:** triển khai hạ tầng theo lớp, mỗi thứ một lý do không thể thay thế.
