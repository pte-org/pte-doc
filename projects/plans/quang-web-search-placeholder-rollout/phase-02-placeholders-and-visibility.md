# Phase 02 — Localized Placeholders and Search Visibility

## Goal

Remove generic search copy from all visible tenant/admin tables and make the presence of search intentional.

## Scope

- Add feature-owned placeholder and aria-label copy for the 35 generic tables.
- Keep and verify the five existing criteria-specific table placeholders.
- Correct the Question Bank placeholder to match its real predicate, or add the missing ID/code predicate if that is explicitly approved by the data contract.
- Add explicit `showSearch={false}` to contextual/review tables selected in Phase 1.
- Leave the four existing hidden tables unchanged unless the Phase 1 contract proves otherwise.

## Suggested copy families

- Students/learners: name, email, phone, student code.
- Exam staff/platform users: name or email.
- Tenants: tenant name, tenant code, tax code.
- Classes/programs: class/program name and code where available.
- Tickets: ticket identifier, subject, requester/tenant where available.
- Audit logs: actor, action, aggregate/object identifier where available.
- Orders/licenses: order/license identifier and tenant where available.
- Announcements: title or body.
- Score/question templates: name/code/version or task type/key/section.

## Implementation steps

1. Add copy to the nearest existing constants or locale/admin-copy catalog.
2. Pass `searchPlaceholder` and `searchAriaLabel` at every enabled table call site.
3. Set `showSearch={false}` for contextual tables with no useful search scope.
4. Ensure copy is localized through the existing tenant/vendor mechanisms.
5. Run a static check that no audited enabled table lacks an explicit placeholder.

## Design Constraints

- Do not change search control styling or shared visual defaults.
- Do not add icons or a second search component.
- Do not promise fields that are only displayed but not part of the actual client/server predicate.
- Keep labels concise enough to remain usable at mobile widths.

## Quality and Testing State

- **Preflight:** reviewed the plan constraints, `DataTable`, `StudentSearchView`, `ExamStaffView`, `PlatformUsersView`, `LocaleProvider`, and `adminCopy`; this phase will reuse the existing search props and locale adapters without changing shared visual defaults.
- **Quality:** approved — all enabled visible tables have explicit localized search copy; contextual/review tables have intentional `showSearch={false}`; the unmounted legacy `ExamStaffTable` is documented and excluded from the visible-surface gate. Report: `pte-doc/projects/plans/quang-web-search-placeholder-rollout/quality/phase-02-placeholders-and-visibility-quality-report.json`.
- **Testing:** passed — static inventory, tenant/vendor typecheck and lint, UI typecheck, tenant tests 37/37, and API-client tests 442/442. Report: `pte-doc/projects/plans/quang-web-search-placeholder-rollout/tests/phase-02-placeholders-and-visibility-test-report.json`.
- Planned checks: completed; no shared `DataTable` visual defaults were changed.

Phase status: completed after the final placeholder/visibility inventory and scoped checks.
