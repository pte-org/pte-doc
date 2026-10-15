# Phase 2: Backend platform-user lifecycle

## Requirements

Backend cung cấp profile update, platform password reset và archive/restore an
toàn, đồng thời bảo vệ login/refresh, role scope, token và audit history.

## Design Constraints

- Preflight: Reused the existing platform-user controller/policy, `User` soft-delete,
  credential event/listener, `ApiResponse`, audit service and refresh-token
  persistence; tenant-user routes and semantics remain unchanged.
- Giữ namespace platform-user và `ApiResponse` hiện có.
- Mọi write phải enforce server-side, transactional và target-locked khi cần.
- Không trả password/hash/token và không để archived user vượt qua auth guard.
- Không thay đổi tenant-user semantics ngoài shared helper cần thiết.

## Steps

1. Thêm các request/response contract và validation cho profile, automatic password reset và archive lifecycle.
2. Bổ sung target policy cho self/admin protection, allowlisted roles và tenantless scope.
3. Triển khai profile update, automatic temporary-password reset, archive và restore với state transition rõ ràng.
4. Invalidate target refresh sessions khi suspend, archive hoặc reset password; gửi credential reset qua email mà không trả cleartext trong API.
5. Bổ sung login/refresh checks và active-query filtering cho archived accounts.
6. Ghi audit event cho mọi mutation thành công và authorization denial cần thiết.
7. Viết focused service/controller/repository/security tests cho allow/deny, idempotency và concurrency.

## Success Criteria

- Các API mới trả envelope/DTO an toàn và từ chối target hoặc payload không hợp lệ.
- Archived account không login/refresh được và không xuất hiện trong active list.
- Existing platform-role and tenant-user regression tests vẫn pass.

## Quality and Testing State

- Quality gate: completed through the hard-cook review; lifecycle responsibilities
  are isolated in `PlatformUserLifecycleService` and existing tenant-user behavior
  remains outside the change.
- Testing: backend compile passed; focused identity/security suite passed with 27
  tests; the full app suite passed with the existing `ModuleStructureTest` excluded
  (`2082` tests, `0` failures, `0` errors, `56` skipped). The unfiltered suite still
  reports the pre-existing module dependency cycles in `ModuleStructureTest`.

## Risks

- Token invalidation không bao phủ refresh token đã phát — kiểm tra target-wide
  revoke bằng test thực tế thay vì chỉ kiểm tra status row.
- Archive/restore race làm state sai — dùng target lock và test hai mutation đồng thời.
