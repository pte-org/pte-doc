# Spec: Project-specific Report 3–6 documentation for PTE Prep

**Date:** 2026-10-06  
**Status:** Ready  
**Slug:** `pte-prep-report-documents`

---

## Problem Statement

The existing report Markdown files are generic templates. They describe what an author should write but do not document the actual PTE Prep product, its organization-based exam workflows, approved actors, technical boundaries, test evidence, or user procedures. This makes review difficult and allows requirements, design, testing, and user guidance to drift apart.

This specification defines a documentation work package for Reports 3, 4, 5, and 6. Each report will preserve the structure and order of its original DOCX table of contents while being split into maintainable Markdown section files. The files will contain detailed, project-specific English content based on the approved PTE Prep SRS baseline and verified repository evidence. Vietnamese copies and Report 7 are deferred.

PTE Prep is an independent organization-based platform for PTE-style practice and mock exams. It simulates exam tasks and operational workflows; it does not connect to, represent, certify for, or claim endorsement by PTE Academic. The documentation must keep that boundary visible.

---

## User Stories

<!-- P1 = current documentation work package, P2 = useful extension, P3 = deferred/out of scope -->

- **[P1]** As a project leader, I want Report 3 to contain every original SRS section in a project-specific Markdown file so that reviewers can understand the PTE Prep scope without reading generic template instructions.
  Accepted when: the Report 3 folder contains a record of changes file and one canonical file for product overview, user requirements, functional requirements, non-functional requirements, and requirement appendix; each file contains PTE Prep content and the original DOCX section mapping.

- **[P1]** As a business analyst, I want the requirements report to describe the six approved human roles and the External Integration Services actor so that the role model cannot expand accidentally during implementation.
  Accepted when: the report defines Platform Admin, Platform Author, Host, Proctor, Examiner, Student, and External Integration Services, including each actor’s responsibilities, data visibility, allowed actions, and boundaries.

- **[P1]** As a reviewer, I want requirements to distinguish Current, Partial, Planned/Future, Out of scope, and TBD behavior so that the report does not present an unimplemented design as a delivered capability.
  Accepted when: every material capability with incomplete evidence has an explicit status and the report records the evidence source or unresolved decision.

- **[P1]** As a technical lead, I want Report 4 to describe the PTE Prep architecture, package ownership, data model, and core interactions so that implementation and design review use the same system boundary.
  Accepted when: the design report covers the web portals, Windows-first exam client, modular-monolith backend, PostgreSQL, Redis, RabbitMQ, media storage, external integrations, deployment topology, authorization boundaries, database entities, and core sequence/class designs.

- **[P1]** As a tester, I want Report 5 to map PTE Prep features and business rules to test strategy, environments, cases, evidence, and reports so that the testing document can be executed instead of merely defining testing vocabulary.
  Accepted when: each in-scope feature has at least one linked test case or explicitly documented test dependency, and the plan covers tenant isolation, roles, exam delivery, answer recovery, scoring, publication, audit, integrations, and non-functional targets.

- **[P1]** As an organization operator, I want Report 6 to explain installation, access, configuration checks, role workflows, and recovery steps in plain language so that a Host, Proctor, Examiner, or Student can use the product without reading source code.
  Accepted when: the guide includes supported environment prerequisites, installation or access instructions, verification and recovery steps, and role-specific procedures with preconditions and expected results.

- **[P1]** As a document reviewer, I want each report section and asset to have stable names, identifiers, captions, and links so that comments can refer to an exact requirement, diagram, test case, or procedure.
  Accepted when: cross-report links resolve to existing files or IDs, and every diagram/table is either linked to an asset or marked `TBD` with its intended content explained.

- **[P1]** As a project leader, I want the English report set to be the canonical version for this pass so that later Vietnamese copies can reuse the same section structure and identifiers.
  Accepted when: the English files are complete enough for review and the specification explicitly records Vietnamese versions and Report 7 as deferred work.

- **[P2]** As a reviewer, I want a report-level index or navigation page generated from the section map so that I can move between sections quickly.
  Accepted when: a future implementation can add an index without changing the canonical section files.

