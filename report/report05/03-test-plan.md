# 3. Test Plan

This section maps the original DOCX heading **3. Test Plan**. It defines test work packages, order, dependencies, entry/exit checks, and evidence ownership.

## 3.1 Work packages

| Work package | Scope | Dependencies | Owner | Exit evidence |
|---|---|---|---|---|
| `TP-01` Foundation/structure | Markdown file map, encoding, IDs, links, task catalog, status vocabulary | Report foundation | Automation Engineer | Structural validator result and scan output |
| `TP-02` Access/onboarding | Registration, approval/rejection, Host creation, session/recovery | Identity/tenancy build | QA Analyst + Security Reviewer | API/UI evidence and audit record |
| `TP-03` Content/template | Draft, media, revision, approval, Score Template activation | Shared content build | QA Analyst + Business Reviewer | Revision/status evidence |
| `TP-04` Roster/package | Student import, classes, candidate selection, limits, payment/license | Tenant/billing build | QA Analyst | Conflict/capacity/callback evidence |
| `TP-05` Exam generation | Draft validation, fixed version, form mode, schedule/lifecycle | Report 4 generation design | QA Analyst + Automation Engineer | Snapshot/provenance/state evidence |
| `TP-06` Student delivery | Device check, timed tasks, local save, sync/retry, submit | Windows client + attempt service | QA Analyst + Automation Engineer | Client/server correlation evidence |
| `TP-07` Integrity | Proctor assignment, monitoring, violation, allowed intervention | Proctoring design and policy | Security Reviewer + QA Analyst | Assignment/audit/policy evidence |
| `TP-08` Scoring/report | Examiner queue, source states, Host review, readiness, publication | Scoring/reporting design | QA Analyst + Business Reviewer | Score-source/publication evidence |
| `TP-09` External services | Payment/media/AI/notification failure/retry/idempotency | Provider boundary/simulators | Integration test owner | Correlation/retry evidence |
| `TP-10` Quality targets | Performance, availability/recovery, accessibility, compatibility | Stable environment and workload | Performance Analyst/Security Reviewer | Dated measured results |

## 3.2 Execution order

1. Run structural/encoding/secret checks before functional execution.
2. Establish two organization fixtures and role/assignment fixtures.
3. Verify onboarding and access before creating tenant-owned test data.
4. Verify content/template readiness before exam generation.
5. Verify package/roster validation before schedule/generation tests.
6. Verify fixed-version generation before delivery/proctor/scoring tests.
7. Run delivery/retry cases before publication cases, because reports depend on submitted attempts.
8. Run scoring/publication and notification failure cases.
9. Run cross-flow, performance, recovery, accessibility, and compatibility checks after the baseline is stable.

## 3.3 Environment matrix

| Environment ID | Purpose | Required records | Sensitive-data rule |
|---|---|---|---|
| `ENV-DOCS` | Structural documentation tests | Repository commit/worktree identifier, Python version | No product data. |
| `ENV-LOCAL` | Developer API/UI/client checks | Compose profile, build identifier, configuration checklist | Local synthetic data only. |
| `ENV-STAGE` | Integrated UAT and provider simulation | Deployment ID, web/client builds, provider mode | Masked synthetic organization/Student data. |
| `ENV-PERF` | NFR load/capacity/recovery | Workload profile, resource limits, monitoring | Synthetic data; no real credentials in tools. |
| `ENV-PROD-DRILL` | Approved operations drill only | Incident/change approval and backup evidence | Requires explicit operational authorization; not implied by this report. |

## 3.4 Entry checklist

- Build and deployment identifier recorded.
- Database migration/configuration state known.
- Test accounts have only the intended approved product role.
- Organization A and B fixtures are isolated and safe.
- Content/media/template revisions are versioned and complete for the test mode.
- Package/license and date/capacity data are deterministic.
- Provider stubs/sandboxes and failure controls are identified.
- Evidence folder is writable and contains no secrets.

## 3.5 Exit checklist

- Critical/high cases have executed evidence or a documented blocker/dependency.
- No test result is inferred from a plan, screenshot mock, or code presence alone.
- Defect IDs link to requirement/design/case and owner.
- NFR measurements include workload/environment/tool/result.
- Cross-tenant and assignment-negative cases are included.
- Offline/retry/duplicate/publication cases are included.
- Remaining TBD items are visible in the handoff report.

## 3.6 Schedule and milestones

Dates are intentionally represented as release-planning slots until the project schedule is approved.

| Milestone | Entry | Exit | Status |
|---|---|---|---|
| `M-01` Documentation baseline | Reports 3–4 exist | Structural and traceability scan | Current for this documentation work package |
| `M-02` Core functional readiness | Access/content/roster/exam flows available | Critical functional/negative cases have evidence | Planned/Future |
| `M-03` Delivery and integrity readiness | Fixed version and client baseline available | Retry, Proctor, audit, and submission evidence | Planned/Future/TBD client matrix |
| `M-04` Scoring/publication readiness | Score sources and Host review available | Publication gate and Student visibility evidence | Planned/Future/TBD AI policy |
| `M-05` Release acceptance | Functional and NFR evidence reviewed | Test report/sign-off with open defects | Planned/Future |

## 3.7 Test record ownership

The person executing a case is responsible for actual evidence, but the Test Lead owns the summary. A product actor may participate in UAT, but a test result must identify test responsibility separately from the product role to avoid confusing permissions with verification ownership.

