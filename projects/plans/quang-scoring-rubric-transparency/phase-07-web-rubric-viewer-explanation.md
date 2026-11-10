# Phase 7: vendor-web trang luật chấm (màn A) và tenant-web màn giải thích điểm (màn B)

## Mục tiêu

Hiển thị: (A) trên **vendor-web**, trang luật chấm cho 22 task type chuẩn (tiêu chí, thang, mô tả từng mức, điều kiện chặn, các mức Form, quy tắc khách quan, bảng ánh xạ Azure kèm nhãn "chưa hiệu chỉnh với dữ liệu người chấm", trọng số kỹ năng của mẫu đề đang xem, số trang Pearson);
(B) trên **tenant-web**, màn giải thích một lượt thi đã chấm đi từ điểm tiêu chí tới điểm 10-90, dành cho Host (lượt thi của trung tâm) và Examiner (lượt thi được phân công). FE chỉ **hiển thị dữ liệu từ API**, không tự viết lại luật. Vendor-web không có màn nào đọc dữ liệu lượt thi.

## Stories/FR covered

- S1 (22/22 task type có trang luật chấm), S3 (giải thích khớp chính xác báo cáo đã publish)
- FR-01, FR-07, FR-10

## Files to read first

- `D:\GitHub\pte-org\docs\CODING_STANDARDS_WEB.md` (đọc đủ: component <= 150 dòng, không inline style, không magic number, chuỗi người dùng vào constants/i18n, TanStack Query, không `any`, return type, route kebab-case, loading/error cho route)
- **vendor-web (A)**: `pte-web/apps/vendor-web/features/scoretemplate/` (`api.ts`, `constants.ts`, `components/ScoreTemplateListView.tsx`, `ScoreTemplateDetailView.tsx`, `_ScoreTemplateItemTable.tsx`, `TemplateInfoPanel.tsx`), `features/examstudio/`,
  `lib/apiClient.ts`, `lib/navigation.tsx`, `lib/navigationConstants.ts`, `lib/breadcrumbRoutes.ts`, `features/auth/constants.ts` (`ACADEMIC_ROLES`), `features/auth/permissions.ts`, `app/(dashboard)/admin/exam-template/page.tsx` và `[publicId]/page.tsx`, `features/i18n/` (cần xác minh vị trí khóa vi/en)
- **tenant-web (B)**: `pte-web/apps/tenant-web/features/exams/components/AttemptsSection.tsx` (danh sách lượt thi của Host, điểm vào của màn B), `ExamDetailTabs.tsx`, route `app/(dashboard)/host/exams/[publicId]/page.tsx`;
  phía giám khảo: `features/examiner/ExaminerAttemptDetailView.tsx`, `components/ExaminerAttemptHeader.tsx`, route `app/(dashboard)/examiner/work/[sessionPublicId]/[attemptPublicId]/page.tsx`, `features/examiner/api.ts`, `queryKeys.ts`, `constants.ts`, `messages/vi.ts`, `messages/en.ts`;
  `features/auth/resolveWorkspace.ts`, `components/DashboardChrome.tsx` (cách gate theo role; cần xác minh)
- `pte-web/packages/api-client/src/requests/scoretemplate/index.ts` (mẫu hàm và kiểu), `pte-web/packages/ui`
- Phase 2 (API đọc rubric, nhãn chưa hiệu chỉnh), Phase 6 (`ScoreExplanationResponse`, `rubricParameters`, `traceAvailable`)

## Implementation steps

1. **api-client**: `packages/api-client/src/requests/scoringrubric/index.ts` (danh sách/chi tiết task type, danh sách/chi tiết phiên bản — cho vendor-web) và `requests/scoreexplanation/index.ts` (kiểu `ScoreExplanationResponse`, hàm `GET /api/v1/reports/attempts/{attemptPublicId}/score-explanation`, **không có tham số so sánh phiên bản**);
   xuất qua `index.ts`; thêm `rubricVersionPublicId` (tùy chọn) vào `ScoreTemplateResponse`. Cần xác minh quy ước xuất và script `typecheck` của package.
