# Phase 1: Nền tảng — inventory, spike JSON/H2, profile local-schema, bảng hạ tầng

## Requirements

Chốt nền kỹ thuật cho cả plan: feature map + inventory endpoint/client, bằng chứng `SqlTypes.JSON` chạy trên H2, profile `local-schema` (Hibernate dựng schema, Flyway tắt) cùng seed dev `db/dev-seed/*.sql` ngay từ phase này (kèm tài khoản `admin@test.local`), và các bảng hạ tầng dùng chung (`IdempotencyKey`, `OtpChallenge`, `MediaAsset`, `AuditLog` mở rộng; `PlatformSetting` và `RefreshToken` giữ). Phục vụ FR-01, FR-07, FR-09 và tiêu chí function parity.

## Design Constraints

- Đọc đầy đủ `D:\GitHub\pte-org\docs\CODING_STANDARDS_API.md`, `API_RESPONSE_SETUP.md`, `COMMON_EXCEPTION_SETUP.md`; ghi standards-read note vào progress update đầu tiên.
- Jsonb chỉ qua `@JdbcTypeCode(SqlTypes.JSON)` không `columnDefinition`; không native query jsonb.
- Inventory xuất TRƯỚC khi sửa bất kỳ controller/DTO; phase này không đổi endpoint nào.
- `IdempotencyKey` chỉ là dedupe + receipt; lịch sử/audit thuộc `AuditLog`. Retention theo scope khai báo trong constants (ATTENDANCE và EXAMINER_COMMAND: `closesAt` + 90 ngày; LICENSE_ISSUE: 365 ngày; PRACTICE_SESSION_OP: 7 ngày).
- Seed tài khoản: chỉ lưu BCrypt hash, sinh bằng `PasswordEncoder` của app lúc implement; KHÔNG ghi mật khẩu plaintext vào file repo, plan hay báo cáo. Seed nằm trong `db/dev-seed/020-local-accounts.sql` (chỉ chạy với profile `local-schema`), không phải SQL thủ công.
- Thông điệp/mã lỗi mới nằm trong `*Constants.java` của module sở hữu; không dùng Testcontainers.
- Cơ chế flow test dùng chung cho mọi phase (chốt ở phase này, phase 2 dùng đầu tiên): `@DataJpaTest` trên profile test H2 hiện có + `@Import` các service thật của luồng; stub bằng `@TestConfiguration` cho RabbitMQ publisher, Redis, Cloudinary/media, PayOS, mail và AI provider (dùng stub scorer có sẵn trong `scoring/internal/vendor/stub`); listener `@TransactionalEventListener`/`@ApplicationModuleListener` chỉ chạy sau commit nên flow test phải tắt transaction rollback mặc định của `@DataJpaTest` (`@Transactional(propagation = NOT_SUPPORTED)` + dọn dữ liệu giữa test) hoặc gọi listener tường minh; chọn một cách và ghi vào base class. Đặt base class/config dùng chung dưới `app/src/test/java/com/pte/support/flow/`.

## Steps

