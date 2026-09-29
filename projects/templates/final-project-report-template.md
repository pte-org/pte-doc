# Report 7 — Final Project Report

## Document control

| Field | Value |
|---|---|
| Template source | Report7_Final Project Report.docx |
| Template status | Draft |
| Project name | [Project name] |
| Project code | [Project code] |
| Group | [Group name / class] |
| Version | [Version] |
| Date | [YYYY-MM-DD] |
| Prepared by | [Name / role] |
| Supervisor | [Name] |
| External supervisor | [Name or Not applicable] |
| Approval status | [Draft / Reviewed / Approved] |

> **How to use this template:** This document is the final project report
> container. Replace every placeholder with project evidence and keep the
> section order unless the institution requires another order. The report
> brings together the project introduction, management plan, requirements,
> design, testing, and release/user-guide material. Standalone Report 3, 4, 5,
> and 6 documents may be referenced, but the final report must make clear
> which version is the approved final version.

> **Consistency rule:** Use one project name, one project code, one list of
> members, one role vocabulary, and one version history throughout the report.
> Requirement IDs, design IDs, test IDs, figures, tables, and release
> identifiers must remain stable when referenced across sections.

## Record of Changes

| Date | A*M, D | In charge | Change Description | Reference |
|---|---|---|---|---|
| [YYYY-MM-DD] | A | [Name] | [Initial final-report structure/content] | [Review/decision] |
| [YYYY-MM-DD] | M | [Name] | [Updated section, requirement, design, or test evidence] | [Reference] |
| [YYYY-MM-DD] | D | [Name] | [Removed or superseded content] | [Reference] |
|  |  |  |  |  |
|  |  |  |  |  |
|  |  |  |  |  |
|  |  |  |  |  |
|  |  |  |  |  |
|  |  |  |  |  |
|  |  |  |  |  |
|  |  |  |  |  |
|  |  |  |  |  |
|  |  |  |  |  |

*A — Added; M — Modified; D — Deleted. Record substantive changes to the
report or approved project baseline.*

---

## Front matter

### Cover page

Use the institution's approved cover-page format. At minimum, include:

- institution and faculty/school;
- project name and project code;
- capstone or course name;
- group name and class;
- all group members and student codes;
- supervisor and external supervisor, if any;
- submission date and report version.

| Item | Value |
|---|---|
| Institution | [Institution] |
| Faculty / school | [Faculty] |
| Capstone project | [Course or capstone name] |
| Project name | [Project name] |
| Project code | [Code] |
| Group / class | [Group/class] |
| Submission date | [YYYY-MM-DD] |

### Acknowledgement

Write a specific acknowledgement describing the people, organizations, and
resources that materially supported the project. Do not claim approval,
partnership, certification, or product ownership unless evidence exists.

[Write the team acknowledgement here.]

### Definition and Acronyms

Define terms and abbreviations used in the report. Use the same meaning in the
SRS, design, testing, and user guide sections. If a term is a user-facing
business term, write its plain-language meaning before any technical meaning.

| Acronym / term | Definition | First section used | Notes |
|---|---|---|---|
| [TERM] | [Definition] | [Section] | [Notes] |
| [TERM] | [Definition] | [Section] | [Notes] |
| [TERM] | [Definition] | [Section] | [Notes] |

---

# I. Project Introduction

This part explains why the project exists, what product is being built, who
it serves, and where its boundary lies. The narrative must agree with the
approved project registration and the final SRS.

## 1. Overview

### 1.1 Project Information

Provide concise but complete project metadata and a high-level description.
State the problem, the intended users, the product form, and the project
context without claiming capabilities that are outside the approved scope.

| Item | Description |
|---|---|
| Project name | [Name] |
| Project code | [Code] |
| Product type | [Web/mobile/desktop/service/etc.] |
| Intended users | [Roles and audiences] |
| Problem addressed | [Problem statement] |
| Main outcome | [Outcome] |
| Delivery boundary | [What the team delivers] |
| Known dependency | [Dependency or assumption] |

### 1.2 Project Team

List the project members and stakeholders. Distinguish the person who owns a
task from the people who review or approve it.

