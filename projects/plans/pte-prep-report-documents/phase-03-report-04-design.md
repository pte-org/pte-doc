# Phase 03 — Report 4: Software Design Document

## Objective

Create the project-specific English Report 4 design set from the frozen Report 3 requirements and verified repository architecture. The design must explain component ownership, deployment boundaries, data relationships, and detailed interactions for the PTE Prep core flows without describing legacy modules as independent production microservices or presenting future design as current implementation.

## Inputs / Outputs

### Inputs

- Phase 01 foundation and Phase 02 Report 3 IDs.
- `pte-doc/projects/pte-org-srs/spec.md` and relevant approved plans/ADRs.
- Backend modular-monolith source/configuration, tenant/vendor web source, Flutter Windows client source/design, Compose/Caddy topology, and integration contracts where available.
- `template-doc/Report4_Software Design Document.docx` and the Report 4 template for section order and expected diagram types.

### Outputs

- `pte-doc/report/report04/00-project-report.md`
- `pte-doc/report/report04/00-record-of-changes.md`
- `pte-doc/report/report04/01-system-design.md`
- `pte-doc/report/report04/02-database-design.md`
- `pte-doc/report/report04/03-detailed-design.md`
- Report 4 architecture/package/ERD/class/sequence/deployment assets or explicit TBD placeholders.
- Updated design ID ledger and Report 3-to-Report 4 traceability matrix.

## Dependencies

- Phase 02 must provide stable `FR-*`, `NFR-*`, `UC-*`, and `BR-*` IDs.
- Current/Partial/Future labels must follow Phase 01 evidence rules.
- Any proposed design change that alters a requirement must be recorded as an open decision, not hidden in the design report.

## Detailed Steps

1. Write the record of changes with Report 4 metadata and the baseline source links.
2. In `00-project-report.md`, map the DOCX document-level `II. Software Design Document` heading and provide report metadata, navigation, design-status summary, and links to all Report 4 section files.
3. Write **System Design**:
   - describe the three channels: organization web portal, platform administration portal, and Windows-first exam client;
   - describe the Spring/Java modular-monolith application, PostgreSQL, Redis, RabbitMQ, edge proxy, Docker Compose deployment, and internal/public boundaries;
   - describe signed browser-to-Cloudinary media upload and other external integration boundaries without exposing secrets;
   - distinguish Current, Partial, Planned/Future, and TBD components;
   - define package/module ownership for identity, tenant/organization, content, scoring, package/license, exam, delivery, proctoring, Examiner, reporting, audit, and integrations;
   - define authentication, authorization, tenant scope, assignment scope, and public service boundaries;
   - create or link context, deployment, package, and component diagrams with `SD-*`, `PKG-*`, and `ADR-*` IDs.
4. Write **Database Design**:
   - identify Organization, user/role, registration, package/license/order, Student/membership, program/class/enrollment, question/media/revision, score template/task, exam/session/form/attempt, answer/outbox/sync state, Proctor assignment/violation, Examiner assignment/score, report/publication, notification, and audit entities as supported by evidence;
   - document tenant ownership, primary/foreign keys, lifecycle/status fields, immutability/snapshot rules, uniqueness/conflict rules, indexes or query needs where evidence exists, and retention classification;
   - define relationships and invariants for fixed exam versions, per-Student forms, local-first answers, score-source coexistence, and publication visibility;
   - create/link an ERD with `DB-*` IDs and mark unsupported columns/relationships TBD rather than inventing schemas.
5. Write **Detailed Design** for the high-risk flows:
   - registration approval and Host activation;
   - exam draft, pre-exam validation, fixed version/form generation, and scheduling;
   - Student task timing, local answer persistence, outbox sync, retry, recovery, and final submission;
   - Proctor assignment, monitoring, violation recording, policy state, and audit;
   - Host assignment to Examiner, work queue, marking, score-source review, readiness checks, and report publication;
   - include class/component responsibilities, inputs/outputs, state transitions, validation/error paths, idempotency/concurrency points, and links to `FR-*`, `BR-*`, and `NFR-*`.
