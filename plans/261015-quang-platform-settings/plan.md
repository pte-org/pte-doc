# Plan: Mở rộng cài đặt nền tảng theo chính sách nghiệp vụ

Status: ✅ Complete — targeted gates passed; full suite retains a repository-level error  
Date: 2026-10-15  
Mode: Hard  
Test: default  
Owner/slug: Quang — `261015-quang-platform-settings`  
Scope: `pte-api`, `pte-web` (`vendor-web`, `packages/api-client`), `pte-doc`  
Related: [`quang-tenant-commercialization`](../../projects/plans/quang-tenant-commercialization/), [`261015-quang-platform-user-crud`](../261015-quang-platform-user-crud/)

## Mục tiêu

Biến màn hình **Cài đặt nền tảng** từ form key/value chỉ có hai dòng thành
một khu vực quản lý các chính sách nghiệp vụ nền tảng có kiểu dữ liệu, phạm vi
áp dụng, validation và audit rõ ràng.

Màn hình mới phải giúp `PLATFORM_ADMIN` hiểu một thay đổi ảnh hưởng đến đâu,
không để lộ machine key trong giao diện và không biến các secret hoặc cấu hình
deployment thành setting có thể sửa nhầm.

## Scope challenge

### Exists?

Có một nền tảng ban đầu:

- Vendor Web chỉ lọc và hiển thị `free_student_limit` và
  `suspension_default_days` trong `PlatformSettingsView`.
- API hiện có `GET /api/v1/settings`, `GET /api/v1/settings/{key}` và
  `PUT /api/v1/settings/{key}`.
- Database dùng một dòng cho mỗi setting trong `platform_settings`.
- `free_student_limit` được đọc khi duyệt hồ sơ tenant.
- `suspension_default_days` đã được seed nhưng chưa được nối vào nghiệp vụ
  suspend/expire tenant.

### Minimum?

Phạm vi nhỏ nhất để màn hình có giá trị và an toàn:

1. Tạo registry định nghĩa setting ở backend: category, type, unit, range,
   default, scope và khả năng chỉnh sửa.
2. Chuẩn hóa `free_student_limit` thành setting số nguyên có metadata và giữ
   tương thích endpoint hiện tại.
3. Thêm `tenant_application_response_sla_hours` để cấu hình SLA nghiệp vụ
   dùng trong email phản hồi hồ sơ tenant.
4. Ẩn/đánh dấu deprecated `suspension_default_days` cho đến khi có model
   `suspended_until` và cơ chế tự hết hạn.
5. Bổ sung API client và Vendor Web theo nhóm **Thương mại & phê duyệt**,
   với label thân thiện, đơn vị, hiệu lực và một thao tác lưu cho mỗi nhóm.
6. Ghi audit cho thay đổi setting và bổ sung validation/backend tests.

Thời hạn thanh toán, giới hạn tối đa phiên thi và các setting bảo mật được
đưa vào phase sau vì cần quyết định rõ về hiệu lực đối với dữ liệu hiện có.

### Complexity?

Hard — thay đổi chạm billing runtime, notification runtime, API contract,
cache, migration, audit và Vendor Web. Nếu chỉ thêm các row mới mà không có
typed registry, backend vẫn chấp nhận giá trị tùy ý và UI sẽ tiếp tục phụ thuộc
vào machine key.

## Current source evidence

- [`PlatformSettingsView`](../../../pte-web/apps/vendor-web/features/commercialization/components/PlatformSettingsView.tsx)
  đang hard-code danh sách hai key và tạo một form/save button cho từng key.
- [`PlatformSetting`](../../../pte-api/app/src/main/java/com/pte/billing/domain/PlatformSetting.java)
  chỉ lưu `key`, `value`, `description`; `BaseEntity` đã có `createdAt` và
  `updatedAt` nhưng chưa có metadata kiểu dữ liệu hay actor cập nhật.
- [`PlatformSettingService`](../../../pte-api/app/src/main/java/com/pte/billing/internal/service/PlatformSettingService.java)
  đang cache đọc và cập nhật value dạng chuỗi; validation số nguyên hiện chỉ
  nằm ở `getInteger` của caller.
- [`V22__billing_plan_catalog.sql`](../../../pte-api/app/src/main/resources/db/migration/V22__billing_plan_catalog.sql)
  seed hai setting hiện tại.
