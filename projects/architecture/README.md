# Architecture Decision Records — PTE Platform

Kiến trúc nền tảng mô phỏng thi PTE Academic. Chốt 2026-07-24, thu gọn về monolith 2026-09-15, **toàn bộ ADR viết lại theo hiện trạng 2026-09-16**.

**Kiến trúc hiện tại:** một Spring Modulith monolith — 1 Maven module (`app`), 12 module nghiệp vụ dưới `com.pte.*`, 1 Postgres (schema quản bằng Flyway), không gateway. Hạ tầng: Redis, RabbitMQ, Cloudinary, Jaeger, Caddy.

## Nền tảng kiến trúc

- [ADR-001](ADR-001-module-boundaries.md) — **Module boundaries & data ownership**: 12 module cắt theo capability, 5 bất biến, cách ranh giới được ép (quy ước package, chưa có test xác minh)
- [ADR-002](ADR-002-communication-and-scoring-lifecycle.md) — **Giao tiếp & vòng đời chấm điểm**: gọi in-process qua facade; RabbitMQ chỉ còn vai work-queue; chấm điểm **host-gated** với cổng publish
- [ADR-003](ADR-003-tenant-isolation-and-infrastructure.md) — **Tenant isolation & hạ tầng**: 3 lớp cô lập, stack đang chạy thật, và danh sách thẳng thắn những gì chưa có (RLS, metrics, statement timeout)
- [ADR-004](ADR-004-per-module-code-structure.md) — **Cấu trúc code từng module**: layout chuẩn, quy ước, inventory entity/controller/service của cả 12 module
- [ADR-005](ADR-005-deployment-topology.md) — **Deployment topology**: một host, Caddy edge, danh sách SPOF, điều kiện để xét tách lại
- [ADR-008](ADR-008-modulith-reconciliation.md) — **Quyết định thu gọn về monolith**: ánh xạ service cũ → module mới, cái giá đã trả, nợ kỹ thuật

## Nghiệp vụ

- [ADR-006](ADR-006-commercialization-and-exam-templates.md) — **Thương mại hoá tenant (bán sỉ cho tổ chức)**: bounded context `billing`, đăng ký → thẩm định → mua gói qua PayOS **hoặc** redeem mã, Subscription là license instance có `licenseKey`, đề sinh từ template thay vì soạn tay, kho đề chỉ còn SHARED
- [ADR-007](ADR-007-student-identity-and-login.md) — **Định danh sinh viên & đăng nhập**: `username` sinh có tiền tố `Tenant.code`, import roster là passthrough (không diễn giải cột, xuất lại file + `account`/`password`), email không còn là khoá với `STUDENT`

## Trạng thái (2026-09-16)

| | |
|---|---|
| **Đánh đổi lớn nhất** | Lý do gốc để chọn microservice — cô lập tài nguyên vật lý cho đường thi — **đã mất**. Một tiến trình, một pool, một DB. Xem [ADR-008](ADR-008-modulith-reconciliation.md) |
| **Lỗ hổng thật** | **RLS chưa có** (cô lập tenant hoàn toàn ở tầng app) · không có metrics/log aggregation · chưa có statement timeout · bulk import chạy đồng bộ · 1 replica là SPOF toàn hệ · ranh giới module chưa có test xác minh |
| **Món rẻ nhất nên làm trước** | `ApplicationModules.verify()` — biến ranh giới module từ quy ước thành ràng buộc |
| **Cần chốt** | ADR-006 và ADR-007 đều **0 câu hỏi treo**. Việc tiếp theo là plan triển khai — ADR-007 phải làm cùng ADR-006 vì `Tenant.code` cần có từ lúc duyệt đơn |

## Ba trụ cột quyết định

1. **Vì sao monolith:** chi phí vận hành cho đội 4 người, đổi lấy việc mất cô lập tài nguyên vật lý — đánh đổi có ý thức, không phải sơ suất.
2. **Bất biến kỹ thuật:** snapshot bất biến pin lúc tạo attempt · `attempt` không gọi ra ngoài giữa lúc thi · control plane ngoài critical path · module = capability, actor = RBAC + scope · ownership dữ liệu ép bằng ranh giới package `internal/`.
3. **Bất biến thương mại:** nền tảng bán sỉ cho tổ chức — sinh viên không bao giờ là bên thanh toán.
