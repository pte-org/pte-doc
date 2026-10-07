# Phase 01 — Skeleton + flag + index redirect

**Workstream:** pte-web
**Blocks:** Phase 02-05
**Spec:** FE-FR-01, FE-FR-06, FE-FR-07, FE-FR-08
**Test mode:** standard (no-tdd)
**Risk:** NONE — pure add-only, no nav edit, no package add
**Preflight:** No existing `layout.tsx` pattern under `(dashboard)/*`; creating one for `proctor` is a new but Next.js-supported pattern. Boundary files mirror `examiner/loading.tsx` and `examiner/work/error.tsx` exactly. Error copy uses `ERROR_PAGE_TEXT` from `@/lib/errorPageConstants` (need to add `PROCTOR_DESCRIPTION` in this phase — single export extension, low blast radius).
**Quality status:** skipped_by_user; decision: user_confirmed_skip
**Testing status:** skipped by user (--fast mode)

## Goal

Ship the smallest possible proctor surface that:

1. Has a route at `/proctor` that redirects to `/proctor/profile`.
2. Has a `layout.tsx` enforcing the `NEXT_PUBLIC_PROCTOR_UI_ENABLED`
   flag (so the route 404s when the flag is off).
3. Has 1 placeholder component so we can verify routing works.

This phase is intentionally minimal — it exists to put the **flag and
route skeleton in place** so every subsequent phase adds inside it
safely. Any reviewer can verify by:

- Setting `NEXT_PUBLIC_PROCTOR_UI_ENABLED=false` (default) →
  `/proctor` returns 404
- Setting `NEXT_PUBLIC_PROCTOR_UI_ENABLED=true` →
  `/proctor` redirects to `/proctor/profile`

## Design Constraints

### Flag enforcement (`app/(dashboard)/proctor/layout.tsx`)

```tsx
import type { ReactElement, ReactNode } from "react";
import { notFound } from "next/navigation";

export default function ProctorLayout({ children }: { children: ReactNode }): ReactElement {
  if (process.env.NEXT_PUBLIC_PROCTOR_UI_ENABLED !== "true") notFound();
  return <>{children}</>;
}
```

This is a server component. `notFound()` is called before rendering
any children, so the route segment is effectively a 404 when disabled.

### Index redirect (`app/(dashboard)/proctor/page.tsx`)

Mirror `apps/tenant-web/app/(dashboard)/examiner/page.tsx`:

```tsx
import { redirect } from "next/navigation";

export default function ProctorIndexPage(): never {
  redirect("/proctor/profile");
}
```

The profile placeholder is a server component in Phase 01; it just
renders a heading. Phase 04 fills it in.

### Placeholder profile (`app/(dashboard)/proctor/profile/page.tsx`)

```tsx
import type { ReactElement } from "react";

export default function ProctorProfilePlaceholder(): ReactElement {
  return (
    <div className="p-8">
      <h1 className="text-2xl font-semibold text-gray-900">Proctor profile</h1>
      <p className="mt-2 text-sm text-gray-600">
        Phase 01 placeholder. Phase 04 wires the read-only fields.
      </p>
    </div>
  );
}
```

### Boundary files

Follow the established pattern from
`apps/tenant-web/app/(dashboard)/examiner/work/loading.tsx` and
`error.tsx`. Two boundary files for `/proctor/profile` only — the
index redirect doesn't need them (no data fetching).

### Error copy (`lib/errorPageConstants.ts`)

Add one line to the existing export (this is a tiny edit — not a
"navigation files" edit, and Phase 01's only file edit):

```ts
PROCTOR_DESCRIPTION: "We could not load the proctor console. Please try again.",
```

Place it after `EXAMINER_DESCRIPTION` for parallel structure.

## Files to create

| File | Lines (est.) | Purpose |
|---|---|---|
| `app/(dashboard)/proctor/layout.tsx` | 10 | Flag enforcement |
| `app/(dashboard)/proctor/page.tsx` | 5 | Index redirect |
| `app/(dashboard)/proctor/profile/page.tsx` | 12 | Phase 01 placeholder |
| `app/(dashboard)/proctor/profile/loading.tsx` | 11 | Loading skeleton |
| `app/(dashboard)/proctor/profile/error.tsx` | 22 | Error boundary |
| `features/proctor/.gitkeep` | 0 | Marker so future phases can `mkdir features/proctor/components` |

**Total: 6 files added, 1 edited** (the `errorPageConstants.ts` line addition).

## Files to edit

| File | Change |
|---|---|
| `lib/errorPageConstants.ts` | Add `PROCTOR_DESCRIPTION` (1 line) |

This single edit is intentional and necessary so the boundary file
can reference the existing `ERROR_PAGE_TEXT` constant pattern. It does
not violate S4 (which forbids edits to `lib/navigation*` and
`features/auth/constants.ts` — `errorPageConstants.ts` is neither).

## Tests to Write (alongside implementation)

1. `layout.test.tsx:notFound_whenFlagIsFalse` (using `notFound` mock)
2. `layout.test.tsx:renderChildren_whenFlagIsTrue`

[quality: skipped_by_user; decision: user_confirmed_skip]

## Merge checklist

- [x] `git status` shows no other in-flight edits to `apps/tenant-web/lib/*` (verified before cook)
- [x] `next build` PASS (verified with flag OFF and flag ON)
- [x] `tsc --noEmit` PASS
- [x] `eslint --max-warnings 0` PASS
- [x] Smoke: `pnpm dev` then `curl http://localhost:3000/proctor` →
      404 (flag off) — confirmed via build prerender
- [x] Smoke: `NEXT_PUBLIC_PROCTOR_UI_ENABLED=true pnpm dev` then
      `curl http://localhost:3000/proctor` → 307 redirect to
      `/proctor/profile` — confirmed via build prerender

## Build gate results

- `npx tsc --noEmit` → exit 0 (no errors)
- `npx eslint <changed files>` → exit 0 (no warnings)
- `npx next build` (flag=false) → ✓ Compiled successfully, 28 static pages
- `npx next build` (flag=true) → ✓ Compiled successfully, 28 static pages

## Quality and Testing State

- Quality: skipped_by_user; decision: user_confirmed_skip
- Testing: skipped by user (--fast mode)