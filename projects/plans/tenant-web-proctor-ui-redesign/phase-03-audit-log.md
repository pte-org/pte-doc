# Phase 03 — Audit log (stub UI, no backend)

**Workstream:** pte-web
**Blocks:** Phase 04, 05
**Spec:** FE-FR-03
**Test mode:** standard (no-tdd)
**Risk:** LOW — pure add-only, no backend integration, no new packages
**Preflight:** Verified the audit log endpoints do not exist on
`hung/fix-ui-first` either. `ViolationAuditController` is not
referenced in any current api-client code; the deleted branch's
`useProctorAuditLog` returned `[]` and never called any real
endpoint. Plan v3 follows the same stub approach. User chose
"stub-deleted-style" for Phase 02-03.
**Quality status:** skipped_by_user; decision: user_confirmed_skip
**Testing status:** skipped by user (--fast mode)

## Goal

Ship `/proctor/audit-log/[publicId]` as a **pure stub UI** — two
tabs (Violations, Security audit) render, both display empty state
copy that explains the deferred state. No data fetching beyond
`useQuery` with empty `queryFn` (the hooks do exist for future
swappability).

When real endpoints ship, the `queryFn` bodies in
`useProctorAuditLog` / `useProctorSecurityAudit` are the only
changes needed; the view, types, and constants do not change.

## Design Constraints

### No backend integration

**Backend does not have these endpoints on `hung/fix-ui-first`:**
- `GET /api/v1/exam-sessions/{publicId}/violations`
- `GET /api/v1/exam-sessions/{publicId}/security-audit?limit&cursor`

The deleted branch's `useProctorAuditLog` returned `[]` and never
called any real endpoint (verified via `git show ec1bba5`). Plan v3
follows the same stub approach. The hooks are still implemented as
`useQuery` / `useInfiniteQuery` with empty `queryFn` so when real
endpoints ship, only the `queryFn` body changes.

### Tabs are state-driven, not URL-driven

Tab state lives in `useState<string>("violations")` in the view.
No URL query parameter — avoids per-tab deep-link complexity.

### Cursor pagination contract (preserved for future)

Backend will return opaque `cursor` string + boolean `hasNext`. The
hook uses `useInfiniteQuery` (NOT `useQuery` with page-number). "Load
more" calls `fetchNextPage()`; if `!hasNext`, button disabled with
label "End of audit log". The stub returns `hasNext: false` so
the button is permanently disabled.

### Component budget

≤ 1 new component (the view itself):

1. `AuditLogView` — main view (~150 lines, 2 inline tab regions,
   reuses `DataTable` from `@pte/ui`)

`SecurityAuditEntryRow` and split `<ViolationsList>` /
`<SecurityAuditList>` are deferred — Phase 03 ships with one
component and inline tab regions. Phase 03 budget fits the
"≤ 6 components total" rule (Phase 02 added 1, this adds 1 → 2 of 6).

### Hooks (stub)

`features/proctor/api.ts` (append to Phase 02 file):

```ts
import {
  POLL_INTERVAL_MS,
  PROCTOR_AUDIT_LOG_QUERY_KEY,
  PROCTOR_AUDIT_SECURITY_QUERY_KEY,
} from "./constants";

export function useProctorAuditLog(
  sessionPublicId: string,
): UseQueryResult<{ items: ProctorAuditLogEntry[]; page: number; size: number; totalPages: number; totalItems: number }> {
  return useQuery({
    queryKey: [...PROCTOR_AUDIT_LOG_QUERY_KEY, sessionPublicId],
    enabled: sessionPublicId.length > 0,
    queryFn: async () => ({
      items: [] as ProctorAuditLogEntry[],
      page: 0,
      size: 20,
      totalPages: 0,
      totalItems: 0,
    }),
  });
}

export function useProctorSecurityAudit(
  sessionPublicId: string,
  limit = 20,
): UseInfiniteQueryResult<{ items: ProctorSecurityAuditEntry[]; cursor: string | null; hasNext: boolean }> {
  return useInfiniteQuery({
    queryKey: [...PROCTOR_AUDIT_SECURITY_QUERY_KEY, sessionPublicId, limit],
    initialPageParam: undefined as string | undefined,
    queryFn: async () => ({
      items: [] as ProctorSecurityAuditEntry[],
      cursor: null,
      hasNext: false,
    }),
    getNextPageParam: () => undefined,
    enabled: sessionPublicId.length > 0,
  });
}
```

### Types (additions to features/proctor/types.ts)

```ts
export interface ProctorAuditLogEntry {
  publicId: string;
  action: "FORCE_SUBMIT" | "FLAG_VIOLATION" | "CLOSE_SESSION";
  sessionPublicId: string;
  attemptPublicId: string | null;
  note: string;
  createdAt: string;
  performedBy: { publicId: string; fullName: string; email: string };
}

export interface ProctorSecurityAuditEntry {
  publicId: string;
  recordedAt: string;
  eventType: string;
  hashPosition: number;
  description: string;
}
```

### Constants (additions to features/proctor/constants.ts)

