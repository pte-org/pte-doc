# Phase 02 — Shared + Identity

**Plan:** [plan.md](plan.md) · **Spec:** [spec.md](spec.md)
**Covers:** P1 "mở đúng một thư mục", FR-04 (bắt đầu xoá hạ tầng đồng bộ)
**Nguồn:** `pte-common` + `services/iam` (65 file)

---

## Mục tiêu

Đăng nhập thật được qua monolith: gọi `POST /api/auth/login` trên app mới, nhận JWT
hợp lệ, dùng JWT đó gọi được một endpoint có bảo vệ.

Đây là phase đầu tiên port nghiệp vụ, và `identity` là lựa chọn bắt buộc — mọi module
khác đều phụ thuộc vào nó để xác thực.

---

## Design Constraints

- **JWT phải giữ nguyên định dạng.** Token hiện tại mang `tenant_id`, `sub`, `roles`,
  `iss: pte-iam`. Hai app frontend đang đọc các trường này. Đổi định dạng ở phase này
  sẽ gãy frontend mà chưa có gì bù lại.

- **Monolith chạy độc lập, KHÔNG dùng chung token với stack cũ.**

  > Bản đầu của phase này ghi "giữ nguyên khoá ký để monolith và gateway cùng xác thực
  > được token của nhau". **Giả định đó sai** — red-team review ngày 2026-09-15 phát
  > hiện `RsaKeyProvider` sinh khoá RSA mới ở *mỗi lần khởi động*:
  >
  > ```java
  > public RsaKeyProvider() { this.rsaKey = generateKey(); }
  > ```
  >
  > Không có khoá nào để giữ. Javadoc của chính lớp đó đã ghi: *"Dev generates an
  > ephemeral key at startup (tokens invalidate on restart). Production MUST load a
  > stable key from Vault/env — TODO before release."*

  Vì vậy monolith **tự phát và tự xác thực** token của mình, trên cổng riêng, với
  khoá riêng. Không đấu nối vào gateway cũ. Stack microservice trên prod tiếp tục
  chạy nguyên vẹn, không bị chạm. Hai hệ thống sống song song nhưng **không chia sẻ
  phiên đăng nhập** — đăng nhập lại khi chuyển sang monolith là hành vi mong đợi,
  không phải lỗi. Việc đấu nối thật diễn ra ở Phase 11 (cutover).

  Cách này loại bỏ luôn vấn đề JWKS mà review nêu: không cần monolith phơi JWKS cho
  gateway cũ, vì gateway cũ không bao giờ nhận token của monolith.

- **Khoá RSA trong monolith phải ổn định.** Đọc từ biến môi trường
  `IAM_RSA_PRIVATE_KEY_PEM`, chỉ sinh khoá tạm khi biến này trống (và ghi log cảnh
  báo). Đây là việc TODO mà `iam` chưa làm — làm luôn ở đây thay vì mang theo nợ.
- `shared` đã tồn tại từ Phase 01 với `@ApplicationModule(type = OPEN)` (không phải
  "không khai báo" như bản nháp gốc ghi — Modulith tự coi mọi package con là module,
  kể cả khi không có annotation; OPEN mới thực sự cho module khác đọc được các lớp
  lồng trong `shared.security.*`, `shared.web.*`).
- Bảng giữ nguyên tên: `users`, `login_hashes`, `refresh_tokens`, `tenant_registry`.
- **Không thêm `pte-common` làm dependency của `app`** (bài học Phase 01): package
  root của nó trùng `com.pte.common`, bị Modulith quét nhầm thành module thứ 13.
  Port class, không port jar.

---

## Việc cần làm

1. **Port `pte-common` → `com.pte.shared`**
   - Chuyển: `security/` (`CurrentUser`, `CurrentUserContext`, `ResourceServerJwt`,
     `InternalServiceAuth`), `web/` (`ApiResponse`, `PagedResult`, `PageMeta`,
     `ExportPage`, `KeysetCursor`), exception handler, config.
   - **Bỏ lại:** `messaging/` — `AbstractOutboxRelay`, `AbstractProcessedEvent`,
     `AbstractOutboxCleanupJob`, `OutboxJpaRepository`. Toàn bộ nhóm này tồn tại chỉ
     vì hệ thống bị tách.
   - `KeysetCursor` / `ExportPage` chỉ phục vụ rebuild export → **bỏ**, trừ khi có
     chỗ khác dùng (kiểm tra bằng grep trước khi xoá).

