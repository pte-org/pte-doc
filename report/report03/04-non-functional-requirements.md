# 4. Non-Functional Requirements

This section maps the original DOCX heading **4. Non-Functional Requirements**. It defines quality targets and cross-cutting constraints for PTE Prep. Numeric values are acceptance targets or planning baselines, not evidence that the current environment has already achieved them. Report 5 defines the test objectives and evidence needed to demonstrate them.

## 4.1 Interface requirements

### 4.1.1 Organization and platform web portals

- The portals must provide role-appropriate navigation for Platform Admin, Platform Author, Host, Proctor, and Examiner.
- The organization portal must keep organization-owned data separate and show the current package, exam, assignment, scoring, and publication state in business language.
- The platform portal must show approval/rejection, content revision, package, and audit context to authorized Platform Admins and draft/review context to Platform Authors.
- Forms must show required fields, validation messages, confirmation for irreversible/high-impact actions, and an outcome after save.
- Lists must support understandable search/filter/pagination where a roster or work queue can be large.
- A user must not have to infer a critical state from color alone; text, icon/label, or status description is required.

### 4.1.2 Windows-first exam client

- The client must authenticate the Student and load only eligible assigned exams.
- It must perform the configured device/audio/microphone checks before timed work.
- It must render text, image, audio, selection, text-entry, and recorded-response task controls needed by the fixed exam version.
- It must show preparation/response timers and local save/synchronization state.
- It must retain pending answers locally during a supported temporary connectivity interruption and expose retry/recovery state.
- It must show final submission acknowledgement only after the service accepts or safely records the final state.

### 4.1.3 Application and service interfaces

| Interface | Required behavior | Boundary/status |
|---|---|---|
| Web/API boundary | Authenticated, tenant/assignment-scoped operations with business-readable errors and stable correlation where retries matter. | Current architecture boundary; exact endpoint coverage must be verified. `EVD-FOUNDATION-003`, `EVD-FOUNDATION-004`. |
| PostgreSQL | Store organization ownership, fixed versions, attempts, answers, scores, reports, and audit relationships consistently. | Current infrastructure boundary; schema details are in Report 4. |
| Redis | Support configured cache/session/coordination behavior without becoming the source of truth for submissions or reports. | Current infrastructure boundary; exact use per feature is evidence-dependent. |
| RabbitMQ | Support asynchronous work where configured, with retry/failure visibility and no duplicate business result. | Current infrastructure boundary; provider/workflow status may be Partial/Planned. |
| Cloudinary or approved media service | Signed upload/access, media completion state, and safe link renewal. | External boundary; credentials remain outside documentation. |
| PayOS or approved payment service | Verified callback, order correlation, duplicate-safe activation. | External boundary; registration is not itself a payment. |
| AI scoring service | Correlated request, pending/success/failure/retry/review state, provider threshold TBD. | Partial/Planned/TBD; no unverified quality guarantee. |
| Email/notification service | Attempt/sent/failed state and retry without rolling back business success. | External boundary; notification is not the source of truth. |

### 4.1.4 Data and audit interface

Sensitive Student data, responses, audio, scores, reports, and audit events must use protected connections in transit and must not be written into ordinary diagnostic logs. The interface for export, deletion, legal hold, and retention is contract-dependent and remains TBD until the data policy is approved.

## 4.2 Quality attribute requirements

### 4.2.1 Performance and capacity targets

#### NFR-01 — Ordinary request response target

At least 95% of ordinary user requests should complete within **0.5 seconds** under the agreed acceptance workload, excluding a separately measured external provider wait. This is a target, not a current result.  
**Evidence required:** dated load/run record, endpoint scope, environment, build, and result.  
**Related:** `FR-ORG-001`, `FR-EXAM-003`, `FR-REPORT-002`; `OBJ-PERF-001`.

#### NFR-02 — Concurrent active attempt target

The platform should support **1,000 active Student attempts** at the agreed peak workload without violating answer integrity or tenant isolation. The target needs capacity planning and a measured run.  
**Related:** `FR-DELIVERY-001`–`FR-DELIVERY-008`; `OBJ-PERF-002`.

#### NFR-03 — Answer-ingestion burst target

The platform should accept a burst of **100 answer submissions per second** without silently losing a locally saved answer or creating duplicate accepted answers. Provider/media waits are measured separately.  
**Related:** `FR-DELIVERY-005`–`FR-DELIVERY-007`; `OBJ-PERF-003`.

#### NFR-04 — Pre-exam validation target

Validation for a candidate list of up to **500 Students** should return a usable result within **5 seconds** under the agreed workload. The result must remain correct even when the target time is not met.  
**Related:** `FR-ENROLL-002`, `FR-EXAM-003`; `OBJ-PERF-004`.

### 4.2.2 Availability, recovery, and growth targets

#### NFR-05 — Availability target

Production service availability should target **99.9% per month**, with exclusions and measurement method agreed before acceptance. A local compose run or one successful request is not proof of this target.  
**Related:** `FR-HARDENING-003`, `FR-INTEGRATION-006`; `OBJ-OPS-001`.

#### NFR-06 — Data-loss target

After a severe service failure, recovery planning should limit unrecoverable committed data to **15 minutes** or less, subject to the backup and transaction design actually approved. Local answer data has a separate client-device risk that must be documented.  
**Related:** `FR-DELIVERY-005`–`FR-DELIVERY-006`, `FR-REPORT-005`; `OBJ-RECOVERY-001`.

#### NFR-07 — Recovery-time target

