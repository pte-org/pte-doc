# Phase 07 — DOCX regeneration and submission inspection

Status: Not started
Depends on: Phase 06 document validation and accepted dependent scope decisions
Stories: US-05, US-08

## Inputs and exact outputs

Read-only source templates:
- `template-doc/Report3_Software Requirement Specification.docx`
- `template-doc/Report4_Software Design Document.docx`
- `template-doc/Report5_Test Documentation.docx`
- `template-doc/Report6_Software User Guides.docx`

Generator: `pte-doc/tools/generate_report_docx.py`.
Canonical outputs in `pte-doc/report/docx/`:
- `FA26SE182_Report3_PTE-Prep_Software-Requirement-Specification.docx`
- `FA26SE182_Report4_PTE-Prep_Software-Design-Document.docx`
- `FA26SE182_Report5_PTE-Prep_Software-Test-Documentation.docx`
- `FA26SE182_Report6_PTE-Prep_Software-User-Guides.docx`
- Update `README.md` with baseline/revision/date/status and reproducible generation/inspection instructions.
Publication review: `pte-doc/plans/reports/YYMMDD-pte-prep-report-docx-publication-review.md`; evidence in matching assets directory.

## Steps

1. Inspect generator metadata before use. Its fixed Version 1.0 / 06 October 2026, shorthand cover and organization-only summary must be replaced by validated revision metadata or explicit metadata input. Read applicable coding instructions before future tooling edits.
2. Preserve shell/theme/page settings/logo, original heading hierarchy, tables, captions, TOC control and full registered title. Do not change original templates or invent supervisor approval.
3. Create required figure manifest from reports. Render Mermaid to actual image assets; prohibit source-text fallback from satisfying required-figure acceptance. Record renderer/version and errors; pinned reproducible tooling where adopted.
4. Generate all four DOCX from one validated Markdown baseline using the real generator command. Existing filenames stay stable unless an explicit documented output policy says otherwise.
5. Inspect OOXML for full title/revision/date/status, expected headings, logo/media relationships, figure count and captions; package parsing does not complete visual inspection.
6. Open/render all exports using available Word/LibreOffice/PDF tooling. Inspect covers/logo, every required figure, long tables and page breaks, margins/fonts, heading numbering, captions, non-English encoding in names and footer consistency. Record screenshots/pages with relative links.
7. Refresh Word TOC/page fields using an available tool; if unavailable keep honest cached-page policy and explicitly block submission-ready claim until visual/field verification completes. Do not invent pagination results.
8. Fix any publication defects and regenerate/reinspect affected files. Mark exports current only after the same baseline passes; preserve genuine earlier source templates and change history.

## Acceptance

Four new DOCX exist and are readable, original style and school logo retained, exact full title and correct revision/date visible. Every required diagram appears as a readable rendered figure; no generic filler or diagram source fallback remains. TOC reflects original section topology and current headings; page fields/layout inspected or publication explicitly withheld. Final receipt separates Markdown validation, package inspection and visual inspection results.

## Final handoff

Provide links to four DOCX and the scope gap handoff. State that documentation is revised against desired scope; practice implementation and runtime verification remain a separate later task.

## Design Constraints

- Preserve exact registered title, original DOCX TOC and canonical section filenames.
- Requirements, implementation evidence and approval remain independent fields.
- Draft independent content while D01–D03 remain open; block only dependent finalization. Supervisor confirmation remains pending without preventing authorized draft edits.
- No application source, migrations, configuration/deployment or production changes. Preserve unrelated edits and historical receipts.

## Quality and Testing State

Quality: not evaluated.
Testing: not started; document validation only; no inherited `--tdd`.
Optional phase check choices/outcomes: not selected; record during execution.

