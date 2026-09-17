# Phase 3: vendor-web — duyệt đơn đăng ký tổ chức

## Requirements

Nối `AdminApplicationsView` và `AdminApplicationDetailView` với API thật. Admin xem danh sách đơn, mở chi tiết, duyệt hoặc từ chối. Duyệt xong hiện mật khẩu `HOST_ADMIN` **một lần duy nhất**.

Xoá `DEMO_APPLICATIONS`.

Maps to: **[ADR-006](../../architecture/ADR-006-commercialization-and-exam-templates.md) §1**

## Design Constraints

- **`hostAdminPassword` chỉ tồn tại trong response của `approve`.** Không có endpoint nào lấy lại. Admin đóng modal trước khi sao chép là mất — phải reset thủ công qua đường khác. UI phải coi đây là dữ liệu quý: chặn đóng bằng click ra ngoài, có nút sao chép, có dòng cảnh báo rõ ràng.

- **Không cache mật khẩu vào query cache.** `approve` là mutation; dùng giá trị trả về trực tiếp trong state của modal, không `setQueryData`. Cache sống lâu hơn modal, và không có lý do gì để mật khẩu nằm trong đó.

- **Type của backend khác type trình bày hiện có.** `features/commercialization/types.ts` đang có `TenantApplication` với `reference`, `representative`, `submittedAt` dạng chuỗi đã định dạng — backend không trả những thứ đó. Dùng `TenantApplicationResponse` từ `@pte/api-client`, định dạng ở component. **Xoá hoặc thu hẹp type cũ**, không để hai type cùng tên gây nhầm.

- **Đơn đã duyệt/từ chối không duyệt lại được** — backend ném `APPLICATION_NOT_PENDING` (409). UI phải ẩn nút hành động với đơn không `PENDING`, nhưng vẫn phải xử lý 409 tử tế phòng trường hợp hai admin thao tác đồng thời.

- **Lý do từ chối là bắt buộc** (`@NotBlank` phía backend). Validate ở client trước khi gửi, không để người dùng nhận 400 vì bỏ trống.

- Mọi lệnh gọi qua TanStack Query trong `features/commercialization/api.ts` (rule 5). Không `fetch()` trong component.

## Steps

1. Tạo `features/commercialization/api.ts`:
   - `useApplicationsQuery()` — `useQuery`, key `["admin", "applications"]`
   - `useApproveApplicationMutation()` — `onSuccess` invalidate key trên
   - `useRejectApplicationMutation()` — tương tự

2. `AdminApplicationsView.tsx`: thay `DEMO_APPLICATIONS` bằng `useApplicationsQuery()`. Thêm ba trạng thái: đang tải, lỗi (kèm nút thử lại), rỗng ("chưa có đơn nào").

3. Bộ lọc theo trạng thái (nếu view đang có): lọc **trên client** từ danh sách đã tải — backend `GET /api/v1/applications` trả tất cả, không nhận tham số lọc. Đừng bịa query param không tồn tại.

4. `AdminApplicationDetailView.tsx`: lấy đơn theo `publicId` từ danh sách đã tải trong cache; backend **không có** endpoint lấy một đơn theo id. Nếu vào thẳng URL chi tiết mà cache rỗng thì tải danh sách rồi tìm — không gọi endpoint không tồn tại.

5. Modal xác nhận duyệt: nêu rõ hệ quả (tạo tenant + tài khoản `HOST_ADMIN`, cấp hạn mức sinh viên miễn phí theo `free_student_limit`).

6. `ApprovalResultModal` (mới): hiện `tenantCode`, `hostAdminUsername`, `hostAdminPassword`.
   - Nút sao chép mật khẩu
   - Dòng cảnh báo: mật khẩu chỉ hiện một lần
   - **Không đóng được bằng click nền hay phím Esc** — chỉ đóng bằng nút bấm có nhãn xác nhận đã lưu
   - Chuỗi hiển thị lấy từ `constants.ts` (rule 1)

7. Modal từ chối: ô nhập lý do, validate không rỗng trước khi gửi.

8. Xử lý lỗi: map mã lỗi backend sang thông báo tiếng người — `APPLICATION_NOT_PENDING` (đơn đã được xử lý bởi người khác), `REQUESTED_CODE_ALREADY_USED` (mã đã bị chiếm giữa lúc chờ duyệt). Hai cái này đều xảy ra thật khi có hai admin.

9. Xoá `DEMO_APPLICATIONS` khỏi `data.ts`. Nếu file rỗng thì xoá file.

10. Dọn `types.ts`: bỏ `TenantApplication`/`ApplicationStatus` trùng với type của `api-client`.

## Success Criteria

- Vòng khép kín chạy được: nộp đơn (curl/Postman) → thấy trong danh sách vendor-web → duyệt → **đăng nhập được bằng `HOST_ADMIN` và mật khẩu vừa hiện**
- Từ chối đơn → trạng thái đổi sang `REJECTED`, mã được nhả ra (nộp lại cùng mã thành công)
- Modal mật khẩu không đóng được bằng click nền
- Không còn `DEMO_APPLICATIONS` trong codebase
- Duyệt một đơn đã duyệt → thông báo rõ ràng, không phải lỗi thô
- Không `fetch()` trần trong component

## Quality and Testing State

- Quality gate: APPROVED — inline quality audit; no blocking findings.
- Testing: PASSED — vendor-web typecheck, lint, and production build.

## Session Notes

## Cook result — 2026-09-17

- Implementation and quality gate: `APPROVED`.
- Vendor application list/review uses the real billing API, keeps approval credentials one-time in component state, and passes typecheck, lint, and build.

_(trống)_
