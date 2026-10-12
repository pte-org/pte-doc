# Phase 2 — Core workflow and separate workspace views

Status: COMPLETED. Stories E01,E02,E06,E10. Fast mode execution.

## Tasks

- [x] Add approved workflow persistence/repos under scoring/domain and scoring/internal/repository; implement explicit start in ExaminerWorkflowCommandService with session-first lock, current identity/tenant/assignment/manual/publication/cohort checks.
- [x] After current read authorization, replay exact stored start receipt before mutable checks. Missing work revision 0 creates persisted revision 1 atomically with start event/receipt. Same key changed intent conflicts; repeated start new key follows explicit already-started result policy, never duplicates original start event.
- [x] Add controller DTO/response and server workflow capability to queue/detail. GET detail remains side-effect free.
- [x] Define authoritative status projection: Pending not explicitly started and no retained legacy progress; In Progress explicit start or partial legacy final, including valid-but-not-finalized Ready; Completed nonempty approved atomic finalization/all-final legacy. Expose readiness separately from queue status.
- [x] Update ExaminerWorkspaceReadRepository and fallback ExaminerWorkQueueRepository from shared predicates; overview counts, priority and lists use identical owner/scope. Draft answer counts and immutable final counts remain distinct.
- [x] Add server safe attempt/session identifier search, whitelisted stable sort with ID tie-breaker, filters before paging, max-page-size existing policy. Task/section filter only if actual pinned metadata permits EXISTS semantics without duplicate assignment rows. No inferred deadlines.
- [x] Preserve Q3 approved publication scope consistently across assigned total, status counts, progress numerator/denominator, priority, Completed and detail; include explicit scope/asOf contract.
- [x] Extend packages/api-client/src/requests/scoring/examiner.ts and types/scoring/examiner.ts with raw-object JSON request conventions; preserve old final-score endpoint contract for supported legacy mode.
- [x] Update features/examiner/api.ts/queryKeys.ts with authenticated subject+tenant keys and normalized status/search/sort/page fields; invalidate overview and queues after committed start.
- [x] Refactor thin app/(dashboard)/examiner/work/page.tsx and ExaminerWorkView into view-selection controller: no status -> overview-only; valid status -> queue-only. Remove dead selected-detail state.
- [x] Reuse ExaminerWorkspaceOverview/ExaminerPriorityWork; separate ExaminerOverviewView and status-scoped ExaminerQueueView compositions. Overview queries only overview/priority; queue queries only queue. Initial load/error do not manufacture totals.
- [x] Normalize invalid/legacy ALL query and page; retain canonical /examiner/work?status=... URLs, bookmarks/fromStatus/fromPage and explicit overview origin.
- [x] Extend lib/navigation.tsx/navigationConstants only as required; preserve attendance resolveActiveNavItem and Host classes/program override. Four workspace links visible, one active link including detail origin.
- [x] Add localized status-specific headers/actions/empty states. Pending “Start” invokes command; read-only open does not start; In Progress resumes, Completed reads. Resources added only in phase 4 when functional.
- [x] Add pure URL/view/active-nav tests and queue/start backend tests while implementing.

## Checks and acceptance

Unit/API wiring tests: exact raw JSON body, canonical URLs, no overview request/render on filtered queues, safe error states. Integration: only assigned owner/tenant sees rows; GET does not start; start retry and parallel start create one work/event; search/filter before pagination; count/list parity including legacy states and approved publication scope. Scoped lint/typecheck/compile before handoff. Do not enable full workflow while draft/finalization guards are missing.

## Design Constraints

Existing query-aware navigation is reusable; avoid four copied pages. Reuse @pte/ui and locale catalogs. Server is status authority. READY is not Completed; zero eligibility is flagged for triage. No client-filtered one-page “search” or unsupported task/deadline presentation.

## Quality and Testing State

Quality: not evaluated. Testing: not started. Required checks planned above. Optional TDD/ck:quality: not selected. Dependencies: phase 1; Q1/Q3 confirmed; phase 3 gate before user cutover.

Planning preflight: existing query URLs and locale hooks, @pte/ui defaults, SessionService mutex and public scoring DTOs; preserve user attendance/navigation/lockfile changes. contracts.md is a proposed backend/frontend handshake. No phase execution or check choices activated.
