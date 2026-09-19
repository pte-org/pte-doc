# Phase 1: Host Navigation, Session Exit & Branding

## Requirements

1. A Host user must be able to reach the public Home page from the dashboard.
2. Leaving the dashboard through Home must not leave the client in a logged-in
   state.
3. The sidebar must retain Home and also expose a clear Dashboard destination.
4. Clicking the sidebar logo or the adjacent product name must go to Home and
   clear the client session.
5. Both tenant and vendor login surfaces must use the supplied PTE Prep logo.

## Design constraints

- Reuse the existing `useTokenManager().clearToken()` behavior rather than
  introducing a second logout/session implementation.
- Keep the public Home route at `/` and the authenticated Host dashboard at
  `/host/dashboard`.
- Scope the logout-on-Home behavior to the tenant Host navigation. The vendor
  application does not have the same public Host Home flow.
- Keep the shared `GradCapIcon` export available unless a repository-wide API
  cleanup is explicitly requested.
- Do not store production credentials in source, logs, or plan files.

## Implementation record

### Navigation

- `DashboardChrome` now accepts `clearSessionOnNavigate` on a `NavItem`.
- The tenant `Home` item sets that flag to `true`.
- `SidebarBrand` is rendered as a `next/link` to `/`, with `replace` and an
  `onClick` handler that clears the token/session.
- The Home navigation link uses the same clear-and-replace behavior.
- `isActive()` treats `/` as an exact route and all other items as prefix routes.
- The former `Overview` label is now `Dashboard` and targets `/host/dashboard`.

### Branding

- The supplied square logo was used as the public `/logo.png` asset in both apps.
- Tenant and vendor `_AuthBrandPanel` components render the image in the login
  illustration card.
- Tenant and vendor login form brand areas render the same image.
- Tenant and vendor dashboard brand areas render the same image.
- A repository search confirmed that the old graduation-cap component is not
  rendered by the login/dashboard surfaces covered by this change.

## Acceptance criteria

- [x] Home remains visible in the Host sidebar.
- [x] Dashboard is visible and routes to `/host/dashboard`.
- [x] Home navigation clears the local session.
- [x] Logo/text navigation clears the local session.
- [x] Root Home is not shown as active on dashboard subroutes.
- [x] Both login apps reference `/logo.png`.
- [x] Both dashboard brand areas reference `/logo.png`.
- [x] The vendor public logo asset exists locally.
- [x] Local browser verification covers both Home exit paths.
- [ ] Production vendor logo endpoint returns 200 after deployment.
- [ ] Real production account login succeeds.

## Quality and testing state

The completed checks were:

- lint and Prettier checks for the touched tenant and vendor frontend files;
- tenant and vendor Next compile-mode builds;
- Playwright local smoke test with a deterministic fake `HOST_ADMIN` session;
- production HTTP checks for the two logo endpoints;
- direct production login request using the supplied account, which returned 401.

The Playwright smoke test verified:

| Action | Expected result | Result |
|---|---|---|
| Open dashboard | Dashboard route renders | Pass |
| Click brand logo/text | Navigate to `/`, clear session | Pass |
| Click sidebar Home | Navigate to `/`, clear session | Pass |
| Inspect Dashboard link | `href=/host/dashboard` | Pass |

## Deferred items

- Production deployment of `apps/vendor-web/public/logo.png`.
- Browser favicon replacement, if the requirement includes the tab icon.
- Live login and post-login verification with a valid account.
