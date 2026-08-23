# Phase 3: New-screen tests, routing test, full regression gate

## Requirements
`RespondToASituationScreen`'s prep/response/recorded lifecycle and the situation-text display are covered by an independent widget test suite, `TaskTypeDispatcher` routes `RESPOND_TO_A_SITUATION` correctly, and the full existing test/analyze/standards suite passes with zero regressions.

## Steps
1. Create `test/widget/features/exam_attempt/respond_to_a_situation_screen_test.dart`, mirroring `answer_short_question_screen_test.dart`'s structure: the same 5 mock classes, `_FakePathProviderPlatform`, and a task-builder helper using `prepSeconds: 40, responseSeconds: 40` and the confirmed `promptText`.
2. Write the fixed-instruction-text and situation-text rendering assertions, then the full prep-phase sub-stage sequence using the pre-derived numbers (audioSeconds = 40 − 20 − 10 = 10): elapsed 0s → "Beginning in 20 seconds" / Record blank / `recorder.start` never called; elapsed 20s → "Playing 10 seconds left"; elapsed 29s → "Playing 1 seconds left"; elapsed 30s → "Playing 0 seconds left" (frozen) + "Beginning in 10 seconds"; elapsed 39s → "Beginning in 1 seconds" — verifying each derived number independently against the widget's actual output during implementation, not just copying the pre-derivation blindly.
3. Write the response-phase test (`recorder.start` called once, "Recording 40 seconds left", Listening frozen at "Playing 0 seconds left") and the full prep→response→recorded transition test (`recorder.stop` called once, upload-status card replaces the "Recording" text).
4. Write the `pinnedItemPublicId` mismatch identity-guard regression test (a snapshot for a different task is never forwarded — `recorder.start` never called), matching the equivalent test in `answer_short_question_screen_test.dart`.
5. Add a `RESPOND_TO_A_SITUATION routing` group to `task_type_dispatcher_test.dart`, mirroring the existing routing groups' shape (stub `mediaDao.watchRow`, use a distinct `pinnedItemPublicId` so the timer-bridge identity guard never matches, assert the placeholder text is absent and the confirmed instruction text renders).
6. Run the full `flutter test` suite and record the actual pass count as this session's fresh baseline (do not assume any prior session's count) — 100% pass required, zero regressions in previously-passing tests.
7. Run `flutter analyze` (0 issues) and `.github/scripts/check-standards.sh`, reviewing its output line by line for any new finding — particularly no hardcoded `Text('literal')` introduced by this feature — and resolve anything flagged before considering the phase done.

## Success Criteria
- `flutter test` reports 100% pass across the entire suite, with the new `respond_to_a_situation_screen_test.dart` and the new dispatcher routing group both green.
- `flutter analyze` reports 0 issues.
- `.github/scripts/check-standards.sh` reports no new findings attributable to this feature's files.
- Every numeric assertion in the new test file was independently verified against the running widget output during implementation, not merely asserted from this plan's pre-derivation.

## Risks
- Off-by-one errors in the sub-stage boundary math (elapsed 29s/30s especially) could make the pre-derived expectations wrong: mitigate by treating the pre-derived numbers in this plan as a starting hypothesis, re-deriving from `elapsedPrepSeconds`'s actual clamp logic during implementation, and trusting the running test output over the plan if they disagree.
- A stale full-suite baseline assumption could mask a real regression as "expected": mitigate by measuring the pre-Phase-1 baseline fresh at the start of this phase (or reusing a baseline captured immediately before Phase 1's changes) rather than trusting any previously reported count.
