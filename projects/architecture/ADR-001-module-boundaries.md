# ADR-001: Module Boundaries & Data Ownership

**Date:** 2026-07-24 · **Viết lại 2026-09-16** theo kiến trúc Spring Modulith
**Status:** Accepted
**Context:** Nền tảng mô phỏng thi PTE Academic (`pte-api`, `pte-app`, `pte-web`). Đội 4 người + AI-assisted. Multi-tenant: nhiều trung tâm trả phí, admin nền tảng, giám thị, sinh viên. Desktop + web client.

> **Lịch sử:** ADR này ban đầu chốt kiến trúc **10 microservice** (2026-07-24). Tháng 9/2026 hệ thống thu gọn về **một Spring Modulith monolith** (commit `1d103c2`, `eb1a38d`). Lý do và cái giá của việc thu gọn ghi ở [ADR-008](ADR-008-modulith-reconciliation.md). File này đã viết lại theo kiến trúc hiện tại.

---

## Decision

Một ứng dụng Spring Boot duy nhất, cắt thành **module theo capability (bounded context)**, **không theo actor**. Mỗi module là một `@ApplicationModule` của Spring Modulith.

Cắt theo capability chứ không theo actor là quyết định còn nguyên giá trị sau khi thu gọn: nếu cắt theo actor thì "host tạo đề" và "admin tạo đề" thành hai module, trong khi chúng là **cùng một năng lực, khác phạm vi dữ liệu**.

---

## Nguyên tắc cứng (bất biến)

1. **`attempt` không gọi ra ngoài trong lúc sinh viên đang thi.** Mọi thứ cần thiết đã pin vào snapshot lúc tạo attempt.
2. **Snapshot bất biến, pin tại thời điểm tạo attempt.** Module khác đổi dữ liệu sau đó → bài thi đang chạy không bị ảnh hưởng.
3. **Ownership dữ liệu tuyệt đối.** Mỗi bảng thuộc đúng một module. Không module nào query bảng của module khác — chỉ qua facade công khai.
4. **Control plane không nằm trên critical path.** `tenancy`, `billing` sập/khoá không được chặn sinh viên đang thi.
5. **Module = capability. Actor = ai được gọi, ở phạm vi nào.** Ánh xạ actor→module là nhiều-nhiều, giải bằng **RBAC + scope ở tầng dữ liệu**, không bao giờ bằng cách sinh thêm module.

---

## 12 module

| Module | Bounded context | Sở hữu (write) |
|---|---|---|
| **identity** | Danh tính, xác thực | `User`, `RefreshToken`, `LoginHash`, khoá ký JWT |
| **tenancy** | Quản trị tổ chức | `Tenant`, `Organization`, `QuotaTransaction` |
| **enrollment** | Cơ cấu học thuật | `Program`, `StudentClass`, `ClassMembership`, `LecturerAssignment`, `ProgramCoordinatorAssignment` |
| **itembank** | Ngân hàng câu hỏi | `Question`, `QuestionOption` |
| **assessment** | Soạn & đóng băng đề | `ExamBlueprint`, `BlueprintItem`, `ExamSnapshot`, `SnapshotItem` |
| **session** | Kỳ thi & ghi danh | `ExamSession`, `Enrollment`, `SessionComposition`, `ProctorAssignment`, `ExamPolicy` |
| **attempt** | Làm bài (critical path) | `ExamAttempt`, `AttemptAnswer`, timer state, snapshot đã pin |
| **proctoring** | Giám thị | `ProctorSession`, `ViolationEvent`, audit log hash-chain |
| **scoring** | Chấm điểm | `ScoringAnswer`, kết quả AI vendor |
| **reporting** | Read model | Báo cáo attempt, tổng hợp điểm |
| **notification** | Gửi thông báo | Log thông báo, trạng thái gửi |
| **media** | Lưu trữ nhị phân | Audio upload, ảnh, presigned URL |

Thêm `shared` — hạ tầng dùng chung (`BaseEntity`, security context, web filter, audit). Không phải bounded context.

**Quy ước tên:** một khái niệm domain, danh từ hoặc năng lực, một từ, không hậu tố `-service`/`-api`.

---

## Ranh giới được ép thế nào

Không còn ranh giới mạng hay credential DB riêng. Ranh giới nay là **quy ước package** — và đó là điểm yếu phải biết:

```
com.pte.<module>/
├── <Module>Service.java      ← facade: cửa DUY NHẤT module khác được gọi
├── domain/                   ← entity + enum, công khai
├── dto/                      ← DTO công khai cho lời gọi xuyên module
├── internal/                 ← controller, service, repository, mapper — RIÊNG
└── package-info.java         ← @ApplicationModule
```

Ví dụ: `SessionService` phơi ra `checkEntitlement`, `checkProctorAssignment`, `verifyHostAccess` — đúng ba thứ module khác cần. `SessionLifecycleService`, repository, controller đều nằm trong `internal/`.

**Cảnh báo:** một `@Autowired` vào lớp trong `internal/` của module khác vẫn **biên dịch được**. Spring Modulith có test xác minh cấu trúc (`ApplicationModules.verify()`) — hiện **chưa có** trong repo. Cho tới khi có, bất biến #3 được giữ bằng kỷ luật code review, không bằng cơ chế nào.

---

## Actor → module (nhiều-nhiều, qua RBAC)

| Actor | Chạm module nào |
|---|---|
| **student** | `attempt` (chính), `media` (upload), `identity` |
| **host** | `assessment`, `session`, `enrollment`, `reporting`, `proctoring`, `tenancy` (đọc gói) |
| **admin nền tảng** | `itembank` (phạm vi global), `tenancy`, `billing`, `reporting` (mọi tenant), `identity` |
| **proctor** | `proctoring`, `attempt` (command) |

Khác biệt admin-tạo-đề và host-tạo-đề là **khác phạm vi dữ liệu, không khác năng lực** → cùng module `itembank`, phân quyền theo scope.

> **Cập nhật theo [ADR-006](ADR-006-commercialization-and-exam-templates.md):** kho đề chuyển sang **chỉ còn SHARED** — host không tạo câu hỏi nữa; và `billing` thêm vào làm bounded context thứ 13.

**Cơ chế ép scope là tầng application** (cột `tenantId` + điều kiện trong repository), **không phải Postgres RLS**. RLS vẫn là mục tiêu, chưa triển khai.

---

## Consequences

**Được:** ranh giới khái niệm rõ ràng. Một `docker compose up` là chạy được cả hệ. Không có network hop giữa các module → không cần circuit breaker, không cần retry, không có partial failure giữa hai bước nghiệp vụ. Lời gọi xuyên module là lời gọi hàm, nằm trong cùng một transaction nếu muốn.

**Trả giá:**
- **Không còn cô lập tài nguyên vật lý.** Một tiến trình, một connection pool. Bulk import chậm ăn thẳng vào tài nguyên phục vụ sinh viên đang nộp bài. Đây là cái giá lớn nhất của việc thu gọn — xem [ADR-008](ADR-008-modulith-reconciliation.md).
- **Ownership dữ liệu không có gì cưỡng chế.** Một JOIN xuyên module viết được và chạy được.
- **Triển khai là all-or-nothing.** Sửa một dòng trong `notification` cũng phải deploy lại cả ứng dụng, kể cả phần đang phục vụ thi.
