# ADR-008: Thu gọn 10 microservice về Spring Modulith monolith

**Date:** 2026-09-16
**Status:** Accepted
**Context:** `pte-api` khởi đầu là 10 microservice ([ADR-001](ADR-001-module-boundaries.md) bản 2026-07-24). Tháng 9/2026 toàn bộ được collapse về một Spring Boot app (commit `1d103c2`, `eb1a38d`). ADR này ghi **quyết định thu gọn** và cái giá của nó. ADR-001..005 đã viết lại theo kiến trúc mới; file này là nơi giải thích *vì sao đổi*.

---

## Decision

Gộp 10 service thành một ứng dụng, mỗi bounded context thành một `@ApplicationModule` của Spring Modulith. Gỡ bỏ API gateway, `pte-common`, 4 cell Postgres, outbox relay và event backbone.

---

## Ánh xạ service cũ → module mới

| Cũ | Mới | Ghi chú |
|---|---|---|
| `iam` | `identity` | |
| `admin` | `tenancy` + `enrollment` | **Tách đôi** — đúng theo câu hỏi mở mà ADR-001 bản gốc để lại về việc `admin` phình phạm vi |
| `authoring` | `itembank` + `assessment` | **Tách đôi** — ngân hàng câu hỏi tách khỏi việc soạn/đóng băng đề |
| `scheduling` | `session` | |
| `exam-delivery` | `attempt` | |
| `proctor` | `proctoring` | |
| `scoring`, `reporting`, `notification`, `media` | giữ tên | |
| `gateway` | — | Gỡ. JWT + rate limit chuyển vào app |
| `pte-common` | `com.pte.shared` | |

Việc thu gọn **giải luôn** hai câu hỏi mở của kiến trúc cũ: phạm vi `admin` phình ra, và ranh giới giữa nội dung với việc soạn đề.

---

## Cái giá: lý do chọn microservice đã không còn

ADR-001 bản gốc nêu **một** lý do chính đáng để chọn microservice:

> *Cô lập tài nguyên vật lý (CPU / connection pool / process) cho đường đi của student, tách khỏi mọi subsystem có khả năng tạo tải bất thường.* Và nói rõ: modular monolith dù sạch đến đâu vẫn dùng chung 1 process / 1 connection pool — một query bulk-import chậm vẫn ăn vào tài nguyên request nộp bài của student.

Một tiến trình, một pool, một Postgres → **lý do đó mất hoàn toàn.** Đúng kịch bản mà kiến trúc cũ dựng lên để tránh nay đã mở: bulk import roster chạy đồng bộ ([ADR-003](ADR-003-tenant-isolation-and-infrastructure.md) lớp 2) ăn thẳng vào tài nguyên phục vụ sinh viên đang thi.

Đây là đánh đổi có ý thức — chi phí vận hành phân tán không tương xứng với một đồ án 4 người — chứ không phải sơ suất. Nhưng phải ghi ra: nếu sau này có sự cố kiểu *"thi bị chậm lúc trung tâm đang import"*, nguyên nhân gốc đã nằm sẵn đây, không cần đi tìm.

---

## Năm bất biến: cái nào còn, cái nào đổi hình thức

| # | Bất biến gốc | Trạng thái |
|---|---|---|
| 1 | Dependency chỉ đi VÀO exam-delivery qua event | **Đổi hình thức.** Nay là lời gọi in-process qua facade, không qua event. Tinh thần giữ được — `attempt` chỉ gọi ra ngoài trong `SnapshotPinService`, tức lúc tạo attempt — nhưng cơ chế bảo vệ không còn là ranh giới mạng |
| 2 | Snapshot bất biến pin lúc tạo attempt | **Giữ nguyên** |
| 3 | Ownership dữ liệu tuyệt đối — 1 service 1 DB | **Mất hình thức, giữ tinh thần.** Một DB, không credential riêng. Ownership nay ép bằng quy ước package `internal/` — tức bằng kỷ luật code review, không bằng cơ chế nào |
| 4 | Control plane ngoài critical path | **Giữ được** ở mức thiết kế |
| 5 | Module = capability, actor = RBAC + scope | **Giữ nguyên** |

---

## Những gì biến mất cùng với microservice

| Thứ | Vì sao mất | Thay bằng |
|---|---|---|
| Transactional Outbox + relay | Dual-write bug không tồn tại trong một transaction | Không cần gì |
| `ProcessedEvent` dedup | Không còn at-least-once giữa các module | Còn dedup ở worker chấm AI |
| Circuit breaker (Resilience4j) | Không còn lời gọi mạng nội bộ | `spring-retry` cho lời gọi AI vendor |
| Event backbone | — | RabbitMQ còn lại đúng vai work-queue |
| 4 cell Postgres | — | Một Postgres |
| Spring Cloud Gateway | Một upstream thì không có gì để định tuyến | `oauth2-resource-server` + `RateLimitFilter` trong app |

**Mất mà chưa có gì thay:** load-leveling cho write spike. RabbitMQ từng đứng giữa hấp thụ bulk import và nộp bài hàng loạt; nay cả hai ghi thẳng vào Postgres.

---

## Nợ kỹ thuật hiện tại

Kế thừa, **chưa cái nào được giải**:

- **RLS chưa có** — cô lập tenant hoàn toàn ở tầng application. [ADR-006](ADR-006-commercialization-and-exam-templates.md)/[ADR-007](ADR-007-student-identity-and-login.md) thêm `subscription_id`, `license_key`, `tenant.code` → số cột tenant-scoped chỉ tăng, chi phí bổ sung RLS sau này càng lớn. **Ưu tiên số một.**
- **Không có metrics/log aggregation** — chỉ tracing qua Jaeger. Không đo được thì không biết có cần tách lại hay không.
- **Chưa có statement timeout.**
- **Bulk import chạy đồng bộ.**

Phát sinh do thu gọn:

- **Một replica là SPOF toàn hệ thống**, không còn là SPOF của một service.
- **Ranh giới module không có gì ép ngoài quy ước.** Spring Modulith có `ApplicationModules.verify()` — **chưa có** trong repo. Đây là món rẻ nhất trong danh sách này và nên làm trước.
