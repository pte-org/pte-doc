# Phase 3: Catalog gói & tham số nền tảng

## Requirements

Admin nền tảng tạo và quản lý catalog gói (`Plan`). Hai họ gói với cơ chế hoàn toàn khác nhau: `EXAM_PACKAGE` (có hạn, cap sinh viên mỗi kỳ thi) và `STUDENT_CAPACITY` (vĩnh viễn, cộng vào hạn mức tài khoản). Thêm `PlatformSetting` cho tham số toàn hệ.

Maps to: **[ADR-006](../../architecture/ADR-006-commercialization-and-exam-templates.md) §1**

## Design Constraints

- **Hai họ gói tách biệt hoàn toàn.** Hết hạn gói thi không làm mất chỗ sinh viên đã mua, và ngược lại. Không gộp chúng vào một cơ chế "credit" chung.
- `STUDENT_CAPACITY` **không sinh `Subscription`** — nó ghi vào `tenancy.QuotaTransaction` đã có sẵn. **Không tạo bảng mới cho việc này.**
- `Plan` có `ARCHIVED` chứ không xoá. Archive **không được** ảnh hưởng `Subscription` đã bán — đó là lý do Phase 4 snapshot cap thay vì đọc live.
- Trường theo họ gói: `durationDays` + `maxStudentsPerSession` chỉ có nghĩa với `EXAM_PACKAGE`; `extraStudentSlots` chỉ có nghĩa với `STUDENT_CAPACITY`. Validate theo `type`, không để null lẫn lộn.
- `PlatformSetting` là bảng key-value một dòng một tham số, không phải một entity với 20 cột — tham số sẽ còn thêm.
- Preflight: Billing follows the monolith convention of internal controllers/services/repositories with DTOs and user-facing error constants owned by the module; cross-module calls use public facades, IDs exposed as `BaseEntity.publicId`, and class-level `@PreAuthorize`. The existing API uses root-level routes (no `/api` prefix), so this phase maps the plan catalog to `/admin/plans`, `/plans`, and `/admin/settings`. No cache starter is present, so setting reads will use a local cache with write invalidation.

## Steps

1. Enum `PlanType` (`EXAM_PACKAGE`, `STUDENT_CAPACITY`) và `PlanStatus` (`DRAFT`, `ACTIVE`, `ARCHIVED`) trong `billing/domain/enums/`.

2. Entity `Plan`: `name`, `description`, `type`, `price`, `currency`, `durationDays`, `maxStudentsPerSession`, `extraStudentSlots`, `status`.

3. Entity `PlatformSetting`: `key` (unique), `value`, `description`. Seed hai dòng trong migration:
   - `free_student_limit` — hạn mức sinh viên miễn phí khi tenant mới được duyệt
   - `suspension_default_days` = `0` — đình chỉ không tự hết hạn (Phase 13)

4. Migration `V16__billing_plan_catalog.sql` + seed `PlatformSetting`.

5. `PlanService`: CRUD cho `PLATFORM_ADMIN`. Validate theo `type`:
   - `EXAM_PACKAGE` → `durationDays > 0` và `maxStudentsPerSession > 0` bắt buộc, `extraStudentSlots` phải null
   - `STUDENT_CAPACITY` → `extraStudentSlots > 0` bắt buộc, hai trường kia phải null
   - Sai → 422 nói rõ trường nào thừa/thiếu

6. Chuyển `Plan` sang `ACTIVE` chỉ từ `DRAFT`; `ARCHIVED` là một chiều, không quay lại.

7. `PlatformSettingService`: đọc có cache (giá trị đổi rất hiếm), ghi chỉ `PLATFORM_ADMIN`. Đọc một key không tồn tại là lỗi cấu hình → ném exception rõ ràng lúc gọi, không trả default ngầm.

8. Sửa Phase 2: `TenantApplicationService.approve()` đọc `free_student_limit` từ `PlatformSetting` thay cho hằng số tạm.

9. Controller: `/api/admin/plans` (CRUD, `PLATFORM_ADMIN`), `/api/plans` (chỉ liệt kê `ACTIVE`, tenant đọc được), `/api/admin/settings`.

10. Test: tạo Plan sai họ (ví dụ `EXAM_PACKAGE` mà điền `extraStudentSlots`) → 422.

11. Test: archive một Plan → không còn xuất hiện ở `/api/plans` nhưng vẫn đọc được bằng id.

## Success Criteria

- Admin tạo được cả hai họ gói, validate chặn đúng trường sai họ
- Tenant chỉ thấy gói `ACTIVE`
- `free_student_limit` đổi được và tenant duyệt sau đó nhận hạn mức mới
- Archive không xoá dữ liệu, không ảnh hưởng gì đang chạy
- Không có bảng mới nào cho gói mở rộng sinh viên — `QuotaTransaction` là nơi duy nhất

## Quality and Testing State

- Checkpoint: Unit tests = yes; Quality gate = yes (Mode Hard default)
- Quality gate: **approved**, inline senior audit found 0 blocking/advisory/noted findings. Report: `quality/phase-03-plan-catalog-quality-report.json`. Cryptographic receipt skipped because the plan/report lives in `pte-doc` while reviewed source/test files live in the separate `pte-api` repository; this is recorded in the report.
- Testing: **passed**, `.\mvnw.cmd -pl app test` completed with 511/511 tests passing, including 19 Phase 3/billing tests. Report: `tests/phase-03-plan-catalog-test-report.json`.

## Session Notes

Implemented 2026-09-16.

- Added the two-family `Plan` catalog with common DTOs, repository, mapper, service, and admin lifecycle endpoints. `EXAM_PACKAGE` requires positive `durationDays` and `maxStudentsPerSession` and forbids `extraStudentSlots`; `STUDENT_CAPACITY` requires positive `extraStudentSlots` and forbids the exam-only fields. Invalid family fields return HTTP 422 through `PlanValidationException`.
- Added explicit DRAFT -> ACTIVE activation and one-way archive transitions. Admin reads include archived plans by public ID; `/plans` queries ACTIVE only. Admin routes are `/admin/plans`; the repository convention has no `/api` prefix even though the original phase text names `/api/admin/plans` and `/api/plans`.
- Added `PlatformSettingService` with process-local cached reads, eviction on writes, explicit missing/invalid configuration errors, and `/admin/settings` restricted to `PLATFORM_ADMIN`. Seeded `free_student_limit=50` and `suspension_default_days=0` in `V16__billing_plan_catalog.sql`.
- Updated tenant application approval to read `free_student_limit` from `PlatformSettingService`; the regression test changes the setting to 75 to prove the old temporary constant is no longer used.
- Full app tests passed. Docker was unavailable in this environment, so V16 was not applied against a live Postgres instance; SQL/schema alignment was reviewed against the existing Flyway/JPA conventions.
