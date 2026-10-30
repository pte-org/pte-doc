# Plan: Admin cấp gói theo hợp đồng (thay luồng Host nhập mã)

**Status:** Implemented (2026-10-30, `/ck:cook --fast`: build/typecheck/lint passed; unit tests not written or run, quality gate skipped)
**Date:** 2026-10-29
**Owner/slug:** Hung — `hung-license-grant`
**Mode:** Hard · **Test:** default (khuyến nghị `--tdd`)
**Scope:** pte-api (billing, session, tenancy, notification) · pte-web (api-client, vendor-web, tenant-web)
**Related:** [spec.md](./spec.md) · [brainstorm](../reports/261029-hung-license-grant-brainstorm.md) · [đề xuất gốc](../reports/261029-hung-license-grant-renewal.md)
**Nhánh Git:** `hung/feat/license-grant` (pte-api, pte-web, pte-doc)

---

## 1. Phases Overview

| # | Phase | Repo | Stories | Phụ thuộc |
|---|---|---|---|---|
| 1 | [Kích hoạt có ngày bắt đầu + mã gắn tổ chức](./phase-01-activation-start-and-bound-code.md) | pte-api | P1 #1, #2 | — |
| 2 | [API cấp gói, xem trước, tra cứu tổ chức](./phase-02-grant-api.md) | pte-api | P1 #1, #3 · P2 | 1 |
| 3 | [Gói chờ dùng được để lên lịch](./phase-03-pending-subscription-scheduling.md) | pte-api | P1 #4 | 1 |
| 4 | [vendor-web: wizard Cấp gói](./phase-04-vendor-grant-wizard.md) | pte-web | P1 #1, #3 · P2 | 2 |
| 5 | [tenant-web: nhãn gói, ẩn trang nhập mã](./phase-05-tenant-billing-labels.md) | pte-web | P1 #4, #5 | 3 |
| 6 | [Seed script + tài liệu](./phase-06-seed-and-docs.md) | pte-api, pte-doc | — | 1–5 |
| 7 | [Admin tạo tenant trực tiếp đúng nghiệp vụ](./phase-07-direct-tenant-onboarding.md) (bổ sung 2026-10-30) | pte-api, pte-web | P1 bổ sung · FR-15→18 | 2, 4 |

- [x] Phase 1 [quality: skipped_by_user; decision: user_confirmed_skip] (tests: not_started — `--fast`)
- [x] Phase 2 [quality: skipped_by_user; decision: user_confirmed_skip] (tests: not_started — `--fast`)
- [x] Phase 3 [quality: skipped_by_user; decision: user_confirmed_skip] (tests: not_started — `--fast`)
- [x] Phase 4 [quality: skipped_by_user; decision: user_confirmed_skip] (tests: not_started — `--fast`)
- [x] Phase 5 [quality: skipped_by_user; decision: user_confirmed_skip] (tests: not_started — `--fast`)
- [x] Phase 6 [quality: skipped_by_user; decision: user_confirmed_skip] (tests: not_started — `--fast`)
- [x] Phase 7 [quality: skipped_by_user; decision: user_confirmed_skip] (tests: not_started)

**Sự cố khi chạy Docker (2026-10-30):** nhánh được cập nhật từ `dev` kéo theo PR chat #85, PR này đã dùng số V7 và V8. Migration của plan này đổi thành `V9__license_code_grant_fields.sql`; Flyway đã chạy V6 → V9 thành công.

**Phát hành:** Phase 1–3 (backend) merge trước được vì không đổi hành vi hiện tại: PayOS và redeem cũ vẫn chạy y nguyên. Phase 4 và 5 **phát hành cùng đợt** để Host thấy nhãn *Sắp hiệu lực* ngay khi Admin bắt đầu cấp gói chờ.

## 2. Quyết định thiết kế chính

