# Phase 3: tenant-web — Exam Session UI (List, Create, Detail Shell)

## Requirements

`tenant-web` has zero UI for Exam Sessions today (confirmed by grep — zero
matches for "session" in any FE app), even though the backend
(`services/scheduling`'s `SessionController`) already has full
create/get/list. Every later phase in this plan (add students, manage
proctors) needs a session to attach to, so this is the foundational phase.
Scope confirmed via AskUserQuestion: build list + create (including the
blueprint→snapshot picker) + a detail-page shell that Phase 4/5 will add
tabs/sections into.

Maps to: `plan.md` Decision #5; Research Summary items 1, 5, 9.

## Design Constraints

- **New feature folder** `apps/tenant-web/features/exams/`, mirroring
  `apps/vendor-web/features/tenancy/`'s established structure
  (`types/`, `constants/`, `api/`, `components/`, `utils/`) — same
  react-query mutate→onSuccess→`setQueryData`+`invalidateQueries` pattern,
  same query-key-as-named-constant convention (this session's own prior
  refactor made every query key across `pte-web` a named constant — new
  code must follow that from the start, not add a fresh raw-string
  violation).
- **No backend changes in this phase** — `POST/GET /sessions`,
  `GET /sessions/{id}` already exist and already do exactly what's needed
  (confirmed in Research Summary item 1).
- **Create-session flow, exact shape** (per Research Summary item 5's
  documented gap): step 1, pick a `Blueprint` from `GET /blueprints`
  (list, already tenant-scoped by caller); step 2, if its `status` isn't
  already published in THIS flow's memory (i.e., every blueprint picked
  here always gets freshly published — there's no "already published,
  reuse it" path, per the documented gap), call
  `POST /blueprints/{id}/publish`, capture the returned
  `SnapshotResponse.publicId`; step 3, `POST /sessions` with that
  `snapshotPublicId` + the form's `name`/`opensAt`/`closesAt`. Present
  this as ONE guided modal flow (not 3 separate screens) — the user
  shouldn't need to understand the blueprint/snapshot distinction, just
  "pick your exam content, then set the schedule."
- **List page**: `DataTable` (reuse `@pte/ui`'s existing component, same
  as `_TenantTable.tsx`/`_LicenseTable.tsx` precedent) showing
  name/status/opensAt/closesAt, row click → detail page (`/host/exams/[publicId]`).
- **Detail page shell**: renders session name/status/schedule +
  `open`/`close` action buttons (`POST /sessions/{id}/open` /
  `/close` — both already exist, unused by any FE today, wire them here
  since they're clearly part of "manage this exam" and cost nothing extra
  once the detail page exists) + two placeholder section anchors
  ("Students", "Proctors") that Phase 4/5 fill in — build the shell with
  empty/TODO sections rather than leaving the page absent, so Phase 4/5
  are additive edits to an existing file, not new-file creation racing
  each other.
- **Nav hoist** (Research Summary item 9): create
  `apps/tenant-web/lib/navigation.tsx` (mirrors `apps/vendor-web/lib/navigation.tsx`,
  which tenant-web never had), export one `HOST_NAV: NavItem[]` with
  entries for Overview / Import Learners / Exams; update both existing
  page files (`host/dashboard/page.tsx`, `host/roster/page.tsx`) to import
  it instead of each declaring their own copy; new `host/exams/page.tsx`
  and `host/exams/[publicId]/page.tsx` import it too.

## Steps

1. `packages/api-client/src/types/scheduling/index.ts` (new) —
   `SessionResponse`, `CreateSessionRequest`, `BlueprintResponse`,
   `SnapshotResponse` (mirror the real backend DTOs read during
   investigation — field-for-field, not guessed).
2. `packages/api-client/src/requests/scheduling/sessions.ts` (new) —
   `createSession`, `getSession`, `listSessions`, `openSession`,
   `closeSession`, under `/api/scheduling/sessions...` (real gateway
   prefix, not the fictitious `/api/v1/host/...` this plan is replacing
   elsewhere).
3. `packages/api-client/src/requests/authoring/blueprints.ts` (new) —
   `listBlueprints`, `publishBlueprint`, under `/api/authoring/blueprints...`.
4. `packages/api-client/src/requests/index.ts`,
   `packages/api-client/src/types/index.ts` — add the two new barrel
   exports.
5. `apps/tenant-web/features/exams/types/index.ts`,
   `constants/index.ts` (query keys: `SESSIONS_QUERY_KEY`,
   `SESSION_QUERY_KEY`, `BLUEPRINTS_QUERY_KEY`; UI text constants), `api/index.ts`
   (`useSessions`, `useSession(publicId)`, `useBlueprints`,
   `useCreateSession` — the last one internally chains
   publish-then-create as described in Design Constraints, exposed to the
   component as a single mutation), `utils/validateCreateSession.ts`.
6. `apps/tenant-web/features/exams/components/`:
   `SessionTable.tsx` (list), `CreateSessionModal.tsx` (blueprint picker +
   schedule form, key-based remount convention per this repo's established
   modal pattern), `SessionDetailView.tsx` (shell: header + open/close
   actions + two empty section placeholders).
7. `apps/tenant-web/lib/navigation.tsx` (new) — hoisted `HOST_NAV`.
8. `apps/tenant-web/app/(dashboard)/host/exams/page.tsx` (new),
   `apps/tenant-web/app/(dashboard)/host/exams/[publicId]/page.tsx` (new).
   Update `host/dashboard/page.tsx` and `host/roster/page.tsx` to import
   `HOST_NAV` from the new shared file instead of declaring it inline.
9. No backend tests needed (no backend changes). Manual FE verification
   only for this phase (see Success Criteria) — `tsc`/`eslint`/`next build`
   clean across `tenant-web` is the automated gate.

## Success Criteria

- [ ] `/host/exams` lists sessions for the logged-in Host's tenant.
- [ ] Creating a session: pick a blueprint → publish happens automatically
      → session is created with the resulting snapshot → appears in the
      list without a manual refresh.
- [ ] `/host/exams/[publicId]` shows the session's name/status/schedule;
      Open/Close buttons change status and the page reflects it.
- [ ] `tsc --noEmit`, `eslint`, and `next build` are clean for `tenant-web`
      and `@pte/api-client`.

## Quality and Testing State

- Not started.
