# ADR-004: Cấu trúc code từng module

**Date:** 2026-07-24 · **Viết lại 2026-09-16** theo cây thư mục thực tế
**Status:** Accepted
**Depends on:** [ADR-001](ADR-001-module-boundaries.md), [ADR-002](ADR-002-communication-and-scoring-lifecycle.md), [ADR-003](ADR-003-tenant-isolation-and-infrastructure.md)

Mono-repo `pte-api/`, **một Maven module (`app`)**, một Spring Boot application, một Postgres. Mọi module nghiệp vụ dùng cùng một layout.

> **Cách đọc:** danh sách dưới đây sinh từ cây thư mục thật `app/src/main/java/com/pte/*/`. Thêm class mới thì cập nhật file này trong cùng PR — nếu không, file quay lại vô dụng như bản trước.

---

## Layout chuẩn của một module

```
com.pte.<module>/
├── <Module>Service.java        ← facade công khai — cửa DUY NHẤT module khác gọi
├── package-info.java           ← @ApplicationModule(displayName = "...")
├── domain/                     ← CÔNG KHAI
│   ├── <Entity>.java
│   └── enums/
├── dto/                        ← CÔNG KHAI — chỉ DTO dùng xuyên module
│   ├── request/
│   ├── response/
│   └── event/
└── internal/                   ← RIÊNG — không module nào được import
    ├── controller/
    ├── service/
    ├── repository/
    ├── mapper/
    ├── dto/{request,response}/ ← DTO chỉ dùng trong module
    ├── exception/
    ├── constant/
    └── config/
```

### Ba quy tắc

1. **`internal/` là riêng.** Import xuyên module vào `internal/` là vi phạm ADR-001 #3. Trình biên dịch **không chặn** — chỉ code review chặn, cho tới khi có `ApplicationModules.verify()`.
2. **Facade mỏng.** `<Module>Service` chỉ uỷ quyền, không chứa logic. `SessionService` là ví dụ đúng: ba phương thức, mỗi phương thức một dòng gọi xuống `EntitlementService`.
3. **Chỉ phơi ra cái có người gọi.** `session` có hàng chục thao tác nhưng facade chỉ phơi ba — số còn lại chỉ controller của chính nó dùng.

### Quy ước chung

- **Entity** kế thừa `shared.domain.BaseEntity` (`id` nội bộ + `publicId` UUID + timestamp). **Tham chiếu xuyên module luôn bằng `publicId`**, không bao giờ bằng khoá ngoại tới bảng module khác — đây là thứ giữ cho ranh giới còn nghĩa và cho phép tách lại sau này.
- **Thông báo lỗi** nằm trong `internal/constant/<Module>Constants.java`, không hardcode trong code.
- **Không tìm thấy trong tenant của caller → 404, không phải 403.** Nhất quán toàn hệ: không rò rỉ sự tồn tại của tài nguyên thuộc tenant khác.
- **Schema do Flyway quản** (`db/migration/V1..V13`), Hibernate `ddl-auto: validate`. Entity lệch schema là app không khởi động được.

---

## Inventory

### identity — xác thực, nguồn của JWT
**Sở hữu:** `User`, `LoginHash`, `RefreshToken`
**controller:** `Auth` (login/refresh/logout), `User` (CRUD + bulk create)
**service:** `AuthService`, `UserService`, `UserBulkCreateWriter` (**chạy đồng bộ** — xem cảnh báo ADR-003 lớp 2), `UserProvisioningHelper`, `RefreshTokenService`
**security:** `AccessTokenIssuer`, `RsaKeyProvider` (ký RS256), `TokenHasher`
`tenantId` nhét vào JWT claim → module khác đọc từ token, không tra DB lúc runtime.

### tenancy — quản trị tổ chức
**Sở hữu:** `Tenant`, `Organization`, `QuotaTransaction`
**controller:** `Tenant`, `Organization`, `HostOrganization`
**service:** `TenantLifecycleService`, `OrganizationService`, `QuotaTransactionService`
`QuotaTransaction` là ledger append-only — `amount` là delta có dấu, không phải tổng đang chạy.

### enrollment — cơ cấu học thuật
**Sở hữu:** `Program`, `StudentClass`, `ClassMembership`, `LecturerAssignment`, `ProgramCoordinatorAssignment`
**controller:** `Program`, `Class`, `ClassMembership`, `LecturerAssignment`, `ProgramCoordinatorAssignment`, `StudentRoster`
**service:** `ProgramService`, `ClassService`, `AssignmentService`, `StudentRosterQueryService`

