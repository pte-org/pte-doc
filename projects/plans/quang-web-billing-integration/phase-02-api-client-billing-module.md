# Phase 2: `api-client` — module `billing`

## Requirements

Thêm lớp contract cho toàn bộ API thương mại hoá vào `packages/api-client`: types và request function cho applications, plans, subscriptions, orders, license codes, platform settings, student quota.

**Không đụng UI.** Phase này kết thúc mà giao diện không đổi một pixel — đó là chủ đích.

Maps to: **[ADR-006](../../architecture/ADR-006-commercialization-and-exam-templates.md)**

## Design Constraints

- **Type phải phản chiếu response DTO thật của backend, không phản chiếu nhu cầu hiển thị.** `features/commercialization/types.ts` hiện có của vendor-web là type *trình bày* — `price: string` (`"$49"`), `duration: string` (`"30 days"`), `capacity: string` (`"500 students / exam"`). Backend trả `price: BigDecimal`, `durationDays: number`, `maxStudentsPerSession: number`. **Không sửa type backend cho khớp UI**; việc định dạng thuộc về component.

- **Giữ nguyên quy ước module hiện có**: một thư mục `requests/billing/`, một `types/billing/`, mỗi nhóm endpoint một file, export qua `requests/index.ts` và `types/index.ts`. Không tạo pattern mới.

- **Chỉ viết request function, không viết hook.** `api-client` là package thuần contract — không phụ thuộc React, không `useQuery`. TanStack Query nằm ở `features/*/api.ts` của từng app (xem `requests/admin/programs.ts` làm mẫu).

- **Đường dẫn dùng prefix `/api/v1/` versioned của Phase 1.** Phase này là nơi đầu tiên viết mới theo quy ước đó — viết sai thì các phase sau nhân bản cái sai.

- **`publicId` là khoá đối ngoại, không phải `id`.** Backend dùng `publicId` (UUID) ở mọi API; `id` (bigint) không bao giờ lộ ra. Type phải phản ánh đúng, tránh việc component sau này lỡ dùng `id` không tồn tại.

- **`hostAdminPassword` trong `ApproveApplicationResponse` là bí mật dùng một lần.** Đánh dấu rõ trong javadoc của type: không lưu, không log, không cache vào query cache quá vòng đời modal.

## Steps

1. `types/billing/index.ts` — enum dạng union type, khớp đúng enum backend:
   ```ts
   export type TenantApplicationStatus = "PENDING" | "APPROVED" | "REJECTED";
   export type PlanType = "EXAM_PACKAGE" | "STUDENT_CAPACITY";
   export type PlanStatus = "DRAFT" | "ACTIVE" | "ARCHIVED";
   export type SubscriptionStatus = "ACTIVE" | "EXPIRED" | "CANCELLED";
   export type ActivationSource = "PAYMENT" | "LICENSE_CODE";
   export type OrderStatus = "PENDING" | "PAID" | "CANCELLED" | "EXPIRED";
   export type LicenseCodeStatus = "ISSUED" | "REDEEMED" | "REVOKED" | "EXPIRED";
   ```

2. `types/billing/application.ts` — `TenantApplicationResponse`, `SubmitApplicationRequest`, `RejectApplicationRequest`, `ApproveApplicationResponse`. Đối chiếu từng trường với DTO trong `billing/internal/dto/`, **không đoán tên trường**.

3. `types/billing/plan.ts` — `PlanResponse`, `PlanRequest`. Nhớ các trường chỉ có nghĩa theo `type`: `durationDays`/`maxStudentsPerSession` (EXAM_PACKAGE) và `extraStudentSlots` (STUDENT_CAPACITY) đều nullable.

4. `types/billing/subscription.ts` — `SubscriptionResponse` (`licenseKey`, `startsAt`, `expiresAt`, `maxStudentsPerSession`, `status`, `activationSource`).

5. `types/billing/order.ts` — `OrderResponse`, `CreateOrderRequest`. `orderCode` là số nguyên lớn — dùng `number` và **ghi chú giới hạn an toàn của JS**, hoặc `string` nếu backend trả chuỗi; kiểm DTO thật trước khi chọn.

6. `types/billing/licenseCode.ts` — `LicenseCodeResponse`, `IssueLicenseCodeRequest`, `RevokeLicenseCodeRequest`, `RedeemLicenseCodeRequest`.

7. `types/billing/platformSetting.ts` — `PlatformSettingResponse`, `PlatformSettingRequest`.

8. `types/billing/quota.ts` — `StudentQuotaResponse`, `StudentImportPreviewRequest`.

9. `requests/billing/applications.ts`:
   ```ts
   export const APPLICATION_ENDPOINTS = {
     submit: "/api/v1/applications",                                   // công khai, không auth
     adminList: "/api/v1/applications",
     approve: (id: string) => `/api/v1/applications/${id}/approval`,
     reject: (id: string) => `/api/v1/applications/${id}/rejection`,
   } as const;
   ```

10. `requests/billing/plans.ts` — `listActive`/`adminList`/`create` (`/api/v1/plans`), `get`/`update` (`/api/v1/plans/{publicId}`), `activate`/`archive` theo action sub-resource trong route catalog.

11. `requests/billing/subscriptions.ts` — `list` (`/api/v1/subscriptions`).

12. `requests/billing/orders.ts` — `create`, `list` (`/api/v1/orders`).

13. `requests/billing/licenseCodes.ts` — `issue`/`list` (`/api/v1/license-codes`), `revoke` theo action sub-resource trong route catalog, `redeem` (`/api/v1/license-code-redemptions`).

14. `requests/billing/platformSettings.ts` — `list`, `get`, `update` (`/api/v1/settings`).

15. `requests/billing/quota.ts` — `getQuota` (`/api/v1/tenant/quota`), `previewImport` (`/api/v1/students/import/preview`).

16. Export tất cả qua `requests/index.ts` và `types/index.ts`.

17. Đối chiếu lần cuối: mở từng controller trong `billing/internal/controller/` và `tenancy/internal/controller/StudentQuotaController.java`, so từng method với request function tương ứng — đúng đường dẫn, đúng HTTP method, đúng hình dạng body.

## Success Criteria

- `pnpm build` sạch ở `packages/api-client` — TypeScript là lớp kiểm duy nhất ở phase này
- Mỗi endpoint billing của backend có đúng một request function tương ứng, không thiếu không thừa
- Không có `any` trong bất kỳ type mới nào
- Không file nào vượt 300 dòng
- UI **không đổi gì** — vẫn chạy dữ liệu cứng, đúng như thiết kế của phase

## Quality and Testing State

- Quality gate: chưa chạy
- Testing: chưa bắt đầu

## Session Notes

_(trống)_