- `free_student_limit` được dùng trong `TenantApplicationService` khi duyệt
  tenant; thay đổi không hồi tố giới hạn đã cấp cho tenant trước đó.
- `suspension_default_days` chưa có consumer nghiệp vụ; `TenantLifecycleService`
  chỉ chuyển trạng thái và `Tenant` chưa có trường thời điểm hết hạn tạm ngưng.
- `tenant_application_response_sla_hours` hiện là deployment property được
  dùng trong email phản hồi hồ sơ; khi chuyển vào database, listener phải đọc
  setting runtime thay vì giữ một giá trị chỉ nạp lúc startup.
- `paymentLinkTtlHours`, `pending order TTL` và `MAX_STUDENT_COUNT` đang là
  cấu hình/constants có consumer thật nhưng có tác động rộng hơn và cần phase
  riêng.

## Product decisions

1. Chỉ `PLATFORM_ADMIN` được xem và thay đổi platform settings; frontend guard
   không phải security boundary.
2. Màn hình chỉ hiển thị setting nghiệp vụ được allowlist. Không hiển thị toàn
   bộ row trong bảng `platform_settings`.
3. `free_student_limit` là số nguyên không âm, đơn vị học viên, áp dụng cho
   các tenant được duyệt sau thời điểm lưu.
4. `tenant_application_response_sla_hours` là số nguyên dương, đơn vị giờ,
   mặc định hiện tại là 72; chỉ ảnh hưởng các thông báo tạo sau khi thay đổi.
5. `suspension_default_days` không hiển thị trong V1 của màn hình mới. Không
   gọi nó là setting đang hoạt động khi backend chưa có expiry semantics.
6. Giá, thời hạn gói, capacity/session và extra slots tiếp tục thuộc Plan
   Catalog; cửa sổ thi, retry, mode và thời lượng tiếp tục thuộc Exam/Session.
7. Secret, credential, endpoint, CORS, scheduler, retry nội bộ, rate limit kỹ
   thuật và private key không được chuyển thành input platform settings.
8. Thay đổi có ảnh hưởng rộng phải hiển thị impact copy và ghi audit gồm actor,
   key, giá trị trước/sau đã chuẩn hóa; không ghi secret.

## Setting catalog

| Key | Nhóm | Kiểu | Trạng thái/hiệu lực | Phase |
|---|---|---|---|---|
| `free_student_limit` | Thương mại & phê duyệt | `INTEGER` | Đang dùng thật; áp dụng cho tenant approval mới | 1–3 |
| `tenant_application_response_sla_hours` | Thương mại & phê duyệt | `DURATION_HOURS` | Đang là env; cần chuyển consumer sang DB runtime | 2–3 |
| `payment_link_ttl_hours` | Thanh toán | `DURATION_HOURS` | Đang là PayOS property; thay đổi ảnh hưởng link tạo mới | 2, sau khi chốt nghiệp vụ |
| `pending_order_ttl_hours` | Thanh toán | `DURATION_HOURS` | Đang là scheduler property; ảnh hưởng đơn pending đang tồn tại | 2, sau khi chốt nghiệp vụ |
| `platform_max_students_per_session` | Giới hạn nền tảng | `INTEGER` | Thay thế cách dùng trực tiếp `MAX_STUDENT_COUNT` chỉ sau khi chốt tác động plan | 2, protected |
| `suspension_default_days` | — | `INTEGER` | Deprecated/hidden; chưa có consumer | Không hiển thị V1 |

## Phân loại cấu hình

### DB-backed business settings

Được quản lý qua màn hình này khi có registry, validation và consumer runtime:

- free student limit;
- SLA phản hồi hồ sơ tenant;
- payment/order TTL sau khi chốt tác động;
- giới hạn nghiệp vụ toàn nền tảng sau khi có confirmation phù hợp.

### Deployment/operations settings

Tiếp tục ở environment/config file hoặc một operations console riêng:

- database, Redis, RabbitMQ, CORS và origin;
- PayOS credentials, Cloudinary credentials, RSA key, AI provider key;
- scheduler poll interval, retry internals, rate limit kỹ thuật;
- feature flags cần restart hoặc chưa có cơ chế dynamic refresh.

### Resource-level settings

Không lặp lại trên platform settings:

