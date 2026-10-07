# Phase 02 — Live monitoring (stub UI, no backend)

**Workstream:** pte-web
**Blocks:** Phase 03-05
**Spec:** FE-FR-02
**Test mode:** standard (no-tdd)
**Risk:** LOW — pure add-only, no backend integration, no new packages
**Preflight:** Verified the deleted branch (`ec1bba5`) **did not** actually
integrate with backend live-monitoring endpoints. Its `features/proctor/api.ts`
imported `useAnswers` and `useSessions` from `features/exams/api.ts` — neither
file exists on `hung/fix-ui-first` (and did not exist on the deleted branch
either, confirmed by `git show ec1bba5:apps/tenant-web/features/exams/api.ts`
returning "path does not exist"). The deleted branch was a **stub UI** that
never compiled end-to-end. Plan v3 follows the same stub approach: ship the
UI structure with empty/static data; backend integration is a follow-up plan
that requires backend endpoints that do not exist yet on `hung/fix-ui-first`.
**User chose "stub-deleted-style"** in cook session for Phase 02-03.
**Quality status:** skipped_by_user; decision: user_confirmed_skip
**Testing status:** skipped by user (--fast mode)

## Goal

Ship the live monitoring view at `/proctor/sessions/[publicId]` as a
**pure stub UI** — page renders, layout is correct, components compile,
table headers and empty state show. No real data is fetched (backend
endpoints for live monitoring do not exist on `hung/fix-ui-first`).

This phase puts the **shape in place** so when backend endpoints ship,
Phase 02b (follow-up plan) can swap the stub data hooks for real ones
without restructuring components.

## Design Constraints

### No backend integration

**Backend does not have these endpoints on `hung/fix-ui-first`:**
- `GET /api/v1/exam-sessions/{sessionPublicId}/attempts`
- `POST /api/v1/proctor-sessions/{id}/commands`
- `POST /api/v1/proctor-sessions/{id}/violations`
- `POST /api/v1/proctor-sessions/{id}/close`

All Phase 02 data hooks return **stub values** (empty arrays, no
network call). When the real endpoints ship (separate backend
workstream), the hooks can be swapped to real ones without
restructuring the views.

This matches the **actual shipped approach of the deleted branch**
(`ec1bba5`) which also stubbed all of these — see its
`features/proctor/api.ts` "Optimistic: build a local entry immediately;
real network call will replace it when the endpoint ships" comment.

### Polling structure, no STOMP

Even with stub data, the `useQuery` shape uses polling-shaped
configuration (`refetchInterval: 3000`, `refetchIntervalInBackground:
false`). When the real endpoint ships, no caller-side changes
needed. STOMP remains deferred to Phase 06 / P2.

### Component budget

≤ 3 components in this phase:

1. `LiveMonitoringView` — main view (~150 lines, has 3 inline sub-
   regions; if it grows, split)
2. `LiveAttemptsTable` — table region
3. `ActionPanel` — force-submit + flag-violation buttons (UI only,
   no network)

If the view file exceeds 300 lines, split the Header region into
`LiveSessionHeader` (4 components total, still within budget).

### Hook shape (stub)

`features/proctor/api.ts` (Phase 02 deliverable). Stub hooks return
empty data with `isLoading: false` and `isError: false`:

```ts
import { useQuery } from "@tanstack/react-query";
import { usePollingInterval } from "./hooks/usePollingInterval";
import { POLL_INTERVAL_MS, PROCTOR_LIVE_ATTEMPTS_QUERY_KEY } from "./constants";
import type { ProctorLiveAttempt } from "./types";

/**
 * Live attempt list for a single session.
 * STUB: backend endpoint not available. Returns []. When the
 * per-attempt endpoint ships, replace the `queryFn` body with the
 * real fetch — call sites are unchanged.
 */
export function useProctorLiveAttempts(
  sessionPublicId: string,
): UseQueryResult<ProctorLiveAttempt[]> {
  const { refetchInterval, refetchIntervalInBackground } = usePollingInterval({
    intervalMs: POLL_INTERVAL_MS,
  });
  return useQuery<ProctorLiveAttempt[]>({
    queryKey: [...PROCTOR_LIVE_ATTEMPTS_QUERY_KEY, sessionPublicId],
    enabled: sessionPublicId.length > 0,
    refetchInterval,
    refetchIntervalInBackground,
    queryFn: async () => [] as ProctorLiveAttempt[],
  });
}
```

Stub action hooks are **omitted** for Phase 02 — the user said
stub-deleted-style, and the deleted branch had only one
optimistic-only mutation (`useCreateProctorAction`) that
exercised no network. We skip it to keep Phase 02 focused on the
view; the ActionPanel renders disabled buttons with explanatory
copy until a follow-up plan adds the real mutations.

