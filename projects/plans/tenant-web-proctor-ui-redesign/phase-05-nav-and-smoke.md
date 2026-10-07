# Phase 05 — Nav wiring + final smoke

**Workstream:** pte-web
**Blocks:** none (last phase)
**Spec:** FE-FR-05, file-level acceptance
**Test mode:** manual + lint/build gates
**Risk:** MEDIUM — touches `lib/navigation*` files that may be in flight

## Goal

Wire proctor routes into the sidebar:

1. Add `PROCTOR_ROLES` to `features/auth/constants.ts` (1 line).
2. Add `PROCTOR_NAV_TEXT` to `lib/navigationConstants.ts`.
3. Add `buildProctorNav()` to `lib/navigation.tsx`.
4. Wire `ProctorProfileView` (from Phase 04) into the page file
   (per Option A from Phase 04).

After this phase, **ops can flip `NEXT_PUBLIC_PROCTOR_UI_ENABLED=true`
in production** to enable proctor UI for end users.

## Design Constraints

### Pre-flight: verify `git status`

Before starting Phase 05, run:

```bash
git status --short apps/tenant-web/lib/
git status --short apps/tenant-web/features/auth/constants.ts
```

If either file is **modified on the working tree** by another branch,
**defer Phase 05** until that branch merges. This is the load-bearing
risk identified in the brainstorm.

### `features/auth/constants.ts` (1 line addition)

```ts
export const PROCTOR_ROLES: SessionRole[] = ["PROCTOR"];
```

Place after `export const HOST_ROLES: SessionRole[] = ["HOST_ADMIN"];`.

### `lib/navigationConstants.ts` (one export addition)

```ts
export const PROCTOR_NAV_TEXT = {
  PROFILE: "Profile",
  AUDIT: "Audit log",
  SECTION: "Proctor",
} as const;
```

### `lib/navigation.tsx` (one function addition)

```tsx
export function buildProctorNav(): NavItem[] {
  return [
    { label: PROCTOR_NAV_TEXT.PROFILE, href: "/proctor/profile", icon: <UserIcon />, section: PROCTOR_NAV_TEXT.SECTION },
    { label: PROCTOR_NAV_TEXT.AUDIT, href: "/proctor/audit-log", icon: <DocumentIcon />, section: PROCTOR_NAV_TEXT.SECTION },
    // Note: Audit list at /proctor/audit-log is OUT OF SCOPE (requires backend endpoint).
    //       Per-session audit at /proctor/audit-log/{publicId} is deep-linked from /proctor/sessions/{id}.
  ];
}
```

Note: `UserIcon` is imported from `@pte/ui`. Verify during `ck:cook`
that this icon exists; otherwise omit icon (Phase 05 boundary).

### `app/(dashboard)/proctor/profile/page.tsx` (Phase 04 wiring)

```tsx
import { ProctorProfileView } from "@/features/proctor/components/ProctorProfileView";

export default function ProctorProfilePage() {
  return <ProctorProfileView />;
}
```

### LoginView post-login redirect (optional, deferred)

The deleted branch updated `LoginView.tsx` to redirect PROCTOR users to
`/proctor`. This is **deferred** to a follow-up plan because:

- `LoginView.tsx` is shared with HOST_ADMIN/EXAMINER/STUDENT flows
- Adding a PROCTOR branch requires careful testing of all 4 roles
- The deep-link entry model means pro doesn't need to land on `/proctor`
  after login — they enter via deep-link from host UI

Document this as a P2 follow-up.

## Files to edit

| File | Lines added | Purpose |
|---|---|---|
| `features/auth/constants.ts` | 1 | `PROCTOR_ROLES` |
| `lib/navigationConstants.ts` | 4 | `PROCTOR_NAV_TEXT` |
| `lib/navigation.tsx` | 15 | `buildProctorNav` |
| `app/(dashboard)/proctor/profile/page.tsx` | 5 | Wire `<ProctorProfileView>` |

**Total: 0 files added, 4 files edited.**

This matches spec S4's exception (only Phase 05 edits files outside
`features/proctor/`).

## Files to create

NONE.

## Tests to Write (alongside implementation)

1. `buildProctorNav.test.ts:returns2ItemsForProctor` (snapshot)
2. `features/auth/constants.test.ts:PROCTOR_ROLES_includesProctor`

## Manual smoke (deferred — requires running backend)

Cannot TDD; document the checklist and ask a second human (or
`generalPurpose` agent with browser) to execute:

1. `git pull` (latest Phase 04 PR merged).
2. `pnpm install` (no new packages).
3. Set `NEXT_PUBLIC_PROCTOR_UI_ENABLED=true` in `.env.local`.
4. `pnpm dev`.
5. Log in as a PROCTOR.
   - Sidebar shows: `Profile`, `Audit log` (under "Proctor" section).
   - Click `Profile` → /proctor/profile renders with username/email/roles.
   - Click `Audit log` → /proctor/audit-log redirects to a 404 page
     (no list endpoint yet — this is expected).
6. Deep-link from host UI to `/proctor/sessions/{id}` → live
   monitoring renders, polls at 3s.
7. Force-submit an attempt → row updates within 5s.
8. Navigate to `/proctor/audit-log/{id}` → tabs render.
9. Set `NEXT_PUBLIC_PROCTOR_UI_ENABLED=false` → /proctor/* returns
   404 (flag off).

## Final acceptance criteria

- 5 PRs merged sequentially
- 19 new files, 4 edited files (Phase 05)
- ≤ 6 components in `features/proctor/`
- 1 new env var (`NEXT_PUBLIC_PROCTOR_UI_ENABLED`)
- 0 new packages
- 0 backend changes
- Default OFF in production; opt-in via env var

## Quality and Testing State

- Quality: not evaluated
- Testing: not started