# Plan: B2B Tenant/Host Admin — Auth Contract Fix, RBAC, Org Hierarchy, Quota Audit Trail

Status: 🟡 In Progress
Date: 2026-08-25
Mode: Hard
Created by: Ninh
Target platform: Web (`pte-api` service `admin` + `pte-web` apps `vendor-web`/`tenant-web`)

## Overview

Fixes the Super-Admin "register a Host" flow end to end. A prior code
review (no code changes) found 5 real gaps: no real RBAC on `vendor-web`'s
`/admin/*` routes, the suspend action is a stub, two competing Host-creation
UIs exist, there's no Organization (1 Host → N branches) hierarchy or
white-label (logo/color) support, and Package/Quota is two mutable columns
with no allocation history. While verifying the plan before implementation,
a materially bigger foundational bug surfaced: `vendor-web`'s (and
`tenant-web`'s) entire auth flow calls the wrong gateway paths and expects a
response shape the backend has never returned — nothing in this app has
ever successfully authenticated against the real `pte-api`. That fix was
folded into Phase 0 (approved by the user) since RBAC is meaningless without
a working login. This plan closes all 6 gaps in dependency order: fix the
foundation first (Phase 0), gate access (Phase 1), then layer features that
build on a now-trustworthy session/tenant model (Phases 2–5).

## Phases

- [x] Phase 0: Auth + API Contract Fix — correct the 4 request modules that
      have a real backend counterpart (`auth`, `admin/hosts`, `tenant`,
      `question`) from a fictitious `/api/v1/*` prefix to the real
      gateway+context-path route; replace `AuthResponse` with iam's actual
      `TokenResponse` shape; decode `roles`/`tenant_id` from the JWT instead
      of reading non-existent response fields; add a single-flight
      refresh-on-401 interceptor to `packages/api-client`'s `client.ts`.
      [quality: approved (1 BLOCKER fixed — login body sent a fictitious
      `credential` field instead of the real backend's `email`; 1 HIGH
      fixed — empty-roles session didn't fail closed; 2 MEDIUM fixed —
      undocumented fictitious endpoint, duplicated apiClient.ts across
      apps); testing: tsc+eslint clean on all 4 packages/apps; **live
      login/refresh against a running backend not yet executed** — no
      stack up, no seeded PLATFORM_ADMIN user in this environment, carried
      forward as a residual gap, not silently dropped]
- [x] Phase 1: RBAC Route Guard for `/admin/*` — `allowedRoles` made a
      required per-call-site prop on `DashboardChrome` (not hardcoded
      inside it), first correct use of this prop anywhere in the repo.
      [quality: approved (1 BLOCKER fixed — the first version of this fix
      hardcoded `PLATFORM_ADMIN` inside the shared `DashboardChrome` shell,
      which also wraps `/host`, locking out every HOST_ADMIN/HOST_AUTHOR
      user); testing: tsc+eslint clean; live E2E not yet run, same
      deferred gap as Phase 0]
- [x] Phase 2: Suspend/Reactivate — real `suspend`/`reactivate` end to end
      (admin service + iam's tenant-registry projection), plus a scope
      expansion approved mid-phase: the entire Tenant/Host create+list
      contract between `vendor-web` and `services/admin` turned out to be
      fictitious (wrong request/response bodies, not just wrong paths —
      Phase 0 only fixed paths for this endpoint, not body shape), so it
      was fixed to match the real 4-field backend contract, pulling forward
      part of Phase 3's consolidation. [quality: approved (1 MEDIUM fixed —
      suspend/reactivate silently swallowed mutation errors with no visible
      feedback, unlike the create-tenant flow in the same file); testing:
      13 new backend tests (admin 8/8, iam 5/5 — both services' first-ever
      test suites) all passing; tsc+eslint+next build clean; live E2E not
      yet run, same deferred gap as Phase 0/1]
- [x] Phase 3: Consolidate Host-Creation Flows — deleted the orphaned
      `admin/hosts` route + `HostCreationForm` + the now-fully-dead
      `admin/hosts.ts`/`CreateHostRequest`/`HostResponse` api-client
      module; kept the linked `admin/tenants` flow (real end to end since
      Phase 2). [quality: approved, 0 findings; testing: next build clean
      (11 routes, was 12), tsc+eslint clean; live E2E not yet run, same
      deferred gap as prior phases]
