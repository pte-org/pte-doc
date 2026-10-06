# PTE Prep — Actor and Feature Catalog

**Status:** Current foundation artifact  
**Canonical product name:** PTE Prep  
**Product boundary:** Independent organization-based PTE-style practice and mock-exam platform. It does not connect to, represent, certify for, or claim endorsement by PTE Academic.

## Approved actor categories

| Actor | Category | Primary channel | Data scope | Boundary |
|---|---|---|---|---|
| Platform Admin | Human platform operator | Platform administration portal | Platform-wide organizations, content, packages, reports, and audit | Controls platform data and approvals; does not represent a Student or Examiner in a tenant workflow |
| Platform Author | Human content author | Platform administration portal | Shared question, media, task, and scoring-template drafts | Creates and submits drafts; cannot self-activate production content |
| Host | Human organization operator | Organization web portal | One organization’s learners, programs, classes, exams, staff assignments, packages, scores, and reports | Cannot read another organization or edit the shared question bank directly |
| Proctor | Human exam monitor | Assigned monitoring workspace | Assigned exams, Student/attempt status, assistance and violation records | Works only within assigned exams; does not publish scores or manage packages |
| Examiner | Human scorer | Assigned scoring workspace | Assigned Student answers, rubric, and submitted scores | Scores assigned work; Host controls final score-source selection and publication |
| Student | Human learner/test taker | Windows-first exam client and published result view | Own assigned exam, own answers, own attempt state, own published report | Cannot see another Student’s data or publish a report |
| External Integration Services | Integration actor, not a login role | Service-to-service boundary | Only data needed by a payment, media, AI scoring, email/notification, or approved service contract | Cannot administer PTE Prep users, organizations, or reports |

## Prohibited additional product roles

The report set must not introduce Lecturer, Program Coordinator, Tenant Owner, Applicant, or another login role. A public organization registrant is a pre-tenant state that can become the first Host after Platform Admin approval; it is not a seventh human role.

## Feature catalog

| Feature ID | Feature group | Primary actors | Canonical Report 3 area | Status rule |
|---|---|---|---|---|
| FEAT-01 | Account and organization onboarding | Platform Admin, Host | Functional Requirements — onboarding | Current/Partial only with implementation evidence |
| FEAT-02 | Organization, Student, program, class, and enrollment management | Host, Student | Functional Requirements — organization data | Tenant-scoped |
| FEAT-03 | Shared question bank and image/audio media | Platform Admin, Platform Author, Host, Student, External Integration Services | Functional Requirements — content | Platform-owned shared content |
| FEAT-04 | Score Templates and task rules | Platform Admin, Platform Author, Host, Student | Functional Requirements — scoring configuration | Host selects active templates; cannot change shared rules |
| FEAT-05 | Packages, payment integration, licenses, and limits | Platform Admin, Host, External Integration Services | Functional Requirements — package usage | Registration and package activation are separate flows |
| FEAT-06 | Exam setup, validation, generation, and scheduling | Host, Student, Proctor, Examiner | Functional Requirements — exam lifecycle | Fixed version/snapshot before Student delivery |
| FEAT-07 | Student exam delivery and answer submission | Student, Proctor, External Integration Services | Functional Requirements — delivery | Windows-first, local-first answer persistence |
| FEAT-08 | Proctoring and exam integrity | Host, Proctor, Student | Functional Requirements — integrity | Policy is fixed for an attempt; advanced detection is out of scope |
| FEAT-09 | Examiner assignment, marking, and score-source review | Host, Examiner, External Integration Services | Functional Requirements — scoring work | Host reviews source before publication |
| FEAT-10 | Reports, publication, notification, and audit | Host, Student, Platform Admin, Proctor, Examiner, External Integration Services | Functional Requirements — reporting | Student sees only own report after publication |
| FEAT-11 | External service contracts and failure handling | Platform Admin, Host, Student, External Integration Services | Interfaces/appendix | Retry/status/error behavior must be explicit |
| FEAT-12 | Exam generation provenance and platform hardening | Host, Platform Admin, Student, External Integration Services | Functional Requirements — hardening | Advanced anti-cheat and adaptive testing are not current scope |

## Shared business vocabulary

- **Organization:** a tenant using PTE Prep for its learners and exams.
- **Host:** the organization operator who manages its operational data.
- **Exam:** a scheduled practice/mock exam with a fixed audience and content policy.
- **Student attempt:** one Student’s delivery instance for an exam.
- **Score Template:** the approved configuration for task composition, timing, weights, and score sources.
- **Fixed exam version:** the question/task/policy snapshot that cannot change after delivery begins.
- **Publish:** make content, an exam, or a report available to the authorized next actor.
- **Audit log:** record of who performed an important action, when, and on which data.
- **Retry:** safe re-attempt after a transient failure, without duplicating the business result.

