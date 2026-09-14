# ADR-001: Microservice Architecture — Service Boundaries & Data Ownership

**Date:** 2026-07-24
**Status:** Accepted — đối chiếu as-built 2026-09-14 (xem mục "As-built reconciliation" cuối file)
**Context:** PTE Academic exam-simulation platform (`pte-api`, `pte-app`, `pte-web`). Team of 4 + AI-assisted. Multi-tenant SaaS: nhiều host (tổ chức trả phí), admin (control plane số lượng ít), giám thị, student. Desktop + web clients.

---

## Decision

Chuyển từ modular monolith sang **microservice**, cắt theo **capability (bounded context)**, **không theo actor**.

### Lý do chính đáng để chọn microservice (không phải "team lớn" hay "dễ maintain")

**Cô lập tài nguyên vật lý (CPU / connection pool / process) cho đường đi của student, tách khỏi mọi subsystem có khả năng tạo tải bất thường** (bulk-import của host, WebSocket proctor, gọi AI vendor chậm). Modular monolith dù sạch đến đâu vẫn dùng chung 1 process / 1 connection pool / 1 thread pool — một query bulk-import chậm hoặc WS leak connection vẫn ăn vào tài nguyên request nộp bài của student. Chỉ tách deployable mới cắt được blast radius này.

Team 4 người + AI-assist làm **yếu** lý do Conway's Law; lý do đứng vững duy nhất là **availability/blast-radius cho critical path (exam-delivery)**.

---

## Nguyên tắc cứng (bất biến, quan trọng hơn số lượng service)

1. **Hướng phụ thuộc runtime chỉ đi VÀO exam-delivery qua event, không bao giờ đi RA.** exam-delivery publish event; không gọi sync sang service khác giữa lúc student đang thi.
2. **exam-delivery tự chủ tuyệt đối lúc thi:** exam config/question set được **pin snapshot (versioned, immutable)** tại thời điểm tạo attempt. Authoring/admin/scoring sập sau đó → student vẫn hoàn thành bài.
3. **Data ownership tuyệt đối:** mỗi service 1 DB (schema + credential riêng). Không service nào query chéo DB service khác — chỉ qua API hoặc event.
4. **Control plane không bao giờ nằm trên critical runtime path.** Admin sập không được ảnh hưởng data plane.
5. **Service = capability. Actor = ai được phép gọi, ở scope nào.** Ánh xạ actor→service là nhiều-nhiều, giải bằng **RBAC ở gateway + scope ở data layer**, không bao giờ bằng cách sinh thêm service.

---

## Services (10)

| Service | Bounded context | Sở hữu (write) | Ghi chú |
|---|---|---|---|
| **iam** | Identity | User, Credential, Session, JWT signing keys, **tenant registry** | Cấp/rotate JWT (asymmetric RS256/EdDSA). Nhét `tenantId` + status vào JWT claim → data plane đọc từ token, không call sống |
| **admin** (control plane) | Platform governance **+ academic org structure** (mở rộng 2026-08/09, xem reconciliation) | Tenant lifecycle, Organization, Program, StudentClass, ClassMembership, Lecturer/Coordinator assignment, QuotaTransaction, AuditLog | Low-traffic, đặc quyền cao. **Không** own tenant identity runtime (đó là iam). Không ai phụ thuộc runtime sync |
| **authoring** | Content (data plane) | Question, Exam blueprint, media refs | Host **và** admin cùng dùng, phân biệt bằng RBAC + scope (`tenant_id` NULL = global do admin tạo, host read-only). Publish immutable versioned snapshot. Per-tenant quota |
| **scheduling** | Exam session orchestration | ExamSession, Enrollment, session config, cửa sổ thời gian | Cầu nối: đọc snapshot từ authoring → tạo entitlement mà exam-delivery kiểm khi student vào. Vòng đời khác authoring (nội dung bất biến vs. sự kiện thi có thời gian) |
| **exam-delivery** | Delivery (critical path) | ExamAttempt, AttemptAnswer, TimerState, pinned ExamSnapshot | State machine làm bài. Zero outbound sync call lúc thi. Service cần bảo vệ nhất — resource pool riêng |
| **proctor** | Supervision | ProctorSession, ViolationEvent, tamper-evident audit log | WebSocket real-time. Gửi command tới delivery qua event, không share DB |
| **scoring** | Assessment | ScoringJob, SkillScore, AI vendor results | Consume submitted-answer events, gọi AI vendor async, retry/DLQ. Idempotent theo answerId |
| **reporting** | Analytics (read model) | Denormalized attempt reports, score aggregates | CQRS read-side, build từ event stream. Không own source-of-truth. Đọc từ read replica |
| **notification** | Outbound messaging | Notification log, delivery status | Fan-out consumer: `ViolationDetected`, `AttemptScored`, `ImportCompleted` → email/push/WS. Tách vì vendor + retry độc lập |
| **media** | Binary storage | Audio uploads, images, presigned URLs | Student audio + host media. Upload/presign/validate/transcode. Tách vì I/O profile khác |