- **[P3]** _(out of scope for this work package)_ As a project team, we want a complete Report 7 final project report and Vietnamese editions so that all submission documents are bilingual and complete.
  Accepted when: a separate approved work package starts after Reports 3–6 are baselined.

---

## Functional Requirements

1. **FR-01 — Preserve the DOCX section map**
   - The work package shall use the original DOCX table of contents as the authority for section order and section meaning for Reports 3–6.
   - The implementation shall record the source heading, Markdown file, and any intentional file-name simplification in a section map.
   - No original top-level section may disappear silently.

2. **FR-02 — Split reports into stable Markdown files**
   - The canonical root shall be `pte-doc/report/` with `report03`, `report04`, `report05`, and `report06` directories.
   - Each report shall contain a `00-project-report.md` file mapping the DOCX document-level `II.` heading, a `00-record-of-changes.md` file mapping section `I.`, one file per numbered major report section, and a mandatory `assets/` directory.
   - File names shall be stable, lowercase, hyphenated, and ordered with numeric prefixes so that the file list follows the DOCX table of contents.
   - A report section may be split into subordinate files only when the section map preserves the original section as one navigable unit.
   - Shared foundation artifacts shall be stored under `pte-doc/report/_foundation/`; the final validation record shall be stored under `pte-doc/report/_validation/`.

3. **FR-03 — Provide report metadata and change history**
   - Every report shall identify the project as **PTE Prep**, report number/title, document status, language, source DOCX, author/owner field, and last update date.
   - The record of changes shall contain version, date, change type, person/team in charge, change description, and reference.
   - The first project-specific version shall state that it replaces a generic template with content based on the approved PTE Prep SRS baseline, without altering the original DOCX.

4. **FR-04 — Describe product purpose and boundary in Report 3**
   - The overview shall explain the organization-based business model, three usage channels, exam lifecycle, and intended value.
   - It shall state that PTE Prep is a practice and mock-exam simulation product independent from PTE Academic.
   - It shall include in-scope capabilities, out-of-scope capabilities, assumptions, constraints, terminology, and known open decisions.
   - It shall not claim research-based learning, academic research contribution, official certification, or PTE Academic representation.

5. **FR-05 — Define the approved actor and authorization model**
   - Report 3 shall define Platform Admin, Platform Author, Host, Proctor, Examiner, Student, and External Integration Services.
   - It shall define responsibilities, normal channel, data scope, permitted actions, and prohibited actions for each actor.
   - It shall state that External Integration Services are integration actors, not user accounts.
   - It shall not introduce Lecturer, Program Coordinator, Tenant Owner, Applicant, or other additional roles.
   - It shall describe tenant isolation, assignment boundaries for Proctor/Examiner, Student self-visibility, and platform-wide authority for Platform Admin.

6. **FR-06 — Document PTE Prep functional requirements**
   Report 3 shall provide detailed, uniquely identified requirements for these feature groups:

   1. account and organization onboarding;
   2. organization, Student, program, class, and enrollment management;
   3. shared question bank and image/audio media;
   4. scoring templates and task rules;
   5. organization packages, payment integration, licenses, and limits;
   6. exam setup, Student selection, validation, generation, and scheduling;
   7. Student exam delivery and answer submission;
   8. Proctoring and exam integrity;
   9. Examiner assignment, marking, and Host score-source review;
   10. report aggregation, publication, Student viewing, notifications, and audit;
   11. external service contracts and failure handling;
   12. exam generation provenance and platform hardening.

   Each feature group shall document actors, preconditions, main flow, alternate/error flows, business rules, data created or changed, authorization, status, and acceptance criteria.

   - Report 3 shall explicitly document the configured PTE task catalog: 22 scored task types plus the unscored Personal Introduction, including task timing/response types, the product score range, score-source behavior, and how task composition is captured by Score Templates and fixed exam versions.

