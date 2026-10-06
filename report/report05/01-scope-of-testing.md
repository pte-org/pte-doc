# 1. Scope of Testing

This section maps the original DOCX heading **1. Scope of Testing**. It defines what the PTE Prep test documentation covers, what is excluded, the testable baseline, assumptions, and evidence boundaries.

## 1.1 Test objective

The test effort must show whether the approved PTE Prep requirements and design are internally consistent and whether the implemented product preserves the core business invariants. The focus is not only happy-path screen completion. It includes authorization, tenant ownership, fixed exam provenance, local-first answer recovery, Proctor/Examiner assignment, scoring-source review, publication blocking, and external-service failure behavior.

## 1.2 In-scope product surfaces

| Surface | Test focus | Requirement/design anchors |
|---|---|---|
| Public organization registration and platform portal | Registration state, approval/rejection, shared content/template governance, package/admin scope, account support | `FR-ONBOARD-*`, `FR-CONTENT-*`, `FR-TEMPLATE-*`, `UC-ONBOARD-001`, `SD-ARCH-CONTEXT-001` |
| Organization web portal | Host roster/package/exam operations, Proctor monitoring, Examiner queue, score review/publication, audit visibility | `FR-ORG-*`, `FR-PACKAGE-*`, `FR-EXAM-*`, `FR-INTEGRITY-*`, `FR-SCORE-*`, `FR-REPORT-*` |
| Windows-first exam client | Device check, task/timer behavior, local save, sync/retry, submission, own-result visibility | `FR-DELIVERY-001`–`FR-DELIVERY-009`, `SEQ-ANSWER-SYNC`, `DB-INV-005`–`DB-INV-006` |
| Shared relational data | Tenant ownership, fixed version, candidate/form uniqueness, attempt/answer/score/report relationships | `DB-ORGANIZATION`, `DB-EXAM-VERSION`, `DB-ATTEMPT-ANSWER`, `DB-INV-001`–`DB-INV-008` |
| External boundaries | Payment callback, Cloudinary/media, AI scoring, email/notification, timeout/retry/idempotency | `FR-INTEGRATION-001`–`FR-INTEGRATION-006`, `NFR-19` |
| Deployment/operations | Health, configuration boundaries, backup/recovery evidence, public edge/internal service separation | `NFR-05`–`NFR-08`, `NFR-19`, `SD-ARCH-DEPLOY-001` |

## 1.3 Functional coverage

The test scope covers all 12 PTE Prep feature groups:

1. account and organization onboarding;
2. organization, Student, program, class, and enrollment management;
3. shared question bank and image/audio media;
4. Score Templates and task rules;
5. packages, payment integration, licenses, and limits;
6. exam setup, validation, generation, and scheduling;
7. Student exam delivery and answer submission;
8. Proctoring and exam integrity;
9. Examiner assignment, marking, and score-source review;
10. reports, publication, notification, and audit;
11. external service contracts and failure handling;
12. exam provenance and platform hardening.

The catalog baseline is the 23-row task list in [`../_foundation/pte-task-catalog.md`](../_foundation/pte-task-catalog.md): 22 scored task types and unscored Personal Introduction. Tests may use a smaller representative task subset only when the case records the untested rows and reason.

## 1.4 In-scope quality attributes

- response, concurrency, answer-ingestion, and pre-exam validation targets (`NFR-01`–`NFR-04`);
- availability/recovery/capacity evidence (`NFR-05`–`NFR-08`);
- tenant isolation, sensitive-action audit, login protection, and sensitive-data handling (`NFR-09`–`NFR-12`);
- contract-based retention and jurisdiction decision checks (`NFR-13`–`NFR-14`);
- language, keyboard/accessibility, recovery transparency, Windows/browser compatibility (`NFR-15`–`NFR-18`);
- deployment and integration resilience (`NFR-19`).

Numeric NFR values are targets. A test run must include environment, build, workload, tool/procedure, observed result, and evidence location before the result can be treated as a measured acceptance outcome.

## 1.5 Out of scope

- PTE Academic certification, affiliation, official score comparison, or official exam security certification.
- Student self-payment and personal package ownership.
- Research-based learning experiments, IRT/adaptive testing, or a new scientific scoring model.
- Mobile exam delivery redesign; mobile may be a later compatibility project.
- Universal no-repeat question guarantees across all sittings.
- Host private question-bank governance separate from shared platform content.
- Advanced anti-cheat such as virtual-machine detection, screen recording, and complete secondary-device blocking.
- A provider-specific AI quality guarantee before `TBD-AI-001` is decided.
- Unmasked production Student data, real credentials, secrets, private keys, or `.env` values in fixtures/evidence.

## 1.6 Test personnel and responsibilities

The test team is a project activity, not an additional PTE Prep product role. The following test responsibilities are distinct from the product actors:

| Test responsibility | Responsibility |
|---|---|
| Test Lead | Owns scope, risk, entry/exit decisions, and evidence quality. |
| QA Analyst | Designs cases, prepares data, executes functional/negative checks, and records observations. |
| Automation Engineer | Maintains repeatable API/UI/structural checks and test data helpers. |
| Performance Analyst | Designs target workload and records measured latency/capacity/recovery evidence. |
| Security Reviewer | Performs authorization, tenant isolation, sensitive-data, and audit checks. |
| Business Reviewer | Confirms that workflows/messages match the approved requirement meaning. |

These labels must not be added as product login roles in Reports 3, 4, or 6.

## 1.7 Entry and exit conditions

### Entry conditions

- Report 3 requirement IDs and out-of-scope boundary are stable.
- Report 4 design IDs, state invariants, and core sequences are available.
- Test environment and build/baseline are recorded without exposing secrets.
- Safe organization/Student/answer/media fixtures are available or a case is marked blocked.

### Exit conditions

- All critical/high-risk cases have an execution result or a named dependency/blocker.
- Tenant/authorization, duplicate/conflict, retry/recovery, score/publication, and integration-failure cases have evidence.
- No result is labelled as an execution outcome without date, environment, build, observed result, and evidence location.
- Open defects and TBD decisions are linked to owners and affected IDs.

## 1.8 Evidence rules

Each case/result records:

1. case/objective ID;
2. requirement/design links;
3. data set and organization scope;
4. environment/build/client/provider conditions;
5. execution date/time and tester responsibility;
6. expected result and actual result;
7. status (`Planned`, `Blocked`, `Pass`, `Fail`, or `Not run` only after execution context exists);
8. safe evidence path/reference;
9. defect/TBD link where applicable.

The current Report 5 baseline contains planned cases and result-record templates only. It does not claim a product test run or execution evidence for the product.
