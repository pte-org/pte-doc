# Phase 6 — Template Policy, Composition, and Readiness Enforcement

## Goal

Allow score templates to contain either the complete standard PTE catalog or a
deliberately configured set of dynamic task types. Drafts may be incomplete;
submission/activation must provide a complete, actionable readiness report and
must record publication usage for locking.

## Dependencies

- Phase 3 runtime resolver.
- Phase 4 task catalog and publication-usage contract.
- Phase 5 question-bank task-key facade.
- Existing score-template approval lifecycle and single-active behavior.

## Exact files/modules likely affected

- pte-api/app/src/main/java/com/pte/scoretemplate/domain/ScoreTemplate.java
- pte-api/app/src/main/java/com/pte/scoretemplate/domain/ScoreTemplateItem.java
- new pte-api/app/src/main/java/com/pte/scoretemplate/domain/enums/TemplatePolicy.java
- pte-api/app/src/main/java/com/pte/scoretemplate/dto/request/CreateScoreTemplateRequest.java
- pte-api/app/src/main/java/com/pte/scoretemplate/dto/request/ScoreTemplateItemRequest.java
- pte-api/app/src/main/java/com/pte/scoretemplate/dto/request/ReplaceScoreTemplateItemsRequest.java
- pte-api/app/src/main/java/com/pte/scoretemplate/dto/response/ScoreTemplateResponse.java
- pte-api/app/src/main/java/com/pte/scoretemplate/dto/response/ScoreTemplateItemResponse.java
- pte-api/app/src/main/java/com/pte/scoretemplate/internal/service/ScoreTemplateAdminService.java
- pte-api/app/src/main/java/com/pte/scoretemplate/internal/service/ScoreTemplateActivationValidator.java
- pte-api/app/src/main/java/com/pte/scoretemplate/internal/mapper/ScoreTemplateMapper.java
- pte-api/app/src/main/java/com/pte/scoretemplate/internal/constant/ScoreTemplateConstants.java
- pte-api/app/src/main/java/com/pte/scoretemplate/ScoreTemplateService.java
- pte-api/app/src/test/java/com/pte/scoretemplate/internal/service/ScoreTemplateActivationValidatorTest.java
- pte-api/app/src/test/java/com/pte/scoretemplate/ScoreTemplateServiceTest.java
- pte-web/apps/vendor-web/features/scoretemplate/types.ts
- pte-web/apps/vendor-web/features/scoretemplate/serialization.ts
- pte-web/apps/vendor-web/features/scoretemplate/taskTypeReadiness.ts
- pte-web/apps/vendor-web/features/scoretemplate/components/ScoreTemplateEditorView.tsx
- pte-web/apps/vendor-web/features/scoretemplate/components/ActivateTemplateModal.tsx
- pte-web/packages/api-client/src/types/scoretemplate/index.ts
- pte-web/packages/api-client/src/requests/scoretemplate/index.ts

## Implementation steps

1. Add templatePolicy to create, edit, list, and response contracts. Existing
   templates default to STANDARD_PTE.
2. Split activation validation:
   STANDARD_PTE runs the existing exact 22-scored-task requirement, duplicate
   checks, counts, sequence, weights, and section checks.
   CUSTOM validates selected task keys, contract readiness, section matching,
   duplicate keys, count/weight rules, and question-bank feasibility without
   requiring all standard tasks. Shared structural rules remain common to both
   policies. Scored status and scoring behavior are derived from the runtime
   contract: scored items require an active scoring profile; unscored items
   must have zero weight; mixed scored/unscored custom templates are allowed;
   a score-producing template must contain at least one scored item.
3. Resolve task definitions and runtime contracts in one batch through the
   public itembank facade.
4. Permit DRAFT save with missing/inactive runtime readiness. Store a
   readiness report on the response or derive it on demand.
5. Block submit and activation with all issues, not just the first:
   missing task key, inactive task, missing screen contract, unsupported
   contract version, section mismatch, insufficient question bank, and
   standard-task omissions.
6. At activation, call the public itembank publication-usage service to create
   append-only usage rows for every task type in the published version in the
   same transaction as the status change. Itembank owns the table and its
   unique (taskTypeKey, templateVersion) idempotency constraint; scoretemplate
   never writes the usage table directly.
7. Retain existing Platform Author/Platform Admin approval behavior. Do not add
   a second submission state.
8. Pin the resolved contract into the template item at publish time; do not
   allow later catalog edits to mutate an active template.
9. Expose readiness and policy in vendor-web API responses.

## API/DB contract

Score template request additions:

    templatePolicy: STANDARD_PTE | CUSTOM
    items[].taskTypeKey
    items[].runtime is server-resolved; client-supplied contract/scoring values
    are ignored for authority

