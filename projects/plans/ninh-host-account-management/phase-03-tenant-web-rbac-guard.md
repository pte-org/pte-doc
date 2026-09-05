# Phase 3: tenant-web RBAC Route-Guard for /host/*

## Requirements

`tenant-web`'s `/host/*` routes (dashboard, roster import) currently have
no role gate at all — any authenticated user, regardless of role, can
reach them. `vendor-web` had the exact same gap once (fixed in the prior
plan's Phase 1); `tenant-web` never got the equivalent fix. Independent of
Phases 1–2 in this plan (no shared files) — included here because it was
found during this plan's own investigation, per the user's request to fold
it in rather than leave it as a dangling note.

## Design Constraints

- **Mirror `vendor-web`'s existing fix exactly** — this codebase already
  has the reference implementation one directory over:
  - `RequireAuth.tsx` (both apps) already accepts an optional
    `allowedRoles?: SessionRole[]` and does
    `isAuthorized={allowedRoles ? hasRole(allowedRoles) : true}` — this is
    **already correct** in `tenant-web` too. The bug is one layer up:
    `DashboardChrome` never passes the prop through, and doesn't even
    declare it.
  - `vendor-web/features/auth/components/DashboardChrome.tsx`:
    `DashboardChromeProps.allowedRoles: SessionRole[]` is **required, not
    optional** — its own comment explains why: a default here previously
    locked every caller to the same role set and silently broke whichever
    route didn't match it (QUAL-001 from the original Phase 1 quality
    gate). Copy that same "required, no default" shape into `tenant-web`,
    not an optional one — don't reintroduce the bug class the comment
    documents.
- **Role value: `["HOST_ADMIN", "HOST_AUTHOR"]`.** Originally scoped this
  to `HOST_ADMIN` only on the (wrong) assumption that nothing provisions a
  `HOST_AUTHOR` account today. The Phase 3 quality gate caught this: iam's
  `POST /users` already lets a `HOST_ADMIN` caller create `HOST_AUTHOR`
  users (`UserProvisioningHelper.HOST_ASSIGNABLE_ROLES`), and
  `HOST_AUTHOR` already has real permissions elsewhere in the backend
  (e.g. `authoring`'s `QuestionController`). `vendor-web`'s own analogous
  `/host` page already grants `HOST_ROLES = ["HOST_ADMIN", "HOST_AUTHOR"]`
  — excluding `HOST_AUTHOR` here would have silently locked out an
  account the backend already permissions, on every page in the app
  (`tenant-web` has no other route than `/host/dashboard`/`/host/roster`
  plus a root page that redirects to `/login`). Added a `HOST_ROLES`
  constant to `apps/tenant-web/features/auth/constants.ts`, mirroring
  `vendor-web`'s, instead of inlining the array at each call site.
- **Two call sites to update**, both already importing `DashboardChrome`:
  `app/(dashboard)/host/dashboard/page.tsx` and
  `app/(dashboard)/host/roster/page.tsx`. Grep for any other
  `<DashboardChrome` usage in `tenant-web` before assuming these are the
  only two — don't rely on memory of what was seen earlier in this
  session.

## Steps

1. `apps/tenant-web/features/auth/components/DashboardChrome.tsx`:
   - Add `allowedRoles: SessionRole[]` (required) to `DashboardChromeProps`,
     with the same explanatory comment `vendor-web`'s version has (why
     required-not-defaulted).
   - Import `SessionRole` from `@pte/ui`.
   - `export const DashboardChrome = (props: DashboardChromeProps) => (<RequireAuth allowedRoles={props.allowedRoles}><ChromeContent {...props} /></RequireAuth>)`.
2. Update both page call sites to pass `allowedRoles={["HOST_ADMIN"]}`.
3. `tsc --noEmit` on `tenant-web` — confirms every `<DashboardChrome>` call
   site was updated (the now-required prop makes a missed call site a
   compile error, which is the point).

## Success Criteria

- [ ] `tsc --noEmit` on `tenant-web` fails if any `<DashboardChrome>` call
      site is missing `allowedRoles` (proves the prop is genuinely
      required, not just documented as such).
- [ ] Logging in with a non-`HOST_ADMIN` role (e.g. `STUDENT`, or
      `PLATFORM_ADMIN`) and navigating to `/host/dashboard` redirects to
      `/login` instead of rendering the page.
- [ ] Logging in as `HOST_ADMIN` reaches `/host/dashboard` and
      `/host/roster` normally — no regression for the intended user.
- [ ] `eslint` and `next build` clean on `tenant-web`.

## Quality-and-Testing-State

- Frontend: `tsc --noEmit`, `eslint`, `next build` clean on `tenant-web`.
- Quality gate (`ck:quality`, `quality-reviewer` agent): first pass found
  **1 HIGH (QUAL-101)** — the `HOST_ADMIN`-only role list was justified by
  a factually wrong claim ("nothing provisions HOST_AUTHOR"); fixed by
  widening to `["HOST_ADMIN", "HOST_AUTHOR"]` via a new `HOST_ROLES`
  constant (see Design Constraints). Also 1 NOTED (no automated test for
  `RequireAuth`'s role-gating — pre-existing gap, not a regression, left
  for `ck:test`). Re-verified `tsc`/`eslint` clean after the fix.
  Re-review not re-run as a separate agent call — the fix is a mechanical
  widening of a literal array with no new logic, matching the exact
  pattern (`vendor-web`'s `HOST_ROLES`) the gate itself pointed to as
  correct.
- Manual E2E: not yet run — same deferred pattern as every phase.