The service should target restoration within **1 hour** after a severe failure, measured from declared incident start to usable service and verified data state. This is not a promise until operations evidence exists.  
**Related:** `FR-HARDENING-003`, `FR-INTEGRATION-006`; `OBJ-RECOVERY-002`.

#### NFR-08 — Growth target

The deployment and data design should support **two to five times** the initial user/load baseline without changing the approved business rules. Capacity evidence must state which component is the limiting factor.  
**Related:** `NFR-01`–`NFR-04`; `OBJ-PERF-005`.

### 4.2.3 Security, privacy, and audit

#### NFR-09 — Tenant isolation

No ordinary user operation may read or modify private data belonging to another organization. Organization, Student, exam, answer, score, report, and audit reads/writes must enforce the correct scope.  
**Evidence required:** authorization tests with positive and negative tenant cases.  
**Related:** `FR-HARDENING-002`, `CR-TENANT-001`; `OBJ-SEC-001`.

#### NFR-10 — Sensitive-action audit coverage

Changes to permissions, payment/package state, enrollment, exam policy, content publication, Proctor violations, score approval/source selection, and report publication must create an audit record containing actor, time, scope, target, action, and outcome. The baseline target is **100% of defined sensitive actions**.  
**Related:** `FR-REPORT-005`, `FR-INTEGRITY-003`, `FR-SCORE-007`; `OBJ-SEC-002`.

#### NFR-11 — Login protection target

The system should apply temporary protection after no more than **five failed sign-in attempts within fifteen minutes** for the configured account/source scope. The exact throttling mechanism may vary, but the user must receive a safe, non-sensitive message.  
**Related:** `FR-ONBOARD-004`; `OBJ-SEC-003`.

#### NFR-12 — Sensitive data handling

Student identity data, answer payloads, recorded media, scores, reports, and audit events must use protected connections and must not appear in ordinary logs. Support/debug artifacts must be masked and access-controlled.  
**Related:** `FR-DELIVERY-005`, `FR-REPORT-005`, `FR-INTEGRATION-005`; `OBJ-SEC-004`.

#### NFR-13 — Retention and data lifecycle

Attempts, answers, scores, reports, media references, and audit logs are retained according to the contract with each organization. The exact period, deletion/export workflow, legal hold, and exception rules are **TBD** under `TBD-RETENTION-001`; no fixed period is claimed here.  
**Related:** `FR-REPORT-005`, `BR-REPORT-043`; `OBJ-DATA-001`.

#### NFR-14 — Jurisdiction and data protection decision

Before production contracting, the applicable country/jurisdiction and data-protection obligations must be recorded. This report does not assert HIPAA, PCI-DSS, SOC 2, or any banking certification. `TBD-DATA-001` remains open.  
**Related:** `FR-INTEGRATION-001`–`FR-INTEGRATION-005`; `OBJ-DATA-002`.

### 4.2.4 Usability, accessibility, and language

#### NFR-15 — Language support

User-facing labels and important messages should support Vietnamese and English in the product baseline, with consistent role and status terminology. This Markdown deliverable is English-first; Vietnamese report copies are deferred.  
**Related:** `FR-REPORT-005`, all role workflows; `OBJ-UX-001`.

#### NFR-16 — Accessibility and keyboard operation

Web portals should target WCAG AA-aligned behavior where applicable: readable contrast, visible focus, keyboard access, meaningful labels, non-color-only status, and understandable error messages. The exact compliance claim requires an accessibility review; it is not assumed from a UI screenshot.  
**Related:** `FR-ONBOARD-004`, `FR-INTEGRITY-002`; `OBJ-UX-002`.

#### NFR-17 — Usable recovery and transparency

When an operation is pending, rejected, queued, or failed, the user should see the affected object, current state, reason at a safe level, and next permitted action. Recovery instructions must distinguish Student/Host/Platform Admin escalation and must not expose provider secrets.  
**Related:** `FR-DELIVERY-006`, `FR-INTEGRATION-005`, `FR-REPORT-002`; `OBJ-UX-003`.

### 4.2.5 Compatibility and delivery

#### NFR-18 — Supported client compatibility

The supported first delivery client is Windows-first. The web portals must support the agreed modern browser baseline; the exact browser/device/microphone matrix is `TBD-CLIENT-001`. Mobile exam delivery is outside this release.  
**Related:** `FR-DELIVERY-002`–`FR-DELIVERY-004`; `OBJ-COMPAT-001`.

#### NFR-19 — Deployment and integration maintainability

The system must preserve clear boundaries between public edge routes, the application, PostgreSQL, Redis, RabbitMQ, the Windows client, and external integrations. Configuration and secrets must be supplied through the approved environment/secret process, not embedded in Markdown, source, or screenshots. Integrations must have observable status, correlation, retry, and failure behavior.  
**Related:** `FR-INTEGRATION-001`–`FR-INTEGRATION-006`, `FR-HARDENING-003`; `OBJ-OPS-002`.

## 4.3 Reliability and consistency principles

1. A locally saved Student answer is not discarded merely because synchronization fails.
2. A retry cannot create a second payment activation, enrollment, answer, score, or report publication.
3. A fixed exam version remains explainable after shared content changes.
4. A pending or failed external result remains distinguishable from a valid result.
5. A report cannot be published while required score readiness conditions are false.
6. An audit record identifies the scope and outcome of a sensitive action.

## 4.4 Verification note

The numeric targets in this section originate from the approved SRS baseline and are classified as acceptance targets by `EVD-FOUNDATION-001`. A Report 5 result must include the target, measured workload, environment, build/baseline, tool/procedure, observed result, and evidence location. Until then, report language must use “target”, “should”, or “baseline”, never “achieved”.

