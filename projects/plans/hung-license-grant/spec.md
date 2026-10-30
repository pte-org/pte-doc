# Spec: Admin cấp gói theo hợp đồng (thay luồng Host nhập mã)

**Date:** 2026-10-29
**Status:** Ready
**Nguồn:** [Brainstorm](../reports/261029-hung-license-grant-brainstorm.md) · [Đề xuất gốc](../reports/261029-hung-license-grant-renewal.md)
**Repo:** pte-api (billing, session, tenancy), pte-web (vendor-web, tenant-web, api-client)
**Cập nhật 2026-10-30:** thêm phần *Admin tạo tenant trực tiếp* (FR-15 → FR-18). Lý do: form tạo tenant cũ có ô Plan chỉ là nhãn (không tạo gói), hạn mức nhập tay đi vòng qua `freeStudentLimit`, và không tạo tài khoản Host.

---

## Problem Statement

Tổ chức ký hợp đồng trực tiếp hiện phải đi đường vòng: Admin phát mã, tự gửi mã ra ngoài hệ thống, rồi Host vào trang *Redeem* nhập mã. Cách này dễ gửi nhầm người hoặc lộ mã, và gói bị tính ngày từ lúc Host nhập mã chứ không theo ngày trên hợp đồng.

Đợt này đổi thành: **Admin chọn đúng tổ chức, bấm Cấp gói, gói kích hoạt ngay, Host không phải làm gì.** Nguyên tắc thiết kế là **sửa ít nhất có thể**, tái dùng mã kích hoạt, đường kích hoạt và thông báo đang có.

---

## User Stories

- **[P1]** Là Platform Admin/Manager, tôi muốn tìm tổ chức theo mã tổ chức hoặc mã số thuế và cấp gói cho đúng tổ chức đó, để không phải gửi mã ra ngoài hệ thống.
  Accepted when: sau khi xác nhận, tổ chức có ngay một license (gói thi) hoặc được cộng chỗ (gói chỗ học viên), và không có bước nào cần Host thao tác.

- **[P1]** Là Admin, tôi muốn chọn ngày bắt đầu theo hợp đồng, với giá trị tự điền nối tiếp sau gói cùng loại còn hạn, để tổ chức không mất ngày khi ký lại.
  Accepted when: tổ chức đang có "Gói năm" hết hạn 31/12 thì form tự điền ngày bắt đầu 31/12. Gói được tạo ra chạy 31/12 → 31/12 năm sau.

- **[P1]** Là Admin, tôi muốn thấy màn xác nhận (MST in đậm) và bản xem trước khoảng ngày trước khi cấp, để đối chiếu với hợp đồng giấy.
  Accepted when: màn xác nhận hiện tên, mã tổ chức, **MST**, địa chỉ, loại cơ sở, Host hiện tại; bản xem trước hiện "chạy từ … đến …" và số học viên tối đa mỗi kỳ thi.

- **[P1]** Là Host, tôi muốn thấy gói được cấp kèm trạng thái *Sắp hiệu lực từ dd/mm* và tạo được kỳ thi trước cho khoảng ngày của gói, để chuẩn bị đợt thi sớm.
  Accepted when: Host nhận thông báo inbox; thẻ gói hiện nguồn *PTEPrep cấp* và nhãn trạng thái đúng; tạo kỳ thi nằm trong khoảng ngày của gói chờ thì được, nằm ngoài thì báo lỗi kèm khoảng ngày.

- **[P1]** Là Host, tôi không còn thấy lối vào trang nhập mã.
  Accepted when: tenant-web không còn menu, nút hay đường dẫn nào tới `/host/redeem-license`.

- **[P2]** Là Admin, tôi muốn danh sách cấp gói hiện tổ chức, số hợp đồng, ngày bắt đầu và ngày hết hạn, để tra cứu theo hợp đồng.

- **[P1] (bổ sung 2026-10-30)** Là Admin, khi tạo tenant trực tiếp tôi muốn tổ chức đi đúng quy tắc của luồng duyệt đơn và có ngay tài khoản Host, để tổ chức dùng được luôn.
  Accepted when:
  - Form tạo tenant **không còn ô Plan và Student Limit**.
  - Hạn mức học viên = `freeStudentLimit` trong Platform settings.
  - Có ô **Email Host** bắt buộc. Host được tạo và nhận email mật khẩu.
  - Modal "đã tạo" có nút **Cấp gói ngay**, mở wizard đã chọn sẵn tổ chức vừa tạo.
  - Danh sách tenant thay cột/bộ lọc "Plan" bằng cột **Hạn mức học viên**.

- **[P3]** _(ngoài phạm vi)_ Thu hồi theo gói cho mọi nguồn, nhắc hạn, gia hạn PayOS, dời ngày bắt đầu.

---

## Functional Requirements

**Cấp gói (pte-api, billing)**

