# Report 6 — Software User Guides

## Template information

| Field | Value |
|---|---|
| Template source | Report6_Software User Guides.docx |
| Template status | Draft |
| Project | [Project name] |
| Project code | [Project code] |
| Release / version | [Version] |
| Date | [YYYY-MM-DD] |
| Prepared by | [Name / role] |
| Technical owner | [Name / role] |
| Support contact | [Contact or support channel] |
| Related release | [Build, tag, or release identifier] |

> **How to use this template:** Write instructions for the people who install,
> operate, administer, or use the product. Use the names and labels that
> appear in the released interface. Each procedure should state who can
> perform it, what must be true before it starts, the exact steps, the
> expected result, and what to do when the result is not obtained.

> **Evidence and safety:** Use screenshots or screen references that match the
> documented release. Mask personal information, tokens, passwords, private
> keys, and other secrets in every screenshot and example. If a procedure
> changes or deletes data, explain the effect and include the confirmation or
> recovery step.

---

## I. Record of Changes

| Date | A*M, D | In charge | Change Description | Reference |
|---|---|---|---|---|
| [YYYY-MM-DD] | A | [Name] | [Describe the added guide or release content] | [Release/review] |
| [YYYY-MM-DD] | M | [Name] | [Describe the modified installation or user instruction] | [Defect/feature/release] |
| [YYYY-MM-DD] | D | [Name] | [Describe the removed instruction] | [Decision/release] |
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

*A — Added; M — Modified; D — Deleted. Record changes that affect the
reader's ability to install, operate, or use the release.*

---

## II. Release Package & User Guides

### 1. Deliverable Package

List every item included in the release or handed over to the project
stakeholder. Include a version or commit identifier, location, owner, and
verification status. The original document provides the following baseline
items; keep an item only when it belongs to the project.

| No. | Deliverable item | Version / identifier | Description and contents | Location | Owner | Verified |
|---:|---|---|---|---|---|:---:|
| 1 | Project schedule / tracking | [Version/date] | [What is included] | [Path/link] | [Role] | [ ] |
| 2 | Project backlog | [Version/date] | [What is included] | [Path/link] | [Role] | [ ] |
| 3 | Source code | [Commit/tag] | [Applications, modules, or packages] | [Repository/path] | [Role] | [ ] |
| 4 | Database scripts | [Version/date] | [Migrations, seed data, or schema scripts] | [Path/link] | [Role] | [ ] |
| 5 | Final report document | [Version/date] | [Report 7 or final report] | [Path/link] | [Role] | [ ] |
| 6 | Test cases document | [Version/date] | [Test cases and traceability] | [Path/link] | [Role] | [ ] |
| 7 | Defects list | [Version/date] | [Open and closed defects] | [Path/link] | [Role] | [ ] |
| 8 | Issues list | [Version/date] | [Known issues, risks, and decisions] | [Path/link] | [Role] | [ ] |
| 9 | Presentation slides | [Version/date] | [Review or final presentation] | [Path/link] | [Role] | [ ] |
| 10 | Installation package / deployment files | [Version/date] | [Build or deployment artifacts] | [Path/link] | [Role] | [ ] |
| 11 | User guide | [Version/date] | [This guide and related role guides] | [Path/link] | [Role] | [ ] |

#### Release identification

| Item | Value |
|---|---|
| Release name | [Name] |
| Application version | [Version] |
| Source commit/tag | [Identifier] |
| Build date | [YYYY-MM-DD] |
| Supported environments | [Environment list] |
| Known limitations | [Short list with issue references] |
| Rollback artifact | [Location or Not applicable] |

### 2. Installation Guides

This section explains how an authorized operator installs and prepares the
release. Separate local development, test, staging, and production
instructions when their prerequisites or risk differ. Never place real
credentials in this document; refer to the approved secret-management
procedure instead.

#### 2.1 System Requirements

Define the hardware, software, network, storage, account, permission, and
external-service requirements needed to install and run the application.
Include a version or compatibility range where the result depends on it.

##### Operator or server requirements

| Category | Requirement | Version / capacity | How to verify | Notes |
|---|---|---|---|---|
| Operating system | [Operating system] | [Version] | [Command or screen] | [Notes] |
| Runtime | [Runtime/framework] | [Version] | [Check] | [Notes] |
| Database | [Database] | [Version] | [Check] | [Schema/extension] |
| Supporting services | [Cache, queue, storage, etc.] | [Version] | [Check] | [Notes] |
| Network | [DNS, ports, outbound access] | [Requirement] | [Check] | [Restrictions] |
| Storage | [Application and data storage] | [Requirement] | [Check] | [Growth/backup] |
| Permissions | [Operating/system permissions] | [Requirement] | [Check] | [Least privilege] |

##### End-user device requirements

| User group | Device / operating system | Supported browser/app version | Input/output devices | Network requirement | Notes |
|---|---|---|---|---|---|
| [Role] | [Device/OS] | [Version] | [Microphone, camera, headset, etc.] | [Requirement] | [Notes] |
| [Role] | [Device/OS] | [Version] | [Devices] | [Requirement] | [Notes] |