2. **vendor-web feature `scoringrubric`** (`features/scoringrubric/`): `api.ts` (`useRubricTaskTypes`, `useRubricTaskType`, `useRubricVersions`), `constants.ts` (query key, nhãn), `types.ts`, `components/`: `RubricTaskTypeListView` (22 task type nhóm theo kỹ năng, lọc, thẻ "có cổng", tổng tối đa), `RubricDetailView`,
   `_TraitTable` (tiêu chí, thang, nguồn, trang; hàng mở rộng hiện **mô tả từng mức**), `_GateList`, `_FormBandTable`, `_ObjectiveRuleCard`, `_AzureBandMapping` (ngưỡng Azure -> 0-5, **nhãn "chưa hiệu chỉnh với dữ liệu người chấm" lấy từ API**), `_SkillWeightPanel` (trọng số S/W/R/L/Overall theo mẫu đề), `_TemplatePicker` (mặc định mẫu ACTIVE, hiện phiên bản rubric mẫu ghim).
   Mỗi component <= 150 dòng, không inline style, không màu thô.
3. **vendor-web route**: `app/(dashboard)/admin/scoring-rubric/page.tsx` và `[taskType]/page.tsx` kèm `loading.tsx`/`error.tsx`; mục điều hướng "Luật chấm" ở `lib/navigation.tsx` (nhóm Content, `requiredRoles: ACADEMIC_ROLES`), khóa i18n `nav.scoringRubric`, hằng ở `navigationConstants`, breadcrumb ở `lib/breadcrumbRoutes.ts`.
4. **tenant-web feature `scoreexplanation`** (`apps/tenant-web/features/scoreexplanation/`): `api.ts` (`useScoreExplanation(attemptPublicId)` bằng TanStack Query), `queryKeys.ts`, `constants.ts`, `messages/vi.ts` + `en.ts` (theo mẫu `features/examiner/messages`), `components/`: `ScoreExplanationView` (khung),
   `_ExplanationHeader` (mẫu đề, phiên bản rubric ghim, đã publish hay chưa), `_RubricParametersPanel` (tham số phiên bản ghim: trọng số tiêu chí, Form band, cổng; **nhãn "chưa hiệu chỉnh với dữ liệu người chấm" cho bảng Azure**), `_AnswerTraceList` + `_TraitRows` (từng câu: tiêu chí đạt/tối đa/trọng số/đóng góp, cổng kích hoạt, band Form, điểm câu),
   `_TaskTypeAverageTable` (số câu có điểm và số câu bỏ trống), `_SkillTraceTable` (w, avg, w × avg, Σ, tỉ lệ, `10 + 80 × tỉ lệ`, làm tròn; cùng cho Overall hoặc "không áp dụng"), `_NoTraceNotice` (khi `traceAvailable=false`). **Mọi con số lấy nguyên từ API**; FE không tính lại, không có công cụ so sánh phiên bản.
5. **tenant-web route và điểm vào**: Host: `app/(dashboard)/host/exams/[publicId]/attempts/[attemptPublicId]/score-explanation/page.tsx` (hoặc tham số query theo cách `ExamDetailTabs` đang dùng; cần xác minh), liên kết "Xem giải thích điểm" từ `AttemptsSection.tsx`;
   Examiner: `app/(dashboard)/examiner/work/[sessionPublicId]/[attemptPublicId]/score-explanation/page.tsx`, liên kết từ `ExaminerAttemptDetailView.tsx`/`ExaminerAttemptHeader.tsx`. Kèm `loading.tsx`/`error.tsx`; lỗi 403/404 hiển thị thông báo chung "không có quyền hoặc không tồn tại" (không rò thông tin).
   Chỉ role `HOST_ADMIN` và `EXAMINER` thấy liên kết; hiển thị phản ánh phân quyền backend (backend quyết định thật).
6. **Tiện ích thuần và test**: vendor (`tests/unit/features/scoringrubric/*.test.ts`): nhóm theo kỹ năng, định dạng `đạt/tối đa`, ghép trọng số mẫu đề. Tenant (`apps/tenant-web/tests/unit/features/scoreexplanation/*.test.ts`): map vết sang hàng bảng, quyết định hiển thị khi `traceAvailable=false`, định dạng nhãn chưa hiệu chỉnh,
   dựng đường dẫn từ vai trò, xử lý 403/404. Thêm test hygiene tương tự `tests/unit/features/dashboard/hygiene.test.ts` nếu phù hợp (cần xác minh).
7. **Chuỗi người dùng**: nhãn, chú thích, trống/lỗi vào constants/i18n (vi và en nếu app đang có cả hai); không chuỗi cứng trong JSX.

## Acceptance criteria

