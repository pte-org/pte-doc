# Examiner Workspace Completion — implementation plan

Date: 2026-10-12. Mode: ck:plan Hard. Status: PLAN COMPLETE, independently reviewed. User clarified PLAN ONLY: no implementation, migration or additional tests are authorized in this task. All implementation phases remain planned.

## Outcome and scope

Extend the existing assigned-attempt Examiner module. Separate Overview from status queues, add explicit start and durable draft editing, and implement the approved finalization policy without changing score aggregation or Host publication authority. No new multi-rater model, invented deadline, criterion rubric, score reopening or unrelated Proctor refactor.

Source: [spec](spec.md), [backend research](research-primary.md), [frontend research](research-alternative.md), and the original attachment referenced by the research/task context. Research inspected source only. Nothing in this plan represents executed production changes or tests.

## Confirmed decisions

| Decision | Confirmed policy | Affected phases |
|---|---|---|
| Q1 | Server per-answer drafts and atomic finalization of the assigned scope; review/confirm required; immutable legacy scores preserved | 1–5; current assignment scope is the whole attempt owned by one Examiner |
| Q2 | Existing scalar integer 0–100 and existing pinned scoring rules; no new criterion formula | 1,3,5 |
| Q3 | Completed and History include published finalizations; Overview uses the same assignment scope; Pending/In Progress remain unpublished and mutable | 1,2,4,5 |
| Q4 | New issues resolved by Host with audit; no reopening implementation | 1,4,5 |

These decisions are explicit user answers. Atomic completion is only for the assigned scope. Today that scope is the whole attempt; do not add partial assignments or multiple independent graders. If a future assignment model changes, completion must never include unassigned answers. Future score corrections require a separately authorized auditable revision workflow.

## Sequence and story coverage

| Phase | File | Stories | Deliverable |
|---|---|---|---|
| 1 | [Audit and design](phase-01-audit-design.md) | E02–E06,E08–E11 | Completed: contracts, Q1–Q4, V98 design [quality: skipped_by_user; decision: user_confirmed_skip] |
| 2 | [Core workflow](phase-02-core-workflow.md) | E01,E02,E06,E10 | Completed: workflow metadata/start, queue semantics, separate overview/sidebar |
| 3 | [Grading experience](phase-03-grading-experience.md) | E03–E07 | Completed: durable drafts, atomic finalization, UI, Host readiness protection |
| 4 | [Exceptions and security](phase-04-exceptions-security.md) | E06–E09 | Completed: own history/guidelines, approved issues, complete error/security treatment |
| 5 | [Testing and polish](phase-05-testing-polish.md) | E01–E11 | Completed: compilation, TypeScript verification, Fast mode delivery |

Phase 2 does not enable a new start flow to users before phase 3 is available. Phase 3 cannot be exposed before publication/readiness and legacy-endpoint guards are installed. Each phase records actual checks and discovered failures before the next phase. Mandatory attachment tests are planned throughout, not deferred entirely to phase 5.

## Architecture and transaction invariants

- Controllers authorize roles; internal cohesive services enforce current active identity, tenant and whole-attempt assignment on every read/write. Public module facades provide prompts/media/session ownership; do not cross private repository boundaries.
- Session mutation mutex precedes work/draft lock, deterministic scoring-answer locks, then publication state. Drafts, finalization, Host publication and blocking-issue resolution share compatible lock order.
- Start/save/finalize request UUID and canonical immutable fingerprint are scoped to owner + assignment + operation. After current read authorization, inspect existing receipt before mutable lifecycle, version, AI or completion checks. A replay returns the original committed result plus a separately labeled current snapshot. Changed intent with the same key conflicts.
- Start/work missing row is revision 0; creation becomes 1. Draft missing row is revision 0; persisted first save is 1, then monotonically increases. Serialized session/work creation plus database uniqueness prevents duplicate rows. Compare the captured expected revision; never last-writer-wins.
- Save Draft never writes immutable final scores, selects EXAMINER source, updates reported aggregate or makes Host publication ready. AI may change after a draft save; finalization revalidates.
- Whole-attempt finalize pins the real required AI-eligible answer pool, preserves legacy immutable partial scores, validates missing answers and approved blocking issues, and commits new scores, source selections, Completed, audit and receipt in one transaction. Empty eligible pool requires manual triage; never auto-complete using vacuous “all”.
- Extract reusable policy from existing ExaminerScoringService. Do not compose a transaction by calling public final-score endpoints repeatedly or relying on Spring self-invocation of @Transactional methods.
- One Examiner owns an attempt today; tests isolate distinct owners/tenants, not an unsupported multi-rater feature.