### Constants

`features/proctor/constants.ts` (Phase 02 deliverable):

```ts
export const POLL_INTERVAL_MS = 3000;
export const PROCTOR_LIVE_ATTEMPTS_QUERY_KEY = ["proctor", "liveAttempts"] as const;
export const PROCTOR_LIVE_TEXT = {
  TITLE: "Live monitoring",
  LOADING: "Loading session attempts…",
  COL_ATTEMPT: "Attempt",
  COL_STATUS: "Status",
  COL_ELAPSED: "Elapsed",
  FORCE_SUBMIT: "Force submit",
  FLAG_VIOLATION: "Flag violation",
  CLOSE_SESSION: "Close session",
  ACTIONS_DISABLED_HINT: "Proctor actions are pending backend availability.",
  EMPTY_ATTEMPTS: "Live monitoring will populate once the backend endpoint is wired up.",
} as const;
```

### Types

`features/proctor/types.ts` (Phase 02 deliverable, minimal):

```ts
import type { UseQueryResult } from "@tanstack/react-query";

export interface ProctorLiveAttempt {
  attemptPublicId: string;
  studentPublicId: string;
  studentName: string;
  status: "PENDING" | "IN_PROGRESS" | "COMPLETED";
  startedAt: string | null;
  lastHeartbeatAt: string | null;
  flagged: boolean;
  notesCount: number;
}

export type { UseQueryResult };
```

### Request helpers (api-client)

**No api-client request helpers added in Phase 02** (stub approach).
When the real backend ships, this file is created:

```
packages/api-client/src/requests/proctor/live.ts
```

with endpoints:
- `attempts: (id) => /api/v1/exam-sessions/{id}/attempts`
- `commands: (id) => /api/v1/proctor-sessions/{id}/commands`
- `violations: (id) => /api/v1/proctor-sessions/{id}/violations`
- `close: (id) => /api/v1/proctor-sessions/{id}/close`

And types added under `packages/api-client/src/types/proctor/`:
- `ExamAttemptResponse`
- `IssueCommandRequest` / `IssueCommandResponse`
- `FlagViolationRequest` / `FlagViolationResponse`
- `CloseSessionRequest` / `CloseSessionResponse`

These are **out of scope** until the backend workstream delivers
the controllers. The Phase 02 stub `useProctorLiveAttempts` is
the only consumer in this phase; it imports only from
`@tanstack/react-query` and `features/proctor/types`.

## Files to create

| File | Lines (est.) | Purpose |
|---|---|---|
| `app/(dashboard)/proctor/sessions/[publicId]/page.tsx` | 15 | Server component wrapping `<LiveMonitoringView>` |
| `app/(dashboard)/proctor/sessions/[publicId]/loading.tsx` | 11 | Loading skeleton |
| `app/(dashboard)/proctor/sessions/[publicId]/error.tsx` | 22 | Error boundary |
| `features/proctor/api.ts` | 30 | Stub hook (1 useQuery, returns []) |
| `features/proctor/constants.ts` | 25 | `POLL_INTERVAL_MS`, query keys, `PROCTOR_LIVE_TEXT` |
| `features/proctor/types.ts` | 20 | `ProctorLiveAttempt` interface |
| `features/proctor/components/LiveMonitoringView.tsx` | 150 | Main view (3 inline sub-regions) |
| `features/proctor/hooks/usePollingInterval.ts` | 30 | Polling config hook |

**Total: 8 files added, 0 edited.**

If `LiveMonitoringView` exceeds 300 lines after implementation, split:
- extract `<LiveSessionHeader>` (component 2)
- extract `<LiveAttemptsTable>` (component 3)
- extract `<ActionPanel>` (component 4)
- still within ≤ 6 component budget from spec §6

## Files to edit

NONE.

## Tests to Write (alongside implementation)

1. `LiveMonitoringView.test.tsx:showsEmptyState_whenNoAttempts`
2. `LiveMonitoringView.test.tsx:pollsEvery3Seconds`
3. `api.test.ts:useExamSessionAttempts_disabledWhenIdIsEmpty`
4. `api.test.ts:useIssueProctorCommand_postsToCorrectEndpoint`

## Merge checklist

- [ ] `git status` shows no in-flight edits to `packages/api-client/src/types/`
- [ ] Component count ≤ 4 (this phase)
- [ ] No STOMP-related imports anywhere
- [ ] `next build` PASS
- [ ] `tsc --noEmit` PASS
- [ ] `eslint --max-warnings 0` PASS
- [ ] Smoke: deep-link to `/proctor/sessions/{id}` with flag ON →
      table populates within 5s (3s polling + 2s first request)

## Quality and Testing State

- Quality: not evaluated
- Testing: not started