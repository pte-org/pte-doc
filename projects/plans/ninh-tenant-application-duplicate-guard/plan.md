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
- **Bổ sung theo yêu cầu**: xóa 2 đơn PENDING trùng MST123456 ở DB local; thêm `V54__organization_tax_code_unique_while_live.sql`
  (tự từ chối các đơn PENDING trùng MST còn sót — giữ đơn đã duyệt hoặc đơn cũ nhất — rồi thay `uq_org_tax_code_approved` bằng
  `uq_org_tax_code_live` `WHERE status <> 'REJECTED'`). Cập nhật dev-seed, ánh xạ lỗi ràng buộc, và `submit` giờ dịch lỗi
  unique-index thành 409 khi hai request đồng thời. V54 cao hơn V53 trên origin/dev. Đã chạy thử migration trong transaction rollback trên DB local: OK.
- Chưa chạy test tích hợp Postgres và chưa thử trên trình duyệt với API thật.

## Giới hạn
- Chưa có unique index nên 2 request đồng thời cùng MST vẫn có thể lọt (hiếm; bị chặn lại ở bước duyệt).
- Đơn PENDING trùng MST đã tồn tại trong DB không bị xử lý lại; admin cần từ chối thủ công.
- Chưa có cảnh báo trên bảng admin cho đơn nghi trùng (đề xuất tách riêng).

## Bổ sung: email hỗ trợ
- Biến `NEXT_PUBLIC_SUPPORT_EMAIL` (mặc định `support@pte.com`) của tenant-web, hiển thị trong lỗi MST trùng (VI/EN, placeholder `{supportEmail}`).
- Thêm `apps/tenant-web/.env.example` và `!.env.example` trong `pte-web/.gitignore` (trước đó `.env*` chặn cả file mẫu).
- Production: đặt `NEXT_PUBLIC_SUPPORT_EMAIL` lúc build (biến NEXT_PUBLIC_ được nhúng vào bundle khi build, không đổi được khi chạy).
