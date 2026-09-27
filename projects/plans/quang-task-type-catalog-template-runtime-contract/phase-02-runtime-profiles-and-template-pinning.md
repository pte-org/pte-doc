# Phase 2: Allowlisted Runtime Profiles and Template Pinning

## Objective

Introduce the stable runtime vocabulary that connects a standard task code to its
renderer, answer schema and scoring behavior without binding the database to
implementation class names.

## Files

- `pte-api/app/src/main/java/com/pte/itembank/` runtime profile descriptor,
  public catalog facade and allowlist
- `pte-api/app/src/main/java/com/pte/scoretemplate/domain/ScoreTemplateItem.java`
- `pte-api/app/src/main/java/com/pte/scoretemplate/internal/service/`
  profile resolution and clone/pin mapping
- scoretemplate DTO/mapper/repository tests and the next Flyway migration
- `pte-web/packages/api-client/src/types/questiontype/` only if additive DTOs
  are frozen in this phase

## Implementation steps

1. Define the runtime profile contract in the owning backend module. At minimum
   it contains taskTypeCode, behaviorKey, rendererKey, answerSchemaVersion,
   scoringProfileKey, scoringProfileVersion, required client capabilities and
   lifecycle status.
2. Add an immutable profile persistence model/migration. A profile version is
   unique for its task code and stable keys; retirement is soft and leaves
   historical profiles readable.
3. Implement a BE allowlist/registry for the current 23 standard profiles. The
   registry resolves keys to validation/scoring descriptors; DB values outside
   the allowlist cannot be activated.
4. Expose additive runtime fields through the question-type response. Keep old
   clients valid when fields are absent during rollout. Do not expose executable
   implementation details.
5. Extend ScoreTemplateItem and its DTOs with a pinned profile reference (key
   and versions, or a stable profile public key). Keep taskType and section
   strings to preserve scoretemplate/itembank module boundaries.
6. Resolve the active profile when a draft item is saved/submitted and pin the
   resolved profile on submission/activation. A later profile activation does not
   mutate an existing template.
7. Update clone behavior to copy the pinned profile and create a new draft
   version. Editing the old active/retired version remains forbidden.
8. Add repository/service methods that batch-load profiles for an entire
   template. Avoid a profile query per template item.

## Design Constraints

Preflight: current convention is Java 21/Spring Modulith with public module
facades, JPA entities under the owning module and forward-only Flyway
migrations. Sibling conventions checked: `QuestionTypeDefinition`,
`ScoreTemplateItem`, `ScoreTemplateMapper`, `V43__snapshot_generation_provenance.sql`
and existing repository interaction tests.

- No Class.forName, Dart class name, script, expression or free-form scorer
  value may be persisted or read from the database.
- Runtime profile keys are opaque stable identifiers with semantic version
  fields; changing behavior requires a new version, never an in-place edit.
- A catalog display/active change is not allowed to change a pinned template
  profile or a published snapshot.
- Existing taskType, section and scoringMethod JSON fields remain present. New
  profile fields are additive and must be tolerant of legacy nulls during rollout.
- Only platform-authorized services can create/retire profiles. The MVP UI does
  not let users invent profile keys.
- The canonical profile descriptor is exposed by the itembank public catalog
  facade. The scoring module owns executable scorer implementations and may
  validate/resolve `scoringProfileKey` through a public service, but
  scoretemplate never imports scoring internals or repository classes.
- PERSONAL_INTRODUCTION receives an unscored profile but is not required as a
  scored template item.

## Acceptance criteria

- Every standard task type resolves to exactly one active profile for new
  authoring, and all 22 scored types resolve to a scoring profile.
- A DB row containing an unknown renderer, behavior or scoring key cannot be
  saved as an active profile or activated in a template.
- Saving/cloning a draft pins the intended profile version; activating a newer
  profile does not rewrite the old template item.
- Legacy score-template responses still deserialize when profile fields are
  absent, and canonical V40 task codes are returned on new writes.
- Profile lookup for a full template is batched and covered by a query-count or
  repository interaction test.

## Dependencies and handoff

- Depends on Phase 1 canonical catalog rows and alias mapper.
- Provides the profile contract required by Phase 3 template readiness and
  Phase 4 snapshot provenance.
- Coordinate the new profile DTOs with @pte/api-client only after the BE
  response shape is frozen.

## Quality and Testing State

Status: passed.

Decision: unit tests = yes; quality gate = yes. Runtime fields are additive;
legacy template items may have null pins until they are saved/submitted, while
new drafts and the clean seeded template receive an allowlisted profile version.

Required before phase completion:

- Backend unit tests for registry allowlisting, version immutability, profile
  resolution, template clone pinning and legacy-null compatibility.
- Migration/repository tests for unique profile versions and soft retirement.
- Backend compile and test commands:
  .\mvnw.cmd -pl app -DskipTests compile and
  .\mvnw.cmd -pl app test.
- If API-client types are changed in this phase, run
  corepack pnpm --filter @pte/api-client typecheck and its focused Vitest suite.
- Mandatory ck:quality --gate receipt for domain ownership, API compatibility,
  persistence immutability and security.

Verification: added the allowlisted 23-profile registry, immutable V45 profile
rows, additive catalog runtime/taskTypeCode fields, batched active-profile
resolution, and template-item profile pinning with legacy-null compatibility.
Unit result: PASSED (33 passed, 0 failed, 0 skipped); report:
`tests/phase-02-runtime-profiles-and-template-pinning-test-report.json`.
Quality gate: APPROVED; receipt:
`quality/phase-02-runtime-profiles-and-template-pinning-receipt.json`. Live
PostgreSQL migration execution remains scheduled for Phase 8.