- plan price, currency, duration, max students/session, extra slots;
- exam/session capacity, schedule window, exam mode, retry và time policy;
- practice catalog/session time limit;
- tenant organization profile và white-label branding.

## Architecture decisions

### AD-01: Typed registry, không expose arbitrary key/value

Tạo registry backend cho các key được hỗ trợ. Mỗi definition tối thiểu có:

```text
key, category, type, label, description, defaultValue,
unit, min, max, editable, requiresRestart, scope, impact
```

`PlatformSettingService` chỉ đọc/ghi các key có definition và validate theo
definition trước khi chạm database. Row lạ hoặc deprecated không được trả về
UI editable.

### AD-02: Giữ storage row-per-setting và backward compatibility

Không tạo một column cho từng setting. Giữ `platform_settings` dạng một row
cho mỗi key, thêm migration seed idempotent cho key mới và giữ endpoint single
key hiện tại để tránh phá caller cũ.

### AD-03: Bulk update theo nhóm

Giữ `PUT /api/v1/settings/{key}` cho tương thích. Bổ sung một endpoint batch
transactional cho Vendor Web; backend validate toàn bộ payload trước khi lưu,
không để một nhóm được lưu một phần.

### AD-04: Consumer phải đọc runtime setting

Các property chuyển từ env sang DB chỉ được đưa lên UI sau khi consumer đọc qua
facade/service runtime. Không thêm row database rồi giả định consumer tự động
nhận giá trị mới.

### AD-05: Audit mọi thay đổi

Thay đổi thành công ghi `PLATFORM_SETTING_UPDATED` với aggregate type ổn định,
key, actor và summary không chứa secret. Có thể ghi failure cho update bị từ
chối nếu phù hợp với convention audit hiện tại.

### AD-06: UI theo ngôn ngữ nghiệp vụ

Không hiển thị `FREE_STUDENT_LIMIT` hoặc `SUSPENSION_DEFAULT_DAYS` làm label.
Dùng component hiện có của `@pte/ui`: `PageHeader`, panel/section, `FormField`,
`Input`, `FormActions`, `Alert`, `Toast` và trạng thái loading/error.

## API contract

### Existing contract to preserve

| Capability | Endpoint | Ghi chú |
|---|---|---|
| List | `GET /api/v1/settings` | Vẫn hỗ trợ caller hiện tại; response mới có metadata |
| Detail | `GET /api/v1/settings/{key}` | Chỉ trả key hợp lệ hoặc lỗi rõ ràng |
| Single update | `PUT /api/v1/settings/{key}` | Giữ backward compatibility, dùng typed validation |

### New contract

| Capability | Endpoint | Payload/result |
|---|---|---|
| Batch update | `PUT /api/v1/settings/batch` | `{ settings: [{ key, value }] }`, validate atomic |

Response nên mở rộng từ chuỗi thuần thành metadata có thể render:

```text
publicId
key
category
type
value
defaultValue
unit
min
max
description
editable
requiresRestart
scope
impact
updatedAt
```

Actor chi tiết được truy từ audit log; không bắt buộc nhồi display name vào
setting response ở phase đầu.

## Phases

| Phase | Nội dung | Phụ thuộc |
|---|---|---|
| 01 | Contract, registry, allowlist và quyết định hiệu lực | Không |
| 02 | Backend, migration, runtime consumers và audit | Phase 01 |
| 03 | API client và Vendor Web settings UX | Phase 02 |
| 04 | Verification, migration review và handoff | Phase 01–03 |

Chi tiết nằm trong các file phase cùng thư mục.

## Cook progress

- [x] Phase 01: Contract, registry, allowlist và quyết định hiệu lực.
- [x] Phase 02: Backend, migration, runtime consumer SLA và audit.
- [x] Phase 03: API client và Vendor Web settings UX.
- [x] Phase 04: Automated verification, diff review và handoff evidence.
- [x] Human confirmation để chuyển plan sang trạng thái hoàn tất — received 2026-10-15.

## Acceptance criteria

- `GET /api/v1/settings` trả đúng các setting được allowlist và metadata typed;
  không trả raw secret/env config.
- `PLATFORM_ADMIN` có thể cập nhật `free_student_limit` với giá trị hợp lệ;
  giá trị sai type, âm hoặc vượt range bị từ chối ở backend.
