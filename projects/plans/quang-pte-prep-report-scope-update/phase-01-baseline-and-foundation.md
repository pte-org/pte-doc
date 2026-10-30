# Phase 01 — Baseline and shared foundation

Status: Drafted 2026-10-22; cross-report validation pending
Depends on: user scope decisions only for affected finalization
Stories: US-01, US-02, US-04, US-06

## Concrete outputs

Update these existing files under `pte-doc/report/_foundation/`:
- `section-map.md`: verify original Report3–6 DOCX document-level/major section order; retain canonical granular paths.
- `actor-feature-catalog.md`: eight roles, external services, four channels and resource/action allow/deny matrix.
- `status-evidence-matrix.md`: independent requirement decision, implementation evidence and approval fields.
- `id-ledger.md`: preserve IDs, add explicit old-to-new/superseded mappings and allocate new practice namespaces.
- `tbd-register.md`: D01–D03 with answers/status/date/owner, alternatives, dependent artifacts and closure evidence.
- `evidence-catalog.md`: dated registration/source/plan evidence and limits; no inherited runtime verification.
- `pte-task-catalog.md`: per-channel/variant support, source capability, intended scope and scoring/timing references.

## Steps

1. Inventory current files, headings and IDs; compare to originals `template-doc/Report3_Software Requirement Specification.docx`, `Report4_Software Design Document.docx`, `Report5_Test Documentation.docx`, `Report6_Software User Guides.docx`.
2. Record baseline date and draft revision identifier after inspecting existing report metadata; use one consistent new revision across the package. Keep actual old change records; do not backdate approval.
3. Define Platform Admin, Platform Manager, Academic Manager, Academic Staff, Host, Proctor, Examiner and Student, plus External Integration Services. Record Host ↔ HOST_ADMIN; legacy PLATFORM_AUTHOR ↔ ACADEMIC_STAFF compatibility.
4. Map resource actions explicitly: Staff drafts/submits; Academic Manager reviews/publishes/activates where permitted; Admin permissions source-backed; Platform Manager operations do not inherit unrestricted platform-account/settings or academic powers.
5. Preserve existing ID meanings; where Author-era responsibility changes a requirement's meaning allocate successor IDs and map impacted UCs/BRs/tests/guides. Do not silently transfer an Author ID.
6. Record channel boundaries: vendor, tenant, practice web, Windows exam client. Host exam mode “practice” differs from Student self-practice.
7. Add D01–D03 option impacts before answers; do not freeze task rows, shared identity ownership or pack completion prematurely.
8. Mark existing DOCX exports stale in `pte-doc/report/docx/README.md` when report edits commence; old validation receipts remain historical.
9. Record confirmed D04: question-level Practice Web and Windows Exam Client usage flags and automatic pool filtering. Distinguish task-family catalog, publication/visibility, channel eligibility and Student entitlement. Allocate stable rule/requirement IDs; record both-enabled reuse, flag-change review and historical-data defaults as proposals/open design items rather than inferred approvals.

## Acceptance

All seven foundation files have actionable project content; exact eight-role matrix includes rejection boundaries. Original headings map exactly once. ID migration distinguishes duplicate definitions from ordinary references. Decision rows identify what can proceed and what cannot be finalized. Catalog count derives from accepted D01 rather than an unconditional 23-row assertion.

## Design Constraints

- Preserve exact registered title, original DOCX TOC and canonical section filenames.
- Requirements, implementation evidence and approval remain independent fields.
- Draft independent content while D01–D03 remain open; block only dependent finalization. Supervisor confirmation remains pending without preventing authorized draft edits.
- No application source, migrations, configuration/deployment or production changes. Preserve unrelated edits and historical receipts.

## Quality and Testing State

Quality: not evaluated.
Testing: not started; document validation only; no inherited `--tdd`.
Optional phase check choices/outcomes: not selected; record during execution.

