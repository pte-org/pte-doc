# Plan: Phân tách role vận hành và học thuật cho Admin Web

Status: Complete pending release
Date: 2026-10-08
Mode: Hard
Test: default (TDD được khuyến nghị khi cook)
Scope: `pte-api` + `pte-web` (`vendor-web`, `packages/api-client`, `packages/ui`) + `pte-doc`

## Objective

Triển khai role catalog cố định cho platform và tách trách nhiệm trong Admin Web:

1. `PLATFORM_ADMIN` vẫn toàn quyền.
2. `PLATFORM_MANAGER` quản lý vận hành platform nhưng không quản lý security/role hoặc publish học thuật.
3. `ACADEMIC_MANAGER` quản trị, review, approve và publish tài nguyên học thuật.
4. `ACADEMIC_STAFF` thay thế trách nhiệm author: tạo/import/chỉnh sửa draft và submit để review.
5. `HOST_ADMIN`, `EXAMINER`, `PROCTOR`, `STUDENT` giữ nguyên boundary tenant/exam/own-data.
6. Backend enforce permission + scope; frontend chỉ là lớp UX.

## Scope Challenge

### Hiện trạng đã xác nhận

- Backend canonical role nằm ở `pte-api/app/src/main/java/com/pte/identity/domain/Role.java`, hiện có `PLATFORM_ADMIN`, `PLATFORM_AUTHOR`, `HOST_ADMIN`, `PROCTOR`, `EXAMINER`, `STUDENT`.
- JWT chỉ phát claim `roles` và `tenant_id`; `ResourceServerJwt` chuyển role thành `ROLE_*`; chưa có permission registry hoặc dynamic role builder.
- `UserProvisioningHelper` chỉ cho `PLATFORM_ADMIN` tạo `HOST_ADMIN`, còn `HOST_ADMIN` tạo `PROCTOR`/`EXAMINER`/`STUDENT`.
- Question, task type/question type, score template, blueprint và snapshot hiện đang dùng literal `PLATFORM_ADMIN`/`PLATFORM_AUTHOR` ở controller hoặc service policy.
- Các academic aggregate (`Question`, `QuestionTypeDefinition`, `ScoreTemplate`, `ExamBlueprint`) chưa có `authorUserPublicId`; audit log hiện chỉ ghi actor sau khi thao tác xảy ra.
- Các endpoint tenant/application/plan/license/settings/announcement/support phần lớn đang guard trực tiếp bằng `PLATFORM_ADMIN`; service signatures không phải nơi nào cũng nhận `CurrentUser`.
- Vendor web dùng `SessionRole` trong `packages/ui`, `ADMIN_ROLES`/`PLATFORM_ADMIN_ONLY` trong `apps/vendor-web/features/auth/constants.ts`, `requiredRoles` trong navigation và page-level `RequireAuth`.
- API client còn comment và contract giả định nhiều score-template/admin endpoints là `PLATFORM_ADMIN`-only.

### Phạm vi tối thiểu

- Dùng fixed role catalog và static permission bundles; không xây custom-role editor trong MVP.
- Thêm platform-user management tối thiểu để `PLATFORM_ADMIN` có thể tạo, khóa/mở khóa và gán ba role platform mới; không mở quyền role management cho manager/academic roles.
- Không thay đổi authentication/token architecture; chỉ mở rộng canonical role claim và normalize legacy author.
- Không thay đổi business logic chấm điểm, examiner assignment, exam publishing hoặc tenant-host workflow ngoài authorization boundary.

## Confirmed Decisions

1. `PLATFORM_MANAGER` không được `cancel`, `revoke`, `refund` hoặc thực hiện thao tác tài chính hủy/hoàn tiền; các thao tác này giữ ở `PLATFORM_ADMIN`.
2. `PLATFORM_AUTHOR` được giữ như legacy alias trong thời gian chuyển tiếp; token/API/UI normalize về `ACADEMIC_STAFF`, sau khi backfill và xác nhận compatibility mới loại bỏ alias ở migration cleanup.
3. `ACADEMIC_MANAGER` review/approve/publish version; không sửa trực tiếp scoring policy đang active. Mọi thay đổi phải đi qua draft/version và audit.
4. Không cho `ACADEMIC_STAFF` approve/publish. `ACADEMIC_MANAGER` cũng không approve bản draft do chính mình tạo; `PLATFORM_ADMIN` giữ quyền override đặc quyền và phải có audit.
5. Các common contract/constant/policy đã có phải được rà soát và tái sử dụng trước khi tạo mới: `CurrentUser`, `CurrentUserContext`, `ResourceServerJwt`, `AuditLogService`, `@pte/ui` `SessionRole`, API-client types và các lifecycle status hiện có.