##### Configuration and external-service prerequisites

| Prerequisite | Required value or setup | Owner | Verification | Failure impact |
|---|---|---|---|---|
| [Database/schema] | [Setup] | [Role] | [Check] | [Impact] |
| [External service] | [Approved account/endpoint/configuration] | [Role] | [Check] | [Impact] |
| [Domain/TLS] | [Setup] | [Role] | [Check] | [Impact] |

#### 2.2 Installation Instruction

Write the steps in the order an operator must perform them. Distinguish
commands from explanations, identify where each command is run, and document
the expected output or state after every important step.

##### Before installation

| Check | Expected result | Evidence / owner |
|---|---|---|
| Release package and checksum/tag are available. | [Result] | [Evidence] |
| Required access and approved configuration are available. | [Result] | [Evidence] |
| Backup or rollback point is confirmed when existing data may be changed. | [Result] | [Evidence] |
| Dependencies and external services are reachable. | [Result] | [Evidence] |
| Maintenance window and communication plan are confirmed. | [Result] | [Evidence] |

##### Installation steps

| Step | Where / who | Action | Expected result | Evidence or checkpoint |
|---:|---|---|---|---|
| 1 | [Machine/role] | [Prepare directory, package, or dependency] | [Result] | [Checkpoint] |
| 2 | [Machine/role] | [Apply configuration through the approved mechanism] | [Result] | [Checkpoint] |
| 3 | [Machine/role] | [Create/update database schema] | [Result] | [Migration output] |
| 4 | [Machine/role] | [Install/start application services] | [Result] | [Service status] |
| 5 | [Machine/role] | [Run health check or smoke test] | [Result] | [Test evidence] |
| 6 | [Machine/role] | [Complete handoff and communicate status] | [Result] | [Handoff record] |

##### Configuration guidance

Describe each setting that an operator is expected to provide or verify.
Separate non-sensitive configuration from secrets and link to the approved
secret-management process for the latter.

| Setting | Purpose | Required? | Allowed form / example | Source of truth | Safe change procedure |
|---|---|:---:|---|---|---|
| [Setting name] | [Purpose] | Yes/No | [Non-sensitive example] | [Document/system] | [Procedure] |
| [Secret reference] | [Purpose] | Yes/No | [Reference only; never a real value] | [Secret manager] | [Procedure] |

##### Post-installation verification

| Check | Expected result | Actual result | Evidence | Pass/fail |
|---|---|---|---|:---:|
| Application starts and reports healthy. | [Expected] | [Observed] | [Link] | [ ] |
| Sign-in and role boundary work. | [Expected] | [Observed] | [Link] | [ ] |
| Main read/write workflow works with test data. | [Expected] | [Observed] | [Link] | [ ] |
| Database and background processing work as expected. | [Expected] | [Observed] | [Link] | [ ] |
| Logs and monitoring contain no unexpected critical error. | [Expected] | [Observed] | [Link] | [ ] |

##### Rollback, uninstall, and recovery

| Scenario | Detection | Action | Data impact | Verification | Owner |
|---|---|---|---|---|---|
| [Installation failure] | [How detected] | [Rollback steps] | [Impact] | [Check] | [Role] |
| [Release rollback] | [How detected] | [Steps] | [Impact] | [Check] | [Role] |
| [Uninstall/decommission] | [How detected] | [Steps] | [Data retention/deletion] | [Check] | [Role] |

##### Installation troubleshooting

| Symptom / message | Likely cause | Diagnostic step | Corrective action | Escalation |
|---|---|---|---|---|
| [Symptom] | [Cause] | [Check] | [Action] | [Team/contact] |
| [Symptom] | [Cause] | [Check] | [Action] | [Team/contact] |

### 3. User Manual

This section is written for end users and administrators. Use plain language,
describe one outcome at a time, and avoid implementation terms unless the
reader must perform a technical operation. Add a separate guide or subsection
for each role when permissions or workflows differ.

#### 3.1 Overview

Describe:

- the purpose of the application and the problems it helps the user solve;
- the intended audience and the role-specific responsibilities;
- how the main areas of the application are organized;
- the key terms, statuses, and actions a user will see;
- how to sign in, sign out, recover access, and obtain support;
- the important rules that apply to all workflows;
- what information is saved, submitted, published, or visible to others;
- what to do when the application is offline, unavailable, or reports an
  error.

<!-- Insert a product overview image or feature workflow diagram here when it
helps a new user understand the complete application. -->

> **Diagram placeholder:** Figure UG-01 — [Product overview / feature workflow]

##### Role and navigation summary

| Role / audience | Main goals | Available areas | Important restrictions | Related workflows |
|---|---|---|---|---|
| [Role] | [Goals] | [Areas] | [Restrictions] | [Sections] |
| [Role] | [Goals] | [Areas] | [Restrictions] | [Sections] |

##### Common interface conventions

