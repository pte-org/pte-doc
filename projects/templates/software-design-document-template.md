# Report 4 — Software Design Document

## Template information

| Field | Value |
|---|---|
| Template source | Report4_Software Design Document.docx |
| Template status | Draft |
| Project | [Project name] |
| Project code | [Project code] |
| Version | [Version] |
| Date | [YYYY-MM-DD] |
| Prepared by | [Name / role] |
| Approved by | [Name / role] |
| Related SRS | [Link or document identifier] |

> **How to use this template:** Replace every square-bracket placeholder with
> project-specific content. Keep the same requirement, feature, entity, class,
> and diagram identifiers when they are referenced by other documents. Every
> design decision must be traceable to an approved requirement or must be
> marked as a design constraint or an assumption. Do not paste credentials,
> private keys, production environment values, or other secrets into this
> document.

> **Expected level of detail:** This document explains how the approved
> requirements are organized into a solution. It should be detailed enough for
> a developer to understand component responsibilities, data ownership,
> interfaces, relationships, important processing steps, error paths, and
> security boundaries without guessing the intended behavior. It is not a
> replacement for source code or a deployment secret store.

---

## I. Record of Changes

| Date | A*M, D | In charge | Change Description | Reference |
|---|---|---|---|---|
| [YYYY-MM-DD] | A | [Name] | [Describe the added design content] | [SRS/design review] |
| [YYYY-MM-DD] | M | [Name] | [Describe the modified design content] | [Requirement or decision] |
| [YYYY-MM-DD] | D | [Name] | [Describe the deleted design content] | [Decision or review] |
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

*A — Added; M — Modified; D — Deleted. Each row should describe one
meaningful design change, not an editorial correction.*

---

## II. Software Design Document

### 1. System Design

This section presents the system-level design. Explain the major parts of the
solution, the boundary of each part, the communication paths between parts,
and the external systems or devices that are involved. The design must be
consistent with the system boundary, actors, interfaces, and non-functional
requirements in the SRS.

#### 1.1 System Architecture

Describe the selected architecture style and why it fits the project. State
which parts run in the browser, mobile application, desktop application,
server, database, background worker, or external provider. Explain the
responsibility of each component and the data or control flow between
components.

Include an architecture diagram that shows:

- the system boundary;
- user-facing applications and the users who access them;
- application modules or services;
- databases and durable storage;
- queues, scheduled jobs, or background workers;
- external systems, devices, and service providers;
- trust boundaries and authentication boundaries;
- the direction and purpose of each important connection.

<!-- Insert the system architecture diagram here. Give it a figure number,
caption, and a short explanation. The explanation must cover every component
and every connection shown in the diagram. -->

> **Diagram placeholder:** Figure SD-01 — [System architecture diagram]

##### Architecture component descriptions

| Component ID | Component / boundary | Responsibility | Owned data | Inbound interfaces | Outbound interfaces | Dependencies | Deployment location |
|---|---|---|---|---|---|---|---|
| C-01 | [Component name] | [What this component is responsible for] | [Data owned or managed] | [Users, modules, or systems] | [Modules, systems, or devices] | [Required dependencies] | [Browser, app, server, cloud, etc.] |
| C-02 | [Component name] | [Responsibility] | [Owned data] | [Interfaces] | [Interfaces] | [Dependencies] | [Location] |
| C-03 | [Component name] | [Responsibility] | [Owned data] | [Interfaces] | [Interfaces] | [Dependencies] | [Location] |

##### Architecture decisions and constraints

| Decision ID | Decision or constraint | Reason | Alternatives considered | Requirement or risk affected |
|---|---|---|---|---|
| ADR-01 | [Architecture decision] | [Reason for choosing it] | [Alternatives] | [FR/NFR/risk IDs] |
| ADR-02 | [Architecture decision] | [Reason] | [Alternatives] | [IDs] |

##### Data and control flows

For each important flow, describe the event that starts it, the components
involved, the data that is sent, the validation or authorization performed,
the durable state that changes, and the response or recovery behavior.

