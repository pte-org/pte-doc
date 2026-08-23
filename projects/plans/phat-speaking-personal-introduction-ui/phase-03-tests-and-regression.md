# Phase 3: Tests + Full Regression Gate

## Requirements
`PersonalIntroductionScreen` and its dispatcher routing are covered by widget tests matching the codebase's existing patterns, and the full test/analyze/standards suite passes cleanly with no new findings.

## Steps
1. Measure the actual pre-Phase-1-state `flutter test` pass count fresh (do not reuse the prior session's reported 295 as ground truth) to establish this phase's regression baseline.
2. Create `test/widget/features/exam_attempt/personal_introduction_screen_test.dart`, porting `read_aloud_screen_test.dart`'s structure (mocks, `_FakePathProviderPlatform`, `stubBlocState` helper, `buildSubject`) adapted for `PersonalIntroductionScreen` and its single-card status layout.
3. Cover in the new screen test: instruction text renders with 25/30 interpolated correctly, prep-phase "Beginning in X seconds" countdown with no recording started, response-phase auto-start of recording plus "Recording X seconds left", full prep→response→recorded transition with the upload-status card swap, and the `pinnedItemPublicId` identity-guard regression case (recorder.start never called for a mismatched task's snapshot).
4. Add a `PERSONAL_INTRODUCTION routing` group to `task_type_dispatcher_test.dart`, mirroring the existing `REPEAT_SENTENCE`/`DESCRIBE_IMAGE` groups' shape and adding a matching `_personalIntroductionTask({required pinnedItemPublicId})` helper.
5. Run the full `flutter test` suite and confirm 100% pass with a total count consistent with the fresh baseline plus the newly added tests (no unexplained deltas).
6. Run `flutter analyze` across the whole project and confirm 0 issues.
7. Run `.github/scripts/check-standards.sh`, review its output line by line, and confirm no new findings — in particular no hardcoded `Text('literal')` and no file exceeding the project's line-count thresholds.
8. Update `plan.md`'s phase checkboxes and status once all gates pass.

## Success Criteria
- `flutter test` — 100% pass, full suite green, count matches fresh baseline + new tests added.
- `flutter analyze` — 0 issues.
- `.github/scripts/check-standards.sh` — no new findings.
- New tests fail if `PersonalIntroductionScreen` regresses to a manual-advance or audio-sub-stage shape (i.e., they assert on the auto-advance/single-card behavior, not just presence of text).

## Risks
- Hardcoding a stale expected test count instead of measuring fresh — mitigated by step 1's explicit fresh-baseline measurement.
- Copy-pasted `read_aloud_screen_test.dart` boilerplate drifting from `PersonalIntroductionScreen`'s actual field values (25/30 vs Read Aloud's fixture values) — mitigated by explicit review of every literal timer value before finalizing the test file.
