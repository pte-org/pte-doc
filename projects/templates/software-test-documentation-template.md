# Report 5 — Software Test Documentation

## Template information

| Field | Value |
|---|---|
| Template source | Report5_Test Documentation.docx |
| Template status | Draft |
| Project | [Project name] |
| Project code | [Project code] |
| Version | [Version] |
| Date | [YYYY-MM-DD] |
| Prepared by | [Name / role] |
| Test owner | [Name / role] |
| Related SRS | [Link or document identifier] |
| Related design document | [Link or document identifier] |

> **How to use this template:** Replace the placeholders with evidence-based
> project information. Every test should trace to a requirement, risk,
> interface, business rule, or quality target. Record the exact build,
> environment, test data, and result used for each test run. Do not report a
> requirement as verified only because a test case exists; record execution
> evidence and the result.

> **Scope discipline:** This document describes the testing work and its
> evidence. It does not change the approved product scope. If a requirement
> cannot be tested yet, identify the reason, the risk, the owner, and the
> planned follow-up.

---

## I. Record of Changes

| Date | A*M, D | In charge | Change Description | Reference |
|---|---|---|---|---|
| [YYYY-MM-DD] | A | [Name] | [Describe the added test scope, strategy, or evidence] | [SRS/test review] |
| [YYYY-MM-DD] | M | [Name] | [Describe the modified test content] | [Requirement/build/defect] |
| [YYYY-MM-DD] | D | [Name] | [Describe the deleted test content] | [Decision or review] |
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

*A — Added; M — Modified; D — Deleted. Each row should identify the reason or
reference for a meaningful testing change.*

---

## II. Testing Documentation

### 1. Scope of Testing

Describe what will be tested, what will not be tested, and why. The scope
should cover features, functions, user roles, interfaces, data flows, and
non-functional requirements that are relevant to the release. Use the
approved SRS and the design document as the source of truth.

#### 1.1 Test objectives

State the decisions that testing must support. Examples include confirming
that a user can complete an approved workflow, protecting data boundaries,
detecting invalid input, proving integration behavior, and measuring an
agreed quality target.

| Objective ID | Test objective | Evidence needed | Owner |
|---|---|---|---|
| OBJ-01 | [What decision or risk this testing addresses] | [Test results, logs, screenshots, report] | [Name/role] |
| OBJ-02 | [Objective] | [Evidence] | [Name/role] |

#### 1.2 In-scope requirements and functions

| Requirement / feature ID | Requirement or feature | Test level | Test types | Critical scenarios | Planned evidence |
|---|---|---|---|---|---|
| [FR/UC/NFR ID] | [Requirement or feature] | [Unit/integration/system/acceptance] | [Types] | [Normal and important alternate paths] | [Evidence location] |
| [ID] | [Requirement or feature] | [Level] | [Types] | [Scenarios] | [Evidence] |

#### 1.3 Out-of-scope items

List anything deliberately excluded from this test cycle. An out-of-scope
statement must explain the boundary and the risk it leaves open. Do not use
“not tested” without a reason.

| Item | Reason excluded | Risk or impact | Owner / follow-up release |
|---|---|---|---|
| [Feature, interface, or quality attribute] | [Reason] | [Risk] | [Owner and target] |
| [Item] | [Reason] | [Risk] | [Owner and target] |

#### 1.4 Test levels and stages

Describe the stages applied to the project. For each stage, identify the
inputs, the person responsible, the focus, the entry conditions, the exit or
acceptance criteria, and the evidence that is retained.

| Test level | Purpose | Inputs | In charge | Entry criteria | Focus | Exit / acceptance criteria | Evidence |
|---|---|---|---|---|---|---|---|
| Unit | [Verify a small unit in isolation] | [Code, fixtures] | [Role] | [Conditions] | [Logic and validation] | [Criteria] | [Report/log] |
| Integration | [Verify collaboration between components] | [Build, services, data] | [Role] | [Conditions] | [Interfaces and persistence] | [Criteria] | [Report/log] |
| System | [Verify the complete product behavior] | [Release candidate] | [Role] | [Conditions] | [End-to-end workflows and qualities] | [Criteria] | [Report/log] |
| Acceptance | [Confirm business acceptance] | [Stable release and scenarios] | [Stakeholder/role] | [Conditions] | [User outcomes] | [Criteria] | [Signed result] |