| Name | Student/staff code | Project role | Main responsibility | Approval/review responsibility |
|---|---|---|---|---|
| [Name] | [Code] | [Role] | [Responsibility] | [Responsibility] |
| [Name] | [Code] | [Role] | [Responsibility] | [Responsibility] |

## 2. Product Background

Explain the history or situation that led to the product idea. Describe the
current pain points, affected users, current workarounds, and the person or
organization that raised the need. Separate observed facts from assumptions.

| Background point | Evidence or source | Effect on users/organization | Relevance to product |
|---|---|---|---|
| [Current situation] | [Interview, observation, document] | [Effect] | [Why it matters] |
| [Pain point] | [Evidence] | [Effect] | [Product response] |

## 3. Existing Systems

Describe systems that may solve part of the problem or that were reviewed as
references. Do not imply that the project integrates with, represents, is
certified by, or is owned by an external product unless that relationship has
been formally established.

| System / reference | Purpose | Relevant capabilities | Limitations for this project | Relationship to proposed product |
|---|---|---|---|---|
| [System] | [Purpose] | [Capabilities] | [Limitations] | [Reference, replacement, integration, or none] |
| [System] | [Purpose] | [Capabilities] | [Limitations] | [Relationship] |

## 4. Business Opportunity

Describe the business or organizational problem being solved and the
environment in which the product will be used. Include a careful comparison
with current alternatives, the users who benefit, and the reason the
proposed product is attractive. Avoid unsupported market-size claims.

| Opportunity / problem | Current alternative | Gap | Product response | Expected benefit |
|---|---|---|---|---|
| [Problem] | [Alternative] | [Gap] | [Response] | [Benefit] |
| [Problem] | [Alternative] | [Gap] | [Response] | [Benefit] |

## 5. Software Product Vision

Write a concise vision statement and then explain the intended future state.
The vision should balance user needs, organizational value, technical
constraints, available resources, and the approved project boundary.

> **Vision statement:** [One or two sentences describing the product's
> purpose and the improved situation it is intended to create.]

| Vision element | Description |
|---|---|
| Target users | [Who benefits] |
| User problem | [Problem] |
| Product promise | [Value delivered] |
| Differentiating capability | [Capability] |
| Constraint acknowledged | [Constraint] |
| Future direction | [Potential future direction, clearly marked as future] |

## 6. Project Scope & Limitations

Define the solution boundary. List what is included, what is explicitly
excluded, assumptions, dependencies, and limitations. A proposed feature
outside this boundary requires a documented scope decision and an assessment
of its effect on time, effort, quality, and risk.

### 6.1 In-scope features

| Feature ID | Feature | User value | Release | Related requirements |
|---|---|---|---|---|
| F-01 | [Feature] | [Value] | [Release] | [FR/UC IDs] |
| F-02 | [Feature] | [Value] | [Release] | [IDs] |

### 6.2 Out-of-scope features

| Item excluded | Reason | Effect on users | Possible future treatment |
|---|---|---|---|
| [Feature/capability] | [Reason] | [Effect] | [Future decision or Not planned] |
| [Feature/capability] | [Reason] | [Effect] | [Future decision] |

### 6.3 Assumptions, dependencies, and limitations

| Type | Statement | Owner | Impact if false/unavailable | Mitigation |
|---|---|---|---|---|
| Assumption | [Statement] | [Owner] | [Impact] | [Mitigation] |
| Dependency | [Dependency] | [Owner] | [Impact] | [Mitigation] |
| Limitation | [Known limitation] | [Owner] | [Impact] | [Mitigation/communication] |

---

# II. Project Management Plan

This part records how the team planned, estimated, coordinated, reviewed, and
controlled the project work. It should describe what was actually used and
identify material differences between the plan and the final outcome.

## 1. Overview

### 1.1 Scope & Estimation

List the software product functions and classify their complexity. Explain
the estimation basis, assumptions, dependencies, and changes from the
original estimate.

| Feature/function | Complexity | Estimated effort | Actual effort | Basis/assumptions | Requirement IDs |
|---|---|---:|---:|---|---|
| [Feature] | [Simple/Medium/Complex] | [Effort] | [Effort] | [Basis] | [IDs] |
| [Feature] | [Simple/Medium/Complex] | [Effort] | [Effort] | [Basis] | [IDs] |

