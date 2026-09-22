# Phase 9 — Vendor-Web Authoring and Template Readiness UX

## Goal

Replace the misleading standard-only form with a real custom task-type form,
add debounced duplicate warnings, allowlist screen selection, show lock state,
and make template readiness/activation errors understandable to non-technical
users.

## Dependencies

- Phase 4 catalog API, availability, lock, and capability DTOs.
- Phase 6 template policy/readiness DTOs.
- Phase 8 snapshot/runtime fields for detail views.
- Existing common ActionMenu, Modal, constants, and friendly error patterns.

## Exact files/modules likely affected

API client:

- pte-web/packages/api-client/src/types/questiontype/index.ts
- pte-web/packages/api-client/src/requests/questiontype/index.ts
- pte-web/packages/api-client/src/types/scoretemplate/index.ts
- pte-web/packages/api-client/src/requests/scoretemplate/index.ts
- pte-web/packages/api-client/src/client/errorMessage.ts
- new API-client availability/capability request tests

Question/task catalog:

- pte-web/apps/vendor-web/features/questiontemplate/components/QuestionTypeEditorModal.tsx
- pte-web/apps/vendor-web/features/questiontemplate/components/_QuestionTypeEditorFields.tsx
- pte-web/apps/vendor-web/features/questiontemplate/components/QuestionTemplateView.tsx
- pte-web/apps/vendor-web/features/questiontemplate/api.ts
- pte-web/apps/vendor-web/features/questiontemplate/constants.ts
- pte-web/apps/vendor-web/features/questiontemplate/errorMessage.ts
- pte-web/apps/vendor-web/features/questiontemplate/components/_QuestionTypeRequirements.tsx

Template UX:

- pte-web/apps/vendor-web/features/scoretemplate/types.ts
- pte-web/apps/vendor-web/features/scoretemplate/serialization.ts
- pte-web/apps/vendor-web/features/scoretemplate/taskTypeReadiness.ts
- pte-web/apps/vendor-web/features/scoretemplate/components/ScoreTemplateEditorView.tsx
- pte-web/apps/vendor-web/features/scoretemplate/components/ActivateTemplateModal.tsx
- pte-web/apps/vendor-web/features/scoretemplate/components/_ScoreTemplateItemTable.tsx
- pte-web/apps/vendor-web/features/scoretemplate/constants.ts
- pte-web/apps/vendor-web/features/scoretemplate/errorMessage.ts

Tests:

- existing vendor-web API/client tests
- new component/form tests under the relevant features
- authenticated Playwright walkthrough fixture, with credentials supplied
  outside the repository

## Implementation steps

1. Rename visible terminology to Task type while keeping compatibility module
   names and endpoint functions.
2. Form fields:
   taskTypeKey free input, displayName, shortName, section, screenKey select,
   contract version, active state, and order. Runtime/scoring requirements
   render read-only from the selected capability.
3. Normalize taskTypeKey on blur/change and preserve a user-friendly visible
   value while showing the canonical uppercase form.
4. Debounce availability requests for key and displayName. Show field-level
   warnings as soon as a conflict is confirmed; keep submit disabled when
   confirmed unavailable.
5. Keep submit guarded by the backend response so a race displays the friendly
   409 message and refresh action.
6. On edit, display editability metadata. Disable taskTypeKey always; disable
   screen/section/runtime fields after published use and show the locked reason.
   Keep display metadata editable where the API permits it.
7. Remove the contradictory “all standard types already exist” and
   “standard types only” copy from the custom-create form. Replace it with a
   concise explanation that behavior/scoring comes from the selected platform
   screen contract.
8. Add template policy selection and render separate STANDARD_PTE/CUSTOM
   readiness states. Draft save should show warnings; activation modal should
   show actionable issue rows.
9. Map all API codes to centralized friendly constants. Never render raw
   PLAN_*, TASK_*, or runtime codes as the primary message.
10. Preserve common ActionMenu behavior for catalog row actions and modal
    backdrop/close semantics already fixed in the UI.

## API/DB contract

Client types mirror additive taskTypeKey, screenKey, contractVersion,
runtime, readiness, editability, templatePolicy, and issues fields. Legacy code
and taskType fields remain available for old consumers.

The form must not send behaviorKey, scoring formulas, renderer class names, or
authoring flags as a source of truth. It sends selected semantic contract
identity; the server returns derived values.

## Error UX

Centralize messages for:

- invalid key format;
- key/display-name availability;
- unavailable screen contract;
- locked runtime fields;
- draft readiness warnings;
- activation blockers;
- conflict/race retry.

Example UI:

“This task type is already used by a published template. The screen and
scoring behavior are locked. You can still update its display name.”

## Security and ownership

- Hide create/edit controls for tenant/host users according to existing route
  guards; do not rely only on disabled HTML controls.
- Do not show implementation classes or internal registry storage.
- Do not cache availability across accounts or leak conflict owner data.
- Preserve authenticated API client and unauthorized redirect behavior.

## Design Constraints

- Use existing UI primitives and constants patterns.
- Do not duplicate messages in TSX.
- Do not make the form infer readiness from the list of standard enum values.
- Use server response as the authority for lock/readiness.
- Keep the legacy API client functions as compatibility adapters.

## Quality and Testing State

Quality: not evaluated.
Testing: not started.

Required tests:

- API client request/response tests for new fields and availability query.
- Normalization and debounced availability tests.
- Duplicate key/name warnings and race 409 rendering tests.
- Create custom task with screen selection.
- Edit unlocked screen versus locked screen field behavior.
- Template STANDARD_PTE/CUSTOM readiness and activation issue rendering.
- Assertion that raw machine error codes are not rendered as the primary UI
  message.
- Keyboard, modal focus, validation, and responsive form tests.
- Authenticated walkthrough: create custom task, create draft custom template,
  observe readiness, activate after the contract is ready, edit label after
  publication, and verify runtime fields are disabled.

Mandatory gate:

    /ck:quality --gate D:\GitHub\pte-org\pte-doc\projects\plans\quang-dynamic-task-type-screen-contract\phase-09-vendor-web-authoring-and-readiness-ux.md

## Acceptance criteria

- The modal visibly creates a new task type rather than selecting an existing
  standard enum value.
- Key and display-name duplicates are warned during entry and rejected on race.
- Screen key is selected from the registry and requirements are read-only.
- Published-use lock warnings are clear and runtime fields are disabled.
- Draft readiness is understandable; activation blockers are actionable.
- Standard catalog/template screens remain compatible.

## Verification commands

    pnpm --filter vendor-web lint
    pnpm --filter vendor-web build
    pnpm exec prettier --check apps/vendor-web/features/questiontemplate packages/api-client/src/types/questiontype packages/api-client/src/requests/questiontype
    pnpm exec playwright test tests/authenticated/task-type-contract.spec.ts
    git diff --check

Use approved local authenticated credentials for the walkthrough; do not add
credentials to test files or logs. Run the quality gate after static and
browser checks.

## Risks and rollback

Risk: the browser shows a green availability result that is stale. Always
handle backend 409 and refetch catalog after conflict.

Risk: old components still assume supportedTypes is the create source. Keep
API aliases and update all callers before removing the old query.

Rollback: hide the custom-create control behind a feature flag and retain
standard catalog editing; keep friendly errors and lock display paths.
