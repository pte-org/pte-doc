# Phase 09: Cross-app regression, visual matrix, and handoff

## Objective

Verify the refactor across both apps, close common regressions, and document
remaining route-level decomposition proposals without claiming unavailable
runtime or production evidence.

## Files and Areas

- `pte-web` entire workspace
- Route/density/theme/locale matrix from phase 01
- New verification report under this plan directory
- Route-level split backlog and follow-up decision record

## Inputs

- All phase verification reports and updated route/actor/behavior/density/
  failure matrices.
- Final changed-file list and any accepted limitations from local browser/API
  environments.

## Outputs

- `phase-09-verification.md`: static, browser, accessibility, responsive,
  theme/locale, role, and behavior evidence with PASS/UNVERIFIED/BLOCKED
  status per gate.
- `route-split-backlog.md`: remaining route-level proposals with rationale,
  affected actors, and required product decisions.
- Final handoff summary distinguishing implementation, quality review, local
  browser evidence, and release-readiness limitations.

## Steps

1. Run common package typecheck, both app lint/typecheck/build checks, and
   `git diff --check`.
2. Run browser smoke at representative vendor/admin, tenant/host,
   examiner, student, public, and auth routes at desktop, 390px, and 320px
   widths.
3. Repeat visual checks in light/dark and vi/en, including theme/locale
   persistence after reload and `html[lang]`.
4. Check navigation/role visibility, dialogs, action menus, forms, table
   scrolling, loading/empty/error/success/stale/conflict/forbidden state
   presentation, focus-visible behavior, reduced-motion behavior, pathname/
   query/hash preservation, refresh/deep-link, browser back/forward, Escape,
   close, and focus return.
5. Run a raw-string and literal-color audit for changed surfaces; classify
   intentional domain text separately from untranslated UI copy.
6. Record pre-existing warnings, unavailable PostgreSQL/API/browser gates,
   and any route not covered by local data.
7. Publish a handoff report with completed phases, open risks, and route-level
   split candidates requiring a separate product decision.

## Design Constraints

- Do not repair unrelated pre-existing warnings as part of handoff.
- Do not claim production readiness from static/build/browser-local evidence.
- Do not include credentials, tokens, hashes, or sensitive domain data in
  screenshots or reports.
- A route-level split remains out of scope unless a new plan is approved.

## Quality and Testing State

- Quality: not evaluated.
- Testing: not started; this phase owns final fresh evidence.

## Blocking Gate

- **PASS** when all applicable mandatory static and browser checks are
  recorded, all actor/behavior/failure rows are resolved, and remaining
  route-level proposals are handed back without being silently implemented.
- **UNVERIFIED** when infrastructure or local data prevents a required check;
  release readiness remains blocked, unless a written waiver follows the
  master-plan gate policy.
- **BLOCKED** when a regression changes route, role, API, validation, state,
  or action contracts and cannot be isolated as unrelated pre-existing work;
  release readiness remains blocked unless a written waiver follows the
  master-plan gate policy.

## Exit Criteria

- All applicable static and browser checks have recorded outputs.
- The final report distinguishes implementation, quality review, local browser
  evidence, and release-readiness limitations.
- Remaining overloaded screens and route-split proposals are explicitly
  handed back for product planning.

## Cook Record 2026-10-07

- Implementation: static handoff recorded in
  `cook-run-2026-10-07.md`; both apps and the shared package passed the
  available static checks.
- Verification: browser, authenticated API/data, responsive, role, and full
  regression checks were not run; `ck:test` and `ck:quality` were skipped at
  the user's request.
- Blocking Gate: **UNVERIFIED**; release readiness remains intentionally open
  until the user performs the runtime review.