| Estimate summary | Planned | Actual | Difference | Explanation |
|---|---:|---:|---:|---|
| Requirements | [Value] | [Value] | [Value] | [Explanation] |
| Design | [Value] | [Value] | [Value] | [Explanation] |
| Implementation | [Value] | [Value] | [Value] | [Explanation] |
| Testing | [Value] | [Value] | [Value] | [Explanation] |
| Project management/documentation | [Value] | [Value] | [Value] | [Explanation] |

### 1.2 Project Objectives

State the overall objective and specific targets for scope, quality, schedule,
effort, usability, reliability, and stakeholder acceptance. Mark targets as
planned, achieved, partially achieved, or not measured, and link each target
to evidence.

| Objective ID | Objective / target | Measure | Planned value | Final result | Status | Evidence |
|---|---|---|---|---|---|---|
| OBJ-01 | [Objective] | [Measure] | [Target] | [Result] | [Status] | [Link] |
| OBJ-02 | [Objective] | [Measure] | [Target] | [Result] | [Status] | [Link] |

### 1.3 Project Risks

Record risks that could affect scope, schedule, quality, cost, people,
technology, security, data, or stakeholder acceptance. Include risks that
remain at handover.

| Risk ID | Risk description | Cause | Probability | Impact | Exposure | Mitigation / response | Owner | Status |
|---|---|---|---|---|---|---|---|---|
| R-01 | [Risk] | [Cause] | [Low/Medium/High] | [Low/Medium/High] | [Assessment] | [Response] | [Name] | [Open/closed] |
| R-02 | [Risk] | [Cause] | [Level] | [Level] | [Assessment] | [Response] | [Name] | [Status] |

## 2. Management Approach

Describe how the team organized and controlled the work, including planning,
prioritization, review, change control, communication, quality checks,
escalation, and release decisions.

| Management practice | How it was applied | Owner | Evidence |
|---|---|---|---|
| Planning and prioritization | [Process] | [Role] | [Backlog/plan] |
| Change control | [Process] | [Role] | [Record of changes] |
| Review and approval | [Process] | [Role] | [Review records] |
| Issue and risk escalation | [Process] | [Role] | [Issue/risk list] |

### 2.1 Project Process

Draw and describe the software development process model used by the team.
Show how work moves from an idea or requirement through analysis, design,
implementation, testing, review, and release. Explain how changes return to
earlier activities when a defect or new decision is found.

<!-- Insert the project process diagram here. -->

> **Diagram placeholder:** Figure PM-01 — [Software development process]

| Process stage | Inputs | Main activities | Outputs | Entry/exit decision | Owner |
|---|---|---|---|---|---|
| Requirements | [Inputs] | [Activities] | [Outputs] | [Decision] | [Role] |
| Design | [Inputs] | [Activities] | [Outputs] | [Decision] | [Role] |
| Implementation | [Inputs] | [Activities] | [Outputs] | [Decision] | [Role] |
| Testing | [Inputs] | [Activities] | [Outputs] | [Decision] | [Role] |
| Release | [Inputs] | [Activities] | [Outputs] | [Decision] | [Role] |

### 2.2 Quality Management

Explain how the team planned and evaluated quality. Cover requirement
reviews, design reviews, code review, automated checks, test execution,
defect triage, documentation review, security/access checks, and acceptance.
Distinguish a planned target from a measured result.

| Quality activity | When performed | Entry criteria | Completion criteria | Evidence | Owner |
|---|---|---|---|---|---|
| Requirements review | [When] | [Criteria] | [Criteria] | [Evidence] | [Role] |
| Design review | [When] | [Criteria] | [Criteria] | [Evidence] | [Role] |
| Implementation review | [When] | [Criteria] | [Criteria] | [Evidence] | [Role] |
| Test review | [When] | [Criteria] | [Criteria] | [Evidence] | [Role] |

### 2.3 Training Plan

Identify knowledge or skill gaps and the training needed to complete project
work. Include both technical skills and project practices such as
requirements writing, testing, documentation, security, or tool use.

