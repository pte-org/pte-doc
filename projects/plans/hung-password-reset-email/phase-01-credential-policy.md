# Phase 01 — Credential policy (pte-api)

**Stories:** P1 #1 (backend), P1 #4 · **FR:** 01, 02, 03, 06, 13, 14
**Status:** [x]

## Overview

Gom mọi thao tác đổi credential về chung một bộ quy tắc: chặn khi học viên đang thi, bật buộc đổi mật khẩu khi người khác đặt hộ, thu hồi toàn bộ phiên, ghi audit. Bỏ chặn gửi mail mật khẩu tạm cho STUDENT.

## Files

- `shared/StartedAttemptLookup.java`: thêm `boolean hasInProgressAttempt(UUID studentPublicId)`.
- `attempt/AttemptService.java` + `attempt/internal/repository/ExamAttemptRepository.java`: hiện thực bằng query `existsBy…` với `status = IN_PROGRESS AND deleted = false`.
- `identity/internal/service/user/UserCredentialRotation.java`: logic chính.
- `identity/internal/service/PlatformUserLifecycleService.java`: đã thu hồi phiên + bật cờ; chỉ cần kiểm tra lại.
- `identity/internal/service/RefreshTokenService.java`: tái dùng `revokeAllForUser`; thêm `revokeAllOthers(Long userId, String keepRawToken)`. Hàm này chỉ giữ lại token nếu token đó thuộc đúng user và còn hiệu lực; ngược lại thu hồi hết.
- `identity/internal/repository/RefreshTokenRepository.java`: query `revokeAllActiveByUserIdExceptId`.
- `identity/internal/dto/request/auth/ChangePasswordRequest.java`: thêm `String refreshToken` (tuỳ chọn). Response của `change-password` giữ nguyên `Void`.
- `identity/internal/exception/StudentAttemptInProgressException.java` (mới, 409).
- Xoá `StudentCredentialEmailNotAllowedException` và hằng số `STUDENT_CREDENTIAL_EMAIL_NOT_ALLOWED` nếu không còn chỗ dùng.
- `identity/internal/constant/IdentityConstants.java`: `STUDENT_ATTEMPT_IN_PROGRESS`, `USER_CREDENTIALS_EMAILED` (+ `_SUMMARY`), `USER_PASSWORD_CHANGED_SELF`.

## Steps

1. Trong `UserCredentialRotation`, thêm hàm private `applyCredentialChange(User user, String rawPassword, boolean mustChange)`. Hàm này: kiểm tra guard đang thi (STUDENT + `hasInProgressAttempt` → 409), set hash, set `mustChangePassword`, `save`, `revokeAllForUser`.
2. `resetPassword` gọi helper với `mustChange = true` (FR-14).
3. `sendGeneratedCredentials`: bỏ nhánh chặn STUDENT. Giữ yêu cầu email (`UserEmailRequiredException`) và quy tắc `mayChangeCredential`. Ghi audit `USER_CREDENTIALS_EMAILED`. Không ghi mật khẩu.
4. `generateStudentCredentials` dùng chung helper (có guard + thu hồi phiên).
5. `changeOwnPassword`: guard → set hash, tắt cờ. Nếu `request.refreshToken()` có giá trị thì `revokeAllOthers(userId, refreshToken)`; nếu không thì không thu hồi gì (client cũ). Ghi audit `USER_PASSWORD_CHANGED_SELF`.

## Design Constraints

- `identity` không import gì từ `attempt` ngoài `shared.StartedAttemptLookup` (ADR-001 #3, ADR-004).
- Thông báo lỗi nằm trong `IdentityConstants`, không hardcode.
- Học viên ngoài tổ chức của caller → 404, không phải 403 (ADR-004).
- Mật khẩu tạm chỉ đi qua event trong bộ nhớ, như hiện tại; không lưu vào notification log (`dispatchExternalSensitive`).

## Tests

- `UserServiceTest`: sửa test đang mong `StudentCredentialEmailNotAllowedException` thành gửi thành công. Thêm: học viên không email → `UserEmailRequiredException`; học viên đang thi → 409 cho generate, send-email, reset, change-password; reset bật `mustChangePassword`; mọi đường đều gọi `revokeAllForUser`.
- `AuthController`/integration: `change-password` có `refreshToken` → token đó vẫn gia hạn được, token khác của user bị từ chối; `refreshToken` thuộc user khác hoặc đã thu hồi → thu hồi hết; không có `refreshToken` → mọi token còn sống (tương thích ngược); response vẫn là `data: null`.
- `AttemptService.hasInProgressAttempt`: true/false/đã xoá.

## Quality and Testing State

- Quality: approved (verify, after QUAL-001 fixed; no receipt, Python unavailable)
- Testing: passed (tdd-verify, 70 phase tests; full suite has 3 pre-existing failures)
