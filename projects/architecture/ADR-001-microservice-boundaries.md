# ADR-001: Microservice Architecture — Service Boundaries & Data Ownership

**Date:** 2026-07-24
**Status:** Accepted
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

## Services (9)

| Service | Bounded context | Sở hữu (write) | Ghi chú |
|---|---|---|---|
| **iam** | Identity | User, Credential, Session, JWT signing keys, **tenant registry** | Cấp/rotate JWT (asymmetric RS256/EdDSA). Nhét `tenantId` + status vào JWT claim → data plane đọc từ token, không call sống |
| **admin** (control plane) | Platform governance | Subscription, platform config, feature flags, kill-switch, tenant lifecycle (onboard/suspend) | Low-traffic, đặc quyền cao. **Không** own tenant identity runtime (đó là iam). Không ai phụ thuộc runtime |
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

Khác biệt admin-tạo-đề vs host-tạo-đề = **khác scope dữ liệu, không khác capability** → cùng service `authoring`, RLS phân quyền: host đọc global read-only, chỉ `PLATFORM_AUTHOR` ghi global.

---

## Consequences

**Được:** blast radius cắt theo capability; scale độc lập (exam-delivery theo attempt đồng thời, proctor theo WS connection, scoring theo queue depth — 3 profile khác nhau); control plane sập không kéo critical path.

**Trả giá (chấp nhận có chủ đích):** eventual consistency giữa service; exam-delivery giữ snapshot copy denormalized (trùng lặp dữ liệu đổi lấy tự chủ); vận hành phân tán đầy đủ (gateway, event backbone, observability, saga) — xem ADR-002, ADR-003.

**Deciding factor còn mở:** tenant registry ở iam (đã chốt) vs admin — chọn iam vì chỉ auth cần nó runtime để nhét claim; admin chỉ quản lý lifecycle.
