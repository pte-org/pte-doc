# Phase 03 — Report 4 design derived from revised SRS

Status: Drafted 2026-10-22; dependent decisions and cross-report validation pending
Depends on: Phase 02 accepted requirement slices
Stories: US-03, US-04, US-06

## Files and outputs

Within `pte-doc/report/report04/` update:
- `00-project-report.md`, `00-record-of-changes.md`: synchronized revision metadata and actual changes.
- `01-system-design.md`: four-channel context/deployment, modular monolith ownership, role authorization, external services, source-observed versus proposed components.
- `02-database-design.md`: entity dictionary, ownership/cardinality, constraints, lifecycle/version provenance; classify observed entities separately from proposed ones.
- `03-detailed-design.md`: practice interactions, failure handling, contracts, state transitions, academic content/review, exam/scoring regression coverage.
- `assets/README.md`: figure manifest with caption/ID/source/status/requirement links; actual rendered figures at report asset paths.

## Steps

1. Trace each added/changed design to Report 3 IDs and evidence; retain modular-monolith architecture and distinguish current deployed topology evidence from desired practice channel design.
2. Model account/practice identity versus organization membership. D02 alternative A shows explicit org selection and per-org ownership; alternative B identifies replacement work needed for existing linkage. Never equate verified email with membership.
3. Preserve ClassMembership versus exam Enrollment; distinguish ExamSession/attempt/answer from PracticeSession/item/response/media.
4. Show practice state machine and authoritative timing; idempotent retry, stale version, owner checks, save-exit/resume and entitlement changes. Show media grant/upload/binding and no arbitrary URL acceptance.
5. Define proposed AI feedback component boundaries, asynchronous status/attempt handling where selected, stable answer linkage, question/rubric/provider/model/prompt/feedback version provenance, access checks and retriable versus terminal failures. Mark this solution proposed; never present invented schema as migrated.
6. Academic oversight states guidance/rubric ownership and content review responsibility; unresolved approval/escalation policy stays a named decision.
7. Update ERD with real cardinalities and relationship ownership; sequence diagrams cover login/context, entitlement/session, submission/media, AI feedback failure/retry and progress. D03 expanded packs would require explicit proposed entities; quick-group option does not create LMS completion entities.
8. Refresh retained exam-generation/form freezing, local save/sync, proctor incidents, Examiner assignment and publication designs wherever actor mappings change.
9. Model D04 as separate question usage flags and trace them through academic authoring/review and practice/exam pool queries. Both catalog readiness and actual selection must use channel eligibility; otherwise a runnable task can fail against an empty channel pool. Record source-backed versus proposed fields, no cross-channel fallback, fixed selected content and explicit default/migration/both-enabled reuse policies for later implementation.

## Acceptance

Every diagram renders and matches prose; no flowchart substitutes for ERD semantics. Actual entities/contracts have source references; proposed missing AI entities/contracts are labeled. No unexplained role assignment, ownership gap or conflation of practice scores with Host-published exam reports. D01–D03-sensitive designs stay provisional until answered.

## Design Constraints

- Preserve exact registered title, original DOCX TOC and canonical section filenames.
- Requirements, implementation evidence and approval remain independent fields.
- Draft independent content while D01–D03 remain open; block only dependent finalization. Supervisor confirmation remains pending without preventing authorized draft edits.
- No application source, migrations, configuration/deployment or production changes. Preserve unrelated edits and historical receipts.

## Quality and Testing State

Quality: not evaluated.
Testing: not started; document validation only; no inherited `--tdd`.
Optional phase check choices/outcomes: not selected; record during execution.

