# Chặn trùng MST / email khi nộp đơn đăng ký tổ chức

## Vấn đề
Tên và mã tenant bị chặn trùng ngay lúc nộp đơn (`status <> 'REJECTED'`), nhưng mã số thuế chỉ bị chặn khi duyệt
(index `uq_org_tax_code_approved` chỉ phủ ACTIVE/SUSPENDED) và email/SĐT không bị kiểm tra. Kết quả: nhiều đơn PENDING cùng
MST + email, đến lúc duyệt đơn thứ 2 mới lỗi.

## Quyết định
- **MST**: chặn ngay lúc nộp nếu đã có tổ chức không phải REJECTED giữ MST đó (đồng bộ với tên/mã). REJECTED giải phóng MST.
  Áp dụng cả `onboardDirect` của vendor.
- **Email**: chặn khi cùng email (không phân biệt hoa thường) đang có đơn PENDING (mức tối thiểu, chống nộp đúp/spam).
  Email của tổ chức đã duyệt/bị từ chối không bị chặn.
- **SĐT**: cho phép trùng (hotline/chi nhánh dùng chung).
- **Không đổi index DB**: dữ liệu hiện có đã chứa đơn PENDING trùng MST, tạo unique index mới sẽ làm migration fail.
  Kiểm tra ở tầng service; kiểm tra lúc duyệt (`approveApplication`) vẫn giữ làm lưới an toàn.

## Thay đổi
- pte-api: `OrganizationRepository.existsByContactEmailIgnoreCaseAndStatus`, `TenancyService.existsByTaxCode / hasPendingApplicationForEmail`,
  `TenantApplicationService.submit/onboardDirect`, mã lỗi `APPLICATION_EMAIL_ALREADY_PENDING` (409) + `ApplicationEmailAlreadyPendingException`.
- pte-web: thông báo VI/EN `duplicateEmail` ở trang đăng ký tenant, catalog `errorMessage.ts`.
- Test: `TenantApplicationServiceTest` (MST trùng, email đang chờ).

## Kết quả thực hiện
- `TenantApplicationServiceTest`: 15/15 pass (thêm 2 test mới).
- tenant-web: `tsc --noEmit` và eslint `features/auth` sạch.
- **Bổ sung theo yêu cầu**: xóa 2 đơn PENDING trùng MST123456 ở DB local; thêm `V55__organization_tax_code_unique_while_live.sql`
  (tự từ chối các đơn PENDING trùng MST còn sót — giữ đơn đã duyệt hoặc đơn cũ nhất — rồi thay `uq_org_tax_code_approved` bằng
  `uq_org_tax_code_live` `WHERE status <> 'REJECTED'`). Cập nhật dev-seed, ánh xạ lỗi ràng buộc, và `submit` giờ dịch lỗi
  unique-index thành 409 khi hai request đồng thời. V55 cao hơn V54 trên origin/dev (V54 do nhánh khác dùng cho drop_proctor_assignment_role; đã đổi số khi merge dev). Đã chạy thử migration trong transaction rollback trên DB local: OK.
- Chưa chạy test tích hợp Postgres và chưa thử trên trình duyệt với API thật.

## Giới hạn
- Chưa có unique index nên 2 request đồng thời cùng MST vẫn có thể lọt (hiếm; bị chặn lại ở bước duyệt).
- Đơn PENDING trùng MST đã tồn tại trong DB không bị xử lý lại; admin cần từ chối thủ công.
- Chưa có cảnh báo trên bảng admin cho đơn nghi trùng (đề xuất tách riêng).

## Bổ sung: email hỗ trợ
- Biến `NEXT_PUBLIC_SUPPORT_EMAIL` (mặc định `support@pte.com`) của tenant-web, hiển thị trong lỗi MST trùng (VI/EN, placeholder `{supportEmail}`).
- Thêm `apps/tenant-web/.env.example` và `!.env.example` trong `pte-web/.gitignore` (trước đó `.env*` chặn cả file mẫu).
- Production: đặt `NEXT_PUBLIC_SUPPORT_EMAIL` lúc build (biến NEXT_PUBLIC_ được nhúng vào bundle khi build, không đổi được khi chạy).

