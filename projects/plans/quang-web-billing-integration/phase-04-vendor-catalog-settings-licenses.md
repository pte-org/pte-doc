# Phase 4: vendor-web — catalog gói, tham số nền tảng, mã kích hoạt

## Requirements

Ba màn hình còn lại của vendor-web: `PlanCatalogView` (CRUD gói + activate/archive), `PlatformSettingsView` (đọc/ghi tham số), `LicenseCodesView` (phát/thu hồi mã).

Xoá `DEMO_PLANS`, `DEMO_LICENSE_CODES`.

Maps to: **[ADR-006](../../architecture/ADR-006-commercialization-and-exam-templates.md) §1, §7, §8**

## Design Constraints

- **Form gói phải đổi trường theo `type`.** `EXAM_PACKAGE` cần `durationDays` + `maxStudentsPerSession`, cấm `extraStudentSlots`; `STUDENT_CAPACITY` ngược lại. Backend trả 422 nếu lẫn lộn. Form hiện đúng nhóm trường theo `type` đang chọn — để người dùng nhập rồi mới báo lỗi là thiết kế tệ khi đã biết trước luật.

- **`DRAFT → ACTIVE` một chiều, `ACTIVE → ARCHIVED` một chiều.** Không có đường quay lại. Nút phải phản ánh đúng: gói `ARCHIVED` không còn nút nào, gói `ACTIVE` chỉ còn `archive`. Xác nhận trước khi archive vì không hoàn tác được.

- **Archive không ảnh hưởng `Subscription` đã bán** — đó là lý do Phase 4 backend snapshot cap thay vì đọc live. Modal xác nhận nên nói rõ điều này, tránh admin tưởng archive sẽ cắt gói của khách.

- **Mã kích hoạt là bearer token.** Ai cầm mã thì kích hoạt được. Hiển thị mã đầy đủ chỉ ở thời điểm vừa phát; trong bảng danh sách thì che bớt hoặc để sau một hành động rõ ràng. Không log mã ra console.

- **Thu hồi mã đã `REDEEMED` sẽ huỷ luôn `Subscription`** sinh ra từ nó, kéo theo huỷ các kỳ thi `SCHEDULED` của làn đó. Modal xác nhận phải nêu hệ quả này — đây không phải thao tác nhẹ.

- **`PlatformSetting` là key-value, giá trị là chuỗi.** `free_student_limit` và `suspension_default_days` mang nghĩa số nhưng lưu chuỗi. Validate ở client theo key (số không âm), và hiểu rằng backend cũng validate lại.

## Steps

### Catalog gói

1. Thêm vào `features/commercialization/api.ts`: `usePlansQuery` (admin), `useCreatePlanMutation`, `useUpdatePlanMutation`, `useActivatePlanMutation`, `useArchivePlanMutation`. Mọi mutation invalidate `["admin", "plans"]`.

2. `PlanCatalogView.tsx`: thay `DEMO_PLANS` bằng query thật, thêm loading/error/empty.

3. `PlanFormModal` (mới hoặc tách từ view hiện có): chọn `type` trước, form đổi nhóm trường theo lựa chọn. Validate client:
   - `EXAM_PACKAGE`: `durationDays > 0`, `maxStudentsPerSession > 0`
   - `STUDENT_CAPACITY`: `extraStudentSlots > 0`
   - `price >= 0`, `currency` 3 ký tự

4. Định dạng hiển thị nằm ở component, không ở type: `durationDays: 30` → `"30 ngày"`, `price` + `currency` → chuỗi tiền tệ. Đưa hàm định dạng vào `utils/`, không nhúng trong JSX.

5. Nút `activate` chỉ hiện với `DRAFT`; `archive` chỉ hiện với `ACTIVE`; `ARCHIVED` không có nút. Modal xác nhận archive nêu rõ: gói đã bán **không** bị ảnh hưởng.

### Tham số nền tảng

6. `usePlatformSettingsQuery`, `useUpdateSettingMutation`.

7. `PlatformSettingsView.tsx`: bảng key/value/description, sửa tại chỗ hoặc qua modal. Validate theo key trước khi gửi.

8. Hiện `description` của từng tham số — admin cần biết `free_student_limit` ảnh hưởng gì trước khi đổi.

### Mã kích hoạt

9. `useLicenseCodesQuery`, `useIssueLicenseCodeMutation`, `useRevokeLicenseCodeMutation`.

10. `LicenseCodesView.tsx`: thay `DEMO_LICENSE_CODES`. Bảng hiện mã, gói, trạng thái, ngày phát, hạn redeem, tenant đã redeem (nếu có).

11. Modal phát mã: chọn gói từ danh sách gói `ACTIVE` (dùng lại query ở bước 1, lọc client), chọn hạn redeem. Sau khi phát, hiện mã đầy đủ kèm nút sao chép.

12. Modal thu hồi: bắt buộc nhập lý do. Với mã `REDEEMED`, thêm cảnh báo rõ: sẽ huỷ `Subscription` và các kỳ thi `SCHEDULED` thuộc làn đó.

13. Xoá `DEMO_PLANS`, `DEMO_LICENSE_CODES`. Dọn `types.ts` khỏi các type trùng với `api-client`.

## Success Criteria

- Tạo gói `EXAM_PACKAGE` mà điền `extraStudentSlots` → form chặn từ client, không cần đợi 422
- Gói `DRAFT` → `ACTIVE` → xuất hiện ở `/api/v1/plans` (kiểm bằng tài khoản tenant)
- Archive gói → biến mất khỏi danh sách tenant, vẫn còn trong danh sách admin
- Đổi `free_student_limit` → duyệt một đơn mới → tenant nhận đúng hạn mức mới
- Phát mã → mã hiện đầy đủ một lần, sao chép được
- Thu hồi mã đã redeem → modal cảnh báo hệ quả trước khi cho bấm
- Không còn `DEMO_PLANS`/`DEMO_LICENSE_CODES` trong codebase
- Không file nào vượt 300 dòng, không component nào vượt 150 dòng

## Quality and Testing State

- Quality gate: APPROVED — inline quality audit; no blocking findings.
- Testing: PASSED — vendor-web typecheck, lint, and production build.

## Session Notes

## Cook result — 2026-09-17

- Implementation and quality gate: `APPROVED`.
- Vendor plans, settings, and license codes use real API hooks; revoke is confirmed; typecheck, lint, and build pass.

_(trống)_