#### 1.5 Assumptions and constraints

Record constraints that can affect the test design or the interpretation of
results. Examples include unavailable third-party services, test data
limitations, device availability, limited network conditions, authentication
dependencies, unstable builds, or an agreed manual-only check.

| ID | Assumption or constraint | Effect on testing | Mitigation or follow-up |
|---|---|---|---|
| CON-01 | [Constraint or assumption] | [Effect] | [Mitigation/owner] |
| CON-02 | [Constraint or assumption] | [Effect] | [Mitigation/owner] |

### 2. Test Strategy

Explain how the selected test types, levels, tools, data, and evidence work
together. The strategy should be proportional to project risk and should
explain how failures are triaged, fixed, retested, and closed.

#### 2.1 Testing Types

For every selected testing type, state its objective, what is included,
technique, data, environment, entry criteria, completion criteria, evidence,
and responsible role. Add or remove rows to fit the project.

| Test type | Objective | Technique | Main targets | Entry criteria | Completion criteria | Evidence | Owner |
|---|---|---|---|---|---|---|---|
| Unit testing | [Verify isolated logic] | [Examples, mocks, boundary values] | [Classes/functions] | [Build is available] | [Criteria] | [Automated report] | [Role] |
| Integration testing | [Verify component interactions] | [Real or controlled dependencies] | [APIs, database, queues] | [Dependencies available] | [Criteria] | [Logs/results] | [Role] |
| System testing | [Verify the product as a whole] | [User workflows and system scenarios] | [End-to-end features] | [Release candidate] | [Criteria] | [Execution report] | [Role] |
| Acceptance testing | [Confirm stakeholder outcomes] | [Business scenarios] | [Priority workflows] | [Stable test environment] | [Stakeholder decision] | [Sign-off record] | [Role] |
| Regression testing | [Detect unintended changes] | [Selected repeatable suite] | [Existing critical behavior] | [Changed build] | [Criteria] | [Suite report] | [Role] |
| Security testing | [Check access and data protection] | [Role matrix, negative tests, dependency review] | [Authentication, authorization, sensitive data] | [Relevant interfaces ready] | [Criteria] | [Findings/report] | [Role] |
| Performance testing | [Check agreed response/capacity targets] | [Controlled workload and measurement] | [Critical requests/workflows] | [Representative environment] | [Criteria] | [Measurement report] | [Role] |
| Usability/accessibility testing | [Check that intended users can complete tasks] | [Scenario observation and accessibility review] | [User-facing screens] | [UI build available] | [Criteria] | [Findings/evidence] | [Role] |

##### Test completion and failure rules

| Rule ID | Rule |
|---|---|
| STR-01 | [Define when a test run is complete and which results are required.] |
| STR-02 | [Define how a blocked, skipped, or inconclusive test is recorded.] |
| STR-03 | [Define which defect severities block release and who makes the decision.] |
| STR-04 | [Define how a fix is retested and how regression impact is selected.] |

#### 2.2 Test Levels

The source template uses a mapping between test types and test levels. Keep
the mapping explicit so that the team can see where each type is performed.
Mark a cell with X only when the project has planned and owned work at that
intersection.

| Type of tests | Unit | Integration | System | Acceptance |
|---|:---:|:---:|:---:|:---:|
| [Test type 1] | X |  |  |  |
| [Test type 2] |  | X | X |  |
| [Test type 3] |  |  | X | X |

Describe each level in project terms:

| Test level | Scope boundary | Test types performed | Environment/data | Responsible role | Exit decision |
|---|---|---|---|---|---|
| Unit | [Boundary] | [Types] | [Environment/data] | [Role] | [Decision] |
| Integration | [Boundary] | [Types] | [Environment/data] | [Role] | [Decision] |
| System | [Boundary] | [Types] | [Environment/data] | [Role] | [Decision] |
| Acceptance | [Boundary] | [Types] | [Environment/data] | [Role] | [Decision] |

#### 2.3 Supporting Tools

