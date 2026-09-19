# Phase 01: Tenant navigation and public Home header

## Requirements

Implement the selected tenant-only direction from the spec and brainstorm.
This phase covers the code changes; verification evidence is recorded in
Phase 02.

Stories: P1 login redirect, P1 brand-to-Home, P1 authenticated Home Dashboard
action, P1 sidebar terminology, and P2 signed-out Home actions.

Acceptance criteria: the login route remains `/host/dashboard`; the sidebar
contains no Home item and retains `Overview` at `/host/dashboard`; the complete
brand area links to `/` without changing local session state; authenticated Home
shows one Dashboard action; signed-out Home keeps Sign in/Register and no
Dashboard action.

## Design Constraints

- Scope is limited to `pte-web/apps/tenant-web`.
- Do not edit `vendor-web/admin`, backend code, API-client contracts, shared
  session storage, favicon assets, or deployment configuration.
- In `DashboardChrome.tsx`, remove only the brand/sidebar session-clearing
  behavior. Keep the existing account-menu logout implementation intact.
- In `navigation.tsx`, remove only the Home nav entry and restore/retain the
  `Overview` label and `/host/dashboard` route. Preserve unrelated working-tree
  changes in the remaining nav sections.
- Brand navigation must be a regular `Link href="/"` without `clearToken`,
  `clearSession`, or `replace`.
- Public Home must stay renderable before and after session hydration. The
  header may read local storage through `useSessionManager`, but it must not
  fetch authentication state solely to render Dashboard.
- Render one semantic Dashboard action for an authenticated user and keep the
  existing signed-out actions. Do not duplicate Dashboard markup for responsive
  layouts.
- Do not auto-redirect an authenticated visitor from `/` to the dashboard.
- Preserve the existing login success redirect and `RequireAuth` protection.

Preflight: the tenant keeps route constants in `features/auth/constants.ts`,
client session hooks in `@pte/ui`, and explicit logout behavior in account
actions. Public `/` remains outside `RequireAuth`; this phase is limited to the
three planned tenant files and uses ordinary Next `Link` navigation.

## Dependency-ordered steps

1. Record the current dirty-worktree baseline for `tenant-web` and confirm
   there are no pre-existing edits to overwrite.
2. Update `lib/navigation.tsx`: remove `HomeIcon` and the Home item; leave the
   existing Overview route/label and all unrelated entries untouched.
3. Update `features/auth/components/DashboardChrome.tsx`: remove brand
   `clearToken`/`replace`, remove now-unused clear-on-navigate plumbing if no
   remaining tenant nav item uses it, and retain `clearToken` only in
   `HeaderActions.logout`.
4. Update `features/public/components/PublicHeader.tsx` (or a narrowly scoped
   client child): read `isReady` and `session` from `useSessionManager`; show a
   single Dashboard link to `AUTH_ROUTES.hostDashboard` when the session is
   available; preserve the public signed-out actions.
5. Review imports and type boundaries so the client-only session hook is not
   invoked from a server component. Keep `PublicShell` and `HomeView` public.
6. Re-check `LoginView.tsx`, `RequireAuth.tsx`, and the shared session manager
   to confirm no unrelated auth behavior changed.
7. Search the resulting tenant diff for the superseded patterns and confirm
   any remaining `clearToken` call is the explicit account-menu logout.

## Expected file impact

- Change: `pte-web/apps/tenant-web/lib/navigation.tsx`
- Change: `pte-web/apps/tenant-web/features/auth/components/DashboardChrome.tsx`
- Change: `pte-web/apps/tenant-web/features/public/components/PublicHeader.tsx`
- Verify only: `LoginView.tsx`, `RequireAuth.tsx`, `PublicShell.tsx`,
  `HomeView.tsx`, `features/auth/constants.ts`, and `packages/ui` session files

## Quality and Testing State

- Quality: approved by the Phase 01 quality gate; receipt issued at
  `quality/phase-01-tenant-navigation-and-public-header-receipt.json`.
- Testing: passed through tenant lint, TypeScript, Prettier, production build,
  and the ephemeral Playwright smoke matrix recorded in
  `tests/phase-01-tenant-navigation-and-public-header-test-report.json`.
- No new test framework or out-of-scope production file was added.

## Exit criteria

- The implementation matches FR-01 through FR-09.
- No brand/Home path clears or replaces the session.
- The next phase can run static checks and browser smoke tests without further
  design decisions.

