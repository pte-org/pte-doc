# Phase 4: FE `features/chat` (side panel)

**Repo:** `pte-practice` · **Ước lượng:** 2.5–3.5 ngày (kể cả responsive và spike CSS) · **Phủ:** FR-06, FR-07, P1 (UI quota/giới hạn 1000 ký tự), P2 (side panel, markdown, disclaimer), NFR-02 (không `dangerouslySetInnerHTML`)

## Requirements
Trong màn làm bài, học viên bật/tắt một side panel chat đẩy nội dung bài tập sang bên (overlay trên màn nhỏ), gửi câu hỏi, xem câu trả lời markdown, thấy quota/cảnh báo/giờ reset, bắt đầu "Đoạn chat mới", và tải lại trang vẫn thấy phiên gần nhất.

## Design Constraints
- Phải đọc `AGENTS.md` và hướng dẫn trong `node_modules/next/dist/docs/` trước khi viết mã Next (repo ghi rõ đây không phải Next quen thuộc: Next 16.4, `cacheComponents`).
- Render nội dung AI chỉ qua `react-markdown` + `remark-gfm`; không `dangerouslySetInnerHTML`, không `rehype-raw`, không HTML, chặn `img`, link mở tab mới `noopener noreferrer` và chỉ cho `href` scheme `http`/`https`/`mailto` (giữ `urlTransform` mặc định).
- Hành vi spec "bảng và `pre` bọc `overflow-x-auto`, nội dung `break-words`" được thực hiện bằng **CSS tay có phạm vi** của panel chat, không bằng Tailwind utility (app gần như không dùng utility và `globals.css` không import `tailwindcss`). Đây là đổi cơ chế, không đổi hành vi. `@tailwindcss/typography` chỉ dùng cho kiểu chữ văn xuôi và chỉ khi spike chứng minh nạp được mà không kèm preflight.
- Phương án dự phòng nêu trước: nếu spike không nạp được typography an toàn, bỏ `@tailwindcss/typography` và viết CSS tay có phạm vi cho cả văn xuôi (tiêu đề, danh sách, đoạn, code), rồi báo lại vì spec có nêu plugin này.
- Không để chuỗi người dùng hay hằng số rải rác: chuỗi qua i18n (`common/i18n/{types,en,vi}.ts`), hằng số tập trung trong `features/chat/constants.ts` (theo AD-02/AD-03 của plan 261026).
- Không thêm kiểu reset CSS toàn cục: không được làm đổi giao diện các trang hiện có.
- Server là nguồn sự thật cho quota và `session_id` gần nhất; client chỉ tạo `session_id` mới khi bấm "Đoạn chat mới", hoặc để sinh UUID **đầu tiên** khi server không trả phiên gần nhất (student mới — không phải nút "Đoạn chat mới"). Ô nhập + nút gửi khoá khi đang xử lý và khi hết lượt; lỗi giữ nguyên nội dung đã gõ.
- `taskType` gửi lên là giá trị thuộc whitelist enum các dạng bài PTE (cùng tập với `LocaleDict.tasks`/server); giá trị lạ thì bỏ qua thay vì gửi chuỗi tự do.
- Chỉ web `pte-practice`; không đụng Flutter. Dùng **npm** (có `package-lock.json`); `pnpm-lock.yaml` tồn tại trong repo nhưng không được cập nhật.

