# Design review and validation receipt

Date: 2026-10-05. Scope: planning documentation only. No production code, tests, migrations, commits, pushes or deployment. Source heads inspected: API f070e38, web eafe3c8. Runtime gates remain not started.

## Independent HARD review

Reviewer inspected authoritative spec, research, coverage ledger, master and all seven phase files, with source checks for disputed contracts. Initial verdict: BLOCK for two contract contradictions; one precision warning. Main agent adjudicated against accepted business policies and current code, then requested a fresh review of the revised files.

| Finding | Disposition | Planning correction |
|---|---|---|
| R-01: count/category consent allowed changed SCHEDULED membership | ACCEPTED | Phase05 and master bind exact sorted SCHEDULED publicIds, effective code/subscription/tenant state and actor/resource in an authenticated short-lived digest; recompute under coherent locks. Added/removed/same-count replacement requires fresh preview and reset acknowledgements. OPEN/CLOSED stay informational and preserved. |
| R-02: DTO @Future could reject an already committed issuance replay | ACCEPTED | Phase04 requires structural validation/current authorization, then intent lookup, then dynamic eligibility/future-expiry validation only for a new intent. Remove outer/DTO prechecks that preempt replay. HTTP tests cover both admin and protected legacy routes after original expiry. |
| R-03: precision17/scale2 wording ambiguous | ACCEPTED | Phase03 specifies total precision19, scale2, maximum17 integer digits, matching current schema and boundary tests. |

Final re-review: PASS for documentation readiness; all three findings resolved, no remaining actionable planning findings. Reviewer freshly read revised contracts and confirmed45 unique IDs, all Not run. This receipt is not evidence of implemented atomicity, browser behavior or a passing test suite.

Main-agent documentation checks: seven phase files each contain Design Constraints and Quality and Testing State; coverage has45 unique IDs (12 APP,12 PLN,15 LIC,6 COM); local Markdown links resolve; diff whitespace check reports no errors (only Git LF/CRLF notices). API and web worktrees remain clean at verified heads. No compile, test, lint, build or browser execution was performed for this docs-only task.

## Policy validation already answered

The user accepted the recommended answers to the four material questions before plan creation:

1. New license issuance EXAM-only; retain legacy capacity and defer compensation.
2. Truthful approval/email wording plus existing authorized manual reset; no new durable email/invitation workflow.
3. New/edited Plans VND, EXAM duration1..3650; no silent legacy rewrite and capacity Plans remain valid.
4. REDEEMED EXAM revoke requires reason, explicit subscription/SCHEDULED confirmation; preserve OPEN/CLOSED and reconfirm changed scope.

Existing outstanding-code and ACTIVE-family lifecycle guards remain authoritative; no license snapshots. No additional business-policy interview is needed. Technical defaults are documented with phase01 verification gates, not presented as already implemented.

## Handoff boundary

Seven execution tasks remain unchecked. Test/quality consent for this new cook is pending; recommend unit tests and ck:quality for every phase, with TDD as an explicit optional choice. Historical lifecycle failures on906345c require fresh baseline on current heads. Approval of this plan does not start cook or authorize deployment.
