# Phase 6: vendor-web — màn hình platform-admin quản lý Score Template

Covers UI cho spec P1 story #1 ("xem template ACTIVE") và #2 ("clone → sửa DRAFT → kích hoạt"), dùng API admin dựng ở Phase 1. Chỉ vendor-web (platform admin) — không đụng tenant-web/host UI (Plan B).

## Requirements

Platform admin đăng nhập vendor-web thấy được template APEUNI V5 đang ACTIVE (22 dòng, đủ mọi cột: section, số câu min~max, thời gian, cách chấm, % Overall/từng skill), có thể tạo bản DRAFT mới bằng cách clone từ một template có sẵn, sửa các dòng của DRAFT đó, rồi kích hoạt để nó trở thành ACTIVE mới (bản ACTIVE cũ tự RETIRED).

## Files

**Tạo mới**
- `pte-web/packages/api-client/src/types/scoretemplate/index.ts` — `ScoreTemplateStatus`, `TimingMode`, `ScoringMethod`, `ScoreTemplateItemResponse`, `ScoreTemplateResponse`, `ReplaceScoreTemplateItemsRequest` (khớp DTO backend của Phase 1).
- `pte-web/packages/api-client/src/requests/scoretemplate/index.ts` — `listScoreTemplates`, `getActiveScoreTemplate`, `getScoreTemplate(publicId)`, `cloneScoreTemplate(publicId)`, `replaceScoreTemplateItems(publicId, payload)`, `activateScoreTemplate(publicId)`, endpoint path khớp đúng `@RequestMapping` thật của `ScoreTemplateController` (kiểm tra lại path lúc code Phase 1, không giả định trước).
- `pte-web/packages/api-client/src/index.ts` — export thêm 2 module trên (mirror cách `question`/`scoring` đã export).
- `pte-web/apps/vendor-web/features/scoretemplate/api.ts` — `useActiveScoreTemplate`, `useScoreTemplates` (list), `useScoreTemplate(publicId)` (TanStack Query), `useCloneScoreTemplate`, `useReplaceScoreTemplateItems`, `useActivateScoreTemplate` (mutation, invalidate query list+active sau khi thành công).
- `pte-web/apps/vendor-web/features/scoretemplate/types.ts` — kiểu dữ liệu UI-facing (tách khỏi kiểu API-client, theo đúng convention `questionbank/types.ts`).
- `pte-web/apps/vendor-web/features/scoretemplate/constants.ts` — query key, nhãn cột, nhãn trạng thái.
- `pte-web/apps/vendor-web/features/scoretemplate/components/index.ts`.
- `pte-web/apps/vendor-web/features/scoretemplate/components/ScoreTemplateListView.tsx` — bảng tất cả template (code/version/status/name), badge trạng thái, click ACTIVE → xem chi tiết read-only, click DRAFT → vào trang sửa, nút "Clone to new draft" trên dòng ACTIVE/RETIRED.
- `pte-web/apps/vendor-web/features/scoretemplate/components/_ScoreTemplateItemTable.tsx` — bảng 22 dòng (đọc hoặc sửa tùy prop `editable`), cột đúng FR-02.
- `pte-web/apps/vendor-web/features/scoretemplate/components/ScoreTemplateDetailView.tsx` — xem chi tiết 1 template (dùng cho ACTIVE/RETIRED, read-only).
- `pte-web/apps/vendor-web/features/scoretemplate/components/ScoreTemplateEditorView.tsx` — sửa DRAFT: form tên + `_ScoreTemplateItemTable` editable, nút "Save draft" (gọi `replaceScoreTemplateItems`) và "Activate" (modal xác nhận cảnh báo sẽ retire ACTIVE hiện tại, gọi `activateScoreTemplate`).
- `pte-web/apps/vendor-web/app/(dashboard)/admin/score-template/page.tsx` — bọc `DashboardChrome` + `ScoreTemplateListView`.
- `pte-web/apps/vendor-web/app/(dashboard)/admin/score-template/[publicId]/page.tsx` — `ScoreTemplateDetailView` (ACTIVE/RETIRED).
- `pte-web/apps/vendor-web/app/(dashboard)/admin/score-template/[publicId]/edit/page.tsx` — `ScoreTemplateEditorView` (chỉ DRAFT; redirect hoặc báo lỗi nếu template không phải DRAFT — theo cùng bất biến backend Phase 1).

