# Phase 1: MC Reading Single Authoring

## Requirements

Build the first complete Host vertical slice: list questions accessible to the
authenticated Host and create one tenant-private `MC_READING_SINGLE` question
with task-specific validation and exactly one correct option.

Maps to: **P1 Stories #2–3 (question authoring and visibility) | FR-05, FR-06,
FR-17, FR-18**

## Design Constraints

- Use an `authoring` feature with separate `data`, `domain`, and
  `presentation` layers plus `authoring_module.dart`.
- Domain code imports no Flutter, Dio, GetIt, or JSON package.
- Backend DTO and wire names stay in data/domain boundaries; widgets and BLoCs
  consume domain types.
- `AuthoringRepository` exposes only
  `Future<List<Question>> loadQuestions()` and
  `Future<Question> createMcReadingSingle(CreateMcReadingSingleInput input)` in
  this phase.
- List and create flows use separate BLoCs. Neither BLoC contains
  `BuildContext`, navigation, mutable form controllers, or direct `ApiClient`
  calls.
- Host create requests always send `pteTaskType: MC_READING_SINGLE` and
  `visibility: PRIVATE`; the UI does not offer Host users a SHARED write toggle.
- A valid input has trimmed nonblank title/prompt, at least two trimmed nonblank
  options, unique contiguous `orderIndex` values starting at zero, and exactly
  one correct option.
- Unknown task-type/visibility values fail fast during DTO parsing instead of
  silently defaulting.
- The list reflects the authoritative POST/GET response. Creation success
  returns the created domain entity and reloads the list; no optimistic fake
  entity is inserted.
- Phase 1 consumes existing authoring endpoints and must not modify backend
  source.

## Steps

1. Define immutable `PteTaskType`, `QuestionVisibility`, `Question`,
   `QuestionOption`, `QuestionOptionInput`, and
   `CreateMcReadingSingleInput` domain types; unit-test all input invariants.
2. Define `AuthoringRepository`, `LoadQuestions`, and
   `CreateMcReadingSingle` use cases. The create use case rejects invalid input
   before delegating.
3. Implement `QuestionModel.fromJson`/`toEntity` for the complete Phase-1
   response shape, including public IDs, section, visibility, tenant, status,
   options, and skills; test shared/private and unknown enum cases.
4. Implement `AuthoringRepositoryImpl` using
   `GET /api/authoring/questions` and `POST /api/authoring/questions`; capture
   request JSON in tests and assert exact task type, visibility, trimmed text,
   correct flags, and order indexes.
5. Implement `QuestionListBloc` with sealed request/retry events and explicit
   initial, loading, empty, loaded, and failure states; test each transition.
6. Implement `CreateQuestionBloc` with idle, submitting, invalid, success, and
   failure states; test invalid input never calls the use case and valid input
   emits exactly one submission cycle.
7. Register repository, use cases, and factory BLoCs in
   `authoring_module.dart`; add a GetIt test proving BLoCs are fresh instances
   while repository/use cases are lazy singletons.
8. Add all question-list/create labels and validation messages to `AppStrings`.
9. Build `QuestionListPage` and `QuestionCard` for loading, empty, retryable
   failure, and lazily-rendered success states. Cards render title, task type,
   visibility, and status from the domain entity.
10. Build `CreateMcReadingSinglePage` with dynamic option editors, a single
    radio-group correct selection, add/remove option behavior, normalized input,
    loading-disabled submit, preserved form values on failure, and complete
    controller disposal.
11. On create success, pop with the backend-created `Question`; on return to the
    list, dispatch one reload. Add the page to the Host shell without changing
    the authenticated non-Host branch.
12. Run authoring domain/data/BLoC/widget tests, Phase 0 regression tests,
    `flutter analyze`, and the full Flutter suite; inspect new files for size,
    hardcoded copy/colors, and direct Dio imports.

## Success Criteria

- [x] Question list renders loading, empty, failure/retry, and loaded states.
- [x] Accessible SHARED and tenant PRIVATE records parse without exposing a
      tenant-selection control.
- [x] A valid `MC_READING_SINGLE` request sends `PRIVATE`, at least two options,
      contiguous indexes, and exactly one correct option.
- [x] Blank title/prompt/options, fewer than two options, and missing correct
      choice are rejected before an API request.
- [x] Create submission is disabled while in flight and not sent twice.
- [x] Successful creation returns the backend-created entity and refreshes the
      authoritative list.
- [x] List and create use separate BLoCs and all dependencies resolve through
      the authoring GetIt module.
- [x] All new authoring unit/BLoC/widget tests, Phase 0 regressions,
      `flutter analyze`, and full `flutter test` pass.

## Quality and Testing State

- Quality gate: approved after independent review and re-review; all findings
  are resolved. Report and receipt are stored under
  `pte-app/plans/hung-host-mini-console/quality/`.
- Testing: passed (`flutter analyze`, 98 focused Phase 0–1 tests, and 241
  full-suite tests). Runtime gateway verification remains explicitly pending
  and is recorded under `pte-app/plans/hung-host-mini-console/tests/`.

## Risks

- **MEDIUM:** The backend currently accepts one or more correct options for a
  generic option task, while this task requires exactly one. Mitigation: enforce
  exactly one in the domain input and UI; retain backend validation as a second
  boundary.
- **MEDIUM:** The existing list contract is non-pageable and may contain task
  types whose full detail is introduced only in Phase 2. Mitigation: model the
  shared list fields and all three known task-type enum values now, but do not
  add Phase-2 create behavior.
- **MEDIUM:** Dynamic option controllers can leak or shift the selected answer
  when an earlier option is removed. Mitigation: dedicated widget tests cover
  removal before/at/after the selected index and verify every controller is
  disposed.
- **LOW:** Reload-after-create costs one extra GET. Mitigation: prefer
  authoritative consistency for Milestone 1; optimize only if measured.
