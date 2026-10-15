# Phase 3: API client and Vendor Web actions

## Requirements

Vendor Web gọi các mutation mới bằng API client typed, cung cấp form/action
usable cho manageable target và giải thích rõ protected target thay vì tạo cảm
giác mọi action đều bị lỗi.

## Design Constraints

- Preflight: Reused `@pte/api-client` request patterns and the existing
  `@pte/ui` `DataTable`, `ActionMenu`, `Modal`, `ConfirmDialog`, `Input`,
  `DateInput`, `Checkbox`, `Badge` and pagination components; no feature-local
  visual replacements were introduced.
- Reuse common UI fields, modal, action menu, badge, alert và query patterns.
- Không đặt raw API error hoặc authorization logic riêng trong JSX.
- Không hiển thị email/password mutation ngoài contract được duyệt.
- Query invalidation phải giữ search/filter/page behavior hiện có.

## Steps

1. Mở rộng API-client types, endpoint functions và request contract tests.
2. Thêm query mutations cho profile, password, archive và restore.
3. Bổ sung modal/form theo field whitelist và confirmation cho destructive-looking actions; reset password chỉ là action xác nhận, không có ô nhập password.
4. Tách profile editing khỏi role editing và lifecycle confirmation.
5. Hiển thị protected-state explanation cho self/admin target và giữ direct API denial handling.
6. Cập nhật translation/error catalog, loading state, success toast và cache invalidation.
7. Chạy component/API-client checks cho create, update, suspend/reactivate và archive/restore.

## Success Criteria

- Admin thao tác được trên platform manager/academic target và thấy list cập nhật sau mutation.
- Self/admin target không có action mutation gây nhầm lẫn.
- API 401/403/validation errors được map qua common user-facing error handling.

## Quality and Testing State

- Quality gate: completed through the hard-cook review; the implementation reuses
  shared API-client and `@pte/ui` components and keeps route/feature boundaries
  separated.
- Testing: API client typecheck and 605 tests passed; Vendor Web typecheck, lint
  (0 errors; 2 pre-existing question-bank warnings), build and 66 tests passed;
  tenant-web typecheck also passed.

## Risks

- FE chỉ test với admin row nên tưởng API vẫn hỏng — fixture phải có target
  manager/staff thật và protected target riêng.
- Mutation thành công nhưng cache stale — tất cả mutation dùng cùng platform-user query key.
