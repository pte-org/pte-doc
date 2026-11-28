# Phase 3: WF-02 onboard tổ chức

**Owner gợi ý:** Ninh (lớp, tax code), Hùng (đơn hàng, bulk staff) · **Ưu tiên:** P1 (FR-08, FR-13), P2 (bulk staff, tax code) · **Phụ thuộc:** phase 01

## Overview

Không thêm được học viên vào lớp không ACTIVE. Đơn hàng PENDING hết hạn theo setting (demo ≤ 2 phút), Host hủy được đơn PENDING. Có endpoint tạo staff hàng loạt và mã số thuế được chuẩn hóa.

## Spec stories covered

- P1: Host không thêm học viên vào lớp không ACTIVE (FR-08, 2-2, F-06).
- P1: đơn hàng hết hạn ≤ 2 phút theo cấu hình demo, Host hủy đơn PENDING (FR-13, DS-02e).
- P2: Host tạo staff hàng loạt (FR-14, F-20, 2-3).
- P2: chuẩn hóa mã số thuế (2-6, DS-02b).

## Files to modify/create

Đọc trước: `docs/CODING_STANDARDS_API.md`, `docs/API_RESPONSE_SETUP.md`, `docs/COMMON_EXCEPTION_SETUP.md`, `docs/HOST_STUDENT_IMPORT_FLOW.md`, `docs/TEST_SCENARIOS_IAM.md`. Đường dẫn dưới `pte-api/app/src/main/`:

- `java/com/pte/enrollment/internal/service/ClassStudentService.java` — assign, bulkAssign, transfer, merge ném lỗi khi lớp đích không ACTIVE.
- `java/com/pte/enrollment/internal/service/ClassReorganizationService.java` — kiểm tra merge/transfer đi qua cùng guard (xác minh có đường riêng).
- `java/com/pte/enrollment/internal/constant/*Constants.java` — mã lỗi lớp không ACTIVE (xác minh tên file).
- `resources/db/migration/V62__billing_order_ttl_settings.sql` — tạo mới (kiểm lại số): seed platform setting TTL đơn hàng theo phút (giữ giá trị tương đương 24 giờ) và setting khoảng chạy cron nếu thiết kế dùng setting.
- `java/com/pte/billing/internal/service/order/OrderExpirationService.java` — hiện dùng `billing.order.pending-ttl-hours` và cron `0 0 * * * *`; đọc TTL từ setting (đơn vị phút) qua `billing/BillingSettingsService.java`; cron chuyển sang chạy mỗi phút, bản thân vòng quét rẻ nếu không có đơn quá hạn.
- `java/com/pte/billing/BillingSettingsService.java` — thêm getter TTL có fallback an toàn, tránh đọc setting chưa seed.
- `java/com/pte/billing/internal/service/order/OrderService.java` (dòng 85, 95 chặn `ORDER_PENDING_EXISTS`) — thêm cancel đơn PENDING của chính tổ chức; controller trong `billing/internal/controller/` (xác minh) và cập nhật `ApiInventoryExportTest`.
- `java/com/pte/billing/internal/constant/BillingConstants.java` — mã lỗi hủy đơn không hợp lệ.
- `resources/application.yml` (dòng 99-101) — giữ `BILLING_ORDER_PENDING_TTL_HOURS` làm giá trị mặc định ban đầu cho setting.
- `java/com/pte/identity/internal/controller/UserController.java` và `identity/internal/service/UserBulkCreateWriter.java` — thêm `POST /users/bulk-staff` (Proctor/Examiner), tái dùng provisioner và quota; không tạo lớp trùng với bulk student.
- `java/com/pte/tenancy/internal/service/OrganizationLifecycleService.java`, `tenancy/internal/dto/request/OnboardTenantRequest.java` — chuẩn hóa mã số thuế (bỏ ký tự phân tách) trước khi kiểm trùng; `TenantTaxCodeAlreadyUsedException` giữ nguyên. Cân nhắc dữ liệu cũ khi V55 đã có unique index.
- Web: `pte-web/apps/tenant-web` — nút hủy đơn PENDING ở màn billing và form bulk staff (xác minh thư mục feature).

## Implementation steps

1. Thêm guard lớp ACTIVE dùng chung cho assign/bulkAssign/transfer/merge, thông điệp rõ.
2. Seed platform setting TTL đơn hàng (phút) trong migration; đọc setting khi xét hết hạn, rơi về env cũ nếu thiếu.
3. Đổi lịch quét đơn hết hạn thành mỗi phút, giữ đường chuyển trạng thái và webhook-sau-hết-hạn hiện có.
4. Thêm endpoint Host hủy đơn PENDING (kiểm tenant, chỉ PENDING, ghi audit ở phase 07), cập nhật UI.
5. Thêm endpoint tạo staff hàng loạt theo cách của bulk student: validate cả file, quota, mật khẩu tạm, email.
6. Chuẩn hóa mã số thuế khi onboard và khi so trùng; viết quy tắc rõ trong thông điệp.
7. Cập nhật `ApiInventoryExportTest` / tài liệu endpoint nếu số endpoint đổi.

