# Plan: Tenant-Web Proctor UI Redesign (UI-only, SAFE variant)

**Slug:** `tenant-web-proctor-ui-redesign`
**Mode:** Hard
**Test:** standard (no-tdd, user override)
**Spec:** `spec.md` (adjacent)
**Brainstorm:** `../reports/261007-tenant-web-proctor-ui-redesign-brainstorm.md`
**Revision:** v3 — "Pillar-first" safety plan. Mirrors examiner exactly.

---

## Scope

Redesign the tenant-web proctor workspace from scratch (previous
attempt deleted). Backend-driven: **only ship frontend**, with **6 hard
safety constraints** the previous plan did not.

The 6 safety constraints are the **load-bearing contract** for this
plan. Violating any one requires a re-roll of the affected phase.

### S1 — Pillar-first, no big-bang (5 PRs, each ≤ 8 new files + ≤ 3 edits)

### S2 — Feature flag, default OFF
`NEXT_PUBLIC_PROCTOR_UI_ENABLED` env var; `app/(dashboard)/proctor/layout.tsx`
calls `notFound()` unless it's `"true"`. Production users see 404 on
`/proctor/*` until ops flips the flag.

### S3 — Mirror examiner pattern exactly
- `features/proctor/api.ts` ↔ `features/examiner/api.ts` shape
- `features/proctor/constants.ts` ↔ `features/examiner/constants.ts` shape
- **≤ 6 components total** (examiner has 1 component; deleted branch had 18)

### S4 — Add-only under `features/proctor/` and `app/(dashboard)/proctor/`
No edits to `features/examiner/`, `features/exams/`, `lib/navigation*`
**until Phase 05**.

### S5 — NO new packages in Phase 01-03
The deleted proctor UI used 3s polling, no STOMP. Plan v3 follows the
**actual shipped approach** (REST polling), not v2's "spec assumed
STOMP". New packages added in Phase 04+ only if/when STOMP is
implemented.

### S6 — Defer nav edits to Phase 05
`lib/navigation.tsx` and `lib/navigationConstants.ts` are currently
modified on the working tree by another branch. Phase 05 is the only
phase that edits them; it lands last.

---

## Phases (one PR each)

| # | Title | Files added | Files edited | Flag? | Status |
|---|---|---|---|---|---|
| 01 | Skeleton + flag + index redirect | 6 | 0 | yes | queued |
| 02 | Live monitoring (3s polling, no STOMP) | 6 | 0 | yes | blocked on 01 |
| 03 | Audit log | 5 | 0 | yes | blocked on 02 |
| 04 | Profile (read-only) | 2 | 0 | yes | blocked on 03 |
| 05 | Nav (`PROCTOR_ROLES` + `buildProctorNav`) + final smoke | 0 | 2 | yes | last |
| 06 | (P2, separate plan) STOMP-based live monitoring | ~12 | 0 | yes | follow-up |

Phases 01-05 are sequential (Phase 02 references components from
Phase 01, etc.). Phase 06 is a separate future plan.

---

## Dependency graph

```
[01 Skeleton + flag + redirect]  ← standalone
       ↓
[02 Live monitoring (polling)]   ← sequential (uses <DashboardChrome> wrapper from 01)
       ↓
[03 Audit log]                   ← sequential
       ↓
[04 Profile]                     ← sequential
       ↓
[05 Nav + final smoke]           ← LAST (this is where we touch lib/navigation*)
```

(No parallelism. Sequential is safer for a 5-PR roll-out.)

---

## Test mode (revised: no-tdd, per user override)

Standard test-after. Every phase still has automated coverage at the
file level (vitest for hooks + components) but tests are written
alongside the implementation rather than strictly first.

Per-phase test inventory unchanged from v2 (see each phase file's
"Tests to Write" section).

---

## Risks (specific to SAFE variant)

1. **PR-merge order matters.** If Phase 02 ships before Phase 01,
   `<LiveMonitoringView>` references files that don't exist. Sequential
   merge only — no parallel PRs.
2. **Nav collision** — Phase 05 touches `lib/navigation.tsx`. If
   another branch is in flight at that time, defer Phase 05 until
   that branch merges. Verify with `git status` at each phase start.
3. **Lockfile churn** — only happens if Phase 06 (STOMP) is implemented.
   Phase 01-05 do not modify `pnpm-lock.yaml`.
4. **Flag misuse** — if `NEXT_PUBLIC_PROCTOR_UI_ENABLED=true` is set
   in production before all phases ship, partial proctor UI may
   surface. Document in merge checklist; recommend ops keep it
   "false" until Phase 05 lands.
