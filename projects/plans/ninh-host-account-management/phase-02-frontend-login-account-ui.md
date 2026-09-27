# Phase 2: Frontend — Login Account Section in TenantDetailView

## Requirements

Depends on Phase 1. Give the Admin a place, inside a Tenant's detail page,
to (a) create that Host's first login account if none exists yet, and (b)
reset its password if it does. Closes the gap where a newly onboarded
Tenant has no way to ever log in.

## Design Constraints

- **Placement:** a new "Login Account" section in
  `apps/vendor-web/features/tenancy/components/TenantDetailView.tsx`,
  alongside the existing Organizations/Branding sections. Tenant is always
  the one the page is already open on — no tenant picker anywhere (per the
  AskUserQuestion decision in `plan.md`).
- **Role is fixed, not a picker.** The created account is always
  `HOST_ADMIN` — this flow exists specifically to give a Host its admin
  login, not a general "create any user" form. `roles: ["HOST_ADMIN"]` is
  hardcoded in the create-login mutation, never exposed as a form field.
- **Query:** `useQuery(["loginAccount", tenantPublicId], () => listUsersByTenant(apiClient, tenantPublicId))`.
  Empty array → "no account yet" state. Non-empty → take `[0]` as the
  primary account (per `plan.md`'s Risks note — backend can return more,
  UI only surfaces the first). Deliberately **not** nested under a
  `"tenants"` root — the quality gate caught an earlier draft that used
  `["tenants", tenantPublicId, "loginAccount"]`, which TanStack Query v5's
  default prefix-matching invalidation would treat as a match for every
  plain `invalidateQueries({ queryKey: ["tenants"] })` call elsewhere in
  this file (`useCreateTenant`/`useSuspendTenant`/`useReactivateTenant`),
  causing unrelated tenant-list mutations to refetch whatever tenant
  detail page happened to be open. `useOrganizations`/`useTenant` already
  avoid this by using their own root segment (`"organizations"`/
  `"tenant"`) — `"loginAccount"` follows the same convention.
- **Create-login form:** email + password (min 8 chars, mirror backend's
  `@Size(min = 8)` client-side like `validateCreateTenant.ts` already does
  for other fields) + full name. Submits via a new `useCreateLoginAccount`
  mutation calling `createUser(apiClient, { email, fullName, password,
  roles: ["HOST_ADMIN"], tenantId: tenantPublicId })`. `onSuccess` →
  `invalidateQueries(["tenants", tenantPublicId, "loginAccount"])` (the
  established mutate→invalidate pattern from Organizations/Branding).
  Handle the `EMAIL_ALREADY_USED` 409 the same way Phase 4's Organization
  flow handled `ORGANIZATION_NAME_ALREADY_USED` (`ApiError.kind ===
  "conflict"` → friendly message, not a generic error).
- **Reset-password action:** shown only when an account already exists.
  Opens a modal with a single "new password" field (min 8 chars, same
  client-side check). Submits via a new `useResetPassword(userPublicId)`
  mutation calling the new `POST /users/{publicId}/reset-password`.
  `onSuccess` → close modal, show a one-time inline success message
  ("Password reset. Relay it to the Host directly — it won't be shown
  again.") — the backend never returns the password, so there is nothing
  to redisplay; this message is purely to confirm the action happened.
  Clear the password field from component state immediately after submit
  (don't let it linger in a closed-but-not-unmounted form).
- **Key-based remount for both modals**, matching this codebase's
  established convention (`SuspendTenantModal`, `GrantQuotaModal`,
  `BrandingEditor`) instead of a `useEffect` reset — keys off
  `tenantPublicId` for the create-login modal and the account's
  `publicId` for the reset-password modal.
- **New `packages/api-client` additions:**
  - `types/user/index.ts` — `UserResponse` (mirrors iam's DTO:
    `publicId, email, fullName, tenantId, status, roles`),
    `CreateUserRequest`, `ResetPasswordRequest`.
  - `requests/user/index.ts` — `createUser`, `listUsersByTenant`,
    `resetPassword`. Paths: `POST /api/iam/users`,
    `GET /api/iam/users/by-tenant/{tenantId}`,
    `POST /api/iam/users/{publicId}/reset-password` — the real
    `/api/iam` prefix from the start; no `/api/v1` mistake to repeat here.
  - Barrel exports updated (`requests/index.ts`, `types/index.ts`).

## Steps

1. `packages/api-client`: new `types/user`, `requests/user`, barrel
   exports.
2. `apps/vendor-web/features/tenancy/api/index.ts`: `useLoginAccount(tenantPublicId)`,
   `useCreateLoginAccount(tenantPublicId)`, `useResetPassword(userPublicId)`.
3. `apps/vendor-web/features/tenancy/constants/index.ts`: text +
   validation-error strings for both forms (mirror `CREATE_TENANT_TEXT`/
   `CREATE_TENANT_ERRORS` shape).
4. `apps/vendor-web/features/tenancy/utils/validateCreateLoginAccount.ts`,
   `validateResetPassword.ts` (new, mirror `validateBranding.ts`'s shape).
5. `components/CreateLoginAccountModal.tsx` (new), `components/ResetPasswordModal.tsx` (new).
6. `components/TenantDetailView.tsx`: new "Login Account" section wired to
   the query + both modals.

## Success Criteria

- [ ] Opening a Tenant with no login account shows "Create Login"; opening
      one with an account shows its email + status and "Reset Password"
      instead.
- [ ] Creating a login account succeeds and the section updates without a
      page reload; a duplicate email shows the friendly conflict message,
      not a raw error.
- [ ] Resetting a password succeeds, shows the one-time confirmation, and
      the new password actually works logging into `tenant-web`
      (`POST /auth/login`) while the old one no longer does — verify this
      manually against the running stack, same as every other phase in
      the prior plan.
- [ ] `tsc --noEmit`, `eslint`, `next build` all clean on `@pte/api-client`
      and `vendor-web`.

## Quality-and-Testing-State

- Frontend: `tsc --noEmit`, `eslint`, `next build` clean on
  `@pte/api-client` and `vendor-web`.
- Quality gate (`ck:quality`, `quality-reviewer` agent): first pass found
  **1 MEDIUM (QUAL-001)** — `useLoginAccount`'s query key
  `["tenants", tenantPublicId, "loginAccount"]` shared the `"tenants"`
  root with the pre-existing tenant-list invalidation key, causing
  unrelated tenant-list mutations to also refetch an open tenant's login
  account. Fixed by renaming to `["loginAccount", tenantPublicId]` (see
  Design Constraints), matching `useOrganizations`/`useTenant`'s existing
  convention of a distinct root segment per entity. All six specifically
  requested checks (contract accuracy, query correctness, password not
  lingering, conflict handling, one-time reset-success message, general
  hook correctness) passed clean on the first pass. Re-verified
  `tsc`/`eslint` clean after the fix; not re-run as a separate quality
  pass — a mechanical query-key rename with no logic change.
- Manual E2E: not yet run — same deferred pattern as every phase.
