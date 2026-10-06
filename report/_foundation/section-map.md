# PTE Prep Reports 3–6 — DOCX to Markdown Section Map

**Status:** Current foundation artifact  
**Owner:** Documentation work package  
**Source authority:** Original Report 3–6 DOCX heading order; project meaning comes from the approved PTE Prep SRS.

## Mapping rules

- The original DOCX files are unchanged.
- `00-project-report.md` maps the document-level `II.` heading and provides the cover, metadata, navigation, and report-level scope status.
- `00-record-of-changes.md` maps `I. Record of Changes`.
- Numbered files map the numbered child sections. Their nested DOCX headings remain inside the corresponding file.
- A malformed heading observed during DOCX extraction is recorded in the raw-heading column, then mapped to a normalized Markdown heading. The source replacement character is not copied into final report prose.

## Report 3 — Software Requirement Specification

| DOCX order | Raw source heading | Normalized Markdown section | Canonical file |
|---|---|---|---|
| I | I. Record of Changes | Record of Changes | `report03/00-record-of-changes.md` |
| II | II. Software Requirement Specification | Software Requirement Specification | `report03/00-project-report.md` |
| 1 | 1. Product Overview | Overall Description / Product Overview | `report03/01-overall-description.md` |
| 2 | 2. User Requirements | User Requirements | `report03/02-user-requirements.md` |
| 3 | 3. Functional Requirements | Functional Requirements | `report03/03-functional-requirements.md` |
| 4 | 4. Non-Functional Requirements | Non-Functional Requirements | `report03/04-non-functional-requirements.md` |
| 5 | 5. Requirement Appendix | Requirement Appendix | `report03/05-requirement-appendix.md` |

Nested Report 3 headings retained in their parent files include actors/use cases, system functional overview, screen flow/descriptions/authorization, non-screen functions, ERD, feature/function subsections, external interfaces, quality attributes, business rules, common requirements, messages, and other requirements.

## Report 4 — Software Design Document

| DOCX order | Raw source heading | Normalized Markdown section | Canonical file |
|---|---|---|---|
| I | I. Record of Changes | Record of Changes | `report04/00-record-of-changes.md` |
| II | II. Software Design Document | Software Design Document | `report04/00-project-report.md` |
| 1 | 1. System Design | System Design | `report04/01-system-design.md` |
| 2 | 2. Database Design | Database Design | `report04/02-database-design.md` |
| 3 | 3. Detailed Design | Detailed Design | `report04/03-detailed-design.md` |

Nested Report 4 headings retained in their parent files include architecture, package diagram, ERD/database constraints, class diagrams, and sequence diagrams for each feature/function.

## Report 5 — Testing Documentation

| DOCX order | Raw source heading | Normalized Markdown section | Canonical file |
|---|---|---|---|
| I | I. Record of Changes | Record of Changes | `report05/00-record-of-changes.md` |
| II | II. Testing Documentation | Testing Documentation | `report05/00-project-report.md` |
| 1 | 1. Scope of Testing | Scope of Testing | `report05/01-scope-of-testing.md` |
| 2 | 2. Test Strategy | Test Strategy | `report05/02-test-strategy.md` |
| 3 | 3. Test Plan | Test Plan | `report05/03-test-plan.md` |
| 4 | 4. Test Cases | Test Cases | `report05/04-test-cases.md` |
| 5 | 5. Test Reports | Test Reports | `report05/05-test-reports.md` |

Nested Report 5 headings retained in their parent files include objectives, in/out-of-scope requirements, assumptions, testing types/levels/tools, human resources, environment, milestones, test case record structure, execution summary, coverage, defects, and conclusion.

## Report 6 — Release Package & User Guides

| DOCX order | Raw source heading | Normalized Markdown section | Canonical file |
|---|---|---|---|
| I | I. Record of Changes | Record of Changes | `report06/00-record-of-changes.md` |
| II | II. Release Package & User Guides | Release Package & User Guides | `report06/00-project-report.md` |
| 1 | 1. Deliverable Package | Deliverable Package | `report06/01-deliverable-package.md` |
| 2 | 2. Installation Guides | Installation Guides | `report06/02-installation-guides.md` |
| 3 | 3. User Manual | User Manual | `report06/03-user-manual.md` |

Nested Report 6 headings retained in their parent files include release identification, system requirements, installation instructions, overview, workflows, support/troubleshooting/FAQ, screenshot inventory, and guide review checklist.

## Normalization record

| Source observation | Normalized output | Reason |
|---|---|---|
| DOCX text extraction produced a replacement character in a child heading under Requirement Appendix | Keep the intended English heading from its surrounding DOCX numbering and record the raw observation as `U+FFFD observed during extraction` | Final Markdown must be readable UTF-8; the source document remains the audit authority |
| Report 4 design template is stored under an existing `projects/templates/report/report03/` path | Use `pte-doc/report/report04/` for generated Report 4 files | Canonical output follows report number, not the legacy template path |

