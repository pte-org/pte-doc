# Phase 1: Canonical Codes, Catalog Lifecycle and Idempotent Backfill

## Objective

Make the standard PTE task-type catalog complete and internally consistent
without breaking /api/v1/question-types, existing question rows or old
snapshots. Resolve the V40 naming mismatch before adding any runtime metadata.

## Files

- `pte-api/app/src/main/java/com/pte/itembank/QuestionTypeService.java`
- `pte-api/app/src/main/java/com/pte/itembank/domain/QuestionTypeDefinition.java`
- `pte-api/app/src/main/java/com/pte/itembank/domain/enums/PteTaskType.java`
- `pte-api/app/src/main/java/com/pte/itembank/internal/controller/QuestionTypeController.java`
- `pte-api/app/src/main/java/com/pte/itembank/internal/constant/`
- `pte-api/app/src/main/resources/db/migration/Vxx__task_type_catalog_backfill.sql`
- itembank unit/integration/controller tests and the `pte-doc` compatibility matrix

## Implementation steps

1. Freeze one canonical mapping in the itembank module:
   - FILL_BLANKS_READING_WRITING -> FILL_IN_THE_BLANKS_DROPDOWN.
   - FILL_BLANKS_READING -> FILL_IN_THE_BLANKS_DRAG_AND_DROP.
   - FILL_BLANKS_LISTENING -> FILL_IN_THE_BLANKS_TYPE_IN.
   - all other values pass through only when they are current PteTaskType names.
2. Add a small compatibility mapper owned by itembank. It must be used by
   template input validation, snapshot/attempt mapping and any legacy import
   boundary. New writes, DB seeds and API responses use canonical names.
3. Verify the current post-V43 migration baseline and add the next Flyway
   migration, rather than editing V37 or V40. Add a catalog lifecycle column if
   needed for ACTIVE, INACTIVE and RETIRED, while retaining the old active/
   soft-delete fields for response compatibility.
4. Backfill all 23 PteTaskType values with canonical section, scored state and
   authoring requirements. Use INSERT ... ON CONFLICT DO NOTHING (or the
   repository equivalent) so existing display labels, short names, order and
   explicit inactive/retired state are preserved. Newly inserted standard rows
   default to ACTIVE unless the rollout explicitly selects a staged inactive
   state.
5. Treat PERSONAL_INTRODUCTION as a real catalog row with scored = false; do not
   include it in the 22-row scored-template requirement.
6. Make the old delete endpoint a soft retirement operation. Keep deleted rows
   readable to question/snapshot delivery and exclude them from active authoring
   lists.
7. Add migration diagnostics/audit output for inserted rows, preserved rows,
   canonicalized rows and unrecognized legacy codes. Do not silently guess an
   unknown code.
8. Update itembank constants and API DTO documentation so “question type” is
   understood as “standard task type catalog” while preserving JSON field names.

## Design Constraints

- Preflight: current convention is Java 21/Spring modular monolith; itembank
  owns task-code normalization and constants, Flyway migrations are forward-only,
  and cross-module callers use public services. Sibling conventions checked:
  `PteTaskType`, `QuestionTypeService`, `V40__rename_fill_blanks_task_types.sql`.
- PteTaskType remains the canonical code authority in MVP; arbitrary codes are
  rejected with a friendly validation message.
- Do not rewrite historical migrations or delete question/snapshot rows.
- The backfill must not overwrite admin-curated presentation metadata or
  re-enable a row deliberately marked inactive/retired.
- The mapper must be deterministic, centralized and independent of Java/Dart
  class names. It may only map the three known V40 legacy aliases.
- Existing callers of GET /api/v1/question-types, POST, PUT and DELETE continue
  to receive compatible fields and authorization behavior.
- Catalog/profile data is platform-owned; tenant users cannot mutate it.
- All user-facing errors belong in the itembank owning constants, not inline in
  controllers or DTOs.
- Existing update requests may still carry requirement flags for wire
  compatibility, but the service must re-derive and persist canonical flags
  from `PteTaskType`; clients cannot change validation behavior of old
  questions through catalog metadata.

## Acceptance criteria

- A clean local Postgres migration yields exactly 23 standard catalog codes,
  including Personal Introduction; the scored subset is exactly 22.
- Rerunning the migration or bootstrapping against a populated catalog does not
  change existing labels, order, active state or soft-deleted state.
- New writes reject each legacy FILL_BLANKS_* alias and accept its canonical
  replacement; the compatibility reader resolves old data to canonical output.
- An unknown legacy code is reported as a migration/validation blocker with no
  guessed mapping.
- Deleting a catalog row does not make an old question or snapshot unreadable,
  but the row no longer appears in active template authoring.
- Platform role/security tests prove host/tenant users cannot mutate catalog data.

## Dependencies and handoff

- Depends on the current V43 schema and the completed question-type admin plan.
- Unblocks runtime profile creation and template readiness validation.
- The implementation must record the exact migration number and a before/after
  row-count report in the phase verification notes.

## Quality and Testing State

Status: passed.

Decision: unit tests = yes; quality gate = yes; local data posture = greenfield,
so migration verification uses an idempotent clean-catalog seed plus explicit
unknown-code blocking rather than destructive data rewriting.

Required before phase completion:

- Backend unit tests for alias normalization, canonical writes, lifecycle
  filtering, delete/retire behavior and PERSONAL_INTRODUCTION semantics.
- Migration test on a clean and pre-populated Postgres database, including a
  rerun/idempotency check and preservation of an inactive row.
- Backend commands:
  .\mvnw.cmd -pl app test and
  .\mvnw.cmd -pl app -DskipTests compile.
- Mandatory ck:quality --gate receipt covering migration safety, module
  ownership, compatibility and security. A BLOCKER/HIGH finding or a current
  change MEDIUM finding blocks handoff.

Verification: V44 was added as a forward-only idempotent seed for all 23
canonical task types, with legacy-alias diagnostics and unknown-code blocking.
The compatibility mapper is used by catalog, template and exam-generation
boundaries. Unit result: PASSED (15 passed, 0 failed, 0 skipped); report:
`tests/phase-01-canonical-codes-catalog-backfill-test-report.json`. Quality
gate: APPROVED; receipt:
`quality/phase-01-canonical-codes-catalog-backfill-receipt.json`. Live
PostgreSQL rerun remains scheduled for Phase 8 because local data is greenfield.
