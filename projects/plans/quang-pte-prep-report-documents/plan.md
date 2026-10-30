# Plan: Project-specific PTE Prep Reports 3–6

**Date:** 2026-10-06  
**Mode:** Hard  
**Test flag:** `--tdd`; documentation validation only, with RED/GREEN structural tests  
**Spec:** [`spec.md`](./spec.md)  
**Brainstorm:** [`../../../plans/reports/261006-pte-prep-report-documents-brainstorm.md`](../../../plans/reports/261006-pte-prep-report-documents-brainstorm.md)  
**Canonical output root:** `pte-doc/report/`

## Scope challenge

| Check | Result |
|---|---|
| Exists? | Generic Report 3–6 Markdown templates exist, but the project-specific split reports do not yet exist. |
| Minimum? | Create a shared documentation foundation, then one detailed Markdown file per major DOCX section for Reports 3–6, followed by cross-report validation. |
| Complexity? | **Hard** — four reports, many files, DOCX structure preservation, diagrams/assets, cross-report identifiers, source evidence, and status discipline. |
| Test mode | Default — run structural/content validation; do not add product tests because no product code changes are planned. |

## Plan decision

Use a hybrid sequence:

```text
Foundation and evidence ledger
    → Report 3 / SRS baseline
    → Report 4 / Design derived from Report 3
    → Report 5 / Tests derived from Reports 3–4
    → Report 6 / Guides derived from verified workflows
    → Cross-report vertical-flow review and validation
```

The original DOCX table of contents controls section order. The PTE Prep SRS controls business scope and terminology. Current and Partial labels require implementation/configuration/UI/API evidence; approved plans describe Planned/Future behavior unless they point to an existing implementation slice. Unresolved decisions remain TBD.

## Research synthesis

Two independent research passes agreed on the following:

- Establish a section map and stable identifier/evidence ledger before writing prose.
- Write Report 3 first because Reports 4–6 depend on its scope and IDs.
- Review the four high-risk vertical flows across all reports: organization onboarding, exam preparation/generation, Student delivery/proctoring, and scoring/review/publication.
- Treat the production backend as a Spring modular monolith, not as a public microservice fleet.
- Keep the six approved human roles and External Integration Services only.
- Mark numeric NFR values as targets/baselines unless current execution evidence exists.
- Keep contract-based retention, provider behavior, missing diagrams, and other unresolved decisions as explicit TBD items.

Research inputs were the approved spec/brainstorm, the PTE Prep SRS baseline, original `template-doc/Report3..6` DOCX files, existing report templates, and the approved modular-monolith, Student-exam-flow, Examiner-assignment, billing/integration, and anti-cheat plan files referenced by the research agents.

## Report-to-file map

The following files are the canonical output targets. Nested DOCX headings remain inside their parent Markdown file so the source report can be mapped one-to-one to the split set.

| Report | Source DOCX major section | Markdown file |
|---|---|---|
| 3 | Software Requirement Specification (document-level section II) | `report/report03/00-project-report.md` |
| 3 | Record of Changes | `report/report03/00-record-of-changes.md` |
| 3 | Product Overview | `report/report03/01-overall-description.md` |
| 3 | User Requirements | `report/report03/02-user-requirements.md` |
| 3 | Functional Requirements | `report/report03/03-functional-requirements.md` |
| 3 | Non-Functional Requirements | `report/report03/04-non-functional-requirements.md` |
| 3 | Requirement Appendix | `report/report03/05-requirement-appendix.md` |
| 4 | Software Design Document (document-level section II) | `report/report04/00-project-report.md` |
| 4 | Record of Changes | `report/report04/00-record-of-changes.md` |
| 4 | System Design | `report/report04/01-system-design.md` |
| 4 | Database Design | `report/report04/02-database-design.md` |
| 4 | Detailed Design | `report/report04/03-detailed-design.md` |
| 5 | Testing Documentation (document-level section II) | `report/report05/00-project-report.md` |
| 5 | Record of Changes | `report/report05/00-record-of-changes.md` |
| 5 | Scope of Testing | `report/report05/01-scope-of-testing.md` |
| 5 | Test Strategy | `report/report05/02-test-strategy.md` |
| 5 | Test Plan | `report/report05/03-test-plan.md` |
| 5 | Test Cases | `report/report05/04-test-cases.md` |
| 5 | Test Reports | `report/report05/05-test-reports.md` |
| 6 | Release Package & User Guides (document-level section II) | `report/report06/00-project-report.md` |
| 6 | Record of Changes | `report/report06/00-record-of-changes.md` |
| 6 | Deliverable Package | `report/report06/01-deliverable-package.md` |
| 6 | Installation Guides | `report/report06/02-installation-guides.md` |
| 6 | User Manual | `report/report06/03-user-manual.md` |

