# Report 3 — Software Requirement Specification

## Template information

| Field | Value |
|---|---|
| Template source | Report3_Software Requirement Specification.docx |
| Template status | Draft |
| Project | [Project name] |
| Version | [Version] |
| Date | [YYYY-MM-DD] |
| Prepared by | [Name / role] |

> **How to use this template:** Replace text in square brackets and angle
> brackets, add rows where needed, and remove the sample text after adapting
> it to the project. Keep requirement IDs stable after they have been
> referenced by design, development, or test artifacts.

---

## I. Record of Changes

| Date | A*M, D | In charge | Change Description |
|---|---|---|---|
| [YYYY-MM-DD] | A | [Name] | [Describe the change] |
| [YYYY-MM-DD] | M | [Name] | [Describe the change] |
| [YYYY-MM-DD] | D | [Name] | [Describe the change] |
|  |  |  |  |
|  |  |  |  |
|  |  |  |  |
|  |  |  |  |
|  |  |  |  |
|  |  |  |  |
|  |  |  |  |
|  |  |  |  |
|  |  |  |  |
|  |  |  |  |

*A — Added; M — Modified; D — Deleted*

---

## II. Software Requirement Specification

### 1. Product Overview

Describe the overall product, its purpose, and the context in which it will
operate. Include a context diagram that shows the system boundary and the
connections between the system and external software, hardware, people, and
other systems.

> **Sample text (replace):** The Cafeteria Ordering System is a new software
> system that replaces the current manual and telephone processes for ordering
> and picking up meals in the Process Impact cafeteria. The context diagram
> below illustrates the external entities and system interfaces for release
> 1.0. The system is expected to evolve over several releases, ultimately
> connecting to Internet ordering services for local restaurants and to credit
> and debit card authorization services.

#### Context Diagram

<!-- Insert the context diagram here. Describe every external entity and data,
control, or material flow shown in the diagram. -->

> **Diagram placeholder:** Insert the project context diagram here.

### 2. User Requirements

#### 2.1 Actors

An actor is a person, software system, or hardware device that interacts with
the system to perform a use case. Use the following questions to identify
actors:

- Who or what is notified when something occurs within the system?
- Who or what provides information or services to the system?
- Who or what helps the system respond to and complete a task?

| # | Actor | Description |
|---:|---|---|
| 1 | [Actor name] | [Role, goal, and relationship with the system] |
| 2 | [Actor name] | [Role, goal, and relationship with the system] |
| 3 | [Actor name] | [Role, goal, and relationship with the system] |

#### 2.2 Use Cases

A use case describes a sequence of interactions between the system and an
external actor that results in an outcome of value for the actor. Use a strong
name in the form **verb + object**, for example, View Menu or Submit Order.

##### 2.2.1 Diagram(s)

<!-- Insert one or more use-case diagrams here. Show actor-to-use-case and
use-case-to-use-case relationships. Add a short caption for each diagram. -->

> **Diagram placeholder:** Insert one or more project use-case diagrams here.

##### 2.2.2 Descriptions

| ID | Use Case | Actors | Use Case Description |
|---|---|---|---|
| UC-01 | [Verb + object] | [Actor(s)] | [Outcome and short summary] |
| UC-02 | [Verb + object] | [Actor(s)] | [Outcome and short summary] |
| UC-03 | [Verb + object] | [Actor(s)] | [Outcome and short summary] |

### 3. Functional Requirements

#### 3.1 System Functional Overview

Provide an overview of the software functionality. Cover screen flow, screen
descriptions, system roles, screen authorization, non-screen functions, and the
entity relationship model.

##### 3.1.1 Screens Flow

<!-- Insert a screen-flow diagram. Use a different notation for normal screens,
pop-up screens, and screens with multiple information tabs when useful. -->

> **Diagram placeholder:** Insert the project screen-flow diagram here.

##### 3.1.2 Screen Descriptions

Describe every screen shown in the screen-flow diagram.

| # | Feature | Screen | Description |
|---:|---|---|---|
| 1 | [Feature name] | [Screen name] | [Brief screen description] |
| 2 | [Feature name] | [Screen name] | [Brief screen description] |
| 3 | [Feature name] | [Screen name] | [Brief screen description] |

##### 3.1.3 Screen Authorization

Replace Role 1, Role 2, and Role 3 with the project roles. Add or remove
columns and rows so that every screen activity has an explicit authorization
decision.

