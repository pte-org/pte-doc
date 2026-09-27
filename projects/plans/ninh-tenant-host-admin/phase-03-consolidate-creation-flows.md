# Phase 3: Consolidate Host-Creation Flows

## Requirements

Two independent, non-consolidated Host-creation UIs exist:
`app/(dashboard)/admin/hosts/page.tsx` (`HostCreationForm`, a flat 11-field
form, not linked in `lib/navigation.tsx`'s nav) and
`app/(dashboard)/admin/tenants/page.tsx` (`TenantManagementView` +
`CreateTenantModal`, richer — slug, plan select, expiry date, duplicate
pre-check, and the linked, actually-navigable one). Keep exactly one.

Maps to: **Cleanup discovered during the original review — not a business
rule directly, but removes a real source of confusion/dead code before
Phase 4/5 extend the surviving flow.**

**Update from Phase 2:** the surviving `tenants` flow's contract with the
real backend (`OnboardTenantRequest`/`TenantResponse`) was itself fictitious
until Phase 2 fixed it — `useCreateTenant()` was calling the fictitious
`admin/hosts` module (`createHost`) under a translated shape, not a real
`onboardTenant` call. That's fixed now: `useCreateTenant()` calls the real
`onboardTenant` from the `tenant` request module, and Phase 2 confirmed via
grep that `useCreateHost()`/`admin/hosts.ts` are referenced only by
`HostCreationForm.tsx` — i.e. exactly the files this phase already planned
to delete, with nothing else depending on them. This phase's scope is
otherwise unchanged (still pure FE deletion, no backend change) — Phase 2
did not delete these files itself to keep that decision and diff separate.

## Design Constraints

- Depends on Phase 0: only keep a flow already verified to hit the real
  backend correctly.
- No backend change in this phase — purely FE deletion/cleanup.
- Grep the whole `apps/vendor-web` tree for `HostCreationForm` and
  `admin/hosts` **before** deleting, to confirm nothing else references
  them (deep links, tests, other components) — not just the nav file.

## Steps

1. Delete `app/(dashboard)/admin/hosts/page.tsx` and
   `features/tenancy/components/HostCreationForm.tsx`.
2. Remove the `HostCreationForm` export from
   `features/tenancy/components/index.ts` if present.
3. Check whether `useCreateHost()` (the raw, unmapped mutation, distinct
   from `useCreateTenant()`) is still referenced by anything after step 1;
   remove it too if it's now dead.
4. Grep-verify zero remaining references to the deleted files/route.

## Success Criteria

- [x] `HostCreationForm`/`admin/hosts` route no longer exist in the tree.
- [x] No broken links anywhere in the admin nav (confirmed: nothing in
      `lib/navigation.tsx` ever linked to it).
- [x] Creating a Host end-to-end through the surviving `tenants` flow still
      works after the deletion — unaffected by this phase's diff (Phase 2
      already made `useCreateTenant` real; this phase deleted the fully
      separate, unreferenced fictitious flow, not touched by any create
      path in the surviving UI). Live E2E click-through not yet run, same
      deferred gap as prior phases.

## Quality and Testing State

- Deleted: `app/(dashboard)/admin/hosts/page.tsx`,
  `features/tenancy/components/HostCreationForm.tsx`,
  `packages/api-client/src/requests/admin/` (whole dir),
  `packages/api-client/src/types/host/host.ts`. Edited barrels:
  `features/tenancy/components/index.ts`, `features/tenancy/api/index.ts`
  (removed `useCreateHost` + its dead imports), `requests/index.ts`,
  `types/host/index.ts` (kept `import.ts`/`student.ts` exports — a separate,
  unrelated, still out-of-scope roster-import module).
- Verified via grep (zero real source matches for `HostCreationForm`,
  `useCreateHost`, `CreateHostRequest`, `HostResponse`, `createHost(`,
  `admin/hosts`) before AND after by both the implementer and the
  independent quality-gate review.
- `next build`: clean, 11 routes (was 12 — `/admin/hosts` correctly gone).
- `tsc --noEmit`: clean on `@aptis/api-client` and `vendor-web`.
- `eslint`: clean on `vendor-web`.
- Quality gate (`ck:quality`, `quality-reviewer` agent): **0 findings,
  APPROVED**. Independently re-ran all greps, confirmed the unrelated
  host-import/student-list module (`requests/host/*`,
  `types/host/{import,student}.ts`) was not collaterally broken, confirmed
  no dangling references in `pte-api`/`pte-doc`/`pte-app`.
- Manual E2E: not yet run — same deferred gap as prior phases.