List the tools used to create, execute, collect, and report tests. Include
their purpose, provider, version, configuration, and the location of the
evidence. Do not list a tool merely because it is installed; explain how it is
used by this project.

| Purpose | Tool | Vendor / in-house | Version | Configuration or use | Evidence location |
|---|---|---|---|---|---|
| [Purpose] | [Tool] | [Vendor or internal] | [Version] | [How it is used] | [Path/link] |
| [Purpose] | [Tool] | [Vendor or internal] | [Version] | [How it is used] | [Path/link] |

### 3. Test Plan

Describe the people, environments, schedule, data, and dependencies needed
to execute the strategy. The plan must identify ownership rather than
assuming that every team member performs every task.

#### 3.1 Human Resources

| Worker / doer | Role | Specific responsibilities and comments | Required skills | Availability / handoff |
|---|---|---|---|---|
| [Name] | [Role] | [Responsibilities] | [Skills] | [Availability/handoff] |
| [Name] | [Role] | [Responsibilities] | [Skills] | [Availability/handoff] |

##### Review and defect ownership

| Activity | Primary owner | Reviewer/approver | Supporting roles | Required output |
|---|---|---|---|---|
| Test case design | [Role] | [Role] | [Roles] | [Cases and traceability] |
| Test execution | [Role] | [Role] | [Roles] | [Execution results] |
| Defect triage | [Role] | [Role] | [Roles] | [Prioritized defect list] |
| Retest and closure | [Role] | [Role] | [Roles] | [Retest evidence] |
| Release recommendation | [Role] | [Role] | [Roles] | [Recommendation/sign-off] |

#### 3.2 Test Environment

List the software, hardware, infrastructure, network conditions, external
services, accounts, permissions, test data, and configuration required for
each important test environment. Separate shared environments from
developer-local environments.

| Environment ID | Purpose | Software / build | Hardware / device | Infrastructure | Network / external services | Data and accounts | Owner |
|---|---|---|---|---|---|---|---|
| ENV-01 | [Purpose] | [Versions] | [Device] | [Services] | [Conditions] | [Data/accounts] | [Role] |
| ENV-02 | [Purpose] | [Versions] | [Device] | [Services] | [Conditions] | [Data/accounts] | [Role] |

##### Environment readiness checklist

| Check | Status | Evidence / value |
|---|:---:|---|
| Correct application build is deployed and identified. | [ ] | [Build/version] |
| Database schema and seed data match the test plan. | [ ] | [Migration/fixture reference] |
| Test accounts have the required roles and permissions. | [ ] | [Account set reference] |
| External services are available or replaced by an approved test double. | [ ] | [Endpoint/double reference] |
| Devices, browsers, microphones, cameras, or other test hardware are ready. | [ ] | [Device matrix] |
| Logs and evidence collection are enabled without exposing secrets. | [ ] | [Configuration reference] |

#### 3.3 Test Milestones

Use milestones to communicate what has been prepared, executed, reviewed, and
accepted. Add dependencies and the evidence expected at each milestone.

| Milestone task | Start date | End date | Owner | Entry criteria | Exit criteria / deliverable | Status |
|---|---|---|---|---|---|---|
| [Test planning] | [YYYY-MM-DD] | [YYYY-MM-DD] | [Role] | [Conditions] | [Approved plan] | [Planned/In progress/Done] |
| [Test case preparation] | [YYYY-MM-DD] | [YYYY-MM-DD] | [Role] | [Conditions] | [Cases and traceability] | [Status] |
| [Test execution] | [YYYY-MM-DD] | [YYYY-MM-DD] | [Role] | [Conditions] | [Execution report] | [Status] |
| [Defect retest] | [YYYY-MM-DD] | [YYYY-MM-DD] | [Role] | [Conditions] | [Retest evidence] | [Status] |
| [Acceptance/sign-off] | [YYYY-MM-DD] | [YYYY-MM-DD] | [Role] | [Conditions] | [Decision record] | [Status] |

### 4. Test Cases

Prepare the detailed test cases in the agreed spreadsheet or test-management
tool. The original template references the following external artifacts; keep
the links current:

- Unit test cases: [Path/link to the unit-test case file]
- Other test cases (integration, system, acceptance): [Path/link to the test case file]