| Screen / activity | Role 1 | Role 2 | Role 3 | [Role N] |
|---|:---:|:---:|:---:|:---:|
| [Screen name] | X |  | X |  |
| └ [Screen activity] |  |  | X | X |
| [Screen name] | X |  | X |  |
| └ Query all data | X |  |  |  |
| └ Query own data |  |  | X |  |
| └ Query managed data |  |  | X |  |
| └ Add new data |  |  | X | X |
| └ Update all data |  |  |  | X |
| └ Update own data |  |  |  | X |
| └ Update managed data |  |  |  | X |
| └ Delete data |  |  |  |  |
| └ [Other activity] |  |  |  |  |

##### 3.1.4 Non-Screen Functions

Describe non-screen system functions such as batch jobs, scheduled jobs,
services, integrations, and APIs.

| # | Feature | System Function | Description |
|---:|---|---|---|
| 1 | [Feature name] | [Function name] | [Function description] |
| 2 | [Feature name] | [Function name] | [Function description] |
| 3 | [Feature name] | [Function name] | [Function description] |

##### 3.1.5 Entity Relationship Diagram

<!-- Insert the entity relationship diagram and describe the entities below. -->

> **Diagram placeholder:** Insert the project entity relationship diagram here.

**Entities Description**

| # | Entity | Description |
|---:|---|---|
| 1 | [Entity name] | [Purpose and important relationships] |
| 2 | [Entity name] | [Purpose and important relationships] |
| 3 | [Entity name] | [Purpose and important relationships] |
| 4 | [Entity name] | [Purpose and important relationships] |

#### 3.2 [Feature Name 1]

##### 3.2.1 [Function Name 1]

A function can be a screen function or a non-screen function listed in
Section 3.1.4. Describe the following:

- **Function trigger:** How the function is triggered, such as a navigation
  path, event, or schedule.
- **Function description:** Actors or roles, purpose, interface, and data
  processing.
- **Screen layout:** Link to or embed a mock-up or prototype when applicable.
- **Function details:** Data fields, validation, business rules, normal cases,
  and abnormal cases.

**Function trigger:** [Trigger, navigation path, event, or frequency]

**Function description:** [Describe actors, purpose, interface, and processing]

**Screen layout / prototype:** [Link, image, or Not applicable]

**Function details**

| Area | Details |
|---|---|
| Inputs | [Fields, formats, and source] |
| Validation | [Required fields, ranges, formats, and cross-field rules] |
| Business rules | [Rules applied by this function] |
| Normal flow | [Expected successful behavior] |
| Abnormal flow | [Validation errors, timeouts, retries, and recovery] |
| Outputs | [Screen state, response, event, or persisted data] |

##### 3.2.2 [Function Name 2]

[Repeat the function specification above.]

#### 3.3 [Feature Name 2]

##### 3.3.1 [Function Name]

[Repeat the function specification above.]

##### 3.3.2 [Function Name]

[Repeat the function specification above.]

#### 3.4 [Feature Name N]

[Add feature sections and function subsections as required.]

### 4. Non-Functional Requirements

#### 4.1 External Interfaces

Describe the requirements that ensure the system communicates correctly with
users, external hardware, external software, and other systems.

| Interface | External party | Data exchanged | Protocol / format | Authentication | Constraints |
|---|---|---|---|---|---|
| [Interface name] | [System, device, or actor] | [Data] | [HTTPS, WebSocket, file, etc.] | [Method] | [Limits or rules] |
| [Interface name] | [System, device, or actor] | [Data] | [Protocol / format] | [Method] | [Limits or rules] |

#### 4.2 Quality Attributes

List the required system characteristics. Each requirement should be
measurable where possible and should identify the affected feature or use case.

##### 4.2.1 Usability

Specify requirements that affect usability, such as training time, task
completion time, accessibility, supported languages, and conformance to
recognized user-interface standards.

| Requirement | Measure / acceptance criterion | Related feature or use case |
|---|---|---|
| [Usability requirement] | [Numeric or observable criterion] | [ID] |

##### 4.2.2 Reliability

Specify availability, maintenance access, degraded-mode behavior, mean time
between failures, mean time to repair, output accuracy, and defect-rate
targets as applicable.

| Requirement | Measure / acceptance criterion | Related feature or use case |
|---|---|---|
| Availability | [e.g., percentage and measurement period] | [ID] |
| Mean time between failures | [Target] | [ID] |
| Mean time to repair | [Target] | [ID] |
| Accuracy | [Definition and target] | [ID] |
| Maximum bug / defect rate | [Target, such as bugs per KLOC or function-point] | [ID] |
| Defect-rate classification | [Define minor, significant, and critical defects] | [ID] |

##### 4.2.3 Performance