| Convention | Meaning / user action |
|---|---|
| [Navigation item] | [Where it leads and when to use it] |
| [Status label] | [Meaning and allowed next actions] |
| [Required-field marker] | [How missing input is shown] |
| [Confirmation dialog] | [When the action is irreversible or affects other users] |
| [Notification/message] | [How success, warning, and error messages are presented] |

#### 3.2 Workflow 1 — [Workflow name]

Describe the purpose of the workflow, the user who performs it, and the
outcome that confirms completion. Add a workflow diagram and any relevant
state or role diagram.

| Item | Description |
|---|---|
| Workflow ID | [WF-01] |
| Purpose | [User outcome] |
| Primary actor | [Role] |
| Supporting actors/services | [Roles/systems] |
| Preconditions | [What must already be true] |
| Starting point | [Screen, link, notification, or event] |
| Success result | [What is saved, published, or shown] |
| Alternate results | [Valid alternatives] |
| Failure/recovery | [What the user should do] |
| Permissions | [Who can view/create/update/submit] |

<!-- Insert the workflow diagram here. Use a readable diagram that follows the
same step names as the instructions below. -->

> **Diagram placeholder:** Figure UG-02 — [Workflow 1 diagram]

##### Step-by-step instructions

| Step | Screen or location | User action | Information to enter/select | Expected result | Screenshot/reference |
|---:|---|---|---|---|---|
| 1 | [Screen] | [Action] | [Data] | [Result] | [Image/link] |
| 2 | [Screen] | [Action] | [Data] | [Result] | [Image/link] |
| 3 | [Screen] | [Action] | [Data] | [Result] | [Image/link] |
| 4 | [Screen] | [Action] | [Data] | [Result] | [Image/link] |

##### Validation, messages, and recovery

| Situation | Message or visible result | User action | Data preserved? | Escalation |
|---|---|---|:---:|---|
| [Missing/invalid input] | [Message] | [Correction] | Yes/No | [Contact] |
| [Permission denied] | [Message] | [Required role/action] | Yes/No | [Contact] |
| [Network/service failure] | [Message] | [Retry/offline/recovery] | Yes/No | [Contact] |

##### Completion checklist

| Check | Done |
|---|:---:|
| The intended record or action is visible in the expected status. | [ ] |
| The user has received or can access the expected confirmation/report. | [ ] |
| No duplicate or unintended record was created. | [ ] |
| Any follow-up task or notification is understood. | [ ] |

#### 3.3 Workflow 2 — [Workflow name]

Repeat the complete workflow structure above. Describe a different important
user outcome rather than combining unrelated tasks into a vague procedure.

| Item | Description |
|---|---|
| Workflow ID | [WF-02] |
| Purpose | [User outcome] |
| Primary actor | [Role] |
| Supporting actors/services | [Roles/systems] |
| Preconditions | [Conditions] |
| Starting point | [Screen/event] |
| Success result | [Result] |
| Alternate results | [Alternatives] |
| Failure/recovery | [Recovery] |
| Permissions | [Access rules] |

> **Diagram placeholder:** Figure UG-03 — [Workflow 2 diagram]

| Step | Screen or location | User action | Information to enter/select | Expected result | Screenshot/reference |
|---:|---|---|---|---|---|
| 1 | [Screen] | [Action] | [Data] | [Result] | [Image/link] |
| 2 | [Screen] | [Action] | [Data] | [Result] | [Image/link] |
| 3 | [Screen] | [Action] | [Data] | [Result] | [Image/link] |

<!-- Add more workflow sections (3.4, 3.5, ...) as required by the released
features and user roles. -->

### 4. Support, Troubleshooting, and Frequently Asked Questions

This optional section gives users a safe path when a workflow cannot be
completed. Do not ask users to change protected settings or reveal secrets.

| Question or symptom | Likely explanation | User action | When to contact support | Reference |
|---|---|---|---|---|
| [Question/symptom] | [Explanation] | [Action] | [Escalation condition] | [Workflow/issue] |
| [Question/symptom] | [Explanation] | [Action] | [Escalation condition] | [Reference] |

## Appendix A — Screenshot and terminology inventory

| ID | Screen / screenshot | Release/build | Used in sections | Data masked? | Owner |
|---|---|---|---|:---:|---|
| IMG-01 | [Screen name] | [Build] | [Sections] | Yes/No | [Name] |

| Term | User-facing meaning | Notes / related status |
|---|---|---|
| [Term] | [Plain-language definition] | [Notes] |

## Appendix B — Guide review checklist

| Checklist item | Status | Evidence / reviewer |
|---|:---:|---|
| Instructions match the released interface and build. | [ ] | [Reference] |
| Every procedure names its actor, preconditions, outcome, and failure path. | [ ] | [Reference] |
| Screenshots are readable and contain no personal data or secrets. | [ ] | [Reference] |
| Installation instructions identify configuration, verification, and rollback. | [ ] | [Reference] |
| Role restrictions and data-changing actions are clearly stated. | [ ] | [Reference] |
| Links and referenced artifacts are accessible to the intended audience. | [ ] | [Reference] |
| A user who follows the guide can complete the workflow without guessing. | [ ] | [Reference] |

