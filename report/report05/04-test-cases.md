# 4. Test Cases

This section maps the original DOCX heading **4. Test Cases**. The cases are executable specifications derived from Reports 3–4. Their baseline status is **Planned**; no case is presented as an executed result in this documentation version.

## 4.1 Test-case record format

Each case records:

- `TC-*` case ID and `OBJ-*` objective;
- risk/priority and test level/type;
- product actor and test responsibility separately;
- preconditions, safe data, steps, expected result;
- requirement/business/design/sequence links;
- environment/build and evidence path fields;
- result state to fill only after an actual run.

## 4.2 Access, tenant, and onboarding cases

| ID | Objective | Type/priority | Preconditions and steps | Expected result | Traceability | Planned result/evidence |
|---|---|---|---|---|---|---|
| TC-ACCESS-001 | Verify pending registration cannot enter a workspace | Negative, Critical | Submit valid registration; attempt tenant operation before approval. | Registration remains pending; no Host workspace or package action is available. | `OBJ-ACCESS-001`, `FR-ONBOARD-001`, `BR-ACCESS-008`, `NFR-09` | Planned; fill `ENV-*`, date, observation, evidence. |
| TC-ACCESS-002 | Verify approval materializes one organization/Host | Functional/idempotency, Critical | Approve one pending registration; repeat approval request. | One organization and first Host scope exist; repeat returns existing state; audit shows one decision. | `OBJ-ACCESS-002`, `FR-ONBOARD-002`–`FR-ONBOARD-003`, `SEQ-ONBOARD-001`, `DB-INV-003` | Planned; no execution claim. |
| TC-ACCESS-003 | Verify cross-tenant denial | Authorization, Critical | Sign in as Host A; request Student/attempt/report object belonging to B. | Server denies; no data mutation or sensitive detail appears. | `OBJ-SEC-001`, `FR-HARDENING-002`, `NFR-09`, `DB-INV-001` | Planned; requires Organization A/B fixture. |
| TC-ACCESS-004 | Verify assignment-scope denial | Authorization, High | Proctor/Examiner from another exam requests status/work item. | Access is denied; no event/score is created. | `OBJ-SEC-002`, `FR-INTEGRITY-001`, `FR-SCORE-001`, `CR-AUTH-001` | Planned. |
| TC-ACCESS-005 | Verify login protection and recovery | Security/High | Use invalid credentials up to configured threshold; attempt recovery on locked/suspended account. | Protection state is safe; recovery does not broaden role/tenant scope. | `OBJ-SEC-003`, `FR-ONBOARD-004`, `NFR-11` | Planned; threshold is an NFR target until measured. |

## 4.3 Content, package, roster, and exam preparation cases

| ID | Objective | Type/priority | Preconditions and steps | Expected result | Traceability | Planned result/evidence |
|---|---|---|---|---|---|---|
| TC-CONTENT-001 | Block incomplete required media | Negative, High | Create task draft with required audio/image missing or expired; submit/publish. | Validation identifies media and keeps content non-published. | `OBJ-CONTENT-001`, `FR-CONTENT-002`–`FR-CONTENT-003`, `BR-CONTENT-012` | Planned; provider mode recorded. |
| TC-CONTENT-002 | Preserve revision in a fixed exam | Functional/integrity, Critical | Generate exam using revision A; edit question to revision B; open attempt. | Attempt shows A; B is available only to later eligible generation. | `OBJ-EXAM-001`, `FR-CONTENT-004`, `FR-EXAM-009`, `DB-INV-001`–`DB-INV-002` | Planned; requires snapshot evidence. |
| TC-PACKAGE-001 | Prevent invalid package/capacity/date | Negative, High | Use expired/over-limit/out-of-window package and oversized candidate list; validate draft. | Each blocking condition is named; exam remains unpublished. | `OBJ-PACKAGE-001`, `FR-PACKAGE-005`, `FR-EXAM-003`, `BR-PACKAGE-019`–`BR-PACKAGE-020` | Planned. |
| TC-PACKAGE-002 | Deduplicate license callback/redeem | Idempotency, Critical | Send same verified payment callback/license redemption twice. | One order/subscription/activation; duplicate response identifies existing state. | `OBJ-PACKAGE-002`, `FR-PACKAGE-003`–`FR-PACKAGE-004`, `BR-PACKAGE-021`, `FR-INTEGRATION-001` | Planned; provider callback evidence required. |
| TC-ROSTER-001 | Report invalid and duplicate import rows | Validation, High | Import valid, missing, duplicate, and over-capacity Student rows. | Row-level reasons; no silent partial success; committed records are scoped/audited. | `OBJ-ROSTER-001`, `FR-ORG-002`, `BR-ACCESS-010`, `NFR-04` | Planned. |
| TC-EXAM-001 | Validate candidates and schedule conflict | Negative, Critical | Select Student/class/program with duplicates, existing assignment, and same-license overlap. | Preview explains included/excluded/conflicting candidates; publish blocked until resolved. | `OBJ-EXAM-002`, `FR-ENROLL-002`, `FR-EXAM-003`, `BR-EXAM-024`–`BR-EXAM-026` | Planned. |
| TC-EXAM-002 | Generate fixed form with provenance | Functional, Critical | Use active template/content/package; generate shared and unique-form modes. | Generation status, fixed version, candidate snapshot, selected revisions, and form mode are persisted. | `OBJ-EXAM-003`, `FR-EXAM-004`–`FR-EXAM-005`, `FR-HARDENING-001`, `SD-EXAM-STATE-001` | Planned. |
| TC-EXAM-003 | Recover interrupted generation | Recovery/idempotency, High | Interrupt generation after request; retry and then cancel in separate runs. | No partial publication; retry resumes/returns one result; cancel leaves an auditable safe state. | `OBJ-EXAM-004`, `FR-EXAM-007`, `TBD-GENERATION-001`, `CR-IDEMPOTENCY-001` | Planned; exact state machine is TBD. |