**Sửa**
- `pte-web/apps/vendor-web/lib/navigation.tsx` — thêm mục `{ label: "Score Template", href: "/admin/score-template", icon: ..., section: "Content" }` vào `ADMIN_NAV`.

## Steps

1. Thêm types + requests vào `packages/api-client` khớp đúng contract thật của `ScoreTemplateController` (Phase 1) — kiểm tra lại path/shape response bằng cách đọc code Java vừa viết, không đoán.
2. Viết `features/scoretemplate/api.ts` theo pattern `useQuery`/`useMutation` đã dùng ở `features/questionbank` và `features/licensing` (invalidate query đúng key sau mutation).
3. Viết `ScoreTemplateListView` + `_ScoreTemplateItemTable` (component bảng dùng chung cho view lẫn edit qua prop `editable`).
4. Viết `ScoreTemplateDetailView` (read-only) và `ScoreTemplateEditorView` (form sửa + nút Activate có modal xác nhận, dùng component `@pte/ui` Modal/Button sẵn có, mirror `GrantQuotaModal`/`CreateTenantModal`).
5. Nối 3 route Next.js App Router (`page.tsx` list, `[publicId]/page.tsx` detail, `[publicId]/edit/page.tsx` editor), mỗi trang bọc `DashboardChrome` với `allowedRoles={ADMIN_ROLES}` giống `admin/questions/page.tsx`.
6. Thêm mục nav "Score Template" vào `ADMIN_NAV`.
7. Kiểm tra thủ công luồng đầy đủ trên môi trường dev: xem ACTIVE (22 dòng khớp bảng) → Clone → Edit (đổi vài giá trị) → Activate → quay lại list thấy bản mới ACTIVE, bản cũ RETIRED.

## Tests

Dự án `vendor-web` hiện chưa có bộ test UI tự động cho các feature admin tương tự (`questionbank`, `tenancy`) — kiểm tra lại thư mục `pte-web/apps/vendor-web` xem có `*.test.tsx`/Playwright nào trước khi quyết định; nếu có sẵn convention test cho feature khác, viết theo đúng convention đó cho `scoretemplate`. Tối thiểu:

- `tsc --noEmit` (hoặc `next build`) cho `vendor-web` và `packages/api-client` — không lỗi kiểu.
- Nếu project có lint script (`pnpm lint`/`npm run lint` ở `pte-web`), chạy và xác nhận sạch cho các file mới.
- Kiểm tra thủ công (không tự động hoá) luồng end-to-end mô tả ở Steps #7, vì đây là màn hình admin không có test tự động sẵn trong repo hiện tại — nêu rõ đây là giới hạn được chấp nhận, không phải bỏ sót.

## Success Criteria

- `pnpm build` (hoặc lệnh build tương ứng của repo) cho `vendor-web` + `packages/api-client` thành công.
- Trang `/admin/score-template` hiển thị đúng 22 dòng của template ACTIVE, giá trị khớp bảng V5 (đối chiếu bằng mắt với bảng ở Phase 1, hoặc so với response JSON thật của API).
- Luồng Clone → Edit → Activate hoạt động qua UI thật (không cần API test riêng vì Phase 1 đã cover phần backend), sau khi Activate thì `/admin/score-template` liệt kê đúng 1 ACTIVE mới.
- Chỉ `PLATFORM_ADMIN` truy cập được các trang này (`allowedRoles={ADMIN_ROLES}` — đã có sẵn cơ chế `DashboardChrome`, chỉ cần dùng đúng).

## Risks

- `packages/api-client` hiện có một số path lệch giữa comment và backend thật (vd `QUESTION_ENDPOINTS` ghi `/api/authoring/questions` nhưng `QuestionController` thật map ở `/questions`) — không lặp lại lỗi này cho `scoretemplate`, phải đọc đúng `@RequestMapping` thật của Phase 1 trước khi viết endpoint path, không copy pattern cũ mù quáng.
- Không có test UI tự động sẵn có trong repo cho các trang admin dạng này — rủi ro regression im lặng nếu sau này có người sửa lại `_ScoreTemplateItemTable`; chấp nhận được vì cùng mức rủi ro với các feature admin khác đã có (`questionbank`, `tenancy`).
- Trang edit DRAFT không tự chặn khi admin cố sửa 1 template không phải DRAFT nếu backend không trả lỗi rõ ràng — đảm bảo Phase 1's `ScoreTemplateNotDraftException` map ra một mã lỗi HTTP dễ phân biệt (409) để UI hiện thông báo đúng thay vì lỗi chung chung.
