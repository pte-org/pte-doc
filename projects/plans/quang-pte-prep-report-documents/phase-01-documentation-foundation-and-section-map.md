# Phase 01 — Documentation foundation and section map

## Objective

Create the shared foundation that prevents Reports 3–6 from drifting apart before any project-specific report prose is written. This phase fixes the DOCX-to-Markdown map, canonical paths, approved actor/feature catalog, status/evidence rules, identifier namespaces, asset convention, and unresolved-decision register.

## Inputs / Outputs

### Inputs

- [`spec.md`](./spec.md)
- [`261006-pte-prep-report-documents-brainstorm.md`](../../../plans/reports/261006-pte-prep-report-documents-brainstorm.md)
- `pte-doc/projects/pte-org-srs/spec.md`
- `pte-doc/projects/pte-org-srs/brainstorm.md`
- `template-doc/Report3_Software Requirement Specification.docx`
- `template-doc/Report4_Software Design Document.docx`
- `template-doc/Report5_Test Documentation.docx`
- `template-doc/Report6_Software User Guides.docx`
- Current generic templates under `pte-doc/projects/templates/`
- Currently available implementation, configuration, UI/API, plan, and design evidence; later report phases may append evidence records discovered during writing.

### Outputs

- `pte-doc/report/report03/` through `report06/` directories.
- One mandatory `assets/` directory inside each report directory.
- `pte-doc/report/_foundation/section-map.md` recording every original DOCX document-level and major child section and its Markdown target.
- `pte-doc/report/_foundation/actor-feature-catalog.md`.
- `pte-doc/report/_foundation/status-evidence-matrix.md`.
- `pte-doc/report/_foundation/id-ledger.md`.
- `pte-doc/report/_foundation/tbd-register.md`.
- `pte-doc/report/_foundation/evidence-catalog.md`.
- `pte-doc/report/_foundation/pte-task-catalog.md` with exactly 23 unique task rows.
- A cross-report identifier ledger for `FR`, `NFR`, `UC`, `BR`, `CR`, `MSG`, `SD`, `ADR`, `PKG`, `DB`, `SEQ`, `OBJ`, `TC`, `BUG`, `WF`, `STEP`, `IMG`, and `EVD` IDs.
- A TBD/open-decision register with owner, impact, and report references.
- A record of changes and project-report baseline for each report.

## Dependencies

- The approved spec and brainstorm must be available.
- The original DOCX files must remain readable and unchanged.
- The user’s requested root convention `pte-doc/report/report03..report06` is treated as the canonical output assumption.
- No final report content is generated until the section map and catalogs exist.

## Detailed Steps

1. Create the four canonical report directories and their `assets/` children without deleting or overwriting original templates or DOCX files.
2. Record the DOCX document-level and child headings in order:
   - Report 3: `I. Record of Changes`, `II. Software Requirement Specification`, then Product Overview, User Requirements, Functional Requirements, Non-Functional Requirements, Requirement Appendix.
   - Report 4: `I. Record of Changes`, `II. Software Design Document`, then System Design, Database Design, Detailed Design.
   - Report 5: `I. Record of Changes`, `II. Testing Documentation`, then Scope of Testing, Test Strategy, Test Plan, Test Cases, Test Reports.
   - Report 6: `I. Record of Changes`, `II. Release Package & User Guides`, then Deliverable Package, Installation Guides, User Manual.
3. Map `II.` to `00-project-report.md`, `I.` to `00-record-of-changes.md`, and each numbered child heading to the exact Markdown filename in `plan.md`; keep nested DOCX headings within that file.
4. When DOCX extraction exposes a malformed heading or Unicode replacement character (`U+FFFD`), preserve the raw source text in the section map, write a normalized English Markdown heading, and record the reason for normalization. Do not copy the replacement character into final report headings.
5. Record the six human actors and the External Integration Services integration actor. Explicitly record prohibited extra roles.
6. Record the 12 feature groups and the complete 23-task catalog (22 scored task types plus unscored Personal Introduction), including task timing/response types, score range, score-source behavior, Score Template relationship, and fixed-exam-version relationship.
7. Define the status vocabulary and create an evidence record format containing `EVD-*`, status, source path/route/configuration/plan/test/decision reference, verification date, related actor/feature/report section, owner/reviewer, and limitations. Require implementation/configuration/UI/API evidence for Partial; a plan or ADR alone supports Planned/Future.
8. Reserve stable ID namespaces, including `EVD-*`, and prevent reuse across files. Use a ledger rather than numbering independently in each file.
9. Define asset naming, caption, status, source, and relative-link rules. Missing diagrams receive a TBD entry instead of a fabricated image. `assets/` remains mandatory for every report, including Report 5.
10. Record unresolved items including contract-based retention, AI provider/quality thresholds, violation synchronization details, audience/generation recovery details, and any missing exam-client evidence.
11. Add `00-project-report.md` and `00-record-of-changes.md` to each report with the initial project-specific baseline entry and links to the source DOCX/spec.
12. Run a read-only inventory of existing templates and planned/source files to identify sample-domain text and misleading paths (for example, the Report 4 template located under a `report03` template directory). Record the hazard; do not rename unrelated existing templates in this phase.
13. Validate that the foundation itself is UTF-8, has no secrets, and contains no claim that the final reports are already complete.

