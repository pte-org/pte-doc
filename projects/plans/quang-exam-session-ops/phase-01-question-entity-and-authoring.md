# Phase 1: Question Entity Extension & Vendor/Host Authoring

## Requirements

Extend the `Question` entity with tenant scoping (`tenantId` nullable, `source` enum) and implement create-read-update-delete endpoints and UI for Vendor and Host to author questions in all 4 skill types (MCQ, Listening, Writing, Speaking) independently. Vendor-authored questions are shared across all tenants; Host-authored questions are scoped to that tenant only.

Maps to: **P1 Story #1, #2 | FR-01**

## Design Constraints

- Question entity must never allow Host to author Vendor content or see Vendor-scoped questions outside their own tenant.
- Tenant scoping must follow the existing `Asset.tenantId` pattern (nullable field, not a separate table or inheritance hierarchy).
- All endpoints must be gated by role-based access control (VENDOR or HOST role).
- Authoring UI must not expose fields for the 4 skills that are not yet implemented (e.g., audio upload is Phase 2; MCQ question creation in Phase 1 is field-only, no upload).

## Steps

1. Extend `Question` entity in questionbank module with `tenantId: UUID` (nullable) and `source: enum{VENDOR, HOST}` fields; add database migration to add columns with defaults (null, VENDOR for existing rows).

2. Add DAO/repository query methods to fetch questions by `source` and `tenantId` (Vendor → null, Host → specific tenant); ensure Spring Data repository supports these filters.

3. Implement CRUD endpoints (POST create, GET list/detail, PUT update, DELETE) in examoperations or questionbank API controller; apply `@PreAuthorize("hasAuthority('VENDOR')")` or `@PreAuthorize("hasAuthority('HOST')")` respectively; validate tenant scoping on update/delete.

4. Implement role-based access control: if request is from HOST user, automatically set `tenantId` from the authenticated principal's tenant; if VENDOR, leave null.

5. Create authoring UI forms (HTML/React/Angular—match aptis-web tech stack) for Vendor and Host with fields for MCQ question type (correct answer, distractors); stub fields for Listening/Writing/Speaking (UI present but marked "Phase 2–audio upload" and "Phase 2–audio/prompt").

6. Wire form submission to create/update endpoints; validate that all required fields are present (question text, skill type, question type).

7. Implement publish/status transition: author creates question in DRAFT, can publish to LIVE (marks `publishedAt` timestamp); only LIVE questions appear in exam sessions.

8. Test end-to-end: Vendor creates Reading-MCQ, Host creates Speaking-MCQ in their tenant, verify Vendor's question appears in shared list, Host's appears only in their tenant's question list.

## Success Criteria

- Vendor user can create a Reading MCQ question with multiple-choice answers and publish it (visible in shared question bank).
- Host user can create a Listening MCQ question, scoped to their tenant only (invisible to other Hosts and in Vendor's list).
- GET /api/questions list returns only questions relevant to the authenticated user's scope (Vendor sees all, Host sees only their own + Vendor's shared).
- Question created with all required fields and can be queried by skill type and question type.
- Published questions have a `publishedAt` timestamp; draft questions are not served in exam sessions (Phase 3+).

## Quality and Testing State

- Quality gate: **approved** (report: `quality/phase-01-question-entity-and-authoring-quality-report.json`, receipt issued 2026-07-15). One HIGH finding (PERF_NO_N_PLUS_ONE, batch asset loading in `listQuestions`) found and fixed before approval.
- Testing: not started — skipped by user for Phase 1 (policy: unit tests required only for Phase 6-9)

## Session Notes

- Implemented aptis-api backend only (Question entity tenant/source/publishedAt fields, migration V5, tenant-scoped Specification, role/tenant-aware QuestionService with ownership enforcement, publish transition, updated controller with ADMIN+HOST authority and new publish endpoint). "Vendor" maps to the existing ADMIN role — no separate VENDOR role was introduced.
- aptis-web (Next.js) authoring UI forms from the original Steps 5-6 were **not implemented** in this pass — tracked as a known gap (see quality report QUAL-002, NOTED, owner: none) rather than a backend defect.
- Build Gate: PASS (`./mvnw -o clean compile`, 198 source files).

## Risks

- **Tenant scoping bug**: If the DAO query doesn't correctly filter by `tenantId`, a Host could inadvertently create questions visible to other Hosts. Mitigation: write explicit integration tests for cross-tenant visibility before Phase 1 completion; audit DAO query logic during code review.
- **Question type / skill mismatch**: If UI allows creating a Speaking question without audio and database saves it, Phase 5 exam-delivery may crash when trying to serve it. Mitigation: add pre-publish validation that skill type + question type combo is valid (Speaking must have audio URL after Phase 2, etc.); record decision in enum validators.
