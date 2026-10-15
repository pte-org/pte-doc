# Phase 2: Backend, migration và runtime consumers

Status: Implemented — focused gates passed; full suite retains a repository-level error  

## Requirements

Triển khai registry/validation ở `pte-api`, thêm setting nghiệp vụ được duyệt,
chuyển consumer cần dynamic read sang `PlatformSettingService` hoặc facade,
đồng thời ghi audit cho thay đổi.

## Design constraints

- Không cho phép cập nhật key ngoài registry hoặc key deprecated.
- Validate trước khi save; batch update phải atomic.
- Không ghi giá trị nhạy cảm vào audit hoặc response.
- Cache phải được invalidate sau single update và batch update.
- Không xoá dữ liệu setting cũ một cách destructive trong phase này; migration
  chỉ thêm/đánh dấu tương thích.

## Steps

1. Bổ sung typed `PlatformSettingDefinition` registry và service validation.
2. Mở rộng response DTO/API client contract với category, type, unit, range,
   default, scope, impact, editable, restart requirement và updatedAt.
3. Bổ sung idempotent migration/seed cho `tenant_application_response_sla_hours`
   với default 72; kiểm tra migration không duplicate row.
4. Thêm batch update transaction, validate toàn bộ payload trước persistence,
   trả lỗi theo key/field rõ ràng.
5. Nối SLA notification consumer với DB-backed runtime setting; giữ fallback
   an toàn trong migration/deploy transition nếu cần.
6. Thêm audit `PLATFORM_SETTING_UPDATED` sau khi thay đổi thành công; summary
   phải chứa key và giá trị đã chuẩn hóa, không chứa secret.
7. Đánh giá hai TTL billing và global cap theo effect semantics. Chỉ triển khai
   consumer/runtime read trong phase này nếu product decision đã chốt; nếu chưa,
   giữ chúng ngoài active registry.
8. Bổ sung service/controller tests cho role guard, allowlist, type/range,
   atomic batch, cache invalidation, SLA consumer và audit.

## Success criteria

- Unknown/deprecated/readonly key bị từ chối ở backend dù gọi direct API.
- `free_student_limit` và SLA được đọc đúng sau update mà không restart.
- Batch failure không làm thay đổi bất kỳ row nào trong batch.
- Audit có actor và old/new value an toàn.
- Migration chạy được trên database hiện tại và database mới.

## Quality/testing state

- Preflight: reuse existing `PlatformSettingService`, `AuditLogService`,
  `CurrentUserContext`, Flyway schema and notification module boundary; do not
  widen platform settings into deployment secrets or plan/session configuration.
- `pte-api` compile passed.
- Focused `PlatformSettingServiceTest`, `BillingSettingsServiceTest`,
  `TenantApplicationNotificationListenerTest` and
  `NotificationMigrationVersionTest` passed: `13/13`.
- Full backend run reported `2090` tests, `0` failures, `1` error and `56`
  skipped. The remaining error is the existing module-structure/H2 schema path
  outside this plan; no unrelated cycle or fixture repair was included.
- Cache invalidation, typed/range validation, atomic batch behavior, SLA
  fallback and notification consumer are covered by focused tests. Live
  database migration, HTTP authorization matrix and concurrency load were not
  run in this session.

## Risks

- Listener còn giữ `NotificationProperties` cũ khiến UI báo saved nhưng email
  không đổi.
- Scheduler payment dùng giá trị mới cho đơn cũ mà product chưa chấp thuận.
- Global cap thay đổi validation plan nhưng không thay đổi snapshot subscription;
  phải ghi rõ behavior trong response/error copy.