| Flow ID | Flow name | Trigger | Steps across components | Data exchanged | Success result | Failure or recovery |
|---|---|---|---|---|---|---|
| FLOW-01 | [Flow name] | [User action, event, or schedule] | [C-01 → C-02 → C-03] | [Data] | [Result] | [Errors, retry, fallback] |
| FLOW-02 | [Flow name] | [Trigger] | [Component sequence] | [Data] | [Result] | [Failure behavior] |

#### 1.2 Package Diagram

Provide a package diagram for each subsystem or application boundary. The
diagram should show the logical packages, their responsibilities, and their
allowed dependencies. A package may represent a business module, a layer, a
feature area, or a shared capability. Use the same package names in the
diagram, source code, database design, and class specifications.

<!-- Insert the overall package diagram here. If the solution contains
multiple independently understandable subsystems, add one diagram per
subsystem and give each diagram a unique identifier. -->

> **Diagram placeholder:** Figure SD-02 — [Overall package diagram]

##### Package descriptions

| No. | Package ID / name | Responsibility | Main classes or modules | Public entry points | Allowed dependencies | Forbidden dependencies |
|---:|---|---|---|---|---|---|
| 1 | [PKG-01 / package name] | [Business or technical responsibility] | [Classes/modules] | [Services, controllers, or interfaces] | [Allowed packages] | [Packages it must not access] |
| 2 | [PKG-02 / package name] | [Responsibility] | [Classes/modules] | [Entry points] | [Allowed packages] | [Forbidden packages] |
| 3 | [PKG-03 / package name] | [Responsibility] | [Classes/modules] | [Entry points] | [Allowed packages] | [Forbidden packages] |

##### Dependency rules

Document rules that protect the design from accidental coupling. Examples
include which package owns a business rule, where authorization is checked,
which package may read a data store, how shared utilities are used, and how
cross-package errors are represented.

| Rule ID | Dependency rule | Reason | Verification method |
|---|---|---|---|
| DEP-01 | [Example: Package A may call Package B only through its public service interface.] | [Boundary or ownership reason] | [Code review, architecture test, or checklist] |
| DEP-02 | [Dependency rule] | [Reason] | [How it will be checked] |

### 2. Database Design

This section describes the logical and physical data design required to
support the SRS. Explain data ownership, relationships, identifiers,
constraints, lifecycle, retention, and audit requirements. The database design
must agree with the ERD in the SRS and must not introduce entities or
relationships that are not needed by an approved feature.

#### 2.1 Database overview

| Item | Decision |
|---|---|
| Database technology | [Technology and version] |
| Database boundary | [Shared database, schema, tenant boundary, or other] |
| Primary data owners | [Modules or components] |
| Identifier strategy | [Generated IDs, natural keys, or both] |
| Time and date convention | [Timezone and storage/display convention] |
| Migration approach | [How schema changes are created, reviewed, and applied] |
| Backup and recovery assumption | [Document the approved operational assumption] |
| Retention and deletion | [Reference the SRS requirement or contract decision] |

#### 2.2 Entity relationship and table relationship

<!-- Insert the logical ERD and, when useful, a physical table relationship
diagram. Explain cardinalities, optional relationships, ownership boundaries,
and any relationship that is intentionally represented by a join table. -->

> **Diagram placeholder:** Figure SD-03 — [Database ERD / table relationship]

| Relationship ID | Parent entity | Child entity | Cardinality | Optionality | Ownership rule | Delete/update behavior |
|---|---|---|---|---|---|---|
| REL-01 | [Entity] | [Entity] | [1-to-many, etc.] | [Optional/required] | [Which side owns the relationship] | [Restrict, cascade, archive, etc.] |
| REL-02 | [Entity] | [Entity] | [Cardinality] | [Optionality] | [Ownership] | [Behavior] |

#### 2.3 Table descriptions

| No. | Table / collection | Purpose | Primary keys | Foreign keys | Important fields and constraints | Owner package |
|---:|---|---|---|---|---|---|
| 1 | [Table name] | [What records represent] | [List of primary key fields] | [List of foreign key fields] | [Required fields, unique rules, allowed states] | [Package] |
| 2 | [Table name] | [Purpose] | [Keys] | [Keys] | [Constraints] | [Package] |
| 3 | [Table name] | [Purpose] | [Keys] | [Keys] | [Constraints] | [Package] |

For each table, document details that cannot be understood from the diagram:

