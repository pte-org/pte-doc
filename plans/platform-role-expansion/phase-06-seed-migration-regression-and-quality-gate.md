# Phase 6: Seed/migration verification, full regression và quality gate

## Goal

Hoàn tất compatibility cleanup sau khi các phase chức năng đã chạy, kiểm chứng migration/seed trên PostgreSQL thật, chạy permission matrix end-to-end và thực hiện quality gate cuối cùng trước khi kết luận feature sẵn sàng.

## Stories covered

- Toàn bộ P1 stories

## Steps

1. Rà lại migration chain: role catalog, academic ownership/lifecycle và mọi index/constraint mới; chạy Flyway trên database sạch và database có dữ liệu legacy.
2. Chạy compatibility window verification: login/refresh legacy author, token canonicalization, role assignment mới, old rows và old API clients trong phạm vi được hỗ trợ.
3. Backfill `PLATFORM_AUTHOR` rows thành `ACADEMIC_STAFF` sau khi xác nhận không còn account/token cần alias; giữ hoặc loại legacy enum/check theo migration decision đã ghi trong Phase 1, không xóa dữ liệu audit.
4. Cập nhật local seed path/manifest cho các role mới và các resource học thuật ownership-aware; seed local chỉ dùng fixture an toàn, không ghi credential production.
5. Chạy backend unit/service/controller tests thuộc identity, shared security, itembank, assessment, scoretemplate, billing, tenancy, notification, support; chạy integration PostgreSQL/Flyway cho migration và critical authorization.
6. Chạy API-client test suite, vendor-web lint/typecheck/build và Playwright smoke: login từng platform role, redirect, menu, create/submit/review/publish, manager forbidden actions, host boundary.
7. Kiểm tra audit output không chứa password, access/refresh token, raw license code hoặc payment secret; kiểm tra authorization failures có trace actor/target/scope cần thiết.
8. Chạy final `ck:quality`/code review trên changed scope; sửa BLOCKER/HIGH và current-change MEDIUM trước khi ghi nhận quality gate.
9. Ghi final verification report vào plan hoặc quality artifact: command, environment, exit code, pass/fail, known limitations; không gọi static build là live authorization proof.

## Design Constraints

- Preflight: review the existing migration/seed and test conventions before adding new artifacts; reuse common security, identity, fixture, API-client, and frontend test helpers where they already cover the contract.

- Không dùng `docker volume rm`, reset database hoặc destructive cleanup trong phase này nếu chưa xác định đúng PTE-scoped target và có xác nhận riêng.
- Integration authorization phải chạy với real PostgreSQL/migration state; unit mock không đủ để chứng minh check constraint/backfill.
- Không seed production-like credentials vào repo; local account fixture phải được tài liệu hóa riêng và chỉ dùng local.
- Không đánh dấu phase/feature complete chỉ vì compile hoặc frontend route render; cần evidence cho API 403/allow và migration data integrity.
- Quality gate độc lập với test runner; một report pass không thay thế code review/quality audit.

## Files / ownership

- `pte-api/app/src/main/resources/db/migration/V86__*.sql` và migration tiếp theo
- identity/security/academic/billing test suites
- `pte-api/scripts/*seed*`, `pte-doc/data` hoặc manifest seed liên quan
- `pte-web/packages/api-client` tests, vendor-web checks/Playwright smoke scripts
- `pte-doc/plans/platform-role-expansion/quality/*` nếu quality/test artifacts được ghi ra file

## Quality and Testing State

- Quality: APPROVED after final changed-scope review; no BLOCKER, HIGH, or current-change MEDIUM findings. Existing vendor-web `no-img-element` warnings remain noted and are outside this role phase.
- Testing: PASSED. Backend regression completed with 1,312 tests, 0 failures, 0 errors, and 41 opt-in skips; API-client completed 20 files/422 tests; vendor-web typecheck, lint, and production build passed.
- This phase's migration contract test passed 3/3. The dedicated PostgreSQL migration rehearsal passed 1/1 inside the Compose network, including V1-V88 fresh schema creation, legacy `PLATFORM_AUTHOR` insertion, V89 backfill, and V90 index rebuild.
- Local Docker verification reached Flyway schema version 90. The platform username uniqueness index is rebuilt with `tenant_id IS NULL AND deleted = false`; the local role seed reconciled the three new platform fixtures through the `PLATFORM_ADMIN` API without resetting unrelated data.
- Live HTTP verification covered login/refresh for the eight role categories and allow/deny samples for platform, academic, tenant, and student boundaries. Playwright smoke passed for `PLATFORM_ADMIN` login, platform navigation, platform-user management, and the question-type route.
- Limitations: the 41 skipped tests are existing opt-in PostgreSQL suites without their dedicated DB properties in the host Maven process; the new migration rehearsal was executed separately against the dedicated Docker PostgreSQL. Browser smoke covered the admin role; other role boundaries are evidenced by live HTTP, not browser sessions. No production deployment or non-local database validation was performed.

## Acceptance Criteria

- Fresh PostgreSQL migration và legacy-data migration đều pass, không mất role/resource/audit data.
- Legacy author compatibility được verify trước backfill; sau backfill account nhận `ACADEMIC_STAFF` canonical.
- Permission matrix có bằng chứng allow/deny cho cả tám role và các scope chính.
- Self-approval, cross-tenant access, mixed-role assignment, manager-sensitive action và academic staff publish đều bị kiểm chứng.
- Existing Host/Examiner/Proctor/Student exam flow và notification/support/commercial regression pass trong phạm vi thay đổi.
- Frontend/API client/backend quality checks có command + result rõ ràng.
- Không còn BLOCKER/HIGH hoặc current-change MEDIUM từ quality gate; mọi limitation còn lại được ghi rõ thay vì tuyên bố quá mức.
