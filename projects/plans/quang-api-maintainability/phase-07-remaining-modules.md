# Phase 7: billing, identity, tenancy, media, practice

## Requirements

| File | Dòng | Hướng tách |
|---|---|---|
| `billing/internal/service/LicenseCodeService.java` | 596 | phát hành / đổi mã (redeem) / truy vấn & reveal |
| `billing/internal/service/PlanService.java` | 382 | CRUD + vòng đời (activate/archive/delete) + kiểm tra quyền lợi |
| `identity/internal/service/UserService.java` | 468 | tạo/cập nhật / trạng thái / truy vấn |
| `identity/IdentityService.java` (facade) | 377 | giữ chữ ký, thân sang `internal` |
| `media/internal/service/CloudinaryMediaService.java` | 423 | ký upload / hoàn tất & xác minh / presign đọc |
| `tenancy/internal/service/OrganizationLifecycleService.java` | 310 | suspend (impact digest) / reactivate / hết hạn |
| `practice/internal/service/PracticeSessionService.java` | 489 | tạo phiên / thao tác idempotent / truy vấn |
| `practice/internal/service/PracticeResponseService.java` | 309 | ghi câu trả lời / chấm qua scoring |

## Design Constraints

- Luồng IAM/onboarding: đọc `docs/TEST_SCENARIOS_IAM.md`; giữ nguyên các kịch bản xác minh.
- `LicenseCodeService` và `PlanService` có test Postgres race (`LicenseIssue*`, `ArchiveLifecycle*`): giữ khoá `findByPublicIdForUpdate` và thứ tự claim → lưu → complete của idempotency.
- Webhook PayOS (`PayOsWebhookService`) chỉ đổi `Clock` ở phase 2, không tách ở đây trừ khi > 300.

## Steps

1. Tách từng lớp, chạy test module sau mỗi lớp.
2. Gom `billing/internal/service` (16 file trước khi tách, ví dụ `license/`, `plan/`, `order/`), và các thư mục khác vượt 15 file sau khi tách.
3. Cập nhật allowlist.

## Success Criteria

- Tám file ≤ 300 dòng.
- Suite + 42 test Postgres xanh; Docker gate: đăng nhập hai tài khoản, phát hành/đổi license qua seed, practice tạo phiên được.

## Quality and Testing State

- Quality gate: not evaluated
- Testing: not started

## Risks

- `IdentityService` được nhiều module gọi: facade giữ nguyên để không lan sửa.