7. **FR-07 — Document Report 3 non-functional requirements and interfaces**
   - The SRS shall describe external interfaces for web users, the Windows exam client, backend APIs, Cloudinary, payment, AI scoring, notification delivery, and operational infrastructure where applicable.
   - It shall preserve numeric targets as baselines or acceptance targets, not as evidence that the current deployment already satisfies them.
   - The baseline shall cover response time, active attempts, answer submission burst, pre-exam validation, availability, recovery, data confidentiality, tenant isolation, auditability, accessibility/usability, compatibility, and retention policy.
   - Exam answers, scores, and audit logs shall be retained according to each organization’s contract; the exact period and deletion/export/legal-hold process shall remain an explicit TBD until approved.

8. **FR-08 — Provide a requirement appendix**
   - The appendix shall contain business rules, common requirements, application messages, external-service error handling, data/retention assumptions, and unresolved decisions.
   - Business rules shall use stable IDs such as `BR-###`; messages shall use stable IDs such as `MSG-###`.
   - The appendix shall include rules for approval, tenant access, package limits, fixed exam versions, duplicate/conflict checks, answer acceptance, retry, score-source review, publication, and audit.

9. **FR-09 — Describe the current PTE Prep design in Report 4**
   - The system-design section shall describe the organization web portal, platform administration portal, Windows-first exam client, backend modular monolith, database, supporting infrastructure, edge routing, and external services.
   - The architecture description shall not represent legacy service-module directories as independent production microservices.
   - The package diagram shall show ownership and public boundaries between identity, tenant/organization, content, scoring, package/license, exam, delivery, proctoring, examiner, reporting, audit, and integration concerns where those boundaries exist.
   - The design shall identify which components are current, partial, planned, or dependent on a provider/policy decision.

10. **FR-10 — Provide Report 4 database and detailed design**
    - The database section shall define the entities, ownership, identifiers, lifecycle/status fields, tenant keys, important constraints, relationships, and retention classification needed by PTE Prep.
    - The detailed-design section shall cover at minimum registration approval, exam generation/scheduling, local-first answer synchronization and retry, Proctor violation recording, Examiner assignment/marking, score-source review, and report publication.
    - Every class, sequence, ERD, package, or deployment diagram shall have an identifier, caption, legend, source/status note, and links to the requirements it realizes.
    - Sensitive values and real credentials shall never appear in diagrams or examples.

11. **FR-11 — Provide an executable Report 5 test plan**
    - The scope shall identify features and risks included in the current PTE Prep release and explicitly list exclusions.
    - The strategy shall define testing types, levels, entry/exit conditions, evidence expectations, defect severity, test data handling, and traceability.
    - The plan shall describe human resources, test environments, supported clients, service dependencies, test milestones, and release gates.
    - Test cases shall cover positive, negative, boundary, authorization, tenant-isolation, concurrency/retry, integration failure, and recovery behavior where applicable.
    - Test reports shall distinguish planned, executed, blocked, failed, passed, and not-applicable cases; no result may be invented.

12. **FR-12 — Cover PTE Prep high-risk test areas**
    Report 5 shall include test coverage for:

    - organization registration review, rejection, approval, and Host activation;
    - login, session renewal, password change/reset, role permissions, and tenant isolation;
    - question/media draft, validation, approval, publication, archive, and immutable exam snapshots;
    - score template validity, task composition, and prohibited Host edits;
    - package activation, payment callback/idempotency, limits, and expiry behavior;
    - Student roster import, duplicate/conflict detection, class/program membership, and enrollment;
    - exam pre-validation, shared/unique form generation, scheduling, publication, opening, closing, and cancellation;
    - device check, timed tasks, text/audio/image responses, local answer outbox, reconnect/retry, final submission, and duplicate-submit protection;
    - Proctor assignment, monitoring, violation recording, policy status, and audit history;
    - Examiner queue assignment, score entry, reassignment/review, automated-score coexistence, source selection, and incomplete-score blocking;
    - report calculation, Host publication, Student visibility, notifications, and audit;
    - Cloudinary/media, payment, AI scoring, and notification failure/retry behavior;
    - performance, availability, recovery, accessibility/usability, and compatibility baselines.

