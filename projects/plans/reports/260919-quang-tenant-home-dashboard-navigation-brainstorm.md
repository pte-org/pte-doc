# Brainstorm: Tenant Home and Dashboard Navigation

**Date:** 2026-09-19

## Ideas Explored

### Direction A — Home sidebar item logs out

The first implementation kept `Home` in the sidebar and cleared the session when
the user clicked it. This was rejected: the public Home page must be reachable
without losing the authenticated state.

### Direction B — Brand link to public Home, session preserved

Remove `Home` from the authenticated sidebar. Make the full tenant brand area
(logo, `PTE Prep`, and `School Portal`) link to `/` without calling logout or
clearing local session state. Add a `Dashboard` action to the public Home header
for an already-authenticated user. This is the selected direction.

### Direction C — Automatically redirect an authenticated user from Home

An authenticated user could be sent immediately back to `/host/dashboard` when
opening `/`. This was rejected because Home is intentionally public and the user
must be able to remain there and choose the Dashboard button.

### Direction D — Apply the same change to vendor/admin

The admin brand area was initially considered as part of the same flow. The user
clarified that this request is tenant-only; `vendor-web/admin` has dashboard UI
only and is out of scope.

## User's Direction

- Scope is `tenant-web` only.
- Successful sign-in still goes directly to `/host/dashboard`.
- The Host sidebar removes `Home`.
- The existing `Overview` label remains `Overview` and continues to point to
  `/host/dashboard`; it must not be renamed to `Dashboard`.
- The tenant dashboard brand area (`logo + PTE Prep + School Portal`) navigates to
  the public `/` page without logging out.
- The authenticated session remains available after arriving at Home, including
  after a refresh.
- The public Home header shows a `Dashboard` button for an authenticated user;
  clicking it goes to `/host/dashboard`.
- Vendor/admin navigation is unchanged.

## Open Questions

None blocking. The public tenant route already exists at `/`, and the current
public header is the natural location for the conditional Dashboard action.

The earlier `clearToken` + `replace` behavior is superseded by this direction.
The implementation should preserve the session and use ordinary Home navigation;
no logout-on-Home behavior is part of this spec.

## Risks

1. A client-side public header must read the existing session without causing the
   public Home route to become protected or redirecting away from `/`.
2. The Dashboard action should not appear for signed-out visitors; the existing
   Sign in/Register actions must remain available.
3. Existing logout behavior in the dashboard account menu must remain unchanged;
   only brand-to-Home navigation changes.