## Tests

Dưới `pte-api/app/src/test/java/com/pte/`:
- Tạo/mở rộng test cho `enrollment/internal/service/ClassStudentService` (tìm test hiện có): lớp INACTIVE bị từ chối ở cả bốn thao tác.
- Mở rộng `billing/internal/service/order/OrderExpirationServiceTest.java` — TTL theo phút từ setting, setting thiếu thì fallback.
- Mở rộng `billing/internal/service/order/OrderServiceTest.java` — hủy PENDING thành công, hủy đơn PAID/EXPIRED trả lỗi, hủy đơn tổ chức khác bị chặn, mua lại sau khi hủy thành công.
- Mở rộng `PayOsWebhookServiceTest.java` — đơn đã hủy/hết hạn nhận thanh toán vẫn xử lý theo đường hiện có (log hoàn tiền).
- Test bulk staff (controller + service): quota, trùng email, vai trò hợp lệ.
- Test chuẩn hóa tax code: `0101234567` và `0101-234-567` bị coi trùng.
- Test seed: dòng setting tồn tại sau migration (Postgres IT).

## Design Constraints

- Migration additive V62 (kiểm số cao nhất trong `db/migration`, hiện là V60 và phase 02 dự kiến V61); setting mới seed cùng migration vì đọc setting thiếu làm transaction rollback-only.
- Thông điệp/mã lỗi trong `*Constants.java` của module sở hữu; giữ envelope và mã lỗi cũ (`ORDER_PENDING_EXISTS`...).
- Cross-module chỉ qua public service API (enrollment, billing, identity, tenancy không chọc internals nhau); bulk staff dùng API công khai của identity.
- File ≤ 300 dòng, `internal/**` ≤ 15 lớp (ratchet architecture); `ClassStudentService` và `enrollment/internal/service` cần theo dõi.
- `Clock` inject cho hết hạn đơn hàng; không dùng `Instant.now()`.
- Không nới tenant boundary: hủy đơn và tạo staff luôn gắn tenant của caller; giữ hành vi import theo `HOST_STUDENT_IMPORT_FLOW.md`.
- Restart docker app local sau backend.

## Risks

- Cron mỗi phút gây tải hoặc hủy nhầm đơn đang thanh toán: bỏ qua đơn vừa cập nhật dưới ngưỡng và giữ đường webhook idempotent.
- Chuẩn hóa tax code làm đụng dữ liệu hiện có: chỉ chuẩn hóa dữ liệu mới và so khớp, không viết lại cột.
- Bulk staff mở lỗ quota: dùng đúng kiểm quota như tạo từng người.

## Quality and Testing State

- Quality gate: skipped_by_user (user_confirmed_skip)
- Testing: passed (2026-11-28: 172 related tests green; pre-existing ModuleStructureTest proctoring→session violation from 2930fe63 out of scope)

## Todo

- [ ] Guard lớp ACTIVE + test
- [ ] V62 seed setting TTL, đọc setting, cron mỗi phút
- [ ] Endpoint Host hủy đơn PENDING + UI + cập nhật inventory
- [ ] Endpoint bulk staff + test
- [ ] Chuẩn hóa tax code + test
- [ ] tsc/eslint/vitest cho tenant-web, ratchet architecture, restart docker
- [ ] Thử curl 2-2, DS-02e (tạo đơn, đợi hết hạn, mua lại)

## Bổ sung sau red-team (2026-11-27)

- **[M2] Guard lớp INACTIVE và Excel auto-placement:** auto-placement đã lọc ACTIVE (`ImportedStudentClassAssigner.java:65`).
  Guard áp cho assign/bulkAssign/transfer/merge thủ công. Thêm test import để chắc import không bị gãy.
- **[M1] TTL đơn hàng theo phút:** đơn vị setting là phút, UI admin nhận phút. Phase 08 có bước **trả TTL về 1440 phút và cron về giá trị cũ** sau demo.
  Banner admin hiện khi TTL < 60 phút.
- **[M1] Đơn đã EXPIRED/CANCELLED mà PayOS báo PAID:** giữ log và ghi audit `ORDER_PAID_AFTER_CLOSE` (phase 07). Nói rõ trong Q&A rằng hoàn tiền là thủ công, do Platform Admin xử lý.
- Audit cho thao tác hủy đơn nằm ở phase 07 (phase 03 chỉ gắn điểm gọi).
