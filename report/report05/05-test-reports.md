# 5. Test Reports

This section maps the original DOCX heading **5. Test Reports**. It defines the execution-summary format, coverage view, defect record, evidence manifest, and sign-off boundary. The baseline contains no fabricated runtime outcome.

## 5.1 Execution summary template

| Field | Value for a future run |
|---|---|
| Test run ID | `RUN-YYYYMMDD-##` |
| Scope/build | Record repository/build identifier and included services/clients. |
| Environment | `ENV-LOCAL`, `ENV-STAGE`, `ENV-PERF`, or approved operations environment. |
| Execution window | Start/end time with time zone. |
| Test responsibility | Named Test Lead/QA Analyst/Automation Engineer; product role listed separately if participating. |
| Cases planned/executed | Counts by priority and status. |
| Defects/TBDs | Links to `BUG-*`/`TBD-*` with owner and severity. |
| Evidence manifest | Masked logs/screenshots/traces/query outputs with safe paths. |
| Conclusion | Explain readiness, dependencies, and unresolved risk; do not use a pass label without the evidence below. |

**Current baseline:** No product runtime execution is claimed for this document. The TDD checks recorded for Reports 3–6 validate Markdown structure/content only.

## 5.2 Result status rules

| Status | Allowed use |
|---|---|
| `Planned` | Case is specified but has not been executed. |
| `Not run` | The run was planned but did not execute; record reason. |
| `Blocked` | Execution cannot continue because a dependency/environment/decision is missing. |
| `Pass` | Actual result meets expected result and evidence is attached. |
| `Fail` | Actual result does not meet expected result; defect/evidence is attached. |
| `Inconclusive` | Evidence is insufficient or provider/device behavior could not be isolated. |

The words “Pass” and “Fail” describe a case result only after an execution record exists. They do not describe the existence of a test plan or a mock response.

## 5.3 Coverage summary template

| Coverage dimension | Required view | Baseline state |
|---|---|---|
| Report 3 functional requirements | Each `FR-*` maps to one or more `TC-*`, or a documented dependency/TBD. | Planned; initial links are in `04-test-cases.md`. |
| Report 3 NFRs | Each `NFR-*` maps to objective/procedure/evidence, especially numeric targets. | Planned; no measured result claimed. |
| Report 3 business rules | Access, package, fixed-version, answer, Proctor, scoring, publication, integration rules have positive/negative cases. | Planned. |
| Report 4 design | `SD-*`, `DB-*`, and `SEQ-*` invariants are exercised or marked blocked/TBD. | Planned. |
| Roles/scopes | Six product roles plus integration boundaries have permitted/denied checks. | Planned. |
| Vertical flows | Onboarding, exam preparation, delivery/proctoring, scoring/publication run end to end. | Planned/Future. |

The violation-recording path `FR-INTEGRITY-003` is covered by `TC-PROCTOR-001`; its result must include the audit event, actor, attempt, policy, and synchronization limitation.

## 5.4 Evidence manifest template

Each evidence item must be safe to share and reproducible:

| Field | Required content |
|---|---|
| Evidence ID | `EVD-TEST-*` or case-specific reference. |
| Case/objective | `TC-*` and `OBJ-*`. |
| Source type | API log, UI capture, client log, database assertion, queue/provider trace, performance report, recovery timeline. |
| Environment/build | Environment ID, version/build, relevant configuration profile without secret values. |
| Date/time | Execution time and time zone. |
| Data scope | Synthetic organization/Student identifiers or masked values. |
| Observation | Actual behavior, including latency/status/error where relevant. |
| File/path | Relative safe path; no credential-bearing attachment. |
| Reviewer | Test responsibility and business/security reviewer where needed. |
| Limitation | Mock/provider/device limitation or missing evidence. |

## 5.5 Defect report template

| Field | Example format |
|---|---|
| Defect ID | `BUG-DELIVERY-001` |
| Severity | Blocker/High/Medium/Low/Noted |
| Requirement/design link | `FR-DELIVERY-006`, `SEQ-ANSWER-SYNC` |
| Environment/build | `ENV-STAGE`, build identifier |
| Reproduction | Safe steps and synthetic data |
| Expected/actual | Business-readable difference |
| Evidence | Masked log/screenshot/request trace |
| Owner/status | Assigned, fixed, retest pending, accepted/TBD |
| Risk decision | Impact on publication/release and approver |

## 5.6 Current documentation-run evidence

| Evidence ID | What was actually run | Result | Limitation |
|---|---|---|---|
| `EVD-TEST-DOC-001` | `test_phase01_foundation.py` after foundation implementation | GREEN structural result | Does not prove product runtime behavior. |
| `EVD-TEST-DOC-002` | `test_phase02_report03.py` after Report 3 implementation | GREEN structural result | Does not prove SRS implementation coverage. |
| `EVD-TEST-DOC-003` | `test_phase03_report04.py` after Report 4 implementation | GREEN structural result | Does not prove architecture/runtime behavior. |
| `EVD-TEST-DOC-004` | Report 5 structural test will be recorded after this phase | Planned in current phase | No Report 5 runtime execution is claimed. |

## 5.7 Release conclusion template

The Test Lead should conclude only after reviewing executed evidence:

1. core-flow readiness and blocked dependencies;
2. security/tenant/assignment isolation;
3. answer recovery and publication safety;
4. score-source/provider limitations;
5. NFR measurements and operational recovery;
6. open defects/TBD decisions and owners;
7. release recommendation and expiry of evidence.

This Report 5 baseline is **not a runtime sign-off**. It is an executable test specification and an honest result-record format for later runs.
