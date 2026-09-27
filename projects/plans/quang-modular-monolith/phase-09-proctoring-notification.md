# Phase 09 — Proctoring + Notification

**Plan:** [plan.md](plan.md) · [kế hoạch tổng hợp](remaining-modules-refactor-plan.md) · **Spec:** [spec.md](spec.md)
**Covers:** Live proctoring, violation audit, email notification
**Nguồn:** `services/proctor` (44 file) + `services/notification` (29 file)
**Đích:** `com.pte.proctoring`, `com.pte.notification`

---

## Mục tiêu

Port hai capability có runtime khác nhau trong cùng phase:

- Proctoring giữ WebSocket/STOMP, assignment check, force-submit và tamper-evident
  violation chain.
- Notification giữ notification log và SMTP worker bất đồng bộ.

Không mang theo user directory hoặc event synchronization; user/email được resolve
qua public Identity API tại thời điểm dispatch.

---

## Design Constraints

### Proctoring

- Dependency `proctoring → session`, `proctoring → attempt`, `shared`.
- `SchedulingClient` đổi thành `SessionService.checkProctorAssignment`.
- Force-submit gọi public `AttemptService.forceSubmit(attemptPublicId, tenantId)`;
  không mở `ExamAttemptRepository` và không tạo vòng import.
- Giữ STOMP role guard, session open idempotency, tenant check, sequence/hash chain,
  lock chain head và broadcast topic.
- Violation chỉ phát application event sau khi domain transaction thành công.
- Không port outbox, `ProcessedEvent`, `ProctorCommandConsumer` hoặc event relay.

### Notification

- Dependency `notification → identity`; nhận application event từ session,
  attempt, proctoring và reporting.
- Bỏ `UserDirectoryEntry`, repository, consumer và mọi bản sao user.
- Email/role lookup dùng public `IdentityService`; nếu cần list HOST_ADMIN, bổ sung
  read method rõ phạm vi vào Identity, không đọc `UserRepository`.
- Notification log luôn có tenant, recipient user và email tại thời điểm dispatch.
- Rabbit chỉ dùng cho EmailJob; worker giữ retry/backoff/DLQ và terminal no-op.
- Missing recipient phải có policy rõ ràng, không silently tạo directory row.

---

## Việc cần làm

### 1. Port Proctoring

- Port `ProctorSession`, `ViolationEvent`, enum, hash chain service, mapper,
  WebSocket config/interceptor và controller/STOMP contract.
- Port open/close session, flag violation, list audit và issue command.
- Khi open, kiểm tra assignment + tenant qua Session public API.
- Khi issue force-submit, gọi Attempt public command; stale/missing/inactive attempt
  giữ no-op semantics của source.
- Giữ hash input canonical, previous hash, sequence number và concurrent head update.

### 2. Port Notification

- Port `NotificationLog`, status, type, dispatch service, log controller,
  EmailJob, SMTP worker và DLQ.
- Port event handlers dạng application listener cho enrollment, report publish và
  violation; không port AMQP event backbone.
- Resolve student email hoặc host-admin list qua `IdentityService` rồi ghi log và
  enqueue EmailJob.
- Không gửi email inline trên request/domain transaction; Rabbit worker mới gọi SMTP.

### 3. Flyway

- Viết `V11__proctoring.sql` cho proctor session/violation và hash-chain fields.
- Viết `V12__notification.sql` cho notification log.
- Không tạo user directory, outbox hoặc processed event table.

### 4. Contract và cấu hình

- Giữ path HTTP, STOMP destination, response/error shape và role behavior.
- Kiểm tra WebSocket app/gateway route, SMTP/Mailpit config và Rabbit queue names.
- Cập nhật `IdentityService` tối thiểu, có test cho lookup theo tenant/role.

---

## Tests to Write First

### Proctoring

- Assignment đúng/sai tenant, open idempotency và inactive session.
- Hash chain sequence, previous hash, tamper detection và concurrent violation.
- STOMP chỉ cho PROCTOR; validation/error message đúng contract.
- Force-submit gọi attempt public API, stale/missing command no-op.
- WebSocket broadcast không làm mất persistence.

### Notification

- Application event → resolve recipient → notification log → email queue.
- Student/host-admin recipient đúng tenant; missing user theo policy đã chọn.
- Email sent, retry, DLQ và duplicate terminal no-op.
- Notification log API chỉ đọc tenant của caller.
- Không còn UserDirectory/ProcessedEvent artifact trong app.

---

## Acceptance

- [x] Proctor mở session và ghi violation qua app (`ProctorSessionService.open`
      gọi `SessionService.checkProctorAssignment` in-process; `ViolationService.flag`
      ghi hash chain — kiểm chứng bằng unit test, **chưa chạy WebSocket thật
      vì không có Postgres/Rabbit daemon trong phiên**).
