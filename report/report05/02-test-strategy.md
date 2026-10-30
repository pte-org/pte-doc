# 2. Test Strategy

This section maps the original DOCX heading **2. Test Strategy**. It explains the levels, test types, test data, tools, risk priorities, and evidence rules used to evaluate PTEPrep.

## 2.1 Risk-based strategy

| Risk | Why it matters | Priority | Main coverage |
|---|---|---|---|
| Cross-organization data exposure | A valid login must not reveal another organization’s Students, attempts, scores, or reports. | Critical | Authorization/tenant negative cases, API and UI checks, `NFR-09`. |
| Unreproducible exam version | A content/template edit after delivery could change the Student’s exam or report meaning. | Critical | Snapshot, revision, form, provenance, and mutation attempts. |
| Lost/duplicated answer | A connectivity interruption can damage a timed attempt or create conflicting results. | Critical | Local save, outbox, retry, duplicate correlation, submit recovery. |
| Unsafe publication | An incomplete or unreviewed score may become a Student-visible report. | Critical | Source states, readiness gate, Host selection, publication visibility. |
| Package/roster conflict | An exam may exceed capacity, reuse a Student, or overlap a license window. | High | Validation, duplicate/conflict, package/date/capacity cases. |
| Integrity/audit gap | Proctor actions or score decisions may be untraceable. | High | Assignment scope, violation records, audit fields, policy behavior. |
| External service failure | Payment/media/AI/notification failure may duplicate or silently block a business action. | High | Timeout, retry, duplicate callback, pending/failure state. |
| Performance/recovery shortfall | Peak workload or incident recovery may not meet the SRS target. | High | Target workload and operational evidence; not assumed from local checks. |

## 2.2 Test levels

1. **Structural/documentation checks:** validate section/file structure, IDs, links, roles, placeholders, encoding, and evidence wording. These are the TDD checks used while creating this report set.
2. **Unit/component checks:** validate package-level rules such as candidate deduplication, state transitions, scoring readiness, authorization predicates, and message mapping.
3. **Integration/API checks:** validate application service boundaries, database constraints, queues, provider adapters, and idempotent retries.
4. **UI/client checks:** validate role navigation, form validation, device check, timers, local answer state, work queues, publication visibility, and accessible status presentation.
5. **End-to-end checks:** validate the four vertical flows from onboarding to publication across the channels.
6. **Performance/recovery checks:** measure NFR targets with a controlled workload, service restart/failure, backup/restore, and client connectivity interruption.
7. **Security checks:** validate server-side authorization, tenant/assignment isolation, sensitive-data handling, login protection, and audit completeness.

## 2.3 Test types

| Type | Question answered | Example |
|---|---|---|
| Functional | Does the feature produce the required business outcome? | Host publishes a ready exam and Student can enter it. |
| Negative/validation | Is unsafe or invalid input stopped with a useful reason? | Incomplete media blocks publication. |
| Authorization | Is the operation limited to the correct role/scope? | Proctor from another exam cannot flag an attempt. |
| Tenant isolation | Can an organization see only its own data? | Host A cannot read Student/answer/report from Host B. |
| State transition | Are invalid lifecycle changes rejected? | Closed exam cannot reopen by ordinary Host action. |
| Idempotency/concurrency | Does retry produce one result? | Duplicate payment callback creates one subscription. |
| Recovery/resilience | Does the user recover after temporary failure? | Offline answer remains queued and synchronizes once. |
| Compatibility/accessibility | Can supported users/devices operate safely? | Keyboard focus and Windows microphone check are usable. |
| Performance/capacity | Does measured workload meet the target? | 1,000 active attempts under the agreed scenario. |
| Security/privacy | Are sensitive data and secrets protected? | Raw answer/audio does not appear in ordinary logs. |

## 2.4 Test data strategy

- Use synthetic organization names, accounts, Students, audio, images, prompts, and scores.
- Create at least two organizations for tenant-isolation checks, with similarly named Students to catch accidental global lookup.
- Use separate accounts for each approved product role; keep test-team responsibility labels outside product role fixtures.
- Use deterministic task/template/revision identifiers and a fixed exam-generation seed where a reproducibility check needs one.
- Include valid, missing, duplicate, oversized, expired, inactive, and conflicting input sets.
- Mark provider stubs/simulators clearly; a stub result is not evidence of a real provider contract.
- Never copy real `.env`, tokens, private keys, passwords, production Student data, or unmasked recordings into test assets.

## 2.5 Tool and environment approach

| Area | Preferred evidence | Limitation |
|---|---|---|
| API/service | Reproducible API request/response log with masked data | A mocked response does not prove production routing/provider behavior. |
| Web portal | Browser automation/screenshot with route, account scope, and build | A mocked authenticated route is not production E2E proof. |
| Windows client | Client log/screenshot plus local queue/server acceptance state | Device-specific behavior needs the supported matrix. |
| Database | Safe query/assertion or migration/test output | Do not export sensitive rows. |
| Queue/provider | Correlation/status log and provider simulator/contract evidence | Provider outage simulation must identify what is simulated. |
| Performance | Tool report with workload, latency percentiles, error rate, capacity | One local request is not a capacity result. |
| Recovery | Timeline and before/after integrity check | Recovery target remains unproven without an executed drill. |
| Documentation | Python structural validators and link/encoding scan | Structural GREEN does not prove product runtime behavior. |

## 2.6 Defect and severity model

| Severity | Meaning for PTEPrep |
|---|---|
| Blocker | Data loss/exposure, duplicate material business result, unsafe publication, or inability to execute a critical flow. |
| High | Core workflow or required safeguard fails with no safe workaround. |
| Medium | Requirement or supported path is incorrect but a controlled workaround exists. |
| Low | Minor wording, layout, or non-critical usability issue. |
| Noted/TBD | Evidence/policy gap deliberately recorded for owner decision; not silently treated as pass. |

## 2.7 TDD documentation boundary

The cook pipeline uses RED/GREEN Python structural tests before each report phase. These tests verify the documentation bundle, not the production application. Product tests are specified here for later execution and must not be represented as already run.



## 2.8 Practice and AI test strategy

### 2.8.1 State-focused practice testing

Practice testing follows the state transitions rather than only screen clicks:

1. identity challenge requested -> delivered -> accepted/expired/reused/throttled;
2. context resolved -> entitlement available/locked/revoked/unavailable;
3. catalog item visible -> runnable/unavailable/insufficient content;
4. session created -> active -> saved/pending -> resumed -> submitted/discarded/expired;
5. media grant -> uploading -> bound/failed/retryable;
6. feedback not requested -> queued -> processing -> available/unavailable/retryable failure;
7. progress activity -> pending feedback -> completed activity, without a false score.

### 2.8.2 AI evaluation boundary

AI explanation cases verify correlation, access, provenance, labelling, answer preservation and failure recovery. They do not claim that a generated explanation is academically correct unless a separate approved rubric and human review result exists. Provider timeouts and duplicate callbacks are tested as integration states, not as a reason to delete the Student response.

### 2.8.3 Channel isolation

The same fixture question may be enabled for one, both or neither channel. The test harness must prove that practice selection reads the practice flag and exam generation reads the exam flag, while publication/readiness and task support remain required filters.

The AI test oracle covers both `NFR-AI-001` (provider isolation and recovery) and `NFR-AI-002` (learner-readable, labelled explanation). It checks state, provenance and access rather than declaring a model output academically correct without an approved rubric.
