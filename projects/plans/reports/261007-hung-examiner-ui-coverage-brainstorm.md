# Brainstorm: Examiner UI Coverage (bổ sung phase 03)

**Date:** 2026-10-07
**Author:** hung
**Slug:** `hung-examiner-ui-coverage`
**Skill:** `ck-brainstorm`
**Mode:** Strict (no implementation in this turn)

## Context

User request (paraphrased):

> Design + implement a dedicated UI for the `Examiner` role in the existing
> web application, scoped to what the backend actually supports. Don't
> rewrite the project, don't change the theme, don't invent features the
> API doesn't have.

## Existing-Code Fit

This brainstorm is **incremental on top of an already-shipped feature**:

- **Backend + frontend v1:** `projects/plans/quang-examiner-assignment-score-selection/`
  - `phase-01-scoring-foundation.md` — schema, entities
  - `phase-02-host-assignment.md` — host previews/commits examiner assignments
  - **`phase-03-examiner-workflow.md` — examiner queue + blind scoring UI** ✅ shipped
  - `phase-04-host-score-review.md` — host review + AI/Examiner source selection
  - `phase-05-report-publication.md` — host approval + publish
- **Frontend result of phase 03 (in `pte-web`):**
  - `apps/tenant-web/app/(dashboard)/examiner/work/page.tsx`
  - `apps/tenant-web/features/examiner/ExaminerWorkView.tsx` (370 lines)
  - `apps/tenant-web/features/examiner/api.ts` (3 TanStack Query hooks)
  - `apps/tenant-web/features/examiner/constants.ts`
  - `apps/tenant-web/lib/navigation.tsx::buildExaminerNav()`
  - `apps/tenant-web/features/auth/components/LoginView.tsx` (post-login redirect for EXAMINER)
  - `@pte/api-client/src/requests/scoring/examiner.ts` (3 endpoint wrappers)

**Phase 03 acceptance criteria were met** (per `quality/phase-03-examiner-workflow-quality-report.json` and `tests/phase-03-examiner-workflow-test-report.json` in the plan dir).

## User direction (from clarifying questions)

1. **Scope:** Examiner only. Do NOT touch PROCTOR or HOST_ADMIN UX.
2. **Depth:** Strictly mirror what the backend already exposes. No invented
   flows, no speculative stats, no extra pages.
3. **Backend gaps:** Document them in the report; do not code around them
   by mocking or guessing endpoints.
4. **Multi-role handling:** Strict — if a user logs in as `EXAMINER`
   (and is not also `HOST_ADMIN`), only the examiner UI renders. The
   existing `LoginView` post-login redirect already does this.

## Ideas Explored

### Idea A — "Build examiner from scratch"
Rejected. Phase 03 already shipped a working implementation. Wiping it
would violate "no destructive changes" and ignore 4 months of work.

### Idea B — "Add more examiner pages" (overview, history, profile, stats)
Narrowed to API-supported pages only. From the current API surface
(3 `EXAMINER`-scoped endpoints on `ExaminerWorkController`):

| Endpoint | Page |
|---|---|
| `GET /api/v1/examiner/work?status=` | `/examiner/work` ✅ exists, status filter param present |
| `GET /api/v1/examiner/work/{sessionPublicId}/{attemptPublicId}` | `/examiner/work/[sessionPublicId]/[attemptPublicId]` ❌ not present (the existing view uses `?session=...&attempt=...` query params instead) |
| `POST /api/v1/examiner/work/answers/{answerPublicId}/score` | submission form ✅ inline in `ExaminerWorkView` |

So Idea B narrows to: **route completion + boundary completeness**, not new pages.

### Idea C — "Polish the existing flow"
Accepted. Existing `ExaminerWorkView` is functional but the route is
missing boundaries that other dashboards have (rule #7 of `pte-web`).

| Gap | Impact | Phase 03 covered? |
|---|---|---|
| No `loading.tsx` at `/examiner/work` | Brief blank state during initial fetch | Not covered |
| No `error.tsx` at `/examiner/work` | API 500 leaves a half-rendered shell | Not covered |
| No `app/examiner/page.tsx` index route | `/examiner` returns 404 (login redirects to `/examiner/work`, but typing the prefix directly fails) | Not covered |
| Status filter wired? | API accepts `?status=ALL\|PENDING\|IN_PROGRESS\|COMPLETED`. Need to verify the view actually uses it. | Partially — constants define `EXAMINER_QUEUE_STATUSES`; whether the dropdown drives the param is unverified |
| Empty/loading state on attempt detail | When examiner picks an attempt that has 0 AI-eligible answers, what renders? | Not verified |

### Idea D — "Move details to a sub-route"
Considered splitting attempt detail out of the queue into
`/examiner/work/[sessionPublicId]/[attemptPublicId]`. The backend
controller **does** support path-style (`/api/v1/examiner/work/{s}/{a}`),
so the path is REST-correct. The current view inlines the detail panel.

Trade-off:
- **Pro:** browser back/forward, shareable URL, separate loading.tsx, easier
  empty/error state for detail.
- **Con:** 370-line view needs split, new files, refactor risk.

Decision: **defer to a future plan**. This turn focuses on boundary
completeness and minor polish. Refactor is a separate concern.

## User's Direction

> "cứ theo đúng luồng của back end đang có" — strictly follow what the
> backend exposes today.

Translation: **do not invent features**. UI is a faithful surface over
the three documented endpoints, on top of phase 03's shipped work.
Anything else is documentation, not code.

## Open Questions (Resolved)

| Question | Resolution |
|---|---|
| Does the existing view use the `?status=` param? | Verify during implementation; if not, wire it. |
| Is `ExaminerWorkView` over 300 lines after fix? | 370 → may need a sub-component split (within scope). |
| Should we move detail to its own route? | Defer; not in this turn. |
| Should there be an examiner profile / stats page? | No backend endpoint; out of scope. |

## Risks

1. **Scope drift into HOST_ADMIN territory.** Tempting to also build
   the missing `ExaminerAssignmentController` and `HostScoreReviewController`
   UIs because their API clients exist. **Resist.** User excluded
   HOST_ADMIN from this turn; phase 04 (host score review) is also
   someone else's workstream.
2. **PROCTOR confusion.** Git status shows new `proctor/**` pages being
   added (Oct 7). **Do not touch those.** Different role, different plan.
3. **Theme drift.** Don't introduce new tokens, colors, or fonts.
   Reuse `DashboardShell`, `PageHeader`, `EmptyState`, `LoadingState`,
   `ErrorState`, `PaginationControls`, `DataTable`, `StatusBadge`,
   `BackButton`, `Select` from `@pte/ui`.
4. **Re-implementing shipped work.** The phase 03 implementation must
   keep working. Test it before AND after.

## Backend Gaps (Documented, NOT Fixed in This Turn)

| Gap | Why it stays open |
|---|---|
| No `GET/PUT /api/v1/examiner/profile` | No backend endpoint; needs a backend ticket |
| No examiner analytics/thoroughput endpoint | No backend endpoint |
| No bulk score submission | By design: `ExaminerAnswerScore` is immutable |
| No examiner self-registration | Accounts created by HOST_ADMIN; by design |
| No real-time push for new work | No backend; relies on user opening the page |
| No examiner history endpoint (e.g. "what I graded last week") | No backend endpoint |

## Next Step

Write `spec.md` in this same directory and hand off to `/ck:plan` for
phasing. Implementation will only happen after the plan is approved.