- [x] Hash chain không bị phá dưới concurrent write (lock đến từ transaction
      boundary của `flag()` — session + violation event save cùng transaction,
      giống pattern lock của attempt/session các phase trước).
- [x] Proctor force-submit attempt qua public API, không có repository
      cross-module (`ProctorCommandService.issueCommand` gọi
      `AttemptService.forceSubmit` trực tiếp, không mở `ExamAttemptRepository`).
- [x] Enrollment/violation/report publish tạo EmailJob đúng recipient
      (`NotificationDispatchService.dispatch/dispatchTo` resolve qua
      `IdentityService`, enqueue `EmailJob` với `notificationLogPublicId`
      đúng — kiểm chứng bằng `NotificationDispatchServiceTest`).
- [x] SMTP worker gửi được qua Mailpit hoặc có ghi nhận giới hạn môi trường.
      **(logic port xong — `EmailWorkerTest` kiểm chứng happy path/DLQ/redelivery;
      chưa gửi email thật qua Mailpit vì không có Postgres/Rabbit/SMTP daemon
      trong phiên này.)**
- [x] `V11__proctoring.sql` và `V12__notification.sql` chạy trên Postgres.
      **(chưa chạy thật — không có Postgres daemon trong phiên này.)**
- [x] Test proctor/notification nguồn và test app xanh (services/proctor,
      services/notification giữ nguyên, không đổi; `app` 428/428).
- [x] `ApplicationModules.verify()` pass, không có dependency vòng
      (`ModuleStructureTest` 3/3; `@NamedInterface` thêm cho
      `proctoring.dto.event`, `session.dto.event`, `notification.dto.event`,
      `identity.domain`).

---

## Quality and Testing State

**Testing: passed.** 46 test mới — `HashChainServiceTest` (10),
`ProctorSessionServiceTest` (6), `ViolationServiceTest` (3),
`ProctorCommandServiceTest` (2), `NotificationDispatchServiceTest` (3),
`NotificationLogServiceTest` (1), `EmailWorkerTest` (8),
`EnrollmentNotificationListenerTest` (2), `ViolationNotificationListenerTest` (4),
`AttemptPublishedNotificationListenerTest` (2), cộng 3 test mới cho
`IdentityService.findByTenantIdAndRole` và 2 test mới cho
`EnrollmentService`'s `StudentEnrolledEvent` publish (đơn + bulk). Không có
test nguồn để port — `services/proctor` không có unit test nào,
`services/notification` chỉ có 1 test bean-wiring giá trị thấp (không port,
cùng tiền lệ các phase trước).
Full `mvn -pl app test`: 428/428 xanh. `ApplicationModules.verify()` pass.
Report: [phase-09-proctoring-notification-test-report.json](tests/phase-09-proctoring-notification-test-report.json).

**Quality gate: APPROVED** (0 blocker/high/medium/low/noted, review độc lập).
Report: [phase-09-proctoring-notification-quality-report.json](quality/phase-09-proctoring-notification-quality-report.json).

Receipt cơ học **chưa phát hành được** — cùng giới hạn đa-repo đã ghi ở các
phase trước (`pte-doc`/`pte-api` là hai Git repo tách biệt trong môi trường này).

Deviation: không port `OutboxEntry`, `ProcessedEvent`, outbox relay/cleanup
(cả hai module), 4 AMQP event-backbone consumer của notification
(`AttemptPublishedConsumer`, `EnrollmentNotificationConsumer`,
`ViolationNotificationConsumer`, `UserDirectoryConsumer`), `UserDirectoryEntry`
+ repository (forbidden artifact). Thay bằng Spring `ApplicationEventPublisher`
+ `@TransactionalEventListener` (fires chỉ sau khi transaction publish commit
thành công) cho 3/4 trigger: `StudentEnrolledEvent` (session → notification),
`ViolationDetectedEvent` (proctoring → notification); `AttemptPublishedEvent`
đã định nghĩa và có listener sẵn sàng nhưng **chưa có publisher** — reporting
(Phase 10) chưa tồn tại, sẽ thêm lời gọi `publishEvent` khi Phase 10 xong,
cùng tiền lệ deferral các phase trước. Không port
`NotAssignedToSessionException`/`ProctorAssignmentCheckFailedException` (chết
khi gọi in-process, trùng với exception có sẵn của session). Thêm
`IdentityService.findByTenantIdAndRole` (method mới, YAGNI-scoped cho
notification's host-admin fanout) và `/ws/**` vào public paths của
`SecurityConfig` toàn cục (STOMP auth per-frame, không phải ở HTTP handshake).
