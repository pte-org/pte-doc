# Phase 1: Contract and security decisions

## Requirements

Chốt contract CRUD/lifecycle cho platform user, target policy, field whitelist,
error/audit catalog và các quyết định sản phẩm trước khi sửa backend.

## Design Constraints

- Không mở quyền cho role khác ngoài `PLATFORM_ADMIN` trong V1.
- Không cho mutate self hoặc `PLATFORM_ADMIN` target.
- Không đổi email/username và không hard-delete trong phase này.
- Không dùng frontend guard làm security boundary.

## Steps

1. Đối chiếu endpoint hiện có với product decisions và xác định phần backward-compatible.
2. Chốt request/response fields, validation, status transition và archive semantics.
3. Chốt capability/target matrix cho create, read, profile, role, password và lifecycle.
4. Chốt machine-readable errors và audit events cho success/denial paths.
5. Xác định refresh-token invalidation và login/refresh deleted-user guard requirements.
6. Ghi lại quyết định còn mở từ handoff questions trước khi bắt đầu cook.

## Success Criteria

- API matrix và permission matrix không còn endpoint/mutation mơ hồ.
- Mọi mutating operation có validation, target authorization và audit expectation.
- Email, delete semantics và password delivery được product owner xác nhận.

## Quality and Testing State

- Quality gate: completed through the hard-cook review; scoped changes follow the
  existing identity policy, DTO, audit and token patterns.
- Testing: decision-only phase; no executable test was required.

## Risks

- Product decision chưa chốt làm backend contract phải đổi giữa phase — giữ open
  decisions ở plan và không cook Phase 2 trước khi được xác nhận.
