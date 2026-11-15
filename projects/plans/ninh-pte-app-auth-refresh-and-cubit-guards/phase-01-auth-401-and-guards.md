# Phase 1: Bỏ qua refresh cho endpoint xác thực, thêm chốt `isClosed`

Status: Completed

## Requirements

- Một 401 từ `/auth/login`, `/auth/refresh`, `/auth/logout` đến UI nguyên vẹn, không có request refresh nào.
- Các 401 khác vẫn refresh một lần rồi phát lại (single-flight không đổi).
- Hai callback luồng không emit khi cubit đã đóng.

## Related files

- `pte-app/lib/core/network/interceptors/token_refresh_interceptor.dart`
- `pte-app/lib/features/exam_attempt/speaking_writing/presentation/cubit/read_aloud_cubit.dart`
- `pte-app/lib/features/device_check/presentation/cubit/device_check_cubit.dart`
- `pte-app/test/unit/network/token_refresh_interceptor_test.dart`

## Quality/Testing State

- Test đơn vị mới cho interceptor; `flutter analyze` và `flutter test` toàn bộ.
