# Phase 05 — Report 6: Release Package and User Guides

## Objective

Create project-specific English Report 6 documentation that explains the PTE Prep release package, supported environment, installation/access and verification steps, operational recovery, and business workflows for all approved roles. The guide must document verified or explicitly labeled partial behavior in plain language and must never expose secrets.

## Inputs / Outputs

### Inputs

- Phase 01 foundation and Phase 02 Report 3 scope/actor/requirements IDs.
- Phase 03 Report 4 deployment, interfaces, states, and detailed flows.
- Phase 04 Report 5 environment, verification, and expected evidence.
- Current UI routes, labels, permissions, Windows exam-client behavior, deployment/configuration docs, and approved operational plans.
- `template-doc/Report6_Software User Guides.docx` for section order.

### Outputs

- `pte-doc/report/report06/00-project-report.md`
- `pte-doc/report/report06/00-record-of-changes.md`
- `pte-doc/report/report06/01-deliverable-package.md`
- `pte-doc/report/report06/02-installation-guides.md`
- `pte-doc/report/report06/03-user-manual.md`
- Troubleshooting/FAQ and screenshot/terminology sections retained inside the mapped parent files or linked assets.
- `assets/` containing masked screenshots/diagrams or explicit TBD entries.
- Updated guide ID ledger and Report 3–5-to-Report 6 traceability table.

## Dependencies

- Report 3 requirements and actor boundaries are frozen for this pass.
- Report 4 must establish supported architecture/deployment boundaries; Report 5 must establish verification/evidence expectations.
- A user-guide step may be labeled Current only when the corresponding UI/client/configuration behavior is verified.
- Real credentials, private keys, production `.env` values, and unmasked personal data are prohibited.

## Detailed Steps

1. Write the record of changes with version, source DOCX, report status, owner, and project-specific adaptation note.
2. In `00-project-report.md`, map the DOCX document-level `II. Release Package & User Guides` heading and provide report metadata, navigation, release-status summary, and links to all Report 6 section files.
3. Write **Deliverable Package**:
   - identify PTE Prep organization web portal, platform administration portal, Windows-first exam client, backend application, database/supporting infrastructure, external integration dependencies, and documentation assets;
   - define release identifiers, supported scope, known partial/TBD items, package contents, and evidence expected for handoff;
   - state that PTE Prep is independent from PTE Academic and is for practice/mock-exam simulation.
4. Write **Installation Guides**:
   - document system requirements for organization/admin web users, server/deployment environment, and Windows exam client;
   - describe access/installation prerequisites, configuration checklist, service startup/health verification, client setup/device check, data/migration safeguards, rollback/recovery, support escalation, and safe cleanup;
   - distinguish internal service addresses from public edge routes and do not instruct users to expose internal backend ports;
   - use placeholders for secrets and refer to the approved secret-management process instead of copying values;
   - add step IDs such as `STEP-INSTALL-*` and verification evidence fields.
5. Write **User Manual** overview and role procedures:
   - Platform Admin: review organization registration, approve/reject, manage platform content/packages, inspect audit and assist account recovery;
   - Platform Author: create/edit question and media drafts, validate content, submit for approval, view revision/status, and understand that publication requires Platform Admin;
   - Host: activate package, manage Students/programs/classes, assign staff, create/validate/generate/schedule exam, manage policies, review scores, publish reports, and inspect audit;
   - Proctor: open assigned monitoring workspace, observe status, assist according to policy, record violations, and understand audit/visibility consequences;
   - Examiner: open assigned queue, review prompt/answer/rubric, enter/submit score, handle reassignment/review, and understand Host score-source selection;
   - Student: sign in, enter assigned eligible exam, complete device check, follow timed tasks, save/sync answers, recover after connectivity loss, submit, and view published results only;
   - for each workflow include `WF-*`, actor, purpose, prerequisites, steps, expected result, messages, alternate/error paths, recovery, visibility, audit effect, and related requirement/test IDs.
6. Retain/support **Support, Troubleshooting, and FAQ** content within the mapped User Manual/Installation files:
   - login/session/password issues;
   - missing/invalid package or capacity;
   - incomplete content/media;
   - exam conflict or generation failure;
   - microphone/audio/device check failure;
   - offline answer synchronization/retry;
   - proctoring/violation handling;
   - pending/failed AI or Examiner scores;
   - report not ready/not visible after publication;
   - external service or notification failure.
