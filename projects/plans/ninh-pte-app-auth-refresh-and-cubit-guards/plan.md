# Plan: Không refresh token khi gọi xác thực trả 401, và chốt chặn `isClosed` cho hai cubit

Status: Completed
Date: 2026-11-15
Mode: Fast
Test: default
Owner/slug: Ninh — `ninh-pte-app-auth-refresh-and-cubit-guards`
Scope: `pte-app`, `pte-doc`
Related: [ninh-attempt-stale-status-race](../ninh-attempt-stale-status-race/plan.md)

## Mục tiêu

Ba điểm từ một nhận xét về pte-app, đã đối chiếu với code:

1. `TokenRefreshInterceptor` chỉ kiểm tra mã 401, không kiểm tra endpoint. Đăng nhập sai (401 từ `/auth/login`) kéo theo một `POST /auth/refresh`
   vô ích; nếu máy còn refresh token cũ, refresh có thể thành công, xoay vòng token và phát lại request đăng nhập. **Đúng, sửa.**
2. `AutoRecordCubit` emit trong listener của luồng Drift mà không kiểm tra `isClosed`. **Gần như không xảy ra** vì `close()` gọi `cancel()` ở dòng đầu,
   trước `super.close()`; chỉ thêm chốt phòng thủ.
3. `DeviceCheckCubit._onPlaybackFinished` tương tự (`close()` `await cancel()` trước `super.close()`). Chỉ thêm chốt phòng thủ.

Không làm: khôi phục phiên khi mở lại app (quyết định sản phẩm), xóa `InTextSelect` (vẫn đang được màn preview của host và một widget test dùng).

## Scope challenge

Tối thiểu: một danh sách đường dẫn xác thực bỏ qua refresh; hai dòng `isClosed`. Fast.

## Phases

- [x] Phase 1: Bỏ qua refresh cho endpoint xác thực, thêm chốt `isClosed` — [phase-01-auth-401-and-guards.md](./phase-01-auth-401-and-guards.md)

## Kết quả thực hiện (2026-11-15)

- `token_refresh_interceptor.dart`: bỏ qua refresh khi đường dẫn chứa `/auth/login`, `/auth/refresh` hoặc `/auth/logout`; lỗi 401 gốc được chuyển thẳng ra UI.
- `read_aloud_cubit.dart` (`AutoRecordCubit`) và `device_check_cubit.dart`: `if (isClosed) return;` ở đầu callback.
- Test mới ở `token_refresh_interceptor_test.dart`: 401 từ `/auth/login` không gọi refresh và không phát lại login. Hai chốt `isClosed` không có test riêng vì không tái hiện được.

Kiểm chứng: `flutter analyze` sạch; toàn bộ `flutter test` (726 test) qua.
Chưa làm: chạy app thật; commit.
