# Phase 1: Domain Model Redesign

## Requirements

Restructure the `Question` and `Exam` entities to support all 20 PTE Academic task types with type-specific fields (e.g., audio prompt for Read Aloud, image for Describe Image, reference answer for scoring). Replace the current one-skill-per-question model (APTIS-era `skill_subset_*` booleans) with a config-driven multi-skill-per-task scoring mapping that allows a single task to contribute to multiple communicative and enabling skills simultaneously.

This phase delivers the foundation for all downstream work: without the correct question schema and skill-mapping structure, exam delivery, scoring, and reporting cannot proceed correctly.

## Design Constraints

- The domain model must support the fixed 20 PTE task types; no attempt to make it infinitely generic or provider-agnostic (PTE is the only scope).
- Task-to-skill mapping is **config-driven** (static rubric files or data-driven config, not a dynamic DB join-table). This decision prevents migration churn and aligns with the fixed PTE taxonomy; do not introduce a generic N:N join-table.
- The model must remain backward-compatible at the API level for the proctor module and examdelivery state machine; breaking changes to attempt state or user-facing question rendering must not occur. (The internal Question schema can change; the external API contract for "get question details" can be versioned or adapted, but the attempt lifecycle must remain stable.)
- Multi-tenancy (tenant isolation in the question bank) must be preserved exactly as it is now; no changes to the `tenancy` module.
- The canonical 20-task-type list (spec.md Assumptions) is a working assumption, not verified fact — it must be cross-checked against official Pearson PTE Academic materials before the schema is finalized (Step 1a). If the list is wrong, this phase's schema design changes.
- `correct_answer`/`correct_answers` fields are **mandatory** at the schema level for every objective task type (multiple-choice, fill-in-blank, re-order, highlight, select-missing-word) — enforced by save-time validation, not left optional for Phase 6 to discover missing.

## Steps

1. Audit the current `Question` entity schema (skill enums, questionType enum, part, difficultyLevel, versioning, tenant isolation) and document all APTIS-specific fields that must be removed or repurposed (e.g., `skill_subset_listening` → removed, replaced by config-driven mapping).

1a. Cross-reference the assumed 20-task-type list (spec.md Assumptions) against the current official Pearson PTE Academic specification (candidate guide / official task-type documentation). Document the confirmation (or corrections) in the research report started in this phase. If discrepancies are found, escalate to the thesis advisor and update the list before proceeding to Step 2.

2. Design the new `Question` schema to support all 20 PTE task types, including type-specific fields: for each task type, identify the required fields (e.g., Read Aloud needs audio_prompt_url + reference_answer_text; Describe Image needs image_url + model_response_text; Multiple Choice needs options list + correct_answer_index). Document the schema change as a migration plan (SQL DDL or JPA entity update).

3. Design the config-driven skill-mapping schema: define how a single task type (e.g., Describe Image) maps to multiple skills (e.g., Speaking, Oral Fluency, Vocabulary). Store this as a versioned config file (JSON or YAML) in the codebase or as versioned data in a small reference table (TaskTypeRubric). Document the schema.

4. Create or update the `Exam` and `ExamQuestion` entities to support multiple skills per question (replacing `skill_subset_*` booleans). Add fields to track which skills a submitted answer will be scored on (derived from the task-type's config-driven mapping).

5. Implement JPA migrations or Flyway scripts to transform the database schema (remove APTIS skill fields, add PTE task-type fields, add scoring-config references). For tenants with existing question data, implement a data-migration script that archival old questions under a legacy tenant or marks them with a deprecation flag. **Decide and document the legacy-data policy explicitly**, choosing one: (A) APTIS questions are archived and unavailable for new exams, but existing in-progress attempts complete normally with old scoring logic, and archived exams show an "archived" badge in the student dashboard; (B) APTIS questions are fully migrated/converted to PTE format; (C) APTIS and PTE questions coexist and are scored separately. Default to (A) unless the user/advisor requests otherwise, since it's the lowest-risk option — write the decision into this phase's Success Criteria and verify it in Phase 9.

6. Update the `Question` repository/service layer (Spring Data JPA or custom queries) to filter and sort questions by task type, to validate task-type-specific required fields on save (including: reject save if an objective task type is missing `correct_answer`/`correct_answers`), and to load the config-driven skill mapping on retrieval.

7. Create unit tests for the new Question schema: test field validation per task type (e.g., Read Aloud missing audio_prompt_url must fail), test skill-mapping config loading, test backward-compatibility of the Question API for existing proctor/examdelivery code paths.

8. Update the domain model documentation (entity diagrams, API contracts) to reflect the new schema. Mark APTIS-specific sections as "deprecated" and cross-reference Phase 9 (documentation supersession).

## Success Criteria

- All 20 PTE task types have working creation forms in the question-bank backend (CRUD endpoints accept type-specific fields, validate required fields per type, persist to DB).
- Task-to-skill mapping config is versioned and loadable at runtime (if stored as files, they are in `src/main/resources/config/` and loaded by Spring; if stored in DB, a seed script populates the reference data).
- Existing `examdelivery` state machine, `proctor` audit trail, and `iam`/`tenancy` isolation continue to work unchanged with sample PTE questions (no null-pointer exceptions, no permission errors).
- Unit tests for `Question` entity and config-mapping service are passing (minimum 80% code coverage on new code paths).
- Schema migration script is idempotent and can be run on a copy of the production DB without data loss or integrity violations.

## Quality and Testing State

- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementing this phase)
- Testing: not started (Unit tests for entity validation, field-mapping, config-loading will be written during implementation; integration tests will come in Phase 9)

## Risks

- **MEDIUM: Existing Data Migration** — If production tenants have thousands of APTIS questions, the data-migration script may be slow or may fail on edge cases (malformed data, missing fields). *Mitigation:* Test the migration script on a production-size snapshot before running on production; implement a dry-run mode; plan for a maintenance window.

- **MEDIUM: Schema Versioning Complexity** — Supporting both APTIS and PTE questions during a transition period (if needed) doubles the schema complexity. *Mitigation:* This phase fully removes APTIS fields (not dual-support); existing APTIS questions are archived or migrated to a legacy tenant. If dual-support is later required, it becomes a separate phase.

- **LOW: Task-Type Enum Explosion** — Defining 20 explicit task types as Java enums or DB rows is verbose but manageable. If the list ever changes (new PTE versions), enum values must be updated in code and DB. *Mitigation:* Store task-type definitions in config, not as code-level enums; allow new types to be added without code recompile.

