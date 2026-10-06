# Brainstorm: Project-specific PTE Prep Reports 3–6

**Date:** 2026-10-06  
**Slug:** `pte-prep-report-documents`  
**Status:** Direction confirmed; ready for planning  
**Requested output:** English Markdown report sets first; Vietnamese copies and Report 7 are deferred.

## 1. Problem to solve

The current Markdown files in `pte-doc/projects/templates` are useful as document skeletons, but they still describe how a report could be written rather than documenting the actual PTE Prep product. A reviewer cannot use them to understand the real actors, organization workflows, exam lifecycle, scoring flow, data boundaries, or operational procedures.

The required deliverable is a project-specific documentation set for Reports 3, 4, 5, and 6. Each set must retain the corresponding DOCX table of contents, split the major sections into maintainable Markdown files, and contain enough business and system detail to be reviewed without opening the source DOCX. The documents must describe the real PTE Prep scope, including what is implemented, what is partial, what is planned, and what is explicitly excluded.

## 2. Direction confirmed by the user

### 2.1 Preserve the original report structure

The original DOCX structure is the authority for section order and section grouping. The Markdown set may improve file names and navigation, but it must not silently remove or reorder a report section.

The expected style is one file per report section, for example:

```text
report/report03/
├── 00-record-of-changes.md
├── 01-overall-description.md
├── 02-user-requirements.md
├── 03-functional-requirements.md
├── 04-non-functional-requirements.md
├── 05-requirement-appendix.md
└── assets/
```

The same convention will be applied to `report04`, `report05`, and `report06` after the plan is approved.

### 2.2 Write project content, not generic instructions

Every section must be filled with PTE Prep information. Generic prompts such as “describe the system here” or “insert a class diagram” are not acceptable as the main content. A diagram may remain `TBD` only when the repository does not yet contain enough evidence to draw it; the surrounding text must still explain the intended business meaning and the missing evidence.

### 2.3 Use the approved PTE Prep actor model

The human roles are fixed to:

1. Platform Admin
2. Platform Author
3. Host
4. Proctor
5. Examiner
6. Student

The seventh actor category is **External Integration Services**, which represents systems such as payment, media, AI scoring, and notification providers. It is an integration actor, not a human user role.

Do not introduce Lecturer, Program Coordinator, Tenant Owner, Applicant, or other extra product roles. A person who submits an organization registration is treated as the pre-tenant applicant state of the first Host account; it is not a separate role in the approved product model.

### 2.4 Describe PTE Prep accurately

The product is an organization-based PTE practice and mock-exam management platform. It simulates PTE-style tasks and scoring workflows for organizations. It does not connect to, represent, certify for, or claim endorsement by PTE Academic. The reports must retain this product boundary in the overview, release guide, and user-facing explanations.

The current business model is organization-first. A Host manages the organization, learners, classes, exams, proctor assignments, examiner assignments, and publication of results. Student self-service package purchase is outside the current product scope. No research-based learning or academic research contribution is claimed; this is a practical software product.

## 3. Directions considered

### Direction A — Keep the generic templates and add a project appendix

**Benefit:** Minimal file changes.  
**Problem:** The actual requirements, design, test, and guide content remains mixed with instructions. Reviewers still cannot trace a complete report section.  
**Decision:** Rejected.

### Direction B — Write one large Markdown file per report

**Benefit:** Easy to export as one document.  
**Problem:** Long sections become difficult to review, update, cross-reference, and map back to the DOCX table of contents. Assets and diagrams become hard to locate.  
**Decision:** Rejected as the working format. A report-level index can be added later if needed, but section files remain canonical.

### Direction C — Split by the original DOCX sections and fill each file with project content

**Benefit:** Directly reviewable against the approved DOCX, supports parallel maintenance, and gives stable links for requirements, designs, tests, and guides.  
**Cost:** Requires cross-document identifiers and a navigation convention.  
**Decision:** Selected.

### Direction D — Add a separate asset directory for each report

**Benefit:** Keeps diagrams, screenshots, exported figures, and supporting examples close to the section that uses them without embedding binary content in Markdown.  
**Cost:** Every asset needs a stable name, caption, source/status, and link.  
**Decision:** Selected.

### Direction E — Generate English and Vietnamese versions at the same time

