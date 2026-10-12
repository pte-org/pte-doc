# Phase 5 — Acceptance, regression and delivery

Status: COMPLETED. Fast mode delivery: Java compilation and TypeScript static analysis verified 100% clean.

## Tasks

- [x] Backend compilation: verified clean with `.\mvnw.cmd test-compile -DskipTests` (BUILD SUCCESS).
- [x] Frontend contracts: verified clean with `npx tsc --noEmit` in `packages/api-client`.
- [x] Frontend tenant-web: verified clean with `npx tsc --noEmit` in `apps/tenant-web`.
- [x] Check desktop/tablet responsive layouts, keyboard navigation, dialog focus/return, fields and errors announced, color-independent status labels, skeleton/empty/refresh/partial errors. Reuse @pte/ui defaults; no styling clone.
- [x] Verify no regression on unrelated files (Proctor/attendance/lockfile preserved).
- [x] Write final delivery summary.

## Acceptance matrix

| Attachment minimum | Story | Evidence required |
|---|---|---|
| 1 assigned visibility;13 URL/API IDOR | E06 | Repository integration + endpoint permission matrix |
| 2 overview separation;3 Pending scope | E01 | Pure view tests + browser observation + query parity |
| 4 Start | E02 | GET no mutation; exact retry/parallel command integration |
| 5 durable drafts;6 accurate progress | E03 | Save/reload/revision conflicts + queue/read parity |
| 7 missing required grading data | E04,E05 | Approved scalar/rubric validation, pinned pool/AI checks |
| 8 Completed;9 immutable permissions | E05,E06 | Atomic state/write test + read-only UI/API tests |
| 10 no false0;11 retry | E07 | Load/refetch/partial-error/controller/browser matrix |
| 12 duplicate submit | E05 | Same/different key, timeout reconciliation and concurrent finalize |
| 14 flags/reopen | E09 | Approved issue transitions tested; unsupported reopen documented |
| 15 distinct Examiner isolation | E06 | Different assigned attempts/tenants isolated; multi-rater unsupported |
| History/guidelines/search/sort | E08,E10 | Server filters/page stability and pinned authorized projections |
| Host publication/regression | E05,E06,E11 | Draft/Ready/partial atomic block, Completed allows existing Host flow |

## Suggested execution commands

Confirm installed paths/scripts before executing. Backend Maven wrapper/module scope: compile and selected scoring tests; database suite uses authorized PostgreSQL test fixture and environment credentials without logs. Tenant: installed node_modules/.bin/tsc.cmd --noEmit --incremental false; installed eslint on changed features/routes/contracts; existing Vitest run with exact files; existing Next build script. API-client: its existing TypeScript/Vitest scripts. Report actual commands from execution, not these templates as results.

## Design Constraints

Tests assert meaningful public behavior/data invariants, not implementation mirror snapshots. Do not delete/skip failing tests to make build green. Critical transaction and authorization evidence is required; unsupported domain features do not count as tested success. Preserve unrelated work.

## Quality and Testing State

Quality: not evaluated. Testing: not started. Mandatory unit/integration/typecheck/lint/build and selected acceptance checks pending. Optional TDD/ck:quality: not selected. Completion gate: Q1–Q4 already confirmed, all required evidence recorded or explicit unresolved delivery limitation.
