# Phase 5 — Question-Bank Logical Task Identity

## Goal

Make taskTypeKey the authoritative logical identity for question authoring,
validation, filtering, counting, random selection, freezing, and downstream
module views while preserving the enum field for standard compatibility.

## Dependencies

- Phase 2 questions.task_type_key migration.
- Phase 3 dynamic runtime resolver.
- Phase 4 catalog create/read/update contract.
- Existing question approval, revision, tenant, and visibility rules.

## Exact files/modules likely affected

- pte-api/app/src/main/java/com/pte/itembank/domain/Question.java
- pte-api/app/src/main/java/com/pte/itembank/ItembankService.java
- pte-api/app/src/main/java/com/pte/itembank/internal/service/QuestionValidationHelper.java
- pte-api/app/src/main/java/com/pte/itembank/internal/repository/QuestionRepository.java
- pte-api/app/src/main/java/com/pte/itembank/internal/repository/TaskTypeCountProjection.java
- pte-api/app/src/main/java/com/pte/itembank/internal/controller/QuestionController.java
- pte-api/app/src/main/java/com/pte/itembank/dto/request/CreateQuestionRequest.java
- pte-api/app/src/main/java/com/pte/itembank/dto/response/QuestionResponse.java
- pte-api/app/src/main/java/com/pte/itembank/dto/response/QuestionFreezeView.java
- pte-api/app/src/main/java/com/pte/itembank/internal/mapper/QuestionMapper.java
- pte-api/app/src/main/java/com/pte/itembank/domain/enums/PteTaskType.java
- existing TaskTypeCodeCompatibility.java and itembank constants
- question-bank tests under pte-api/app/src/test/java/com/pte/itembank
- pte-web/apps/vendor-web/features/questionbank/api.ts
- pte-web/apps/vendor-web/features/questionbank/types.ts
- pte-web/apps/vendor-web/features/questionbank/components/QuestionEditorForm.tsx
- pte-web/apps/vendor-web/features/questionbank/constants.ts
- pte-web/packages/api-client/src/types/question/index.ts
- pte-web/packages/api-client/src/requests/question/index.ts

## Implementation steps

1. Add taskTypeKey to Question as the authoritative field. Keep pteTaskType
   nullable/legacy during transition and map standard rows through one adapter.
   This phase must update every enum dereference (QuestionFreezeView,
   BlueprintService, repository projections, generation inputs, and validation)
   so a custom row with pteTaskType = null is a supported state, not an
   exceptional path.
2. On create/update, resolve the task definition and runtime authoring
   requirements from the catalog contract. Do not accept requirement flags as
   an authority from the client.
3. Write both taskTypeKey and pteTaskType for standard tasks. For custom tasks,
   write taskTypeKey and leave the enum field null behind an explicit
   compatibility boundary.
4. Replace enum-only repository filters, counts, random selection, freeze
   views, and question validation with task-key queries.
5. Add indexed task-key filtering and preserve existing tenant/visibility/status
   constraints.
6. Extend QuestionFreezeView and all public module facades with taskTypeKey,
   runtime contract, section, scoring, and authoring metadata.
7. Keep old enum-only response fields for standard rows. For custom rows,
   return the additive taskTypeKey and a structured compatibility limitation
   instead of inventing an enum value.
8. Update vendor question authoring to load task definitions from the dynamic
   catalog and show the selected contract's requirements as read-only.

## API/DB contract

Create question requests accept taskTypeKey. A legacy pteTaskType/taskType
value is normalized only when it maps to a standard definition.

Question responses include:

    taskTypeKey
    legacy taskType or pteTaskType when standard
    section
    runtime contract
    authoring requirements

Question-bank counts and random-selection APIs use taskTypeKey internally and
return the same stable key in projections. A custom task must be eligible for
question authoring only when its task definition is active and its selected
contract is active.

Legacy consumer projection is explicit:

| Consumer | Standard task | Custom task |
|---|---|---|
| `/api/v1/question-types` legacy client | Existing enum-safe fields | Filtered from legacy projection or stable compatibility error |
| `/api/v1/task-types` canonical client | taskTypeKey plus compatibility alias | taskTypeKey plus full contract |
| Vendor question bank | Full taskTypeKey contract | Full taskTypeKey contract |
| pte-app legacy snapshot | Existing standard alias | Terminal unsupported/upgrade state, never fabricated enum |
| New snapshot/attempt DTO | Pinned taskTypeKey and runtime contract | Pinned taskTypeKey and runtime contract |
| Reporting/export | Standard legacy mapping | Explicit custom key or documented unsupported export, never guessed |

## Error UX

Use friendly messages:

- “Select an active task type from the platform catalog.”
- “This task type is not available for new questions.”
- “This question uses a custom task type. Refresh the question-bank contract
  before editing it.”
- “The selected task type requires audio/image/options that are missing.”

Legacy clients that cannot represent a custom key receive a stable
compatibility error, not a Java enum exception or raw stack trace.

## Security and ownership

- Questions remain platform-owned as in the current item-bank policy.
- Task catalog writes remain platform-role-only.
- Tenant/host question reads continue through existing visibility/authorization
  checks.
- Runtime metadata must not reveal answer keys or future exam content.

## Design Constraints

- Do not create a second question table.
- Do not duplicate task-specific validation in every controller.
- Do not remove pteTaskType until all standard compatibility consumers are
  proven migrated.
- Do not let custom task keys bypass question status, revision, or approval
  invariants.
- Use the public item-bank facade for assessment and scoretemplate consumers.

## Quality and Testing State

Quality: not evaluated.
Testing: not started.

Required tests:

- Standard dual-write and legacy-read tests.
- Custom task create, edit, list, count, random-selection, and freeze tests.
- Requirement resolution from the selected screen contract.
- Section mismatch, inactive task, retired task, and missing contract tests.
- Tenant/visibility/status regression tests.
- Legacy endpoint behavior for all 23 standard task values.
- TypeScript question-editor API/type tests.

Mandatory gate:

    /ck:quality --gate D:\GitHub\pte-org\pte-doc\projects\plans\quang-dynamic-task-type-screen-contract\phase-05-question-bank-logical-task-identity.md

## Acceptance criteria

- A new taskTypeKey can have questions authored without a new enum constant.
- Question filters, counts, random selection, and freeze use the logical key.
- Standard questions remain readable by old clients.
- Requirements cannot be weakened by editing request flags.
- No custom task is silently treated as another standard task.
- A custom question can be persisted and frozen with a non-null taskTypeKey and
  null legacy enum value without an ORM, query, or mapper null-dereference.

## Verification commands

    .\mvnw.cmd -pl app -Dtest=*Question* test
    .\mvnw.cmd -pl app -DskipTests compile
    pnpm --filter vendor-web lint
    pnpm --filter vendor-web build
    git diff --check

Run API fixtures for both standard and custom rows before the quality gate.

## Risks and rollback

Risk: a downstream module still dereferences nullable pteTaskType. Use
compile-time search plus custom fixture tests to identify every enum boundary;
keep the adapter until Phase 8 is complete.

Risk: random selection uses a legacy enum index and undercounts custom rows.
Add a query-count/count parity test and a task-key database index.

Rollback: feature-flag custom question authoring and continue serving standard
dual-written rows. Retain custom rows as inactive/read-only rather than
deleting them.
