# Phase 5: tenant-web, nhãn gói và ẩn trang nhập mã

**Status:** Not started · **Repo:** pte-web · **Stories:** P1 #4, #5 (FR-13, FR-14)

Gốc đường dẫn: `pte-web/apps/tenant-web/`

## Mục tiêu

Host thấy gói được cấp kèm nguồn và trạng thái, chọn được gói chờ khi tạo kỳ thi, và không còn lối vào trang nhập mã. **Phát hành cùng đợt với Phase 4.**

## Việc cần làm

1. **Trạng thái và nguồn trên Billing:**
   - `features/commercialization/components/BillingExpiryStatus.tsx`: với từng subscription hiện
     - *Đang hiệu lực đến dd/mm/yyyy* (khi `startsAt <= now`)
     - *Sắp hiệu lực từ dd/mm/yyyy* (khi `startsAt > now`)
     - số ngày còn lại
   - Dùng `Badge`/`StatusBadge` của `@pte/ui`. Logic tính trạng thái để trong `utils/subscriptionStatus.ts`.
   - `BillingPlanTab.tsx:59-63` đang gộp theo gói, và `BillingExpiryStatus:25-29` lấy `expiresAt` muộn nhất của nhóm. Đổi sang **mỗi subscription một dòng**, để gói đang chạy và gói chờ cùng loại không bị gộp.
   - `HomePlans.tsx:20-23`: gói chỉ được đánh dấu "đang dùng" khi `startsAt <= now`. Gói chờ hiện *Sắp hiệu lực*.
   - `badge nguồn`: `PAYMENT` → *Mua online*; `LICENSE_CODE` → *PTEPrep cấp* (không có giá trị enum mới).
2. **Ô chọn gói khi tạo kỳ thi:**
   - `features/exams/components/create-exam/ExamDetailsStep.tsx:55-69`: nhãn `planName — licenseKey (dd/mm – dd/mm)`, gói chờ thêm hậu tố *Sắp hiệu lực*.
   - `useCreateExamAudience.ts:30-31` không cần sửa (đã chỉ lọc `ACTIVE`).
   - Khi chọn gói chờ, `opensAt` mặc định của wizard = `max(now, subscription.startsAt)`, để không mặc định rơi vào trước ngày gói chạy.
3. **Bỏ lối vào trang redeem:**
   - `BillingPlanTab.tsx:72-77`: bỏ ActionMenu, nếu chỉ còn mục đó thì bỏ cả menu.
   - `BillingPlanTab.tsx:94-99`: bỏ link ở ô trống.
   - `PlanCatalogView.tsx:100-112`: bỏ thẻ link.
   - `BillingOverviewView.tsx:42`: bỏ prop.
   - **Giữ** file route `app/(dashboard)/host/redeem-license/page.tsx`, chỉ ẩn lối vào (mở bằng link cũ vẫn chạy được, backend vẫn nhận mã cũ).
4. **Sửa câu chữ:**
   - `constants.ts:57` `NO_ACTIVE_ACCESS_DESCRIPTION` → "Chưa có gói. Mua online hoặc liên hệ PTEPrep để được cấp theo hợp đồng."
   - `LocaleProvider.tsx` `tenant.billing.noActiveAccessDescription` (vi `:675`, en `:1668`).
   - Bỏ `REDEEM_LICENSE` / `tenant.billing.redeemLicense` nếu không còn chỗ dùng.
   - `features/exams/constants/index.ts:109-110` sửa câu "redeem a license or purchase a plan first".

## Design Constraints

- So sánh `startsAt` với giờ hiện tại phía client chỉ để hiển thị. Quyết định thật nằm ở backend.
- Ngày hiển thị theo giờ của người dùng (`toLocaleDateString` theo locale hiện tại).
- Không đổi component chung trong `@pte/ui`.

## Tests

- `utils/subscriptionStatus.test.ts`: gói đang chạy, gói chờ, sắp hết hạn, nhãn nguồn cho 2 giá trị `activationSource`.
- `renderHtml` cho `BillingExpiryStatus`: hiện *Sắp hiệu lực từ …*.
- Grep kiểm tra: không còn `href="/host/redeem-license"` trong `features/`.
- `pnpm --filter tenant-web lint typecheck test`.

## Quality and Testing State

- Quality: not evaluated
- Testing: not started