**Naming convention:** một khái niệm domain, danh từ hoặc năng lực, kebab-case, không dấu `/`, không hậu tố `-service`/`-api`.

---

## Actor → Service (nhiều-nhiều, qua RBAC)

| Actor | Chạm service nào |
|---|---|
| **student** | exam-delivery (chính), media (upload), iam |
| **host** | authoring (scope tenant), scheduling, reporting (scope tenant), proctor (quản giám thị), admin (đọc gói dịch vụ) |
| **admin** | authoring (scope global), admin, reporting (mọi tenant), iam — vượt tenant, quyền `PLATFORM_*` |
| **proctor** | proctor, exam-delivery (command qua event) |

Khác biệt admin-tạo-đề vs host-tạo-đề = **khác scope dữ liệu, không khác capability** → cùng service `authoring`, phân quyền theo scope: host đọc global read-only, chỉ `PLATFORM_AUTHOR` ghi global.

> **As-built 2026-09-14:** cơ chế ép scope hiện là **tầng application** (cột `tenantId` + điều kiện trong repository/service), **không phải Postgres RLS**. RLS vẫn là mục tiêu, chưa triển khai — xem reconciliation.

---

## Consequences

**Được:** blast radius cắt theo capability; scale độc lập (exam-delivery theo attempt đồng thời, proctor theo WS connection, scoring theo queue depth — 3 profile khác nhau); control plane sập không kéo critical path.

**Trả giá (chấp nhận có chủ đích):** eventual consistency giữa service; exam-delivery giữ snapshot copy denormalized (trùng lặp dữ liệu đổi lấy tự chủ); vận hành phân tán đầy đủ (gateway, event backbone, observability, saga) — xem ADR-002, ADR-003.

**Deciding factor còn mở:** tenant registry ở iam (đã chốt) vs admin — chọn iam vì chỉ auth cần nó runtime để nhét claim; admin chỉ quản lý lifecycle.

---

## As-built reconciliation — 2026-09-14

Đối chiếu ADR gốc (2026-07-24) với `pte-api` thực tế. Mục này ghi **hiện trạng**, không đổi quyết định; chỗ nào cần quyết định lại thì ghi rõ là câu hỏi mở.

### Bất biến — trạng thái thực tế

| # | Bất biến | As-built | Bằng chứng |
|---|---|---|---|
| 1 | Dependency runtime chỉ đi VÀO exam-delivery | **GIỮ ĐƯỢC.** exam-delivery có 3 sync client (`AuthoringClient`, `SchedulingClient`, `MediaClient`) nhưng **cả ba chỉ được inject vào `SnapshotPinService`** — tức chỉ chạy lúc tạo attempt, không chạy trong lúc thi. Đúng như ADR-002 cho phép. | `services/exam-delivery/.../service/SnapshotPinService.java` |
| 2 | exam-delivery tự chủ lúc thi (snapshot pin immutable) | **GIỮ ĐƯỢC.** `PinnedExamSnapshot` + `PinnedItem` là bản copy denormalized; `PinnedSnapshotCacheService` warm Redis ngay sau khi pin (TTL 24h, có single-flight lock). | `service/cache/PinnedSnapshotCacheService.java` |
| 3 | Data ownership tuyệt đối — 1 service 1 DB + credential riêng | **GIỮ ĐƯỢC về ownership**, khác về topology: mỗi service có DB + user + password riêng, nhưng 10 DB được **gom vào 4 Postgres instance ("cell")**, không phải 10 instance. Xem mục Cell bên dưới. | `docker-compose.yml`, `docker/postgres/init-*/01-create-databases.sql` |
| 4 | Control plane ngoài critical runtime path | **GIỮ ĐƯỢC.** Không service nào có `AdminClient`; admin chỉ giao tiếp ra ngoài bằng event (iam consume `Tenant*`). | sweep `services/*/client/` |
| 5 | Service = capability, actor = RBAC + scope | **GIỮ ĐƯỢC ở tầng service**, nhưng cơ chế ép scope là app-layer chứ không phải RLS (xem trên). | không có `CREATE POLICY` nào trong repo |