## Steps
1. Spike thiết lập (làm đầu tiên): cài `react-markdown`, `remark-gfm` và thử `@tailwindcss/typography` bằng npm (kiểm peer deps với React 19.3; cập nhật `package-lock.json`, không đụng `pnpm-lock.yaml`). Vì `app/globals.css` không import `tailwindcss` mà chỉ có loader `@tailwindcss/turbopack`, thử nạp typography trong một file CSS riêng của chat với theme + utilities nhưng không preflight; xác nhận kiểu `prose` hoạt động và trang chủ/phiên không đổi giao diện. Ghi kết quả vào đầu file CSS; nếu thất bại, chuyển sang phương án dự phòng (CSS tay cho cả văn xuôi) và báo lại.
2. Chốt hợp đồng với BE (có thể dùng mock nếu BE chưa xong): đường dẫn endpoint trong `API_PATHS`, kiểu dữ liệu (`contracts.ts` chuẩn hoá response như `features/practice/contracts.ts`), mã lỗi (`CHAT_QUOTA_EXCEEDED`, `CHAT_REQUEST_IN_FLIGHT`, `CHAT_BUSY`), tập `taskType` whitelist. Mở rộng `PracticeApiError` bằng trường `data` tuỳ chọn (tương thích ngược) để đọc `resetAt` từ lỗi 429; thêm test cho thay đổi này.
3. Viết `features/chat/{constants,contracts,api}.ts` dùng lại `practiceRequest` (Bearer + refresh) và các hàm thuần có test: kiểm tra độ dài ≤ 1000/rỗng, tính "còn X giờ Y phút" từ `resetAt`, ngưỡng cảnh báo ≤ 3, sinh `session_id` UUID v4, lọc `taskType` theo whitelist, kiểm tra scheme link, ánh xạ lỗi → khoá i18n.
4. Viết hook `useChatQuota` (nạp khi mở panel, cập nhật theo response/429) và `useChatSession` (nạp phiên gần nhất + lịch sử từ server khi mount; nếu server không trả phiên nào thì sinh UUID đầu tiên ở client; gửi tin với `session_id`, `taskType`, ngôn ngữ UI; trạng thái loading/lỗi; "Đoạn chat mới" sinh `session_id` mới và xoá danh sách tin hiển thị); chống gửi trùng khi đang xử lý, dùng `common/hooks/latest-request` nếu phù hợp để bỏ kết quả cũ.
5. Viết giao diện: nút bật/tắt, `ChatPanel` (tiêu đề + "Đoạn chat mới", danh sách tin, ba chấm khi chờ, thanh cảnh báo quota, thông báo hết lượt kèm giờ reset, ô nhập có đếm ký tự, disclaimer cố định dưới ô nhập), thành phần render markdown với `table` bọc wrapper cuộn ngang, `pre` cuộn ngang, `break-words`, override `a` (chỉ http/https/mailto) và `img` (chặn) — toàn bộ quy tắc cuộn/ngắt dòng là CSS tay có phạm vi dưới một lớp gốc của panel. Disclaimer tiếng Việt đúng nguyên văn: "Đoạn chat được lưu lại để kiểm tra chất lượng dịch vụ và cải thiện AI. Đừng chia sẻ thông tin cá nhân." (bản tiếng Anh do PM/pháp lý duyệt).
6. Thêm khoá i18n `chat.*` vào `LocaleDict` (`types.ts`), `en.ts`, `vi.ts`; không còn chuỗi cứng trong component.
7. Gắn vào màn làm bài theo Open Decision d (khuyến nghị D1: bọc nhánh render chính của `features/practice/PracticeSessionView.tsx`; lấy `taskType` của task hiện tại — tên trường cần xác minh trong `contracts.ts`/kiểu task). CSS layout đẩy nội dung ở màn rộng, overlay ở màn nhỏ (breakpoint theo `globals.css`), giữ nguyên `.practice-session { max-width: 1100px }`; chốt layout cuối với UI/UX Designer.
8. Viết test Vitest (môi trường node, không có testing-library): hàm thuần (độ dài, đếm ngược, ngưỡng cảnh báo, UUID, whitelist `taskType`, scheme link, ánh xạ lỗi), chuẩn hoá contract, `PracticeApiError.data`, và `renderToStaticMarkup` cho thành phần markdown (bảng có wrapper cuộn, `<script>`/HTML thô bị escape, `img` bị chặn, link có `rel` và scheme lạ như `javascript:` không thành link), cho trạng thái hết lượt/cảnh báo. Chạy `npm ci`, `npm run lint`, `npm run test:unit`, `npm run typecheck`, `npm run build`; kiểm thủ công bằng trình duyệt với BE đang chạy (đặt `practice.strict-entitlement.enabled=true` phía BE, nếu không chat trả 403).

## Files
- `pte-practice/package.json` + `pte-practice/package-lock.json` — thêm `react-markdown`, `remark-gfm`; dev: `@tailwindcss/typography` (nếu spike nạp được); `pnpm-lock.yaml` không sửa
- `pte-practice/features/chat/constants.ts` — đường dẫn, giới hạn, ngưỡng, whitelist `taskType`, tên storage nếu có
- `pte-practice/features/chat/contracts.ts` · `api.ts` — hợp đồng + gọi API qua `practiceRequest`
- `pte-practice/features/chat/chat-quota.ts` · `chat-input.ts` · `chat-session-id.ts` · `chat-links.ts` (+ `*.test.ts`) — hàm thuần (tên cuối có thể gộp)
- `pte-practice/features/chat/useChatQuota.ts` · `useChatSession.ts` — hook
- `pte-practice/features/chat/ChatPanel.tsx` · `ChatToggleButton.tsx` · `ChatMarkdown.tsx` (+ `*.test.tsx`) — giao diện
- `pte-practice/features/chat/chat.css` (hoặc phần cuối `app/globals.css`) — layout panel + CSS tay có phạm vi cho markdown (+ typography nếu spike đạt)
- `pte-practice/features/practice/api.ts` — thêm `data` vào `PracticeApiError`
- `pte-practice/features/practice/PracticeSessionView.tsx` — mount panel + layout đẩy nội dung
- `pte-practice/common/i18n/{types,en,vi}.ts` — khoá `chat.*`