| Table | Field | Type / size | Required | Default | Allowed values | Validation or business meaning | Sensitive? |
|---|---|---|:---:|---|---|---|:---:|
| [Table] | [Field] | [Type] | Yes/No | [Default] | [Range or enum] | [Meaning and rule] | Yes/No |
| [Table] | [Field] | [Type] | Yes/No | [Default] | [Range or enum] | [Meaning and rule] | Yes/No |

#### 2.4 Data integrity, indexes, and transactions

Describe the constraints and transaction boundaries needed to keep the data
correct. Include uniqueness, referential integrity, optimistic or pessimistic
locking, idempotency, isolation expectations, indexes for important queries,
and the behavior when two users update the same record.

| Design ID | Data rule or mechanism | Affected tables/flows | Failure behavior | Verification |
|---|---|---|---|---|
| DB-01 | [Unique or referential constraint] | [Tables or flow IDs] | [Message, rollback, retry] | [Test or migration check] |
| DB-02 | [Transaction or concurrency rule] | [Tables or flow IDs] | [Behavior] | [Verification] |
| DB-03 | [Index or query performance rule] | [Tables or query] | [Behavior if unavailable] | [Query review or test] |

#### 2.5 Audit, retention, and sensitive data

Document which data changes create an audit record, who can view the record,
what is retained, how deletion or anonymization works, and how sensitive data
is protected. Refer to the SRS and the organization contract for unresolved
retention decisions.

| Data category | Examples | Access restriction | Audit event | Retention/deletion rule | Protection |
|---|---|---|---|---|---|
| [Category] | [Fields or records] | [Allowed roles] | [Event name] | [Rule or TBD] | [Encryption, masking, etc.] |
| [Category] | [Examples] | [Restriction] | [Event] | [Rule] | [Protection] |

### 3. Detailed Design

Create one subsection for every significant feature or function. A detailed
design must connect the feature to its SRS requirements and describe the
classes, interfaces, data, sequence, states, validation, authorization, and
failure handling needed to implement it.

> **Reuse rule:** When multiple features use the same class or sequence
> structure, document the shared design once and reference it from the other
> features. State what is shared and what is specialized.

#### 3.1 [Feature / Function Name 1]

| Item | Value |
|---|---|
| Feature ID | [Feature or FR ID] |
| SRS requirements | [FR/NFR/BR/UC IDs] |
| Actors or callers | [Roles, modules, or external systems] |
| Entry point | [Screen, API, event, schedule, or message] |
| Main responsibility | [Outcome produced by the feature] |
| Data read | [Entities/tables or external data] |
| Data changed | [Entities/tables or external data] |
| Authorization boundary | [Who may perform each important action] |
| Transaction boundary | [What succeeds or rolls back together] |
| External dependencies | [Services, devices, queues, or files] |

##### 3.1.1 Class diagram

<!-- Insert the class diagram for this feature. Show the relevant classes,
interfaces, inheritance, composition, associations, and multiplicities. Keep
implementation-only helpers out of the diagram unless they affect the design. -->

> **Diagram placeholder:** Figure SD-04 — [Class diagram for feature 1]

##### 3.1.2 Class specifications

| Class / interface | Type | Responsibility | Important attributes | Public operations | Collaborators | Invariants |
|---|---|---|---|---|---|---|
| [Class name] | [Entity/service/controller/interface] | [Responsibility] | [Attributes] | [Operations and outcomes] | [Other classes] | [Rules that must always hold] |
| [Class name] | [Type] | [Responsibility] | [Attributes] | [Operations] | [Collaborators] | [Invariants] |

For each operation that carries business meaning, provide the following
detail:

| Operation | Trigger/caller | Inputs | Validation | Processing | Output | Errors and recovery | Side effects |
|---|---|---|---|---|---|---|---|
| [Operation name] | [Caller] | [Parameters] | [Rules] | [Steps or decision points] | [Return/event/state] | [Error and retry behavior] | [Data/audit/notification] |
| [Operation name] | [Caller] | [Parameters] | [Rules] | [Processing] | [Output] | [Errors] | [Side effects] |

##### 3.1.3 Sequence diagram — [Sequence name 1]

Describe the scenario represented by the sequence diagram, including the
starting condition and the expected final state. Show actor-to-interface,
interface-to-application, application-to-data-store, and external-service
messages as applicable.

