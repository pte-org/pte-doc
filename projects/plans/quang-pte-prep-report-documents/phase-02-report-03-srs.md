# Phase 02 — Report 3: Software Requirement Specification

## Objective

Create the project-specific English Report 3 set as the canonical business and requirement baseline for PTE Prep. The content must preserve the original DOCX sections while replacing generic template instructions with detailed requirements, use cases, business rules, interfaces, targets, messages, scope boundaries, and explicit evidence/status labels.

## Inputs / Outputs

### Inputs

- Phase 01 section map, ID ledger, actor/feature catalog, evidence/status matrix, and TBD register.
- `pte-doc/projects/pte-org-srs/spec.md` and `brainstorm.md`.
- Current source/configuration/UI/API evidence for onboarding, tenant access, content, scoring, packages, exams, delivery, proctoring, Examiner work, reports, and audit.
- Approved plans/ADRs for exam generation, scoring, Student delivery/timer, lockdown/anti-cheat, Examiner assignment, billing/integration, and report/question workflows.
- `template-doc/Report3_Software Requirement Specification.docx` for section order only.

### Outputs

- `pte-doc/report/report03/00-project-report.md`
- `pte-doc/report/report03/00-record-of-changes.md`
- `pte-doc/report/report03/01-overall-description.md`
- `pte-doc/report/report03/02-user-requirements.md`
- `pte-doc/report/report03/03-functional-requirements.md`
- `pte-doc/report/report03/04-non-functional-requirements.md`
- `pte-doc/report/report03/05-requirement-appendix.md`
- Report 3 diagrams/assets or explicit TBD placeholders.
- Updated foundation ledger with all Report 3 IDs.

## Dependencies

- Phase 01 must be complete and its section map/ID conventions frozen for this pass.
- The product name and role list are already approved.
- Current and Partial claims require implementation/configuration/UI/API evidence; Planned/Future claims may reference approved plans/ADRs; unresolved policy decisions remain TBD.
- Report 4, 5, and 6 content may reference Report 3 IDs only after this phase’s IDs are stable.

## Detailed Steps

1. Write the record of changes with document metadata, source DOCX, baseline version, owner, date, and a project-specific-content change description.
2. Write **Overall Description**:
   - define PTE Prep as an organization-based PTE-style practice and mock-exam platform;
   - state the independent-product/no-PTE-Academic-affiliation boundary;
   - describe organization web portal, platform administration portal, and Windows-first exam client;
   - describe the organization-first package/usage model and why registration is separate from package activation;
   - describe the exam lifecycle from onboarding through report publication;
   - define terminology such as Organization, Host, Student attempt, fixed exam version, Score Template, publish, audit log, and retry;
   - list assumptions, constraints, out-of-scope boundaries, and success indicators without claiming unsupported delivery.
3. Write **User Requirements**:
   - define responsibilities, knowledge, channel, data scope, and boundaries for Platform Admin, Platform Author, Host, Proctor, Examiner, Student, and External Integration Services;
   - state that External Integration Services is not a login role;
   - describe tenant isolation, assignment restrictions, Student self-visibility, and Platform Admin platform-wide authority;
   - define use cases for onboarding, content, exam setup/delivery, proctoring, scoring, reporting, and integration failures;
   - identify main/alternate/error flows and link them to `UC-*` IDs.
4. Write **Functional Requirements**:
   - define a system functional overview, screen flow, screen descriptions, authorization, non-screen functions, and ERD/diagram references;
   - cover all 12 PTE Prep feature groups: onboarding; organization/learner/class/enrollment; shared question/media; score templates; packages/payment/limits; exam setup/validation/generation/scheduling; Student delivery/submission; proctoring/integrity; Examiner assignment/scoring; reports/publication/audit; external integrations; generation/platform hardening;
   - give each requirement a stable `FR-*` ID, actor, precondition, behavior, alternate/error handling, data effect, authorization, status, and acceptance condition;
   - explicitly document local-first answer saving, retry/recovery, fixed exam snapshots, duplicate/conflict checks, score-source review, and publication blocking;
   - distinguish current code behavior from planned AI scoring or advanced anti-cheat behavior.
5. Write **Non-Functional Requirements**:
   - document browser/web-client, Windows exam-client, API, media, payment, AI, notification, and operational interfaces;
   - record performance/capacity/availability/recovery numbers as baseline targets with verification status, not as achieved proof;
   - describe security, tenant isolation, auditability, data protection, accessibility/usability, compatibility, deployment, integration resilience, and contract-based retention;
   - assign `NFR-*` IDs and link targets to test objectives in Report 5.
6. Write **Requirement Appendix**:
   - define `BR-*` business rules for approval, permissions, tenant ownership, package limits, fixed versions, enrollment conflicts, answer acceptance, retries, proctoring, Examiner score source, publication, audit, and integration errors;
   - define `CR-*` common requirements and `MSG-*` application messages with trigger, audience, action, and severity;
   - record assumptions, other constraints, retention TBD, provider TBD, and open decisions with owners/impact;
   - repeat out-of-scope decisions in a traceable table.