13. **FR-13 — Provide project-specific Report 6 release and user guidance**
    - The deliverable package shall identify the organization web portal, platform administration portal, Windows exam client, server-side services, configuration checklist, and release evidence expected for the supported version.
    - Installation/access instructions shall cover prerequisites, environment setup without secrets, startup/health verification, client configuration, data/migration safeguards, rollback or recovery, and support escalation.
    - The manual shall include role-specific or clearly grouped workflows for Platform Admin, Platform Author, Host, Proctor, Examiner, and Student.
    - Each workflow shall include purpose, actor, prerequisites, step-by-step actions, expected result, validation/error messages, recovery path, and audit or visibility consequence.

14. **FR-14 — Manage assets and cross-report traceability**
    - Each report shall have a mandatory `assets/` directory for diagrams, screenshots, exports, and supporting figures, even when the first version contains only a manifest/README stating that no binary evidence is present.
    - Asset names shall be stable and descriptive; Markdown shall link to them using relative paths.
    - Requirements, designs, tests, and guides shall cross-link with IDs rather than maintain conflicting copied definitions.
    - The implementation shall provide a section-map check and a broken-link/identifier check before the report set is considered ready for review.

    - Foundation artifacts shall have deterministic paths: `pte-doc/report/_foundation/section-map.md`, `actor-feature-catalog.md`, `status-evidence-matrix.md`, `id-ledger.md`, `tbd-register.md`, `evidence-catalog.md`, and `pte-task-catalog.md`. The cross-report validation result shall be `pte-doc/report/_validation/report-03-06-validation.md`.

15. **FR-15 — Use status and evidence discipline**
    - `Current` requires implementation, configuration, or verified UI/API evidence.
    - `Partial` identifies an existing slice with a missing end-to-end step, safeguard, role, or integration.
    - `Planned/Future` identifies approved direction without current implementation evidence.
    - `Out of scope` identifies an explicit product boundary.
    - `TBD` identifies a decision that blocks a final rule, contract, or acceptance condition.
    - The same behavior shall use the same status and wording across Reports 3–6 unless a later report intentionally narrows it and explains why.

16. **FR-16 — Preserve scope decisions**
    The reports shall explicitly exclude or defer:

    - Student self-service payment and personal packages;
    - cross-organization Student identity;
    - Host-owned private question banks and self-publication;
    - reusable multi-sitting exam definitions in the first release;
    - adaptive testing, IRT, official PTE certification, and research claims;
    - mobile-first exam delivery/redesign while Windows is the first delivery channel;
    - replacing Cloudinary or adding unapproved media providers;
    - advanced anti-cheat capabilities such as virtual-machine detection, universal screen-recording detection, or automatic cancellation of every Practice violation;
    - Report 7 and Vietnamese copies in this documentation pass.

17. **FR-17 — Cite evidence consistently**
    - Every material Current, Partial, Planned/Future, or TBD claim shall reference an `EVD-*` evidence record.
    - Each evidence record shall include status, source path/route/configuration/plan/test/decision reference, verification date, related actor/feature/report section, reviewer/owner, and limitations or missing evidence.
    - A Partial claim requires evidence of an existing implementation/configuration/UI/API slice. A plan or ADR alone supports Planned/Future, not Partial.
    - The section map shall preserve malformed raw DOCX headings for audit, map them to normalized Markdown headings, and record the normalization reason rather than copying replacement characters into final Markdown. A raw-source field may retain the source replacement character; normalized headings and report prose may not.

---

## Non-Functional Requirements

The following requirements apply to the documentation package and to the PTE Prep baselines it records. Numeric values are acceptance targets or planning baselines unless a current verification result is linked.