<!-- Insert the sequence diagram here. Number messages only when the numbers
help the reader follow a complex interaction. Mark alternative, optional,
retry, and failure paths explicitly. -->

> **Diagram placeholder:** Figure SD-05 — [Sequence diagram name 1]

| Step | Sender | Receiver | Message / data | Validation or decision | Result |
|---:|---|---|---|---|---|
| 1 | [Actor/component] | [Component] | [Action and data] | [Check] | [Result] |
| 2 | [Component] | [Component] | [Action and data] | [Check] | [Result] |
| 3 | [Component] | [Data store/service] | [Action and data] | [Check] | [Result] |

##### 3.1.4 Sequence diagram — [Sequence name 2]

Repeat the sequence design for another important normal, alternate, or
exception scenario. Do not hide error paths that affect user-visible behavior,
data integrity, retry behavior, or audit records.

> **Diagram placeholder:** Figure SD-06 — [Sequence diagram name 2]

| Step | Sender | Receiver | Message / data | Validation or decision | Result |
|---:|---|---|---|---|---|
| 1 | [Actor/component] | [Component] | [Action and data] | [Check] | [Result] |
| 2 | [Component] | [Component] | [Action and data] | [Check] | [Result] |

##### 3.1.5 State, validation, and error design

If the feature has a lifecycle, show its state diagram or list all allowed
state transitions. Document who or what can cause each transition and what is
forbidden.

| Current state | Trigger | Preconditions | Next state | Actor/system allowed | Audit or notification |
|---|---|---|---|---|---|
| [State] | [Action/event] | [Conditions] | [State] | [Role or component] | [Event] |
| [State] | [Action/event] | [Conditions] | [State] | [Role or component] | [Event] |

| Error ID | Condition | Detection point | User/system response | Retry or recovery | Audit/logging |
|---|---|---|---|---|---|
| ERR-01 | [Condition] | [Component] | [Message or response] | [Retry/fallback] | [Record] |
| ERR-02 | [Condition] | [Component] | [Message or response] | [Recovery] | [Record] |

#### 3.2 [Feature / Function Name 2]

Repeat the complete detailed-design structure above. At minimum, provide:

- links to the applicable SRS requirements;
- the feature boundary and callers;
- the class or component design;
- the normal and alternate sequence diagrams;
- data and transaction behavior;
- authorization, validation, error, and audit behavior;
- a statement identifying any shared design reused from Section 3.1.

<!-- Add more feature sections (3.3, 3.4, ...) as required. Do not combine
unrelated features merely to reduce document length. -->

### 4. Cross-Cutting Design Decisions

Use this optional section when a design concern applies to several features
and would otherwise be repeated. Typical topics include authentication and
authorization enforcement, validation and error response conventions,
notifications, file/media handling, idempotency, background processing,
logging, audit trails, time zones, and accessibility.

| Concern | Design rule | Affected components/features | Requirement IDs | Verification |
|---|---|---|---|---|
| [Concern] | [Rule] | [Components/features] | [IDs] | [Review/test] |
| [Concern] | [Rule] | [Components/features] | [IDs] | [Review/test] |

### 5. Design Traceability and Review Checklist

| Checklist item | Status | Evidence / reference | Reviewer |
|---|:---:|---|---|
| Every approved functional requirement maps to a design component or feature. | [ ] | [Section/figure/table] | [Name] |
| Every external interface in the SRS appears in the architecture or sequence design. | [ ] | [Reference] | [Name] |
| Every persisted entity in the SRS is represented in the ERD and table descriptions. | [ ] | [Reference] | [Name] |
| Role and data-access boundaries are explicit. | [ ] | [Reference] | [Name] |
| Normal, alternate, timeout, retry, and failure paths are documented for critical flows. | [ ] | [Reference] | [Name] |
| Design decisions and assumptions are recorded and approved. | [ ] | [Reference] | [Name] |
| No design section contains credentials or production secrets. | [ ] | [Review result] | [Name] |
| Diagrams have captions, identifiers, legends where needed, and readable labels. | [ ] | [Figure list] | [Name] |
| Design has been reviewed against the latest SRS version. | [ ] | [Review record] | [Name] |

