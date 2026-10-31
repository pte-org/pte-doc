# Phase 4: vendor-web, wizard Cấp gói

**Status:** Not started · **Repo:** pte-web · **Stories:** P1 #1, #3 · P2 (FR-12)

Gốc đường dẫn: `pte-web/`

## Mục tiêu

Đổi trang _License codes_ thành _Cấp gói_. Thay form phát mã bằng wizard 4 bước. Danh sách có thêm cột theo hợp đồng.

## Việc cần làm

**4a. api-client (`packages/api-client/src`)**

- `requests/tenant/index.ts:29`: `listTenants(client, params?: { q?: string })`, dựng query bằng `URLSearchParams` như `listAdminLicenseCodes`.
- `requests/billing/licenseGrants.ts` (mới):
  - `previewLicenseGrant(client, body)`
  - `grantLicense(client, body, idempotencyKey)`, đặt header giống `issueLicenseCode:94-102`
  - re-export trong `requests/index.ts`
- Types:
  - `LicenseGrantPreviewRequest/Response`, `LicenseGrantRequest/Response`
  - `AdminLicenseCodeSummary` thêm `boundTenantId`, `contractReference`, `subscriptionStartsAt`, `subscriptionExpiresAt`
  - `ActivationSource` **không đổi**
- Test: `licenseGrants.test.ts` và cập nhật `endpoints.test.ts`.

**4b. Wizard, toàn bộ là file mới** trong `features/commercialization/components/licenseGrant/`:

- Mẫu tham khảo: `tenant-web/features/exams/components/CreateExamWizard.tsx`. Dùng `Modal` + `Stepper` + `DescriptionList` + `DateInput` + `Select` + `Textarea` của `@pte/ui`.
- Các file:
  - `GrantLicenseWizard.tsx`
  - `_GrantTenantSearchStep.tsx`, `_GrantConfirmStep.tsx`, `_GrantDetailsStep.tsx`, `_GrantPreviewStep.tsx`
  - `useGrantLicenseFlow.ts`
  - `constants.ts`
  - `utils.ts`: tính min/max ngày, dựng câu xem trước
- Bước 1, **Tìm tổ chức:** `Input` debounce 300 ms → `listTenants({q})`. Mỗi kết quả là một hàng chọn được (tên · mã · MST). Tổ chức không ACTIVE thì mờ đi, không chọn được. Không có kết quả thì hiện `EmptyState`.
- Bước 2, **Xác nhận:** `DescriptionList` gồm tên, mã, **MST in đậm**, địa chỉ, loại cơ sở (lấy từ kết quả tìm), Host hiện tại (từ `previewLicenseGrant`).
- Bước 3, **Nhập:**
  - `Select` gói: các gói `ACTIVE`, cả gói thi lẫn gói chỗ.
  - `DateInput` ngày bắt đầu: hiện `defaultStartsAt`, `min` = hôm nay, `max` = +6 tháng. **Ẩn khi chọn gói chỗ.**
  - Số hợp đồng (bắt buộc), ghi chú.
- Bước 4, **Xem trước:** gọi lại preview với ngày đã chọn.
  - Gói thi: "Chạy từ dd/mm/yyyy đến dd/mm/yyyy · tối đa N học viên/kỳ thi", thêm "Nối tiếp gói XXXX hết hạn dd/mm" nếu có.
  - Gói chỗ: "+N chỗ học viên".
- **Chỉ gửi `startsAt` khi Admin đã sửa ngày.** Nếu giữ mặc định thì bỏ trường, để backend dùng đúng `expiresAt` của gói trước, không bị lệch giờ.
- **Xác nhận** → `grantLicense`. Idempotency-Key sinh một lần mỗi khi mở wizard và giữ trong state. Thành công thì toast, đóng wizard, invalidate danh sách mã.

**4c. Sửa tối thiểu `LicenseCodesView.tsx`**

- Nút _Create code_ thành _Cấp gói_, mở `GrantLicenseWizard`.
- Bỏ Issue Modal và Issue-success Modal cùng phần khôi phục issue-intent. Lookup, Reveal, Revoke giữ nguyên.
- Bảng thêm cột Tổ chức, Số hợp đồng, Bắt đầu, Hết hạn.
- **Không** tách file trong đợt này. File chỉ được ngắn đi, không dài thêm. Việc tách file ghi thành nợ kỹ thuật.

**4d. Nhãn điều hướng**

- `lib/navigationConstants.ts:7`, `packages/ui/src/i18n/LocaleProvider.tsx:936` (vi "Cấp gói") / `:1928` (en "License Code"), `features/i18n/adminCopy.ts:199`, `LICENSE_CODES_TEXT.TITLE`. **Giữ route** `/admin/license-codes`.
- Mọi chuỗi mới có bản tiếng Việt trong `adminCopy.ts`.

## Design Constraints

- Tuân `pte-web/AGENTS.md` và `docs/CODING_STANDARDS_WEB.md`. Dùng component `@pte/ui` như có sẵn, không viết lại style. Chuỗi để trong constants. Gọi API bằng TanStack Query trong `features/*/api.ts`. Không dùng `any`. File mới ≤ 300 dòng, component ≤ 150 dòng.
- `@pte/ui` chưa có combobox nên dùng Input + danh sách. Không thêm component chung.

## Tests

- vitest + `renderHtml`: các bước render đúng; ẩn ô ngày khi chọn gói chỗ; MST in đậm; xem trước hiện khoảng ngày.
- `utils.test.ts`: min/max ngày; chỉ gửi `startsAt` khi khác mặc định.
- `pnpm --filter vendor-web lint typecheck test`, `pnpm --filter @pte/api-client test`.

## Quality and Testing State

- Quality: not evaluated
- Testing: not started