1. Xuất inventory từ `RequestMappingHandlerMapping`: method + path + roles + tên field response DTO, gồm `/internal/**` (`InternalSessionController`, `InternalSnapshotController`, `InternalMediaController`) và destination STOMP (`ProctorStompController`) — hoặc ghi rõ nếu loại trừ. Lưu JSON vào `pte-doc/plans/reports/assets/261024-entity-consolidation-api-inventory/`.
2. Lập feature map (mỗi endpoint thuộc một tính năng) và call-site inventory bằng grep path trong `pte-web` (gồm `packages/api-client/src/requests/**`), `pte-app`, `pte-practice`; thêm danh sách script/README gọi API hoặc bảng: `pte-api/scripts/seed-local-exam-ready.ps1`, `seed-local-template-and-question-bank.ps1`, `seed-local-sample-class-students.ps1`, `seed-local-platform-roles.ps1`, `seed-plan-b.sh`, phần bootstrap SQL của `pte-api/README.md` (khoảng dòng 64–67).
3. Spike gate: `@DataJpaTest` chứng minh `SqlTypes.JSON` lưu/đọc được trên H2 `create-drop`, gồm danh sách record lồng nhau. Nếu thất bại, dùng `AttributeConverter<String>` làm phương án dự phòng và ghi tác động vào phase 4/5/9/11 trước khi tiếp tục.
4. Đo baseline số query của `next-task`, `answers`, `submit`: **dời sang đầu phase 8 (bước 0, trước khi sửa mã attempt)**. Lý do: mã attempt không đổi cho tới phase 8 và phép đo cần luồng thi đã seed (ca thi OPEN + attempt) mà phase 7 mới có; đo bằng Hibernate statistics trên mã cũ rồi lưu số liệu vào thư mục assets ở bước 1.
5. Quyết định 2026-10-24 (người dùng): giai đoạn phát triển KHÔNG duy trì Flyway. `db/migration` giữ nguyên 126 migration cho môi trường đã deploy (mặc định `ddl-auto: validate`); thêm profile `application-local-schema.yml` (Flyway tắt, `ddl-auto: update`, `defer-datasource-initialization`, `spring.sql.init` đọc `db/dev-seed/*.sql` với separator `@@`) và compose truyền `APP_SPRING_PROFILES` → `SPRING_PROFILES_ACTIVE`. `db/dev-seed/000-postgres-objects.sql` bổ sung những gì JPA không sinh (`btree_gist`, 2 function + 2 trigger, 3 view, exclusion constraint, partial unique index); `010-reference-data.sql` seed task type/runtime contract/score template/settings; `020-local-accounts.sql` seed `admin@test.local` (BCrypt hash). Flyway V1 chỉ sinh MỘT LẦN ở phase 11. `update` không chạy được trên DB do Flyway dựng (Hibernate 7 đòi nới cột `varchar(32)`→`255` và bị 3 view chặn) nên DB local phải dựng mới.
6. Triển khai bảng hạ tầng: `IdempotencyKey` (scope, key, request hash, trạng thái, result jsonb, expiresAt theo scope, unique scope+key+organizationId) cùng job dọn hết hạn; `OtpChallenge` thay `PracticeEmailChallenge` trong `PracticeEmailAuthService`; `MediaAsset` thay `MediaObject` (`MediaService`, `CloudinaryMediaService`, `MediaController`) giữ tên bảng/cột tương thích với cột tham chiếu media UUID publicId của Question, AttemptAnswer, PracticeSessionItem (liệt kê cột phụ thuộc bằng grep khi cook); mở rộng `AuditLog` (`shared/audit`) thêm actor, role, before/after state, requestPublicId, aggregateType/aggregateId, organizationId mà vẫn phục vụ `PlatformAuditLogController`.
7. Viết `local-dev-runbook.md` (trong thư mục plan): sao lưu DB cũ (`pg_dump`), drop/recreate DB `pte` (không đụng volume Caddy), đặt `APP_SPRING_PROFILES=local-schema` trong `.env.local`, build/chạy container `app`, kiểm `/actuator/health` UP và `POST /api/v1/auth/login` với từng tài khoản seed; cập nhật phần bootstrap trong `pte-api/README.md` trỏ tới seed dev; rà `seed-local-platform-roles.ps1`.
8. Chuyển test media/OTP sang entity mới; chạy compile, test toàn app, `ModuleStructureTest`, rồi gate Postgres.

## Success Criteria

- Inventory JSON, feature map, call-site inventory (kể cả script/README) tồn tại; số endpoint khớp mapping runtime; có roles, `/internal/**`, STOMP.
- Spike pass trên H2 (hoặc quyết định fallback đã ghi); baseline query count dời sang phase 8 (ghi lý do ở Steps).
- `db/migration` còn nguyên 126 migration; `ddl-auto` mặc định vẫn `validate`; profile `local-schema` + `db/dev-seed/*.sql` tồn tại (test `DdlAutoDefaultTest`).
- `MediaObject`, `PracticeEmailChallenge` không còn; `IdempotencyKey`, `OtpChallenge`, `MediaAsset`, `AuditLog` mở rộng có test hành vi.
- Gate dev DB (profile `local-schema`): từ `D:\GitHub\pte-org\pte-api`, DB `pte` trống trên Docker Postgres 17; `APP_SPRING_PROFILES=local-schema` trong `.env.local`; `docker compose --env-file .env.local -f docker-compose.yml -f docker-compose.services.yml up -d --no-deps --build app` khởi động (health UP) với Hibernate dựng schema, `db/dev-seed/*.sql` chạy xong, và `POST /api/v1/auth/login` thành công với `admin@test.local`. Ràng buộc chỉ Postgres phải có trong `db/dev-seed/000-postgres-objects.sql`. Không chạy được thì ghi "not verified", không bỏ qua im lặng.
- `.\mvnw.cmd -pl app -DskipTests compile`, `.\mvnw.cmd -pl app test`, `ModuleStructureTest` xanh; ghi số `@Entity` và số bảng do Hibernate dựng.

## Quality and Testing State

- Quality gate: approved (ck:quality --gate 2026-10-24: CHANGES_REQUIRED QUAL-001..004 → fixed → --verify APPROVED; report `quality/phase-01-foundation-spike-infra-quality-report.json`, receipt `quality/phase-01-foundation-spike-infra-receipt.json`)
- Testing: passed (tdd-verify 2026-10-24; full suite 2667 tests, 0 failures, 77 skipped pre-existing; see tests/phase-01-foundation-spike-infra-test-report.json)

## Risks

- Schema export không sinh đủ ràng buộc đặc biệt: đối chiếu từng đối tượng Postgres với `db/migration` (nay là nguồn tham chiếu) khi viết `000-postgres-objects.sql`.
- Rút Flyway cũ làm DB dev hiện có không boot: runbook nêu reset DB (đã được duyệt).
- Hash mật khẩu sinh sai encoder: kiểm bằng login ở gate.
