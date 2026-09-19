# Plan: Tenant Home and Dashboard Navigation

**Status:** Draft — implementation not started  
**Date:** 2026-09-19  
**Mode:** Hard  
**Testing mode:** Default testing, no `--tdd`  
**Scope:** `pte-web/apps/tenant-web` only

## Objective

Implement the approved tenant-only navigation flow:

- A successful tenant login continues to land on `/host/dashboard`.
- The authenticated Host sidebar removes `Home`.
- The existing `Overview` item remains named `Overview` and points to
  `/host/dashboard`.
- The complete tenant dashboard brand area—logo, `PTE Prep`, and
  `School Portal`—links to public `/` without logout or session mutation.
- Public Home remains public for both signed-in and signed-out visitors.
- An authenticated visitor sees one `Dashboard` action in the public Home
  header; clicking it navigates to `/host/dashboard` while preserving the
  session.
- Signed-out visitors retain the existing Sign in and Register actions.
- `vendor-web/admin` is unchanged.

## Current-state findings

Read-only inspection found the implementation that must be superseded:

- `features/auth/components/DashboardChrome.tsx` currently calls
  `clearToken` from `SidebarBrand`, uses `replace`, and supports a
  `clearSessionOnNavigate` sidebar path.
- `lib/navigation.tsx` currently renders a `Home` item with
  `clearSessionOnNavigate: true` and labels the dashboard route `Dashboard`.
- `features/public/components/PublicHeader.tsx` currently has no session-aware
  Dashboard action and is not a client component.
- `features/auth/components/LoginView.tsx` already routes successful login to
  `AUTH_ROUTES.hostDashboard`; preserve and verify that behavior.
- The shared session manager reads `pte.session` from local storage after
  hydration. It must remain the source of truth; no new network request is
  needed for Home header rendering.

## Superseded behavior

The earlier `clearToken` + `replace` implementation is explicitly superseded.
The implementation must remove that behavior from Home/brand navigation. Do not
clear `pte.session`, call `clearToken`, or use logout-specific `replace` when
the tenant brand goes to `/`. The normal account-menu logout path remains
unchanged.

## Phase order

1. **Phase 01 — Tenant navigation and public Home header:** make the code
   changes in dependency order: sidebar/brand semantics, then the public header
   session action, while preserving the existing login redirect and auth guard.
2. **Phase 02 — Verification and handoff:** run static checks and browser
   smoke checks for signed-in, signed-out, refresh, navigation, and scope
   isolation.

Phase 02 depends on Phase 01. No backend, API-client, shared-session-storage,
or vendor/admin implementation phase is required.

## Story and acceptance-criteria traceability

| Phase | Stories / acceptance criteria covered |
|---|---|
| Phase 01 | P1 login redirect; P1 brand-to-Home with unchanged session; P1 authenticated Home Dashboard action; P1 sidebar removes Home and preserves Overview; P2 signed-out actions; FR-01 through FR-09 except final verification evidence |
| Phase 02 | All success criteria, including refresh/session preservation, expired/absent-session behavior, and zero intentional vendor/admin changes |

## Likely files

### Files expected to change

- `pte-web/apps/tenant-web/features/auth/components/DashboardChrome.tsx`
  - Keep `clearToken` only for the existing account-menu logout.
  - Make `SidebarBrand` a normal `Link` to `/` with browser history
    semantics; remove brand `onClick={clearToken}` and `replace`.
  - Remove the sidebar-only session-clearing navigation mechanism if it is no
    longer used after removing `Home`.
- `pte-web/apps/tenant-web/lib/navigation.tsx`
  - Remove the `Home` item and its `HomeIcon` import.
  - Restore/retain `Overview` → `/host/dashboard` with the existing dashboard
    icon and preserve unrelated navigation edits.
- `pte-web/apps/tenant-web/features/public/components/PublicHeader.tsx`
  - Convert to a client component or delegate the client-only action to a
    small client component.
  - Read `useSessionManager()` after hydration and render one Dashboard link
    only when the existing session is present.
  - Preserve public access, existing Sign in/Register behavior for signed-out
    users, and ordinary link navigation without clearing the session.