## Proposed Role and Permission Matrix

| Capability | `PLATFORM_ADMIN` | `PLATFORM_MANAGER` | `ACADEMIC_MANAGER` | `ACADEMIC_STAFF` | Tenant roles |
|---|---:|---:|---:|---:|---|
| Role/security management | Full | No | No | No | No |
| Tenant/application operations | Full | Read + operational review/lifecycle | No | No | Own tenant only for `HOST_ADMIN` |
| Plan/catalog operations | Full | Draft CRUD + activate/archive | No | No | Read active catalog where existing |
| License operations | Full, including reveal/revoke | Issue/list/masked lookup | No | No | Redeem according to existing flow |
| Order/subscription reporting | Full | Read operational view | No | No | Own tenant workflow unchanged |
| Global announcements/support | Full | Create/update/publish/support handling | No | No | Host support submission unchanged |
| Platform settings | Full | No | No | No | No |
| Academic draft authoring | Full | No | Full | Draft/import/edit | No |
| Academic review/approve | Full | No | Other users' drafts | No | No |
| Academic publish/activate | Full | No | Version publish/activate | No | Consume published resources |
| Exam/session scoring workflow | Existing privileged override | No | No | No | Existing Host/Examiner/Proctor/Student boundary |

The final API matrix must define each endpoint/action explicitly. A role name alone is not sufficient for authorization.

## Research and Source Audit Conclusions

### Primary approach: fixed roles + shared authorization policy

Use the existing modular monolith and JWT role claim. Add canonical role/permission definitions under the existing shared security boundary, keep domain-specific lifecycle checks in each module, and pass `CurrentUser` into mutations that currently rely only on controller annotations. This preserves the current architecture and allows explicit deny tests.

### Alternative considered: database-driven permissions/custom roles

This would support future organization-specific roles, but it requires permission tables, cache/token invalidation, admin UI, migration semantics and a much larger audit surface. It is deferred; MVP uses static bundles and no user-created roles.

### Red-team conclusions

- Changing only frontend navigation would leave all current APIs vulnerable to privilege confusion; every controller and service policy must be updated.
- Changing only `PLATFORM_AUTHOR` to `ACADEMIC_STAFF` without a legacy alias would invalidate existing rows/tokens and can lock out authors during rollout.
- Audit logs cannot prove self-approval unless academic rows record their author; add ownership metadata to authorable aggregates.
- Broadening a class-level `PLATFORM_ADMIN` annotation to manager can accidentally expose reveal/revoke/settings endpoints; split endpoint actions before broadening.
- `PLATFORM_MANAGER` access to platform-wide data must remain platform-scoped and must not be mistaken for tenant-scoped `HOST_ADMIN` access.
- Active score/template/runtime rows are immutable contracts; manager or academic UI must not gain in-place mutation paths around existing lifecycle locks.

## Dependency Order

```text
Phase 1: role/common contract + legacy migration
              ↓
Phase 2: identity/platform-user management + shared authorization
          ↙                         ↘
Phase 3: academic workflow       Phase 4: platform operations
          ↘                         ↙
Phase 5: vendor Admin Web + API client role-aware UX
              ↓
Phase 6: migration/seed, integration regression, quality gate
```

Phase 3 and Phase 4 can be developed in parallel after Phase 2, but Phase 5 must wait for their endpoint/action matrix. Phase 6 is the only release-quality gate and does not replace per-phase tests.

## Phases

- [x] Phase 1: Role catalog, common contracts and legacy author migration
- [x] Phase 2: Platform identity, role assignment and shared authorization foundation
- [x] Phase 3: Academic authoring, approval and publish boundaries
- [x] Phase 4: Platform Manager operational boundaries
- [x] Phase 5: Vendor Admin Web and API-client role-aware UX
- [x] Phase 6: Seed/migration verification, full regression and quality gate

## Cross-cutting Design Constraints