- Thay đổi `free_student_limit` chỉ ảnh hưởng tenant approval mới và không làm
  thay đổi snapshot/giới hạn của tenant đã cấp trước đó.
- Sau khi cập nhật SLA, email hồ sơ tenant mới dùng giá trị DB mà không cần
  restart ứng dụng.
- Batch update validate toàn bộ trước khi lưu; khi một field lỗi, không field
  nào trong batch bị thay đổi.
- Mỗi update thành công có audit row với actor, key, old/new value an toàn và
  timestamp; không có secret trong response, audit hoặc log.
- `suspension_default_days` không xuất hiện như một setting đang hoạt động;
  không có UI copy hứa hẹn tự hết hạn tạm ngưng.
- Vendor Web chia setting theo nhóm, dùng label/đơn vị nghiệp vụ, có loading,
  error, empty/deprecated state và một action lưu ở cấp nhóm.
- UI không duplicate plan, exam/session, tenant profile hoặc deployment
  settings hiện có.
- API client types, Vendor Web typecheck/lint/build và backend focused tests
  pass; diff không chứa conflict marker/generated artifact ngoài scope.

## Risks

- **HIGH:** setting vẫn lưu được nhưng consumer tiếp tục đọc env/cache cũ —
  bắt buộc test runtime sau khi update và ghi rõ cache invalidation.
- **HIGH:** bulk update lưu một phần — dùng transaction và validate trước khi
  persist.
- **HIGH:** thay đổi payment/order TTL làm xử lý sai đơn đang pending — cần
  confirmation về hiệu lực đối với dữ liệu tồn tại trước khi bật UI.
- **MEDIUM:** arbitrary key hoặc description khiến admin thay đổi config không
  được hỗ trợ — backend registry phải là allowlist.
- **MEDIUM:** admin hiểu setting global là hồi tố — mọi field phải có scope/effect
  copy và test acceptance tương ứng.
- **LOW:** UI quá dài khi thêm nhóm tương lai — chỉ render category có setting
  supported, không tạo tab rỗng cho Security/Data retention/Feature flags.

## Out of scope

- Dynamic feature flag console.
- Chỉnh secret, credential, encryption key hoặc integration endpoint.
- Chính sách password/token trong màn hình thương mại.
- Audit retention/purge trước khi có policy dữ liệu riêng.
- Triển khai expiry cho tenant suspension trong plan này.
- Thay đổi plan catalog, exam/session settings hoặc tenant profile.

## Quality and handoff

- Các phase giữ thay đổi theo repo: backend ở `pte-api`, contract/API client và
  UI ở `pte-web`, evidence/plan ở `pte-doc`.
- Không merge, push hoặc deploy trong quá trình cook nếu chưa có yêu cầu riêng.
- Handoff phải ghi rõ command đã chạy, test pass/fail, migration được kiểm tra,
  runtime evidence và các giới hạn chưa kiểm chứng.

### Cook evidence — 2026-10-15

- `pte-api`: compile pass; focused billing/notification/migration tests pass
  `13/13`; full backend run có `2090` tests, `0` failure, `1` error và `56`
  skipped. Error còn lại thuộc module-structure/H2 schema path đã tồn tại
  ngoài phạm vi platform settings; không tự sửa dependency cycle hoặc fixture
  schema của module khác.
- `pte-web`: `@pte/api-client` typecheck, `vendor-web` typecheck và build pass;
  Vendor Web lint có `0` error và `2` warning `<img>` có sẵn ở question bank.
  Production build tạo đủ `23` static pages.
- Diff review: `git diff --check` và kiểm tra conflict marker pass ở hai repo;
  không có commit, push hoặc deploy trong cook này.
- Migration `V101__platform_setting_catalog.sql` đã được review theo schema
  `platform_settings`, dùng insert idempotent và đủ các cột bắt buộc. Chưa chạy
  migration trên database live hoặc HTTP/browser role matrix trong session này.
- P2 `payment_link_ttl_hours`, `pending_order_ttl_hours` và global platform cap
  vẫn ngoài active catalog vì chưa có product decision về effect semantics.
- Native `ck:cook`/`ck:quality` executable không có trong môi trường; quality
  review được thực hiện thủ công theo coding standards và quality skill, không
  tạo receipt giả.

## Next command after decisions

```text
/ck:cook --hard plans/261015-quang-platform-settings/plan.md
```
