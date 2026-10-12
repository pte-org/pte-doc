# Exam Staff plan red-team and adjudication

Date: 2026-10-10. Scope: draft Markdown bundle, not implementation.

## Research

- Primary researcher inspected backend ownership, roles, assignment/progress contracts and missing Host queries.
- Alternative researcher inspected frontend/common boundaries and the requested local nextjs-admin-dashboard reference.
- Planner agent could not complete due to usage limit; the main agent wrote the draft directly. This limitation did not change feature scope.

## Independent review

Original verdict: WARN; no concrete HIGH/CRITICAL blocker established in the documented plan. At review time, three user validations still gated implementation; those product decisions have subsequently been confirmed.
Reviewer read plan Markdown only; this review does not independently prove current source contracts, SQL behavior, authorization or UI.

| Finding | Adjudication | Resolution |
| --- | --- | --- |
| Unavailable/inconsistent records need pagination/count reconciliation | ACCEPTED | spec Examiner semantics + phases 01/02/06: separate read-only exceptions page/total, technical query bucket, ALL includes them, totals reconcile |
| Examiner date filtering must name timestamp | ACCEPTED | spec + phase 01: session opensAt/closesAt interval overlap, same across overview/board/table/counts; no assigned/submitted fallback |
| Valid submission aggregation needs explicit eligibility/dedup predicates | ACCEPTED | spec + phases 01/02: name snapshot/pinned eligibility, submitted-state/soft-delete/key; test unrelated/duplicate answer rows |

## Verification boundary

Main-agent checks: seven phase files contain required Design Constraints, Quality and Testing State and acceptance gate; local Markdown links resolve.
All staff implementation phases: not started. Implementation quality: not evaluated. Tests/build for this future feature: not started.
Product decisions confirmed by the user's “ok”: dual-role tabs, profile edit whitelist, timezone policy. Technical contracts still gate implementation in Phase 01; implementation quality/testing remain unevaluated/unstarted.

No new staff production code, plan commit, push, deployment or database change in this planning step.
