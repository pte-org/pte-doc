# Phase 3: Tests + Final Regression

## Requirements
`RetellLectureScreen`'s instruction text, sub-stage timing, and recording lifecycle are covered by an automated widget test suite (mirroring `repeat_sentence_screen_test.dart`'s structure), `TaskTypeDispatcher`'s `RE_TELL_LECTURE` routing is covered, and the whole feature is verified regression-free against the existing suite.

## Steps
1. Create `test/widget/features/exam_attempt/retell_lecture_screen_test.dart`, copying `repeat_sentence_screen_test.dart`'s mock/setup shape verbatim: `_MockExamAttemptBloc`, `_MockAudioRecorderService`, `_MockPendingMediaUploadDao`, `_MockMediaUploadCoordinator`, `_MockSyncEngine`, the `_FakePathProviderPlatform`/`setUpAll` block (required because `AutoRecordCubit`'s default `resolveRecordingFilePath` calls `path_provider`), and a `_retellLectureTask({pinnedItemPublicId})` helper using `prepSeconds: 70, responseSeconds: 40`.
2. Test: the instruction text renders as the literal expected string with `10` and `40` interpolated — not `70` — asserting the exact wording from `plan.md`'s Research Summary item 4.
3. Test: at `elapsed = 0` (start of prep, i.e. `TimerSnapshot(phase: prep, remaining: Duration(seconds: 70))`), the Listening card shows `"Beginning in 3 seconds"`; the Record card is still blank.
4. Test: at `elapsed = 3` (`remaining: Duration(seconds: 67)`, i.e. the audio-playback sub-stage boundary), the Listening card shows `"Playing 57 seconds left"`. At `elapsed = 60` (`remaining: Duration(seconds: 10)`, i.e. the pre-record sub-stage boundary), the Listening card is frozen at `"Playing 0 seconds left"` and the Record card shows `"Beginning in 10 seconds"`.
5. Test: a response-phase snapshot (`remaining: Duration(seconds: 40)`) delivered via the bloc stream auto-starts recording (`recorder.start` called once) and the Record card shows `"Recording 40 seconds left"`, Listening card frozen at `"Playing 0 seconds left"`.
6. Test: the full prep → response → recorded transition stops the recorder once the response countdown reaches zero and swaps the Record card to the upload-status card; and a separate test confirms a snapshot for a mismatched `pinnedItemPublicId` is never forwarded (`recorder.start` never called) — the identity-guard regression case, matching the other two auto-record screens' existing coverage.
7. Add a `TaskTypeDispatcher — RE_TELL_LECTURE routing` group to `test/widget/features/exam_attempt/task_type_dispatcher_test.dart`, mirroring the existing `REPEAT_SENTENCE routing`/`DESCRIBE_IMAGE routing` groups (around lines ~256/~282): asserts a task with `taskType: 'RE_TELL_LECTURE'` routes to `RetellLectureScreen`, not the unsupported-task-type placeholder.
8. Run the full test suite, `flutter analyze`, and `.github/scripts/check-standards.sh` from a clean state; record the exact final pass count, any new `check-standards.sh` findings (fix if genuinely new/in-scope, note-only if pre-existing/unrelated), and confirm no orphaned files against phase-01/phase-02's file lists. Update `plan.md`'s Status and Session Notes with the real results.

## Success Criteria
- `retell_lecture_screen_test.dart` passes in full (all cases from Steps 2–6).
- `task_type_dispatcher_test.dart`'s new `RE_TELL_LECTURE routing` group passes.
- Full test suite: 0 failures; exact final count recorded in `plan.md`'s Session Notes.
- `flutter analyze`: clean, 0 issues.
- `.github/scripts/check-standards.sh`: executed, output reviewed, no new hardcoded-`Text()`-string or 300-line violations introduced by this feature's files.
- `grep -n "Text('" lib/features/exam_attempt/speaking_writing/presentation/pages/retell_lecture_screen.dart test/widget/features/exam_attempt/retell_lecture_screen_test.dart` — the `lib/` file returns no matches (test-file literals are fine, since test assertions legitimately embed expected strings).

## Risks
- Missing the identity-guard (`pinnedItemPublicId` mismatch) test case, silently reintroducing the previously-fixed cross-task recorder-misfire bug class: Mitigation — Step 6 states this as a required, individually-named test case, not optional.
- Test values for `elapsed = 60`/response phase drifting from the actual fixture's `prepSeconds: 70`/`responseSeconds: 40` if either is changed later without updating tests: Mitigation — Steps 3–5 spell out the exact `TimerSnapshot.remaining` values expected for each sub-stage boundary, self-checking against the fixture's documented derivation.
- Treating `check-standards.sh`'s warning-only exit code as "nothing to check": Mitigation — Step 8 explicitly requires reviewing its output, not just its exit code, mirroring the Describe Image plan's Phase 5 precedent.
