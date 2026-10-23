# Phase 06 — Successor validation and later practice handoff

Status: Drafted 2026-10-22; static document validation recorded, product/runtime checks not run
Depends on: Phases 01–05; accepted answers for affected final checks
Stories: US-04, US-06, US-07, US-08

## Outputs

- New validation policy/data: `pte-doc/projects/plans/quang-pte-prep-report-scope-update/validation-manifest.json` and `validation-policy.md`.
- Successor document checker, if needed: `pte-doc/tools/validate_report_scope_revision.py`; preserve old completed-plan tests and receipts.
- Cross-report trace table in `pte-doc/report/_foundation/id-ledger.md` or linked `traceability-matrix.md`.
- Review: `pte-doc/plans/reports/YYMMDD-pte-prep-report-scope-validation.md`.
- Later implementation handoff: `pte-doc/plans/reports/YYMMDD-pte-prep-practice-implementation-gap-handoff.md`.
- Evidence under matching `pte-doc/plans/reports/assets/<report-name>/`.

These script/data outputs are FUTURE execution actions; no code/tooling edits occur while preparing this plan. Before tooling code changes read applicable root/docs rules. Existing coding documents cover Java/Dart/TypeScript; document the Python-tooling applicability review rather than pretending another language's rules fit. Read existing script conventions and applicable response/tenant rules only when relevant.

## Steps

1. Inventory old validators under `projects/plans/quang-pte-prep-report-documents/tests/`, especially `test_phase01_foundation.py`, `test_phase02_report03.py`, `test_phase05_report06.py` and `validate_report_bundle.py`. Catalogue obsolete Author/six-role/23-task assertions.
2. Build successor manifest from accepted scope: canonical roles, permitted legacy contexts, section map, channel/task catalogs, ID definitions/references, required figure IDs and baseline metadata. Avoid mere substring presence as semantic proof.
3. Validate original TOC preservation, English body, exact title, metadata, UTF-8, links/assets, unique definitions, legal repeated references and supersession closure.
4. Review vertical flows end to end: content review to exam generation; organization/entitlement; Student self-practice to AI/progress; Windows delivery/proctoring to Examiner assignment/Host publication.
5. Review requirement/evidence/approval independently; source-observed is not runtime verified. Validate no unauthorized Student feedback scope, invented performance measurements or registration approval.
6. Log issues and fix report defects before publication. D01–D03 still open => affected finalization blocked, not a silent PASS.
7. Handoff each practice gap with stable requirement/design/test IDs, current evidence and date, intended behavior, dependency/owner, acceptance and later priority. Cover AI explanation/provenance/status, truthful progress, context policy, task support and chosen Study-Pack behavior.
8. Separate documentation gaps from product gaps; only documentation defects block document completeness when genuine product incompleteness is clearly labeled.
9. Validate D04 across all four reports and include any missing question flags, editor/reviewer policy, eligibility-aware catalog/pool queries, generation constraints, defaults/migration and regression cases in the later implementation handoff. Check existing exam generation as well as practice: both consumers must honor their own flag, without modifying either consumer during this documentation package.

## Acceptance

Successor checks are reproducible and do not alter historical receipts. Every active material requirement traces to design/test/guide or documented non-applicability. Gap handoff is actionable for a separate practice implementation plan. No product feature implemented. Validation report states commands/results and exact limits; no runtime quality claim follows.

## Design Constraints

- Preserve exact registered title, original DOCX TOC and canonical section filenames.
- Requirements, implementation evidence and approval remain independent fields.
- Draft independent content while D01–D03 remain open; block only dependent finalization. Supervisor confirmation remains pending without preventing authorized draft edits.
- No application source, migrations, configuration/deployment or production changes. Preserve unrelated edits and historical receipts.

## Quality and Testing State

Quality: not evaluated.
Testing: not started; document validation only; no inherited `--tdd`.
Optional phase check choices/outcomes: not selected; record during execution.