6. Create class/sequence/state diagrams for the detailed flows using `SD-*`, `SEQ-*`, and `DB-*` identifiers. Link each diagram to requirements and document status/source.
7. Reconcile design claims against source code and approved plans. A proposed behavior without implementation evidence receives Planned/Future or TBD status.
8. Update the shared ledger and create a design traceability matrix showing each core design element’s requirement, actor, data, and test/guide dependency.
9. Scan for legacy microservice claims, generic sample diagrams, fake endpoints, secrets, and broken relative asset links.

## Acceptance Criteria

- [ ] The five Report 4 files exist under `pte-doc/report/report04/`: `00-project-report.md`, `00-record-of-changes.md`, and three numbered section files, plus mandatory `assets/`.
- [ ] Report 4 preserves the DOCX document-level and child section order.
- [ ] System Design covers the three channels, modular-monolith topology, data/support services, external boundaries, authorization, package ownership, and deployment.
- [ ] Database Design covers entity ownership, tenant keys, relationships, lifecycle/status, immutability/snapshots, and retention classification.
- [ ] Detailed Design covers onboarding, exam generation/scheduling, answer synchronization/retry, Proctor audit, Examiner scoring, score selection, and publication.
- [ ] Every diagram/table has ID, caption, status, evidence/source note, and linked Report 3 IDs.
- [ ] No legacy service directory is documented as an independent production microservice.
- [ ] No design claim is labeled Current without source/config/UI/API evidence.
- [ ] Database/design IDs are unique and cross-links resolve or state TBD.
- [ ] No credentials, private keys, production environment values, or invented provider contracts appear.

## Design Constraints

- Preflight: Read the Phase 01 foundation, the completed Report 3 cover/section map, the modular-monolith/Compose source configuration, and the existing design template. Conventions carried forward are one deployed application boundary, business-readable explanations next to diagrams, stable `SD`/`DB`/`SEQ` IDs, and explicit Current/Partial/Planned/Future/TBD evidence notes. This phase writes only `pte-doc/report/report04/` plus declared test/plan artifacts.

- Report 4 realizes Report 3; it cannot silently redefine scope or introduce new actors.
- The production deployment is a single Dockerized modular-monolith stack behind an edge proxy; internal backend ports are not public product endpoints.
- PostgreSQL is the shared relational database; do not reintroduce legacy multi-database assumptions.
- Cloudinary, payment, AI scoring, notification, Redis, and RabbitMQ behavior must be described only at the contract/evidence level available.
- Fixed exam/version/answer/report invariants must be explicit; design diagrams cannot replace prose rules.
- Use business-readable explanations alongside technical diagrams.
- Unknown schema/sequence details are TBD with owner and impact, not guessed.

## Quality and Testing State

- **Quality:** Not evaluated.
- **Testing:** Not started.
- **Planned checks:** architecture/section-map review, diagram metadata check, requirement/design link scan, duplicate ID scan, secret scan, UTF-8 scan, relative asset link check, legacy microservice phrase scan.
- **Product runtime tests:** Not applicable unless implementation changes are introduced.

## Risks / Notes

- The design template path under `projects/templates/report/report03/` is misleading; generated Report 4 files must use `pte-doc/report/report04/`.
- Source plans may describe future work; preserve status labels rather than copying future design into Current sections.
- Detailed design may reveal requirements that need amendment. Record an issue/TBD and return to Report 3 rather than creating an untraceable design-only rule.
- Diagram assets can be Mermaid source, exported images, or explicit TBD placeholders; all need captions and evidence notes.

## Spec / User Story Mapping

- Spec: FR-09, FR-10, FR-14, FR-15, FR-17; NFR-05, NFR-06, NFR-07, NFR-10, NFR-11, NFR-12, NFR-14, NFR-16, NFR-17, NFR-18, NFR-19.
- User stories: P1 technical-lead architecture/design; P1 reviewer traceability; P1 current/partial/future status; P1 stable diagram/assets.


## Execution Notes

- Status: completed for cook Phase 03.
- RED/GREEN: `python tests/test_phase03_report04.py` initially failed because the design sections and architecture/data/sequence content were absent; after implementation it returned `GREEN/PASSED`.
- Build Gate: Python syntax compilation passed for the phase validator.
- Testing: passed under TDD verify; result at `tests/results/phase-03-report-04-design-test-report.json`.
- Quality: approved; report at `quality/phase-03-report-04-design-quality-report.json`.
- Outputs: System Design, Database Design, Detailed Design, architecture/deployment/ERD/state/sequence diagrams, and explicit TBD design limits.
