# Phase 4: Thẻ tài khoản — tên, e-mail, giới tính và ảnh đại diện

Preflight: Unit tests created and run: no (skipped_by_user) · ck:quality gate: skipped_by_user
Status: Completed · Yêu cầu: thẻ tài khoản hiện e-mail học viên đang dùng; thêm giới tính, đổi ảnh đại diện nam/nữ theo ảnh Hung gửi

## Requirements

- Thẻ tài khoản ở thanh bên hiện **tên thật và e-mail** của học viên thay cho chữ cố định "Student / Account". Mỗi dòng vừa một hàng, không xuống dòng, không mất chữ.
- Cài đặt có mục **Giới tính** với hai ô Nam / Nữ kèm ảnh. Chọn là thẻ đổi ảnh ngay và được lưu.
- Chưa chọn, hoặc không đọc được hồ sơ → hiện avatar nam.
- Nút Cài đặt và Đăng xuất trong thẻ luôn có viền vuông; nút Đăng xuất viền và icon đỏ.

## Design Constraints

- `fullName` và `email` đưa vào `GET /student/practice/entitlement` (dữ liệu của chính người gọi, từ bản ghi học viên đã tải sẵn), **không** nhét vào JWT.
- Cột `gender` nullable, không default, không backfill (V57), CHECK cho `NULL`/`MALE`/`FEMALE`.
- `PUT /student/practice/profile/avatar` là endpoint riêng, body `{gender}` bắt buộc không null. `PUT /profile` và `exam-date-api` không đổi.
- Module avatar ở `features/practice/avatar/` tự gọi API, không dùng lại `exam-date-api`. Đổi lại là thêm một request `GET /profile` mỗi lần nạp app.
- Lưu hỏng thì trả về lựa chọn cũ và báo lỗi; nạp hỏng thì im lặng dùng avatar mặc định.
- E-mail chiếm một hàng riêng dưới tên và hai nút (lưới 4 cột), vì cột chữ cạnh avatar và hai nút chỉ còn khoảng 120px.

## Related files

`pte-api`: `practice/internal/dto/response/PracticeEntitlementResponse.java` (`Student(publicId, status, fullName, email)`), `…/service/PracticeEntitlementService.java`, `practice/internal/domain/PracticeStudentProfile.java`, `…/domain/enums/PracticeAvatarGender.java` (mới), `…/dto/request/PracticeAvatarUpdateRequest.java` (mới), `…/dto/response/profile/PracticeProfileResponse.java`, `…/service/PracticeProfileService.java` (`updateAvatar`), `…/controller/PracticeProfileController.java`, `PracticeConstants.java`, `db/migration/V57__practice_student_profile_avatar.sql`.

`pte-practice`: `features/practice/contracts.ts` (`PracticeStudent`), `features/shell/{StudentShell.tsx,shell-chrome.css}`, `features/practice/avatar/{avatar.ts,avatar-api.ts,StudentAvatarProvider.tsx,StudentAvatar.tsx}`, `features/settings/{AvatarSettings.tsx,StudentSettings.tsx,settings.css}`, `public/avatars/{male,female}.png`, `app/globals.css`, `common/i18n/*`.

## Steps

1. Backend: thêm `fullName`/`email` vào response entitlement, gói trong record `Account` để hàm `response(...)` không phình tham số.
2. Backend: V57 + enum + entity + response + `updateAvatar` (đọc hồ sơ, đặt đúng một field, ghi lại; xử lý đua tạo hàng đầu tiên bằng cách đọc lại) + `PUT /profile/avatar`.
3. Frontend: `normalizeEntitlementResponse` đọc hai field mới; thẻ tài khoản đổi sang lưới, e-mail một hàng riêng, `text-overflow: ellipsis` kèm `title`.
4. `StudentAvatarProvider` bao shell để Cài đặt và thẻ luôn khớp nhau; `AvatarSettings` chọn Nam/Nữ; ảnh chép từ hai ảnh Hung gửi vào `public/avatars/`, cắt tròn bằng `object-fit: cover`.
5. Viền nút: `.icon-button-danger` cho Đăng xuất; viền nút trong `studio-shell` đổi từ `transparent` sang `--line-strong`.

## Success Criteria

- Thẻ hiện `Hung Student` và `hungpahm789456@gmail.com` mỗi dòng một hàng.
- **Đặt ngày thi ở Trang chủ, đổi giới tính, tải lại: ngày thi vẫn còn.**
- Chọn Nữ: thẻ đổi ngay, tải lại vẫn là Nữ; học viên bị khoá thấy avatar nam, không có màn hình lỗi.
- Nút Đăng xuất đỏ cả lúc rê chuột và lúc focus bàn phím.

## Quality and Testing State

- Quality: skipped_by_user
- Testing: skipped_by_user. `PracticeProfileServiceTest` 8 test đạt, `compile` và `tsc`/`eslint` sạch.
- Chưa gọi thật `PUT /profile/avatar` để xác nhận ngày thi giữ nguyên.