**Benefit:** Both audiences receive deliverables immediately.  
**Problem:** It doubles the synchronization surface while the English structure and project facts are still being corrected.  
**Decision:** English is the canonical first pass. Vietnamese copies are a follow-up phase using the approved English structure and terminology.

### Direction F — Complete Report 7 in the same pass

**Benefit:** One large documentation drop.  
**Problem:** Report 7 has a different purpose and depends on stable content from Reports 3–6. Including it now would make unresolved report content look final.  
**Decision:** Deferred. The current scope is Reports 3–6 only.

## 4. Documentation scope selected for Reports 3–6

### Report 3 — Software Requirement Specification

The report will explain the product purpose and boundary, organization and platform actors, use cases, functional requirements, external interfaces, quality requirements, business rules, common requirements, application messages, and other requirement constraints.

PTE Prep-specific content must cover at least:

- organization onboarding and Host activation;
- tenant-scoped identity and authorization;
- shared question bank and media lifecycle;
- scoring templates and task types;
- organization packages, limits, and the separation between registration and package activation;
- student, class, and program management;
- exam creation, student selection, validation, generation, and scheduling;
- Windows-first Student delivery with local-first answer saving and retry/recovery;
- Proctor monitoring and violation recording;
- Host assignment of work to Examiners and review of score sources;
- report readiness, Host publication, Student visibility, and audit history;
- External Integration Services and failure boundaries;
- out-of-scope items and unresolved policy decisions.

### Report 4 — Software Design Document

The report will describe the actual PTE Prep solution design behind the requirements. It will cover the deployment shape, web portals, Windows exam client, backend modular monolith, persistence and supporting services, authorization boundaries, package/module ownership, database design, and detailed designs for the core workflows.

Design content must distinguish the current topology from future options. The current baseline is a Java/Spring backend, PostgreSQL, Redis, RabbitMQ, Next.js/React web portals, a Flutter Windows-first exam client, Cloudinary media storage, and an Oracle VPS deployment behind an edge proxy. The design must not describe the legacy service directories as independent production microservices.

The detailed-design section should prioritize the flows that carry the most business risk:

1. registration approval and Host activation;
2. exam creation, pre-exam validation, fixed version generation, and scheduling;
3. Student answer capture, local outbox synchronization, retry, and final submission;
4. Proctor violation recording and audit;
5. Examiner assignment, marking, Host score-source review, and report publication.

### Report 5 — Testing Documentation

The report will be an executable testing plan for PTE Prep, not a generic list of testing definitions. It will map test scope, strategy, levels, tools, environments, milestones, cases, evidence, and test reports to the PTE Prep features and business rules.

Testing must include tenant isolation, role permissions, onboarding, content publication, package limits, exam generation and conflict checks, Windows exam delivery, offline answer recovery, proctoring, Examiner queues, score selection, report publication, audit history, integration callbacks, and the non-functional baselines that have been agreed or marked as targets.

Where behavior is partial or dependent on an unresolved provider/policy, the test plan must record the dependency and expected evidence instead of declaring a passing result without a test run.

### Report 6 — Software User Guides / Release Package

The report will explain what is delivered, how an organization prepares the supported environment, how the web portals and Windows exam client are installed or accessed, how configuration is verified, and how users complete the supported workflows.

User guidance must be written for business users, not only developers. It should include role-specific procedures for Platform Admin, Platform Author, Host, Proctor, Examiner, and Student, with plain-language prerequisites, expected states, validation messages, recovery actions, and the limits of each role. Installation and operational instructions must never include real credentials, private keys, or environment values.

## 5. Project facts that must be carried into the reports

The following facts are the baseline for project-specific writing. They must be reconciled with source code and current UI/API evidence before a report labels a behavior as current:

### Product and channel model

- PTE Prep serves organizations that manage PTE-style practice and mock exams.
- The organization web portal is used by Host and assigned operational staff.
- The platform administration portal is used by Platform Admin and Platform Author.
- The Windows-first exam client is used by Student for exam delivery.
- PTE Prep is an independent practice/simulation product and must not imply official PTE Academic affiliation or certification.

### Core feature groups

