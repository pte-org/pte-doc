# Phase 01: Hạ tầng chụp trạng thái và API đọc

Repo: `pte-api`. Trạng thái: **xong (2026-11-25)**.

## Mục tiêu

Có một cách thống nhất để module ghi trạng thái trước/sau, và API để vendor-web đọc theo người, theo đối tượng, và xem chi tiết.

## Việc cần làm

### Ghi

1. `shared/audit`: thêm `AuditStateSerializer` (hoặc phương thức trong `AuditLogChangeWriter`) nhận `Object` trạng thái và trả JSON:
   - `ObjectMapper` có `ORDER_MAP_ENTRIES_BY_KEYS`, bỏ field null.
   - Giới hạn `AuditLogConstants.STATE_MAX_CHARS`; vượt thì lưu `{"truncated":true,"preview":...}`.
   - Lỗi serialize: trả `null`, log WARN (không có dữ liệu nhạy cảm trong log), không ném lỗi.
2. Overload `AuditLogChangeWriter.record(caller, aggregateType, aggregateId, resourceName, resourceCode, action, summary,
   Object before, Object after)` để module không tự dựng JSON. `requestPublicId` lấy từ request hiện tại nếu có.
3. Giữ `AuditLogService.record(...)` cho thao tác không có trạng thái (ví dụ submit, approve).

### Đọc

4. `GET /api/v1/platform/audit-logs`: thêm `actorId` (UUID, tùy chọn) và `aggregateId` (tùy chọn). Kết hợp AND với bộ lọc cũ.
   Thêm index nếu cần: kiểm tra `EXPLAIN` trên `(actor_user_id, created_at)` và `(aggregate_type, aggregate_id, created_at)`;
   chỉ thêm migration `V58__audit_logs_actor_aggregate_index.sql` khi bảng local cho thấy seq scan.
5. `AuditLogResponse`: thêm `actorRole` và `hasStateChange` (boolean), **không** thêm trước/sau.
6. `GET /api/v1/platform/audit-logs/{publicId}`: trả `AuditLogDetailResponse` gồm các field trên cộng `beforeState`,
   `afterState` (JSON object, không phải chuỗi). Không tìm thấy hoặc là dòng của tenant: `404` theo `COMMON_EXCEPTION_SETUP.md`,
   mã lỗi trong `AuditLogConstants`.
7. Quyền: giữ `@PreAuthorize("hasAnyRole('PLATFORM_ADMIN','PLATFORM_MANAGER')")`. Endpoint tenant `/api/v1/audit-logs` và
   `recent()` không thay đổi và không lộ trước/sau.

## Tiêu chí hoàn thành

- Unit test serializer: thứ tự key ổn định, cắt khi quá dài, lỗi serialize không ném.
- Controller test: lọc `actorId`, `aggregateId`; chi tiết trả trước/sau; tenant user nhận 403; dòng tenant qua endpoint platform trả 404.
- `ApiInventoryExportTest` cập nhật (thêm 1 endpoint).
- Ratchet kiến trúc vẫn xanh.
