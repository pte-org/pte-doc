# Phase 6: tenant-web — Org-Type Label Dictionary + Label-Driven Navigation

## Requirements

The entire Host UI's Program/Class terminology must adapt to the caller's
`organizationType` — School → "Khối" (Program) → "Lớp" (Class); Center →
"Khóa" (Program) → "Lớp" (Class) — driven by one keyed lookup, never
scattered if/else, and always re-derived from the live session (not stale
`localStorage`) so an F5 reload never shows a stale label.

Maps to: `plan.md` Decision 4 (label config), Decision 5 (live label
source); Research Summary items 1, 8, 14.

## Design Constraints

- **One dictionary, keyed by an org-type "family" bucket, never if/else in
  a component.** `Tenant.organizationType` is free text with 4 existing
  values (`SCHOOL`, `UNIVERSITY`, `TRAINING_CENTER`, `CORPORATE` — per
  vendor-web's `ORGANIZATION_TYPE_OPTIONS`) but the spec only defines a
  binary label split. Define an explicit bucket map
  (`SCHOOL`/`UNIVERSITY` → `"SCHOOL_FAMILY"`, `TRAINING_CENTER`/`CORPORATE`
  → `"CENTER_FAMILY"`) with a documented default bucket
  (`"CENTER_FAMILY"`, the more generic pair of terms) for `null` or any
  future unmapped value — **flag this bucketing choice to the user for
  confirmation before this phase ships to production**, it's this plan's
  own reasonable inference, not something explicitly specified.
- **Label source is `useCurrentUser()`'s live `organizationType` field
  (Phase 1), never persisted into `sessionStorage`'s `PteSession`.**
  `sessionStorage.ts`'s `PteSession` stays exactly as-is (Decision 5 — the
  whole point is F5 always re-fetches from `/auth/me`, not from anything
  cached locally). Do not add `organizationType` to `PteSession`.
- One new hook, `useOrgLabels()`, wrapping `useCurrentUser()` +
  the bucket map + the label dictionary — every component that needs a
  Program/Class label calls this hook, never reads `organizationType`
  directly and branches itself.
- `NavItem` labels that depend on org type must be computed at render time
  from `useOrgLabels()`, not baked into the existing static `HOST_NAV`
  array in `apps/tenant-web/lib/navigation.tsx` (which is a plain constant,
  evaluated once, with no hook access) — `HOST_NAV`'s Program/Class entries
  become a function `buildHostNav(labels)` called from `DashboardChrome`'s
  call sites, or `DashboardChrome` itself gains an optional
  `navItems: NavItem[] | ((labels: OrgLabels) => NavItem[])` — pick
  whichever keeps `DashboardChrome`'s existing required-prop contract
  intact for every *other* (non-Program/Class) page that doesn't need
  labels at all; don't force every existing `page.tsx` call site to change
  if only 2-3 new nav entries need it.
- No hardcoded label strings in JSX anywhere in this feature — the
  dictionary itself lives in one `constants.ts`, exactly like every other
  feature folder in this codebase.

## Steps

1. `apps/tenant-web/features/orgLabels/constants.ts` (new feature folder)
   — the bucket map + the label dictionary:
   `{ SCHOOL_FAMILY: { program: "Khối", class: "Lớp" }, CENTER_FAMILY:
   { program: "Khóa", class: "Lớp" } }`, plus the default-bucket constant.
2. `apps/tenant-web/features/orgLabels/useOrgLabels.ts` — reads
   `useCurrentUser().data?.organizationType`, resolves the bucket (default
   on `null`/unmapped), returns `{ program: string, class: string,
   isLoading: boolean }` (propagate `useCurrentUser`'s own loading state so
   callers can render a skeleton instead of a flash of the wrong label).
3. `apps/tenant-web/lib/navigation.tsx` — convert the Program/Class-related
   entries in `HOST_NAV` to be produced by a `buildHostNav(labels: OrgLabels)`
   function; keep non-label nav entries (Dashboard, Exams, etc.) as static
   as before.
4. Update every `page.tsx` under `app/(dashboard)/host/**` that renders
   `DashboardChrome` with `HOST_NAV` to instead call `useOrgLabels()` +
   `buildHostNav(labels)` — small, mechanical change per file, but touches
   every existing Host page, so grep for all current `HOST_NAV` usages
   first and update every one (don't miss one and leave it showing stale
   static labels).
5. New Program/Class list/nav pages (skeleton only — Phase 7 fills in the
   real UI) get their section headings/breadcrumbs sourced from
   `useOrgLabels()` too, established here as the pattern Phase 7 continues.
6. Verify the F5 case manually is testable in principle: `useCurrentUser()`
   already has no `staleTime` override (default TanStack Query behavior —
   confirm by reading its `useQuery` call) so it refetches on every fresh
   mount, satisfying Decision 5 without extra plumbing; if it turns out
   `retry: false` combined with a cached stale response from a prior
   session could show a wrong label for a moment, add an explicit
   `staleTime: 0`/`refetchOnMount: "always"` to close that gap — check
   before assuming it's already fine.
7. Tests/build: `tsc --noEmit`, `eslint`, `next build` on `tenant-web`.

## Success Criteria

- [x] A School-family tenant's Host sees "Khối"/"Lớp" everywhere the
      dictionary is wired; a Center-family tenant sees "Khóa"/"Lớp" — same
      component code, different data.