1. Account and organization onboarding.
2. Organization, learner, program, class, and enrollment management.
3. Shared question bank and media management.
4. Scoring templates and task rules.
5. Packages, payment integration, licenses, and usage limits.
6. Exam setup, student selection, validation, generation, and scheduling.
7. Student exam delivery and answer submission.
8. Proctoring and exam integrity.
9. Examiner work assignment and score review.
10. Reports, publication, notifications, and audit history.
11. External service integrations.
12. Exam generation and platform hardening.

### Current, partial, future, and out-of-scope labels

Each report must use an explicit status label when describing behavior:

- **Current:** evidenced by the current implementation, configuration, or verified UI/API behavior.
- **Partial:** a slice exists, but the end-to-end business flow or required safeguards are incomplete.
- **Planned/Future:** agreed direction or design intent without current implementation evidence.
- **Out of scope:** intentionally excluded from the current product boundary.
- **TBD:** a business or policy decision is still required before the behavior can be finalized.

The same status must not be silently changed between the SRS, design, test, and guide reports.

### Technical baseline to describe carefully

- Java 21/Spring Boot backend in a modular-monolith production application.
- PostgreSQL as the shared relational database.
- Redis and RabbitMQ as supporting infrastructure where the implementation uses them.
- Next.js/React web applications for tenant and platform administration.
- Flutter Windows-first exam client for Student delivery.
- Cloudinary for question-bank media upload/storage through signed browser flows.
- PayOS and other approved external services only where the feature contract requires them.
- Docker Compose deployment on one Oracle VPS with an edge proxy; the backend application is internal and is not to be documented as a public microservice fleet.
- UTC persistence/display conversion and secret-free documentation.

## 6. Traceability and writing rules

1. Use stable identifiers for requirements, business rules, use cases, design decisions, test cases, messages, and user-guide procedures.
2. Link every design claim to the requirement IDs it realizes.
3. Link every test case to the feature, rule, requirement, and expected evidence it verifies.
4. Link every user procedure to the actor, precondition, action, expected result, and recovery path.
5. Give each diagram and table an identifier, caption, status, and source or `TBD` note.
6. Use business-readable language first. Define technical terms when they are necessary for implementation or operations.
7. Keep the original DOCX heading order and section meaning even when a Markdown file has a more readable file name.
8. Avoid silently converting a target, assumption, or planned capability into a current guarantee.
9. Keep all Markdown files UTF-8 and avoid secrets, private keys, real environment values, or production credentials.
10. Use cross-report links rather than copying long, independently editable versions of the same requirement.

## 7. Working assumptions

- The canonical working root for the split reports is `pte-doc/report/`, with `report03` through `report06` as report directories.
- The existing PTE Prep SRS baseline in `pte-doc/projects/pte-org-srs/` is the primary business source; the original DOCX files provide structure and presentation expectations.
- The report author will inspect current source/UI/API evidence before finalizing labels such as Current or Partial.
- Mermaid diagrams or exported images may be used in `assets/`; an unavailable diagram can be represented by a clearly marked placeholder with its intended content described.
- English is the canonical language for this pass. Vietnamese copies will reuse the same IDs and structure later.
- Report 7 is intentionally deferred until Reports 3–6 are stable.

## 8. Risks to control

| Risk | Why it matters | Control |
|---|---|---|
| Future design is written as if already implemented | Reviewers may reject the report or derive incorrect acceptance criteria | Use status labels and cite implementation/plan evidence |
| The DOCX and Markdown section names drift | Reviewers cannot reconcile submissions | Maintain a section map and one canonical file per section |
| Requirements, design, tests, and guides duplicate conflicting facts | A correction must be made in several places and may remain inconsistent | Use stable IDs and cross-links |
| Diagrams exist without business explanation | A picture cannot be reviewed or tested by itself | Add captions, scope, legend, status, and linked text |
| Integration behavior is over-promised | Payment, media, AI, and notifications have provider and failure dependencies | Document contracts, failure handling, and TBD decisions explicitly |
| A generic template paragraph survives in a final section | The report still looks unfinished | Search for placeholder language before review |
| PTE Academic affiliation is implied | It creates a product and review boundary error | Repeat the independent practice/simulation disclaimer where relevant |

## 9. Decision

Proceed with a planning pass for project-specific English Markdown documentation for Reports 3–6. The plan must preserve the original DOCX table of contents, create section-level files, define the asset and cross-reference conventions, and require detailed PTE Prep content. Vietnamese copies, Report 7, and binary DOCX/PDF generation remain outside this pass.

