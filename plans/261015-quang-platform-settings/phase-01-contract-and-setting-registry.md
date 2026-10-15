# Phase 1: Contract và registry cho platform settings

## Requirements

Chốt allowlist, typed metadata, effect semantics và API contract trước khi mở
rộng consumer hoặc UI.

## Design constraints

- Chỉ `PLATFORM_ADMIN` được đọc/ghi platform settings.
- Không hiển thị arbitrary row trong `platform_settings`.
- Không đưa secret, deployment property hoặc feature flag restart-only vào
  registry editable.
- Giữ `GET /api/v1/settings`, `GET /api/v1/settings/{key}` và
  `PUT /api/v1/settings/{key}` tương thích ở mức cần thiết.
- `suspension_default_days` được đánh dấu deprecated/hidden, không đưa vào
  active catalog.

## Steps

1. Liệt kê toàn bộ current setting consumers trong `pte-api`, phân loại
   business DB-backed, deployment-only và resource-level.
2. Tạo registry/definition type cho key, category, type, unit, default, range,
   editable, restart requirement, scope và impact copy.
3. Chốt tên key cho SLA, payment TTL, pending-order TTL và global platform cap;
   không trùng với field cấu hình plan/session.
4. Chốt response metadata và batch request/response contract.
5. Chốt error catalog cho unknown key, readonly/deprecated key, invalid type,
   out-of-range value và batch validation failure.
6. Chốt audit event/action, summary format và quy tắc không ghi secret.
7. Ghi rõ effect semantics: immediate, future operations only, existing
   pending records hoặc requires restart.

## Success criteria

- Có catalog duy nhất cho active settings và các key hidden/deprecated.
- Mỗi active key có type, unit, default, min/max, scope và consumer cụ thể.
- Không còn quyết định UI nào phụ thuộc vào raw machine key.
- Batch contract và backward compatibility được ghi rõ.

## Quality/testing state

Decision/contract phase; chưa cần test runtime. Có thể thêm contract fixture
hoặc JSON example để phase 2 và phase 3 dùng chung.

## Risks

- Đặt key mới trùng với setting plan/session làm admin chỉnh nhầm phạm vi.
- Định nghĩa `requiresRestart=false` trong khi consumer vẫn inject property lúc
  startup.
- Đưa `suspension_default_days` vào catalog chỉ vì migration đã seed row.

Preflight: Backend giữ module boundary `controller → service → repository`,
mọi message/code mới nằm trong `BillingConstants`, response dùng `ApiResponse`,
và registry là allowlist typed thay vì mở rộng arbitrary key/value. Frontend sẽ
giữ feature constants/API hooks riêng và dùng component đã có của `@pte/ui`.
