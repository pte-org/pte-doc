# Việc còn lại sau bản đầu tiên của chat box AI

**Cập nhật:** 2026-10-29 · Ghi lại những gì **đã làm thêm sau khi review**, những gì **chưa làm và vì sao**, để người sau không phải đoán. Không phải kế hoạch đã được duyệt: mỗi mục "chưa làm" cần một quyết định.

## 1. Đã làm thêm (có test)

| Việc | Ở đâu | Ghi chú |
| --- | --- | --- |
| Test hợp đồng dữ liệu dùng chung hai repo | `pte-api/.../ChatApiContractTest` + `pte-api/app/src/test/resources/chat/api-contract-v1.json` + `pte-practice/features/chat/chat-api-contract.test.ts` | Backend kiểm nó phát ra đúng file mẫu qua controller và error handler thật; frontend kiểm nó đọc được đúng file đó. Đổi tên một field ở một phía thì test đỏ. Đã thử phá có chủ đích để chắc test bắt được. Test frontend tự bỏ qua khi repo backend không nằm cạnh. |
| Ẩn nút chat khi học viên chưa có quyền | `chat-availability.ts`, `useChatQuota.ts`, `ChatLayout.tsx` | `403` (chưa mở khoá luyện tập) hoặc `404` (backend tắt chat) làm nút, panel và phím tắt biến mất. Lỗi mạng, 5xx, 429 giữ nguyên nút. Wrapper layout giữ nguyên để bài tập không bị dựng lại. |
| Học viên rút lại đồng ý | `DELETE /api/v1/student/chat/consent`, `ChatPrivacyActions.tsx` | Xoá bản ghi đồng ý, chat đóng lại tới khi đồng ý lại. Hai bước xác nhận. |
| Học viên tự xoá lịch sử chat | `DELETE /api/v1/student/chat/history`, `ChatStudentDataService` | Xoá chữ, gỡ mã học viên và mã phiên, xoá phiên. **Không** trả lại lượt hỏi của ngày (nếu không xoá lịch sử sẽ thành cách mua thêm lượt). Cả hai endpoint **không kiểm tra quyền luyện tập**: học viên hết hạn gói vẫn lấy lại được dữ liệu của mình, nhưng nút chỉ hiện trong panel nên họ phải qua email (xem 2.3). |
| Báo cáo dùng và chi phí cho PM | `GET /api/v1/admin/chat/usage?from=YYYY-MM-DD&to=YYYY-MM-DD`, chỉ `PLATFORM_ADMIN` | Theo ngày giờ Việt Nam, đủ mọi ngày trong khoảng (tối đa 366 ngày): số tin theo trạng thái, số lần trả từ cache, token vào/ra/suy nghĩ, chi phí ước tính. Không có gì về học viên hay nội dung. Giá cấu hình bằng `CHAT_AI_PRICE_INPUT_PER_MILLION_USD` (mặc định 0,10) và `CHAT_AI_PRICE_OUTPUT_PER_MILLION_USD` (0,40), theo Gemini 2.5 Flash-Lite lúc viết; **hoá đơn của Google mới là số thật**. |

## 2. Chưa làm, và cần quyết định

### 2.1 Màn hình báo cáo trên admin web (pte-web) — **ĐÃ LÀM 2026-10-29**
Trang `/admin/chat-usage` trong `pte-web/apps/vendor-web` (menu System, mục "Mức dùng chat AI" / "AI chat usage", chỉ `PLATFORM_ADMIN` thấy). Làm theo quy ước của repo: `features/chatUsage/{api.ts,constants.ts,components,utils}`, hook TanStack Query qua `@pte/api-client` (`getChatUsage`, type `ChatUsageDayResponse`), các thành phần chung của `@pte/ui` (`PageHeader`, `DataTable`, `DateRangePicker`, `DashboardCard`, `Alert`), chữ VI/EN nằm trong constants, lỗi API qua `getUserFacingApiErrorMessage`. Hiển thị 5 thẻ tổng (số tin, chi phí ước tính, % trả từ cache, % lỗi, token vào/ra) và bảng theo ngày; mặc định 30 ngày gần nhất theo lịch Việt Nam, đổi được bằng bộ chọn khoảng ngày. Có ghi chú "chi phí là ước tính". Chưa có biểu đồ cột: bảng và thẻ đủ cho nhu cầu hiện tại, thêm biểu đồ khi PM yêu cầu. Kiểm trên trình duyệt với API giả (không có đăng nhập thật): thẻ và 30 dòng hiện đúng; chưa kiểm với backend thật.

### 2.2 Câu trả lời hiện dần từng chữ (streaming)
**Chưa làm có chủ đích**: đây là một tính năng riêng, không phải việc dọn dẹp, và có vài quyết định thiết kế:

- Câu trả lời hiện là JSON `{is_on_topic, markdown_content}` (structured output). Muốn hiện dần phải đọc chuỗi `markdown_content` khi nó còn dang dở trong một JSON chưa đóng. Cách khả thi: đặt `is_on_topic` lên đầu schema (`propertyOrdering`) để biết lạc đề trước khi có chữ, rồi dùng bộ đọc JSON tăng dần chỉ trích `markdown_content`. Cần chứng minh bằng test rằng Gemini giữ đúng thứ tự trường.
- Backend phải chuyển từ gọi `generateContent` sang `streamGenerateContent` (SSE), trả về cho trình duyệt qua SSE hoặc chunked response; web phải đọc luồng bằng `fetch` + `ReadableStream` (kèm token và huỷ khi đóng panel), không dùng `EventSource` được vì cần header `Authorization`.
- Các quy tắc hiện có phải giữ đúng khi luồng đứt giữa chừng: trừ lượt trước khi gọi, **hoàn lượt** nếu lỗi, lưu dòng FAILED, nhả khoá từng học viên và ổ gọi đồng thời (giờ giữ lâu hơn).
- Cache: chỉ lưu câu trả lời khi luồng kết thúc đủ và hợp lệ; câu từ cache vẫn có thể hiện ngay.
- Markdown dang dở (bảng, code chưa đóng) phải hiển thị được mà không vỡ; đã có bộ render an toàn nhưng cần thử với văn bản cụt.
- Lợi ích thật: cảm giác nhanh hơn với câu trả lời dài. Chi phí: khoảng một đến hai tuần công, rủi ro cao hơn các việc khác. Nên làm **sau** khi chạy bộ prompt với key thật và đo thời gian trả lời thực tế; nếu câu trả lời thường dưới vài giây thì lợi ích nhỏ.

Quyết định cần có: có làm streaming không, và khi nào (đề xuất: chờ số đo thời gian thật).

### 2.3 Học viên hết hạn gói không thấy nút xoá dữ liệu
Hai nút "Rút lại đồng ý" và "Xoá các đoạn chat của tôi" nằm trong panel chat; học viên chưa có quyền luyện tập không thấy panel (vì nút chat bị ẩn). Họ vẫn yêu cầu được qua email theo chính sách bảo mật và script trong `ops-runbook.md`. Nếu pháp lý yêu cầu họ tự làm được, cần một chỗ khác trong giao diện (ví dụ trang cài đặt hoặc ngay trang `/privacy`).

## 3. Vẫn chờ người khác (không phải code)

Key Gemini trả phí và budget alert; chạy bộ prompt với key thật; pháp lý duyệt chữ màn đồng ý và trang `/privacy`; thay email liên hệ bằng hộp thư dùng chung và xác nhận tên pháp nhân; kiểm tay với backend thật; hẹn nhà thiết kế. Chi tiết ở [release-checklist.md](./release-checklist.md).
