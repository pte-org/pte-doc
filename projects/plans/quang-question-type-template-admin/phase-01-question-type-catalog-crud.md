# Phase 1: Persisted Question Type Catalog and CRUD

Status: Complete
Owner: Platform Admin/Platform Author flow
Source of truth: `question_types` database table

## Implemented backend behavior

### Supported vocabulary

`QuestionTypeService.listSupported()` exposes all 23 values of `PteTaskType` through `SupportedQuestionTypeResponse`:

```text
code, section, scored
```

The frontend no longer owns a 23-item task-code constant. It requests the supported vocabulary from the backend when the create modal opens.

### Create

`CreateQuestionTypeRequest` accepts:

```text
code, displayName, shortName, section, displayOrder, active
```

The service:

- trims and uppercases the code;
- rejects unsupported task codes with `INVALID_QUESTION_TYPE`;
- parses the Section case-insensitively and rejects malformed or mismatched Section values with `INVALID_QUESTION_TYPE`;
- rejects an existing non-deleted code with `QUESTION_TYPE_CODE_ALREADY_USED`;
- restores a matching soft-deleted row instead of creating a duplicate;
- derives Section, scoring and authoring requirements from the canonical `PteTaskType` value;
- stores the admin-curated display name, short name, order and active state.

The canonical flags include audio, image, prompt text, options, correct answer, word count, single-correct-option and ordered-option behavior.

### Update

The stable code and Section mapping are not changed by the update request. Admin can update:

```text
displayName, shortName, displayOrder, active,
requiresAudioPrompt, requiresImagePrompt, requiresPromptText,
requiresOptions, requiresCorrectAnswer, requiresWordCount,
requiresSingleCorrectOption, usesOptionOrderAsCorrectPosition
```

This keeps stable integration keys while allowing authoring metadata to be curated from the Question Types screen.

### Delete and runtime compatibility

Delete is implemented as a soft delete. New authoring operations use `findByCodeAndDeletedFalse`, while runtime definition lookup uses `findByCode`, including deleted rows. This prevents deleting a catalog row from breaking validation or delivery behavior for existing questions.

### Security and errors

`QuestionTypeController` is protected at class level with:

```java
@PreAuthorize("hasAnyRole('PLATFORM_ADMIN','PLATFORM_AUTHOR')")
```

Added domain errors:

- `InvalidQuestionTypeException` → HTTP 400 / `INVALID_QUESTION_TYPE`.
- `QuestionTypeCodeAlreadyUsedException` → HTTP 409 / `QUESTION_TYPE_CODE_ALREADY_USED`.

## Implemented frontend behavior

### API client and React Query

Added or updated:

- `packages/api-client/src/types/questiontype/index.ts`
- `packages/api-client/src/requests/questiontype/index.ts`
- `apps/vendor-web/features/questiontemplate/api.ts`

The query layer now supports persisted list, supported vocabulary, create, update and delete mutations. Mutations invalidate the persisted Question Type list.

### Question Types screen

The screen formerly used for Question Type administration now provides:

- `+ Create question type` header action;
- table columns for order, task type, Section, requirements, scored state and active state;
- row-level `Edit` and `Delete` actions;
- loading, API error, success message and delete confirmation states;
- soft-deleted rows disappearing from the non-deleted catalog list.

The editor was split into focused files to keep the frontend component-size convention:

- `QuestionTypeEditorModal.tsx`
- `_QuestionTypeEditorFields.tsx`
- `_QuestionTypeRequirements.tsx`

The create form includes a required Section select. Selecting a standard task auto-fills the display name, short name and canonical Section. On edit, the stable task code and Section are protected from accidental remapping.

## Files changed for this phase

### `pte-api`

- `app/src/main/java/com/pte/itembank/QuestionTypeService.java`
- `app/src/main/java/com/pte/itembank/internal/controller/QuestionTypeController.java`
- `app/src/main/java/com/pte/itembank/internal/repository/QuestionTypeRepository.java`
- `app/src/main/java/com/pte/itembank/dto/request/CreateQuestionTypeRequest.java`
- `app/src/main/java/com/pte/itembank/dto/response/SupportedQuestionTypeResponse.java`
- `app/src/main/java/com/pte/itembank/internal/exception/InvalidQuestionTypeException.java`
- `app/src/main/java/com/pte/itembank/internal/exception/QuestionTypeCodeAlreadyUsedException.java`
- `app/src/test/java/com/pte/itembank/QuestionTypeServiceTest.java`
- removed `ImportQuestionTypesFromScoreTemplateRequest.java` and `QuestionTypeImportException.java`.

### `pte-web`

- `apps/vendor-web/features/questiontemplate/api.ts`
- `apps/vendor-web/features/questiontemplate/constants.ts`
- `apps/vendor-web/features/questiontemplate/components/QuestionTemplateView.tsx`
- `apps/vendor-web/features/questiontemplate/components/QuestionTypeEditorModal.tsx`
- `apps/vendor-web/features/questiontemplate/components/_QuestionTypeEditorFields.tsx`
- `apps/vendor-web/features/questiontemplate/components/_QuestionTypeRequirements.tsx`
- `packages/api-client/src/requests/questiontype/index.ts`
- `packages/api-client/src/types/questiontype/index.ts`
- `apps/vendor-web/lib/navigation.tsx` for Content navigation ordering.

## Acceptance state

- [x] Section is present in the create form.
- [x] Create/Edit/Delete controls are visible in the Question Types screen.
- [x] Task-code vocabulary comes from the backend, not a frontend 23-item list.
- [x] New Question Type rows are persisted through the normal UI mutation.
- [x] Existing question runtime metadata remains readable after soft delete.
- [x] Targeted service and controller-security tests pass.
