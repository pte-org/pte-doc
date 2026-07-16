# Phase 1: Domain Model Redesign

## Requirements

Restructure the `Question` and `Exam` entities to support all 22 PTE Academic task types with type-specific fields (e.g., audio prompt for Read Aloud, image for Describe Image, reference answer for scoring). Replace the current one-skill-per-question model (APTIS-era `skill_subset_*` booleans) with a config-driven multi-skill-per-task scoring mapping that allows a single task to contribute to multiple communicative and enabling skills simultaneously.

This phase delivers the foundation for all downstream work: without the correct question schema and skill-mapping structure, exam delivery, scoring, and reporting cannot proceed correctly.

## Design Constraints

- The domain model must support the fixed 22 PTE task types; no attempt to make it infinitely generic or provider-agnostic (PTE is the only scope).
- Task-to-skill mapping is **config-driven** (static rubric files or data-driven config, not a dynamic DB join-table). This decision prevents migration churn and aligns with the fixed PTE taxonomy; do not introduce a generic N:N join-table.
- The model must remain backward-compatible at the API level for the proctor module and examdelivery state machine; breaking changes to attempt state or user-facing question rendering must not occur. (The internal Question schema can change; the external API contract for "get question details" can be versioned or adapted, but the attempt lifecycle must remain stable.)
- Multi-tenancy (tenant isolation in the question bank) must be preserved exactly as it is now; no changes to the `tenancy` module.
- The canonical 20-task-type list (spec.md Assumptions) is a working assumption, not verified fact — it must be cross-checked against official Pearson PTE Academic materials before the schema is finalized (Step 1a). If the list is wrong, this phase's schema design changes.
- `correct_answer`/`correct_answers` fields are **mandatory** at the schema level for every objective task type (multiple-choice, fill-in-blank, re-order, highlight, select-missing-word) — enforced by save-time validation, not left optional for Phase 6 to discover missing.

Preflight: Repo is Spring Boot 4.1 / Java / JPA / Lombok, module layout `constant/controller/domain/dto/interfaces/repository/service` per `docs/CODING_STANDARDS_API.md`. Conventions in force: no hardcoded strings (messages/codes in `*Constants.java`); no `@Data` on `@Entity` (use `@Getter @Setter @NoArgsConstructor`, as `Question`/`Exam` already do); `@Transactional` only in `service/`, `readOnly = true` for queries; every endpoint returns `ApiResponse<T>`; exceptions via `@ControllerAdvice`, no try-catch in controllers; validation via `@Valid` + Bean Validation annotations on request DTOs, not manual null-checks in service; tenant isolation via a `tenantId` method parameter threaded controller→service→repository (never read from a static/thread-local context inside repository); Service classes ≤5 public methods, split into `*Helper` if exceeded; files ≤300 lines; **all enums live in `domain/enums/`** (new convention, added this session — `PteTaskType`, `Skill`, `QuestionType`, `QuestionStatus`, `QuestionSource`, `DifficultyLevel` already moved there). `Question` extends `BaseEntity` (`Long id`, `UUID publicId`, audit timestamps, soft-delete `deleted` flag) — new Question work should not duplicate those fields. `Exam`/`ExamQuestion` use invariant-enforcing methods (`addQuestion`/`removeQuestion`) rather than public setters on collections — follow that pattern for any new invariant-bearing mutation.

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

## Implementation Notes (2026-07-16, Senior 1)