| Training need | Audience | Trainer/resource | Method | Planned date | Completion evidence |
|---|---|---|---|---|---|
| [Need] | [Members/roles] | [Person/resource] | [Workshop/self-study] | [Date] | [Evidence] |
| [Need] | [Members/roles] | [Resource] | [Method] | [Date] | [Evidence] |

## 3. Project Deliverables

List internal and external deliverables, their owners, approval status, and
location. Include the final release package and all documentation required for
handover.

| Deliverable | Description | Owner | Version | Due/actual date | Acceptance evidence | Location |
|---|---|---|---|---|---|---|
| [Deliverable] | [Description] | [Role] | [Version] | [Dates] | [Evidence] | [Link] |
| [Deliverable] | [Description] | [Role] | [Version] | [Dates] | [Evidence] | [Link] |

## 4. Responsibility Assignments

Describe who is responsible for producing, reviewing, approving, and receiving
each important output. Use a RACI table or an equivalent unambiguous format.

| Work product / activity | Responsible | Accountable | Consulted | Informed |
|---|---|---|---|---|
| Project scope | [Name/role] | [Name/role] | [Names/roles] | [Names/roles] |
| SRS | [Name/role] | [Name/role] | [Names/roles] | [Names/roles] |
| Design | [Name/role] | [Name/role] | [Names/roles] | [Names/roles] |
| Testing | [Name/role] | [Name/role] | [Names/roles] | [Names/roles] |
| Release/user guide | [Name/role] | [Name/role] | [Names/roles] | [Names/roles] |

## 5. Project Communications

Describe the communication plan, the tools, the audience, the frequency, the
information shared, and how decisions are recorded. Do not use an informal
chat message as the only record for a decision that changes scope or quality.

| Communication | Audience | Purpose | Channel/tool | Frequency/trigger | Owner | Decision record |
|---|---|---|---|---|---|---|
| [Meeting/review] | [Audience] | [Purpose] | [Tool] | [Frequency] | [Role] | [Location] |
| [Status report] | [Audience] | [Purpose] | [Tool] | [Frequency] | [Role] | [Location] |

## 6. Configuration Management

Explain how the team identifies, versions, reviews, stores, and releases
documents, source code, configurations, test evidence, and other baselines.

### 6.1 Document Management

| Document type | Naming/version rule | Storage | Review/approval | Change record | Access |
|---|---|---|---|---|---|
| Requirements | [Rule] | [Location] | [Process] | [Record] | [Roles] |
| Design | [Rule] | [Location] | [Process] | [Record] | [Roles] |
| Testing | [Rule] | [Location] | [Process] | [Record] | [Roles] |
| User guides | [Rule] | [Location] | [Process] | [Record] | [Roles] |

### 6.2 Source Code Management

| Item | Rule |
|---|---|
| Repository and branches | [Repository and branch strategy] |
| Commit and review rule | [Rule] |
| Release tags | [Rule] |
| Dependency and lock files | [Rule] |
| Secret handling | [Rule; never commit secret values] |
| Build and deployment artifacts | [Rule and storage] |

### 6.3 Tools & Infrastructures

| Purpose | Tool/infrastructure | Version/configuration | Owner | Access and recovery notes |
|---|---|---|---|---|
| Planning | [Tool] | [Version] | [Role] | [Notes] |
| Source control | [Tool] | [Version] | [Role] | [Notes] |
| Build/deployment | [Tool] | [Version] | [Role] | [Notes] |
| Testing | [Tool] | [Version] | [Role] | [Notes] |
| Documentation/design | [Tool] | [Version] | [Role] | [Notes] |

---

# III. Software Requirement Specification

This part is the final approved SRS. It may be written inline or included by
reference to the final Report 3 artifact. If it is referenced, provide the
exact path, version, date, and approval status.

| SRS field | Value |
|---|---|
| SRS artifact | [Path/link] |
| SRS version/date | [Version/date] |
| Approved by | [Name/role] |
| Scope baseline | [Reference] |

## 1. Product Overview

Describe the product purpose, users, operating context, system boundary,
external connections, assumptions, constraints, and dependencies. Include the
context diagram and explain every external entity and flow.

> **Diagram placeholder:** Figure SRS-01 — [Product context diagram]

## 2. User Requirements