- vendor-web: danh sách đủ **22/22** task type; chi tiết hiển thị mọi tiêu chí kèm thang, mô tả từng mức (tự luận), điều kiện chặn, Form band, trọng số kỹ năng của mẫu đề đang xem, trang Pearson; khách quan hiển thị công thức; bảng Azure có nhãn chưa hiệu chỉnh.
- tenant-web: Host (lượt thi tenant mình) và Examiner (lượt thi được phân công) xem được chuỗi: điểm tiêu chí -> điểm câu -> trung bình task type (kèm số câu bỏ trống) -> `Σ(w × avg)/Σw` -> 10-90, từng kỹ năng và Overall; hiển thị tham số của phiên bản ghim (ACTIVE/RETIRED) và nhãn chưa hiệu chỉnh; mọi con số bằng API.
- Snapshot cũ/điểm không phân rã hiển thị chú thích, không lỗi; 403/404 hiển thị thông báo chung.
- **Vendor-web không có màn, route hay hook nào gọi API giải thích hay đọc dữ liệu lượt thi** (kiểm tra bằng tìm kiếm mã và test).
- `pnpm --filter vendor-web` và `--filter tenant-web` `typecheck`, `lint`, `test` xanh; component <= 150 dòng; không `any`, `@ts-ignore`, inline style; không Playwright.

## Validation commands

```powershell
cd D:\GitHub\pte-org\pte-web
pnpm --filter @pte/api-client typecheck      # cần xác minh tên script
pnpm --filter vendor-web typecheck; pnpm --filter vendor-web lint; pnpm --filter vendor-web test
pnpm --filter tenant-web typecheck; pnpm --filter tenant-web lint; pnpm --filter tenant-web test
```

Lưu ý ghi nhớ: nếu `pnpm add` làm xáo `eslint-config-next` trong lockfile, khôi phục lockfile về bản đã commit rồi chỉ thêm mục mới. Phase này không dự kiến thêm gói.

## Design Constraints

- `docs/CODING_STANDARDS_WEB.md` bắt buộc đọc đủ: component <= 150 dòng, Server Component mặc định khi không cần tương tác, TanStack Query phía client, không fetch trong `useEffect`, không `any`/`@ts-ignore`, return type, chuỗi trong constants, không inline style/màu thô/magic number.
- FE không chứa bản sao luật chấm: thang, mô tả mức, cổng, Form band, công thức đến từ API.
- Dữ liệu lượt thi chỉ ở tenant-web (Host/Examiner); vendor-web chỉ A (đọc rubric), C và D1; không đường nào cho vendor đọc dữ liệu lượt thi.
- Màn giải thích không hiển thị transcript, bài làm hay thông tin cá nhân học viên; không bao giờ hiển thị bản nháp rubric.
- Bảng Azure luôn kèm nhãn "chưa hiệu chỉnh với dữ liệu người chấm" ở cả màn A và B.
- Phân quyền hiển thị khớp backend; ẩn liên kết chỉ là tiện lợi. Không Playwright (tsc, eslint, vitest).
- Preflight (2026-11-05): đã đọc đủ `docs/CODING_STANDARDS_WEB.md` và `docs/API_RESPONSE_SETUP.md` (client đã bóc envelope `data`). Không đổi backend (API Phase 2 và 6 đủ dùng; `ExamDefinitionResponse` đã có `rubricVersionPublicId`). Quyết định khi làm:
  - api-client: `requests/scoringrubric` (`listRubricTaskTypes`, `getRubricTaskType`, `listRubricVersions`, `getRubricVersion`, tham số `versionId` tùy chọn), `requests/scoreexplanation` (`getScoreExplanation`, không có tham số phiên bản), kiểu ở `types/scoringrubric`, `types/scoreexplanation`; `ScoreTemplateResponse.rubricVersionPublicId?`.
  - Chuỗi người dùng: theo mẫu `features/dashboard/messages` (vendor) và `features/examiner/messages` (tenant): `messages/en.ts` + `vi.ts` cùng khóa, hook `useScoringRubricText`/`useScoreExplanationText` chọn theo locale; khóa nav `nav.scoringRubric` thêm vào `packages/ui` `LocaleProvider` (vi "Luật chấm"). Không thêm vào `adminCopy.ts`.
  - vendor-web: nhóm theo kỹ năng = một dạng bài xuất hiện dưới **mọi** kỹ năng nó tính vào (theo `skills` của API), bộ lọc kỹ năng, đếm 22 dạng bài theo mã duy nhất; "tổng tối đa" = tổng `maxScore` khai báo, tiêu chí theo từ hiển thị `N + ...` (không tự đặt số). Mẫu đề mặc định ACTIVE, chọn được mẫu khác hoặc "không mẫu" (rubric ACTIVE); mẫu ghim null dùng ACTIVE. Breadcrumb: mục sidebar `/admin/scoring-rubric` đã khớp tiền tố trang chi tiết nên không thêm `breadcrumbRoutes.ts`. Nhãn chưa hiệu chỉnh lấy từ `label` của API, chỉ dùng chữ cục bộ khi API gửi rỗng mà `calibrated=false`.
  - tenant-web: Host `host/exams/[publicId]/attempts/[attemptPublicId]/score-explanation` (nút ở cột hành động của `AttemptsSection`, quay lại `?tab=submissions`); Examiner `examiner/work/[sessionPublicId]/[attemptPublicId]/score-explanation` (nút trong `ExaminerAttemptHeader`). 403/404 cùng một thông báo, không thử lại; lượt thi khác `sessionPublicId` trên URL cũng hiển thị như "không xem được". Mỗi `traceKind` có câu giải thích riêng; `traceAvailable=false` hiện chú thích; Overall null hiện "không áp dụng".
  - **Lệch so với bước 4**: cột "đóng góp" từng tiêu chí **không** hiển thị vì `ScoreTrace` không có trường này và FE không được tự tính; màn hiển thị đạt/tối đa, trọng số hiệu lực, cổng kích hoạt và tỉ lệ chưa làm tròn (`rawPercent`) của API. Band Form của câu nằm ở dòng tiêu chí `FORM`.

