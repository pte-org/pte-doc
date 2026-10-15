# Spec: Tenant-Web Proctor UI Redesign (UI-only, SAFE variant)

**Slug:** `tenant-web-proctor-ui-redesign`
**Date:** 2026-10-07
**Author:** hung
**Skill:** `ck-brainstorm` → spec
**Builds on:** `com.pte.proctoring` package (Spring Boot, already shipped)
**Mode:** Strict spec — no implementation in this turn.
**Revision:** v3 — "Pillar-first" safety plan after user concern
about codebase stability.

---

## 0. Why this spec exists

The previous proctor UI (commit `ec1bba5` on
`origin/ninh/feat/proctor-workspace-ui`, **deleted by user**) added
**40 files in one PR** (15 routes + 18 components + 6 hooks + nav +
auth constants). The PR also added **WebSocket realtime** (deferred
from scope but architecturally scoped), and it didn't ship with a
feature flag — every PROCTOR user would have seen it immediately.

This spec redesigns the proctor UI under 6 hard constraints (next
section) that the v1+ v2 plans did not enforce.

---

## 1. Six Safety Constraints (load-bearing)

These are NOT nice-to-have. They are the contract this plan is written
against. Violating any one of them is a re-roll.

### S1 — **Pillar-first, no big-bang**

Each phase is one PR that:

- Touches **at most 3 directories**
- Adds **at most 8 new files** (boundary files count as 1)
- Edits **at most 3 existing files**
- Passes `next build` + `tsc --noEmit` + `eslint --max-warnings 0` before
  PR is marked ready for review
- Ships behind `PROCTOR_UI_ENABLED` flag (S6) so it cannot affect
  production users even if merged

5 PRs total. Each PR is independently reviewable and revertable.

### S2 — **Feature flag, default OFF**