- [ ] Phase 4: Organization Hierarchy + White-Label — new `Organization`
      entity (1 Tenant → N), `logoUrl`/`primaryColor` on `Tenant`, N+1-safe
      list endpoint, secure logo upload validation. [quality: pending;
      testing: pending]
- [ ] Phase 5: Package/Quota Audit Trail — new `QuotaTransaction` ledger
      entity (`actionType` enum ready for a future deduct-on-exam-start
      flow), optimistic locking (`@Version`) on `Tenant`'s cached counters,
      wires the existing `LicensingView` UI shell to real data.
      [quality: pending; testing: pending]

## Research Summary

Decisions below were established via direct codebase/backend inspection
(not re-derived here):

1. **The `/api/v1/*` prefix bug is real and was verified end to end, not
   assumed**: gateway (`pte-api/gateway/.../application.yml`) routes
   `/api/admin/**`→admin, `/api/iam/**`→iam; each service's own
   `server.servlet.context-path` (`/api/admin`, `/api/iam`, `/api/authoring`,
   ...) plus its controller's `@RequestMapping` gives the real path (e.g.
   `/api/admin/tenants`, `/api/iam/auth/login`). `packages/api-client`'s
   request modules instead hardcode `/api/v1/...` — every one of these
   requests 404s through the gateway today. `baseUrl` at runtime is
   `http://localhost:8080` (bare gateway root, confirmed via
   `apps/vendor-web/features/auth/constants.ts`), so there is no compensating
   prefix anywhere else in the chain.
2. **Only 4 of the "10 broken-prefix files" are in this plan's scope**:
   `auth`, `admin/hosts`, `tenant`, `question` map to real backend
   controllers and just need their prefix corrected. The other 5
   (`host/imports.ts`, `host/studentImport.ts`, `host/students.ts`,
   `asset/index.ts`, `account/index.ts`) call features with **no matching
   backend controller anywhere** (verified by grepping every
   `services/*/controller/*.java` in the repo) — roster-batch-import,
   direct multipart upload (media's real flow is presigned-URL, a different
   shape), and a "get current user" self-profile endpoint that plain iam
   never exposes. These are separate, pre-existing, unrelated feature gaps;
   fixing their path would just point at a different 404. Left untouched,
   flagged here so it doesn't read as an oversight.
3. **The real response shape carries no `role`/`tenantId`/`userType`/
   `mustChangePassword`** — iam's `TokenResponse` record
   (`services/iam/.../dto/response/TokenResponse.java`) is
   `{accessToken, refreshToken, tokenType, expiresInSeconds}` only. Those
   claims live inside the JWT itself (`roles: List<String>`, `tenant_id`),
   set by `AccessTokenIssuer.java`. The FE's `AuthResponse`/`JwtTokenResponse`
   type (they're a type alias of each other, confirmed — not two competing
   systems) expected the richer, fictitious shape; `LoginView.tsx`'s
   `onSuccess` in both `vendor-web` and `tenant-web` reads it directly today.
4. **Real role taxonomy**: `PLATFORM_ADMIN, PLATFORM_AUTHOR, HOST_ADMIN,
   HOST_AUTHOR, PROCTOR, STUDENT` (`services/iam/.../domain/enums/Role.java`).
   The FE's prior `SessionRole = "ADMIN"|"HOST"|"STUDENT"` matched neither
   this enum nor anything the backend actually emits — Phase 0 replaces it
   with the real 6 values and changes `AptisSession` from a single `role` to
   a `roles: SessionRole[]` array (the JWT claim is a list).
5. **Auth architecture has two hooks, not two competing systems**:
   `useSessionManager`/`sessionStorage` (key `aptis.session`) is the one
   real authorization store — `RequireAuth.tsx` reads it, `LoginView.tsx`
   writes it. `useTokenManager`/`tokenStorage` is a separate helper used
   only for the logout button's `clearToken()`; its `clear()` already wipes
   both its own key and `aptis.session`, so logout is correct as-is — no
   fix needed there, verified before assuming a bug.
6. **`vendor-web` and `tenant-web` share the exact same `RequireAuth.tsx`**
   (byte-for-byte diff) and the same broken `onSuccess` pattern in
   `LoginView.tsx` (vendor-web additionally branches admin-vs-host login by
   a `?role=` query param pre-login; both call the identical backend
   `/auth/login` endpoint regardless of that branch — the distinction is
   UI-routing only, not a backend concept). Both apps get the identical fix.
