# Phase 2 — Additive Schema and Model Migration

## Goal

Add persistence for dynamic task identity, normalized uniqueness, capability
contracts, template policy, and migration provenance without deleting legacy
columns or rewriting historical snapshots.

## Dependencies

- Phase 1 contract and normalizers approved.
- Existing migrations through V48 and current question_types,
  task_runtime_profiles, score_template_items, and snapshot schemas.

## Exact files/modules likely affected

Database migrations:

- pte-api/app/src/main/resources/db/migration/V49__dynamic_task_type_identity.sql
- pte-api/app/src/main/resources/db/migration/V50__task_runtime_capability_registry.sql
- pte-api/app/src/main/resources/db/migration/V51__question_task_type_key_dual_identity.sql
- pte-api/app/src/main/resources/db/migration/V52__template_policy_and_contract_columns.sql

Backend model/repository paths:

- pte-api/app/src/main/java/com/pte/itembank/domain/QuestionTypeDefinition.java
- pte-api/app/src/main/java/com/pte/itembank/domain/TaskRuntimeProfile.java
- new pte-api/app/src/main/java/com/pte/itembank/domain/TaskRuntimeContract.java
- pte-api/app/src/main/java/com/pte/itembank/internal/repository/QuestionTypeRepository.java
- pte-api/app/src/main/java/com/pte/itembank/internal/repository/TaskRuntimeProfileRepository.java
- new repository for TaskRuntimeContract
- pte-api/app/src/main/java/com/pte/itembank/domain/Question.java
- pte-api/app/src/main/java/com/pte/scoretemplate/domain/ScoreTemplate.java
- pte-api/app/src/main/java/com/pte/scoretemplate/domain/ScoreTemplateItem.java
- pte-api/app/src/main/java/com/pte/assessment/domain/SnapshotItem.java
- pte-api/app/src/main/java/com/pte/attempt/domain/PinnedItem.java

## Implementation steps

1. Inventory existing rows and legacy code aliases in a throwaway local
   database before writing the migration.
2. Add task_type_key and normalized_display_name to question_types, backfill
   standard rows from code, and create unique indexes after normalization.
3. Add runtime binding columns to question_types. Backfill standard bindings
   from the current task_runtime_profiles/registry projection.
4. Add the canonical capability registry keyed by screen_key and
   contract_version. Seed one contract row for every existing standard
   renderer/profile.
5. Add questions.task_type_key as a nullable logical identity with a foreign
   key/index to the task catalog. Keep questions.pte_task_type NOT NULL while
   the logical key is initially nullable.
6. Add nullable taskTypeKey provenance columns to snapshot_items and equivalent
   pinned tables while their legacy enum columns remain NOT NULL. Do not add a
   non-null constraint yet; all three data sets must be backfilled together.
7. Backfill every existing question, snapshot, and pinned row from its standard
   enum/task code through the single compatibility mapper. Abort with a
   deterministic unresolved-row report if any value is unknown. After the
   complete backfill, enforce task_type_key NOT NULL and its FKs/indexes on
   questions, snapshots, and pinned items; only then make the legacy enum
   columns nullable for future custom rows. Update JPA mappings, projections,
   QuestionFreezeView, BlueprintService, and snapshot DTOs in this phase's
   migration contract. Preserve old enum values for standard dual-write
   compatibility.
8. Add score_templates.template_policy with STANDARD_PTE as the default for
   existing rows. Add canonical task key and contract columns to template
   items while retaining taskType/runtime legacy columns.
9. Make every migration idempotent and use explicit mapping for the three V40
   legacy fill-blank codes. Fail loudly on an unknown existing code instead of
   guessing.
10. Add migration audit notices/counts for inserted, preserved, canonicalized,
   and unresolved rows.

## API/DB contract

Database invariants after migration:

- Existing standard rows have task_type_key equal to canonical code.
- task_type_key is non-null and unique across all catalog rows; retired keys
  are not reusable.
- question_types.code remains NOT NULL for storage compatibility and is set to
  task_type_key for new custom rows; only the legacy API projection filters
  custom rows out. No old enum-valued response is allowed to expose that code.
- Normalization is exact and shared: Unicode NFKC, remove only surrounding
  Unicode whitespace and uppercase Locale.ROOT for keys; convert all Unicode
  whitespace runs to one ASCII space, trim, and lowercase Locale.ROOT for
  display-name comparison. Length limits are applied after normalization (key
  2-64, display name 1-128). Internal key whitespace is not collapsed and
  fails the key regex.
