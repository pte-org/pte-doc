# Phase 5: tenant-web — đăng ký tổ chức & theo dõi đơn

## Requirements

Nối `RegisterOrganizationView` với `POST /api/v1/applications` (công khai, không auth) và `ApplicationStatusView` với trạng thái đơn.

Maps to: **[ADR-006](../../architecture/ADR-006-commercialization-and-exam-templates.md) §1**

## Design Constraints

- **Form hiện tại lệch hẳn hợp đồng backend.** Đây là việc chính của phase này, không phải việc phụ:

  | Form đang có | Backend `SubmitApplicationRequest` | Xử lý |
  |---|---|---|
  | `organizationName` | `orgName` | Đổi tên |
  | `organizationType` | `orgType` | Đổi tên; giá trị hiện là `school`/`language-center`… — **xác nhận backend chấp nhận gì** |
  | `email` | `contactEmail` | Đổi tên |
  | `phone` | `contactPhone` | Đổi tên |
  | — | **`requestedCode`** (bắt buộc, `^[a-z0-9-]{3,32}$`) | **Thiếu hẳn — phải thêm** |
  | — | `taxCode` (tuỳ chọn) | Thêm |
  | `representativeName` | không có | Bỏ, hoặc gộp vào `orgName`? — cần quyết định |
  | `password` + `confirmPassword` | không có | **Bỏ hẳn** — xem dưới |

- **Bỏ trường mật khẩu là thay đổi về mô hình, không phải dọn form.** Tổ chức không tự đặt mật khẩu: backend sinh mật khẩu `HOST_ADMIN` lúc admin **duyệt** đơn, và trả về cho admin một lần. Để ô mật khẩu trong form đăng ký là hứa một điều hệ thống không làm. Thay bằng dòng giải thích: tài khoản sẽ được cấp sau khi duyệt, thông tin gửi tới email liên hệ.

- **`requestedCode` cần giải thích tại chỗ.** Người dùng không biết "mã tổ chức" là gì và vì sao không sửa được. Cần nhãn rõ, ví dụ minh hoạ, và cảnh báo **bất biến sau khi duyệt** — nó là tiền tố username của mọi sinh viên sau này.

- **Endpoint công khai, nhưng có rate limit.** `RateLimitFilter` đếm theo `anonymous` khi không có JWT — tức là **mọi khách chưa đăng nhập dùng chung một rổ token**. Nhận 429 là chuyện có thật khi nhiều người nộp cùng lúc; UI phải xử lý tử tế, không hiện lỗi thô.

- **Không gắn `RequireAuth` lên trang đăng ký.** Nghe hiển nhiên nhưng dễ sai vì trang nằm trong nhóm `(auth)`.

- **`ApplicationStatusView` không có endpoint tra cứu công khai.** Backend chỉ có `GET /api/v1/applications` (PLATFORM_ADMIN). Không có đường cho tổ chức tự tra trạng thái đơn bằng mã hay email. Xem mục dưới.

## Steps

1. **Quyết định trước khi code — hai câu hỏi phải chốt với chủ nhiệm đồ án:**
   - `representativeName`: bỏ hẳn hay thêm cột vào backend? Plan này mặc định **bỏ khỏi form**, vì backend không có chỗ chứa và bịa thêm cột là mở rộng phạm vi.
   - `ApplicationStatusView`: backend **không có** endpoint công khai tra cứu đơn. Ba hướng: (a) bỏ màn hình này, (b) chuyển thành trang tĩnh "đơn đã nhận, chờ email", (c) thêm endpoint tra cứu theo `publicId` ở backend. Plan này mặc định **(b)** — không mở rộng backend trong plan FE.

2. `features/commercialization/api.ts` cho tenant-web: `useSubmitApplicationMutation()`. **Không** dùng `apiClient` có token — hoặc dùng cũng được vì `getToken()` trả `null` khi chưa đăng nhập, nhưng phải xác nhận không có nhánh nào ném lỗi vì thiếu token.

3. `RegisterOrganizationView.tsx`: đổi `FormValues` theo bảng trên. Bỏ `password`/`confirmPassword` và mọi thứ liên quan (`PasswordInput`, `LockIcon`).

4. Thêm ô `requestedCode` với:
   - Validate client đúng regex `^[a-z0-9-]{3,32}$`
   - Chữ hướng dẫn: chỉ chữ thường, số, gạch ngang; 3–32 ký tự
   - Cảnh báo bất biến sau khi duyệt
   - Tất cả chuỗi lấy từ `constants.ts` (rule 1)

5. Thêm ô `taxCode` (tuỳ chọn).

6. `organizationType`: đối chiếu giá trị gửi lên với thứ backend mong đợi. Backend nhận `String` tự do (`orgType`), nhưng giá trị này chảy thẳng vào `Tenant.organizationType` và **hiện ra ở `UserService.me()`** — thống nhất tập giá trị với `vendor-web` đang dùng, đừng để mỗi nơi một kiểu.

7. Xử lý lỗi theo mã:
   - `REQUESTED_CODE_ALREADY_USED` (409) → gắn lỗi vào đúng ô `requestedCode`, gợi ý đổi mã
   - 429 → "hệ thống đang nhận nhiều đơn, thử lại sau ít phút"
   - 400 → map `errors` theo trường nếu backend trả `errors` map

8. Thành công: chuyển sang màn xác nhận nêu rõ bước tiếp theo (chờ admin duyệt, tài khoản gửi qua email liên hệ). **Không** hứa thời gian cụ thể nếu không có SLA.

9. Xử lý `ApplicationStatusView` theo hướng đã chốt ở bước 1.

10. Kiểm `PublicShell`/`PublicHeader` không kéo theo lệnh gọi API cần auth — trang này chạy khi chưa đăng nhập.

## Success Criteria

- Nộp đơn thành công khi **chưa đăng nhập**, không 401
- Không còn ô mật khẩu trong form đăng ký
- `requestedCode` có validate đúng regex và giải thích rõ
- Trùng mã → lỗi gắn đúng ô, không phải thông báo chung chung
- Đơn vừa nộp xuất hiện trong vendor-web (Phase 3)
- Không hardcode chuỗi trong JSX

## Quality and Testing State

- Quality gate: chưa chạy
- Testing: chưa bắt đầu

## Session Notes

_(trống)_
