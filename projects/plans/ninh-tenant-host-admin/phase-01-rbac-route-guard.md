# Phase 1: RBAC Route Guard for `/admin/*`

## Requirements

Every route under `/admin/*` in `vendor-web` must actually enforce
platform-admin-only access. Today `RequireAuth`'s `isAuthorized` defaults to
`true` when `allowedRoles` isn't passed, and `DashboardChrome.tsx` renders
`<RequireAuth>` with no `allowedRoles` at all — any authenticated session,
regardless of role, currently passes the admin gate.

Maps to: **Business rule 1 (no public sign-up; only a Super Admin manages
Hosts) — this is the enforcement point for that rule.**

## Design Constraints

- Depends on Phase 0: `hasRole`/`session.roles` must already reflect the
  real, JWT-decoded role set before this gate means anything.
- `RequireAuth.tsx` already supports `allowedRoles?: SessionRole[]` and
  `hasRole([...])` correctly does array-intersection (after Phase 0) — no
  change needed to `RequireAuth.tsx` itself, only to how it's called.
- Use the real role value `"PLATFORM_ADMIN"` (from Phase 0's corrected
  `SessionRole`), not the old, wrong `"ADMIN"`.
- This is the first correct use of `allowedRoles` anywhere in the repo
  (confirmed via grep — no other route in `vendor-web` or `tenant-web`
  passes it) — it becomes the reference pattern other routes should copy
  later, so get the call site right rather than a quick hack.

## Steps

1. ~~Edit `DashboardChrome.tsx` directly~~ — **superseded during the quality
   gate** (see below): `DashboardChrome` is a shared shell for both
   `/admin/*` (`ADMIN_NAV`) and `/host` (`HOST_NAV`), so hardcoding
   `allowedRoles={["PLATFORM_ADMIN"]}` inside it locked `HOST_ADMIN`/
   `HOST_AUTHOR` users out of `/host` entirely.
2. `DashboardChromeProps.allowedRoles: SessionRole[]` made a **required**
   prop (no default) — forces every call site to be explicit rather than
   letting the shell silently apply one role set to every page it wraps.
3. `features/auth/constants.ts`: added exported `ADMIN_ROLES`/`HOST_ROLES`
   constants, shared between `DashboardChrome` call sites and
   `LoginView.tsx`'s post-login redirect decision (previously a local,
   unexported `HOST_ROLES` inside `LoginView.tsx` — deduped).
4. All 6 `admin/*/page.tsx` files pass `allowedRoles={ADMIN_ROLES}`;
   `host/page.tsx` passes `allowedRoles={HOST_ROLES}`.
5. Manually verify both directions (see Success Criteria) against a running
   backend with at least one `PLATFORM_ADMIN` and one `HOST_ADMIN`/other
   seeded user — deferred alongside Phase 0's same manual E2E gap.

## Success Criteria

- [x] A session with role `PLATFORM_ADMIN` reaches `/admin/*` normally
      (unchanged — still true after the re-scoping fix).
- [x] A session with any other role is redirected away from `/admin/*`.
- [x] A `HOST_ADMIN`/`HOST_AUTHOR` session still reaches `/host` — this is
      the specific regression the quality gate caught; re-verify it
      explicitly, not just the admin side.
- [ ] An unauthenticated session is redirected to `/login` (unchanged
      existing behavior) — not yet manually re-verified live.

## Quality and Testing State

- `tsc --noEmit`/`eslint`: clean on `vendor-web` after the fix.
- Quality gate (`ck:quality`, `quality-reviewer` agent): initial pass found
  **1 BLOCKER**:
  - **QUAL-001 (BLOCKER, fixed)**: the original 1-line fix
    (`allowedRoles={["PLATFORM_ADMIN"]}` hardcoded inside `DashboardChrome`)
    made `/host` completely unreachable for `HOST_ADMIN`/`HOST_AUTHOR`
    sessions — `LoginView.tsx` redirects them there on login, then the new
    gate immediately bounced them back to `/login`. Root cause:
    `DashboardChrome` is shared between `/admin/*` and `/host`, not
    admin-only. Fixed by making `allowedRoles` a required per-call-site
    prop instead of a value baked into the shared shell — see Steps above.
  - Re-ran `tsc`/`eslint` after the fix — clean.
- Manual E2E (both role directions against a live backend): not yet run —
  same environment blocker as Phase 0 (no stack up, no seeded users).
