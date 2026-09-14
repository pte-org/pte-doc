# ADR-004: Per-Service Code Structure

**Date:** 2026-07-24
**Status:** Accepted — **nội dung per-service viết lại theo as-built 2026-09-14.** Bản 2026-07-24 mô tả thiết kế dự kiến trước khi code; nhiều entity/service/event khác thực tế. File này giờ mô tả code đang có, không phải dự định.

**Depends on:** ADR-001/002/003, `docs/CODING_STANDARDS_MICROSERVICE.md`

Mono-repo (`pte-api/`), Maven multi-module, database-per-service (10 DB trên 4 Postgres cell — xem ADR-001 mục Cell). Mọi service dùng layout layered thống nhất theo coding standard §2. File này liệt kê nội dung **cụ thể** từng service: entity sở hữu (= bảng DB), controller, service class, event phát/nhận, sync dep.

Legend: **emits** = publish qua outbox→RabbitMQ (polling relay, was Kafka — xem ADR-002's "Superseded-in-part" note, 2026-07-31); **consumes** = RabbitMQ listener; **sync→** = guarded REST call (timeout + circuit breaker).

> **Cách đọc:** danh sách entity/controller/service dưới đây được sinh từ cây thư mục thực tế `pte-api/services/*/src/main/java/com/pte/*/{domain,controller,service}`. Khi thêm class mới, cập nhật file này cùng PR — nếu không, file quay về vô dụng như bản trước.
>
> **Quy ước chung, không lặp lại ở từng service:** service nào có outbox đều sở hữu entity `OutboxEntry`; service nào consume event đều sở hữu `ProcessedEvent` (dedup, `AbstractProcessedEvent` trong `pte-common`). Dưới đây hai entity này được bỏ khỏi danh sách để không nhiễu.

---

## gateway  (Spring Cloud Gateway WebFlux — no domain layers)
- Route + filter only. JWT validation ở biên (`oauth2-resource-server`, JWKS từ iam), per-tenant rate-limit (`RateLimitConfig.tenantKeyResolver()` → Redis token bucket key theo claim `tenant_id`, fallback `"anonymous"`), correlation-id propagation, OTel export.
- Không DB, không business logic. Module `gateway/` trong chính mono-repo — **không phải Kong/APISIX** như ADR-003 mô tả.
- Đứng sau Caddy (TLS/ACME + same-origin routing, `deploy/Caddyfile`).

---

## iam  (auth server — the only one)
**Owns (db `iam`, cell `pg-core`):** `User`, `LoginHash`, `RefreshToken`, `TenantRegistry`.
- **Package:** `com.pte.iam`
- **controller:** `AuthController` (login, refresh, logout), `UserController` (CRUD host/proctor/student + bulk create), `JwksController` (public keys).
- **service:** `AuthService`, `UserService`, `UserBulkCreateWriter` (mỗi row một TX `REQUIRES_NEW`, **chạy đồng bộ** — xem cảnh báo ADR-003 Lớp 2), `UserProvisioningHelper`, `RefreshTokenService`.
- **Tenant registry nằm ở đây**: `tenantId` + status nhét vào JWT claim → data plane đọc từ token, không call admin lúc runtime.
- **emits:** `UserCreated`, `UserSuspended`, `UserPasswordReset`, `TenantOnboarded`, `TenantSuspended`, `TenantReactivated`.
- **consumes:** `TenantEventConsumer` — nhận `Tenant*` từ admin để cập nhật `TenantRegistry`.
- **sync deps:** không (root of trust).

## admin  (control plane + academic org structure)
**Owns (db `admin`, cell `pg-core`):** `Tenant`, `Organization`, `Program`, `StudentClass`, `ClassMembership`, `LecturerAssignment`, `ProgramCoordinatorAssignment`, `QuotaTransaction`, `AuditLog`.
- **Package:** `com.pte.admin`
- **controller:** `TenantController`, `OrganizationController`, `HostOrganizationController`, `ProgramController`, `ClassController`, `ClassMembershipController`, `LecturerAssignmentController`, `ProgramCoordinatorAssignmentController`, `AuditLogController`.
- **service:** `TenantLifecycleService`, `OrganizationService`, `ProgramService`, `ClassService`, `AssignmentService`, `QuotaTransactionService`, `AuditLogService`.
- **emits (25 loại):** `Tenant*` (Onboarded/Suspended/Reactivated/BrandingUpdated), `Organization*`, `Program*`, `Class*` (Created/Updated/StatusChanged/Archived/Split/Merged), `Student*ToClass`, `Lecturer*`, `Coordinator*`, `QuotaGranted`.
- **Không nằm trên critical runtime path** — không service nào có `AdminClient`. Chỉ `Tenant*` có consumer (iam); toàn bộ event `Organization`/`Program`/`Class`/`*Assigned` hiện **chưa có consumer nào**.
- **Không own tenant *identity*** (đó là iam) — own tenant *governance* + cấu trúc tổ chức.
- ⚠️ Phạm vi service này đã phình khỏi định nghĩa "platform governance" ban đầu (`Subscription`/`PlatformConfig`/`FeatureFlag`/`KillSwitch` **không tồn tại**). Câu hỏi mở về ranh giới: xem ADR-001 mục reconciliation.
- **sync deps:** không.

## authoring  (content — data plane, multi-tenant)
**Owns (db `authoring`, cell `pg-core`):** `Question`, `QuestionOption`, `ExamBlueprint`, `BlueprintItem`, `ExamSnapshot`, `SnapshotItem`.
- **Package:** `com.pte.authoring`
- **controller:** `QuestionController`, `BlueprintController`, `SnapshotController` (publish), `InternalSnapshotController` (`/internal/**`, gác bằng `InternalApiKeyFilter` — exam-delivery/scheduling gọi vào đây).
- **service:** `QuestionService` + `QuestionValidationHelper` (validate required-field theo task type), `BlueprintService`, `SnapshotPublishService`, `AuthoringAccessPolicy` (ép scope global/tenant ở tầng app).
- **domain.enums:** `PteTaskType` (22 scored + 1 unscored), `Skill`, `QuestionStatus`, `Visibility` (PRIVATE tenant / SHARED global).
- **Visibility model:** `tenant_id = NULL` = kho SHARED do admin tạo (host đọc, chỉ PLATFORM_AUTHOR ghi); `tenant_id = X` = PRIVATE của host. **Ép bằng `AuthoringAccessPolicy` ở tầng application — chưa có RLS** (ADR-003 Lớp 1).
- **emits:** `ExamSnapshotPublished` (immutable, versioned — scheduling consume).
- Per-tenant quota và bulk create: **chưa triển khai**.
- **sync deps:** không (media presign hiện không được authoring gọi).

## scheduling  (exam session orchestration)
**Owns (db `scheduling`, cell `pg-core`):** `ExamSession`, `SessionComposition`, `Enrollment`, `ProctorAssignment`, `ExamPolicy`, `ReplayPolicy`, `SnapshotRef`, `SnapshotRefItem`.
- **Package:** `com.pte.scheduling`
- **controller:** `SessionController`, `EnrollmentController`, `StudentEnrollmentController` (student tự xem/đăng ký), `ProctorAssignmentController`, `InternalSessionController` (`/internal/**` — exam-delivery/proctor kiểm entitlement/assignment).
- **service:** `SessionService`, `CompositionService`, `EnrollmentService`, `EntitlementService` (student này có quyền vào session này không), `SnapshotRefService` + `SnapshotItemSpec` (giữ tham chiếu tới snapshot đã publish), `HostCommandService` (phát lệnh chấm/publish).
- **Composition là config**: trỏ tới một `ExamSnapshot` đã publish + subset task type + thứ tự + timing override. exam-delivery pin cái này vào attempt.
- **`ExamPolicy` / `ReplayPolicy`** (không có trong ADR gốc): luật thi và luật cho thi lại, per-session.
- **emits:** `SessionScheduled`, `StudentEnrolled`, `StudentUnenrolled`, `ProctorAssigned`, `ProctorUnassigned`, `ProctorRoleUpdated`, `ScoringRequested` (host command), `PublishRequested` (host command), `ExamSnapshotPublished` (re-emit).
- **consumes:** `SnapshotEventConsumer` ← `ExamSnapshotPublished` từ authoring.
- **Lệnh chấm/publish host-facing xuất phát từ đây** (không phải trong scoring service) — đúng ADR-002.
- **sync deps:** `AuthoringClient` — guarded (CB `authoring`).

## exam-delivery  (critical path — most protected)
**Owns (db `exam_delivery`, cell `pg-exam` riêng):** `ExamAttempt`, `AttemptAnswer`, `AttemptHeartbeat`, `PinnedExamSnapshot`, `PinnedItem`.
- **Package:** `com.pte.examdelivery`
- **controller:** `AttemptController` (start, get task, submit answer, submit attempt), `HeartbeatController`, `MockExamController`, `InternalExportController` (`/internal/**` — reporting gọi khi rebuild).
- **service:** `AttemptService` (state machine), `TimerService`, `HeartbeatService`, `SnapshotPinService`, `AnswerSubmitService`, `SubmissionDecryptionService`, `ProctorCommandService`; `service/cache/PinnedSnapshotCacheService` (Redis warm + single-flight).
- **Tự chủ trong lúc thi:** pin snapshot + composition lúc start. 3 sync client (`AuthoringClient`, `SchedulingClient`, `MediaClient`) **chỉ được inject vào `SnapshotPinService`** → chỉ chạy lúc tạo attempt, **không call gì trong lúc student đang thi**. Đây là điểm ép bất biến ADR-001 #1; giữ nguyên ràng buộc này khi sửa code.
- **Timer as-built:** không có entity `TimerState`; trạng thái thời gian nằm trong `ExamAttempt` + `AttemptHeartbeat`. `TimerService` enforce prep/response per task.
- **Mã hoá đáp án:** `EncryptionKeyProvider` (RSA-2048 riêng của exam-delivery, tách khỏi key iam) + `EncryptedSubmissionRequest` + `SubmissionDecryptionService`, kích hoạt ở `answerIntegrityLevel=STRICT`.
- **messaging.outbox:** `AnswerSubmitted`, `AttemptSubmitted` ghi cùng TX với answer.
- **consumes:** **chỉ** `ProctorCommandConsumer` (force-submit / extend-time). **Không** consume `AnswerScored`/`AttemptPublished` — điểm không bao giờ ghi ngược về exam-delivery; `ExamAttempt` không mang trạng thái SCORED/PUBLISHED.
- **Cô lập tài nguyên:** cell Postgres riêng (`pg-exam`, `max_connections=100`), container riêng, pool riêng.

## proctor  (supervision — WebSocket)
**Owns (db `proctor`, cell `pg-live` riêng):** `ProctorSession`, `ViolationEvent` (append-only, hash-chained).
- **Package:** `com.pte.proctor`
- **controller:** `ProctorStompController` (STOMP/WebSocket), `ProctorSessionController`, `ViolationAuditController`.
- **config:** `WebSocketConfig`, `StompAuthChannelInterceptor` (auth JWT trên STOMP CONNECT).
- **service:** `ProctorSessionService`, `ViolationService`, `ProctorCommandService`, `HashChainService` (SHA-256, link = `sessionPublicId|sequenceNo|attemptPublicId|violationType|detail|detectedAt|prevHash`; verify bằng cách tính lại toàn chuỗi).
- **Audit tamper-evident nằm trên chính `ViolationEvent`** (cột `prevHash` + `hash`), không phải entity `AuditLog` riêng.
- **emits:** `ProctorCommandPublished` (exam-delivery consume), `ViolationDetected` (notification consume).
- **consumes:** không có consumer nào (không consume `AttemptSubmitted`).
- **sync deps:** `SchedulingClient` — guarded (CB `scheduling`).
- **Profile scale riêng** (WS long-lived) → cell `pg-live` riêng.

## scoring  (assessment — async, host-gated)
**Owns (db `scoring`, cell `pg-async` riêng):** `ScoringAnswer`.
- **Package:** `com.pte.scoring`
- **controller:** `ScoringReviewController` (host xem/điều chỉnh kết quả SCORED), `InternalExportController` (`/internal/**` — reporting rebuild).
- **service:** `ObjectiveScoringService` (rule-based), `AiScoringDispatcher` + `AiScoringTaskCatalog` (task type nào đi AI vendor), `AnswerPayloadDecoder`, `AttemptCompletionService`, `ScoringReviewService`; `vendor/` (adapter AI vendor).
- **messaging.consumer:** `AnswerIngestConsumer` (nhận `AnswerSubmitted` → lưu, **không chấm**), `ScoringCommandConsumer` (nhận `ScoringRequested` host command → fan-out), `AiScoringWorker` (work queue, gọi vendor, retry/backoff → DLQ).
- **emits:** `AnswerScored`, `AttemptScored`.
- **Chỉ chạy khi có lệnh** — không bao giờ tự trigger từ `AttemptSubmitted`. Không sở hữu quyết định publish.
- **Hai vai RabbitMQ trong cùng service** (outbox-relay và work-queue) dùng 2 `RabbitMqConfig` tách biệt — xem ADR-002.
- **sync deps:** `MediaClient` (fetch audio) — guarded (CB `media`); AI vendor ngoài.
- **Mô hình dữ liệu gọn hơn thiết kế gốc:** một entity `ScoringAnswer` thay cho `ScoringJob`/`AnswerScore`/`SkillScore`/`VendorResult`. Tổng hợp skill score làm ở `reporting`, không lưu ở scoring.

## reporting  (read model — CQRS)
**Owns (db `reporting`, cell `pg-core`):** `AttemptReport`, `AnswerProjection`.
- **Package:** `com.pte.reporting`
- **controller:** `ReportController` (student chỉ thấy PUBLISHED; host thấy SCORED+), `RebuildController` (`POST /reports/rebuild` — host, 1 tenant, tenantId lấy từ JWT), `InternalRebuildController` (`POST /internal/rebuild/bootstrap` — cần **2 key**: `X-Internal-Service-Key` + `X-Internal-Bootstrap-Key`).
- **service:** `AttemptProjectionService`, `AnswerScoreService`, `ScoreAggregationService` + `SkillScore` + `AttemptScoreSummary` (Overall + 4 communicative + 6 enabling; xử lý practice subset → báo "insufficient data" cho skill không có task đóng góp), `ReportService`, `RebuildOrchestrationService`.
- **consumes:** `AttemptIngestConsumer` (`AttemptSubmitted`), `AnswerScoredConsumer` (`AnswerScored`/`AttemptScored`), `PublishConsumer` (`PublishRequested` từ scheduling).
- **emits:** `AttemptPublished` — **quyết định publish materialize ở đây**, notification consume.
- **Không đọc từ replica** (chưa có read replica). Không sở hữu source-of-truth.
- **sync deps:** `ExamDeliveryExportClient`, `ScoringExportClient` — **rebuild-only**, keyset cursor `(updatedAt, publicId)`. Hai client này **chưa có CB** (chấp nhận được: không nằm trên request path).
- **Giới hạn đã biết:** `AttemptReport.published`/`publishedAt` không rebuild được (xem ADR-002).

## notification  (outbound messaging)
**Owns (db `notification`, cell `pg-core`):** `NotificationLog`, `UserDirectoryEntry`.
- **Package:** `com.pte.notification`
- **controller:** `NotificationLogController`.
- **service:** `NotificationDispatchService`, `NotificationLogService`.
- **consumes:** `UserDirectoryConsumer` (`UserCreated` từ iam → dựng directory email nội bộ, không phải call iam lúc gửi), `ViolationNotificationConsumer`, `AttemptPublishedConsumer`, `EnrollmentNotificationConsumer`, `EmailWorker` (work queue gửi thật).
- **`UserDirectoryEntry` là bản sao denormalized** danh bạ người nhận — notification không gọi iam runtime.
- **Không có entity `Template`/`DeliveryStatus`**; trạng thái gửi nằm trên `NotificationLog`.
- **sync deps:** SMTP ngoài (dev: Mailpit).

## media  (binary storage)
**Owns (db `media` trên cell `pg-core` + object store MinIO/S3):** `MediaObject`.
- **Package:** `com.pte.media`
- **controller:** `MediaController` (xin presigned upload/download URL), `InternalMediaController` (`/internal/**` — exam-delivery/scoring gọi).
- **service:** `PresignService`. `MediaValidationService`/`TranscodeService` **chưa có**.
- Presigned URL TTL ngắn; binary không bao giờ nằm trong Postgres. Watermark: chưa có.
- **sync deps:** MinIO.
- ⚠️ **Lưu ý topology:** db `media` nằm trên `pg-core` (cùng cell với control plane), trong khi service `media` phục vụ cả đường thi (presign audio đề) — tách media sang host khác sẽ tách nó khỏi DB của chính nó.

---

## Cross-service reference rule (reminder)
A service stores another service's key as a plain `UUID publicId` column and resolves it via API/event — **never** a JPA relationship across service boundaries. Example: `exam-delivery.PinnedExamSnapshot.snapshotPublicId` references `authoring.ExamSnapshot.publicId`, copied at pin time, never joined.

## Build order (walking skeleton — đã hoàn thành)
gateway + iam → exam-delivery (end-to-end với pinned snapshot) → authoring + scheduling → event backbone → scoring + vendor → reporting → notification/media → pte-app Flutter.

Event backbone as-built là **RabbitMQ + polling outbox relay**, không phải Kafka+Debezium như kế hoạch ban đầu — xem `plans/rabbitmq-outbox-migration/plan.md` (11 phase) và ADR-002.

---

## Chưa triển khai — danh sách rõ ràng (2026-09-14)

Để không ai đọc file này rồi tưởng đã có:

| Thứ | Service | Ghi ở ADR nào |
|---|---|---|
| Postgres RLS | authoring (và mọi service multi-tenant) | ADR-003 Lớp 1 — **khoảng cách nghiêm trọng nhất** |
| Per-tenant quota, bulk-import async | authoring | ADR-003 Lớp 2 |
| `MediaValidationService`, `TranscodeService`, watermark | media | ADR-004 bản gốc |
| Multi-replica sau load balancer | tất cả | ADR-003 Lớp 3 |
| Read replica cho reporting | reporting | ADR-003 |
| Metrics (Prometheus) + log aggregation (Loki) | hạ tầng | ADR-003 |
| Vault / Keycloak / Linkerd / CDN / PgBouncer | hạ tầng | ADR-003 (defer có chủ đích) |
