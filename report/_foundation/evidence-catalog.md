# PTEPrep Evidence Catalog

**Verification date for this baseline:** 2026-10-06
**Owner:** Documentation work package

The records below are the evidence anchors used by Reports 3–6. They classify the strength and limitation of a source; they do not claim that every planned capability is already available.

| Evidence ID | Status supported | Source / reference | Related scope | Owner / reviewer | Limitation |
|---|---|---|---|---|---|
| `EVD-FOUNDATION-001` | Current | `pte-doc/projects/pte-org-srs/spec.md` — approved PTEPrep SRS baseline | Product boundary, actors, features, NFR targets | Documentation work package | The source contains baseline requirements and target values, not proof that every target is met. |
| `EVD-FOUNDATION-002` | Current | `pte-doc/projects/pte-org-srs/brainstorm.md` — approved business decisions | Organization-first model, role names, core flows, out-of-scope choices | Documentation work package | Brainstorm decisions require implementation evidence before a Current product claim. |
| `EVD-FOUNDATION-003` | Current | `pte-api/` Spring/Java application and configuration inventory | Modular-monolith ownership, persistence and integration boundaries | Technical documentation owner | Source inspection is not a production deployment or end-to-end proof. |
| `EVD-FOUNDATION-004` | Current | `pte-web/` tenant/vendor application inventory | Portal channels, route and permission evidence where verified | Web documentation owner | Route presence alone does not prove every UI path is complete. |
| `EVD-FOUNDATION-005` | Partial | Approved Student delivery, Proctor, Examiner, billing, and anti-cheat plans under `pte-doc/projects/plans/` | Local-first delivery, retry, proctoring, scoring, package and hardening direction | Product/architecture documentation owner | A plan or ADR supports Planned/Future, not Partial, unless an implementation slice is also cited in the report. |
| `EVD-FOUNDATION-006` | Current | `pte-api/docker-compose.yml`, `docker-compose.services.yml`, and `docker-compose.deploy.yml` | Single-stack deployment, PostgreSQL, Redis, RabbitMQ, edge boundary | Operations documentation owner | Compose configuration is not a live health or availability result. |
| `EVD-FOUNDATION-007` | Planned/Future | `pte-doc/projects/plans/quang-pte-microservice-platform/` and related approved plans | Future event, scoring, Proctor, notification, and platform-hardening work | Product/architecture documentation owner | These plans describe direction and must not be written as current user behavior. |
| `EVD-FOUNDATION-008` | Current | Original `template-doc/Report3..6` DOCX files | Section order and presentation expectations | Documentation work package | Template sample content is not PTEPrep business evidence. |
| `EVD-FOUNDATION-009` | Current | `pte-doc/report/_foundation/pte-task-catalog.md` | Complete 23-row task vocabulary used by Reports 3–6 | Report 3 owner | Task row definitions still need content-quality and operational approval where marked TBD. |

## How reports cite evidence

Use a short note near the claim:

> **Status: Partial — evidence `EVD-...` (verified 2026-10-06).** The reviewed slice is ..., while ... remains unresolved.

The note must preserve the limitation. Do not cite a plan as if it were a runtime test.



## Scope revision evidence records

| Evidence ID | Status supported | Source / reference | Limitation |
|---|---|---|---|
| `EVD-REG-001` | Current as a scope source | `template-doc/Generate/FA26SE182_Phieu-dang-ky_v1.2.docx` and the original registration form | Registration v1.2 is a written proposal pending supervisor confirmation; it is not runtime proof |
| `EVD-ROLE-001` | Source observed / Partial | `pte-api/app/src/main/java/com/pte/shared/security/SecurityRoles.java` and related role guards | Role constants and guards do not prove every workflow is complete |
| `EVD-PRACTICE-001` | Partial | `pte-practice/` routes, catalog and Study-Pack components; practice API contracts reviewed on 2026-10-22 | The reviewed source does not prove complete AI explanation delivery or final scoring behavior |
| `EVD-PRACTICE-002` | Planned/Future | Practice requirements, AI explanation design and gap handoff in this revision | Proposed behavior must not be presented as an available click path |
| `EVD-DEPLOY-001` | Source observed | Current Compose files and root deployment topology | Compose configuration is not a live production health result |

The scope revision was inspected on 2026-10-22. Source inspection, plans and registration text are kept separate from executed test evidence. Report 5 may cite these records for planning and maturity classification, but not as Passed results.
