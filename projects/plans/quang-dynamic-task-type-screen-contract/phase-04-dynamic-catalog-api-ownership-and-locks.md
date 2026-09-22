# Phase 4 — Dynamic Task-Type API, Uniqueness, Ownership, and Locks

## Goal

Turn the legacy question-types API into a compatibility-preserving dynamic
task-type catalog. Support free taskTypeKey/displayName input, capability
selection, field-level availability checks, friendly conflicts, and permanent
runtime locking after published use.

## Dependencies

- Phase 1 normalizers and API contract.
- Phase 2 question_types/runtime schema.
- Phase 3 runtime resolver.
- Existing platform role/security configuration.

## Exact files/modules likely affected

- pte-api/app/src/main/java/com/pte/itembank/QuestionTypeService.java
- pte-api/app/src/main/java/com/pte/itembank/domain/QuestionTypeDefinition.java
- pte-api/app/src/main/java/com/pte/itembank/internal/controller/QuestionTypeController.java
- pte-api/app/src/main/java/com/pte/itembank/internal/repository/QuestionTypeRepository.java
- pte-api/app/src/main/java/com/pte/itembank/internal/mapper/QuestionTypeMapper.java
- pte-api/app/src/main/java/com/pte/itembank/dto/request/CreateQuestionTypeRequest.java
- pte-api/app/src/main/java/com/pte/itembank/dto/request/UpdateQuestionTypeRequest.java
- pte-api/app/src/main/java/com/pte/itembank/dto/response/QuestionTypeResponse.java
- pte-api/app/src/main/java/com/pte/itembank/dto/response/SupportedQuestionTypeResponse.java
- new availability/capability response DTOs
- pte-api/app/src/main/java/com/pte/itembank/internal/exception/QuestionTypeCodeAlreadyUsedException.java
- new duplicate-display-name, invalid-key, capability-not-found, and locked
  exceptions
- pte-api/app/src/main/java/com/pte/itembank/internal/constant/ItembankConstants.java
- pte-api/app/src/main/java/com/pte/itembank/TaskTypePublicationUsageService.java
- pte-api/app/src/main/java/com/pte/itembank/internal/repository/TaskTypePublicationUsageRepository.java
- pte-api/app/src/main/resources/db/migration/V53__task_type_publication_usage.sql
- controller security and service tests under
  pte-api/app/src/test/java/com/pte/itembank

## Implementation steps

1. Add the canonical /api/v1/task-types CRUD surface for dynamic rows while
   retaining /api/v1/question-types as a standard-only compatibility adapter.
   Accept additive taskTypeKey and screenKey fields on the new surface; retain
   legacy code-only standard requests on the old surface.
2. Normalize key and display name before all lookups. Check uniqueness in the
   service and enforce it again through database unique indexes.
3. Add GET availability with optional excludePublicId for edit forms. Return
   only normalized values and booleans/conflict codes.
4. Add a capability list endpoint for platform-authorized forms. Return only
   active contracts and the fields needed to select one.
5. Resolve the selected contract server-side; ignore client-provided
   behavior/scoring/requirements.
6. Make taskTypeKey immutable in update. Permit display metadata updates.
   Permit screen/section/runtime changes only when no append-only publication
   usage exists and the replacement contract is active.
7. Add a transactionally guarded usage check. Use optimistic version or row
   locking so a template publication racing with an edit cannot bypass the
   lock.
8. Preserve delete response semantics on both surfaces but implement soft
   retirement. Never
   allow a retired key to be reused.
9. Return editability and lock details in catalog responses so web can disable
   fields without guessing.
10. Ensure role checks apply to all list, availability, create, update, delete,
    and capability endpoints.

## API/DB contract

Create accepts taskTypeKey, displayName, shortName, section, screenKey,
contractVersion, displayOrder, and active. Legacy code remains accepted only
for known standard types.

Update accepts display metadata and lifecycle fields plus runtime fields only
when unlocked. A locked runtime update returns HTTP 409:

    code: TASK_TYPE_RUNTIME_LOCKED
    details.lockedFields
    details.firstPublishedAt
    details.publishedTemplateCount