- **Step 4 deliberately simplified**: `Exam.skill_subset_*` booleans were **kept as-is**, not replaced — they gate which skill *sections* a session includes (still a valid PTE concept, e.g. a practice exam covering only Speaking+Writing), which is a different concern from "which skills does this task's score contribute to" (now answered live by `PteTaskTypeSkillMapping.skillsFor(question.getPteTaskType())`). No redundant "scored skills" field was added to `ExamQuestion`, since it's fully derivable from `Question.pteTaskType` at read time — storing it too would just be a second source of truth to keep in sync (violates DRY). `ExamContentDeliveryService.isSkillEnabled` was updated so the 4 new enabling skills (Oral Fluency, Pronunciation, Spelling, Written Discourse) aren't gated by the 4-skill subset either (same treatment as Grammar/Vocabulary already had).
- **Step 5 migration implemented** (`V12__add_pte_task_type_to_questions.sql`): adds `pte_task_type`, `reference_answer_text`, `min_word_count`, `max_word_count`; relaxes `skill` to nullable. **Legacy-data policy: Option (A) selected** (archive, don't migrate forward) — but the actual archival *script* (bulk-flagging existing APTIS questions under tenants) is **not yet written**; there's no production APTIS question data in this thesis project yet, so this is deferred until real data exists rather than built speculatively (YAGNI). Tracked as follow-up before any real APTIS→PTE cutover.
- **Step 6 implemented in full**: `QuestionSpecification.buildFilter` filters by `pteTaskType`; `QuestionService.validateOptions` is task-type-aware (`PteTaskType.requiresCorrectAnswer()`) with a fallback to the old MULTIPLE_CHOICE-string check for callers that don't set `pteTaskType` (backward compatible). A quality-gate finding also surfaced and fixed a related gap: `publishQuestion`/`uploadAudio`'s audio-attachment requirement now derives from `PteTaskType.requiresAudioPrompt()` when set, instead of the now-nullable `skill` field.
- **Step 7 implemented**: 5 test files, 40 test methods (TDD red→green), full-suite regression (235 tests) run clean.
- **Step 8 partial**: this file + `phase-01-contract-draft.md` serve as the interim domain-model doc for the team; the formal `pte-doc` architecture rewrite is still Phase 9's job per the original plan.
- **Task-type list corrected twice**: (1) Personal Introduction is not one of the scored types (unscored warm-up); (2) Pearson added 2 new scored types in August 2025 (`RESPOND_TO_A_SITUATION`, `SUMMARIZE_GROUP_DISCUSSION`, both Speaking) — discovered during Phase 7 research and backported here. `PteTaskType` enum now has **23 values total (22 scored + 1 unscored)**, `PteTaskTypeSkillMapping` updated to match, DTO `@Pattern` regexes updated, full test suite re-verified green (235/235). spec.md, plan.md, and phase-02/08/09 files carry pointer corrections.

## Success Criteria

- All 22 PTE task types have working creation forms in the question-bank backend (CRUD endpoints accept type-specific fields, validate required fields per type, persist to DB).
- Task-to-skill mapping config is versioned and loadable at runtime (if stored as files, they are in `src/main/resources/config/` and loaded by Spring; if stored in DB, a seed script populates the reference data).
- Existing `examdelivery` state machine, `proctor` audit trail, and `iam`/`tenancy` isolation continue to work unchanged with sample PTE questions (no null-pointer exceptions, no permission errors).
- Unit tests for `Question` entity and config-mapping service are passing (minimum 80% code coverage on new code paths).
- Schema migration script is idempotent and can be run on a copy of the production DB without data loss or integrity violations.

## Quality and Testing State

- Quality gate: **approved**. 1 HIGH finding (QUAL-001: `Question.skill` relaxed to nullable but `publishQuestion`/`uploadAudio` still branched on it for audio-prompt requirements — fixed with a `PteTaskType.requiresAudioPrompt()` + task-type-aware service helper, verified resolved with no new issues) + 1 NOTED finding (QUAL-002: task-type count corrected from 20 to 22, receipt reissued after the fix). Report + receipt live in the `pte-api` repo (not `pte-doc`) because the receipt fingerprint mechanism requires the report and every reviewed source file to share one git root: `pte-api/plans/quang-pte-pivot/quality/phase-01-domain-model-redesign-{quality-report,receipt}.json`.
- Testing: passed — `--tdd --verify` GREEN. 40/40 target tests pass; full-suite regression sweep 235 tests, 0 failed, 1 skipped (pre-existing, unrelated). Report: `plans/quang-pte-pivot/tests/phase-01-domain-model-redesign-test-report.json`.

## Risks

- **MEDIUM: Existing Data Migration** — If production tenants have thousands of APTIS questions, the data-migration script may be slow or may fail on edge cases (malformed data, missing fields). *Mitigation:* Test the migration script on a production-size snapshot before running on production; implement a dry-run mode; plan for a maintenance window.

- **MEDIUM: Schema Versioning Complexity** — Supporting both APTIS and PTE questions during a transition period (if needed) doubles the schema complexity. *Mitigation:* This phase fully removes APTIS fields (not dual-support); existing APTIS questions are archived or migrated to a legacy tenant. If dual-support is later required, it becomes a separate phase.

- **LOW: Task-Type Enum Explosion** — Defining 20 explicit task types as Java enums or DB rows is verbose but manageable. If the list ever changes (new PTE versions), enum values must be updated in code and DB. *Mitigation:* Store task-type definitions in config, not as code-level enums; allow new types to be added without code recompile.

