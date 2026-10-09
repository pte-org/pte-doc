# Phase 07: Tenant host operations migration

## Objective

Migrate the tenant host dashboard and organization operations while preserving
role-specific navigation, organization labels, roster behavior, and billing or
support workflows.

## Files and Areas

- `pte-web/apps/tenant-web/features/auth/components/DashboardChrome.tsx`
- `pte-web/apps/tenant-web/features/examoperations/**`
- `pte-web/apps/tenant-web/features/studentSearch/**`
- `pte-web/apps/tenant-web/features/examStaff/**`
- `pte-web/apps/tenant-web/features/programs/**`
- `pte-web/apps/tenant-web/features/classes/**`
- `pte-web/apps/tenant-web/features/commercialization/**`
- `pte-web/apps/tenant-web/features/supportTickets/**`
- `pte-web/apps/tenant-web/features/notifications/**`
- `pte-web/apps/tenant-web/features/auditLog/**`

## Inputs

- Phase 04 common-component contract and Phase 01 actor/behavior/density/failure
  artifacts.
- Host route set and organization-driven label inventory.

## Outputs

- `phase-07-verification.md`: host role matrix, student/class/program behavior
  review, theme/locale/responsive checks, and limitations.
- Approved mini-plans for `StudentSearchView` and class/program surfaces where
  the density rubric requires them.

## Steps

1. Migrate host dashboard, learner overview, exam staff, programs/classes,
   billing, notifications, audit log, and support list/detail surfaces.
2. Treat `StudentSearchView` as a P1 candidate: keep the roster route and
   separate contextual filters, table actions, and add/import/details flows
   visually.
3. Treat class/program detail and roster/import flows as P2 candidates:
   preserve current modal entry points and group related actions into sections.
4. Reuse organization-driven labels in both locales without translating
   organization-provided names as UI copy.
5. Verify host-only navigation and `requiredRoles` filtering remain unchanged.

## Design Constraints

- No change to organization, class, student, lecturer, billing, or support
  API contracts.
- Preserve student credential-generation and staff credential-delivery rules.
- Keep intentional table scrolling scoped to table containers.
- Do not leak tenant data between locale/theme persistence mechanisms.

## Quality and Testing State

- Quality: not evaluated.
- Testing: not started; run tenant lint/typecheck/build and role-specific
  browser smoke for host admin, including mobile and both themes/locales.

## Blocking Gate

- **PASS** when host-only navigation and protected actions match the actor
  matrix, student credential rules and organization labels are unchanged, and
  changed surfaces pass light/dark, vi/en, desktop, 390px, and 320px checks.
- **UNVERIFIED** when host/student local data prevents a browser scenario;
  record the unavailable evidence. This blocks phase 08 and phase 09 unless a
  written waiver follows the master-plan gate policy.
- **BLOCKED** when tenant data ownership, staff/student credential rules,
  role filtering, or API/mutation behavior changes.

## Exit Criteria

- Host operations share the common system without duplicating shell primitives.
- Student/class/program dense surfaces have documented or implemented
  route-preserving grouping decisions.
- Host role restrictions and local data behavior remain intact.

## Cook Record 2026-10-07

- Implementation: tenant host shell/navigation and common presentation
  consumers now use the shared system; no host API or role-filtering changes
  were introduced.
- Verification: tenant typecheck, lint, and build passed; authenticated host
  role/data behavior and dense-surface browser checks were not run.
- Blocking Gate: **UNVERIFIED** because runtime evidence and `ck:quality` were
  skipped at the user's request.