Specify response time, throughput, capacity, and resource-utilization
requirements. Reference related use cases by name where applicable.

| Requirement | Measure / acceptance criterion | Related feature or use case |
|---|---|---|
| Response time | [Average / maximum threshold] | [ID] |
| Throughput | [Transactions per second or equivalent] | [ID] |
| Capacity | [Users, records, files, or transactions] | [ID] |
| Resource utilization | [CPU, memory, disk, network target] | [ID] |

##### 4.2.4 [Quality Attribute Name]

[Add Security, Maintainability, Portability, Compatibility, or another
quality-attribute section when required.]

| Requirement | Measure / acceptance criterion | Related feature or use case |
|---|---|---|
| [Quality requirement] | [Numeric or observable criterion] | [ID] |

### 5. Requirement Appendix

Use this section for business rules, common requirements, application
messages, and other requirements that apply across multiple features.

#### 5.1 Business Rules

List the common business rules that the system must follow.

| ID | Rule Definition |
|---|---|
| BR-01 | [Business rule] |
| BR-02 | [Business rule] |
| BR-03 | [Business rule] |
| BR-04 | [Business rule] |
| BR-05 | [Business rule] |

> **Sample rules from the source template (replace or remove):**
>
> | ID | Rule Definition |
> |---|---|
> | BR-01 | Delivery time windows are 15 minutes, beginning on each quarter hour. |
> | BR-02 | Deliveries must be completed between 10:00 A.M. and 2:00 P.M. local time, inclusive. |
> | BR-03 | All meals in a single order must be delivered to the same location. |
> | BR-04 | All meals in a single order must be paid for by using the same payment method. |
> | BR-11 | If an order is to be delivered, the patron must pay by payroll deduction. |
> | BR-12 | Order price is calculated as the sum of each food item price times its quantity, plus applicable sales tax and a delivery charge when applicable. |
> | BR-24 | Only cafeteria employees designated as Menu Managers by the Cafeteria Manager can create, modify, or delete cafeteria menus. |
> | BR-33 | Network transmissions that involve financial information or personally identifiable information require 256-bit encryption. |
> | BR-86 | Only regular employees can register for payroll deduction for a company purchase. |
> | BR-88 | An employee can register for payroll deduction payment of cafeteria meals if no more than 40 percent of gross pay is currently being deducted for other reasons. |

#### 5.2 Common Requirements

[Fill in requirements that are common to several features or to the whole
system.]

| ID | Common Requirement | Scope |
|---|---|---|
| CR-01 | [Common requirement] | [Feature or system-wide] |
| CR-02 | [Common requirement] | [Feature or system-wide] |

#### 5.3 Application Messages List

| # | Message code | Message Type | Context | Content |
|---:|---|---|---|---|
| 1 | MSG-01 | [Inline / toast / dialog / field error] | [Context] | [Message text] |
| 2 | MSG-02 | [Inline / toast / dialog / field error] | [Context] | [Message text] |
| 3 | MSG-03 | [Inline / toast / dialog / field error] | [Context] | [Message text] |
| 4 | MSG-04 | [Inline / toast / dialog / field error] | [Context] | [Message text] |
| 5 | MSG-05 | [Inline / toast / dialog / field error] | [Context] | [Message text] |
| 6 | MSG-06 | [Inline / toast / dialog / field error] | [Context] | [Message text] |
| 7 | MSG-07 | [Inline / toast / dialog / field error] | [Context] | [Message text] |
| 8 | MSG-08 | [Inline / toast / dialog / field error] | [Context] | [Message text] |
| 9 | MSG-09 | [Inline / toast / dialog / field error] | [Context] | [Message text] |

> **Sample messages from the source template (replace or remove):**
>
> | Code | Context | Content |
> |---|---|---|
> | MSG01 | There is no search result | No search results. |
> | MSG02 | Required input is empty | The \* field is required. |
> | MSG03 | Updating asset information succeeds | Update asset(s) information successfully. |
> | MSG04 | Adding a new asset succeeds | Add asset successfully. |
> | MSG05 | Confirmation email is sent | A confirmation email has been sent to {email_address}. |
> | MSG06 | Resetting asset information succeeds | Return asset(s) successfully. |
> | MSG07 | Deleting asset information succeeds | Delete asset(s) successfully. |
> | MSG08 | Input value exceeds the maximum length | Exceed max length of {max_length}. |
> | MSG09 | Username or password is incorrect at sign-in | Incorrect user name or password. Please check again. |

#### 5.4 Other Requirements

[Add internationalization, localization, legal, licensing, regulatory,
deployment, migration, audit, or other requirements not covered above.]