## Bổ sung: email xác nhận đơn + sửa lỗi không gửi mail
- Viết lại `BrandedEmailTemplate.applicationReceived` (tên tổ chức, mã tenant, các bước tiếp theo, email hỗ trợ lấy từ `SUPPORT_EMAIL` -> `notification.support-email`).
- Lỗi phát hiện: `notification_logs.body` là varchar(255) nên email dài hơn làm lưu log fail và mail không được gửi (đơn vẫn nộp được). V56 (`V56__notification_log_body_text`) đổi cột sang `text`, entity `columnDefinition = "text"`.
- Hai đơn nộp trước khi sửa (`ninh-le-5`, `ninh-le2` id 9/10) không có mail xác nhận; không tự gửi lại.
- Đã nộp thử bằng email test, mail tới Mailpit đúng, rồi dọn dữ liệu thử.

## Bổ sung: email duyệt đơn
- Viết lại `applicationApproved` cùng phong cách mail tiếp nhận: lời chào, khung tóm tắt (tổ chức, mã tenant, username, mật khẩu tạm, badge Approved xanh), nút đăng nhập + link dự phòng, callout bảo mật, email hỗ trợ, chữ ký. Footer đã dùng chung cho mọi mail qua `EmailLayout.page`.
- Biến mới `HOST_LOGIN_URL` (-> `notification.login-url`); mặc định `APP_WEB_TENANT_URL` + `/login`. Đã thêm vào `.env.example`, `.env`, compose local.
- Không ghi hạn dùng của mật khẩu tạm vì hệ thống không có cơ chế hết hạn; callout nói sẽ bị yêu cầu đổi mật khẩu ở lần đăng nhập đầu (HostAdminProvisioner đặt mustChangePassword).
- Chưa gửi mail duyệt thật (duyệt sẽ tạo tenant và tài khoản); đã kiểm tra bằng HTML render + test listener.

- Tinh chỉnh mail duyệt: `EmailLayout.linkHint` (cách dòng gợi ý 6px, cách khối dưới 22px, `word-break:break-all`); nút dùng chung một mã xanh thương hiệu `#3359d2` với logo, link và số bước (trước đó nút dùng `#0d6fbe`; đổi này áp cho mọi mail có nút, gồm đặt lại mật khẩu). Đã xem ở khổ 390px với URL dài.

## Bổ sung: email từ chối đơn
- Viết lại `applicationRejected`: lời chào, câu mở đầu mềm hơn, khung tóm tắt (tổ chức, mã tenant, badge đỏ "Not approved"), lý do trong callout đỏ nhạt (chữ thường, đã escape, giữ xuống dòng), nút "Submit a new application" + link dự phòng, email hỗ trợ, chữ ký. Callout dùng chung hàm với callout vàng của mail duyệt (cỡ chữ 13 -> 14px cho cả hai).
- Biến mới `HOST_REGISTER_URL` (-> `notification.register-url`), mặc định `APP_WEB_TENANT_URL` + `/register`; thêm vào `.env.example`, `.env`, compose local.
- Chưa làm: nút chọn nhanh lý do mẫu trong popup từ chối (đề xuất riêng); lý do admin nhập vẫn hiện nguyên văn trong mail.

## Chuẩn hóa biến URL (thay HOST_LOGIN_URL và HOST_REGISTER_URL)
- Bỏ hai biến riêng; email dùng chung `APP_WEB_TENANT_URL` (biến đã có, cũng dùng cho link đặt lại mật khẩu) và tự nối `/login` (mail duyệt) và `/register` (mail từ chối). Dấu `/` cuối được bỏ. `NotificationProperties.tenantWebUrl` + `getLoginUrl()`/`getRegisterUrl()`.
- `.env.example`, `.env`, compose local (`docker-compose.services.yml`) cập nhật; compose deploy đã truyền sẵn `APP_WEB_TENANT_URL`.
- Mail từ chối: lý do được escape, `
` chuẩn hóa rồi đổi thành `<br>` (không dùng `white-space: pre-line` vì Outlook desktop bỏ qua). Mail duyệt và từ chối đã dùng chung màu nút `#3359d2` và khoảng cách link 6px/22px (có test).
