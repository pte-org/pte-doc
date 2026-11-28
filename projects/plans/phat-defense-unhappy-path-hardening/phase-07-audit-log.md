# Phase 7: Audit log NFR-06

**Owner gợi ý:** Quang (rubric, chọn điểm, publish), Ninh (billing, import) · **Ưu tiên:** P1 · **Phụ thuộc:** làm song song được sau phase 01; rubric nên sau khi phase 01 đổi `RubricWorkflowPolicy`; audit của hủy đơn (phase 03) và đổi công tắc AI (phase 05) nhập vào đây khi các phase đó xong

## Overview

Mọi thao tác trong FR-09 ghi dòng audit qua `shared/audit/AuditLogService`, có test kiểm 100%. Bước đầu là xác minh chỗ nào đã có để không ghi trùng.

## Spec stories covered

- P1: auditor thấy payment PAID, license redeem/revoke/grant, student/staff import, rubric submit/reject/activate, chọn điểm, publish (FR-09, NFR-06, 1-14, 2-9).
- Bổ sung: đổi công tắc AI (FR-10) và Host hủy đơn (FR-13) có dòng audit.

## Files to modify/create

Đọc trước: `docs/CODING_STANDARDS_API.md`, `docs/COMMON_EXCEPTION_SETUP.md`. Đường dẫn dưới `pte-api/app/src/main/java/com/pte/`.

Kết quả xác minh ngày 2026-11-27 (Grep `AuditLogService`):

| Hành động | Hiện trạng | Việc cần làm |
|---|---|---|
| License issue | Có: `billing/internal/service/license/LicenseCodeIssuer.java` | Không |
| License grant | Có: `LicenseGrantService.java` (dòng ~179), lệch với báo cáo | Chỉ thêm test khẳng định |
| License reveal | Có: `LicenseCodeService.java` (dòng ~124) | Không |
| License redeem | Chưa có: `LicenseCodeRedeemer.java` | Thêm |
| License revoke | Chưa có: `LicenseCodeRevoker.java` | Thêm |
| Payment PAID (webhook) | Chưa có: `billing/internal/service/order/PayOsWebhookService.java` | Thêm, idempotent (replay không ghi trùng) |
| Student/staff import, bulk, đơn | Chưa có: `identity/internal/service/user/UserAccountProvisioner.java`; `UserService` có audit nhưng cần kiểm bulk | Thêm; một dòng tổng kết mỗi lần import |
| Rubric submit/reject | Chưa có: `scoring/internal/rubric/service/RubricVersionCommandService.java` và workflow | Thêm |
| Rubric activate | Ghi bảng riêng `scoring_rubric_activation_audits` | Thêm dòng audit chung; quyết định và ghi lại |
| Chọn điểm | Chưa có: `scoring/internal/service/selection/ScoreSourceSelectionService.java` | Thêm |
| Publish kết quả | Chưa có ở `reporting/internal/service/ReportPublishService.java` (`assessment/internal/service/SnapshotPublishService.java` là việc khác) | Thêm |
| Host hủy đơn (phase 03); đổi công tắc AI (phase 05) | Kiểm khi các phase đó xong | Thêm nếu thiếu |

Ngoài ra:
- `shared/audit/AuditLogService.java` — dùng API sẵn có (`record`, `recordFailure`); chỉ mở rộng nếu thiếu actor hệ thống cho webhook.
- Constants tên hành động: `billing/internal/constant/BillingConstants.java`, `scoring/internal/constant/ScoringConstants.java`, constants của identity và reporting (xác minh).
- Migration: không cần (dự kiến). Nếu có CHECK theo loại hành động thì thêm V66+ (kiểm số cao nhất).

## Implementation steps

1. Chạy lại Grep xác minh từng hàng bảng khi bắt đầu; cập nhật bảng nếu code đã đổi.
2. Thêm audit cho payment PAID, redeem, revoke; replay webhook không sinh dòng trùng.
3. Thêm audit cho provisioner (import/bulk/đơn), tóm tắt theo lần import; không ghi dữ liệu nhạy cảm như mật khẩu tạm.
4. Thêm audit cho rubric submit, reject, activate (khớp bảng audit riêng), chọn điểm, publish kết quả.
5. Dùng actor hệ thống rõ ràng cho webhook và sweeper; không ghi khi thao tác rollback.
6. Gom audit của hủy đơn và đổi công tắc AI nếu phase 03/05 chưa làm.
7. Viết test tổng hợp "100% hành động FR-09 có dòng audit"; xem dòng audit qua `shared/audit/internal/controller/AuditLogController.java` ở local.

## Tests

Dưới `pte-api/app/src/test/java/com/pte/`:
- Mở rộng `billing/internal/service/order/PayOsWebhookServiceTest.java` — PAID ghi một dòng, replay không ghi thêm.
- Test cho `LicenseCodeRedeemer`, `LicenseCodeRevoker` (tạo mới nếu chưa có), cộng test grant.
- Test provisioner/`UserService` cho import và bulk.
- Test rubric (submit, reject, activate), `ScoreSourceSelectionService`, `reporting/internal/service/ReportPublishServiceTest.java`.
- Một test tổng hợp NFR-06 liệt kê mọi hành động FR-09 và khẳng định có audit.
- Mở rộng `shared/audit/AuditLogServiceTest.java` nếu API đổi.

## Design Constraints

- Migration additive V61+ chỉ khi cần (kiểm số cao nhất, hiện V60); setting mới (nếu có) seed cùng migration.
- Tên hành động/thông điệp audit trong `*Constants.java` của module sở hữu; giữ envelope/mã lỗi cũ.
- Gọi `AuditLogService` qua public API của `shared`; tránh phụ thuộc vòng giữa billing, identity, scoring.
- File ≤ 300 dòng, `internal/**` ≤ 15 lớp (ratchet architecture); dùng helper audit nhỏ (mẫu `BlueprintAuditState`, `HostExamTemplateAudit`) thay vì nhồi vào service lớn.
- Thời gian dùng `Clock` đã có trong `AuditLogService`.
- Không ghi dữ liệu nhạy cảm (mật khẩu, mã license đầy đủ, token) vào audit.
- Restart docker app local sau backend.

## Risks

- Lỗi audit chặn nghiệp vụ: theo cách `AuditLogService` hiện dùng và test.
- Ghi trùng khi retry/replay: khóa theo id sự kiện, test idempotent.
- Service vượt 300 dòng khi thêm dependency: dùng helper nhỏ.

## Quality and Testing State

- Quality gate: skipped_by_user (user_confirmed_skip)
- Testing: passed (2026-11-28: 520 related tests, clean build; OrderController fixed to pass caller so host cancel is audited)

## Todo

- [ ] Xác minh lại bảng hiện trạng bằng Grep
- [ ] Payment PAID, redeem, revoke
- [ ] Import/bulk/provisioner
- [ ] Rubric submit/reject/activate, chọn điểm, publish
- [ ] Audit hủy đơn (phase 03) và đổi công tắc AI (phase 05)
- [ ] Test tổng hợp NFR-06, ratchet architecture, restart docker
