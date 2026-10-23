# Phase 04: shared API client và Admin Web

**Status:** implemented and verified  
**Dependency:** Phase 02; API contract của Phase 03  
**Output:** Admin Web có thể quản lý rubric bằng common/shared components.

## Mục tiêu

Thêm API client và screens cho Academic Staff/Manager/Platform Admin theo pattern của ScoreTemplate, nhưng không copy code hoặc tạo UI primitive riêng khi `@pte/ui` đã có component phù hợp.

## Công việc

1. Thêm types và requests dưới `pte-web/packages/api-client/src/types/practicerubric/` và `requests/practicerubric/`; export từ index trung tâm.
2. Mirror đúng endpoint, `ApiResponse` envelope, error code và expected-version/`409` contract của backend.
3. Tạo feature `apps/vendor-web/features/practicerubric/` gồm constants, API hooks, query keys, mappers, permission helpers và views.
4. Tạo routes:
   - `/admin/practice-rubrics`
   - `/admin/practice-rubrics/[publicId]`
   - `/admin/practice-rubrics/[publicId]/edit`
5. List có filter task/status/revision/author; detail published/retired là read-only.
6. Draft editor có criteria, level descriptors, applicability, evidence rules, anchors và provenance; save theo complete document contract.
7. Readiness panel hiển thị blocker từ server; review diff hiển thị thay đổi trước publish.
8. Reject dialog bắt buộc reason; publish dialog cảnh báo immutable version/historical pin; override dialog chỉ Platform Admin và bắt buộc reason.
9. Navigation dùng academic role group hiện có; action visibility chỉ là advisory.
10. Invalidate list/detail/readiness/diff queries sau mutation; xử lý stale `409` bằng thông báo và reload dữ liệu server.
11. Thêm localization trong `features/i18n/adminCopy.ts` hoặc convention hiện có; không hard-code text trong component.

## Common/shared bắt buộc

- Dùng `@pte/api-client` cho request/types, không gọi `fetch` trực tiếp trong view.
- Dùng `@pte/ui` hiện có: `PageHeader`, `DataTable`, `Badge`, `ActionMenu`, `FormField`, `Input`, `Textarea`, `Select`, `Checkbox`, `Modal`/`ConfirmDialog`, `Tabs`, `Alert`, `FormActions`, `useToast`.
- Dùng `features/auth/permissions.ts` và role constants; không tạo role strings rải rác.
- Dùng React Query conventions và shared query error handling hiện có.
- Chỉ thêm component vào `@pte/ui` nếu chứng minh được component đó dùng chung cho ít nhất hai app.

## Design Constraints

- Không đưa task-specific business logic vào generic `@pte/ui`.
- Không lặp lại readiness validation chỉ ở TypeScript; server là nguồn quyết định.
- Không render answer key, raw reference hoặc internal prompt trong Admin UI nếu user không có quyền tương ứng.
- Direct route access phải nhận `403` từ API dù UI không hiện navigation.
- Draft editor không cho sửa published/retired; clone tạo revision mới.

## Quality and Testing State

- Quality: **APPROVED** by the independent review for common/shared component use, localization, readiness error visibility and server-owned permissions; final phase completion remains subject to the `--hard` confirmation gate.
- Testing: API-client typecheck and rubric request tests pass; vendor typecheck, lint and production build pass. Authenticated browser interaction remains unverified.
- Required checks: API-client typecheck, vendor-web typecheck/lint/build, query invalidation tests, permission/status action matrix, reject/publish/override forms, stale `409`, readiness blockers và authenticated browser flow Staff → Manager → Platform Admin.
- TDD gate: API-client contract tests were added before accepting the related client changes; browser interaction is a remaining manual boundary.
