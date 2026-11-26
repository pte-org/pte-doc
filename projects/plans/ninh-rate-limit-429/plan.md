# Lỗi "We couldn't complete this action" thỉnh thoảng hiện (429 Rate limit exceeded)

**Trạng thái:** đã sửa phía api-client, chưa commit.

## Chuyện gì xảy ra
- API có bộ giới hạn tần suất (`RateLimitFilter`, Bucket4j/Redis): 40 yêu cầu/giây cho mỗi người dùng, 200/giây cho cả tổ chức, 10/giây cho mỗi địa chỉ chưa đăng nhập. Vượt thì trả `429 "Rate limit exceeded. Try again shortly."` kèm `Retry-After: 1`.
- Một lần mở trang gửi ~12 yêu cầu cùng lúc (đo ở `/host/classes`), thêm refetch khi quay lại tab, nhiều tab, DevTools "Disable cache" (preflight CORS mỗi lần)... nên thỉnh thoảng một nhóm yêu cầu chạm giới hạn trong cùng giây.
- Giao diện không xử lý 429: câu hỏi báo lỗi chung bằng tiếng Anh, không tự thử lại. Chuông thông báo (`unread-count`, hỏi mỗi vài chục giây) là yêu cầu hay bị thấy nhất.
- Tái hiện bằng `curl`: 16 yêu cầu ẩn danh song song → 13×401 + 3×429; 45 yêu cầu có token song song → 40×200 + 5×429. Tốc độ bình thường (2–3 yêu cầu/giây) không bao giờ bị 429; sau một cú dồn 50 yêu cầu thì hồi phục ngay.

## Đã sửa (`packages/api-client`)
- `authRetry.ts`: gặp 429 có `Retry-After` ≤ 3 giây thì chờ đúng thời gian đó (+ nhiễu tới 250 ms) rồi gửi lại, tối đa 2 lần. Bộ giới hạn từ chối trước khi xử lý nên gửi lại không làm việc gì hai lần. Không `Retry-After` hoặc chờ lâu thì báo lỗi như cũ. Áp dụng cho cả tenant-web và vendor-web.
- `errorMessage.ts`: nếu 429 vẫn lọt tới giao diện, hiện "The system is busy right now. Please wait a few seconds and try again." thay cho câu lỗi chung.
- Test mới `client.rateLimit.test.ts`.

## Chưa làm / ghi nhận
- Câu thông báo trên vẫn là tiếng Anh (danh mục lỗi dùng chung chưa có bản dịch).
- Không đổi cấu hình giới hạn ở backend. Nếu muốn thoáng hơn khi phát triển: đặt `RATE_LIMIT_PER_SECOND` lớn hơn trong `.env`.

## Vòng 2: tiếng Việt và trang lỗi
- `api-client/errorMessage.ts`: bản tiếng Việt cho các câu chung (không kết nối được, hệ thống đang bận khi 429, lỗi theo loại: hết phiên, không có quyền, xung đột, máy chủ…). Thêm `setUserMessageLanguage`; `LocaleProvider` (`@pte/ui`) gọi nó mỗi khi đổi ngôn ngữ, nên cả tenant-web và vendor-web đều theo ngôn ngữ đang chọn. Câu của từng mã lỗi riêng (ví dụ `PLAN_ARCHIVED_NOT_EDITABLE`) vẫn là tiếng Anh.
- `tenant-web/features/examoperations/errorMessage.ts`: bỏ câu tiếng Anh mặc định cứng, dùng câu chung theo ngôn ngữ.
- Trang lỗi dùng chung (`ErrorPage`) thêm kiểu `rateLimited` (429, "Hệ thống đang bận", VI + EN). Màn Lớp học (`ClassesListView`) khi tải danh sách lỗi giờ hiện trang lỗi này, có nút "Thử lại", thay cho một dòng `Alert`.
- Các danh sách khác (Chương trình, Học viên…) vẫn dùng `Alert`/`ErrorState` như cũ; chưa đổi.