Each report also receives a mandatory `assets/` directory. A report-level index is optional and must not replace the section files. The `00-project-report.md` file maps the DOCX document-level `II.` heading and acts as the section-set cover/metadata page; it does not replace the detailed section files.

## Foundation artifact paths

Phase 01 creates these deterministic shared artifacts before the report prose:

| Artifact | Canonical path |
|---|---|
| DOCX-to-Markdown section map | `pte-doc/report/_foundation/section-map.md` |
| Actor/feature catalog | `pte-doc/report/_foundation/actor-feature-catalog.md` |
| Status/evidence matrix | `pte-doc/report/_foundation/status-evidence-matrix.md` |
| Cross-report ID ledger | `pte-doc/report/_foundation/id-ledger.md` |
| Open/TBD register | `pte-doc/report/_foundation/tbd-register.md` |
| Evidence record catalog | `pte-doc/report/_foundation/evidence-catalog.md` |
| Complete PTE task catalog | `pte-doc/report/_foundation/pte-task-catalog.md` |

Phase 06 writes its validation result to `pte-doc/report/_validation/report-03-06-validation.md`.

## Phase summary

| Phase | Purpose | Main outputs |
|---|---|---|
| 01 | Documentation foundation and section map | Section map, evidence/status catalog, ID ledger, TBD register, report directories/assets |
| 02 | Report 3 SRS | Requirements, actors, use cases, 12 feature groups, NFR, rules, messages, scope appendix |
| 03 | Report 4 design | Architecture, packages, database, detailed designs, diagrams/assets |
| 04 | Report 5 testing | Scope, strategy, plan, cases, evidence/report structure, traceability |
| 05 | Report 6 release/user guides | Package, prerequisites, installation/access, verification, workflows, troubleshooting |
| 06 | Cross-report review and validation | Vertical-flow review, link/ID/encoding scans, status/scope review, handoff report |

## Shared conventions

### Status vocabulary

- **Current:** supported by current source, configuration, or verified UI/API evidence.
- **Partial:** an existing slice is present but an end-to-end capability or safeguard is incomplete.
- **Planned/Future:** approved direction without current implementation evidence.
- **Out of scope:** deliberately excluded from the current product boundary.
- **TBD:** a decision or evidence item is still required.

### Identifier prefixes

| Area | Prefix | Example |
|---|---|---|
| Functional requirement | `FR-` | `FR-EXAM-001` |
| Non-functional requirement | `NFR-` | `NFR-PERF-001` |
| Use case | `UC-` | `UC-HOST-CREATE-EXAM` |
| Business rule | `BR-` | `BR-EXAM-023` |
| Common requirement | `CR-` | `CR-AUDIT-001` |
| Message | `MSG-` | `MSG-EXAM-004` |
| System/design decision | `SD-`, `ADR-` | `SD-ARCH-001` |
| Package/module | `PKG-` | `PKG-EXAM` |
| Database/entity | `DB-` | `DB-ATTEMPT` |
| Sequence/design interaction | `SEQ-` | `SEQ-ANSWER-SYNC` |
| Test objective/case/bug | `OBJ-`, `TC-`, `BUG-` | `TC-DELIVERY-014` |
| User workflow/step/image | `WF-`, `STEP-`, `IMG-` | `WF-HOST-PUBLISH-EXAM` |
| Evidence record | `EVD-` | `EVD-EXAM-GENERATION-001` |

### Evidence hierarchy

1. Current source, configuration, or verified UI/API behavior.
2. Approved PTE Prep SRS and brainstorm.
3. Approved plans and design/ADR documents.
4. Original DOCX for section order and presentation expectations only.
5. Generic Markdown templates for formatting ideas only.

### Evidence record format

Every material Current, Partial, Planned/Future, or TBD claim must reference an evidence record with:

- `EVD-*` identifier;
- status label;
- source path, route, configuration key, test result, plan/ADR, or decision reference;
- verification date;
- related actor/feature and report section;
- reviewer/owner;
- limitations, missing evidence, or reason the claim is not Current.

