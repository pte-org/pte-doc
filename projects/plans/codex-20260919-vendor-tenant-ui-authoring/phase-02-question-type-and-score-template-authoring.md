# Phase 2: Question-type and score-template authoring

## Question-type catalog

The old UI flow that imported question types from an exported score-template
JSON was replaced with a direct catalog workflow.

### Backend

- Added `GET /api/v1/question-types/supported` for server-owned PTE task
  vocabulary.
- Added create and delete operations alongside list/get/update.
- Creation normalizes the stable task code and derives canonical section,
  scoring, and authoring requirements from `PteTaskType`.
- Invalid task codes/sections are rejected by the backend.
- Delete is a soft delete: existing questions keep their stable code while the
  type is unavailable for new authoring.
- Added request/response DTOs and domain exceptions for invalid and duplicate
  codes.
- Added migration `V37__question_type_catalog.sql` and the foreign-key
  alignment for question rows.

### Frontend

- Added a `Create question type` action.
- Added an editor modal with standard task selection, section, display labels,
  ordering, active state, and editable authoring requirements.
- Added edit and delete actions with success/error feedback.
- Moved all question-type API calls into React Query hooks and the shared API
  client.

## Score-template workflow

- Replaced JSON-import-as-draft with `Create template`, which creates an empty
  editable `DRAFT`.
- The editor adds available active question types by section, prevents duplicate
  task types, supports remove/resequence, saves the full item list, and allows
  activation after validation.
- Existing active/retired templates remain immutable; only drafts can be
  deleted.
- Clone-to-draft remains available for non-draft templates.
- JSON export remains available for a template, but JSON import is no longer
  the authoring path.
- Backend and API-client request types were renamed from import semantics to
  create semantics, and empty draft item lists are accepted.

## Main files

### Backend

- `pte-api/app/src/main/java/com/pte/itembank/QuestionTypeService.java`
- `pte-api/app/src/main/java/com/pte/itembank/internal/controller/QuestionTypeController.java`
- `pte-api/app/src/main/resources/db/migration/V37__question_type_catalog.sql`
- `pte-api/app/src/main/java/com/pte/scoretemplate/internal/controller/ScoreTemplateController.java`
- `pte-api/app/src/main/java/com/pte/scoretemplate/internal/service/ScoreTemplateAdminService.java`

### Frontend

- `pte-web/apps/vendor-web/features/questiontemplate/`
- `pte-web/apps/vendor-web/features/scoretemplate/`
- `pte-web/packages/api-client/src/requests/questiontype/`
- `pte-web/packages/api-client/src/requests/scoretemplate/`
- `pte-web/packages/api-client/src/types/questiontype/`
- `pte-web/packages/api-client/src/types/scoretemplate/`
