# Phase 02: Verification and handoff

## Requirements

Validate the completed tenant-only implementation against every success
criterion in the spec, with special attention to session preservation and the
rejected logout-on-Home behavior.

Stories: all P1 and P2 stories, plus the P3 vendor/admin exclusion.

Acceptance criteria: all success-criteria checkboxes in `spec.md` are backed by
fresh command or browser evidence; no vendor/admin behavior is intentionally
changed.

## Design Constraints

- Verify against the actual tenant app and its existing session implementation;
  do not bypass `RequireAuth` or add test-only production behavior.
- Use an ephemeral/fake local session only for browser validation when a real
  account is unavailable. Never commit credentials or browser scripts containing
  credentials.
- Establish the dirty-worktree baseline before judging scope. Existing
  unrelated changes must not be attributed to this feature.
- Do not mutate production data. A deployed smoke check, if available, must
  use read-only navigation and intercepted mutation requests.
- Treat the earlier `clearToken` + `replace` implementation as a regression
  target: brand navigation must preserve the exact serialized `pte.session`.
- Quality and testing remain pending until the implementation phase is cooked;
  this phase describes the checks, not their results.

## Verification steps

1. Run tenant lint, TypeScript, Prettier check, production build/compile mode
   as available in the local environment, and `git diff --check`.
2. Inspect the final changed-file list. Confirm the implementation is limited
   to the planned tenant files and that vendor/admin has no new feature change.
3. Exercise successful login and confirm one navigation to
   `/host/dashboard`; do not alter the existing redirect contract.
4. On the dashboard, assert:
   - no sidebar link named `Home` exists;
   - one sidebar link named `Overview` exists with href `/host/dashboard`;
   - logo, `PTE Prep`, and `School Portal` are all within the Home link or
     otherwise individually activate the same `/` link;
   - clicking brand preserves the exact pre-click `pte.session` value;
   - browser Back can return normally because brand navigation does not use
     `replace`.
5. On public Home with the session present, assert the URL remains `/` after
   navigation and refresh, one Dashboard action is visible, and clicking it
   reaches `/host/dashboard` without changing `pte.session`.
6. On public Home without a session, assert no Dashboard action exists and the
   existing Sign in and Register actions remain available. Confirm `/` does not
   redirect automatically.
7. If an expired-session fixture is tested, record the observed behavior of
   the existing auth guard separately from the public-route requirement; do not
   broaden this plan into an auth-policy rewrite.

## Commands

Run from `D:/DOCUMENTFPT/Github/pte-org/pte-web`:

```powershell
pnpm --filter tenant-web lint
pnpm --filter tenant-web exec tsc --noEmit
pnpm exec prettier --check `
  apps/tenant-web/features/auth/components/DashboardChrome.tsx `
  apps/tenant-web/lib/navigation.tsx `
  apps/tenant-web/features/public/components/PublicHeader.tsx
pnpm --filter tenant-web build
git diff --check -- apps/tenant-web
```

Use the existing Playwright skill for the browser matrix above. If a full
production build is blocked by stale generated `.next` files, record the exact
failure and use the repository's supported compile/build verification mode;
do not delete unrelated generated or user files as part of this plan.

## Quality and Testing State

- Quality: not evaluated.
- Testing: not started.
- Results must be filled in only after the commands and browser checks are
  actually run by the implementation workflow.

## Handoff criteria

- Every spec success criterion has a pass/fail result and evidence.
- Any failure is returned to implementation as a scoped fix; no silent
  relaxation of the session-preservation requirement.
- Final report explicitly states that vendor/admin was left unchanged and that
  the superseded logout/replace behavior was removed from tenant brand/Home
  navigation.