## Success Criteria
- `npm ci` thành công; `npm run typecheck` 0 lỗi; `npm run test:unit` xanh (các test hiện có không hỏng); `npm run lint` không lỗi mới; `npm run build` thành công. `package-lock.json` đã cập nhật, `pnpm-lock.yaml` không đổi.
- Với BE chạy: gửi tin nhận markdown (bảng, danh sách, code) hiển thị đúng; bảng/`pre` cuộn ngang, không tràn panel; chuỗi dài ngắt dòng, không phá layout.
- Còn ≤ 3 lượt hiện cảnh báo kèm giờ reset; 0 lượt khoá ô nhập + nút gửi và hiện "còn X giờ Y phút" từ `resetAt` của server; tin > 1000 ký tự bị chặn ở client.
- Đang xử lý: ba chấm, ô nhập + nút gửi khoá; lỗi (409/503/mạng) giữ nguyên nội dung đã gõ và hiện thông báo i18n.
- Tải lại trang: panel nạp đúng `session_id` gần nhất và lịch sử từ server; student mới (server không trả phiên) thì client sinh UUID đầu tiên; chỉ "Đoạn chat mới" đổi `session_id` về sau.
- Disclaimer luôn hiện dưới ô nhập; `grep` không thấy `dangerouslySetInnerHTML` trong `features/chat`; link chỉ http/https/mailto; giao diện trang chủ/phiên không đổi so với trước khi thêm CSS chat.
- Màn hẹp (≤ breakpoint hiện có) panel là overlay, màn rộng đẩy nội dung bài tập sang bên.

## Quality and Testing State
- Quality gate: approved after one remediation round (report: plans/261028-ninh-practice-ai-chat-box/quality/phase-04-fe-chat-panel-quality-report.json; receipt: plans/261028-ninh-practice-ai-chat-box/quality/phase-04-fe-chat-panel-receipt.json; 0 blocking, 5 NOTED). Fixed: toggle covered the footer buttons, a failed session load minted a client session id, accessibility and quota-expiry gaps. Accepted debt: no dialog semantics or focus trap for the narrow overlay.
- Testing: passed - report `plans/261028-ninh-practice-ai-chat-box/tests/phase-04-fe-chat-panel-test-report.json` (63 files / 558 tests pass, typecheck and lint clean; `npm run build` compiled and prerendered all routes, exit 0, with a Next.js 16.4.0 security-advisory warning about the installed next version - external dependency matter, not part of this phase)

## Risks
- Typography/tailwind làm đổi CSS toàn cục: spike ở bước 1, import không preflight, so sánh trực quan; phương án dự phòng CSS tay cho cả văn xuôi.
- `react-markdown` ESM-only hoặc peer deps với React 19.3 lỗi trong Vitest/build: test bằng `renderToStaticMarkup`, cấu hình `server.deps.inline` nếu cần; phương án cuối là báo lại trước khi đổi thư viện.
- Hai file khoá (`package-lock.json` và `pnpm-lock.yaml`) lệch nhau: chỉ cập nhật `package-lock.json` như yêu cầu, ghi chú để người dùng quyết định về `pnpm-lock.yaml`.
- `PracticeSessionView` đã dài, nhiều nhánh return: bọc bằng một thành phần layout nhỏ, không nhét logic chat vào view.
- Layout đẩy nội dung ảnh hưởng thiết bị ghi âm/đếm giờ của bài: kiểm thủ công trên task Speaking và task có đồng hồ.
- BE chưa sẵn sàng khi làm FE: dùng mock API trong test và chạy song song với Phase 2/3; chốt hợp đồng ở bước 2 trước khi viết hook.
- `taskType` lấy từ nguồn sai/không có: bỏ qua thay vì chặn chat; xác minh tên trường ở bước 7.
