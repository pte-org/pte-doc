# Username tài khoản tổ chức = mã tenant + tiền tố email

## Vấn đề
Username Host/học viên/giám khảo/giám thị là `{mã tenant}.{8 ký tự ngẫu nhiên}`, rất khó nhớ; đăng nhập chỉ bằng username.

## Quyết định
- Công thức chung cho mọi tài khoản của tổ chức: `{mã tenant}.{tiền tố email}`, ví dụ `ninh-le.leninh2005`.
- Tiền tố: phần trước `@`, chữ thường, bỏ dấu (đ -> d), chỉ giữ `a-z0-9`, tối đa 20 ký tự.
- Trùng: thêm số `2`, `3`... (tối đa 20); email không có tiền tố dùng được hoặc hết số thì quay về chuỗi ngẫu nhiên như cũ.
- Không áp cho tài khoản nền tảng (`PlatformUserService`, username là email) và không đổi tài khoản đã tạo.
- Đánh đổi đã chấp nhận: username dễ đoán và lộ tiền tố email với ai nhìn thấy nó. Vẫn cần mật khẩu tạm ngẫu nhiên, bắt đổi ở lần đăng nhập đầu,
  và `LoginThrottle` giới hạn sai theo (username, IP).

## Thay đổi (pte-api)
- `UsernameGenerator.generateUnused(tenantCode, email, taken)` + `emailPrefix`.
- `HostAdminProvisioner`, `UserAccountProvisioner.createAccount` (tạo lẻ) và `createGeneratedStudentWithRetry` (nhập hàng loạt) dùng hàm mới;
  nhập hàng loạt kiểm tra tên đã dùng trước mỗi lần ghi nên hai dòng cùng tiền tố trong một file ra `an`, `an2`.
- Test: `UsernameGeneratorTest` (4 test mới), `IdentityServiceTest`, `UserServiceTest` (tạo lẻ + nhập hàng loạt trùng tiền tố).

## Kết quả thực hiện
- Toàn bộ test package `com.pte.identity`: 338 test, 0 lỗi. API đã rebuild.
- Chưa tạo thử tài khoản thật bằng API; chưa rà các màn hình hiển thị username (ai nhìn thấy username của ai).