7. In `00-project-report.md`, map the DOCX document-level `II. Software Requirement Specification` heading and provide report metadata, section navigation, scope status, and links to all Report 3 section files.
8. Add project-specific diagrams or placeholders for context, actor/use-case view, screen flow, authorization, non-screen processing, and ERD. Every asset gets ID/caption/status/source/related IDs.
9. Cross-check all actor names, feature names, status labels, and the complete 23-task catalog (exactly 22 named scored task rows plus one unscored Personal Introduction row) against Phase 01. Each task row must state timing, response type, scoring/source behavior, Score Template relationship, and fixed-exam-version relationship. Remove generic template prompts and source-DOCX sample-domain content.
10. Update the ID ledger and produce a Report 3 traceability table linking requirements to use cases/business rules/NFRs.

## Acceptance Criteria

- [ ] The seven Report 3 files exist under `pte-doc/report/report03/`: `00-project-report.md`, `00-record-of-changes.md`, and five numbered section files, plus mandatory `assets/`.
- [ ] Report 3 preserves the DOCX document-level and child section order and maps all nested headings.
- [ ] The product is consistently named PTE Prep and carries the independent practice/mock-exam disclaimer.
- [ ] Exactly six human roles and External Integration Services are defined; no extra user roles appear.
- [ ] All 12 feature groups are described with actors, flows, status, authorization, data effects, and acceptance conditions.
- [ ] Report 3 links to a catalog containing exactly 23 unique task rows: 22 named scored task types plus the unscored Personal Introduction, with the required timing/response/scoring/source/template/version fields.
- [ ] Every functional, non-functional, use-case, business-rule, common, and message ID is unique and recorded in the ledger.
- [ ] NFR numbers are clearly targets/baselines, not current proof; retention remains contract-based TBD.
- [ ] Report 3 explicitly separates organization registration from package/payment activation and excludes Student self-payment.
- [ ] Generic template prompts, cafeteria/sample-domain content, secrets, and unsupported PTE Academic claims are absent.
- [ ] Report 3 cross-links are valid or explicitly marked TBD with owner and impact.

## Design Constraints

- Preflight: Read the Phase 01 foundation files, `pte-doc/projects/pte-org-srs/spec.md`, `pte-doc/projects/pte-org-srs/brainstorm.md`, and the existing SRS/template documents. Conventions carried forward are UTF-8 numbered Markdown sections, business-readable wording, stable cross-report IDs, explicit status/evidence notes, and no unsupported role or PTE Academic claim. This phase writes only `pte-doc/report/report03/` plus declared test/plan artifacts.

- Report 3 is the canonical scope source for Reports 4–6; do not create design/test/guide facts that contradict it.
- Requirements must use plain business language first; technical terms are defined when needed.
- Requirements describe behavior and acceptance, not implementation code or private deployment values.
- Use the approved role list and organization-first model.
- Windows is the first exam-delivery channel; mobile delivery is out of scope.
- AI scoring, advanced anti-cheat, provider quality thresholds, and retention details remain Partial/Planned/TBD unless evidence supports Current.
- A diagram may be TBD, but its intended content and missing evidence must be explained in text.

## Quality and Testing State

- **Quality:** Not evaluated.
- **Testing:** Not started.
- **Planned checks:** section-map comparison, ID uniqueness/reference scan, UTF-8 scan, placeholder/sample-domain scan, role/scope scan, secret-pattern scan, relative-link scan.
- **Product runtime tests:** Not applicable to this documentation phase.

## Risks / Notes

- The legacy SRS uses the name PTE Org in places; new files must use PTE Prep while recording the baseline source.
- The SRS contains target metrics; avoid writing “achieved” without a linked test/operations result.
- The distinction between registration, package activation, and payment must remain visible in overview, functional requirements, and business rules.
- Report 3 may expose unresolved design decisions; record them rather than silently choosing an implementation.

## Spec / User Story Mapping

- Spec: FR-01, FR-02, FR-03, FR-04, FR-05, FR-06, FR-07, FR-08, FR-15, FR-16, FR-17; NFR-01 through NFR-11, NFR-13, NFR-18, NFR-19.
- User stories: P1 project-leader SRS completeness; P1 approved actor model; P1 status/evidence discipline; P1 reviewer traceability; P1 English canonical output.


## Execution Notes

- Status: completed for cook Phase 02.
- RED/GREEN: `python tests/test_phase02_report03.py` initially failed because the five numbered Report 3 files and project-specific IDs/content were absent; after implementation it returned `GREEN/PASSED`.
- Build Gate: Python syntax compilation passed for the phase validator.
- Testing: passed under TDD verify; result at `tests/results/phase-02-report-03-srs-test-report.json`.
- Quality: approved; report at `quality/phase-02-report-03-srs-quality-report.json`.
- Outputs: detailed Overall Description, User Requirements, Functional Requirements, Non-Functional Requirements, and Requirement Appendix.