Each test case should be independently executable and should include the
information below. Split a large scenario when different outcomes, roles, or
data conditions require separate evidence.

| Field | Description |
|---|---|
| Test case ID | Stable identifier, for example TC-FR-001. |
| Requirement / risk reference | SRS, business rule, interface, defect, or risk covered. |
| Test objective | What the case proves or attempts to discover. |
| Test level and type | Unit, integration, system, acceptance, or another selected type. |
| Priority | Business or release priority. |
| Preconditions | Required account, state, data, device, and configuration. |
| Test data | Exact input values or fixture reference, excluding secrets. |
| Steps | Ordered actions that another tester can repeat. |
| Expected result | Observable result, state change, message, record, or event. |
| Actual result | What occurred during execution. |
| Evidence | Screenshot, log, response, recording, or report location. |
| Result | Pass, fail, blocked, skipped, or inconclusive. |
| Defect reference | Identifier for a defect raised from the case. |
| Tester and execution date | Person, build, environment, and date of execution. |

#### Test case record template

| Test case ID | [ID] |
|---|---|
| Requirement / risk | [Reference] |
| Objective | [Objective] |
| Level / type / priority | [Values] |
| Preconditions | [Conditions] |
| Test data | [Fixture or values] |
| Steps | 1. [Step] <br> 2. [Step] <br> 3. [Step] |
| Expected result | [Expected outcome] |
| Actual result | [Observed outcome] |
| Evidence | [Path/link] |
| Result | [Pass/Fail/Blocked/Skipped/Inconclusive] |
| Defect reference | [DEF-xxx or None] |
| Executed by / date / build | [Details] |

### 5. Test Reports

Provide the result, statistics, and analysis for each test run or release
candidate. Numbers must be reproducible from the linked test cases and
execution evidence.

#### 5.1 Execution summary

| Run ID | Build/version | Environment | Start/end | Planned | Executed | Passed | Failed | Blocked/skipped | Owner |
|---|---|---|---|---:|---:|---:|---:|---:|---|
| [RUN-01] | [Build] | [ENV-01] | [Dates] | [Count] | [Count] | [Count] | [Count] | [Count] | [Name] |

#### 5.2 Requirement coverage

| Requirement ID | Requirement | Planned cases | Executed cases | Result | Open defects | Evidence |
|---|---|---:|---:|---|---|---|
| [FR/NFR/UC ID] | [Requirement] | [Count] | [Count] | [Status] | [DEF IDs] | [Link] |

#### 5.3 Defect summary and analysis

| Severity / priority | Open | Fixed | Retest passed | Reopened | Deferred | Release impact |
|---|---:|---:|---:|---:|---:|---|
| [Critical] | [Count] | [Count] | [Count] | [Count] | [Count] | [Decision] |
| [High] | [Count] | [Count] | [Count] | [Count] | [Count] | [Decision] |
| [Medium/Low] | [Count] | [Count] | [Count] | [Count] | [Count] | [Decision] |

Explain the important failures, repeated failure patterns, environment
problems, escaped defects, and risks that remain after the test run.

#### 5.4 Test conclusion

| Decision item | Result / statement |
|---|---|
| Overall test conclusion | [Pass, conditional pass, or not ready] |
| Known limitations | [Limitations] |
| Unresolved risks | [Risks and owners] |
| Required follow-up | [Actions and target release] |
| Approval / sign-off | [Name, role, date, or pending decision] |

## Appendix A — Requirement-to-test traceability

| Requirement ID | Feature/use case | Test case IDs | Test level | Latest result | Evidence |
|---|---|---|---|---|---|
| [FR/NFR/UC ID] | [Feature] | [TC IDs] | [Level] | [Result] | [Link] |

## Appendix B — Defect record template

| Field | Value |
|---|---|
| Defect ID | [DEF-xxx] |
| Title | [Short description] |
| Related requirement/test | [IDs] |
| Environment/build | [Details] |
| Preconditions and steps | [Reproduction steps] |
| Expected result | [Expected] |
| Actual result | [Actual] |
| Severity / priority | [Values] |
| Evidence | [Links] |
| Owner / status | [Details] |
| Fix and retest result | [Details] |