## 4.4 Delivery, retry, and integrity cases

| ID | Objective | Type/priority | Preconditions and steps | Expected result | Traceability | Planned result/evidence |
|---|---|---|---|---|---|---|
| TC-DELIVERY-001 | Block ineligible Student entry | Authorization, Critical | Try unassigned Student, closed exam, and wrong organization. | Entry is denied with safe reason; no attempt is created. | `OBJ-DELIVERY-001`, `FR-DELIVERY-001`, `BR-ACCESS-006`, `NFR-09` | Planned. |
| TC-DELIVERY-002 | Verify device/audio check gate | Compatibility, High | Fail microphone/audio/network/device condition before timed work. | Named failure is shown; timed task does not start or follows explicit policy. | `OBJ-DELIVERY-002`, `FR-DELIVERY-002`, `TBD-CLIENT-001`, `NFR-18` | Planned. |
| TC-DELIVERY-003 | Verify local save during network loss | Recovery, Critical | Start assigned attempt; save text/selection/audio; interrupt network before sync. | Local state remains saved/queued and visible; no “accepted” claim is shown prematurely. | `OBJ-DELIVERY-003`, `FR-DELIVERY-005`–`FR-DELIVERY-006`, `SEQ-ANSWER-SYNC`, `BR-DELIVERY-030`–`BR-DELIVERY-031` | Planned; Windows evidence required. |
| TC-DELIVERY-004 | Verify duplicate answer retry | Idempotency, Critical | Submit same task/correlation twice after a timeout. | One accepted answer; repeat returns accepted existing state or safe duplicate result. | `OBJ-DELIVERY-004`, `FR-DELIVERY-006`–`FR-DELIVERY-007`, `DB-INV-006`, `NFR-03` | Planned. |
| TC-DELIVERY-005 | Verify final submission and retake block | State/negative, High | Submit attempt; request second attempt without retake policy. | First final state remains; second attempt is blocked with policy reason. | `OBJ-DELIVERY-005`, `FR-DELIVERY-008`, `BR-DELIVERY-034`, `DB-INV-005` | Planned. |
| TC-PROCTOR-001 | Verify assigned monitoring and violation audit | Authorization/audit, High | Open assigned/unassigned sessions; record warning/violation under Practice policy. | Only assignment succeeds; event has actor/time/attempt/policy/detail; Practice is not silently invalidated. | `OBJ-INTEGRITY-001`, `FR-INTEGRITY-001`–`FR-INTEGRITY-004`, `SEQ-PROCTOR-AUDIT`, `BR-INTEGRITY-035`, `BR-INTEGRITY-039`, `NFR-10` | Planned; sync timing remains TBD. |

## 4.5 Scoring, publication, and integration cases

| ID | Objective | Type/priority | Preconditions and steps | Expected result | Traceability | Planned result/evidence |
|---|---|---|---|---|---|---|
| TC-SCORE-001 | Prevent conflicting Examiner assignment | Concurrency, High | Assign same answer to two Examiners without review policy. | One active assignment or an explicit review state; no silent overwrite. | `OBJ-SCORE-001`, `FR-SCORE-001`, `DB-INV-007`, `NFR-09` | Planned. |
| TC-SCORE-002 | Keep source states separate | Functional, Critical | Produce objective, AI pending/failure, and Examiner score for one attempt. | Sources remain distinct; pending/failed source is not a valid final score by default. | `OBJ-SCORE-002`, `FR-SCORE-003`–`FR-SCORE-005`, `TBD-AI-001`, `SEQ-SCORE-PUBLISH-001` | Planned. |
| TC-SCORE-003 | Block publication until ready | Negative, Critical | Leave required score missing/pending/unreviewed; request publication. | Readiness lists blockers; report remains Student-invisible. | `OBJ-SCORE-003`, `FR-SCORE-006`, `FR-REPORT-002`–`FR-REPORT-004`, `BR-SCORE-038`, `DB-INV-008` | Planned. |
| TC-REPORT-001 | Publish and restrict own report | Authorization, Critical | Complete scores; Host publishes; Student A/B request reports. | Host publication is audited; A sees only A’s report after publication; B is denied. | `OBJ-REPORT-001`, `FR-REPORT-003`–`FR-REPORT-005`, `BR-REPORT-040`–`BR-REPORT-042`, `NFR-09`–`NFR-10` | Planned. |
| TC-INTEGRATION-001 | Handle AI/media/notification failure | Resilience, High | Simulate timeout, expired media link, AI failure, and notification failure. | Pending/retry/error state is visible; no duplicate score/publication; notification failure does not roll back business result. | `OBJ-INTEGRATION-001`, `FR-INTEGRATION-002`–`FR-INTEGRATION-006`, `BR-INTEGRATION-045`–`BR-INTEGRATION-048`, `NFR-19` | Planned; simulation must be identified. |
| TC-OPS-001 | Measure performance and recovery targets | Performance/recovery, High | Run agreed workload for request/active-attempt/answer/validation targets; execute approved recovery drill. | Report measured latency/capacity/RPO/RTO with environment/build/evidence; no inference from one local request. | `OBJ-PERF-001`–`OBJ-PERF-005`, `OBJ-RECOVERY-001`–`OBJ-RECOVERY-002`, `NFR-01`–`NFR-08` | Planned; no result claimed in this baseline. |

## 4.6 Case completion rule

A test case becomes an execution result only when the tester fills actual result, status, environment/build, date, evidence, and defect/TBD link. A planned row is not a pass, and a structural documentation GREEN result is not product runtime evidence.

