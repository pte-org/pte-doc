# Spec: Tenant Home and Dashboard Navigation

**Date:** 2026-09-19
**Status:** Ready

---

## Problem Statement

The tenant dashboard currently treats Home navigation as a logout path and has
also changed the intended `Overview` navigation label. Hosts need to visit the
public Home page while retaining their session, then explicitly return to the
dashboard through a header button.

---

## User Stories

- **[P1]** As a Host user, I want successful sign-in to open the tenant dashboard
  so that I can start managing my organization immediately.
  Accepted when: a successful tenant login navigates to `/host/dashboard`.

- **[P1]** As a Host user, I want the dashboard brand area to open public Home
  without logging me out so that I can view public information and return later.
  Accepted when: clicking the logo, `PTE Prep`, or `School Portal` navigates to
  `/`, and the existing client session remains unchanged.

- **[P1]** As an authenticated visitor on public Home, I want a Dashboard button
  in the header so that I can explicitly return to the Host dashboard.
  Accepted when: the button is visible for an active tenant session and navigates
  to `/host/dashboard` when clicked.

- **[P1]** As a Host user, I want the sidebar to keep the existing Overview item
  so that the dashboard navigation terminology does not change unexpectedly.
  Accepted when: no Home item is rendered in the Host sidebar, `Overview` remains
  visible, and its href is `/host/dashboard`.

- **[P2]** As a signed-out visitor, I want the public Home header to retain the
  existing sign-in and registration actions so that I can authenticate normally.
  Accepted when: the Dashboard action is absent without a valid session and the
  existing Sign in/Register actions remain available.

- **[P3]** _(out of scope — vendor/admin dashboard branding and navigation are
  unchanged.)_

---

## Functional Requirements

1. **FR-01:** Preserve the existing successful tenant sign-in redirect to
   `/host/dashboard`.
2. **FR-02:** Remove the `Home` item from the tenant Host sidebar.
3. **FR-03:** Preserve the `Overview` label and route it to
   `/host/dashboard`; do not rename it to `Dashboard`.
4. **FR-04:** Make the complete tenant dashboard brand area—logo, `PTE Prep`,
   and `School Portal`—a link to `/`.
5. **FR-05:** FR-04 must not call `clearToken`, remove `aptis.session`, or invoke
   any other logout behavior.
6. **FR-06:** The public tenant Home header must detect whether a valid local
   session exists and show a `Dashboard` button only for an authenticated user.
7. **FR-07:** Clicking the Home header's Dashboard button must navigate to
   `/host/dashboard` without modifying the session.
8. **FR-08:** If a session is absent or expired, existing auth protection may
   redirect the user to `/login`; this must not turn public `/` into a protected
   route.
9. **FR-09:** Do not change `vendor-web/admin` routes, labels, or brand behavior
   as part of this feature.

---

## Non-Functional Requirements

- **Performance:** The Home header may read the existing client session but must
  not add a new network request solely to decide whether to render Dashboard.
- **Security:** Dashboard remains protected by the existing `RequireAuth` guard;
  hiding the button must not be treated as authorization.
- **Availability:** Public `/` must render for signed-in and signed-out users.
- **Navigation:** Brand-to-Home navigation must preserve the normal browser
  history behavior; no logout-specific `replace` navigation is required.
- **Scope:** Changes are limited to `tenant-web` and its shared components only
  where required by the tenant implementation.

---

## Success Criteria

- [ ] Successful tenant login reaches `/host/dashboard` in 1 navigation.
- [ ] Host sidebar renders 0 `Home` items and 1 `Overview` item pointing to
  `/host/dashboard`.
- [ ] Clicking each of the three tenant brand targets (logo, `PTE Prep`,
  `School Portal`) reaches `/` with the pre-click session value unchanged.
- [ ] Refreshing `/` while authenticated leaves the user on `/` and keeps the
  session available.
- [ ] Authenticated Home shows exactly 1 Dashboard action in the header, and
  clicking it reaches `/host/dashboard`.
- [ ] Signed-out Home shows 0 Dashboard actions and retains the existing Sign in
  and Register actions.
- [ ] Vendor/admin dashboard routes and labels have 0 intentional changes from
  this feature.

---

## Out of Scope

- Logging out when clicking Home, the tenant brand area, or the public Home logo.
- Automatically redirecting an authenticated user from `/` to the dashboard.
- Renaming `Overview` to `Dashboard` in the sidebar.
- Adding or changing a public Home page for `vendor-web/admin`.
- Changing vendor/admin dashboard navigation.
- Changing favicon assets or production deployment configuration.

---

## Assumptions

- The tenant public Home route remains `/` and is rendered by the existing
  `HomeView`/`PublicShell` flow.
- The existing client session store is the source of truth for determining
  whether the Home header should show Dashboard.
- The existing tenant `RequireAuth` guard continues to protect
  `/host/dashboard`.
- The normal sign-out action in the dashboard account menu remains unchanged.

---

## [NEEDS CLARIFICATION]

None.