2. **Port `iam` → `com.pte.identity`**

   | Giữ | Bỏ |
   |---|---|
   | `User`, `LoginHash`, `RefreshToken` | `OutboxEntry`, `ProcessedEvent`, `TenantRegistry` (xem 3b) |
   | `UserService`, `UserProvisioningHelper`, `UserBulkCreateWriter` | `IamOutboxRelay`, `IamOutboxCleanupJob` |
   | `AuthController`, `UserController`, JWT issuing, JWKS | `InternalExportController` (chỉ phục vụ rebuild) |
   | `UserRepository`, `UserMapper`, enum `Role` | `messaging/consumer/`, `CrossTenantAccessException` (dead code — khai báo nhưng chưa từng được throw) |

3. **Bỏ ghi outbox trong `UserService`**
   - Xoá các lời gọi `outboxWriter.write(...)` ở `create`, `suspend`, `reactivate`
     và trong `UserBulkCreateWriter`.
   - **Giữ `saveAndFlush`** trong `create` — hiện tại nó ở đó để lấy `createdAt` do
     Hibernate sinh, và `createdAt` vẫn cần cho khoá sắp xếp của danh sách student.
     Đây đúng là loại xử lý biên mà nguyên tắc #3 bảo vệ.
   - Email/thông báo mà `notification` từng nhận qua event: để lại TODO trỏ tới
     Phase 08, không tự nghĩ ra cơ chế mới ở đây.

3b. **Phát hiện thêm một cơ chế projection cùng loại với bug roster** *(phát
   hiện khi đọc code thật để port, không có trong bản nháp gốc)*

   `iam`'s `UserService.me()` dùng `TenantRegistryRepository` — một bản sao cục
   bộ của dữ liệu `Tenant`/`Organization` bên `admin`, đồng bộ qua
   `TenantEventConsumer` tiêu thụ event `TenantOnboarded`/`TenantSuspended`/
   `TenantReactivated` từ outbox của `admin`. Cùng một loại kiến trúc đã gây ra
   bug roster sáng 2026-09-15 (projection đồng bộ qua RabbitMQ để tránh gọi
   HTTP chéo service) — chỉ là chưa ai gặp bug với nó.

   Xử lý: bỏ hẳn `TenantRegistry`, `TenantRegistryRepository`,
   `TenantEventConsumer`, và 3 event DTO liên quan. `UserService.me()` tạm trả
   `organizationType = null` kèm `TODO(Phase 03)` — khi `tenancy` được port,
   thay bằng lời gọi in-process thật vào service công khai của `tenancy`.

4. **Sắp xếp theo quy ước Modulith**

   Cấu trúc thật sau khi thực thi (khác bản nháp ban đầu ở hai điểm, cả hai đều
   theo phản hồi trực tiếp khi code — xem chú thích):

   ```
   com.pte.identity/
   ├── domain/                       ← module khác dùng được
   │   ├── User.java
   │   ├── Role.java
   │   └── UserStatus.java           (*)
   ├── IdentityService.java          ← API công khai của module
   └── internal/                     ← không module nào khác chạm được
       ├── domain/        LoginHash, RefreshToken
       ├── repository/    UserRepository, LoginHashRepository, RefreshTokenRepository
       ├── service/       UserService, UserBulkCreateWriter, AuthService,
       │                  RefreshTokenService, UserProvisioningHelper
       ├── mapper/         UserMapper
       ├── security/       RsaKeyProvider, AccessTokenIssuer, TokenHasher
       ├── config/         SecurityConfig, JwtConfig
       ├── controller/     AuthController, UserController, JwksController
       ├── constant/       IdentityConstants
       ├── dto/request/, dto/response/
       └── exception/      7 lớp DomainException con
   ```

   *Điểm khác 1 — `domain/`:* bản nháp ban đầu để `User.java`/`Role.java` rời
   ngay dưới `identity/`. Sau khi code xong, gom vào `identity/domain/` theo
   yêu cầu trực tiếp khi review — Spring Modulith chỉ ẩn những gì nằm dưới
   package tên `internal`, nên `identity/domain/` vẫn là API công khai như cũ,
   chỉ có tổ chức gọn hơn.

   *Điểm khác 2 — `internal/` phân tầng:* bản nháp ban đầu để phẳng
   (`internal/UserRepository.java`, `internal/AuthController.java`... cùng
   cấp). Sau khi code xong, tổ chức lại theo đúng quy ước phân tầng
   `domain/repository/service/controller/...` mà `services/iam`,
   `services/admin` đã dùng — theo yêu cầu trực tiếp khi review, lý do:
   entity/repository/service/controller nằm chung một chỗ khó theo dõi hơn
   quy ước sẵn có của repo.

   (*) `UserStatus` không có trong bản nháp gốc — bổ sung khi code vì
   `User.getStatus()` (public) trả về nó; nếu để trong `internal/`,
   `ApplicationModules.verify()` báo vi phạm ranh giới ngay.

   `IdentityService` là cửa duy nhất module khác đi vào — các module sau sẽ cần
   `findById`, `existsById`, `getTenantOf`.

