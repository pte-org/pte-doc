# Phase 2: Read Aloud, Essay & Media

## Requirements

Extend authoring from the Phase-1 MCQ slice to the remaining Milestone-1 task
types: upload authoring media through the existing presigned-object contract,
create `READ_ALOUD` with an audio prompt reference, and create `WRITE_ESSAY`
with prompt/reference answer and word-count bounds.

Maps to: **P1 Story #2 (all three question types) | FR-07, FR-08, FR-17,
FR-18**

## Design Constraints

- Reuse the shared `MediaRepository`, `MediaPresignResponse`, and
  `RawUploadClient`; do not reuse the exam-attempt `MediaUploadCoordinator`
  because its Drift rows, retry state, and callback semantics are tied to
  student answer submission.
- Presign and complete calls use authenticated `ApiClient`; the direct
  presigned PUT uses the unintercepted `RawUploadClient` and carries no bearer
  token.
- The selected/recorded authoring file is uploaded and completed before the
  question create request is sent. A failed upload never creates a question
  with a dangling media reference.
- Expired/invalid presigned URLs receive one fresh presign and one retry, using
  the current core raw-upload exception semantics; unlimited retries are
  forbidden.
- `READ_ALOUD` requires a completed `audioPromptRef` and prompt text as required
  by the backend task mapping. Raw audio bytes never enter authoring-service.
- `WRITE_ESSAY` requires nonblank title, prompt, and reference answer plus
  positive `minWordCount <= maxWordCount`.
- Keep separate create events/states or form coordinators per task type; do not
  turn the Phase-1 create BLoC into a boolean-flag god state.
- Windows is the primary platform; file/audio selection must be smoke-checked
  on Windows before the phase is marked complete.

## Steps

1. Re-check the media presign/complete DTO and authoring task validation against
   current `pte-api/main`; record accepted content types and required
   READ_ALOUD/WRITE_ESSAY fields.
2. Add immutable `CreateReadAloudInput` and `CreateWriteEssayInput` domain types
   with task-specific invariant tests.
3. Extend `AuthoringRepository` with explicit `createReadAloud` and
   `createWriteEssay` commands; do not introduce a generic dynamic question
   map at the domain boundary.
4. Add a focused `AuthoringMediaUploader` that composes `MediaRepository` and
   `RawUploadClient`: presign, PUT file, complete, return `mediaPublicId`,
   one-time re-presign on stale URL.
5. Unit-test successful upload, PUT failure, complete failure, expired URL
   re-presign, second failure terminal behavior, and absence of Authorization on
   raw PUT.
6. Extend the data repository request encoder and response model coverage for
   audio/reference-answer/word-count fields while retaining Phase-1 enum and
   visibility behavior.
7. Implement separate READ_ALOUD and WRITE_ESSAY create BLoC flows with
   invalid/submitting/success/failure states and duplicate-submit protection.
8. Build a READ_ALOUD form with title, prompt, file/recording selection,
   upload-progress state, replace/remove media, and preserved input on failure.
9. Build a WRITE_ESSAY form with title, prompt, reference answer, minimum and
   maximum word-count fields, numeric/bounds validation, and preserved input on
   failure.
10. Add task-type selection/navigation from the authoring page without exposing
    unsupported backend task types.
11. Add widget tests for validation, media progress/retry, form preservation,
    successful navigation result, and authoritative list refresh.
12. Run Phase 0–1 regression suites, all Phase-2 tests, `flutter analyze`, full
    `flutter test`, and a bounded Windows media smoke check.

## Success Criteria

- [ ] READ_ALOUD media follows presign → raw PUT → complete and sends only the
      returned media public ID to authoring-service.
- [ ] Raw PUT contains no application bearer header and one expired URL triggers
      exactly one re-presign attempt.
- [ ] A failed upload/complete creates no question and preserves form state.
- [ ] Valid READ_ALOUD and WRITE_ESSAY payloads match current backend DTO fields.
- [ ] Invalid/missing audio, prompt, reference answer, or word-count bounds are
      rejected before question creation.
- [ ] All three supported task types can now be selected and successfully
      round-trip through the authoring feature.
- [ ] Phase 0–1 regressions, Phase-2 tests, analysis, and full Flutter suite
      pass; Windows media verification is recorded.

## Quality and Testing State

- Quality gate: not run. Planned report:
  `quality/phase-02-reading-aloud-essay-media-quality-report.json`.
- Testing: not run. Planned evidence:
  `tests/phase-02-reading-aloud-essay-media-test-report.json`, including unit,
  BLoC, widget, full-suite, analysis, and Windows smoke-check results.

## Risks

- **HIGH:** Reusing the student `MediaUploadCoordinator` would couple authoring
  to attempt IDs and answer outbox semantics. Mitigation: reuse only its generic
  network primitives and implement a focused authoring uploader.
- **HIGH:** Direct PUT through intercepted Dio may leak the gateway bearer token
  to MinIO. Mitigation: enforce and test `RawUploadClient`.
- **MEDIUM:** A media object can complete successfully while question creation
  fails, leaving an unused object. Mitigation: surface retry with the completed
  media ID retained in form state; backend garbage collection is outside this
  phase.
- **LOW:** Desktop recording/file-picker support can differ by Windows setup.
  Mitigation: record the platform smoke result and allow file selection as the
  stable authoring path if live recording is unavailable.