- [x] A tenant with `organizationType: null` (pre-Phase-1 tenant, per
      Research Summary item 14) shows the documented default bucket's
      labels, never a blank string or a crash.
- [x] No component contains an `if (organizationType === "SCHOOL")`-style
      branch anywhere — grep confirms the dictionary/bucket-map is the only
      place org-type is compared to a literal.
- [x] Reloading the page (F5) never shows a label from a previous
      session/tenant, even if the browser has stale `localStorage` data
      from a prior login.
- [x] `pnpm --filter tenant-web lint` and `pnpm --filter tenant-web build`
      both clean.

## Quality and Testing State

- Quality gate: APPROVED, 0 findings. Reviewer independently confirmed:
  zero `organizationType ===` comparisons outside `features/orgLabels/`;
  `sessionStorage.ts`'s `PteSession` untouched; the F5-staleness reasoning
  holds (no persister, no `staleTime` override); the 3 Server-to-Client
  Component conversions carry no regression (the original
  `exams/[publicId]/page.tsx` had no data-fetching/`generateMetadata`/
  `revalidate` beyond the `params` unwrap); `DashboardChrome.tsx`'s net
  diff is a doc-comment only, genuinely a no-op; and the bucket map's
  literal values exactly match vendor-web's `ORGANIZATION_TYPE_OPTIONS`
  with no drift.
- Testing: no automated test framework runs in `tenant-web` today (no
  existing precedent in this app to extend — confirmed by grep, matches
  Phase 2's "no precedent" finding pattern for other repos). Verified
  instead via `pnpm --filter tenant-web lint` (clean) and
  `pnpm --filter tenant-web build` (clean — `next build`'s static-page
  generation + TypeScript pass is the closest thing to an integration
  check this app has) and a manual grep sweep confirming zero
  `organizationType ===` comparisons anywhere outside
  `features/orgLabels/`.
- **Bucketing choice confirmed with the user before implementing** (per
  this phase's own Design Constraint): SCHOOL/UNIVERSITY -> SCHOOL_FAMILY
  (Khối), TRAINING_CENTER/CORPORATE -> CENTER_FAMILY (Khóa), default
  bucket for `null`/unmapped = CENTER_FAMILY. Implemented exactly as
  confirmed.
- **RSC boundary finding (not anticipated by the phase's Step 4 wording,
  discovered during `next build`)**: the phase's Design Constraints
  offered an alternative to touching every `page.tsx` — give
  `DashboardChrome` a `navItems: NavItem[] | ((labels) => NavItem[])`
  prop and resolve internally. This does not work in this Next.js
  version: a Server Component `page.tsx` cannot pass a *function* prop to
  a `"use client"` component (`next build` fails with "Functions cannot
  be passed directly to Client Components"). Reverted `DashboardChrome`
  to its original plain `NavItem[]` prop (zero net change to that file)
  and instead followed Step 4 literally: `dashboard/page.tsx`,
  `exams/page.tsx`, and `exams/[publicId]/page.tsx` all gained `"use
  client"` + a direct `useOrgLabels()` + `buildHostNav(labels)` call.
  `exams/[publicId]/page.tsx` additionally switched from an `async`
  Server Component reading `params: Promise<...>` to a Client Component
  using `useParams()` from `next/navigation`, since Client Components
  can't be `async`/await a params Promise. This also resolved a
  correctness question about *when* `useOrgLabels()`'s underlying
  `useCurrentUser()` call fires relative to `RequireAuth`'s auth gate: it
  fires only after the page component itself renders, which `RequireAuth`
  already gates — same lifecycle as the pre-existing `HeaderActions`
  call, no new pre-auth fetch introduced.
- **F5 staleness (Step 6) verified, no extra plumbing needed**:
  `apps/tenant-web/app/providers.tsx` creates a plain in-memory
  `QueryClient` via `useState(() => new QueryClient())` with no persister
  (no `persistQueryClient`/localStorage sync anywhere in `tenant-web` —
  confirmed by grep). A real F5 destroys the entire JS heap, so the
  `QueryClient` — and therefore any cached `useCurrentUser()` result — is
  always empty on a fresh page load regardless of `localStorage`
  contents; `useCurrentUser()`'s `useQuery` call (`features/auth/api.ts`)
  has no `staleTime` override, so even a warm-cache scenario would
  refetch on mount. No `staleTime: 0`/`refetchOnMount: "always"` addition
  was needed. Residual (out-of-scope) observation: logging out and back
  in as a *different* user *without* a full page reload (client-side
  `router.replace`, no reload) could theoretically show a
  stale-for-a-moment label, since logout doesn't call
  `queryClient.clear()` — this is a pre-existing gap in the session-switch
  flow unrelated to org-labels specifically (it would affect the header's
  cached user name too), not something this phase's file scope covers;
  flagged here rather than silently fixed or silently ignored.
- `pnpm --filter tenant-web lint` — clean. `pnpm --filter tenant-web
  build` — clean (`next build`, including static generation for
  `/host/programs`, the new skeleton route).

## Risks

- The School/Center bucket mapping is this plan's own inference from a
  4-value free-text field, not explicitly specified — flagged above and in
  `plan.md` Risks for user confirmation. **Resolved**: confirmed with the
  user before implementation (see Quality and Testing State above).
