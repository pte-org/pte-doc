# Phase 8: Import roster passthrough

## Requirements

Trung tâm upload file Excel **bất kỳ**. Hệ thống không diễn giải cột nào — đếm số dòng, sinh đúng bấy nhiêu tài khoản sinh viên, và **xuất lại chính file đó kèm hai cột mới `account` và `password`**.

Maps to: **[ADR-007](../../architecture/ADR-007-student-identity-and-login.md) § Import roster**

## Design Constraints

- **Không có cột bắt buộc, không có file mẫu bắt buộc, không ánh xạ cột.** Trung tâm tách `Họ`/`Tên` riêng hay đặt tên cột kiểu gì cũng được. Bất kỳ cột nào bị coi là bắt buộc cũng sẽ sai với một định dạng nào đó.
- **Không đối chiếu trùng.** Khoá unique duy nhất là `username` do hệ thống sinh. Mỗi dòng = một sinh viên mới. **Trách nhiệm dữ liệu trùng thuộc trung tâm** — hệ thống không phát hiện, không cảnh báo, không dọn hộ.
- **Mã trong `username` là ngẫu nhiên**, không sinh từ dữ liệu file. Không hash họ tên, không dùng ngày sinh.
- **File xuất ra chứa mật khẩu chữ thường của toàn bộ roster.** Tải một lần, không lưu file trên server, buộc đổi mật khẩu ở lần đăng nhập đầu. Một file rò ra là lộ toàn bộ tài khoản của trung tâm đó.
- Hồ sơ sinh viên trong DB gần như trống — `fullName` null là bình thường (Phase 1 đã cho nullable). Việc đối chiếu tài khoản với người thật nằm ở file trung tâm giữ.
- Import vẫn chạy **đồng bộ** — giữ nguyên tính chất hiện tại, ghi vào nợ kỹ thuật chứ không giải ở đây.

## Steps

1. Thêm dependency đọc/ghi `.xlsx` (Apache POI) vào `app/pom.xml`.

2. `RosterFileService` trong `identity/internal/service/`:
   - `countDataRows(InputStream)` — đếm dòng có dữ liệu, bỏ dòng header và dòng trống cuối file
   - `appendCredentialColumns(InputStream, List<Credential>)` — mở file gốc, thêm hai cột vào **cuối** dải cột đang dùng của mỗi dòng, ghi header `account`/`password` ở dòng đầu, trả `byte[]`

3. Giới hạn đầu vào: kích thước file tối đa, số dòng tối đa, chỉ chấp nhận `.xlsx`. Vượt → 422 nói rõ giới hạn. Đây là endpoint nhận file từ bên ngoài nên validate là bắt buộc, không phải tuỳ chọn.

4. `User` thêm `mustChangePassword` (boolean, mặc định `false`); migration `V26__user_must_change_password.sql`. Tài khoản sinh viên tạo qua import đặt `true`.

5. `AuthService.login()`: trả thêm cờ `mustChangePassword` trong `TokenResponse`. Không chặn đăng nhập — FE dựa vào cờ này để ép sang màn đổi mật khẩu.

6. Endpoint đổi mật khẩu lần đầu: đổi xong đặt `mustChangePassword = false`.

7. `StudentRosterImportService.import(file, caller)`:
   - Đếm dòng → gọi `TenancyService.assertCanAddStudents(tenantId, rowCount)` (Phase 7) **trước khi** tạo gì
   - Sinh `rowCount` tài khoản: `username = UsernameGenerator.generate(tenant.code)` (Phase 1), mật khẩu từ `PasswordGenerator` đã có, role `STUDENT`, `mustChangePassword = true`
   - Ghi qua `UserBulkCreateWriter`
   - Gắn hai cột vào file gốc, trả `byte[]`

8. Controller `POST /api/students/import`:
   - `Content-Type: multipart/form-data`, trả về `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`
   - `Content-Disposition: attachment`
   - **Không** ghi file ra đĩa ở bất kỳ bước nào — xử lý trên stream/bộ nhớ

9. Bước xem trước: FE gọi `POST /api/students/import/preview` (Phase 7) trước khi import thật, hiển thị số sẽ tạo và hạn mức sau import. Response của preview phải đủ để FE dựng câu kiểu *"Sẽ dùng thêm 500 chỗ — còn lại 13/1000"*.

10. Test: file 3 cột (`Họ`, `Tên`, `Lớp`) → xuất ra 5 cột, hai cột cuối là `account`/`password`, số dòng giữ nguyên.

11. Test: file có cột tên kiểu khác hẳn (`MSSV`, `Fullname`, `DOB`) → vẫn chạy, không lỗi.

12. Test: file 500 dòng khi còn 10 chỗ → 409, **không** tài khoản nào được tạo.

13. Test: tài khoản vừa tạo đăng nhập được bằng `account`/`password` trong file xuất ra, và `TokenResponse` có `mustChangePassword = true`.

14. Test: import **cùng một file hai lần** → tạo ra hai bộ tài khoản, hệ thống không cảnh báo gì. **Đây là hành vi đúng theo thiết kế** — test để khoá hành vi, không phải để sửa.

## Success Criteria

- File Excel định dạng bất kỳ import được, không cột nào bắt buộc
- File xuất ra giữ nguyên dữ liệu gốc + hai cột tài khoản
- Không file nào được ghi xuống đĩa server
- Sinh viên đăng nhập được và bị ép đổi mật khẩu lần đầu
- Import vượt hạn mức bị chặn trước khi tạo dòng nào
- Import trùng tạo trùng — có test khoá hành vi này

## Quality and Testing State

- Quality gate: chưa chạy
- Testing: chưa bắt đầu

## Session Notes

_(trống)_