Availability returns:

    taskTypeKey.normalized
    taskTypeKey.available
    displayName.normalized
    displayName.available

Publication usage is append-only and contains taskTypeKey, template public ID,
template version, publication time, and actor/audit reference. It is never
deleted by archive/retire.

## Error UX

Map duplicate and lock conflicts to plain language:

- “That task type key is already in use.”
- “That display name is already used.”
- “This task type is already part of a published template. Its screen and
  scoring contract cannot be changed. Create a new task type if behavior must
  change.”
- “The selected screen is not currently supported by the platform.”

Frontend availability is advisory; the 409 response is authoritative.

## Security and ownership

- Platform Admin and Platform Author may create/edit per the existing policy.
- Capability registry content is release-owned: only a coordinated
  backend/pte-app release seed may create or alter contract fields. Platform
  Admin may activate or retire an existing seeded contract if the current
  policy requires it, but has no UI write path for renderer, scorer, schema,
  or authoring behavior.
- Tenant/host receives no write path and cannot infer internal implementation
  details from conflicts.
- Use audit events for create, update, retire, duplicate attempt, and locked
  update rejection.

## Design Constraints

- Existing endpoint paths and wire fields remain valid.
- taskTypeKey is never silently changed after creation.
- Published use is determined by append-only usage, not current template
  status.
- No runtime field is trusted from the request body.
- Itembank owns the publication-usage table, service, idempotency constraint,
  and lock decision. Scoretemplate activation calls this public itembank
  service in the same transaction as the template status change. Itembank does
  not import scoretemplate repositories or events, and scoretemplate does not
  write usage rows directly.

- Preflight: catalog endpoints, role ownership, availability normalization,
  publication usage, uniqueness, and runtime-lock paths were reviewed.

## Quality and Testing State

Quality: approved; receipt: quality/phase-04-dynamic-catalog-api-ownership-and-locks-receipt.json
Testing: passed; report: tests/phase-04-dynamic-catalog-api-ownership-and-locks-test-report.json

Required tests:

- Key normalization and format boundary tests.
- Display-name normalization and duplicate tests.
- Concurrent duplicate create integration test proving one success and one 409.
- Create custom key with existing screen contract.
- Legacy standard code-only create/read compatibility.
- Unlocked screen edit before publication.
- Locked screen/section/runtime edit after ACTIVE and after RETIRED.
- Platform-role allow/deny matrix.
- Availability endpoint security and excludePublicId behavior.
- Friendly 409 payload does not render a raw implementation class.
- Concurrent publish/update race test proving one transaction wins and the
  runtime lock cannot be bypassed.
- Legacy /question-types projection never returns custom rows or custom keys
  through enum-valued fields; canonical /task-types returns them explicitly.

Mandatory gate:

    /ck:quality --gate D:\GitHub\pte-org\pte-doc\projects\plans\quang-dynamic-task-type-screen-contract\phase-04-dynamic-catalog-api-ownership-and-locks.md

## Acceptance criteria

- The canonical task-types API can create a new key not present in PteTaskType;
  the legacy question-types API rejects non-standard keys.
- Duplicate key/name warnings can be queried while typing and races are still
  rejected by the backend/database.
- New rows select only active allowlisted contracts.
- Runtime fields lock forever after any published/active template usage.
- Archive/retire does not unlock or permit key reuse.
- Standard endpoint clients continue to work.

## Verification commands

    .\mvnw.cmd -pl app -Dtest=QuestionTypeServiceTest,QuestionTypeControllerSecurityTest test
    .\mvnw.cmd -pl app -DskipTests compile
    git diff --check

Run focused API contract tests with a disposable Postgres and then the quality
gate.

## Risks and rollback

Risk: the publication check introduces a circular module dependency. Mitigate
with the itembank-owned usage service called by scoretemplate in one
transaction; do not add a scoretemplate repository dependency to itembank.

Risk: an edit and publish race at the database boundary. Mitigate with one
transaction boundary and an integration test that repeats the race.

Rollback: disable custom create/update through feature flag; keep standard rows,
new columns, usage records, and response adapters. Never unlock a published
task by deleting usage history.