List the agreed human and external actors. Provide use-case diagrams and
descriptions that identify the goal, trigger, preconditions, normal flow,
alternate/exception flow, result, and authorization boundary.

| Actor/use case ID | Actor or use case | Goal | Main result | Related requirements |
|---|---|---|---|---|
| [ACT/UC ID] | [Name] | [Goal] | [Result] | [IDs] |

> **Diagram placeholder:** Figure SRS-02 — [Use-case diagram]

## 3. Functional Requirements

Describe the system functional overview, screen flow, screen descriptions,
authorization, non-screen functions, ERD, and each feature/function in enough
detail to be testable.

### 3.1 System Functional Overview

> **Diagram placeholder:** Figure SRS-03 — [Screen-flow diagram]

| Screen/activity | Platform | Purpose | Roles | Main data | Related IDs |
|---|---|---|---|---|---|
| [Screen/activity] | [Platform] | [Purpose] | [Roles] | [Data] | [IDs] |

| Screen/activity | Platform Admin | Platform Author | Host | Proctor | Examiner | Student |
|---|:---:|:---:|:---:|:---:|:---:|:---:|
| [Screen/activity] | [X/-] | [X/-] | [X/-] | [X/-] | [X/-] | [X/-] |

> **Diagram placeholder:** Figure SRS-04 — [Entity relationship diagram]

### 3.2 [Feature Name 1]

| Area | Details |
|---|---|
| Trigger | [Navigation, event, or schedule] |
| Actors | [Roles/systems] |
| Inputs | [Fields/data] |
| Validation | [Rules] |
| Business rules | [Rules] |
| Normal flow | [Steps] |
| Alternate/abnormal flow | [Errors, retries, recovery] |
| Outputs | [Screen state, response, event, stored data] |

### 3.3 [Feature Name 2]

Repeat the feature specification for every approved feature. Keep
requirements uniquely identified and traceable.

## 4. Non-Functional Requirements

Document external interfaces and quality attributes such as usability,
reliability, performance, security, maintainability, compatibility,
portability, accessibility, auditability, and data protection. Each target
must state its measure or observable acceptance criterion and its evidence
source.

| Requirement ID | Quality/interface requirement | Measure or acceptance criterion | Evidence | Status |
|---|---|---|---|---|
| [NFR-ID] | [Requirement] | [Criterion] | [Test/review] | [Status] |

## 5. Requirement Appendix

### 5.1 Business Rules

| Rule ID | Rule definition | Affected features | Source/owner |
|---|---|---|---|
| BR-01 | [Rule] | [Features] | [Source/owner] |

### 5.2 Common Requirements

| Requirement ID | Common requirement | Scope |
|---|---|---|
| CR-01 | [Requirement] | [System/features] |

### 5.3 Application Messages List

| Message code | Type | Context | Content | Related requirement |
|---|---|---|---|---|
| MSG-01 | [Inline/toast/dialog/field error] | [Context] | [Message] | [ID] |

### 5.4 Other Requirements

[Internationalization, legal, licensing, audit, migration, deployment, or
other requirements not covered above.]

---

# IV. Software Design Description

This part is the final approved design. It may be written inline or included
by reference to the final Report 4 artifact.

| Design field | Value |
|---|---|
| Design artifact | [Path/link] |
| Design version/date | [Version/date] |
| Reviewed by | [Name/role] |
| Related SRS version | [Version/date] |

## 1. System Design

### 1.1 System Architecture

> **Diagram placeholder:** Figure SDD-01 — [System architecture]

| Component | Responsibility | Owned data | Interfaces | Dependencies | Deployment location |
|---|---|---|---|---|---|
| [Component] | [Responsibility] | [Data] | [Interfaces] | [Dependencies] | [Location] |

### 1.2 Package Diagram

> **Diagram placeholder:** Figure SDD-02 — [Package diagram]

| Package | Responsibility | Main classes/modules | Allowed dependencies |
|---|---|---|---|
| [Package] | [Responsibility] | [Classes/modules] | [Dependencies] |

## 2. Database Design

> **Diagram placeholder:** Figure SDD-03 — [Database ERD/table relationship]

| Table/entity | Purpose | Primary keys | Foreign keys | Important constraints | Owner |
|---|---|---|---|---|---|
| [Table/entity] | [Purpose] | [Keys] | [Keys] | [Constraints] | [Package] |

