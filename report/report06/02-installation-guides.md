# 2. Installation Guides

This section maps the original DOCX heading **2. Installation Guides**. It is written for operators and business users. It gives safe prerequisites, access/setup, verification, recovery, and escalation steps without exposing secrets or instructing users to use internal service ports directly.

## 2.1 Installation and access responsibilities

| Area | Responsible person/team | Safe boundary |
|---|---|---|
| Hosted application/deployment | Operations owner | Use the approved repository/workflow/secret process; do not paste secrets into documentation or commands. |
| Platform portal access | Platform Admin | Create/approve Platform Admin/Author access under the identity policy. |
| Organization onboarding | Platform Admin + Host | Registration approval precedes Host workspace/package activation. |
| Windows exam client | Host/Student support | Install the approved client build and run device check before a timed attempt. |
| External providers | Integration/operations owner | Configure provider credentials through the secret manager/environment process. |
| Data/backup/retention | Platform Admin + operations/legal owner | Follow organization contract and approved retention decision; current period is TBD. |

## 2.2 Server/deployment prerequisites

The deployment baseline uses one Dockerized stack behind a public edge:

- public edge/proxy with supported TLS/domain configuration;
- `web-tenant` and `web-vendor` web applications;
- `app` Spring/Java modular-monolith application;
- PostgreSQL database with the expected migrations;
- Redis and RabbitMQ services when the enabled feature requires them;
- health/observability access for the operations owner;
- approved configuration/secret source with least-privilege values;
- backup/restore and rollback procedure approved for the environment.

The exact host size, browser matrix, provider contract, and Windows hardware matrix are environment decisions. Use `TBD-CLIENT-001` and the approved operations checklist rather than guessing a number in a user guide.

## 2.3 Web-user prerequisites

1. Use a supported modern browser with JavaScript/cookies permitted by the organization policy.
2. Use the public edge URL supplied by the Platform Admin; do not browse to an internal backend port.
3. Confirm the account is active and has the intended role/scope.
4. Use synthetic or authorized organization data only in a test/stage environment.
5. Confirm the organization is approved before expecting a Host workspace.
6. Confirm package/license readiness before creating an exam.

## 2.4 Windows exam-client prerequisites

1. Install the approved Windows-first client build from the organization’s release channel.
2. Sign in with the assigned Student account; do not share credentials.
3. Confirm microphone/audio input and required device permissions.
4. Confirm the exam mode’s network and integrity policy.
5. Close unsupported applications or follow the Proctor’s instructions where a controlled policy requires it.
6. Run the device check before the timer begins.
7. Confirm that local storage is available for the answer queue; the client must show save/sync status.
8. If the device check fails, do not start timed work; capture the safe error reference and escalate.

**Requirement links:** `FR-DELIVERY-001`–`FR-DELIVERY-006`, `NFR-18`, `TBD-CLIENT-001`.

## 2.5 `STEP-INSTALL-001` — Prepare a hosted environment

1. Confirm the release identifier, target environment, and approved change/rollback owner.
2. Confirm the repository/build artifacts correspond to the release record.
3. Load configuration from the approved secret/environment process. Never put values in this document, shell history, screenshots, or logs.
4. Validate Compose configuration and required service names without printing environment values.
5. Start or update only the approved stack for the environment.
6. Confirm the edge, web applications, application, PostgreSQL, Redis, and RabbitMQ report the expected process/health state.
7. Run a safe application health check through the approved operations path.
8. Confirm database migrations completed and no destructive data action was requested.
9. Record environment/build/health evidence as `EVD-OPS-*` with masked output.

**Expected result:** The public edge routes to the intended web/API applications; internal services remain internal.  
**Error/recovery:** If a service fails health, stop release handoff, inspect the failed service logs/status, and follow the rollback owner’s procedure. Do not delete database volumes as a first response.  
**Traceability:** `SD-ARCH-DEPLOY-001`, `NFR-05`–`NFR-08`, `NFR-19`, `TC-OPS-001`.

## 2.6 `STEP-INSTALL-002` — Configure an organization safely

1. Platform Admin confirms the organization registration is approved.
2. Create/confirm the first Host access and organization scope.
3. Host signs in through the public organization portal.
4. Host checks organization identity, Student capacity, package/license state, and staff assignment policy.
5. Host activates/redeems an eligible package separately from registration.
6. Confirm the package dates/limits are visible before creating an exam.
7. Record any payment/provider pending state with its correlation reference; do not treat a browser return as payment proof.

