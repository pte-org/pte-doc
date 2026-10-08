# Phase 04 — Profile (read-only, real)

**Workstream:** pte-web
**Blocks:** Phase 05
**Spec:** FE-FR-04
**Test mode:** standard (no-tdd)
**Risk:** LOW — read-only, no mutation, no new endpoints, no new packages
**Preflight:** `useCurrentUser` exists at `features/auth/api.ts` and
returns the real `CurrentUser` shape (`publicId`, `email`, `fullName`,
`tenantId`, `status`, `roles`, `organizationType`). No additional
api-client work needed.
**Quality status:** skipped_by_user; decision: user_confirmed_skip
**Testing status:** skipped by user (--fast mode)

## Goal

Replace the Phase 01 placeholder at `/proctor/profile` with a real
read-only view showing the proctor's `fullName`, `email`, and
`roles` from `useCurrentUser`.

No change-password in this phase (P2 follow-up).

## Design Constraints

### Read-only

No change-password section in this phase. P2 (post-Phase 06) adds it.

If `POST /api/v1/auth/change-password` exists in the backend, we
verify during `ck:cook` and add it as P2 work in a separate spec
(do not bundle into Phase 04 — that would couple scope).

### Component budget

1 new component (the view itself):

1. `ProctorProfileView` — main view (~80 lines)

(No `ProctorRoleBadges` extracted — the view is small enough.)

### Constants (additions to features/proctor/constants.ts)

```ts
export const PROCTOR_PROFILE_TEXT = {
  TITLE: "Proctor profile",
  SUBTITLE: "Your account details. This view is read-only.",
  FULL_NAME_LABEL: "Full name",
  EMAIL_LABEL: "Email",
  ROLES_LABEL: "Roles",
  STATUS_LABEL: "Status",
  TENANT_LABEL: "Tenant",
  LOADING: "Loading profile…",
  ERROR_TITLE: "Could not load profile",
  ERROR_DESCRIPTION: "Try refreshing the page. If the problem persists, contact your host admin.",
  EMPTY_FULL_NAME: "(no name set)",
  ROLES_SEPARATOR: ", ",
} as const;
```

### Use of `useCurrentUser`

Reuse the existing pattern:

```tsx
import { useCurrentUser } from "@/features/auth/api";

export const ProctorProfileView = (): ReactElement => {
  const user = useCurrentUser();
  if (user.isLoading) return <Skeleton ... />;
  if (user.isError || !user.data) return <ErrorState ... />;
  return (
    <div>
      <PageHeader title={PROCTOR_PROFILE_TEXT.TITLE} subtitle={PROCTOR_PROFILE_TEXT.SUBTITLE} />
      <Field label={FULL_NAME_LABEL}>{user.data.fullName || EMPTY_FULL_NAME}</Field>
      <Field label={EMAIL_LABEL}>{user.data.email}</Field>
      <Field label={ROLES_LABEL}>{user.data.roles.join(SEPARATOR)}</Field>
    </div>
  );
};
```

## Files to create

| File | Lines (est.) | Purpose |
|---|---|---|
| `features/proctor/components/ProctorProfileView.tsx` | 80 | Read-only profile |

**Total: 1 file added.**

## Files to edit

| File | Change |
|---|---|
| `app/(dashboard)/proctor/profile/page.tsx` | Replace Phase 01 placeholder with `<ProctorProfileView />` (Option B; S4 add-only rule bent for this trivial 1-line wiring) |
| `features/proctor/constants.ts` | +12 lines: `PROCTOR_PROFILE_TEXT` |

**Total: 1 file added, 2 files edited.**

This deviates from the original Phase 04 plan (which said Option A
— leave page.tsx alone, wire in Phase 05). We bend S4 to wire
`<ProctorProfileView>` directly here so Phase 05 stays focused
on nav wiring only. Cost: 1 trivial 1-line edit to `profile/page.tsx`.

## Tests to Write (alongside implementation)

1. `ProctorProfileView.test.tsx:rendersAllFieldsFromCurrentUser`
2. `ProctorProfileView.test.tsx:showsLoadingSkeleton_whenCurrentUserIsLoading`
3. `ProctorProfileView.test.tsx:showsErrorState_whenCurrentUserFails`

## Merge checklist

- [ ] Component count for proctor ≤ 6 total (Phase 02: 3, Phase 03: 1, this adds 1 → 5)
- [ ] `next build` PASS, `tsc --noEmit` PASS, `eslint --max-warnings 0` PASS
- [ ] No mutation, no new endpoint, no new package

## Quality and Testing State

- Quality: not evaluated
- Testing: not started