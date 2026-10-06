# Phase 04 — Report 5: Testing Documentation

## Objective

Create an executable, project-specific English Report 5 testing set that derives its scope and cases from the frozen PTE Prep requirements and design. It must describe what should be tested, how it is tested, which evidence is required, and how results are reported without inventing execution outcomes.

## Inputs / Outputs

### Inputs

- Phase 01 foundation and Phase 02 Report 3 requirements/rules/NFRs.
- Phase 03 Report 4 architecture, database invariants, detailed flows, and design IDs.
- Current test source/configuration and supported test environments where available.
- `template-doc/Report5_Test Documentation.docx` for section order.

### Outputs

- `pte-doc/report/report05/00-project-report.md`
- `pte-doc/report/report05/00-record-of-changes.md`
- `pte-doc/report/report05/01-scope-of-testing.md`
- `pte-doc/report/report05/02-test-strategy.md`
- `pte-doc/report/report05/03-test-plan.md`
- `pte-doc/report/report05/04-test-cases.md`
- `pte-doc/report/report05/05-test-reports.md`
- Mandatory `pte-doc/report/report05/assets/` with test evidence templates, manifests, or a README stating that no binary evidence is present yet.
- A traceability matrix.
- Updated test ID ledger and requirement/design/test coverage table.

## Dependencies

- Report 3 IDs and scope must be stable.
- Report 4 design invariants and high-risk flows must be available.
- Actual test results may only be recorded when evidence exists; planned cases are not passes.
- Provider-dependent cases must record the dependency and expected evidence.

## Detailed Steps

1. Write the record of changes and test-document metadata, including release/baseline assumptions.
2. In `00-project-report.md`, map the DOCX document-level `II. Testing Documentation` heading and provide report metadata, navigation, testing-status summary, and links to all Report 5 section files.
3. Write **Scope of Testing**:
   - define objectives, in-scope requirements/functions, out-of-scope items, assumptions/constraints, test levels/stages, and risk priorities;
   - map scope to the 12 Report 3 feature groups and Report 4 high-risk flows;
   - explicitly include organization onboarding, tenant isolation, content/media, scoring templates, packages, exams, delivery, Proctoring, Examiner work, reporting/audit, and integrations;
   - explicitly exclude Report 7, Vietnamese copies, official PTE certification, mobile-first delivery, and unsupported future capabilities.
4. Write **Test Strategy**:
   - define functional, authorization, tenant-isolation, validation, negative, boundary, integration, retry/recovery, concurrency/idempotency, usability/accessibility, compatibility, performance, availability/recovery, security, and audit testing;
   - define unit/component/integration/contract/system/UAT levels as applicable;
   - define entry/exit criteria, severity, defect evidence, test-data rules, masking, environment dependencies, and traceability;
   - list supporting tools only when actually used or mark them as planned.
5. Write **Test Plan**:
   - identify test personnel and dependencies separately from product roles: BA/leader, developer, tester, Host/Proctor/Examiner/Student representatives, and provider test contacts where applicable; this list must not create new PTE Prep login roles;
   - define web, backend, database/infrastructure, and Windows exam-client test environments without secrets;
   - define milestones and gates: foundation/requirements, design readiness, feature integration, end-to-end/UAT, regression, and documentation readiness;
   - record test data setup for multiple organizations, roles, Students, classes, exams, forms, answers, score sources, and failures.
6. Write **Test Cases** with stable `OBJ-*`, `TC-*`, and `BUG-*` IDs. For each case include objective, preconditions, data, steps, expected result, requirement/design links, status, evidence, and cleanup/recovery.
7. Ensure test cases cover at minimum:
   - registration review/rejection/approval/Host activation;
   - authentication/session/password flows and tenant/role authorization;
   - question/media lifecycle, publication checks, revision/snapshot immutability;
   - Score Template validity and prohibited Host changes;
   - packages, payment callback/idempotency, limits, expiry, and separation from registration;
   - Student import, class/program membership, duplicate/capacity/schedule conflict;
   - exam generation, shared/unique form rules, pre-validation, publish/open/close/cancel;
   - device check, timed tasks, text/audio/image responses, local answer saving, outbox sync, reconnect/retry, final submit, duplicate submit;
   - Proctor assignment/monitoring/violation/audit and policy status;
   - Examiner assignment/queue/score entry/review/reassignment/source selection/incomplete blocking;
   - report aggregation, Host publication, Student visibility, notification, audit;
   - Cloudinary, payment, AI scoring, notification failure/retry boundaries;
   - NFR performance/capacity/availability/recovery/accessibility/compatibility targets.