### Cell-based DB topology (quyết định chưa từng được ghi ADR)

10 database, 4 Postgres instance, gom theo **failure/tải profile** chứ không theo service:

| Cell | DB | `max_connections` | Lý do gom |
|---|---|---|---|
| `pg-core` | iam, admin, authoring, scheduling, reporting, notification, media | 120 | 7 service low-to-medium traffic, downtime chịu được |
| `pg-exam` | exam_delivery | 100 | Critical path — connection starvation ở đây là không cứu được với student đang thi |
| `pg-live` | proctor | 50 | Profile WebSocket long-lived |
| `pg-async` | scoring | 50 | Tải burst theo queue depth, gọi AI vendor |

Đây là **cell isolation**, không phải database-per-service thuần. Đánh đổi có chủ đích: giữ được nguyên tắc ownership (DB + credential riêng, không query chéo, tách ra instance riêng sau này không phải sửa code — chỉ đổi `*_DB_URL`), đổi lấy chi phí vận hành 4 container thay vì 10.

**Hệ quả phải nhớ:** trong `pg-core`, 7 service vẫn **dùng chung một budget connection và một tiến trình Postgres**. Blast radius ở tầng service đã cắt, ở tầng `pg-core` thì chưa. exam-delivery được bảo vệ vì nó ở cell riêng — đó chính là điểm của cách gom này.

### Drift chưa có quyết định: `admin` phình phạm vi

ADR gốc định nghĩa admin = "platform governance" (Subscription, PlatformConfig, FeatureFlag, KillSwitch). **Không entity nào trong số đó tồn tại.** Thay vào đó admin as-built own **cấu trúc tổ chức học thuật**:

`Organization`, `Program`, `StudentClass`, `ClassMembership`, `LecturerAssignment`, `ProgramCoordinatorAssignment`, `QuotaTransaction`, `AuditLog`, `Tenant` — 9 controller, 25 loại event.

Hai quan sát, chưa phải kết luận:

1. **Chưa vi phạm bất biến #4.** 25 event của admin, các event `Class*`/`Program*`/`Organization*`/`*Assigned` hiện **không có consumer nào**. Chỉ `Tenant*` được iam consume. Runtime path không đụng admin.
2. **Nhưng "control plane" không còn mô tả đúng service này.** Org/Program/Class là dữ liệu data-plane có vòng đời riêng, và nó chồng lấn khái niệm với `scheduling.Enrollment` (student vào session) — hiện hai mô hình student-grouping tồn tại song song ở hai service, không nối với nhau.

**Câu hỏi mở cần chốt:** giữ nguyên (admin = governance + org structure, chấp nhận tên gọi lệch), hay tách `Organization/Program/Class/Membership` thành bounded context riêng (ví dụ `org` hoặc `enrolment`) và trả admin về đúng vai control plane? Chốt trước khi có consumer runtime nào bám vào các event này — sau đó tách sẽ đắt.

### Sai sót tài liệu đã sửa

- Tiêu đề "Services (9)" → **10** (bảng luôn liệt kê 10 dòng; `pte-api/pom.xml` có 10 service module + `gateway` + `pte-common`).
- Bỏ chữ "RLS" ở mục actor→service vì RLS chưa tồn tại trong code.