- **NFR-01 — Readability:** Business users and reviewers shall be able to understand the main requirements and workflows without reading source code. Technical terms such as tenant, fixed exam version, outbox, retry, and audit log shall be defined at first use.
- **NFR-02 — Language and encoding:** The canonical report headings and prose shall be English, UTF-8 encoded, and render without replacement characters. The raw-source field in the foundation section map may preserve a DOCX replacement character for audit, but normalized headings and report content may not. Vietnamese versions, when created, shall preserve the same IDs and section order.
- **NFR-03 — Structural fidelity:** The Markdown section map shall preserve the original DOCX heading order and report meaning. A reviewer shall be able to locate every DOCX top-level section exactly once.
- **NFR-04 — Detail:** There is no artificial word limit. The document shall prefer complete business flows, rules, alternate paths, data effects, and evidence references over short generic summaries.
- **NFR-05 — Consistency:** A requirement, actor, feature name, status label, or business rule shall not have conflicting definitions across Reports 3–6. Cross-report references shall use stable IDs.
- **NFR-06 — Traceability:** Every functional requirement shall link to at least one business rule or acceptance condition; every core design element shall link to a requirement; every in-scope test area shall link to a requirement/rule; every role guide procedure shall link to an actor and flow.
- **NFR-07 — Diagram quality:** Every diagram or table shall have an identifier, title/caption, legend where needed, status, source/evidence note, and readable labels. Missing evidence shall be marked `TBD`, not silently fabricated.
- **NFR-08 — Performance baseline recorded:** The SRS shall retain the current planning baseline of 95% of ordinary requests at or below 0.5 seconds, pre-exam validation for up to 500 Students within 5 seconds, support for 1,000 active attempts, and a burst target of 100 submitted answers per second. These are targets to validate, not current production proof.
- **NFR-09 — Availability and recovery baseline recorded:** The SRS shall retain the target of 99.9% monthly availability, a maximum data-loss objective of 15 minutes where the deployment supports it, and a recovery target of 1 hour, with actual evidence and operational ownership recorded separately.
- **NFR-10 — Security:** No Markdown, diagram, example, or test artifact shall contain real credentials, tokens, private keys, passwords, secret environment values, or sensitive production data. Authentication, authorization, tenant isolation, protected transport, safe logging, and auditability shall be described in business-readable terms.
- **NFR-11 — Data protection:** Exam answers, scores, reports, and audit records shall have an explicit owner, visibility rule, retention classification, export/deletion/legal-hold decision, and status. The exact contractual retention period remains TBD until approved.
- **NFR-12 — Maintainability:** A contributor shall be able to update one report section without rewriting an unrelated report. File names, IDs, headings, links, and asset names shall remain stable after normal content edits.
- **NFR-13 — Reviewability:** A reviewer shall be able to compare each report to the source DOCX, identify changed content in the record of changes, and trace a high-risk business flow from requirement to design, test, and guide.
- **NFR-14 — Tool compatibility:** Markdown shall use portable constructs supported by the repository’s documentation tooling. Mermaid diagrams may be used when supported; binary assets shall have relative links and meaningful fallback text.
- **NFR-15 — Accessibility of user guidance:** User procedures shall not rely on color alone, shall state visible labels and status meanings, and shall include keyboard-relevant or device-check guidance for exam roles where applicable.
- **NFR-16 — Deployment accuracy:** Report 4 and Report 6 shall describe the current single-stack Docker/edge deployment accurately. They shall not instruct users to deploy legacy service databases or expose internal backend ports as public application endpoints.
- **NFR-17 — Integration resilience:** Payment, media, AI scoring, and notification failures shall be documented with timeout/error/retry/idempotency and user-visible status expectations. A failed notification shall not be described as automatically rolling back the core business transaction unless the actual contract requires it.
- **NFR-18 — Evidence honesty:** Test reports shall never claim a pass without execution evidence. Current-product claims shall include a repository/UI/API/configuration source or be labeled Partial, Planned/Future, or TBD.
- **NFR-19 — Evidence reproducibility:** A reviewer shall be able to locate the source, route, configuration, plan, test result, or decision behind each material status claim through an `EVD-*` record that includes verification date, owner, related scope, and limitations.

---

## Success Criteria

