# Phase 0: Auth + API Contract Fix

## Requirements

Fix the foundational bug blocking every later phase: `apps/vendor-web` and
`apps/tenant-web` never actually reach the real `pte-api` backend for login
or tenancy calls — wrong gateway paths, and a response shape the backend
has never returned. Restore a real, verified login→role→tenancy path before
any RBAC or tenancy feature work can be trusted.

Maps to: **Foundational — blocks Phase 1 (RBAC is meaningless without a
working session) and every phase after it.**

## Design Constraints

- Only fix the 4 request modules with a real, verified backend counterpart:
  `packages/api-client/src/requests/{auth,admin/hosts,tenant,question}/index.ts`.
  Do **not** touch `host/imports.ts`, `host/studentImport.ts`,
  `host/students.ts`, `asset/index.ts`, `account/index.ts` — grepping every
  `services/*/controller/*.java` in `pte-api` confirmed none of these have a
  matching backend endpoint at all (not a wrong path — no endpoint exists).
  "Fixing" their prefix would just point at a different 404 and create
  false confidence. Leave them as-is; this is a separate, pre-existing,
  unrelated gap.
- `AuthResponse`/`JwtTokenResponse` (they are a type alias of each other —
  confirmed, not two competing types) must match iam's real `TokenResponse`
  record exactly: `{accessToken, refreshToken, tokenType, expiresInSeconds}`.
  No `role`/`tenantId`/`userType`/`mustChangePassword` fields — the backend
  has never returned them and no downstream code other than the one
  `LoginView.tsx` write-site reads `mustChangePassword`, so it can be
  dropped outright rather than stubbed.
- Role/tenant claims come from decoding the JWT `accessToken` itself
  (`roles: string[]`, `tenant_id: string|null`, both set by
  `AccessTokenIssuer.java`), never from the login response body. Write the
  decoder by hand (base64url + `JSON.parse`) in
  `packages/api-client/src/client/jwt.ts` — do not add the `jwt-decode`
  dependency; verification of the signature is not needed client-side (the
  server already validated it), only reading claims for UI routing/gating.
- `packages/ui/src/hooks/sessionStorage.ts`'s `SessionRole` must be the real
  6-value enum (`PLATFORM_ADMIN, PLATFORM_AUTHOR, HOST_ADMIN, HOST_AUTHOR,
  PROCTOR, STUDENT`, from `services/iam/.../domain/enums/Role.java`), and
  `AptisSession` carries `roles: SessionRole[]` (the JWT claim is a list),
  not a single `role`. Every read site (`hasRole` in both `sessionStorage.ts`
  and `useSessionManager.ts`, `parseSession`'s validation guard) must be
  updated to the array shape — grep for `session.role`/`.role ===` across
  both apps before editing, not just the obvious sites.
- `client.ts`'s new refresh-on-401 logic must not create a circular import:
  `requests/auth/index.ts` already does `import type { ApiClient } from
  "../../client/client"` (type-only, safe), but `client.ts` must never
  import a *value* from `requests/auth`. `ApiClientOptions` instead accepts
  `getRefreshToken`/`refreshAccessToken`/`onTokenRefreshed` callbacks that
  the app wires up itself (`apps/*/lib/apiClient.ts`), using a **raw
  `fetch`** for the refresh call there (not the `apiClient` instance being
  constructed, which doesn't exist yet at that point and would recurse into
  its own 401 handling anyway).
- Concurrent 401s must dedupe into a single in-flight refresh — not one
  refresh call per failed request. Cap retry at exactly 1 attempt per
  request to avoid an infinite loop if the refresh token itself is expired.
- `apps/vendor-web` and `apps/tenant-web` get the identical fix —
  `RequireAuth.tsx` is byte-for-byte the same file in both; `LoginView.tsx`
  has the same broken `onSuccess` pattern in both (tenant-web is simpler,
  host-only login, no admin/host branch).

## Steps

1. Grep every `services/*/controller/*.java` in `pte-api` to build the real
   path table (context-path + `@RequestMapping`) for `iam`, `admin`,
   `authoring` — done; recorded in `plan.md`'s Research Summary items 1–2.
2. Fix `AUTH_ENDPOINTS`/`ADMIN_HOST_ENDPOINTS`/`TENANT_ENDPOINTS`/
   `QUESTION_ENDPOINTS` in the 4 in-scope request files to the real paths.
3. Rewrite `AuthResponse` in `packages/api-client/src/types/auth/index.ts`
   to iam's real shape; remove the now-unused `Role` type (confirmed unused
   elsewhere via grep before deleting).
4. Add `packages/api-client/src/client/jwt.ts`
   (`decodeAccessTokenClaims`/`AccessTokenClaims`), export from
   `client/index.ts`.
5. Add `RefreshedTokens`, `getRefreshToken`, `refreshAccessToken`,
   `onTokenRefreshed` to `ApiClientOptions` in `client.ts`; add the
   dedup'd `tryRefresh()` helper; wrap `request`/`upload`/`download` with a
   `isRetry` parameter that attempts exactly one refresh+retry on a 401
   before falling through to the existing `assertOk`/`onUnauthorized` path.
6. Rewrite `packages/ui/src/hooks/sessionStorage.ts`: real `SessionRole`
   union, `AptisSession.roles: SessionRole[]`, `hasRole`/`parseSession`
   updated for the array shape.
7. Update `useSessionManager.ts`'s `hasRole` to the same array-intersection
   logic.
