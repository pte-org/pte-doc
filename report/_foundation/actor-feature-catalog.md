# PTEPrep - Actor and Feature Catalog

**Status:** Scope revision draft, 22 October 2026
**Canonical product name:** PTEPrep
**Registered title:** PTEPrep: An AI-Powered PTE Practice Platform and Realistic Exam Simulator
**Product boundary:** An independent platform for PTE-style practice and realistic organization exams. It does not connect to, represent, certify for, or claim endorsement by PTE Academic.

## Canonical human roles

The product has exactly eight human login roles. The role names below are used in requirements, design, tests, diagrams, and guides.

| Role | Primary channel | Main responsibility | Data boundary | Important restriction |
|---|---|---|---|---|
| **Platform Admin** | Platform administration web | Controls platform configuration, organization approval, package state, audit, exceptional access and final platform-level decisions | Platform-wide platform records | Does not act as a Student, Examiner, or Host in an organization |
| **Platform Manager** | Platform administration web | Handles operational organization review, account support, package operations, support escalation and operational reporting | Platform operational records needed for the assigned work | Cannot approve academic content or bypass tenant ownership |
| **Academic Manager** | Platform administration web | Reviews academic content and scoring templates, controls publication and activation after academic review | Shared questions, media, rubrics, task definitions and template revisions | Cannot change organization rosters, attempt answers, or publish a Host report |
| **Academic Staff** | Platform administration web | Creates and submits question, media, rubric and Score Template drafts; responds to review findings | Assigned shared-content drafts and revisions | Cannot approve, publish, or activate the submitted content alone |
| **Host** | Organization web | Runs one organization: Students, programs, classes, enrollments, packages, exams, assignments, score review and report publication | One organization plus its permitted audit and subscription records | Cannot edit shared academic content or another organization |
| **Proctor** | Assigned monitoring workspace | Monitors assigned exams, assists Students under policy, and records integrity events | Assigned exams, attempts, device states and event records | Cannot score, select a final score source, or publish reports |
| **Examiner** | Assigned scoring workspace | Scores assigned answers with the approved rubric and submits reviewable scores | Assigned answers and the rubric context needed to score them | Cannot assign work to self, change the exam, or publish a report |
| **Student** | `pte-practice` web, Windows exam client and result view | Practices independently or completes an assigned organization exam; views own progress and published result | Own identity, eligible membership context, sessions, answers, feedback and reports | Cannot read another Student, manage a package, or publish a report |

`Platform Author` is a legacy label found in earlier reports and source history. In the revised scope it maps to **Academic Staff** for traceability only. It is not a ninth role. `Host Admin`, `Lecturer`, `Coordinator`, and similar labels are not additional product roles in this report set.

## Non-human integration actor

**External Integration Services** is an integration boundary rather than a login role. It represents payment, media storage, email/notification, AI scoring or explanation, and other explicitly approved providers. A provider may return accepted, pending, failed, timed-out, or duplicate results. The platform must keep the business state and provider state separate and must never expose provider credentials to a human user.

## Product channels

| Channel | Users | Primary purpose | Current evidence boundary |
|---|---|---|---|
| Platform administration web (`vendor-web`) | Platform Admin, Platform Manager, Academic Manager, Academic Staff | Organization review, operational support, academic authoring/review, packages, platform audit | Source contains the portal and role contracts; each workflow is classified separately as Current, Partial, or Planned |
| Organization web (`tenant-web`) | Host, assigned Proctor, assigned Examiner | Organization operations, exam setup, monitoring, scoring and publication | Tenant-owned operations are supported in the reviewed source to varying degrees |
| Student practice web (`pte-practice`) | Student | Email sign-in, catalog, Study-Pack groups, practice sessions, answers, confidence, progress and future AI explanations | Practice routes and session/progress slices exist; the complete AI explanation journey is not evidenced as complete |
| Windows exam client (`pte-app`) | Student | Device checks, timed organization exam, local answer saving, synchronization and submission | Windows-first exam delivery is the delivery boundary; mobile exam delivery is outside scope |

