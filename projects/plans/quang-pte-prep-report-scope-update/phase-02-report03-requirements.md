# Phase 02 — Report 3 requirements baseline

Status: Drafted 2026-10-22; dependent decisions and cross-report validation pending
Depends on: Phase 01; D01–D03 for affected finalization
Stories: US-01, US-02, US-03, US-04

## Files and required content

Within `pte-doc/report/report03/`:
- `00-project-report.md`: exact full title, draft revision/date, revised scope and approval state.
- `00-record-of-changes.md`: real added/modified/superseded scope, leader responsibility, actual reference/date.
- `01-overall-description.md`: four channels, eight actors, independent-product disclaimer; separate self-practice and organization exam context.
- `02-user-requirements.md`: actor goals, permission matrix, use cases, preconditions/main/alternate flows, postconditions, failure/ownership boundaries.
- `03-functional-requirements.md`: retained exam/platform features plus detailed Student practice and educational AI requirements.
- `04-non-functional-requirements.md`: security, accessibility/usability, response integrity, reliability/recovery, compatibility, observability and maintainability; targets versus measurement explicit.
- `05-requirement-appendix.md`: rules/messages/traceability, task/channel catalog, open decisions, glossary and exclusions.
- `assets/README.md` and affected diagram sources/assets: context, role/use cases and independent practice/exam flows.

## Required detail

Each material requirement: stable ID, actor, prerequisite, trigger, normal flow, alternate/error flow, postcondition, ownership/retained data, acceptance condition, requirement disposition and independent source evidence.

1. Preserve onboarding without payment in registration; package purchase/activation remains separate. Preserve content quality/review/versioning, bank/template generation/randomization, class versus exam enrollment, device constraints/local sync, Proctor incidents, Host-to-Examiner assignment, score-source selection and Host publication.
2. Practice sign-in: verified email/challenge expiry/invalid input/resend/limits; verification never auto-grants membership.
3. Explicit organization context and entitlement: unlocked/locked/ambiguous/unavailable, recheck on writes, revoked entitlement, ownership and history access rules. D02 governs final identity language.
4. Catalog eligibility: visible does not imply runnable; shared catalog decision D01 precedes final task timing/scoring promises. D03 governs Study-Pack depth.
5. Session: overview/begin/timer/draft/confidence/submit/skip/save-exit/resume/complete/discard/expire; repeat command, stale tab, deadline and network recovery. Confidence is self-assessment, not a score.
6. Recording upload and binding to correct owner/session/item; failed upload and safe retry independent from answer submission.
7. Objective/AI feedback: eligible answers, educational explanation grounded in question/rubric/response, pending/available/failure/unavailable/retry, preserved submitted answers, provenance and versions. Define output content and oversight without inventing provider accuracy or official equivalence.
8. Progress separates activity, confidence and scored performance. Missing score remains pending/unavailable rather than zero or fabricated improvement.
9. Student content-reporting actor/target/handler/status remains explicit pending decision if not resolved; Host support is not automatic coverage.
10. Define confirmed D04 question usage: separate Available for practice / Available for exam simulation flags; system selects only from the matching published, ready pool and valid task composition. Explain academic classification/review, excluded content, insufficient-pool errors and no silent cross-channel fallback. Flag edits apply to future selection; existing fixed content remains unchanged. Distinguish confirmed routing from proposed both-enabled reuse/default/migration policy.

## Acceptance

Every in-scope practice capability has testable acceptance and rejection/recovery paths. AI explanation is desired in-scope behavior with implementation gaps visible. Existing exam coverage survives revision. NFR numbers have method/workload/owner and target status or remain pending. All affected IDs allocated and migrated; dependent unresolved options cannot be phrased as settled requirements.

## Design Constraints

- Preserve exact registered title, original DOCX TOC and canonical section filenames.
- Requirements, implementation evidence and approval remain independent fields.
- Draft independent content while D01–D03 remain open; block only dependent finalization. Supervisor confirmation remains pending without preventing authorized draft edits.
- No application source, migrations, configuration/deployment or production changes. Preserve unrelated edits and historical receipts.

## Quality and Testing State

Quality: not evaluated.
Testing: not started; document validation only; no inherited `--tdd`.
Optional phase check choices/outcomes: not selected; record during execution.