8. Rewrite `LoginView.tsx` in both `apps/vendor-web` and `apps/tenant-web`:
   decode the JWT in `onSuccess`, build the session from decoded
   `roles`/`tenantId` instead of response fields, fail closed (surface a
   login error) if decoding fails, redirect host-vs-admin based on decoded
   roles instead of a non-existent `data.role`.
9. Wire `getRefreshToken`/`refreshAccessToken`/`onTokenRefreshed` into
   `apps/vendor-web/lib/apiClient.ts` and `apps/tenant-web/lib/apiClient.ts`
   (raw-`fetch`-based `refreshAccessToken`, identical in both).
10. `tsc --noEmit` on `packages/api-client` and `packages/ui`; fix any
    downstream type errors surfaced in either app before considering this
    phase done.

## Success Criteria

- [x] The 4 in-scope request modules call the real gateway-routed paths
      (`/api/iam/auth/*`, `/api/admin/tenants`, `/api/authoring/questions`).
- [x] `AuthResponse` matches iam's `TokenResponse` exactly; no fictitious
      fields remain on the type.
- [x] `decodeAccessTokenClaims` exists and is exported from
      `@aptis/api-client`; both `LoginView.tsx`s use it instead of reading
      response-body fields for role/tenant.
- [x] `SessionRole`/`AptisSession` reflect the real 6-role, array-shaped
      JWT claim; every call site (`hasRole` × 2, `parseSession`, both
      `LoginView.tsx`s) updated, not just the type declaration.
- [x] `client.ts` retries exactly once on 401 via a deduped refresh, then
      falls through to `onUnauthorized` if refresh is unavailable or fails.
- [x] `tsc --noEmit` passes clean on `packages/api-client` and `packages/ui`
      (also re-verified clean on `apps/vendor-web`/`apps/tenant-web`).
- [ ] Manual: login as a real `PLATFORM_ADMIN` user against a running
      gateway+iam+admin stack; network tab shows `/api/iam/auth/login`
      returning 200; session persists the decoded roles; `GET
      /api/admin/tenants` returns a real (possibly empty) list, not a
      network error or 404. **Not yet run** — needs the full stack up
      (gateway+iam+admin+postgres+rabbitmq) plus a seeded `PLATFORM_ADMIN`
      user, neither of which exist yet in this environment; deferred rather
      than blocking the phase on standing up infra from scratch.
- [ ] Manual: force an access-token expiry mid-form-fill; confirm the next
      request transparently refreshes and retries without losing form state
      or bouncing to `/login`. Same blocker as above.

## Quality and Testing State

- Implementation: complete (all 10 steps above applied across
  `packages/api-client`, `packages/ui`, `apps/vendor-web`,
  `apps/tenant-web`).
- `tsc --noEmit`: **clean** on all 4 touched packages/apps. Worked around a
  pre-existing environment mismatch (`pnpm@11.8.0` in `package.json`
  requires Node ≥22.13; installed Node is `v22.12.0`) by running
  `npx pnpm@9` for install instead — not a project change, purely a local
  workaround; flagging the Node/pnpm mismatch itself as a separate,
  pre-existing environment issue worth fixing independently of this plan.
- `eslint`: clean on both apps.
- Quality gate (`ck:quality`, `quality-reviewer` agent): **APPROVED** after
  fixes. Initial pass found 1 BLOCKER + 1 HIGH + 2 MEDIUM, all fixed:
  - **QUAL-001 (BLOCKER, fixed)**: the login request body used a fictitious
    `credential` field — the real backend `LoginRequest` record only has
    `email`. URL path was correct but the payload never would have been
    accepted (400 on every login attempt). Fixed in `types/auth/index.ts`
    and `requests/auth/index.ts` (`login`/`loginAdmin`/`loginHost`/
    `loginStudent`).
  - **QUAL-002 (HIGH, fixed)**: a JWT that decodes successfully but whose
    `roles` claim contains no recognized value produced an empty
    `roles: []` session that still passed `isAuthenticated` — silently
    logged-in-but-permission-less. Both `LoginView.tsx`s now treat
    zero-recognized-roles the same as a decode failure (fail closed).
  - **QUAL-003 (MEDIUM, fixed)**: `AUTH_ENDPOINTS.changePassword` was
    rewritten to a plausible-looking `/api/iam/auth/change-password` path
    that still doesn't exist on the backend, with no comment distinguishing
    it from the genuinely-fixed endpoints. Documented as deliberately
    unsupported/unused, matching the `types/account/index.ts` treatment.
  - **QUAL-004 (MEDIUM, fixed)**: `apps/vendor-web/lib/apiClient.ts` and
    `apps/tenant-web/lib/apiClient.ts` were byte-for-byte duplicated.
    Extracted `createSessionApiClient(baseUrl)` into
    `packages/ui/src/hooks/createSessionApiClient.ts` (new `@aptis/ui` →
    `@aptis/api-client` workspace dependency); both apps' `apiClient.ts`
    now a 2-line call into the shared helper.
  - Re-ran `tsc --noEmit`/`eslint` on all 4 packages/apps after every fix —
    stayed clean throughout.
- **Residual gap, carried forward, not silently dropped**: the two manual
  end-to-end Success Criteria above (real login against a live backend;
  live token-refresh mid-form) have not been executed. Everything gated on
  static verification (types, lint, independent quality review catching a
  real contract bug) passed, but "the network call actually returns 200"
  has not been empirically proven. Flagging this explicitly rather than
  marking the phase fully done — recommend running it before Phase 1 is
  trusted, or accepting the risk explicitly if moving on regardless.