## Feature catalog

| ID | Feature group | Primary roles | Requirement disposition | Evidence state |
|---|---|---|---|---|
| FEAT-01 | Identity, email sign-in and organization context | Platform Admin, Platform Manager, Host, Student | In scope | Partial; exact cross-organization policy is TBD |
| FEAT-02 | Organization, program, class, Student and enrollment operations | Host, Platform Manager | In scope | Partial/Current slices exist in source |
| FEAT-03 | Shared question, media and rubric authoring | Academic Staff, Academic Manager, Platform Admin | In scope | Partial; approval and quality governance must be completed |
| FEAT-04 | Score Templates, task catalog and channel usage flags | Academic Staff, Academic Manager, Host | In scope | Partial; D04 flag behavior is a confirmed requirement and later implementation gap |
| FEAT-05 | Package, license, subscription and capacity operations | Platform Admin, Platform Manager, Host, External Integration Services | In scope | Partial; payment and activation are separate from registration |
| FEAT-06 | Exam preparation, generation, scheduling and fixed forms | Host, Student, Proctor, Examiner | In scope | Partial; source and plan evidence must be separated |
| FEAT-07 | Student organization exam delivery | Student, Proctor, External Integration Services | In scope | Partial; Windows-first delivery and recovery are the baseline |
| FEAT-08 | Student self-practice | Student, External Integration Services | In scope | Partial; practice UI/progress exists, AI explanation remains incomplete |
| FEAT-09 | Proctoring and integrity | Host, Proctor, Student | In scope | Partial; advanced anti-cheat is out of scope |
| FEAT-10 | Examiner assignment, marking and Host score-source selection | Host, Examiner, External Integration Services | In scope | Partial; allocation and review behavior needs end-to-end evidence |
| FEAT-11 | Reports, progress, publication, feedback and audit | Host, Student, Platform Admin, Platform Manager | In scope with feedback details TBD | Publication is evidenced for organization flow; Student content feedback needs a defined target and handler |
| FEAT-12 | External integration and recovery | All affected roles, External Integration Services | In scope | Provider contracts and failure states are explicit; thresholds remain TBD |

## Shared vocabulary

- **Organization:** a tenant that uses PTEPrep for learners and organized exams.
- **Membership:** a person-to-organization relationship with a role and lifecycle state. An email identity is not automatically a membership.
- **Practice session:** one Student's self-practice activity in `pte-practice`; it is separate from an organization ExamSession and Host-published report.
- **Exam:** an organization-created practice/mock exam with a fixed audience and content policy.
- **Question usage flag:** a separate eligibility flag on a question revision for Practice Web or Windows Exam Client. It is an additional filter, not a permission or entitlement.
- **Score Template:** an approved configuration for task composition, timing, weights and allowed score sources.
- **Fixed version:** the question, media, rubric, template, policy and audience snapshot used by an existing exam or practice session item.
- **Progress:** a truthful record of activity and completion state. It must not be described as a score when scoring is pending or unavailable.
- **Publish:** make content, an exam, a report, or a feedback item available to its authorized next actor.
- **Audit log:** a record of who performed an important action, when, on which scope, with what outcome.

## Scope rules shared by Reports 3-6

1. The four channels are distinct even when they use the same backend application.
2. Practice content and organized-exam content use separate question eligibility flags. There is no silent cross-channel fallback.
3. Academic Staff can draft and submit; Academic Manager reviews and publishes/activates according to policy; Platform Admin retains platform-level control.
4. A requirement may be in scope while its implementation is Partial, Planned/Future, or Not evidenced.
5. AI explanations are educational product requirements, not a claim of official PTE scoring or guaranteed correctness.
6. Contract-based retention remains the interim policy. Exact duration, export and deletion rules require an organization contract decision.
