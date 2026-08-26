# Plan: Host Login Account Management (Create + Admin-Assisted Reset)

Status: 🟢 All 3 phases complete (code + quality gates); live E2E manual
verification against a running stack still deferred to the user
Date: 2026-08-26
Mode: Fast
Created by: Ninh
Target platform: `pte-api` service `iam` + `pte-web` app `vendor-web`

## Overview

Discovered while manually testing the just-completed Tenant/Host Admin plan:
onboarding a Tenant (`POST /tenants`) only creates the Tenant row in
`services/admin` — it never creates a login account in `iam`. A freshly
onboarded Host cannot log in at all today. Separately, there is zero
password-reset capability anywhere in `iam`, so if a Host forgets their
password there is no way — self-service or admin-assisted — to recover it.

Investigation found the creation half is mostly already built:
`POST /users` (`UserController`, `iam`) already creates a `User` +
`LoginHash` for an arbitrary `tenantId` when called by a `PLATFORM_ADMIN`
caller (`UserProvisioningHelper.resolveTargetTenant`). It has just never
been wired to any `vendor-web` UI. The reset half does not exist at all —
no endpoint, no service method.

**Decisions (gathered via AskUserQuestion before planning):**
1. Account creation stays admin-initiated (not automatic on tenant
   onboarding) via a "Create Login" action. Placement: inside
   `TenantDetailView` (the per-tenant page, next to Organizations/
   Branding) — **not** a new standalone "Users" page. The user confirmed
   this after being shown that `vendor-web`'s nav has no Users/Accounts
   entry today; adding a whole new page + nav item was rejected as more
   than this needs. Tenant is therefore always implied by which
   `TenantDetailView` is open — no tenant picker/dropdown anywhere.
2. Password reset is admin-direct: Admin types a new password for the
   Host's account on the spot; no email/SMTP flow. Confirmed explicitly
   over the alternative (a self-service "forgot password" email-link
   flow), which was rejected as more infrastructure than this warrants —
   `notification` service today only builds a local email directory from
   `UserCreated`, it does not send mail for anything.

**A real backend gap this surfaced**, not part of this plan's scope but
recorded for later: `UserController`'s existing `GET /users` scopes by
`caller.tenantId()`, which is always `null` for a `PLATFORM_ADMIN` caller
(a platform user has no tenant of their own) — so that endpoint is
currently unusable by an Admin to look up any tenant's users at all. Phase
1 below adds a separate, purpose-built lookup rather than trying to widen
that endpoint's existing (tenant-caller-facing) semantics.

**Also discovered, folded in as Phase 3 (user confirmed):** `tenant-web`'s
`RequireAuth` is invoked with no `allowedRoles` at all
(`features/auth/components/DashboardChrome.tsx`), meaning `/host/*` routes
currently have no role gate — any authenticated user of any role can reach
them. This mirrors the exact class of bug the original plan's Phase 1
fixed for `vendor-web` (`RequireAuth`/`DashboardChromeProps` already
support `allowedRoles`; `vendor-web`'s version already wires it through —
`tenant-web`'s never got the equivalent fix). Independent of Phases 1–2
(no shared files), included here rather than a separate plan since it was
found during this plan's own investigation.

## Phases

- [x] Phase 1: Backend — `POST /users/{publicId}/reset-password`
      (platform-admin-only) + `GET /users/by-tenant/{tenantId}`
      (platform-admin-only lookup, used by the FE to know whether a
      tenant already has a login account). [quality: approved (0
      findings); testing: 9/9 iam tests passing]
- [x] Phase 2: Frontend — "Login Account" section in `TenantDetailView`:
      create-login form when none exists, show email + status and a
      Reset Password action when one does. [quality: approved after 1
      MEDIUM fixed (query-cache-key namespace collision — see phase
      file); testing: tsc+eslint+build clean]
- [x] Phase 3: Frontend — close `tenant-web`'s missing RBAC route-guard on
      `/host/*` by wiring `allowedRoles` through `DashboardChrome`,
      mirroring `vendor-web`'s existing fix exactly. [quality: approved
      after 1 HIGH fixed (role list widened to `["HOST_ADMIN",
      "HOST_AUTHOR"]` — see phase file); testing: tsc+eslint+build clean]

## Risks

- **LOW: Single-HOST_ADMIN-per-tenant assumption in the UI.** Backend
  stays general (`GET /users/by-tenant/{id}` returns a list), but Phase 2's
  UI only surfaces the first result. If a tenant ever ends up with more
  than one `HOST_ADMIN` user, the UI won't show the others. Acceptable for
  now — nothing in this plan creates that situation, and today's flow only
  ever creates one.
- **LOW: Admin-typed password never leaves this admin's screen except by
  the admin manually relaying it to the Host.** No email/SMTP means there
  is no delivery channel this plan builds — this is the explicitly chosen
  tradeoff from the AskUserQuestion above, not an oversight.