1. FR-01: Thêm endpoint cấp gói cho `PLATFORM_ADMIN` và `PLATFORM_MANAGER`, nhận `tenantId`, `planId`, `startsAt` (chỉ với gói thi), `contractReference` (bắt buộc, tối đa 64 ký tự), `note` (không bắt buộc, tối đa 500 ký tự), header `Idempotency-Key`.
2. FR-02: Trong **một transaction**: phát `LicenseCode` gắn tổ chức (cột mới `bound_tenant_id`), rồi redeem ngay cho chính tổ chức đó qua `LicenseCodeRedeemer` và `SubscriptionActivationService.activate(...)` hiện có. Bước nào lỗi thì không còn mã nào ở trạng thái ISSUED.
3. FR-03: `activate(...)` nhận thêm `startsAt` không bắt buộc. Webhook PayOS và đơn 0 đồng **không truyền** `startsAt` nên vẫn chạy từ lúc kích hoạt. `expiresAt = startsAt + durationDays`.
4. FR-04: Ngày bắt đầu mặc định = `max(hiện tại, expiresAt lớn nhất của các Subscription ACTIVE cùng tổ chức và cùng gói)`, **tính cả gói PayOS và gói chờ**. Dùng `findUsableForPlanRenewal` đã có, bỏ điều kiện `startsAt <= now`, khóa `PESSIMISTIC_WRITE`.
5. FR-05: Từ chối `startsAt` ở quá khứ (so với thời điểm cấp, cho phép lệch trong cùng ngày theo giờ VN) và `startsAt` cách ngày cấp quá **6 tháng** (chốt 2026-10-29).
6. FR-06: Gói `STUDENT_CAPACITY` dùng cùng form và hành vi redeem hiện tại: không có ngày bắt đầu, cộng chỗ vĩnh viễn qua `grantQuota`.
7. FR-07: Endpoint xem trước, chỉ đọc: trả ngày bắt đầu mặc định, `expiresAt` tính ra và `maxStudentsPerSession`.
8. FR-08: Endpoint redeem phía Host (`POST /api/v1/license-code-redemptions`) **giữ nguyên** cho mã cũ. Mã có `bound_tenant_id` khác tổ chức của người nhập thì từ chối như mã không tồn tại (404).
9. FR-09: Ghi audit một bản ghi "cấp gói" kèm tổ chức, gói, số hợp đồng, ngày bắt đầu. Phát `CommercialOutcomeConfirmedEvent` hiện có để Host nhận thông báo inbox; không thêm loại thông báo mới.
10. FR-10: Thêm tham số `?q=` vào `GET /api/v1/organizations` (chỉ role platform dùng `q`). Tham số này khớp mã tổ chức hoặc MST (chính xác hoặc tiền tố), hoặc email (chỉ để tra cứu). Tối đa 20 kết quả. Wizard chỉ cho chọn tổ chức `ACTIVE`; nhiều kết quả thì Admin chọn một.

**Gói chờ dùng được để lên lịch (pte-api, session)**

11. FR-11 (sửa theo plan 2026-10-29): thêm khái niệm *lên lịch được* (`ACTIVE && expiresAt > now`), dùng cho tạo/sửa nháp, publish, đổi lịch, đổi gói, danh sách gói của Host. **Mở kỳ thi** (thủ công và tự động) vẫn đòi gói đã chạy (`startsAt <= now`). Practice và dashboard giữ nguyên. Quy tắc "lịch thi nằm gọn trong `[startsAt, expiresAt]`" vẫn là chốt chặn.

**Giao diện**

12. FR-12 (vendor-web): Đổi tên trang *License codes* thành *Cấp gói*. Form phát mã thay bằng wizard 4 bước: tìm tổ chức → xác nhận → nhập → xem trước, rồi xác nhận. Danh sách thêm cột tổ chức, số hợp đồng, ngày bắt đầu, ngày hết hạn. Hiện mã và thu hồi mã giữ nguyên.
13. FR-13 (tenant-web): Thẻ gói hiện nguồn (*Mua online* / *PTEPrep cấp*, từ `activationSource`) và trạng thái *Đang hiệu lực đến dd/mm* / *Sắp hiệu lực từ dd/mm* (`startsAt > now`). Ô chọn gói khi tạo kỳ thi hiện cả gói chờ kèm khoảng ngày.
14. FR-14 (tenant-web): Ẩn mọi lối vào trang redeem. Sửa câu báo lỗi "redeem a license or purchase a plan first" thành "mua gói hoặc liên hệ PTEPrep để được cấp theo hợp đồng".

**Admin tạo tenant trực tiếp (bổ sung 2026-10-30)**

15. FR-15 (pte-api, billing): `POST /api/v1/admin/organizations` (Admin + Manager, quyền `TENANT_ONBOARD`) nhận `code`, `name`, `organizationType`, `taxCode`, `hostEmail`.
    - Trong **một transaction**: ghi tổ chức như một đơn đăng ký rồi duyệt ngay, dùng chung logic `TenantApplicationService.approve`. Hạn mức học viên lấy `freeStudentLimit`. Tạo `HOST_ADMIN` cho `hostEmail`. Phát `TenantApplicationApprovedEvent` để gửi email mật khẩu.
    - Không có trường plan hay hạn mức.
    - Trả `{publicId, code, name, hostUsername}`. Mật khẩu không bao giờ được trả về.
