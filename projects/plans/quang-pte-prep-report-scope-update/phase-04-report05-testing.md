# Phase 04 — Report 5 verification plan and cases

Status: Drafted 2026-10-22; product execution remains not started
Depends on: Phases 02–03
Stories: US-03, US-04, US-06

## Files and content

Within `pte-doc/report/report05/` update:
- `00-project-report.md`, `00-record-of-changes.md`: draft revision and real change log.
- `01-scope-of-testing.md`: new role/channel/practice scope, exclusions and known gaps.
- `02-test-strategy.md`: functional/security/ownership/recovery/AI-content evaluation approach, data and environment boundaries.
- `03-test-plan.md`: prerequisites, responsibility, dependencies, entry/exit gates and decision-blocked cases.
- `04-test-cases.md`: detailed new and migrated cases.
- `05-test-reports.md`: current evidence versus planned execution, no fabricated runs.
- `assets/README.md`: traceability or explanatory test diagrams where useful.

## Case groups

1. Role allow/deny matrix for platform account/settings, operational organization review, content authoring/review/publication and template activation. Preserve tenant boundaries and Examiner/Proctor assignment.
2. Practice email challenge, expired/reused code and throttling; no-membership/multiple-context cases following D02.
3. Entitlement locked/unavailable/revoked, unauthorized owner/org reads/writes and history rules.
4. Catalog runnable/visible/unavailable and D01 task coverage; Study-Pack cases reflect D03 only after acceptance.
5. Session lifecycle/deadline, draft/save-exit/resume, submit/skip/expire/discard, concurrent tabs, repeated commands and recovery.
6. Recording binding to another Student/session/item, failed upload and retry.
7. AI pending/success/unavailable/failure/retry, duplicated callbacks/repeated work as design permits, answer preservation, provenance mismatch, educational explanation suitability and unauthorized access.
8. Progress activity versus confidence versus score; no completed-score assertion for pending feedback.
9. Regression coverage for content quality, exam generation/frozen forms, student sync, proctoring, Examiner work allocation, Host final score/publication.
10. D04 question-pool isolation: practice-only excluded from exams; exam-only excluded from practice; draft/unapproved/unready content excluded despite its flag; empty/insufficient channel pool produces a clear failure without cross-channel substitution. Check both/neither combinations against the explicitly recorded reuse policy, flag-edit permissions, consistent catalog readiness and preservation of existing content after flag changes. Default/migration cases require a documented policy first.

Each case records TC ID, linked FR/BR/design, actor, test data, prerequisites, steps, expected result, execution status and evidence reference. Unimplemented capabilities may have complete cases with status Not executed or Blocked by implementation; they are not scope exclusions.

## Acceptance

Every revised requirement has case coverage or justified applicability. No case is marked passed from static source inspection. Historical runs preserve date/baseline and are not rerun claims. Numerical NFR cases specify workload/environment/method before measured results. Report drafting runs no product tests.

## Design Constraints

- Preserve exact registered title, original DOCX TOC and canonical section filenames.
- Requirements, implementation evidence and approval remain independent fields.
- Draft independent content while D01–D03 remain open; block only dependent finalization. Supervisor confirmation remains pending without preventing authorized draft edits.
- No application source, migrations, configuration/deployment or production changes. Preserve unrelated edits and historical receipts.

## Quality and Testing State

Quality: not evaluated.
Testing: not started; document validation only; no inherited `--tdd`.
Optional phase check choices/outcomes: not selected; record during execution.