- [ ] **SC-01 — Four report roots:** `pte-doc/report/report03`, `report04`, `report05`, and `report06` exist; each contains `00-project-report.md`, `00-record-of-changes.md`, its numbered section files, and a mandatory `assets/` directory.
- [ ] **SC-02 — DOCX fidelity:** A section-map review confirms that every original Report 3–6 document-level `II.` heading and child section appears exactly once in the corresponding Markdown set, in the same logical order; raw malformed headings are preserved only in the map with normalized output headings.
- [ ] **SC-03 — Report 3 completeness:** Report 3 defines the seven approved actor categories, organization/tenant boundary, 12 feature groups, complete 23-task catalog (22 scored plus unscored Personal Introduction), task timing/response types, score range/source behavior, scope/out-of-scope, external interfaces, NFR baselines, business rules, messages, assumptions, and open decisions.
- [ ] **SC-04 — Report 4 completeness:** Report 4 covers system architecture, package/module ownership, deployment topology, database entities/relationships/constraints, and detailed designs for the core registration, exam, delivery, proctoring, marking, and publication flows.
- [ ] **SC-05 — Report 5 completeness:** Report 5 maps every in-scope feature or risk to a testing level and at least one test case or explicit dependency, and includes scope, strategy, resources, environment, milestones, evidence, and reports.
- [ ] **SC-06 — Report 6 completeness:** Report 6 contains package contents, supported system requirements, installation/access/configuration verification, recovery guidance, and detailed procedures for Platform Admin, Platform Author, Host, Proctor, Examiner, and Student.
- [ ] **SC-07 — Traceability:** Foundation catalogs exist at the canonical paths, evidence records are cited, cross-links for IDs and assets resolve, and no requirement/design/test/procedure ID is duplicated or orphaned without an explanation.
- [ ] **SC-08 — Placeholder removal:** No generic template instruction remains as the main content in Reports 3–6. Any `TBD` or diagram placeholder states the missing decision/evidence and owner.
- [ ] **SC-09 — Scope accuracy:** The reports state that PTE Prep is an independent practice/mock-exam product and do not claim official PTE Academic affiliation, research-based learning, or an unsupported feature as current.
- [ ] **SC-10 — Safety and encoding:** A UTF-8/Markdown scan finds no replacement characters in final headings, secrets, private keys, real environment values, or committed binary credentials; malformed source headings are represented only through the documented normalization map.
- [ ] **SC-11 — Review evidence:** A content review records which sections were checked against the PTE Prep SRS baseline, source evidence, plans/ADRs, and original DOCX.

---

## Out of Scope

- Writing or splitting Report 7 (Final Project Report) in this phase.
- Producing Vietnamese copies in this phase; English is the canonical first pass.
- Editing or replacing the original DOCX files.
- Changing PTE Prep product code, database schema, deployment configuration, or runtime behavior.
- Inventing unsupported UI screens, API contracts, provider guarantees, scoring quality thresholds, or anti-cheat capabilities.
- Turning the report work into academic research, a literature review, a scientific contribution, or a research-based learning module.
- Generating a final PDF or DOCX submission package; the deliverable in this phase is Markdown documentation.
- Adding new user roles beyond the approved six human roles and External Integration Services.
- Making a final contractual retention-period decision where the organization contract or legal policy is not available.

---

## Assumptions

- The canonical business baseline is `pte-doc/projects/pte-org-srs/spec.md` and its companion `brainstorm.md`; the report author will reconcile legacy “PTE Org” naming to the approved product name **PTE Prep** in the new report set.
- The original DOCX files are used for structure and presentation expectations, not as proof that every sample paragraph or diagram describes the current product.
- The canonical output root is assumed to be `pte-doc/report/`, following the user-provided example. If the repository later adopts another root, only navigation paths change; the report IDs and section map remain stable.
- Source code, configuration, verified UI/API behavior, and approved plans/ADRs are the evidence hierarchy for Current, Partial, and Planned/Future labels.
- The six human roles and one integration actor category are fixed for this documentation pass.
- Windows is the first supported exam-delivery channel; a mobile exam client is not required for Reports 3–6.
- The PTE task catalog and score rules are described as configured product content; official PTE certification or equivalence is not claimed.
- Payment, media, AI scoring, and notification providers may be unavailable in some test environments. Their contracts and failure behavior must be labeled accordingly.
- Organization-specific retention is governed by contract; the exact period/process remains a documented open item until the responsible parties decide it.
- Report-level navigation/index generation can be added after section files are stable and is not required to change the canonical content model.