## Acceptance Criteria

- [ ] All four report directories and mandatory `assets/` directories exist under `pte-doc/report/`.
- [ ] Each report has `00-project-report.md` and `00-record-of-changes.md` mapped to DOCX sections II and I.
- [ ] The section map represents every original DOCX document-level and child section exactly once and preserves order.
- [ ] Any malformed raw DOCX heading is preserved in the map with a normalized final heading and normalization reason.
- [ ] No original DOCX or generic template file is modified or deleted.
- [ ] The actor catalog contains exactly six human roles plus External Integration Services.
- [ ] The feature catalog contains the agreed 12 PTE Prep feature groups.
- [ ] `pte-task-catalog.md` contains exactly 23 unique rows: 22 named scored task types plus Personal Introduction, with timing, response type, scoring/source behavior, Score Template relationship, and fixed-version relationship for every row.
- [ ] The status/evidence matrix and evidence catalog define Current, Partial, Planned/Future, Out of scope, and TBD with reproducible `EVD-*` records.
- [ ] The identifier ledger defines prefixes including `EVD-*` and prevents duplicate IDs.
- [ ] Each report has a project-report cover, record-of-changes baseline, and mandatory asset convention.
- [ ] Foundation artifacts exist at the deterministic `_foundation/` paths listed above.
- [ ] TBD items include an owner/decision area and impact; they are not disguised as completed behavior.
- [ ] A placeholder/secrets/UTF-8 scan passes for all foundation files; a raw-source replacement character is allowed only in the documented raw heading field of `section-map.md`.

## Design Constraints

- Preflight: Existing `pte-doc` documents use UTF-8 Markdown with numbered section files, relative links, explicit status/evidence notes, and business-readable headings. This phase follows those conventions, writes only under `pte-doc/report/` and its test/plan paths, and leaves product code, source DOCX, and generic templates unchanged.
- Original DOCX files are structure references and must remain untouched.
- New documents use **PTE Prep**, not the legacy product name in generated headings.
- The output root follows the user-provided `pte-doc/report/` convention.
- Nested sections stay in their parent Markdown section file so the DOCX map remains reviewable.
- The foundation may record evidence and links but must not turn unverified code behavior into a requirement.
- No additional user role may be introduced.
- Report 7 and Vietnamese copies are not part of this phase.

## Quality and Testing State

- **Quality:** Not evaluated.
- **Testing:** Not started.
- **Planned checks:** filesystem/section-map check, UTF-8 scan, placeholder scan, secret-pattern scan, identifier namespace check.
- **Product runtime tests:** Not applicable unless product code is changed, which this phase forbids.

## Risks / Notes

- The existing template path for Report 4 is misleading; the canonical output path must not inherit that mistake.
- DOCX extraction can show sample content that is not PTE Prep evidence; only headings/order are authoritative at this stage.
- If a later phase discovers a missing top-level DOCX section, update the map before writing prose rather than silently adding an untracked file.
- The ID ledger must be maintained as requirements are added; re-numbering after cross-links exist creates avoidable breakage.

## Spec / User Story Mapping

- Spec: FR-01, FR-02, FR-03, FR-14, FR-15, FR-16, FR-17; NFR-02, NFR-03, NFR-05, NFR-07, NFR-12, NFR-13, NFR-19.
- User stories: P1 project-leader section fidelity; P1 stable actor model; P1 status/evidence discipline; P1 stable names/links; P1 English-first canonical output.


## Execution Notes

- Status: completed for cook Phase 01.
- RED/GREEN: `python tests/test_phase01_foundation.py` initially failed because the foundation/report outputs were absent; after implementation it returned `GREEN/PASSED`.
- Build Gate: Python syntax compilation passed for the documentation validators.
- Testing: passed under TDD verify; receipt at `quality/phase-01-documentation-foundation-and-section-map-receipt.json`.
- Quality: approved; report at `quality/phase-01-documentation-foundation-and-section-map-quality-report.json`.
- Outputs: foundation catalogs, four report directories, mandatory assets directories, and eight report baseline files.