### Files to verify, not change unless implementation exposes a real defect

- `pte-web/apps/tenant-web/features/auth/components/LoginView.tsx`
- `pte-web/apps/tenant-web/features/auth/components/RequireAuth.tsx`
- `pte-web/apps/tenant-web/features/public/components/PublicShell.tsx`
- `pte-web/apps/tenant-web/features/public/components/HomeView.tsx`
- `pte-web/apps/tenant-web/features/auth/constants.ts`
- `pte-web/packages/ui/src/hooks/useSessionManager.ts`
- `pte-web/packages/ui/src/hooks/sessionStorage.ts`
- `pte-web/packages/ui/src/components/ProtectedRoute.tsx`

### Explicitly excluded

- All `pte-web/apps/vendor-web/**` routes, labels, brand behavior, and assets.
- `pte-api/**`, API contracts, database migrations, and deployment config.
- Favicon changes.
- New automatic redirect from `/` to the dashboard.
- A new logout flow or changes to the account-menu logout.

## Design decisions

- Use the existing `useSessionManager` hydration state and local session as the
  header signal. Do not add a request just to decide whether Dashboard is
  visible.
- Keep `/` public. The Home page must render while signed in and signed out;
  only `/host/dashboard` remains protected by the existing `RequireAuth` flow.
- Use ordinary `Link` navigation for brand and Dashboard actions. Do not use
  `replace` for the brand-to-Home path because the spec requires normal browser
  history behavior.
- Keep the login success redirect as `router.replace('/host/dashboard')` (or
  its existing `AUTH_ROUTES.hostDashboard` constant); this is distinct from
  brand navigation and must not be changed.
- Avoid duplicating a Dashboard control across desktop/mobile markup. The
  authenticated Home header should expose one semantic Dashboard action.

## Risks and mitigations

- **Hydration flash:** session state is unavailable during the first render.
  Gate the conditional action on the manager's ready state and verify that the
  page does not redirect or become protected while hydration completes.
- **Expired local sessions:** the current shared session model exposes
  `expiresAt`, while the existing auth guard primarily checks token presence.
  Use the existing session semantics for this feature, document any observed
  expiry behavior during verification, and do not silently introduce a new
  auth policy in the public header.
- **Accidental logout regression:** search the final tenant diff for
  `clearToken`, `clearSession`, and `replace` around brand/Home navigation;
  `clearToken` must remain only in intentional logout code.
- **Dirty worktree contamination:** establish the changed-file baseline before
  implementation and review only new tenant changes. Preserve unrelated edits
  in `navigation.tsx` and elsewhere.
- **Scope leakage:** inspect the final diff for `vendor-web`, API, and shared
  storage changes; reject any changes not required by this tenant flow.

## Verification command set

Run from `D:/DOCUMENTFPT/Github/pte-org/pte-web` after implementation:

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

Browser smoke verification should cover:

1. A successful tenant login reaches `/host/dashboard`.
2. Dashboard renders no `Home` sidebar item and exactly one `Overview` link
   with `/host/dashboard`.
3. Clicking the logo, `PTE Prep`, and `School Portal` reaches `/` and leaves
   the pre-click `pte.session` value unchanged.
4. Refreshing `/` while signed in stays on `/` and keeps the session.
5. Signed-in Home shows exactly one Dashboard action; clicking it reaches
   `/host/dashboard` and preserves the session.
6. Signed-out Home shows no Dashboard action and retains Sign in/Register.
7. A missing or expired fixture does not make `/` redirect automatically;
   protected dashboard access continues to follow the existing auth guard.
8. No intentional changes exist under `apps/vendor-web`.

Because the tenant app currently has no colocated unit/e2e test files, use the
existing Playwright skill or an ephemeral browser script for these checks
unless implementation discovers an established test harness. Do not add a new
test framework solely for this small navigation change.

## Handoff

Ready to implement with:

```text
/ck:cook --hard pte-doc/projects/plans/quang-tenant-home-dashboard-navigation/plan.md
```