5. **Flyway**
   - `V2__identity.sql`: `users`, `user_roles`, `login_hashes`, `refresh_tokens`.
     **Không** có `tenant_registry` — bảng đó là chính cơ chế projection bị bỏ
     (xem bước 3b bên dưới), không tồn tại trong monolith.
   - Sinh DDL từ entity đã port, **không** copy migration của `iam` (`iam` thực
     ra chưa từng có Flyway — dùng `ddl-auto: update` — nên không có gì để copy;
     migration này viết tay khớp với entity, theo `ddl-auto: validate` của
     Phase 01).

6. **Port test của `iam`** sang `app`, giữ nguyên assertion.

---

## Tests to Write First

Không có. Phase này là refactor bảo toàn hành vi — test đúng đắn là test sẵn có của
`iam` tiếp tục xanh sau khi port.

---

## Acceptance

- [x] Toàn bộ test của `iam` đã port sang `app` và xanh (4 file, 24 test case:
      `UserServiceTest` 14, `UserBulkCreateWriterTest` 2, `UserProvisioningHelperTest` 8,
      `PasswordGeneratorTest` 2 — cộng `ModuleStructureTest` 3 của Phase 01 = 29/29)
- [x] `services/iam` **vẫn còn và vẫn build được** — `git status` xác nhận 0 diff
      trong `services/`; full reactor 14/14 module xanh
- [x] `ApplicationModules.verify()` vẫn pass — kể cả sau khi tổ chức lại
      `internal/` thành phân tầng và tách `domain/` ra khỏi gốc module
- [ ] `POST /api/auth/login` trên app mới trả JWT; decode ra đúng `tenant_id`, `sub`,
      `roles` như token do `iam` phát — **chưa kiểm chứng thật**, cùng lý do Phase 01:
      không có Docker daemon trong phiên làm việc để khởi động Postgres thật.
      Unit test (Mockito) xác nhận đúng logic tạo token, nhưng không thay thế được
      việc chạy thật.
- [ ] Khởi động lại app **không** làm token đang có hết hiệu lực — **chưa kiểm
      chứng thật**, cùng lý do trên.
- [x] Không còn file nào trong `app/` khớp `grep -riE "outbox|processedevent|idempotency|tenantregistry"`
      ngoài chú thích giải thích lý do bỏ (đã grep xác nhận)

**Khoảng trống còn lại giống Phase 01**: hai mục JWT/restart cần Postgres +
RabbitMQ thật để kiểm chứng end-to-end. Đây không phải lỗi — là giới hạn môi
trường làm việc hiện tại, cần chạy tay (`docker compose up`) trước khi coi
Phase 02 hoàn tất 100%.

---

## Quality and Testing State

- Quality: **approved** — `ck:quality --gate`, chạy 2 lần (lần 1 duyệt trước khi
  tổ chức lại `internal/`, lần 2 xác nhận lại sau khi tổ chức lại theo phản hồi
  người dùng). 0 blocking cả hai lần. Report:
  `pte-doc/projects/plans/modular-monolith/quality/phase-02-identity-quality-report.json`.
  Receipt: `...phase-02-identity-receipt.json` (mốc thời gian khớp lần chạy cuối).
- Testing: `ck:test --unit` sweep = **skipped_by_user** (quyết định lúc bắt đầu
  phase). Test riêng của phase (4 file, 24 case) đã chạy thật và xanh — một
  phần "Việc cần làm" của chính phase, không phải bước hồi quy tùy chọn. Toàn
  reactor (`./mvnw test`, 14 module) đã chạy thật và xanh 2 lần (trước và sau
  khi tổ chức lại package).
- Khoảng trống: JWT login/restart end-to-end chưa kiểm chứng thật (không có
  Docker/Postgres trong phiên) — xem Acceptance.