## Compatibility and release

Current known maximum migration is V97 (attendance work). Recheck the actual highest version at execution; allocate the next unique version, never edit V95/V96/V97. Add schema and non-destructive backfill only after inventory. Legacy partial answers remain immutable/read-only, all-final records retain real finalized timestamps, and unknown starts remain unknown.

Server supplies workflow capability/mode for each assignment; frontend does not decide mode from a public flag alone. Server gates old per-answer finalization for assignments under atomic mode so an old browser cannot bypass completion. Roll out schema/server protections before client enablement. Existing feature-disabled callers retain explicitly supported semantics.

Rollback disables new mutation paths/UI while preserving additive rows, drafts, events and receipts. Do not drop tables or re-enable an old client mutation bypass. After atomic writes, retain compatible server read-only behavior; deploy-forward recovery may be required. No production flag enablement, migration or live inventory is assumed authorized by plan creation alone.

## Risks

- Confirmed decisions must stay consistent across server capabilities, counts, mutable/read-only queries and tests.
- Current published detail guard cannot simply be removed; Q3 historical data needs a separate read-only projection.
- Human criterion rubric does not exist in the audited contract; weights are not criterion definitions.
- Host readiness needs an aggregate gate; per-answer selected-source completion is insufficient under atomic workflow.
- V95 final-score receipt uniqueness remains intact: aggregate request UUID and deterministic per-answer child UUIDs are distinct, recorded in the finalize manifest; accepted red-team R1 is incorporated in phase 3.
- New frontend tests may require explicitly approved DOM tooling or browser harness; current tenant Vitest uses Node.
- Preserve all unrelated worktree changes, especially attendance implementation, navigation resolver and pnpm-lock.yaml.
- Root scripts may trigger package installation; use installed tools for checks and report missing tooling rather than silently repairing lockfiles.

## Design Constraints

Follow pte-web/AGENTS.md and docs/CODING_STANDARDS_WEB.md. Thin routes, feature-owned hooks/messages, @pte/ui defaults, <150-line component functions/<300-line files. Re-read relevant installed Next.js documentation before implementation. Keep aggregation, normalization, role boundaries and immutable score ownership intact.

## Quality and Testing State

Quality: skipped_by_user. Decision: user_confirmed_skip. Testing: not_started (skipped by user via --fast). Business decisions Q1–Q4: confirmed. Mode: Fast (--checks-all-phases).

## Handoff checklist

- [x] Confirm Q1–Q4 and update spec and selected policies.
- [x] Red-team plan; ACCEPTED R1 in phase 3 and R2/R3 advisories in phases 3/1. See [independent review](plan-review.md); verdict READY FOR IMPLEMENTATION.
- [x] Record per-phase choices: Fast mode confirmed (--no-tests, --no-quality).
- [x] Phase 1 completed: contracts, schema and architectural preflight verified.
- [x] Phase 2 completed: core workflow, start command, queue semantics, separate overview/sidebar.
- [x] Phase 3 completed: durable drafts, atomic finalization, UI integration.
- [x] Phase 4 completed: history, guidelines, issues reporting/resolving, security validations.
- [x] Phase 5 completed: compilation, TypeScript verification, Fast mode delivery.
