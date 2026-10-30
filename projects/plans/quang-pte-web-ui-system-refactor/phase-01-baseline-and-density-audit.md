# Phase 01: Baseline inventory and density audit

## Objective

Create the route/component/theme/locale matrix and turn the initial overloaded
screen candidates into evidence-backed migration decisions before changing
shared presentation code.

## Files and Areas

- `pte-web/apps/vendor-web/app/**`
- `pte-web/apps/tenant-web/app/**`
- `pte-web/apps/*/features/**`
- `pte-web/packages/ui/src/**`
- `pte-web/docs/CODING_STANDARDS_WEB.md`
- New planning evidence under this plan directory:
  `route-matrix.md`, `actor-permission-matrix.md`,
  `behavior-preservation-manifest.md`, `density-audit.md`,
  `failure-state-matrix.md`, and `visual-consumer-inventory.md`

## Inputs

- Current `pte-web` route files, role gates, feature views, and shared exports.
- Existing app account role fixtures, without copying credentials into an
  artifact.
- The source-grounded density candidates and ownership decisions in `plan.md`.

## Outputs

- `route-matrix.md`: one row per current route with actor, gate, owner,
  primitive, theme/locale, responsive, and density columns.
- `actor-permission-matrix.md`: one row per actor/route/protected action with
  visibility, access result, redirect/forbidden behavior, and evidence.
- `behavior-preservation-manifest.md`: one row per candidate migration surface
  covering URL state, queries, mutations, payloads, validation, callbacks,
  modal/action entry points, and state ownership.
- `density-audit.md`: exact `J/S/I/M/A/C` counts, classification, priority,
  evidence, and route-preserving treatment for every route.
- `failure-state-matrix.md`: loading, empty, validation, unauthorized,
  forbidden, not-found, network/timeout, conflict, stale, duplicate-request,
  and placeholder-data rows mapped to feature owners and scenarios.
- `visual-consumer-inventory.md`: chart, overlay, status, navigation, and
  literal-color consumers assigned to a migration phase.

## Steps

1. Enumerate every route and every actor boundary: platform administrator,
   host administrator, examiner, proctor, student, and anonymous user.
2. Record route visibility, access result, current redirect/forbidden outcome,
   protected actions, feature owner, page/view component, and shared primitive.
3. Create a behavior-preservation row for every route or surface selected for
   migration, including hooks, queries, mutations, payloads, validation,
   callbacks, modal entry points, and presentation-state ownership.
4. Record current light-only token usage, literal color utility usage, raw UI
   strings, date/number formatting, duplicated shell/navigation code, and all
   chart/overlay/status consumers.
5. Score every route with the `J/S/I/M/A/C` rubric in `plan.md`; classify every
   route as normal, content-heavy, or function-heavy with exact evidence.
6. Map each known failure/recovery state to its current owner, expected UI,
   action, and verification scenario; do not invent new retry/auth behavior.
7. Capture desktop, 390px, and 320px current-theme screenshots for pilot
   routes when local runtime data permits; do not mutate local data.
8. Freeze the first migration wave and list any candidate needing a product
   decision or mini-plan before implementation.

## Design Constraints

- Read-only audit; no production source changes.
- Treat line count as evidence, not as the sole reason to split a screen.
- Do not infer that a feature is complete from route scaffolding alone.
- Keep `pte-app` out of the web inventory.

## Quality and Testing State

- Quality: not evaluated.
- Testing: not started; browser evidence is baseline only.

## Blocking Gate

- **PASS** only when all routes have matrix rows, every actor boundary required
  by the local role contract is observed, every route has density counts and
  classification, every migration surface has a behavior row, every required
  failure state has an owner/scenario, and chart/overlay/status consumers have
  a phase assignment.
- **UNVERIFIED** when local data or browser infrastructure prevents runtime
  observation; this blocks dependent phases unless a written waiver follows
  the master-plan gate policy.
- **BLOCKED** when a route, role gate, protected action, or behavior owner is
  missing from the evidence and implementation would require guessing.

## Exit Criteria

- 100% of current web routes are in the route, actor, density, and failure
  matrices.
- Every migrated surface has a behavior-preservation manifest row.
- Every P1 candidate has an evidence paragraph and an in-route decomposition
  proposal.
- The common foundation and vendor/admin pilot route set are explicitly frozen.

## Cook Record 2026-10-07

- Implementation: completed.
- Outputs: route matrix, actor/permission matrix, behavior-preservation
  manifest, density audit, failure-state matrix, and visual-consumer inventory.
- Blocking Gate: **PASS** for the static artifact gate. Browser/runtime
  validation is owned by Phase 09 and remains unverified.