Readiness response:

    ready
    policy
    issues[]:
      code
      taskTypeKey
      field
      message
      remediation

Examples:

- CUSTOM + READ_ALOUD_PLUS with active READ_ALOUD_V1 is ready.
- CUSTOM + retired screen contract returns TEMPLATE_RUNTIME_NOT_READY.
- CUSTOM may mix scored and unscored tasks; unscored tasks have zero weight and
  use the allowlisted scoring profile NONE/V1, while scored tasks use only the
  contract's active scoring profile. Define scoringMode as SCORED or NONE;
  NONE always means scoringProfileKey=NONE and version=1. Every weight is a
  decimal from 0.00 through 100.00 with at most two decimal places. For each
  skill column that has at least one positive scored weight, the scored-item
  total must equal exactly 100.00; a skill column with no positive scored
  weight must total 0.00. Overall weights must be non-negative and have a
  positive total for a score-producing template, but do not need to sum to a
  fixed value. An all-unscored CUSTOM template returns
  TEMPLATE_NO_SCORED_TASKS.
- STANDARD_PTE missing one of the 22 scored types returns
  TEMPLATE_STANDARD_TASK_TYPES_MISSING.

## Error UX

Show a summary such as:

“This template is saved as a draft, but it cannot be activated yet.”

Then list each task and fix:

“Read Aloud Plus — screen Read Aloud V1 is not supported by the current
platform contract. Select an active screen or wait for the platform release.”

Never render a joined Java exception string or raw enum parsing error.

## Security and ownership

- Platform Author can create/edit/submit drafts.
- Platform Admin can approve, return, activate, and retire.
- Tenant/host cannot change policy or item contracts.
- Activation uses the platform catalog and does not reveal question content
  beyond existing readiness/feasibility permissions.
- Usage records include actor and template version for audit.

## Design Constraints

- Do not weaken the existing STANDARD_PTE validator.
- Do not activate a template merely because the screen key is syntactically
  valid; it must resolve to an allowlisted active contract.
- Do not silently omit custom tasks from generation.
- Preserve single-active template and immutable published-version behavior.
- Cross-module calls use ScoreTemplateService and itembank public facades.

- Preflight: STANDARD_PTE invariants, CUSTOM policy, readiness diagnostics,
  question-bank feasibility, activation flags, and publication locking were
  reviewed.

## Quality and Testing State

Quality: approved; receipt: quality/phase-06-template-policy-readiness-and-activation-receipt.json
Testing: passed; report: tests/phase-06-template-policy-readiness-and-activation-test-report.json

Required tests:

- Existing standard template activation remains green with exactly 22 scored
  task types.
- CUSTOM template with one or more dynamic task keys activates.
- Draft save succeeds with missing readiness; submit/activation fails.
- All readiness issues are returned together.
- Duplicate custom task key, section mismatch, inactive contract, and
  insufficient question-bank tests.
- Publication usage is written transactionally and survives template RETIRED.
- CUSTOM scored/unscored weight and at-least-one-scored policy tests.
- NONE/V1 unscored profile and zero-weight serialization tests.
- Custom per-skill weight aggregation tests: represented skills total 100.00,
  unrepresented skills total 0.00, overall weight has no fixed-total rule, and
  precision/range violations are rejected.
- Concurrent publish/update test proving usage is idempotent and runtime locks
  cannot be bypassed.
- Platform role matrix and old template DTO compatibility tests.
- Vendor-web serialization/readiness unit tests.

Mandatory gate:

    /ck:quality --gate D:\GitHub\pte-org\pte-doc\projects\plans\quang-dynamic-task-type-screen-contract\phase-06-template-policy-readiness-and-activation.md

## Acceptance criteria

- Existing standard templates behave exactly as before.
- Custom templates do not require the 22 standard tasks.
- Draft readiness is visible and non-blocking; activation is strict and
  actionable.
- Every first publication records usage that later locks runtime fields.
- No unsupported task is dropped from a template.

## Verification commands

    .\mvnw.cmd -pl app -Dtest=ScoreTemplateActivationValidatorTest,ScoreTemplateServiceTest test
    .\mvnw.cmd -pl app -DskipTests compile
    pnpm --filter vendor-web lint
    pnpm --filter vendor-web build
    git diff --check

Run focused API tests and the mandatory quality gate.

## Risks and rollback

Risk: custom policy accidentally bypasses score/weight validation. Keep
structural checks shared and policy-specific checks explicit.

Risk: publication usage is written after status change. Use one transaction
with a rollback test and a retry-safe unique constraint.

Rollback: feature-flag CUSTOM policy while retaining STANDARD_PTE enforcement
and all additive template fields.