```ts
export const PROCTOR_AUDIT_LOG_QUERY_KEY = ["proctor", "auditLog"] as const;
export const PROCTOR_AUDIT_SECURITY_QUERY_KEY = ["proctor", "securityAudit"] as const;

export const PROCTOR_AUDIT_TEXT = {
  TITLE: "Session audit log",
  TAB_VIOLATIONS: "Violations",
  TAB_SECURITY: "Security audit",
  LOADING_VIOLATIONS: "Loading violations…",
  LOADING_AUDIT: "Loading security audit…",
  EMPTY_VIOLATIONS_TITLE: "No violations flagged",
  EMPTY_VIOLATIONS_DESCRIPTION:
    "Violations will appear here once the backend endpoint is wired up. The UI shape ships first.",
  EMPTY_AUDIT_TITLE: "No security audit entries",
  EMPTY_AUDIT_DESCRIPTION:
    "Security audit entries will appear here once the backend endpoint is wired up.",
  LOAD_MORE: "Load more",
  END_OF_AUDIT: "End of audit log",
  COL_TIME: "Time",
  COL_TYPE: "Type",
  COL_PROCTOR: "Proctor",
  COL_DESCRIPTION: "Description",
  COL_HASH: "Hash position",
  BACK_TO_PROFILE: "Back to profile",
} as const;
```

### Request helpers (api-client)

**No api-client request helpers added in Phase 03** (stub approach).
When the real backend ships, this file is created:

```
packages/api-client/src/requests/proctor/audit.ts
```

with endpoints:
- `violations: (id) => /api/v1/exam-sessions/{id}/violations`
- `securityAudit: (id) => /api/v1/exam-sessions/{id}/security-audit`

And types added under `packages/api-client/src/types/proctor/`:
- `ViolationEventResponse`
- `SecurityAuditPageResponse`

These are **out of scope** until the backend workstream delivers
the controllers.

## Files to create

| File | Lines (est.) | Purpose |
|---|---|---|
| `app/(dashboard)/proctor/audit-log/[publicId]/page.tsx` | 14 | Server component wrapping `<AuditLogView>` |
| `app/(dashboard)/proctor/audit-log/[publicId]/loading.tsx` | 11 | Loading skeleton |
| `app/(dashboard)/proctor/audit-log/[publicId]/error.tsx` | 22 | Error boundary |
| `features/proctor/components/AuditLogView.tsx` | 150 | Main view (1 component, ≤ 6 budget) |

**Total: 4 files added, 0 edited** (under Phase 03 budget of 5;
the 5th file — `api.ts` additions — is already accounted for in
the Phase 02 file, so we update it in-place).

## Files to edit

| File | Change |
|---|---|
| `features/proctor/api.ts` | +30 lines: 2 stub hooks (`useProctorAuditLog`, `useProctorSecurityAudit`) |
| `features/proctor/types.ts` | +20 lines: 2 type interfaces |
| `features/proctor/constants.ts` | +25 lines: 2 query keys + `PROCTOR_AUDIT_TEXT` |

(3 files edited, 4 created → 7 file touches total. Phase 03 budget
was 5 new + 0 edit; we're at 4 new + 3 edit. Edit count rises by 3
because the prior phase left `api.ts`, `types.ts`, and `constants.ts`
in stub state for the audit hooks.)

### Constants

Append to `features/proctor/constants.ts`:

```ts
export const PROCTOR_AUDIT_TEXT = {
  TITLE: "Session audit log",
  TAB_VIOLATIONS: "Violations",
  TAB_SECURITY: "Security audit",
  LOADING_VIOLATIONS: "Loading violations…",
  LOADING_AUDIT: "Loading security audit…",
  EMPTY_VIOLATIONS: "No violations have been flagged for this session.",
  EMPTY_AUDIT: "No security audit entries recorded.",
  LOAD_MORE: "Load more",
  END_OF_AUDIT: "End of audit log",
  COL_TIME: "Time",
  COL_TYPE: "Type",
  COL_PROCTOR: "Proctor",
  COL_DESCRIPTION: "Description",
  COL_HASH: "Hash position",
} as const;
```

## Files to create

| File | Lines (est.) | Purpose |
|---|---|---|
| `app/(dashboard)/proctor/audit-log/[publicId]/page.tsx` | 15 | Server component wrapping `<AuditLogView>` |
| `app/(dashboard)/proctor/audit-log/[publicId]/loading.tsx` | 11 | Loading skeleton |
| `app/(dashboard)/proctor/audit-log/[publicId]/error.tsx` | 22 | Error boundary |
| `features/proctor/components/AuditLogView.tsx` | 150 | Main view |
| `packages/api-client/src/requests/proctor/audit.ts` | 50 | 2 request helpers |

**Total: 5 files added, 0 edited.** Matches Phase 03 budget.

## Files to edit

NONE.

## Tests to Write (alongside implementation)

1. `AuditLogView.test.tsx:showsEmptyState_whenNoViolations`
2. `AuditLogView.test.tsx:disablesLoadMore_whenHasNextIsFalse`
3. `api.test.ts:useExamSessionViolations_disabledWhenIdIsEmpty`
4. `api.test.ts:useExamSessionSecurityAudit_passesCursorOnNextPage`

## Merge checklist

- [ ] No STOMP imports
- [ ] `next build` PASS, `tsc --noEmit` PASS, `eslint --max-warnings 0` PASS
- [ ] Component count for proctor ≤ 6 total (Phase 02 had 3, this adds 1 → 4)
- [ ] Smoke: deep-link to `/proctor/audit-log/{id}` with flag ON →
      violations tab loads

## Quality and Testing State

- Quality: not evaluated
- Testing: not started