1. **Giữ mã kích hoạt chạy ngầm.** Cấp gói = phát `LicenseCode` gắn `bound_tenant_id` + redeem ngay cho tổ chức đó, trong **một transaction**. Nhờ vậy thu hồi mã hiện có vẫn là đường sửa sai, mà không phải làm luồng thu hồi mới.
2. **Không dùng `LicenseCodePersistenceService.issue`** (nó chạy `REQUIRES_NEW` và chặn gói chỗ). Cấp gói tự làm trong một transaction: activate trước → `LicenseCode.grant` + `markRedeemed` trong bộ nhớ → một lần save. Idempotency dùng lại scope `LICENSE_ISSUE` (đã có trong CHECK), key `grant:…`. **Không thêm giá trị enum/CHECK nào**; `activationSource` vẫn là `LICENSE_CODE`.
3. **`activate(..., startsAt)`**: tham số không bắt buộc. PayOS và đơn 0 đồng truyền `null` nên vẫn chạy ngay (spec: PayOS không gia hạn nối tiếp).
4. **Ngày mặc định** = `max(now, max expiresAt của Subscription ACTIVE cùng tenant + plan)`, tính mọi nguồn và cả gói chờ. Tuần tự hóa bằng **khóa dòng tổ chức** `tenancyService.lockActiveTenant`, để chạy đúng cả khi tổ chức chưa có gói nào.
5. **Tách hai khái niệm**, chỉ ở 3 chỗ kiểm tra thật (`SessionSubscriptionRules:52` có cờ `requireStarted`, `ExamDraftService:230`, preflight `ExamPublishService:255`), cộng danh sách gói và reveal key của Host:
   - *Lên lịch được* (`ACTIVE && expiresAt > now`): tạo/sửa nháp, publish, đổi lịch, đổi gói, danh sách gói của Host.
   - *Dùng được ngay* (`isUsableAt`, đòi `startsAt <= now`): **mở kỳ thi thủ công và auto-open**, practice entitlement, dashboard/overview.
   Chốt chặn chung vẫn là "lịch thi nằm gọn trong `[startsAt, expiresAt]`".
6. **"Host hiện tại" lấy qua `billing`.** `billing` đã import `identity` và `tenancy`; `tenancy → identity` sẽ thành vòng phụ thuộc. Endpoint xem trước trả luôn thông tin tổ chức + Host.
7. **Tra cứu tổ chức:** `GET /api/v1/organizations?q=` khớp `code` / `taxCode` / `contactEmail`, chỉ dành cho role platform.

## 3. Risks

| Rủi ro | Cách giảm |
|---|---|
| Gói chờ lọt qua một đường dùng sớm chưa phát hiện | Phase 3 liệt kê mọi chỗ gọi; test riêng cho mở thủ công, practice, attempt start trước `startsAt` |
| Hai lần cấp đồng thời cùng tenant + plan ra trùng ngày | Khóa dòng tổ chức (`lockActiveTenant`) trước khi tính ngày; test đồng thời Postgres với tổ chức chưa có gói (Phase 2) |
| `LicenseCodesView.tsx` 1095 dòng, sửa dễ vỡ | Wizard là file mới; chỉ bỏ Issue Modal và thêm cột, không tách file đợt này |
| Ô *Plan* ở form tạo tenant chỉ là nhãn, Admin tưởng đã giao gói | Ngoài phạm vi; ghi chú tài liệu. Hướng "mở wizard Cấp gói sau khi tạo tenant" chờ Hung chốt |
| Mã cũ không gắn tổ chức vẫn redeem qua API | Chủ đích (tương thích). UI không còn lối vào |
| Tenant do Admin tạo thẳng **không có Host** | **Đã xử lý ở Phase 7**: tạo trực tiếp nay luôn tạo Host. Tenant cũ tạo trước đó vẫn có thể chưa có Host; màn xác nhận hiện "Chưa có Host" |
| Gói chỗ học viên cấp nhầm không thu hồi được (`LicenseRevokeScopeResolver:73-77`) | Màn xác nhận cảnh báo riêng cho gói chỗ; sửa sai bằng quota-grant âm nếu cần (ngoài phạm vi) |
| Dashboard / suspension impact không tính gói chờ (`SubscriptionRepository:44-78`) | Chấp nhận: dashboard có thể ghi "chưa có gói" trong khi Billing ghi *Sắp hiệu lực* |
| `LicenseCodesView.tsx` vẫn > 300 dòng | Nợ kỹ thuật; đợt này chỉ làm file ngắn đi, wizard là file mới |

## 4. Ngoài phạm vi

Thu hồi theo gói / gói PayOS · gia hạn nối tiếp PayOS · nhắc hạn · nút Gia hạn phía Host · giới hạn 1 gói chờ · dời ngày bắt đầu. (Ô *Plan* ở form tạo tenant: **đã đưa vào phạm vi** ở Phase 7.)