- Reuse existing shared security, audit, API response, lifecycle and UI session contracts before adding new abstractions.
- Keep authorization deny-by-default and server-side. `requiredRoles`, `RequireAuth` and hidden buttons are UX only.
- Do not put a full permission graph or sensitive business data into JWT claims; JWT carries canonical roles, while resource ownership/scope is checked from server data.
- Keep platform roles tenantless (`tenantId == null`) and tenant roles tenant-bound. Reject mixed platform/tenant role sets.
- Legacy `PLATFORM_AUTHOR` must be accepted during the compatibility window but never become a second semantic authoring implementation.
- All role assignment, approval, rejection, publish/activate, financial-sensitive action and authorization failure events must be auditable without passwords, tokens or secrets.
- Existing active/approved/published runtime data remains immutable unless its module already defines a safe version transition.
- Error codes/messages used by the new policy must be centralized in existing module constants/common error contracts; no new literal authorization messages in services.
- Database migrations must be additive/backward-compatible first, then backfill, then cleanup only after the compatibility window is verified.

## Verification Strategy

- Backend unit tests: role normalization, scope invariants, static capability policy, self-approval, manager action matrix and service caller propagation.
- Backend controller/security tests: authenticated role allow/deny, forbidden endpoints, legacy alias behavior, tenantless/tenant-bound claims.
- PostgreSQL/Flyway integration: role constraint, backfill, old rows/tokens compatibility, no mixed role sets, audit rows.
- API-client tests: role contract, endpoint path/method preservation, no stale `PLATFORM_ADMIN`-only comments/assumptions where manager/academic roles are allowed.
- Vendor web checks: `npm` lint, `tsc --noEmit`, build, component tests where present, and Playwright smoke for login/redirect/menu/action visibility.
- Final quality gate: `ck:quality --gate`/equivalent review of changed scope, then full relevant unit/integration/API-client checks. A compile or static check alone does not prove live HTTP authorization.

## Plan Risks and Decisions to Carry into Cook

1. The database has a role check constraint in `V35__identity_role_taxonomy.sql`; role expansion must use a new migration rather than editing an old applied migration.
2. The current platform-user UI is not present in vendor-web; Phase 2 backend and Phase 5 UI must add a dedicated platform-user surface instead of reusing tenant host-account screens incorrectly.
3. Academic approval status is not uniform: questions/blueprints/templates already have approval transitions, while `QuestionTypeDefinition` currently uses `ACTIVE/INACTIVE/RETIRED`. Phase 3 must define a compatible lifecycle without breaking runtime contract locks.
4. The final implementation should preserve the existing local seed workflow and add role fixtures only through documented local seed paths; no production credentials or secrets belong in the plan/code.

## Acceptance Criteria for the Whole Plan

- All eight agreed roles exist in backend and frontend contracts; old `PLATFORM_AUTHOR` accounts remain usable during compatibility and are migrated to `ACADEMIC_STAFF`.
- `PLATFORM_ADMIN` can manage platform users and all privileged actions; no other role can manage role/security.
- `PLATFORM_MANAGER` can perform the explicitly allowed operational actions but receives 403 for settings, role management, academic approve/publish and cancel/revoke/refund.
- `ACADEMIC_STAFF` can create/import/edit/submit drafts but cannot approve or publish through UI or direct API.
- `ACADEMIC_MANAGER` can review/approve/publish another user's academic draft; self-approval is denied; version/audit history is preserved.
- Host/examiner/proctor/student flows and tenant isolation remain unchanged and pass regression tests.
- Vendor Admin Web routes, navigation and action buttons reflect role capabilities without relying on frontend checks for security.
- Migration and local seed verification pass on a real PostgreSQL-backed application; final quality gate reports findings explicitly.

## Final verification

Phase 6 verification is recorded in:

- `pte-doc/plans/platform-role-expansion/tests/phase-06-seed-migration-regression-and-quality-gate-test-report.json`
- `pte-doc/plans/platform-role-expansion/quality/phase-06-seed-migration-regression-and-quality-gate-quality-report.json`
- `pte-doc/plans/platform-role-expansion/quality/phase-06-seed-migration-regression-and-quality-gate-receipt.json`

All six phases are implemented and quality-gated for local release scope. Production deployment, non-local migration, and the deferred opt-in integration suites remain outside this local verification.
