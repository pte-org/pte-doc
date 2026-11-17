# Plan: Refresh token dùng một lần ngay cả khi hai request đua nhau

Status: Completed
Date: 2026-11-15
Mode: Fast
Test: default
Owner/slug: Ninh — `ninh-refresh-token-single-use`
Scope: `pte-api` (`identity`), `pte-doc`
Related: [ninh-billing-auth-hardening](../ninh-billing-auth-hardening/plan.md) (điểm refresh token được để ngoài phạm vi ở đó)

## Mục tiêu

Nhận xét về pte-api có ba điểm, đã đối chiếu:

1. **`playCount` toàn cục chặn nghe audio từ câu 2: không đúng.** Điều hướng tự do phía client chỉ có ở READING và WRITING (`ManualNavigationPolicy`), hai section này không có audio.
   LISTENING và SPEAKING chỉ đi tiếp bằng `submitAnswer` (nút Next, tự chuyển khi upload xong ghi âm đều gọi `flushOne` với `advance: true`), mà đường này gọi `advanceAfterCurrent` rồi `startTask`, tức reset `playCount`.
   Chỉ lưu nháp (`saveAnswer`, `advance: false`) mới không reset, và nó không dùng để sang câu có audio. Không sửa; nếu sau này mở điều hướng tự do cho section có audio thì phải đưa bộ đếm về theo từng item.
2. **Race khi `consume` refresh token: đúng.** `findByTokenHash` không khóa, hai request cùng token đều thấy `revoked = false` và cùng cấp cặp token mới. **Sửa.**
3. **`BigDecimal(double)` trong `TokenAlignment.percent`: không đúng.** Comment ngay tại hàm nói rõ đây là cố ý, làm tròn đúng giá trị nhị phân giống `round(x, 1)` của Python (để khớp kết quả tham chiếu).
   Đổi sang `BigDecimal.valueOf` sẽ làm lệch với Python. Không sửa.

## Phases

- [x] Phase 1: Thu hồi refresh token bằng câu lệnh cập nhật có điều kiện

## Kết quả thực hiện (2026-11-15)

- `RefreshTokenRepository.revokeIfActive(id)`: `update ... set revoked = true where id = :id and revoked = false and deleted = false`, trả số dòng.
- `RefreshTokenService.consume`: sau khi kiểm tra token còn hiệu lực, chỉ tiếp tục nếu `revokeIfActive` trả 1; ngược lại ném `InvalidRefreshTokenException`.
- Test mới `RefreshTokenConsumeRaceTest` (2): token bị thu hồi bằng bulk update sau khi đã được đọc thì `consume` bị từ chối (mô phỏng request kia thắng cuộc đua); token còn hiệu lực dùng được đúng một lần.

Kiểm chứng: test `RefreshToken*`, `AuthService*` và `ModuleStructureTest` qua. Chưa kiểm chứng với hai request đồng thời thật trên Postgres. Chưa làm: phát hiện tái sử dụng refresh token (thu hồi cả chuỗi khi token đã dùng bị trình lại); rebuild container; commit.