## 3. Detailed Design

### 3.1 [Feature/Function Name 1]

> **Diagram placeholder:** Figure SDD-04 — [Class diagram]

| Class/interface | Responsibility | Main attributes | Public operations | Collaborators |
|---|---|---|---|---|
| [Class] | [Responsibility] | [Attributes] | [Operations] | [Collaborators] |

> **Diagram placeholder:** Figure SDD-05 — [Sequence diagram]

| Step | Sender | Receiver | Message/data | Result/error path |
|---:|---|---|---|---|
| 1 | [Sender] | [Receiver] | [Message] | [Result] |

### 3.2 [Feature/Function Name 2]

Repeat the design for each significant feature. Reuse shared class or
sequence diagrams by reference and identify the feature-specific differences.

---

# V. Software Testing Documentation

This part is the final testing plan and evidence summary. It may be written
inline or included by reference to the final Report 5 artifact.

| Testing field | Value |
|---|---|
| Test artifact | [Path/link] |
| Test document version/date | [Version/date] |
| Test conclusion | [Pass/conditional/not ready] |
| Approved by | [Name/role] |

## 1. Scope of Testing

| Area | Included | Excluded | Reason/risk |
|---|---|---|---|
| [Feature/quality area] | [What is tested] | [What is not tested] | [Reason/risk] |

## 2. Test Strategy

### 2.1 Testing Types

| Test type | Objective | Technique | Completion criteria | Owner |
|---|---|---|---|---|
| [Type] | [Objective] | [Technique] | [Criteria] | [Role] |

### 2.2 Test Levels

| Type of tests | Unit | Integration | System | Acceptance |
|---|:---:|:---:|:---:|:---:|
| [Test type 1] | X |  |  |  |
| [Test type 2] |  | X | X |  |

### 2.3 Supporting Tools

| Purpose | Tool | Provider | Version | Evidence |
|---|---|---|---|---|
| [Purpose] | [Tool] | [Provider] | [Version] | [Path/link] |

## 3. Test Plan

### 3.1 Human Resources

| Worker/doer | Role | Responsibilities |
|---|---|---|
| [Name] | [Role] | [Responsibilities] |

### 3.2 Test Environment

| Environment | Software/build | Hardware/device | Data/accounts | Owner |
|---|---|---|---|---|
| [Environment] | [Details] | [Details] | [Details] | [Role] |

### 3.3 Test Milestones

| Milestone task | Start date | End date | Exit deliverable | Status |
|---|---|---|---|---|
| [Task] | [Date] | [Date] | [Deliverable] | [Status] |

## 4. Test Cases

Reference the detailed unit, integration, system, and acceptance test case
files. Every case should identify its requirement, preconditions, steps,
expected result, actual result, evidence, and result.

| Test case ID | Requirement | Level/type | Result | Defect reference | Evidence |
|---|---|---|---|---|---|
| [TC-ID] | [Requirement] | [Level/type] | [Result] | [DEF/None] | [Link] |

## 5. Test Reports

| Run/build | Planned | Executed | Passed | Failed | Blocked/skipped | Conclusion |
|---|---:|---:|---:|---:|---:|---|
| [Run/build] | [Count] | [Count] | [Count] | [Count] | [Count] | [Conclusion] |

Explain the important failures, unresolved defects, limitations, and release
decision. Link the supporting evidence.

---

# VI. Release Package & User Guides

This part is the final release inventory, installation guide, and user manual.
It may be written inline or included by reference to the final Report 6
artifact.

| Release field | Value |
|---|---|
| Release artifact | [Path/link] |
| Release version/tag | [Version/tag] |
| Release date | [YYYY-MM-DD] |
| Release owner | [Name/role] |
| Support contact | [Contact/channel] |

## 1. Deliverable Package

