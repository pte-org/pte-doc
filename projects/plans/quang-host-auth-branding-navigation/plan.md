# Plan: Host Auth, Branding & Home Navigation

Status: Superseded — see `../quang-tenant-home-dashboard-navigation/spec.md`
Date: 2026-09-19
Timezone: Asia/Saigon
Target: `pte-web` (`tenant-web` and `vendor-web`)

> This earlier plan captured an incorrect interpretation that Home should clear
> the session. It is retained as history only. The tenant-only behavior in the
> new spec keeps the session, removes Home from the sidebar, preserves Overview,
> and adds Dashboard to the public Home header.

## Overview

This plan records the work completed in this coding session around the Host sign-in
experience, product branding, and navigation between the public Home page and the
authenticated dashboard.

The intended Host behavior is:

- Sign-in continues to enter the authenticated dashboard.
- The sidebar keeps a `Home` item.
- Selecting `Home` clears the client session and goes to `/`.
- Selecting the logo or `PTE Prep / School Portal` text does the same.
- `Overview` is presented as `Dashboard` and points to `/host/dashboard`.
- The supplied `logo.png` is used by both apps wherever the previous default mark
  was rendered.

## Scope completed

### 1. Host navigation and session behavior

- Kept `Home` in the Host sidebar instead of removing it.
- Added a separate `Dashboard` navigation item for `/host/dashboard`.
- Made the Home route exact-match active, so `/` is not highlighted on every
  authenticated route.
- Made the tenant sidebar logo and adjacent brand text a link to `/`.
- Added `clearSessionOnNavigate` to navigation metadata and used it for Home.
- Home and the sidebar brand call the existing `useTokenManager().clearToken()`
  path, which removes the client session before navigation.
- Used `replace` for these exits so the authenticated dashboard is not retained as
  the immediate browser-history destination.

Primary files:

- `pte-web/apps/tenant-web/features/auth/components/DashboardChrome.tsx`
- `pte-web/apps/tenant-web/lib/navigation.tsx`

### 2. Logo rollout

- Used the source asset supplied at `D:\DOCUMENTFPT\Github\pte-org\logo.png`.
- Added/verified the asset at both public roots:
  - `pte-web/apps/tenant-web/public/logo.png`
  - `pte-web/apps/vendor-web/public/logo.png`
- Updated/verified the tenant and vendor dashboard brand areas to use `/logo.png`.
- Updated/verified both login brand panels to use `/logo.png` instead of the
  default graduation-cap mark.
- Updated the vendor login form's top brand area to use `/logo.png`.
- Searched for remaining `GradCapIcon` usage. The remaining references are shared
  exports in `packages/ui`; no rendered login/dashboard usage remained, so the
  shared export was left intact to avoid an unrelated API break.

Relevant files:

- `pte-web/apps/tenant-web/features/auth/components/_AuthBrandPanel.tsx`
- `pte-web/apps/tenant-web/features/auth/components/LoginView.tsx`
- `pte-web/apps/tenant-web/features/auth/components/DashboardChrome.tsx`
- `pte-web/apps/tenant-web/public/logo.png`
- `pte-web/apps/vendor-web/features/auth/components/_AuthBrandPanel.tsx`
- `pte-web/apps/vendor-web/features/auth/components/LoginView.tsx`
- `pte-web/apps/vendor-web/features/auth/components/DashboardChrome.tsx`
- `pte-web/apps/vendor-web/public/logo.png`

### 3. Production/domain investigation

The deployment runbook maps the public hosts as follows:

| Host | Application |
|---|---|
| `https://pte-tenant.duckdns.org` | `tenant-web` + API |
| `https://pte-admin.duckdns.org` | `vendor-web` + API |

The production asset checks found:

- Tenant host `/logo.png`: HTTP 200, length `858356` bytes.
- Admin host `/logo.png`: HTTP 404 at the time of checking, which explains why
  the production admin screen still showed the fallback/default mark.
- The vendor public asset was added locally. Production still requires the normal
  deployment flow to publish it.

The production workflow deploys from `main`; no production push or deployment was
performed by this session.

### 4. Supplied account login check

The requested tenant-domain login was attempted with the supplied username. The
password was tried with and without the trailing space represented by `&#x20;`.
Both direct login requests returned:

```text
HTTP 401
{"success":false,"data":null,"message":"INVALID_LOGIN"}
```

The credential itself was not written to the repository or saved in these plan
files.

## Verification state

| Check | Result | Notes |
|---|---|---|
| Tenant lint | Pass | Touched tenant files linted successfully. |
| Vendor lint | Pass | Touched vendor files linted successfully. |
| Prettier checks | Pass | Touched frontend files formatted successfully. |
| Tenant Next compile mode | Pass | `next build --experimental-build-mode compile`; dashboard/login/home routes compiled. |
| Vendor Next compile mode | Pass | `next build --experimental-build-mode compile`. |
| Local Host navigation test | Pass | Playwright with a fake `HOST_ADMIN` session verified Dashboard link, brand-to-Home, Home-to-Home, and session clearing. |
| Production tenant logo endpoint | Pass | HTTP 200. |
| Production admin logo endpoint | Not yet | HTTP 404 before deployment of the vendor asset. |
| Real production login | Blocked | API returned `INVALID_LOGIN`/401 for the supplied account. |

## Known gaps and follow-up

- Deploy the vendor asset to production through the existing `main` deployment
  workflow, then recheck `https://pte-admin.duckdns.org/logo.png`.
- If browser-tab branding is also required, update the two app favicon assets;
  this session focused on dashboard and login logos.
- Re-run a real end-to-end Host login after a valid tenant account/password is
  available.
- The normal full Next build previously encountered a stale generated `.next`
  validator reference to a missing `/application-status/page.js`; the explicit
  compile-mode builds passed and were used for this session's verification.

## Worktree hygiene

The repository already contained unrelated changes in commercialization,
question-template, score-template, and UI files. They were preserved and are not
included as part of this plan's implementation scope.