### itembank — ngân hàng câu hỏi
**Sở hữu:** `Question`, `QuestionOption`
**controller:** `Question`
**service:** `ItembankAccessPolicy`, `QuestionValidationHelper`
`PteTaskType` mang sẵn yêu cầu đầu vào của từng loại task → validate theo dữ liệu, không phải 22 nhánh `if` viết tay.

### assessment — soạn & đóng băng đề
**Sở hữu:** `ExamBlueprint`, `BlueprintItem`, `ExamSnapshot`, `SnapshotItem`
**controller:** `Blueprint`, `Snapshot`, `InternalSnapshot`
**service:** `BlueprintService`, `SnapshotPublishService`, `AssessmentAccessPolicy`
Publish = deep-copy nội dung câu hỏi vào snapshot bất biến. Snapshot không bao giờ sửa.

### session — kỳ thi & ghi danh
**Sở hữu:** `ExamSession`, `Enrollment`, `SessionComposition`, `ProctorAssignment`, `ExamPolicy`, `ReplayPolicy`
**controller:** `Session`, `Enrollment`, `StudentEnrollment`, `ProctorAssignment`, `InternalSession`
**service:** `SessionLifecycleService`, `EnrollmentService`, `CompositionService`, `EntitlementService`
**facade:** `checkEntitlement`, `checkProctorAssignment`, `verifyHostAccess`

### attempt — làm bài (critical path)
**Sở hữu:** `ExamAttempt`, `AttemptAnswer`, `AttemptHeartbeat`, `PinnedExamSnapshot`, `PinnedItem`
**controller:** `Attempt`, `Heartbeat`
**service:** `SnapshotPinService`, `AttemptLifecycleService`, `AnswerSubmitService`, `TimerService`, `HeartbeatService`, `ProctorCommandService`, `SubmissionDecryptionService`, `AttemptSummaryQueryService`, `SubmittedAnswerQueryService`
**cache:** `PinnedSnapshotCacheService` (Redis, warm ngay sau khi pin)
Mọi lời gọi ra module khác đều nằm trong `SnapshotPinService` — tức chỉ chạy lúc **tạo** attempt, không chạy giữa lúc thi. Đây là chỗ bất biến #1 của ADR-001 được giữ.

### proctoring — giám thị
**Sở hữu:** `ProctorSession`, `ViolationEvent`
**controller:** `ProctorSession`, `ProctorStomp` (WebSocket), `ViolationAudit`
**service:** `ProctorSessionService`, `ViolationService`, `HashChainService`, `ProctorCommandDispatchService`
`HashChainService` làm audit log tamper-evident — mỗi bản ghi băm cả bản ghi trước.

### scoring — chấm điểm
**Sở hữu:** `ScoringAnswer`
**controller:** `ScoringCommand`, `ScoringReview`
**service:** `ScoringCommandService`, `ScoringIngestService`, `ObjectiveScoringService`, `AiScoringDispatcher`, `AiScoringTaskCatalog`, `ScoringReviewService`, `ScoredAnswerQueryService`, `AnswerPayloadDecoder`
**messaging:** `AiScoringWorker` ← RabbitMQ work-queue
**vendor:** `EssayScoringClient`, `SpeechScoringClient`, hiện thực OpenAI-compatible

### reporting — read model
**Sở hữu:** `AttemptReport`
**controller:** `Report`, `ReportPublish`
**service:** `ReportService`, `ReportPublishService`, `ScoreAggregationService`
Chỉ expose attempt ở trạng thái `PUBLISHED`.

### notification — gửi thông báo
**Sở hữu:** `NotificationLog`
**controller:** `NotificationLog`
**service:** `NotificationDispatchService` → RabbitMQ → `EmailWorker`

### media — lưu trữ nhị phân
**Sở hữu:** `MediaObject`
**controller:** `Media`, `InternalMedia`
**service:** `CloudinaryMediaService` (signed direct upload, TTL ngắn)

### shared — hạ tầng dùng chung (không phải bounded context)
`domain/BaseEntity`, `security/CurrentUser`, `web/RateLimitFilter` + `RateLimitConfig`, `config/RabbitMessageConverterConfig`, `audit/`, `exception/`

---

## Consequences

**Được:** mở một module là thấy hết những gì nó làm. Facade nói rõ bề mặt công khai, nên câu hỏi "đổi cái này có ảnh hưởng ai không" trả lời được bằng cách nhìn một file.

**Trả giá:** layout này là **quy ước, không phải cơ chế**. Không có gì chặn một `@Autowired` xuyên `internal/`, không có gì chặn một `@Query` JOIN hai bảng của hai module. Ranh giới sống hay chết phụ thuộc vào code review — cho tới khi có test xác minh cấu trúc của Spring Modulith.
