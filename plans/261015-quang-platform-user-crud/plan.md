# Plan: Hoàn thiện CRUD platform user trên Vendor Admin Web

Status: ✅ Complete  
Date: 2026-10-15  
Mode: Hard  
Test: default (TDD được khuyến nghị khi cook)  
Owner/slug: Quang — `261015-quang-platform-user-crud`  
Scope: `pte-api` + `pte-web` (`vendor-web`, `packages/api-client`) + `pte-doc`  
Related: [`platform-role-expansion`](../platform-role-expansion/plan.md)

## Scope Challenge

### Exists?

Có một phần. Platform-user management đã có list/detail, create, role update,
suspend/reactivate ở backend và đã có màn hình/vendor hooks tương ứng ở frontend.
Tuy nhiên profile update, password reset riêng cho platform target,
archive/restore, token invalidation và UX cho target protected chưa hoàn chỉnh.

### Minimum?

Nhỏ nhất để đáp ứng yêu cầu là giữ contract hiện có và bổ sung:

1. profile update có whitelist field;
2. reset password của platform user;
3. archive/restore bằng soft-delete;
4. login/refresh guard cho archived user;
5. Vendor Web actions, error states và cache invalidation;
6. security/audit/regression tests.

Không xây custom-role editor, permission editor hoặc email-change flow trong scope
này.

### Complexity?

Hard — feature chạm identity, role authorization, password, refresh token,
soft-delete, audit, API client và Vendor Web. Sai policy có thể gây privilege
escalation hoặc khóa nhầm administrator.

## Overview

Hoàn thiện vòng đời quản lý tài khoản platform user trong Vendor Admin Web. Sau
plan này, `PLATFORM_ADMIN` có thể quản lý các platform account thông thường qua
API thật và UI rõ ràng; self-account và tài khoản `PLATFORM_ADMIN` vẫn được bảo
vệ server-side.

## Phases

- [x] Phase 1: Contract and security decisions — chốt endpoint, target policy, field whitelist, audit và open decisions.
- [x] Phase 2: Backend platform-user lifecycle — triển khai profile, password, archive/restore, token/login guard và tests.
- [x] Phase 3: API client and Vendor Web actions — nối mutation thật, forms, protected-state UX và error mapping.
- [x] Phase 4: Verification and handoff — chạy focused checks, runtime matrix, review và cập nhật evidence.

## Research Summary

### Research track A — Primary: mở rộng resource platform-user riêng

Khuyến nghị giữ namespace `/api/v1/platform-users` và mở rộng lifecycle tại
resource này. Cách này giữ tenant boundary rõ ràng, không làm rộng mơ hồ
`/api/v1/users`, tái sử dụng policy/audit hiện có và cho phép test target
platform độc lập với tenant user.

### Research track B — Alternative: tái sử dụng UserController tenant-user

Có thể dùng các route reset/profile/suspend hiện có của `/api/v1/users`, nhưng
route/service hiện gắn với tenant scope và manageable tenant roles. Reuse trực
tiếp sẽ làm lẫn platform target với tenant target, dễ mở IDOR hoặc sai role
hierarchy. Chỉ nên dùng helper/password primitive dùng chung; không dùng chung
resource contract.

### Chosen approach

Chọn Researcher A. Giữ API hiện có tương thích ngược, thêm mutation rõ ràng cho
platform user và dùng cùng `ApiResponse`, `AuditLogService`, error catalog,
public-id và deny-by-default policy.

## Current source evidence

- Backend đã có `POST` create, `GET` list/detail, `PATCH` roles và `POST`
  suspend/reactivate trong `PlatformUserController`.
- API client và React Query feature đã có các request/mutation tương ứng.
- FE hiện disable role/lifecycle action nếu target là caller hoặc có
  `PLATFORM_ADMIN`, nên menu trong screenshot có thể bị mờ dù endpoint tồn tại.
- Controller/page hiện giới hạn platform-user management cho `PLATFORM_ADMIN`;
  các role platform khác không được mở quyền security/role management theo
  plan `platform-role-expansion`.
- `User` có `status`; `BaseEntity` có `deleted`, nhưng archive lifecycle và
  auth guard cho deleted user chưa được hoàn thiện ở platform-user boundary.

## Product decisions

1. Chỉ `PLATFORM_ADMIN` được list/detail và mutate platform user.
2. Caller không được sửa, suspend, archive hoặc đổi role của chính mình.
3. Target có `PLATFORM_ADMIN` là read-only; không hỗ trợ admin-on-admin mutation
   trong V1.
4. Role có thể cấp là `PLATFORM_MANAGER`, `ACADEMIC_MANAGER` và
   `ACADEMIC_STAFF`; không nhận `PLATFORM_ADMIN` từ create/role-update payload.
5. Profile update chỉ gồm `fullName`, `phone`, `dateOfBirth`.
6. Email/username immutable trong V1 vì username platform hiện gắn với email;
   đổi email là một flow xác minh riêng ở plan khác.
7. `DELETE` là archive/soft-delete có thể restore, không hard-delete.
8. Password không xuất hiện trong response, audit hoặc log. Reset password không
   nhận password từ admin; backend tự sinh temporary password, hash lại, bật
   `mustChangePassword` và gửi credential qua email.