7. Create/link screenshots and diagrams with masked/sample data; assign `IMG-*` IDs, captions, status, source, and related `WF/FR/TC` IDs. Mark unavailable screens TBD with intended evidence.
8. Add a screenshot/terminology inventory and guide review checklist. Ensure user-facing names match current UI or are labeled Planned/Future.
9. Cross-check every workflow against Report 3 authorization/business rules, Report 4 states/design, and Report 5 verification/test cases.
10. Scan for secrets, fake support promises, unsupported current claims, generic template prompts, and incorrect role names.

## Acceptance Criteria

- [ ] The five Report 6 files exist under `pte-doc/report/report06/`: `00-project-report.md`, `00-record-of-changes.md`, and three numbered section files, plus mandatory `assets/`.
- [ ] Report 6 preserves the DOCX document-level and child section order.
- [ ] Deliverable Package identifies all three channels and supported dependencies without exposing secrets.
- [ ] Installation/access instructions cover prerequisites, configuration, health/device verification, recovery/rollback, and support escalation.
- [ ] Workflows exist for Platform Admin, Platform Author, Host, Proctor, Examiner, and Student, with actor/precondition/steps/result/error/recovery/audit details.
- [ ] User steps link to approved requirements, design states, and test cases or explicitly state TBD evidence.
- [ ] Troubleshooting covers the main PTE Prep failure and recovery paths, including offline answer sync and score/publication states.
- [ ] Screenshots/assets are masked, captioned, status-labeled, and linked; missing evidence is marked TBD.
- [ ] The guide uses PTE Prep and preserves the independent practice/mock-exam boundary.
- [ ] No real credential, token, private key, `.env` value, or unverified “current” workflow is included.

## Design Constraints

- Preflight: Read the Phase 01 actor/status catalogs, completed Reports 3?5, the deployment/client configuration, and the existing user-guide template. Conventions carried forward are plain business language, role-specific workflows, step IDs, visible status/evidence notes, and safe placeholders instead of secrets or unverified UI claims. This phase writes only `pte-doc/report/report06/` plus declared test/plan artifacts.

- The guide is for business users/operators and must explain technical prerequisites in plain language.
- It must not document roles outside the approved six human roles.
- It must not turn planned AI, advanced anti-cheat, mobile delivery, or unresolved retention into available user features.
- Installation instructions must respect the single-stack Docker/edge topology and internal backend boundaries.
- A guide step must have a visible label/state or be explicitly marked Planned/Future/TBD.
- Sensitive screenshots and exam/student data must be masked or represented with safe examples.

## Quality and Testing State

- **Quality:** Not evaluated.
- **Testing:** Not started.
- **Planned checks:** DOCX section-map check, role/workflow coverage, requirement/design/test link check, UI-label/evidence check, screenshot/link scan, UTF-8/placeholder/secret scan.
- **Product runtime tests:** Not applicable to writing the guide; future UI/client verification may supply evidence for Current labels.

## Risks / Notes

- UI routes and labels can evolve; record the verification date/source and avoid hardcoding unverified screenshots.
- The Windows exam client has device, timer, offline, and synchronization behavior that should be documented from verified evidence, not only from design plans.
- Support instructions must distinguish user-recoverable steps from Host/Platform Admin escalation and provider incidents.
- If a workflow is not currently available, preserve its business intent as Planned/Future/TBD rather than providing a misleading step-by-step procedure.

## Spec / User Story Mapping

- Spec: FR-03, FR-05, FR-13, FR-14, FR-15, FR-16, FR-17; NFR-01, NFR-02, NFR-05, NFR-07, NFR-10, NFR-12, NFR-13, NFR-15, NFR-16, NFR-18, NFR-19.
- User stories: P1 operator installation/access; P1 six role workflows; P1 project-leader traceability; P1 business-readable guidance.


## Execution Notes

- Status: completed for cook Phase 05.
- RED/GREEN: `python tests/test_phase05_report06.py` initially failed because Report 6 sections and role workflow content were absent; after implementation it returned `GREEN/PASSED`.
- Build Gate: Python syntax compilation passed for the phase validator.
- Testing: passed under TDD verify; result at `tests/results/phase-05-report-06-user-guides-test-report.json`.
- Quality: approved; report at `quality/phase-05-report-06-user-guides-quality-report.json`.
- Outputs: deliverable manifest, installation/access/health/recovery guide, six-role user manual, troubleshooting, escalation, and masked/TBD asset inventory.