7. **No Flyway anywhere in `pte-api`** — every service (including `admin`)
   uses `spring.jpa.hibernate.ddl-auto: update`. Every new column/table in
   this plan (Phases 2/4/5) relies on that; no migration script is written.
8. **1-to-many JPA pattern to mirror** (Phase 4's `Tenant`→`Organization`):
   `services/exam-delivery/.../domain/{PinnedExamSnapshot,PinnedItem}.java`
   — `@OneToMany(mappedBy=..., cascade=ALL, orphanRemoval=true, fetch=LAZY)`
   + `@OrderBy` + an `addX(child)` back-reference helper on the parent;
   `@ManyToOne(fetch=LAZY) @JoinColumn(nullable=false)` + an indexed FK
   column on the child. Both extend `com.pte.common.domain.BaseEntity`
   (`id`, `publicId` UUID, `createdAt`/`updatedAt`) — only `publicId` ever
   crosses a service boundary, never a JPA relationship or the raw `Long id`.
9. **Actor-capture convention** (Phase 4/5's `CurrentUser caller` threading):
   `com.pte.common.security.{CurrentUser,CurrentUserContext}` — a controller
   helper `currentUser()` (pattern:
   `services/authoring/.../controller/QuestionController.java`) resolves it
   once and passes it as an explicit service-method parameter, never a
   static call inside the service (keeps services unit-testable without
   mocking a security context). `admin`'s `TenantController` doesn't use
   this yet — Phase 4/5 are what first introduce it there.
10. **Outbox/event convention**: `TenantLifecycleService.java`'s
    `OutboxWriter.write(aggregateType, aggregateId, eventType, payload,
    partitionKey)` inside the same `@Transactional` method as the entity
    save, with constants in `AdminConstants.java` and payload records under
    `domain/event/`. Every new write path in Phases 2/4/5 follows this
    exactly — no exceptions, including small ones like `reactivate`.
11. **`services/admin` has zero tests today** — Phase 2 is where its test
    directory is created for the first time, mirroring the package-layout
    convention other services use (`src/test/java/com/pte/admin/{service,
    mapper}/...Test.java`).
12. **No existing audit-trail/grant-history pattern anywhere in the repo**
    (Phase 5's `QuotaTransaction`) — confirmed via repo-wide search. This is
    a genuinely new pattern for this codebase, designed fresh but built on
    the existing `BaseEntity`/outbox/`CurrentUser` conventions rather than
    inventing new plumbing for them.

## Dependencies

- `pte-api` running locally (gateway + `iam` + `admin` at minimum) for any
  end-to-end verification step — docker compose already set up from prior
  session work.
- `pnpm`/`turbo` workspace at `pte-web` root; `packages/api-client` and
  `packages/ui` are consumed by both `apps/vendor-web` and
  `apps/tenant-web`, so every Phase 0/1 change to those packages must be
  verified against both apps, not just vendor-web.
- A seeded `PLATFORM_ADMIN` user in `iam` for manual end-to-end login
  verification (Phase 0/1's Verify steps).
- Phases 1–5 each depend on Phase 0 (working auth) directly; Phase 4 and 5
  additionally depend on Phases 1–3 having landed a correct, consolidated
  admin surface to extend rather than building against the pre-consolidation
  duplicate flow.

## Risks

- **HIGH (scope, already bounded)**: the auth/path-contract bug turned out
  to be repo-wide, not tenancy-specific. Mitigation already applied: scope
  was explicitly narrowed to the 4 files with a real backend counterpart
  (Research Summary item 2); the other 5 broken-but-unrelated request
  modules are documented, not silently expanded into this plan.
- **MEDIUM**: `AptisSession.role` → `roles: SessionRole[]` is a breaking
  shape change for anything reading `session.role` directly. Mitigation:
  grepped every call site across both apps before making the change — only
  `useSessionManager`'s internal `hasRole` and `LoginView.tsx`'s redirect
  logic touched it; both updated in Phase 0.
- **MEDIUM**: Phase 4's `Organization` field set (beyond `name`) isn't
  specified by the business rules beyond "branches/facilities" — Phase 4's
  own file flags this as a question for the user before implementation,
  rather than guessing a schema that would need a second migration pass.
- **LOW**: Phase 5's `QuotaTransaction.actionType` enum declares `DEDUCTED`/
  `REVOKED` values that this plan never implements logic for (only
  `GRANTED`) — intentional schema forward-compatibility for a future
  deduct-on-exam-start flow, not scope creep; flagged in Phase 5's Design
  Constraints so it isn't mistaken for unfinished work.