Add `NEXT_PUBLIC_PROCTOR_UI_ENABLED` (string, "true" | "false", default
`"false"`). Server-side route group `app/(dashboard)/proctor/` is
**only mounted when the flag is true**. When false, visiting
`/proctor/*` returns 404 (the segment doesn't exist).

Mechanism: a layout file that checks the env var and `notFound()` from
`next/navigation`. This keeps the routes absent from the production
build's routing tree when disabled.

### S3 — **Mirror examiner pattern exactly**

Examiner phase03 (`projects/plans/quang-examiner-assignment-score-selection/phase-03-examiner-workflow.md`)
is the **single precedent** for this work. Any file in
`features/proctor/` follows the **exact same shape** as the analogous
file in `features/examiner/`:

| Proctor file (new) | Mirrors examiner file |
|---|---|
| `features/proctor/api.ts` | `features/examiner/api.ts` |
| `features/proctor/constants.ts` | `features/examiner/constants.ts` |
| `features/proctor/types.ts` | (no exact examiner equivalent; minimal) |
| `features/proctor/components/*.tsx` | `features/examiner/ExaminerWorkView.tsx` (single component, NOT 18) |

**Critically**: examiner kept 1 component (`ExaminerWorkView.tsx`).
The deleted proctor branch had 18 components. **Plan v3 keeps the
proctor surface to ≤ 6 components total.

### S5 — **No new external packages in phase 1**

Plan v2 added `@stomp/stompjs` to both `packages/api-client/package.json`
and `apps/tenant-web/package.json`. This **modifies `pnpm-lock.yaml`**
and could conflict with another branch in flight.

**Plan v3 splits:**

- **Phase 01-03**: ZERO new packages. Pure REST + TanStack Query +
  existing `@pte/ui` primitives. Same as examiner.
- **Phase 04 (live monitoring)**: add `@stomp/stompjs` in a SEPARATE
  PR, isolated to `packages/api-client/src/realtime/*`. Only after
  Phase 01-03 are merged and on `main`. This means the live monitoring
  feature is a **future plan** until that PR lands.

This is the key insight: **the previous proctor UI was 100%
REST-based + 3s polling** (per the deleted commit message: "live
monitoring with 3s polling"). STOMP was never actually used by the
discarded code. Plan v3 follows the **actual shipped approach**, not
the spec.md that I wrote in v1.

### S6 — **No edits to navigation.tsx/navigationConstants.ts in Phase 01**

The deleted proctor branch edited both files. `git status` shows
`apps/tenant-web/lib/navigation.tsx` and `navigationConstants.ts`
**at the time of writing this spec are modified on the working tree** —
meaning someone is currently working on them. Plan v3 defers all nav
edits to Phase 05 (last phase), so we don't collide.

Concretely, in Phase 01 we ship a working `/proctor` route, but the
sidebar nav still shows the host nav. Pro enters via deep-link only.
This is identical to the current state of examiner (which does not
appear in the sidebar for non-examiners but still works via deep-link).

### S4 — **Add-only under `features/proctor/`**

No edits to `features/examiner/`, `features/exams/`, `features/auth/`
beyond adding `PROCTOR_ROLES` (1 line) to `features/auth/constants.ts`
in Phase 05. Phase 01-04 add files only to `features/proctor/` and
`app/(dashboard)/proctor/`.

---

## 2. Personas & Roles (unchanged from v2)

| Role | Backend mapping | Can do |
|---|---|---|
| `PROCTOR` | `Role.PROCTOR` | Open proctor session, issue force-submit, flag violation, view audit log, change password |
| `HOST_ADMIN` | `Role.HOST_ADMIN` | Read audit log for any session in their tenant |

UI must enforce these same boundaries (defense in depth). Backend is
the source of truth.

---

## 3. Backend prerequisite: NONE

Same as v2. The previous proctor UI used **3s polling** against REST
endpoints that already exist. Plan v3 follows the same pattern.

- Live monitoring: REST polling at 3s (NOT STOMP). Matches deleted
  branch's actual implementation.
- Audit log: REST, both endpoints already exist.
- Profile: read-only from `useCurrentUser`.

**Backend workstream: 0.**

---

## 4. Frontend scope (P1 / P2 / P3)

`<!-- P1 = MVP (must ship), P2 = nice-to-have, P3 = out of scope -->`

### P1 — Route surface (4 routes total)

#### FE-FR-01: `/proctor` — Index landing

- Server component that `redirect("/proctor/profile")` (or
  `/proctor/audit-log` once Phase 03 lands, since deep-link entry means
  the proctor never logs in to "browse").
- Mirrors `apps/tenant-web/app/(dashboard)/examiner/page.tsx` exactly.

#### FE-FR-02: `/proctor/sessions/[publicId]` — Live monitoring (polling)

- Client component. **REST polling at 3s** (not STOMP).
- Three regions in one component (`<LiveMonitoringView>`):
  - **Header** — session metadata, polling status, "Close session" button.
  - **Live attempts table** — fed by `useExamSessionAttempts` polling
    hook; columns: attempt public id, status, started at, elapsed.
  - **Actions panel** — "Force submit" button per attempt;
    "Flag violation" button.
- All in 1 file (`<LiveMonitoringView>`) + 2-3 helper components
  (`<LiveAttemptsTable>`, `<ActionPanel>`, `<ElapsedTimer>`).

#### FE-FR-03: `/proctor/audit-log/[publicId]` — Post-hoc review

- Client component. `useQuery` against two endpoints:
  - `GET /api/v1/exam-sessions/{publicId}/violations`
  - `GET /api/v1/exam-sessions/{publicId}/security-audit?limit&cursor`
- Two tabs: "Violations" + "Security audit".
- Cursor-paginated load-more for security audit.

#### FE-FR-04: `/proctor/profile` — Read-only profile (P1, not P2)

- Read username, email, roles from `useCurrentUser`.
- No change-password in v3 (defer to P2).

### P1 — Cross-cutting plumbing

#### FE-FR-05: `PROCTOR_ROLES` in `features/auth/constants.ts`

- **ONE LINE addition** in Phase 05 (last):
  `export const PROCTOR_ROLES: SessionRole[] = ["PROCTOR"];`
- Until Phase 05 lands, the sidebar simply does not render any
  proctor items. Pro enters via deep-link.

#### FE-FR-06: App Router boundaries

Every route segment ships `loading.tsx` and `error.tsx`. Follow the
examiner pattern verbatim (verified from
`apps/tenant-web/app/(dashboard)/examiner/work/loading.tsx` and
`error.tsx`).

#### FE-FR-07: Constants and forbidden patterns

- New copy → `features/proctor/constants.ts` (mirror
  `features/examiner/constants.ts`).
- No hardcoded strings in JSX, no hardcoded colors, no inline styles,
  no `any`, no `// @ts-ignore`.

### P1 — Feature flag (`PROCTOR_UI_ENABLED`)

#### FE-FR-08: `app/(dashboard)/proctor/layout.tsx`

```tsx
import { notFound } from "next/navigation";

export default function ProctorLayout({ children }: { children: React.ReactNode }) {
  if (process.env.NEXT_PUBLIC_PROCTOR_UI_ENABLED !== "true") notFound();
  return <>{children}</>;
}
```

When the env var is "false" (default), every `/proctor/*` route
404s. Set `NEXT_PUBLIC_PROCTOR_UI_ENABLED=true` in `.env.local` to
opt in for development.

This **prevents the routes from being navigable in production** even
if merged, until the flag is flipped in the deployment environment.

### P2 — Nice-to-have

- Change password section on `/proctor/profile`.
- `PROCTOR_NAV_TEXT` + `buildProctorNav()` so proctors see proctor nav
  in the sidebar (currently they see host nav, which is fine).
- STOMP-based live monitoring (replaces 3s polling).

### P3 — Out of scope

- Force-submit variants beyond `FORCE_SUBMIT`.
- Video feed, device profiling, attempt-by-attempt live status beyond
  REST polling exposes.
- SockJS, WebSocket reconnect resilience beyond STOMP v1 defaults.
- Backend changes.
- Vendor-web proctor admin surfaces.

---

## 5. Route surface (final)

| Route | Purpose | Backend interaction | Behind flag? |
|---|---|---|---|
| `/proctor` | Index → `/proctor/profile` | none | yes |
| `/proctor/sessions/[publicId]` | Live monitoring (3s polling) | `useExamSessionAttempts` polling + `IssueCommandRequest` mutation | yes |
| `/proctor/audit-log/[publicId]` | Post-hoc review | REST list endpoints | yes |
| `/proctor/profile` | Read-only profile | `useCurrentUser` | yes |

**Removed vs. v2:**
- ~~boundary files for `/proctor/sessions` (list page)~~ — never
  existed in deleted branch either; pro enters via deep-link
- ~~STOMP wrapper~~ — deferred to P2 / Phase 04+

---

## 6. Component count budget (vs. deleted branch)

| Layer | Deleted branch | Plan v3 |
|---|---|---|
| `features/proctor/components/*.tsx` | 18 | ≤ 6 |
| `features/proctor/hooks/*.ts` | 1 (polling) | 1 (polling) |
| `features/proctor/api.ts` | 1 | 1 |
| `app/(dashboard)/proctor/**` routes | 15 files (5 routes × 3 each) | 10 files (4 routes × 2 each + index redirect) |
| **Total new files** | **40** | **~20** |

The deleted branch's bloat came from premature decomposition (18
components for what was effectively 3 logical regions). Plan v3 keeps
each region ≤ 1-2 components; the view itself is one file.

---

## 7. Phase plan (one PR each)

| Phase | Title | Files added | Files edited | Flag |
|---|---|---|---|---|
| 01 | Skeleton: 1 route + boundary + index redirect + 1 placeholder component | 6 | 0 | yes |
| 02 | Live monitoring (3s polling, no STOMP) | 6 | 0 | yes |
| 03 | Audit log | 5 | 0 | yes |
| 04 | Profile + nav constants | 1 | 0 | yes |
| 05 | `PROCTOR_ROLES` + `buildProctorNav` + final smoke | 0 | 2 | yes |
| 06 | (P2, separate plan) STOMP-based live monitoring | ~12 | 0 | yes |

**All phases ship behind `NEXT_PUBLIC_PROCTOR_UI_ENABLED=false` (default
OFF). Phase 05 is the gate: when Phase 5+6 of this plan and a future
"go-live" plan are merged, ops sets the env var to "true" in
production.**

---

## 8. File-level acceptance (all phases)

- `next build` PASS, `tsc --noEmit` PASS, `eslint --max-warnings 0` PASS
- File ≤ 300 lines, function ≤ 150 lines
- No new packages in Phase 01-03; new packages in Phase 04 only if
  decided at cook time
- No edits to `features/examiner/`, `features/exams/`, `lib/navigation*`
  until Phase 05
- All new copy in `features/proctor/constants.ts`
- Each PR is independently reviewable and revertable

---

## 9. Risks (specific to "safe" variant)

1. **PR-merge order matters.** If Phase 02 ships before Phase 01, the
   `<LiveMonitoringView>` references files that don't exist. The plan
   file ordering is sequential; cook must respect it.
3. **Nav collision** — Phase 05 edits `lib/navigation.tsx`. If
   another branch is in flight at that time, defer Phase 05 until
   the other branch merges. Verify with `git status` at each phase
   start.
4. **Lockfile churn** — Phase 04 (if STOMP lands) modifies
   `pnpm-lock.yaml`. Merge after any branch that touches lockfile.
5. **Flag misuse** — if `NEXT_PUBLIC_PROCTOR_UI_ENABLED=true` is set
   in production before all phases ship, partial proctor UI surfaces.
   Document this in the merge checklist.
6. **Component budget slippage** — if any phase grows beyond its
   6-component budget, split the phase before merging. Don't let
   bloat re-accumulate.

---

## 10. Acceptance — measurable (same as v2)

| Metric | Target |
|---|---|
| Build / typecheck / lint warnings | 0 |
| PR count | 5 (Phase 01-05) |
| File count | ≤ 20 new + ≤ 2 edited |
| Components | ≤ 6 |
| Edits to `lib/*` | ≤ 2 files, only in Phase 05 |
| Edits to `features/auth/constants.ts` | 1 line, only in Phase 05 |
| Manual smoke items | 6 (see phase-05 plan) |

---

## 11. Out of scope for this spec, listed for clarity

- Backend implementation (none required).
- STOMP migration to live monitoring (P2, separate plan).
- Vendor-web proctor admin surfaces.
- HOST_ADMIN live monitoring of proctor activity.
- Migrating `ExaminerWorkView.tsx` to `packages/ui`.