| No. | Deliverable item | Version | Description | Location | Verified |
|---:|---|---|---|---|:---:|
| 1 | Project schedule/tracking | [Version] | [Description] | [Link] | [ ] |
| 2 | Project backlog | [Version] | [Description] | [Link] | [ ] |
| 3 | Source codes | [Commit/tag] | [Description] | [Link] | [ ] |
| 4 | Database scripts | [Version] | [Description] | [Link] | [ ] |
| 5 | Final report document | [Version] | [Description] | [Link] | [ ] |
| 6 | Test cases document | [Version] | [Description] | [Link] | [ ] |
| 7 | Defects list | [Version] | [Description] | [Link] | [ ] |
| 8 | Issues list | [Version] | [Description] | [Link] | [ ] |
| 9 | Slides | [Version] | [Description] | [Link] | [ ] |

## 2. Installation Guides

### 2.1 System Requirements

| Category | Requirement | Version/capacity | Verification |
|---|---|---|---|
| Operating system/runtime | [Requirement] | [Version] | [Check] |
| Database/supporting services | [Requirement] | [Version] | [Check] |
| Network/storage/permissions | [Requirement] | [Details] | [Check] |
| End-user devices | [Requirement] | [Details] | [Check] |

### 2.2 Installation Instruction

| Step | Action | Expected result | Evidence/checkpoint |
|---:|---|---|---|
| 1 | [Prepare package and configuration] | [Result] | [Evidence] |
| 2 | [Apply schema/configuration] | [Result] | [Evidence] |
| 3 | [Start services/application] | [Result] | [Evidence] |
| 4 | [Run post-install checks] | [Result] | [Evidence] |

Document configuration, verification, rollback, and troubleshooting. Never
include real secret values.

## 3. User Manual

### 3.1 Overview

Describe the purpose of the released application, the user roles, the
navigation areas, common statuses/messages, access rules, and support path.

> **Diagram placeholder:** Figure UG-01 — [Application overview/workflow]

### 3.2 Workflow 1 — [Workflow name]

| Item | Description |
|---|---|
| Purpose | [Outcome] |
| Actor | [Role] |
| Preconditions | [Conditions] |
| Success result | [Result] |
| Failure/recovery | [Recovery] |

> **Diagram placeholder:** Figure UG-02 — [Workflow 1]

| Step | Screen/location | User action | Expected result | Screenshot/reference |
|---:|---|---|---|---|
| 1 | [Screen] | [Action] | [Result] | [Link] |
| 2 | [Screen] | [Action] | [Result] | [Link] |

### 3.3 Workflow 2 — [Workflow name]

Repeat the complete workflow structure for another important user outcome.
Add more workflow sections when required by the product scope.

| Step | Screen/location | User action | Expected result | Screenshot/reference |
|---:|---|---|---|---|
| 1 | [Screen] | [Action] | [Result] | [Link] |
| 2 | [Screen] | [Action] | [Result] | [Link] |

---

## Appendices

### Appendix A — Requirements/design/test traceability

| Requirement ID | Design section/figure | Test case/run | Release/user-guide section | Status |
|---|---|---|---|---|
| [FR/NFR/UC ID] | [Reference] | [Reference] | [Reference] | [Status] |

### Appendix B — Open issues and known limitations

| Issue ID | Description | Impact | Workaround | Owner | Planned resolution |
|---|---|---|---|---|---|
| [ISS-01] | [Issue] | [Impact] | [Workaround] | [Role] | [Plan] |

### Appendix C — References

| Reference | Description | Version/date | Location |
|---|---|---|---|
| [Reference] | [Description] | [Version/date] | [Link/path] |

### Appendix D — Final report review checklist

| Checklist item | Status | Evidence / reviewer |
|---|:---:|---|
| Project scope matches the approved registration and review decisions. | [ ] | [Reference] |
| Team members, roles, supervisor, and project code are consistent. | [ ] | [Reference] |
| Requirements, design, tests, and release guides use matching identifiers. | [ ] | [Reference] |
| Every in-scope feature has requirements, design coverage, and test evidence. | [ ] | [Reference] |
| Out-of-scope items and known limitations are stated clearly. | [ ] | [Reference] |
| Figures and tables have captions, identifiers, and readable labels. | [ ] | [Reference] |
| All referenced artifacts are included or linked to the final release. | [ ] | [Reference] |
| No credentials, tokens, private keys, or real secret values are included. | [ ] | [Review result] |
| Final report has been reviewed and approved by the required parties. | [ ] | [Approval record] |