8. Write **Test Reports**:
   - define execution summary, coverage, defect summary, conclusion, and evidence requirements;
   - separate Planned, Executed, Passed, Failed, Blocked, and Not Applicable;
   - leave result fields empty or `Not executed` until evidence exists.
9. Add requirement-to-test and design-to-test traceability tables. Record gaps/TBD provider dependencies with owners and impact.
10. Scan for invented pass results, generic template wording, unmasked secrets, and incorrect role/product claims.

## Acceptance Criteria

- [ ] The seven Report 5 files exist under `pte-doc/report/report05/`: `00-project-report.md`, `00-record-of-changes.md`, and five numbered section files, plus mandatory `assets/`.
- [ ] Report 5 preserves the DOCX document-level and child section order and is PTE Prep-specific.
- [ ] Every in-scope feature or high-risk requirement maps to a test objective/case or an explicit dependency/TBD.
- [ ] Negative, authorization, tenant-isolation, duplicate/conflict, retry/recovery, and integration-failure cases are included.
- [ ] Test cases link to `FR-*`, `NFR-*`, `BR-*`, `UC-*`, and relevant `SD/DB/SEQ` IDs.
- [ ] No case claims Passed/Failed without execution evidence; planned values are marked accordingly.
- [ ] Test environments contain no real secrets or production data.
- [ ] NFR numeric targets are treated as targets unless linked to a measured result.
- [ ] Out-of-scope and PTE Academic independence boundaries are explicit.

## Design Constraints

- Preflight: Read the Phase 01 catalogs, completed Report 3 and Report 4 files, the existing test source/configuration where available, and the Report 5 DOCX section map. Conventions carried forward are executable-looking structural test records, explicit evidence fields, stable `OBJ`/`TC` IDs, and no Passed/Failed claim without a dated run. This phase writes only `pte-doc/report/report05/` plus declared test/plan artifacts.

- The test document validates the approved requirement/design baseline; it must not silently redefine it.
- Runtime test execution is outside this documentation plan. A report template may record results later, but this phase writes only supported procedures/evidence fields.
- Test data must preserve organization boundaries and mask personal/audio/answer data where required.
- Provider-dependent cases must identify the provider boundary and retry/idempotency expectation.
- Windows-first exam delivery is the supported client baseline; mobile tests are out of scope.
- Performance, availability, and recovery figures are acceptance targets, not guarantees.

## Quality and Testing State

- **Quality:** Not evaluated.
- **Testing:** Not started.
- **Planned checks:** section-map check, requirement/test/design traceability, duplicate ID scan, result-claim scan, UTF-8/placeholder/secret scan, environment/role/scope review.
- **Product runtime tests:** Deliberately not run by this documentation phase; execution is recorded only when a future test run supplies evidence.

## Risks / Notes

- If Report 3 changes after test cases are written, update IDs and traceability rather than leaving stale cases.
- A generic “test passed” summary is not acceptable without a date, environment, build/baseline, evidence, and scope.
- AI scoring and notifications may be asynchronous or unavailable in local environments; keep blocked/dependency states explicit.
- Offline answer recovery and duplicate submission need both client and backend evidence; do not test only the final API call.

## Spec / User Story Mapping

- Spec: FR-11, FR-12, FR-14, FR-15, FR-16, FR-17; NFR-06, NFR-08, NFR-09, NFR-10, NFR-11, NFR-13, NFR-15, NFR-17, NFR-18, NFR-19.
- User stories: P1 tester executable strategy; P1 traceability; P1 role/tenant/security coverage; P1 honest test results.


## Execution Notes

- Status: completed for cook Phase 04.
- RED/GREEN: `python tests/test_phase04_report05.py` initially failed because Report 5 sections and test coverage were absent; after implementation it returned `GREEN/PASSED`.
- Build Gate: Python syntax compilation passed for the phase validator.
- Testing: passed under TDD verify; result at `tests/results/phase-04-report-05-testing-test-report.json`.
- Quality: approved; report at `quality/phase-04-report-05-testing-quality-report.json`.
- Outputs: project-specific scope/strategy/plan, 25 planned case rows, result/evidence templates, and mandatory asset convention.