16. FR-16 (pte-api, tenancy): **gỡ** `POST /api/v1/organizations` (đường tắt cũ: lưu nhãn `packageName`, hạn mức nhập tay, không có Host).
17. FR-17 (vendor-web, tenancy):
    - Form tạo tenant bỏ *Plan* và *Student Limit*, thêm *Email Host* (bắt buộc, kiểm tra định dạng) kèm ghi chú "hạn mức theo Platform settings, cấp gói sau khi tạo".
    - Modal "đã tạo" bỏ dòng Plan, thêm dòng Host và nút **Cấp gói ngay**. Nút này mở `GrantLicenseWizard` với `initialCode`; wizard tự chọn tổ chức khớp đúng mã (đang hoạt động) và nhảy sang bước xác nhận.
    - Danh sách tenant: cột/bộ lọc *Plan* thay bằng cột *Hạn mức học viên*. Trang chi tiết bỏ dòng Plan.
    - `TenantPlan` / `TENANT_PLAN_LABELS` / `PLAN_SELECT_OPTIONS` **giữ lại** cho feature `licensing` (nhãn `packageName` của quota grant).
18. FR-18 (vendor-web, cấp gói): cột *Hạn nhập mã* (Expires) **tắt** bằng cờ `SHOW_CODE_EXPIRY_COLUMN = false`, vì mã cấp gói không có hạn nhập. Hạn của mã cũ vẫn xem qua badge *Expired* và Lookup.

---

## Non-Functional Requirements

- Performance: cấp gói phản hồi < 500 ms p95. Tra cứu tổ chức < 300 ms với ≤ 1.000 tổ chức.
- Concurrency: hai lần cấp cùng tổ chức và cùng gói chạy song song thì không được ra hai ngày bắt đầu trùng nhau (khóa dòng Subscription khi tính ngày nối tiếp).
- Idempotency: cùng `Idempotency-Key` gửi lại thì trả lại đúng kết quả cũ, không sinh thêm gói.
- Security: chỉ role platform cấp được. Mã sinh ra không trả về cho Host. Audit 100% lần cấp.
- Compatibility: mã cũ (không gắn tổ chức) vẫn redeem được qua API; dữ liệu `license_codes` cũ không phải migrate.

---

## Success Criteria

- [ ] Admin cấp một gói thi cho tổ chức trong ≤ 5 thao tác (tìm → chọn → nhập → xem trước → xác nhận), Host không phải thao tác gì.
- [ ] Có gói cùng loại hết hạn 31/12 thì gói mới chạy 31/12 → 31/12 + `durationDays` (test tích hợp).
- [ ] Mua PayOS khi đang có gói cùng loại thì gói mới vẫn chạy từ lúc thanh toán (hồi quy, không đổi hành vi).
- [ ] Host tạo được kỳ thi trong khoảng ngày của gói chờ; lịch trước `startsAt` bị từ chối kèm khoảng ngày (test session).
- [ ] Hai request cấp đồng thời cho cùng tổ chức và cùng gói ra hai khoảng ngày nối tiếp, không chồng nhau (test đồng thời).
- [ ] Thu hồi mã của gói Admin cấp (luồng hiện có) hủy được gói và các kỳ thi SCHEDULED (hồi quy).
- [ ] Tổng thay đổi ≤ ~20 file production (không tính test), trong đó 1 migration Flyway.
- [ ] Admin tạo tenant trực tiếp: tổ chức ACTIVE, hạn mức = `freeStudentLimit`, có đúng 1 `HOST_ADMIN` cho email đã nhập, email mật khẩu được gửi. `POST /api/v1/organizations` trả 404/405.
- [ ] Bấm *Cấp gói ngay* sau khi tạo: wizard mở ở bước *Xác nhận* với đúng tổ chức vừa tạo.

---

## Out of Scope

- Thu hồi theo gói cho gói PayOS (cấp nhầm thì sửa bằng thu hồi mã hiện có).
- Gia hạn nối tiếp cho PayOS: mua tiếp là một license mới chạy ngay, như hiện tại.
- Nhắc hạn 30/7/1 ngày, danh sách "Sắp hết hạn" cho Admin.
- Nút *Gia hạn* phía Host, giới hạn "tối đa 1 gói chờ".
- Dời ngày bắt đầu sau khi đã cấp; ân hạn sau khi hết hạn; gói "chỉ cấp theo hợp đồng".
- Xóa entity mã kích hoạt; phát mã theo lô; bán mã qua đại lý.

---

## Assumptions

- `Organization.publicId` là `tenantId` (đã xác minh), và `code`/`taxCode` là duy nhất trong số tổ chức chưa bị từ chối.
- `CommercialOutcomeConfirmedEvent` đủ nội dung để thông báo Host; có thể cần thêm ngày bắt đầu vào câu thông báo khi gói chưa chạy ngay.
- Nới `getActiveSubscription` không làm hỏng chỗ gọi nào khác ngoài `session`, vì chặn theo khoảng ngày đã có. Bước plan phải rà lại các chỗ gọi `isUsableAt`.
- Migration mới đặt số tiếp theo sau `V6__drop_class_lecturer_assignments.sql` (kiểm tra lại trên `dev` khi làm).

