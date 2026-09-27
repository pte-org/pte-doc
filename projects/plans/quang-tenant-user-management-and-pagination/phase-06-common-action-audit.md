# Phase 06: Common action audit and adoption matrix

## Objective

Audit row-level actions in tenant-web and vendor-web, then select the screens
where a shared three-dot menu improves consistency without hiding contextual
operations.

## Design constraints

- Use the existing `@pte/ui` portal dropdown behavior.
- Keep frequent assignment/unassignment and answer-review controls inline when
  that is clearer.
- Do not change business permissions while changing action presentation.

## Audit result

### Adopt the shared menu

- Tenant Student Search: view/reset credential and suspend/reactivate.
- Tenant Learners Overview and student roster tables: credential actions.
- Tenant Exam Staff: details, send email, credential action, and lifecycle.
- Vendor Tenants and Organizations: existing menu becomes the common contract.
- Vendor Licenses, License Codes, Plans, and application list: row actions are
  suitable for the same menu.
- Vendor Question Bank and tenant Order history: row status/view actions are
  also represented through the same menu.

### Keep contextual controls inline

- Exam answer review, class/coordinator/proctor assignments, and similar
  assign/unassign tables: these are task-context controls rather than resource
  CRUD menus.
- Read-only dashboard/program summary tables without row mutations.

## Quality/testing state

- Source audit: complete.
- Implementation: complete for the audited scope.
- Verification: tenant/vendor typecheck, lint, and build passed; the full
  backend suite passed with 693 tests. New-feature production smoke remains
  deployment-gated.