## Quality and Testing State

- Quality: skipped_by_user
- Testing: passed (2026-11-05), chỉ tsc/eslint/vitest chạy từ `node_modules/.bin` (không `pnpm install`/`pnpm add`; `pnpm-lock.yaml` và mọi `package.json` giữ nguyên, đối chiếu md5). Nền trước phase → sau: `@pte/api-client` vitest 659 → **675** (36 file; +6 test mới, +10 ca tự sinh từ `endpoints.test.ts`), `tsc` exit 0; vendor-web vitest 252 → **281** (45 file; `rubricView` 12, `components` 11, `hygiene` 6), eslint 0 lỗi 2 cảnh báo (cũ, không đổi); tenant-web vitest 604 → **635** (52 file; `explanationView` 12, `components` 11, `hygiene` 8), eslint 0 lỗi 0 cảnh báo; `packages/ui` tsc exit 0, vitest 348/348 (24 file). `tsc --noEmit` của vendor-web (1 lỗi) và tenant-web (2 lỗi) chỉ báo lỗi trong `.next/types/validator.ts` sinh từ lần build cũ, **giống hệt nền trước phase**; mã nguồn không có lỗi kiểu. Test hygiene khẳng định: không inline style/màu thô/`any`/`@ts-ignore`, file <= 300 dòng, component <= 150 dòng, đủ `page/loading/error` cho 4 route, khóa vi/en khớp, vi chứa đúng "chưa hiệu chỉnh với dữ liệu người chấm", **không nguồn nào của vendor-web gọi API giải thích hay báo cáo lượt thi**, chỉ `features/scoreexplanation/api.ts` gọi endpoint giải thích, liên kết chỉ ở `AttemptsSection` (HOST_ADMIN) và `ExaminerAttemptHeader` (EXAMINER), tenant feature không có phép tính trên điểm/trọng số. **Chưa kiểm chứng:** chạy trên trình duyệt (người dùng tự kiểm tra), gọi API thật (đủ 22/22 dạng bài, khớp số với báo cáo đã publish chỉ được bảo đảm bởi backend Phase 2/6), `next build`.

## Risks

- Cấu trúc route Host cho lượt thi (`host/exams/[publicId]`) khác giả định: xác minh `ExamDetailTabs`/`AttemptsSection` trước khi chốt đường dẫn.
- Mô tả mức tiếng Anh dài làm trang nặng: hàng mở rộng/tab theo tiêu chí.
- Kiểu api-client lệch DTO: sinh theo DTO Phase 2 và 6, `typecheck` cả package và hai app.
- Cấu trúc i18n hai app khác nhau: xác minh trước khi thêm khóa; giữ test catalog thông điệp xanh.
