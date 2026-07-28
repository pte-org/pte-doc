# Phase 2: Read Aloud & Write Essay

## Requirements

Extend the Phase-1 question bank with the remaining Milestone-1 task types:
text-prompt `READ_ALOUD` and `WRITE_ESSAY` with reference answer and word-count
bounds.

Maps to: **P1 Story #2 (all three question types) | FR-07, FR-08**

## Backend Contract Decision

The implementation was re-checked against `pte-api/main` before coding:

- `PteTaskType.READ_ALOUD` requires `promptText`; it does not require
  `audioPromptRef`.
- Read Aloud audio is the student's recorded answer and belongs to the existing
  exam-attempt media flow. It is not Host-authored prompt media.
- `WRITE_ESSAY` requires prompt and word-count bounds in backend validation.
  The Host form additionally requires a reference answer because it is part of
  the Milestone-1 authoring requirement and is supported by the DTO.
- Both create commands use `POST /api/authoring/questions` with `PRIVATE`
  visibility. No backend change is required.

This replaces the earlier authoring-media assumption, which would have been
valid JSON but incorrect PTE behavior.

## Design Constraints

- Keep immutable task-specific domain inputs and explicit repository commands.
- Do not replace the repository boundary with a generic dynamic question map.
- Use separate BLoCs for READ_ALOUD and WRITE_ESSAY.
- Reject blank Read Aloud title/prompt before calling the repository.
- Reject blank Essay title/prompt/reference answer and non-positive or reversed
  word-count bounds before calling the repository.
- Preserve all form values on API failure and reject duplicate submissions.
- Expose only the three Milestone-1 task types in the type picker.
- Successful creation returns the backend entity and triggers one authoritative
  question-list reload.

## Implemented Steps

1. Re-checked `CreateQuestionRequest`, `QuestionValidationHelper`, and
   `PteTaskType` against current backend source.
2. Added `CreateReadAloudInput` and `CreateWriteEssayInput` invariants.
3. Added explicit repository commands and use cases for both task types.
4. Added exact request encoders for READ_ALOUD and WRITE_ESSAY.
5. Added separate create BLoCs with invalid/submitting/success/failure states
   and in-flight guards.
6. Added task-specific forms with controller disposal, validation, loading,
   failure preservation, and success navigation.
7. Added a three-type picker from the question bank and registered all new
   dependencies with GetIt.
8. Added domain, repository, BLoC, DI, navigation, and widget regression tests.

## Success Criteria

- [x] READ_ALOUD sends only title, text prompt, task type, and PRIVATE
      visibility required by the current backend contract.
- [x] WRITE_ESSAY sends title, prompt, reference answer, and valid word-count
      bounds using current backend DTO field names.
- [x] Invalid task-specific input is rejected before repository delegation.
- [x] Duplicate submissions are ignored while a request is active.
- [x] API failure preserves user-entered form state.
- [x] All three supported task types are available from the question bank.
- [x] Phase 0–1 regressions, Phase-2 tests, analysis, and the full Flutter suite
      pass.

## Quality and Testing State

- Quality gate: approved. Report:
  `quality/phase-02-read-aloud-and-write-essay-quality-report.json`.
- Testing: passed. Evidence:
  `tests/phase-02-read-aloud-and-write-essay-test-report.json`.
- Runtime gateway round-trip: not run because the full local microservice stack
  was not active; exact DTO/repository contract tests cover the deterministic
  boundary.

## Risks

- **MEDIUM:** Documentation or future clients may again confuse Read Aloud
  prompt content with student response audio. Mitigation: retain the explicit
  backend-contract decision above and keep media primitives out of Authoring.
- **MEDIUM:** Backend validation does not currently require a reference answer,
  while this form does. Mitigation: the stricter requirement is intentional for
  Milestone 1 and uses an existing DTO field without changing backend behavior.
- **LOW:** Word-count policy values remain Host-authored. Mitigation: validate
  positive ordered bounds locally and rely on backend persistence as authority.
