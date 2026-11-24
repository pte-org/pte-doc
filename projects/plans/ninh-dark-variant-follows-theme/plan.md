# Chữ "Ai xử lý" khó đọc ở light mode (`/admin/ai/prompts`)

## Nguyên nhân
Tailwind v4 mặc định áp biến thể `dark:` theo hệ điều hành (`prefers-color-scheme`), còn app đổi giao diện bằng `data-theme` trên `<html>`.
Máy bật dark mode nhưng app ở light thì các chip LLM / Kokoro TTS / Vẽ biểu đồ vẫn nhận màu của dark (chữ `*-200` nhạt, nền `/25`), nên chữ nhạt trên nền nhạt.
Đo trên trình duyệt: `color: lab(84)` ở theme light khi OS dark.

## Sửa
`packages/ui/src/styles/design-tokens.css`: `@custom-variant dark (&:where([data-theme="dark"], [data-theme="dark"] *));` — `dark:` giờ theo công tắc của app (dùng chung tenant-web và vendor-web).
Ảnh hưởng: 12 file có dùng `dark:` nay theo theme của app thay vì hệ điều hành (đúng ý định).

## Kết quả
- Light (OS vẫn dark): chữ LLM `rgb(51,89,210)`, nền `/10` — đọc rõ. Dark: chữ `rgb(182,198,255)` — giữ nguyên như trước.
- Chưa rà từng màn khác dùng `dark:` bằng mắt; chưa có test tự động cho phần CSS này.

## Thanh danh mục của màn Prompt
- Gộp một khung: `Tabs` có thuộc tính `flat` (chỉ rail dọc) và `TabRailCard` có `flatRail`; bỏ viền và khay xám của rail, mục chọn có thanh màu bên trái. Mặc định `false` nên 4 màn khác dùng `TabRailCard` không đổi.
- Chấm màu theo loại: `PromptsView` truyền `icon` là chấm màu của `categoryTone` (cùng màu trang chi tiết prompt).
- Không làm "sticky": `TabRailCard` đã cho rail và nội dung là hai vùng cuộn riêng ở màn rộng (lg+), nên rail đứng yên khi cuộn bảng.
- Kiểm tra: tsc sạch, vitest ui và vendor-web qua, xem trên trình duyệt ở 1300px.

### Vòng 2: bớt card chồng card
- `TabRailCard flatRail` còn bỏ luôn thẻ bao ngoài rail + nội dung (`Frame`); `DataTable frameless` (mặc định `false`) bỏ viền và bo góc của bảng. Màn Prompt bật cả hai nên rail và bảng nằm thẳng trên khung của trang, không còn thẻ trong thẻ và không còn ô trống có viền dưới rail.
- Màn khác dùng `TabRailCard` hoặc `DataTable` không đổi. Kiểm tra: tsc, eslint, vitest ui 398 và vendor-web 748, xem trên trình duyệt.

### Vòng 3: góp ý về bảng Prompt (đối chiếu với code)
| Góp ý | Kết luận |
|---|---|
| "Ai xử lý" viết thường | Đúng (lỗi chính tả copy VI). Đổi "AI xử lý". |
| Nhãn "AI nghe audio (practice)" trộn Anh-Việt, badge xám | Đúng. Đổi "AI nghe audio (luyện tập)", thêm màu xanh lá riêng cho tag `AI_AUDIO` (trước rơi về màu xám mặc định). |
| Tên prompt toàn mã, tách 2 dòng | Làm theo dữ liệu có sẵn: API trả `title` cho mục Sinh đề ("Answer Short Question (ASQ)"), nên hiện tên + mã mono nhỏ. Mục Chấm điểm có `title` = mã nên giữ một dòng, không tự đặt tên. |
| Thiếu ô tìm kiếm | Đúng. Bật tìm theo tên hoặc mã. |
| Phân trang 10 dòng | Đổi mặc định 20. |
| Mục "Khối dùng chung" sát số đếm | Rail rộng tối thiểu 12rem. |
| Thêm tiêu đề trang | Không làm: shell đã có breadcrumb và mục menu đang chọn; chưa thêm header riêng. |
| Thêm cột mô tả/phiên bản/cập nhật | Không làm: API chỉ có `key`, `title`, `tags`. |
| Bấm cả dòng để xem | Không làm: `DataTable` chưa có hỗ trợ; cần đổi thành phần chung. |
| Bọc bảng trong card có viền | Không làm: trái với yêu cầu bỏ card chồng card ở vòng trước. |
| Tô xanh nút trang đang chọn | Không làm: `DataTable` dùng chung nhiều màn. |
Kiểm tra: tsc, eslint, vitest vendor-web 748; xem trên trình duyệt (ô tìm kiếm, badge xanh lá, rail rộng hơn).

### Vòng 4: tab ngang cho màn Prompt
- `PromptsView`: bỏ cột dọc, dùng `Tabs` ngang (kiểu gạch chân) với tab "Tất cả" (tổng 42 = 23+1+14+1+3) và 5 nhóm có chấm màu + số đếm. Lựa chọn tab vẫn được nhớ (`useRememberedState`, mặc định "Tất cả"; giá trị đã lưu cũ vẫn hợp lệ).
- Tab "Tất cả" thêm cột "Nhóm" (badge màu theo nhóm) vì cùng một tên prompt có ở nhiều nhóm (vd. `ANSWER_SHORT_QUESTION` ở Sinh đề và Chấm điểm). Tìm kiếm khớp theo tên, mã và nhóm trên mọi nhóm.
- `flatRail` của `TabRailCard` và `frameless` của `DataTable` (thêm ở vòng 1-2) giữ lại cho dùng sau; màn Prompt chỉ còn dùng `frameless`.
- Kiểm tra: tsc, eslint, vitest vendor-web 748, xem trên trình duyệt.

### Vòng 5: trang chi tiết prompt bị trống một cột
- `_PromptWorkspace`: lưới 2 cột (editor + cột 22rem bên phải) luôn được vẽ, nhưng cột phải chỉ có nội dung khi có đề xuất (proposal) để duyệt hoặc để chạy thử. Khi không có thì để lại một cột trống. Nay chỉ chia 2 cột khi có nội dung cho cột phải (`hasSidePanel`), còn lại editor chiếm toàn chiều ngang.
- Có đề xuất thì giao diện giữ nguyên. Đã xem trên trình duyệt: prompt `ANSWER_SHORT_QUESTION` (chưa có đề xuất) editor full width; chưa xem trang có đề xuất vì chưa tạo đề xuất thử.