- normalized_display_name is globally unique across active, inactive, deleted,
  and retired history rows; no partial active-only index is allowed.
- questions.task_type_key and snapshot/pinned taskTypeKey are non-null after
  backfill. Legacy enum columns are nullable and may be null only for custom
  rows.
- Migration order is explicit: add nullable task keys and provenance columns;
  backfill standard questions, snapshots, and pinned items; fail on unresolved
  legacy codes; enforce task-key NOT NULL; then make legacy enum columns
  nullable. Phase 8 may add remaining scoring-digest columns, but may not defer
  this task-key backfill.
- A task type binding points only to an active or historically readable
  capability contract.
- Existing score templates default to STANDARD_PTE.
- Existing snapshots and attempts remain readable after deterministic standard
  task-key backfill; no historical content is rewritten.

No migration may store a Java class, Dart class, formula, script, secret, or
unbounded JSON execution instruction.

## Error UX

Migration errors are operator-facing:

- Include counts and unresolved code values in Flyway output.
- Do not expose SQL or credentials in a web response.
- If an unknown code is found, stop the migration with a remediation message;
  do not silently map it to a standard task.

## Security and ownership

- Migration-created capability rows are platform-owned.
- No tenant IDs are introduced into the global capability registry.
- New columns must inherit existing platform authorization at the service/API
  layer; schema migration is not an authorization boundary.

## Design Constraints

- Additive, forward-only Flyway migrations.
- Preserve publicId, soft-delete, timestamps, code, enum, and all old fields as
  compatibility data; make legacy enum columns nullable where custom rows need
  a null representation.
- Do not rewrite published snapshot/pinned-item content.
- Use indexes for task key, normalized name, screen/contract, and question
  task-key queries.
- Resolve migration numbering from the current branch before implementation;
  the V49–V52 names are the expected sequence after V48.
- Use a canonical typed TEXT[]/array representation for required capabilities;
  normalize tokens, remove duplicates, sort deterministically, and reject an
  over-limit array. Do not serialize capability lists into an unbounded JSON
  execution blob.

- Preflight: the additive V49-V56 migration chain, legacy columns, indexes,
  and nullable compatibility fields were reviewed before the model changes.

## Quality and Testing State

Quality: approved; receipt: quality/phase-02-additive-schema-and-model-migration-receipt.json
Testing: passed; report: tests/phase-02-additive-schema-and-model-migration-test-report.json

Required tests:

- Flyway migration test on an empty database.
- Flyway migration test with all 23 standard rows.
- Legacy V40 alias migration test.
- Idempotent rerun test preserving edited labels/order/inactive state.
- Unknown-code failure test.
- Repository uniqueness and index integration tests.
- Existing V6/V7 NOT NULL enum fixtures migrate to nullable legacy columns and
  retain standard values.
- Custom question/snapshot rows with null legacy enum values satisfy the new
  non-null logical-key constraints.
- Java normalizer and database/API availability values round-trip identically.

Mandatory gate:

    /ck:quality --gate D:\GitHub\pte-org\pte-doc\projects\plans\quang-dynamic-task-type-screen-contract\phase-02-additive-schema-and-model-migration.md

## Acceptance criteria

- A clean local database contains all standard catalog/profile rows after
  migration.
- A rerun is a no-op and does not reactivate or overwrite curated metadata.
- Existing old columns/rows remain readable.
- Two future task keys can reference one capability contract without a schema
  uniqueness conflict.
- Existing STANDARD_PTE templates retain their policy and runtime values.

## Verification commands

    .\mvnw.cmd -pl app -Dtest=QuestionTypeCatalogMigrationTest test
    .\mvnw.cmd -pl app -DskipTests compile
    docker compose --env-file .env.local -f docker-compose.yml config
    git diff --check

Run migration tests against a disposable local database; never use production
data for this phase.

## Risks and rollback

Risk: an existing local fixture assumes pte_task_type is non-null for every
question or snapshot. Backfill standard values first, then explicitly migrate
the legacy columns to nullable before enabling custom rows; never fake a custom
enum value.

Risk: normalized display names conflict after whitespace/case cleanup. Stop
with a deterministic conflict report and require explicit operator mapping.

Rollback: disable dynamic creation and activation, retain additive columns and
registry rows, and roll application code back to the legacy read adapter. Do
not drop columns or delete history.