**Expected result:** Organization workspace and package state are understandable and separate.  
**Error/recovery:** Rejected registration, inactive package, duplicate callback, or expired license remains visible with an owner/action.  
**Traceability:** `FR-ONBOARD-002`, `FR-PACKAGE-003`–`FR-PACKAGE-005`, `TC-ACCESS-002`, `TC-PACKAGE-002`.

## 2.7 `STEP-INSTALL-003` — Verify an exam client before an exam

1. Student opens the assigned exam from the Windows client.
2. Confirm the exam is published/open and the Student is in the frozen audience.
3. Run device, microphone, audio, connectivity, and policy checks.
4. Confirm the first task loads from the fixed exam version.
5. Save a safe test response only where the organization test procedure permits it.
6. Confirm local save/sync state and remove the test attempt according to the approved data procedure.

**Expected result:** Student can identify readiness before timed work; a failure does not start a misleading timer.  
**Error/recovery:** Capture the client status/reference, correct the device or contact Host/Proctor support, and do not repeat a timed attempt without policy approval.  
**Traceability:** `FR-DELIVERY-001`–`FR-DELIVERY-004`, `TC-DELIVERY-002`, `TC-DELIVERY-003`, `NFR-18`.

## 2.8 Configuration and secret-handling checklist

- Configuration names and required/optional status may be documented; secret values may not.
- Provider credentials are stored in the approved environment/secret manager with least privilege.
- Public URLs may be documented when safe; internal database/queue credentials and private endpoints are not.
- Example commands use placeholders such as `<approved-secret-reference>`, never real values.
- Logs and screenshots mask emails, Student IDs, answer/media content, tokens, and provider payloads.
- A provider sandbox/simulation is labelled clearly in test evidence.

## 2.9 Health and verification checklist

| Check | Expected observation | Evidence ID/status |
|---|---|---|
| Public edge | Supported domain responds and routes to the intended web app/API. | `EVD-OPS-EDGE-*`; execute per environment. |
| Web tenant/vendor | Portal loads without exposing internal addresses. | `EVD-OPS-WEB-*`; environment-specific. |
| Application health | Approved health endpoint/process reports usable state. | `EVD-OPS-APP-*`; not a full business E2E proof. |
| PostgreSQL | Database health/migrations are valid. | `EVD-OPS-DB-*`; no sensitive rows exported. |
| Redis/RabbitMQ | Supporting service health is visible when enabled. | `EVD-OPS-INFRA-*`. |
| Student client | Device check, first task, local save, and sync status work in a safe test. | `EVD-CLIENT-*`; `TBD-CLIENT-001` if incomplete. |
| Provider boundaries | Payment/media/AI/notification state is observable without secrets. | `EVD-INTEGRATION-*`; sandbox/live mode recorded. |

## 2.10 Migration, rollback, and recovery

### Data/migration safeguard

Before a schema/configuration change, record release/build, backup evidence, migration order, compatibility window, and rollback owner. Preserve exam/version/attempt/report provenance. Do not use destructive volume deletion as a routine migration step.

### Rollback

1. Declare the release issue and stop new handoff actions.
2. Identify whether the issue is web, application, migration, provider, or data integrity.
3. Follow the approved version rollback/migration compatibility procedure.
4. Verify public edge and service health.
5. Verify a safe synthetic organization/exam/report read path.
6. Confirm no duplicate payment, answer, score, or publication was created.
7. Record the timeline and evidence; update the related `BUG-*`/`TBD-*` item.

### Student connectivity recovery

The Student follows the client’s visible local-save/retry status. The Host/Proctor must not tell the Student that an answer is submitted until the client/server state confirms it. If local storage or device failure prevents recovery, preserve the safe status and escalate; do not manually invent a score/report.

## 2.11 Support escalation

| Problem | First responder | Escalate to | Evidence to include |
|---|---|---|---|
| Login/session | Account holder/Host | Platform Admin | Safe message/reference, role, organization; never password/token. |
| Package/payment | Host | Platform Admin/integration owner | Order/license correlation and provider state. |
| Content/media | Platform Author | Platform Admin/media owner | Question revision, media status, error reference. |
| Exam generation/conflict | Host | Platform/technical owner | Exam draft ID, validation blockers, generation state. |
| Device/audio | Student/Proctor | Host/exam-client owner | Device-check item and client build. |
| Answer sync | Student/Proctor | Host/technical owner | Attempt/task correlation, local/sync state, time. |
| Violation/audit | Proctor/Host | Integrity/technical owner | Assigned exam, event reference, policy; no raw sensitive payload. |
| Score/publication | Examiner/Host | Scoring/report owner | Source status, readiness blocker, publication state. |
| Notification/provider | Host/Platform Admin | Integration owner | Correlation/status/retry state. |

