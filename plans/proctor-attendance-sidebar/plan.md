# Plan: Sidebar chức năng và điểm danh

Date: 2026-10-12. Mode: Hard. Status: ready for implementation handoff; product validation recorded. Implementation not started.

## Outcome and scope challenge

Existing: overview, assigned-session roster, batch identity/activity and query filters. Missing: attendance persistence/audit/commands and attendance/audit selector entries; sidebar matching is pathname-only. Minimum: reuse those surfaces, two attendance tables (current + immutable command/change log), read DTOs/API and explicit per-student actions. Complexity: cross-module reads, enrollment lifecycle and concurrent staff writes; five phases.

Inputs: [spec](spec.md), [primary](research-primary.md), [alternative](research-alternative.md), [review](plan-review.md). Spec quality PASS: P1/P2 stories, numbered requirements, measurable acceptance and all validation answers recorded.

## Validated behavior

- Both cards and sidebar expose role-allowed functions. Keep current overview/task routes; add assigned-session pickers for attendance and audit.
- Proctor new writes: SCHEDULED/OPEN and `opensAt-30m <= Clock.now < closesAt`, current enrollment and active assignment. No STOMP prerequisite. CLOSED read-only for Proctor; Host correction has mandatory reason/history. Cancelled remains read-only.
- Initial PRESENT/ABSENT permits optional note. Any status correction/reset requires reason; Host writes always require reason. Attendance never gates start, changes attempt/scoring/cohort or rewrites published results.
- Prior optional tests/quality skip preference retained. Compile/typecheck/build are planned; no tests or product changes in this planning turn.

## Phase checklist

- [x] [01 persistence and contracts](phase-01-attendance-persistence-contracts.md): current state, command receipts/history, safe roster/search contract. FR02–04,07,10–11. [quality: skipped_by_user; decision: user_confirmed_skip]
- [x] [02 atomic commands and lifecycle](phase-02-attendance-commands-lifecycle.md): locks, capability, versions, exact retry, reason validation. FR03–09. [quality: skipped_by_user; decision: user_confirmed_skip]
- [x] [03 sidebar and selectors](phase-03-sidebar-selectors.md): role menus, query-aware active state, valid card/selector links. FR01,12. [quality: skipped_by_user; decision: user_confirmed_skip]
- [x] [04 Proctor attendance UI](phase-04-proctor-attendance-ui.md): typed client/cache, roster, per-row writes, conflict/unknown reconciliation. FR02–05,07–12. [quality: skipped_by_user; decision: user_confirmed_skip]
- [x] [05 Host correction and delivery](phase-05-host-correction-delivery.md): exam detail tab/history and scoped verification. FR04,06–12. [quality: skipped_by_user; decision: user_confirmed_skip]

01→02→04→05. 03 follows read contracts in01 and can precede02; deliver only after all phases are integrated.

## Architecture decisions

1. Session owns state/commands; Proctoring composes identity/activity using public facades. Do not introduce Session→Attempt or Session→Proctoring cycles.
2. Stable key tenant/session/student, plus recorded enrollment UUID. Re-enrollment produces visible UNMARKED for a new membership, retains historical log and monotonic version. No cascading Enrollment FK; no repair-on-read.
3. Missing record has expectedVersion0; first saved version1, every real transition increments once. Reset does not delete the row. Compare enrollment UUID and version under session lock before new intent; avoid missing-row/first-write ABA.
4. Immutable AttendanceCommand log serves request receipt AND transition history, with changed=false for accepted no-op. User history displays status changes; no-op receipt avoids duplicate transition entries. Key scope `(tenant, session, actor, requestUUID)`; fingerprint includes student, enrollment UUID, expectedVersion, status, reason/note with identical canonicalization on save/retry.
5. Current actor/tenant/session read authority before receipt lookup. Exact receipt lookup precedes mutable time/version checks. Assigned Proctor may retrieve an own exact committed receipt after close with no new mutation; revoked access denies. Host retains authorized correction access. Return original receipt plus distinct current snapshot so a later correction is never disguised as original command success.
6. Session mutex → current authorization/membership → receipt lookup → new-write policy → attendance row; enrollment removal and assignment mutation use the same mutex. No network/media signing under mutation lock. Scoped same-session key makes insert serialization bounded; retain unique constraints and constraint-specific error mapping.
7. Name/email search must occur before pagination via a minimal Identity-owned staff-safe SQL read view joined by tenant/student, not fetching all student IDs or filtering a page. Identity defines safe view columns from actual schema; attendance repository consumes that published read contract, not Identity internal repositories. No HTTP endpoint exposes the view globally.

## Risks and review adjudication

- Research agents wrote source findings before failing due workspace credits; planner/review stages completed directly by root. No independent final plan-review agent result is claimed.
- Lock gap in unenroll accepted: use existing findOwnedWithLock without changing deletion/access behavior. Preserve subscription→session order; attendance never takes subscription locks after session.
- Historical enrollment generation must remain distinguishable from current membership. Host history can read removed-membership records; corrections target active current roster, not create an orphan enrollment.
- Explicit role context: Proctor routes apply PROCTOR policy even for multi-role users; Host routes apply HOST_ADMIN reason policy. No role-precedence shortcuts.
- SQL/view/query runtime and race behavior remain unverified if only compile checks are chosen. No deploy or data repair; any index only after measurement and explicit scope justification.

## Quality and Testing State

Quality: not evaluated; optional quality audit skipped under prior user preference. Testing: not started; tests/E2E skipped under prior preference. Document acceptance cases; run only agreed compile/typecheck/build after implementation. TDD may be selected later if user changes preference; do not re-ask declined checks.

## Handoff

```text
$ck:cook --hard D:/GitHub/PTE-org/pte-doc/plans/proctor-attendance-sidebar/plan.md
```

No implementation or rollout is performed by this plan-only request.
