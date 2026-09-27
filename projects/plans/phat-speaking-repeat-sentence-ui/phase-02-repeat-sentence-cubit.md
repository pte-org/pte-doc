# Phase 2: Repeat Sentence Cubit + State

## Requirements
A `RepeatSentenceCubit`/`RepeatSentenceState` pair that auto-starts recording when the response window begins and auto-stops when it ends, mirroring Read Aloud's mechanics exactly, fully covered by unit tests before any UI is built on top.

## Steps
1. Add `RepeatSentenceState`, reusing the relocated recording-phase enum and implementing the shared upload-tracking marker interface.
2. Add `RepeatSentenceCubit` with the same constructor dependencies and recording start/stop mechanics as the Read Aloud cubit, reusing the existing file-path resolver as-is (it keeps its Read-Aloud-specific name — it is not Read-Aloud-specific in behavior, just naming, and renaming it is not in scope for this plan; do not touch Phase 1's already-regression-gated files here).
3. Duplicate the timer-snapshot auto-record guard mechanism (in-flight start/stop guards) into the new cubit rather than extracting it — this is only the 2nd such cubit, below this project's 3-occurrence DRY threshold.
4. Add a doc comment on the new cubit's timer-snapshot handler stating that a 3rd auto-record cubit (e.g. Describe Image, Retell Lecture) is the trigger to extract this guard mechanism into a shared base/mixin, not before.
5. Write unit tests mirroring the Read Aloud cubit test's full structure: recording-phase transition cases and every timer-snapshot case (idle-starts, expiry-stops, prep-is-no-op, already-recorded-is-no-op, resume-after-expiry, repeated-mid-recording-tick idempotency, and the synchronous double-snapshot no-double-start case).
6. Run `flutter analyze` and the full `test/unit test/widget` suite; confirm the passing count only grows from Phase 1's baseline, with zero regressions.

## Success Criteria
- `flutter test test/unit/features/exam_attempt/repeat_sentence_cubit_test.dart` passes with a test-case count matching the Read Aloud cubit test's structure (recording-phase transitions + all timer-snapshot edge cases).
- **`repeat_sentence_cubit_test.dart` includes a dedicated, individually-named case asserting a synchronous double `onTimerSnapshot` call (two calls with no `await` between them) does not double-invoke `startRecording`/`stopRecording`** — this is a hard, individually-checkable gate (plan-reviewer HIGH finding), not satisfied merely by an aggregate test-count match. This guard was a real tester-found, debugger-fixed bug in `ReadAloudCubit`; duplicating the mechanism without duplicating the test that proves it works is not acceptable.
- `flutter analyze` reports zero issues.
- Full suite passing count is strictly greater than Phase 1's, with no prior test now failing.
- `RepeatSentenceCubit`'s public shape (constructor params, `startRecording`/`stopRecording`/`onTimerSnapshot`) matches `ReadAloudCubit`'s exactly, differing only in type names.

## Risks
- Copy-paste drift introduces a subtle behavioral difference from the reference cubit (e.g. a missed `whenComplete` guard reset): mitigate by running the exact same test scenarios as the Read Aloud cubit test, adapted only in type names, so any divergence fails a test rather than passing silently.
- Skipping the idempotency guards under time pressure since "it's just a copy": mitigate by treating the resume-after-expiry and repeated-tick test cases as mandatory, not optional, since they document the exact race this mechanism prevents.
