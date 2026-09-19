# Phase 2: Question Template CRUD, Section Mapping and Import Removal

Status: Complete
Admin role: `PLATFORM_ADMIN` for template mutations

## Template CRUD implemented

`ScoreTemplateAdminService` now supports the complete admin lifecycle needed by the UI:

- create an empty DRAFT at the next version in a code family;
- get/list templates;
- clone an existing version into a new DRAFT;
- replace a DRAFT name and full item list;
- delete a DRAFT;
- activate a valid DRAFT and retire the previous ACTIVE template.

ACTIVE and RETIRED templates remain immutable. The existing activation validation and single-ACTIVE transaction behavior remain in place.

The controller exposes:

```text
POST   /api/v1/score-templates
DELETE /api/v1/score-templates/{publicId}
```

alongside the existing list/detail/clone/replace/activate endpoints.

## Section-first template mapping

The vendor editor now loads active persisted Question Types through `useQuestionTypes(true)`.

### Add flow

1. Admin selects one Section: `SPEAKING`, `WRITING`, `READING` or `LISTENING`.
2. The task type dropdown is enabled and contains only active persisted catalog rows whose Section matches the selected Section.
3. Admin adds the selected type; the row is initialized with Section-derived scoring defaults.
4. The Section and task type are sent as part of the replacement payload.

### Existing row edit flow

Each editable item row has a Section dropdown. Changing Section selects the first available active Question Type in that Section, while the task type dropdown only displays types from the selected Section. Existing task values are retained in a compatibility option if the persisted catalog no longer contains them.

This makes the mapping fast while keeping the current catalog as the UI source of available task types.

## Import JSON removal

The following import path was removed after the UI-based workflow was established:

- frontend file picker and JSON parsing;
- `parseScoreTemplateExport` and `toScoreTemplateImportRequest`;
- Question Type import mutation and score-template import mutation;
- `ImportQuestionTypesFromScoreTemplateRequest`;
- `ImportScoreTemplateRequest`;
- `QuestionTypeImportException`;
- `/score-templates/import` and the old Question Type import endpoint.

`downloadScoreTemplateJson` and the `Export JSON` action remain available for read-only export. Removing import does not remove export.

## Files changed for this phase

### `pte-api`

- `app/src/main/java/com/pte/scoretemplate/dto/request/CreateScoreTemplateRequest.java`
- `app/src/main/java/com/pte/scoretemplate/internal/controller/ScoreTemplateController.java`
- `app/src/main/java/com/pte/scoretemplate/internal/service/ScoreTemplateAdminService.java`
- `app/src/main/java/com/pte/scoretemplate/internal/exception/ScoreTemplateNotDraftException.java`
- `app/src/main/java/com/pte/scoretemplate/dto/request/ReplaceScoreTemplateItemsRequest.java`
- `app/src/test/java/com/pte/scoretemplate/internal/service/ScoreTemplateAdminServiceTest.java`
- removed `app/src/main/java/com/pte/scoretemplate/dto/request/ImportScoreTemplateRequest.java`.

### `pte-web`

- `apps/vendor-web/features/scoretemplate/api.ts`
- `apps/vendor-web/features/scoretemplate/components/ScoreTemplateListView.tsx`
- `apps/vendor-web/features/scoretemplate/components/ScoreTemplateEditorView.tsx`
- `apps/vendor-web/features/scoretemplate/components/_ScoreTemplateItemTable.tsx`
- `apps/vendor-web/features/scoretemplate/constants.ts`
- `apps/vendor-web/features/scoretemplate/types.ts`
- `apps/vendor-web/features/scoretemplate/serialization.ts`
- `packages/api-client/src/requests/scoretemplate/index.ts`
- `packages/api-client/src/types/scoretemplate/index.ts`

## Database and onboarding notes

The existing `V37__question_type_catalog.sql` remains intentionally unseeded. It was not edited in this phase, avoiding a Flyway checksum change. The local catalog is expected to be populated by the administrator through `/admin/question-types`, then consumed by the template editor.

The score template's standard V5 data is not imported from JSON by the application anymore. The admin creates the required Question Type rows via the UI, creates a DRAFT template, and maps those rows through the Section-first editor.

## Acceptance state

- [x] Platform admin can create an empty DRAFT template.
- [x] Platform admin can edit DRAFT items and metadata.
- [x] Platform admin can delete only DRAFT templates.
- [x] ACTIVE/RETIRED lifecycle controls remain available.
- [x] Section-first task dropdown mapping is implemented.
- [x] Import JSON UI and contracts are removed.
- [x] Export JSON remains available.
