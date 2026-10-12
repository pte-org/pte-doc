# Staff workspace overview — code review 2026-10-12

Scope: newly committed personal Proctor/Examiner overview implementation; backend commits 99fad2e and 19fe4ac, frontend commits 901ce1a and a99b6eb plus shared client contracts in current HEAD. Compared with `plans/hung-staff-workspace-overview/spec.md` and approved decisions: browser timezone, Today by local session opening date, Examiner completed unpublished assignments. Product source was not edited.

## Latest re-review — fixes 134db9e, 642ca13, 6657d16

The four original findings below are addressed in the inspected source. They are retained as history rather than current outstanding findings.

| ID | Current verification |
| --- | --- |
| R1 | DTOs and consumers use canonical backend fields accessible/upcoming/today, pending/inProgress/completed, eligibleAnswerTotal/finalizedAnswerTotal and priorityItems. Percentage is computed from actual totals. Optional old aliases do not replace the canonical fields. |
| R2 | Boundary source falls back to list.dayEnd; list response context is represented by the client type. Hook supports25-hour DST days with26-hour scheduling allowance and retains focus/visibility listeners for an already elapsed boundary. |
| R3 | Examiner status/page are derived directly from validated search params, so absent params reset to defaults. |
| R4 | Successful Proctor metadata detects an out-of-range page, corrects the URL and exposes a first-page recovery action rather than claiming the assignment scope is empty. Examiner also received page-bound correction. |

No additional actionable defect was confirmed in these fix paths and their adjacent contract/navigation/boundary code. This is a source-level result, not runtime reproduction or a guarantee that no further issues exist.

Fresh check: direct tenant TypeScript executable `tsc.cmd --noEmit --incremental false` exited0. Backend files/commits were unchanged in this fix scope; backend compile was not rerun in this re-review. No pnpm install, tests, application startup, SQL execution or browser/end-to-end checks were run. Product source was not edited.

The previously documented lockfile mismatch remains: packages/ui cmdk references the @types/react-dom19.2.3 peer variant while the matching snapshot is19.3.0. Installed TypeScript passing does not establish a successful frozen-lockfile install. Earlier backend plan gaps and UI acceptance limitations remain as documented below; they are not new runtime findings.

## Original findings — historical

### R1 — P1: Overview wire contracts disagree; cards show false zeros and Examiner priority disappears

Locations: `pte-web/packages/api-client/src/types/proctoring/index.ts:40`, `types/scoring/examiner.ts:49`; consumers `apps/tenant-web/features/proctor/components/ProctorWorkspaceOverview.tsx:73`, `features/examiner/components/ExaminerWorkspaceOverview.tsx`, `features/examiner/ExaminerQueueView.tsx:144`.

Backend Proctor emits counts `{accessible, upcoming, today}`. Frontend reads `{accessibleCount, upcomingCount, todayCount}`. Undefined counts are replaced with0, so every Proctor card shows0 even when the response has assigned work.

Backend Examiner emits counts `{pending,inProgress,completed}`, progress `{eligibleAnswerTotal,finalizedAnswerTotal}` and `priorityItems`. Frontend expects `{unstartedCount,inProgressCount,finalizedCount}`, `{totalUnits,completedUnits,percentComplete}` and `priorityQueue`. Its three cards show0, progress says no eligible units, and its priority section receives an empty array despite valid backend data. The request client directly returns JSON without an adapter, so TypeScript passing cannot repair these mismatches.

Align types/consumers with the actual records, or add one explicit wire-to-view adapter. Compute percent only from real numerator/denominator; do not fabricate empty data for missing fields. Verify actual nonzero payloads for both roles.

### R2 — P2: Proctor midnight refresh fails without overview or on long DST days

Locations: `pte-web/apps/tenant-web/features/proctor/components/AssignedSessionsView.tsx:89`, `hooks/useClientTimezone.ts:58`.

The boundary hook receives only overview.dayEnd, although the list has its own asOf/day bounds. If overview fails but Today list succeeds, no midnight timeout is scheduled; an active page keeps yesterday's list without the promised boundary update. The hook also exits before registering focus/visibility callbacks when the delay exceeds24h+1minute. Browser zones with a25-hour DST day can hit this condition early in the day, and never schedule their midnight update.

Use overview or independent list context, schedule from server asOf/dayEnd, and support actual timezone day length. Retain recovery listeners when the previous boundary has already elapsed; refresh before rescheduling. No repeated polling is required.

### R3 — P2: Removing URL filters does not reset Examiner local state

Location: `pte-web/apps/tenant-web/features/examiner/ExaminerQueueView.tsx:46–55`.

The effect synchronizes status/page only when the query parameter is non-null. Navigating back/forward from a filtered/paginated URL to `/examiner/work` leaves the previous local status/page active, even though the URL now specifies the defaults. Returning to a URL with status but no page can similarly retain a later page instead of0.

Derive validated state from search params directly, or always synchronize absence to the defined defaults. Keep navigation return/filter behavior consistent with the URL.

### R4 — P2: Out-of-range Proctor pages masquerade as an empty assignment scope

Location: `pte-web/apps/tenant-web/features/proctor/components/AssignedSessionsView.tsx:215`, pagination inside the nonempty branch at331.

There is no page-bound correction when totalPages shrinks or a deep link requests a later page. Empty page data selects the “no sessions” branch and hides pagination, even when meta.totalElements is positive and valid earlier pages contain work. Midnight changes or assignment removal can produce this scenario without a fabricated URL.

When successful metadata proves the current page is out of range, reset/clamp the URL page and refetch. Distinguish an empty scope from an empty requested page and keep a usable navigation/recovery action.

## Verification

- Cached offline Maven `-pl app -am -DskipTests compile`: BUILD SUCCESS; classes up to date, not a clean rebuild.
- Direct installed tenant TypeScript executable, `tsc.cmd --noEmit --incremental false`: exit0.
- Initial `pnpm.cmd --filter tenant-web exec tsc ...` detected a broken committed lockfile: packages/ui cmdk points to a peer variant absent from lockfile snapshots. pnpm automatically performed dependency reconciliation before executing the check. The resulting tracked lockfile content change was restored to HEAD without changing product code (`git diff --exit-code -- pnpm-lock.yaml` returned0). Installed dependencies were resynchronized by pnpm; a passing installed TypeScript check does not establish reproducible frozen-lockfile installation. Address that lockfile discrepancy separately before CI/release.
- No tests, app startup, database/native-query execution, browser or end-to-end checks were run. Runtime scenarios above are source-level proofs, not reproduced browser observations.

## Backend result and limits

No confirmed functional backend defect in the reviewed overview scope. Actor/tenant guards, Proctor day/window predicates, server Clock, bounded priorities, fetched session relations and Examiner unpublished scope are present.

Plan gaps: Examiner outstanding readiness is based on stored eligible/score counts instead of explicitly querying canonical outstanding answer rows; no actual contradictory normal-data scenario established. Unsupported Proctor sort silently falls back rather than controlled4xx. These are recorded without presenting speculative failures as release-blocking bugs.

Touched UI still has light-only styles and displays some raw machine errors/reasons; shared-component/locale/theme acceptance is not fully satisfied. Browser/accessibility verification remains unperformed.
