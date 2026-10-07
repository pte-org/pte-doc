# Phase 3: Verification and handoff

## Objective

Verify the UI-only change across the common package and vendor pilot, then
record precise evidence and limitations.

## Files

- No production files are added in this phase.
- Verification evidence belongs in the session notes or command output; do not
  add secrets, credentials, or tokens to the repository.

## Steps

1. Run `corepack pnpm --filter @pte/ui typecheck`.
2. Run `corepack pnpm --filter vendor-web lint`.
3. Run `corepack pnpm --filter vendor-web exec tsc --noEmit`.
4. Run `corepack pnpm --filter vendor-web build`.
5. Run `git diff --check` from `pte-web`.
6. If local auth/API state permits, open `/admin/tenants` in a visible browser,
   capture the pilot at desktop and mobile widths, and check the existing Add,
   filter, collapse, and row-action entry points without submitting mutations.

## Design Constraints

- Preflight: use the repository's existing pnpm scripts and browser evidence
  boundaries; do not claim live API or production release readiness from static
  checks.
- Do not alter source while reporting verification results unless a build
  failure directly identifies a regression in phases 1-2.

## Quality and Testing State

- Quality: final manual review completed; no unrelated files or behavior
  contracts were changed. Formal `ck:quality` was not run.
- Testing: package typecheck, vendor lint/typecheck/build, and `git diff
  --check` passed. Authenticated Playwright smoke opened `/admin/tenants`,
  exercised search filtering and opened/closed Add Tenant without submitting;
  no console/page errors occurred. The 390px smoke confirmed no page-level
  horizontal overflow. The local API login probe accepted all seven supplied
  accounts; role-specific screens were not expanded in this pilot.
- Required checks: completed for the common foundation and platform-admin
  tenant screen.

## Success Criteria

- All applicable commands exit successfully or their exact pre-existing
  limitations are reported.
- Worktree diff contains only the intended common/pilot UI and plan artifacts.
- Final report distinguishes static/build evidence from browser/API evidence.
