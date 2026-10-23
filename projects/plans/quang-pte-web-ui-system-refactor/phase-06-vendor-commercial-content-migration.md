# Phase 06: Vendor commercial, authoring, and content migration

## Objective

Migrate the remaining vendor/admin commercial and authoring surfaces, applying
the approved in-route decomposition to the highest-density workflows.

## Files and Areas

- `pte-web/apps/vendor-web/features/commercialization/**`
- `pte-web/apps/vendor-web/features/licensing/**`
- `pte-web/apps/vendor-web/features/scoretemplate/**`
- `pte-web/apps/vendor-web/features/questionbank/**`
- `pte-web/apps/vendor-web/features/questiontemplate/**`
- `pte-web/apps/vendor-web/features/supportTickets/**`
- Relevant vendor admin routes for plans, license codes, templates, questions,
  question types, platform settings, and support tickets

## Inputs

- Phase 05 pilot verification and the common contracts.
- Phase 01 density, behavior, actor, and failure-state artifacts.
- Approved mini-plans for each P1 function-heavy vendor surface.

## Outputs

- Mini-plan records for `LicenseCodesView`, `PlanCatalogView`, score-template
  list/editor, and any question-authoring surface promoted from P2.
- `phase-06-verification.md`: lifecycle, conflict/recovery, theme/locale,
  responsive, and behavior-preservation evidence.

## Steps

1. Migrate standard list/detail screens using common page, filter, table, form,
   status, modal, and action primitives.
2. Treat `LicenseCodesView` as a P1 density candidate: preserve the route and
   split Issue, Lookup, and Issued codes into in-route work areas.
3. Treat `PlanCatalogView` as a P1 candidate: keep catalog list as the stable
   surface and move create/edit into a drawer or step panel without changing
   payloads or lifecycle actions.
4. Treat score-template list/editor as a P1 candidate: separate metadata,
   task-type ordering, and review/activation visually while retaining current
   hooks and callbacks.
5. Treat question authoring as P2: separate prompt/options/media/scoring and
   preview sections only after the audit confirms the exact workflow boundary.
6. Keep licensing, approval, version-conflict, recovery, and validation
   semantics unchanged.

## Design Constraints

- No new commercial/content capability, API, route, permission, or payload.
- No route-level split in this phase; route proposals go to phase 09 backlog.
- Destructive actions retain their existing confirmation and error handling.
- Secret-like license code reveal behavior must not be exposed in logs or
  translated into a different security flow.
- Conflict, duplicate-request/idempotency, validation, and recovery rows in
  the failure-state matrix must remain reachable in their owning features.

## Quality and Testing State

- Quality: not evaluated.
- Testing: not started; verify vendor routes, approval/lifecycle actions,
  dialog focus, both themes/locales, and no new lint/type/build errors.

## Blocking Gate

- **PASS** when every P1 surface has an approved mini-plan, route-preserving
  grouping is implemented, lifecycle/conflict/recovery behavior is evidenced,
  and all changed vendor surfaces pass the required static and visual checks.
- **UNVERIFIED** when a protected action or failure path cannot be exercised
  locally; name the exact scenario and limitation. This blocks phase 09 unless
  a written waiver follows the master-plan gate policy.
- **BLOCKED** when a decomposition needs a route/API/permission change or a
  failure-state guard is no longer reachable.

## Exit Criteria

- All vendor commercial/content routes use common theme/locale-safe primitives.
- P1 density candidates have the approved in-route structure without behavior
  changes.

## Cook Record 2026-10-07

- Implementation: common theme/locale-safe primitives and shell treatment were
  applied to the vendor commercial/content/support consumers; no route/API
  split was introduced.
- Verification: vendor typecheck, lint, and build passed; route-by-route
  browser behavior and the remaining feature-local migration were not run.
- Blocking Gate: **UNVERIFIED** because the full feature/browser evidence and
  `ck:quality` were skipped at the user's request.