## Permission matrix

| Action | Admin target thường | Self/admin target | Role khác |
|---|---:|---:|---:|
| List/detail | Allow | Read only | Deny |
| Create | Allow | N/A | Deny |
| Update profile | Allow | Deny | Deny |
| Update assignable roles | Allow | Deny | Deny |
| Suspend/reactivate | Allow | Deny | Deny |
| Reset password | Allow | Deny | Deny |
| Archive/restore | Allow | Deny | Deny |

Frontend visibility is UX only; every write repeats this matrix in the backend.

## API contract

### Existing contract to preserve

| Capability | Endpoint | Contract |
|---|---|---|
| List | `GET /api/v1/platform-users?page&size&search&role&status` | Bounded pagination and server-side filters |
| Detail | `GET /api/v1/platform-users/{publicId}` | Tenantless platform target |
| Create | `POST /api/v1/platform-users` | Assignable platform roles only |
| Role update | `PATCH /api/v1/platform-users/{publicId}/roles` | Replace role set atomically |
| Suspend | `POST /api/v1/platform-users/{publicId}/suspend` | Lifecycle command |
| Reactivate | `POST /api/v1/platform-users/{publicId}/reactivate` | Must not restore archived row |

### New contract

| Capability | Endpoint | Payload/result |
|---|---|---|
| Profile update | `PATCH /api/v1/platform-users/{publicId}` | `fullName`, `phone`, `dateOfBirth`; safe `UserResponse` |
| Password reset | `POST /api/v1/platform-users/{publicId}/reset-password` | No password payload; backend generates and emails a temporary credential, then returns safe `UserResponse` |
| Archive | `DELETE /api/v1/platform-users/{publicId}` | Soft-delete; safe `UserResponse` |
| Restore | `POST /api/v1/platform-users/{publicId}/restore` | Restore archived target after policy checks |

All responses use the existing `ApiResponse` envelope and public identifiers. No
database IDs, password hash, refresh token or raw credential is exposed.

## Dependencies

- Existing role/security policy and identity aggregate from
  `platform-role-expansion`.
- Existing audit and API error envelope contracts.
- Refresh-token persistence must support target-wide revocation or the smallest
  additive equivalent must be introduced.
- Local PostgreSQL/Docker runtime is useful for auth and migration verification,
  but is not a prerequisite for writing the source plan.

## Architecture decisions

### AD-01: Dedicated resource boundary

Do not widen tenant-scoped `/api/v1/users/{publicId}` for platform mutations.
Keep platform operations under `/api/v1/platform-users`.

### AD-02: Separate mutation categories

Profile, role, password and lifecycle changes have different validation/audit
requirements. Keep separate endpoint/service operations rather than one arbitrary
PATCH.

### AD-03: Archive is real access revocation

Archive must remove the user from active queries, block login and refresh, and
invalidate active refresh tokens. The soft-delete flag cannot be UI-only.

### AD-04: Protected rows remain readable but not writable

The table may show a protected-state label instead of a disabled menu. This is
only a usability decision; backend denial remains mandatory.

### AD-05: Audit after successful mutation

Create, role update, suspend/reactivate, profile update, password reset and
archive/restore emit auditable events. Denials are recorded without secrets.

## Acceptance criteria

- Given a valid `PLATFORM_ADMIN`, when they create a platform manager, then the
  account is tenantless, has only an allowlisted platform role and can be listed.
- Given a manageable platform target, when profile/role/password/lifecycle action
  succeeds, then the response is safe, the list cache refreshes and an audit row
  exists.
- Given self or `PLATFORM_ADMIN` target, when any protected write is attempted,
  then the API denies it and no user state changes.
- Given an archived user, when login or refresh is attempted, then authentication
  fails and the user is absent from active list/detail queries.
- Given a crafted role payload, when it contains `PLATFORM_ADMIN`, tenant role or
  mixed scope, then the API rejects it before persistence.
- Given the Vendor Web table, when a manageable target is selected, then actions
  are usable; protected targets show an explicit protected state.

## Risks

- **HIGH:** Admin locks or archives the only usable administrator — keep self/admin
  target protection and test administrator invariants.
- **HIGH:** Archived user can still authenticate through an unguarded path — check
  both password login and refresh flow.
- **HIGH:** Crafted role payload escalates privilege — resolve roles through a
  server allowlist and deny mixed platform/tenant scope.
- **HIGH:** Email mutation breaks username login — keep email immutable in V1.
- **MEDIUM:** Password appears in audit/response — use safe DTOs and secret-output
  tests.
- **MEDIUM:** UI looks broken because every visible row is protected — test with
  real manager/staff targets and explain protected state.
- **LOW:** List shows stale status after mutation — invalidate the shared query key
  after every successful mutation.

## Confirmed decisions

1. Only `PLATFORM_ADMIN` manages platform users.
2. Email/username remains immutable in V1.
3. `DELETE` means reversible archive/restore, not physical deletion.
4. Password reset is automatic: no manual password input; the backend generates
   a temporary credential, stores only its hash, sets `mustChangePassword` and
   sends the credential by email.

## Next command after decisions

```text
/ck:cook --hard plans/261015-quang-platform-user-crud/plan.md
```