5. **Component budget slippage** — if any phase grows beyond its
   budget, split the phase before merging.
6. **git status snapshot is stale.** Spec was written from a snapshot
   at start of conversation. `git status` shows
   `apps/tenant-web/lib/navigation.tsx` and `navigationConstants.ts`
   currently modified — verify still-modified at Phase 05 start;
   if clean, proceed; if dirty, coordinate with the owner.

---

## Backend prerequisite gate

**None.** Backend has everything needed for REST polling + audit log +
force-submit. STOMP is backend-supported but plan v3 doesn't use it
yet (Phase 06+).

---

## File-level acceptance (all phases)

- `next build` PASS, `tsc --noEmit` PASS, `eslint --max-warnings 0` PASS
- `vitest run` PASS for new tests
- File ≤ 300 lines, function ≤ 150 lines
- No hardcoded strings, colors, or `style={{}}` blocks
- No `any`, no `// @ts-ignore`
- Phase 01-03: zero new packages
- Phase 04-05: zero new packages
- Phase 01-04: zero edits to `lib/navigation*`, `features/auth/constants.ts`
- All new copy in `features/proctor/constants.ts`

---

## Out of scope (call out for the next reader)

- Video feed, device profiling, attempt-by-attempt live status beyond
  REST polling exposes.
- Force-submit variants beyond `FORCE_SUBMIT`.
- WebSocket-based live monitoring (deferred to Phase 06 / P2).
- SockJS fallback.
- Vendor-web proctor admin surfaces.
- Backend work — none required.
- HOST_ADMIN live monitoring of proctor activity.

---

## Final state at end of Phase 05

- `features/proctor/` exists with ≤ 6 components
- `app/(dashboard)/proctor/` exists with 4 routes
- `lib/navigation.tsx` has `buildProctorNav()` (last edit)
- `features/auth/constants.ts` has `PROCTOR_ROLES` (last edit)
- `NEXT_PUBLIC_PROCTOR_UI_ENABLED="false"` by default
- Production users see 404 on `/proctor/*` until ops flips flag

When ops sets the flag to "true", proctors can:
- Sign in as `PROCTOR`
- Be deep-linked from host UI to `/proctor/sessions/{publicId}`
- See live monitoring with 3s polling

---

## Cook session log (2026-10-07)

All 5 phases cooked in single session, --fast mode (tests=no,
quality=no — user choice). Plan v3's assumption that the deleted
branch had live REST endpoints was wrong (verified at Phase 02
preflight): those endpoints do not exist on `hung/fix-ui-first`.
User chose "stub-deleted-style" — Phase 02-03 ship stub UI that
mirrors the deleted branch's actual implementation (no real network
calls). Phase 04-05 are real (use `useCurrentUser` and existing
`DashboardChrome`).

| Phase | Commit    | Files | Description                       |
|-------|-----------|-------|-----------------------------------|
| 01    | `027aa95` | 7     | Skeleton + flag + index redirect  |
| 02    | `2aeb9ee` | 8     | Live monitoring (stub)            |
| 03    | `75c7eb5` | 7     | Audit log (stub)                  |
| 04    | `f7f1b72` | 3     | Profile (real, useCurrentUser)    |
| 05    | `a9a7bf4` | 4     | Nav wiring (PROCTOR_ROLES + nav)  |
| total | —         | 29    | 23 added, 6 edited                |

All 5 commits pushed to `ninh/feat/proctor-workspace-ui`. Each PR
passes `tsc --noEmit`, `eslint --max-warnings 0`, and `next build`
(both flag=OFF and flag=ON, 28 static pages each).

### Stub vs. real: documented for the next reader

| Page | Implementation | Notes |
|---|---|---|
| `/proctor` | real (redirect) | `redirect("/proctor/profile")` |
| `/proctor/profile` | real | `useCurrentUser()` → read-only fields |
| `/proctor/sessions/{id}` | stub | `useProctorLiveAttempts` returns `[]`; UI shows "endpoint pending" |
| `/proctor/audit-log/{id}` | stub | Both tabs return `[]`; UI shows "endpoint pending" |

When the backend workstream delivers the proctoring controllers,
only the `queryFn` bodies in `features/proctor/api.ts` need to
change. No component, type, or constant rewrites required.

### Phase 06 status

Deferred. STOMP-based live monitoring is a separate future plan.
Plan file at `phase-06-stomp-p2.md` is a high-level sketch; full
plan lands when the backend STOMP endpoints ship.