Report prose uses the evidence ID in a source/evidence note so later reviewers can reproduce the classification. A `Partial` claim requires evidence of an existing implementation/configuration/UI/API slice; a plan or ADR alone supports Planned/Future, not Partial.

### DOCX heading normalization

The original DOCX remains unchanged even when extraction exposes malformed characters. The section map records the raw source heading, normalized Markdown heading, and reason for normalization. For example, a heading containing Unicode replacement character `U+FFFD` is mapped to the intended English section title from the DOCX context and recorded as a normalization, rather than copied into final Markdown. The raw-source field is the only permitted place for the source replacement character; normalized headings and all report prose must be clean.

### Mandatory writing rules

- Use **PTE Prep** as the product name in all new report files.
- Preserve the independent practice/mock-exam disclaimer and do not claim PTE Academic affiliation, official certification, or research-based learning.
- Use only Platform Admin, Platform Author, Host, Proctor, Examiner, Student, and External Integration Services.
- Do not claim future or partial behavior is current.
- Do not leave generic template prompts, sample cafeteria content, fake credentials, private keys, or real environment values.
- Every diagram/table needs an ID, caption, status, evidence/source note, and linked requirement IDs.
- Report 3 must document the complete configured PTE task catalog in `_foundation/pte-task-catalog.md`: exactly 23 unique rows consisting of 22 named scored task types plus the unscored Personal Introduction, with per-task timing, response type, scoring/source behavior, Score Template relationship, and fixed-exam-version relationship.
- Report 7 and Vietnamese copies remain deferred.

## Quality gates for the full plan

1. **Structure:** Every original Report 3–6 document-level (`II.`) and major child section is represented exactly once and in order, including one `00-project-report.md` per report.
2. **Scope:** Roles, product disclaimer, organization-first model, Windows-first delivery, and out-of-scope decisions are consistent.
3. **Traceability:** Report 4–6 artifacts link back to Report 3 IDs; no duplicate or unresolved IDs.
4. **Assets:** Each report has a mandatory `assets/` directory; relative links resolve, or an explicitly described TBD asset/manifest is used.
5. **Encoding:** All files are valid UTF-8 with no replacement characters or accidental mojibake.
6. **Placeholder/content:** Generic template text and unsupported current claims are removed.
7. **Safety:** No credentials, tokens, private keys, `.env` values, or sensitive production data are written.
8. **Evidence honesty:** Test reports do not claim execution results without evidence; NFR numbers are targets unless verified.

## Phase dependencies

```text
Phase 01 ──→ Phase 02 ──→ Phase 03 ──→ Phase 04 ──→ Phase 05 ──→ Phase 06
                 │             │             │             │
                 └─────────────┴─────────────┴─────────────┘
                       shared IDs, scope, status, and evidence rules
```

## Handoff to `/ck:cook`

The plan is ready for implementation after the user reviews the phase boundaries and any unresolved policy assumptions. `/ck:cook` should execute phases in order. Before each phase it should confirm whether to run optional tests/quality checks; for this documentation-only work, the default checks are structural/content validation unless the user selects additional review.


## Cook execution progress

- [x] Phase 01 ? Documentation foundation and section map ? GREEN structural test and APPROVED quality gate.
- [x] Phase 02 ? Report 3 SRS ? GREEN structural test and APPROVED quality gate.
- [x] Phase 03 ? Report 4 design ? GREEN structural test and APPROVED quality gate.
- [x] Phase 04 ? Report 5 testing ? GREEN structural test and APPROVED quality gate.
- [x] Phase 05 ? Report 6 release/user guides ? GREEN structural test and APPROVED quality gate.
- [x] Phase 06 ? Cross-report traceability and validation ? GREEN structural test and APPROVED quality gate.

**Mode:** Hard with tests and quality enabled by explicit `--hard --tdd`.  
**Testing boundary:** documentation structure/content tests only; no product runtime code changed.


## Cook completion checkpoint

- Result: 6/6 phases implemented; all phase structural tests GREEN.
- Quality: 6/6 phase gates APPROVED; receipts issued under `quality/`.
- Final validation: PASS: 9, WARN: 0, BLOCK: 0.
- Runtime product tests: not run because this work package changes documentation only.
- Commit/push: not performed.
