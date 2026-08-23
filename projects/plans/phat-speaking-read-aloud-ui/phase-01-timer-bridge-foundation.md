# Phase 1: Timer Bridge Foundation

## Requirements
A shared mm:ss duration formatter exists and is used by the existing timer display, and `ReadAloudCubit` gains an idempotent method that auto-starts/auto-stops recording purely from forwarded `TimerSnapshot` values and its own `RecordingPhase` state — fully unit-tested in isolation, no UI changes yet.

## Steps
1. Extract the mm:ss formatting logic currently duplicated as a private method inside `ExamAppBar` into a new shared utility function in a new `lib/core/utils/` directory (first file there), preserving its exact output.
2. Update `ExamAppBar` to import and use the extracted formatter instead of its private copy.
3. Add a public, idempotent method to `ReadAloudCubit` that takes a timer snapshot and, based solely on the cubit's current recording phase: starts recording the instant the response phase begins, stops recording the instant the response countdown hits zero, and does nothing in every other case (including repeated calls with the same or irrelevant snapshot). Add a doc comment noting the zero-check relies on `TimerService`'s `_nonNegative` clamp always keeping `remaining` at exactly `Duration.zero` once expired (never negative) — a future change to that invariant would need this guard revisited.
4. Extend the existing `ReadAloudCubit` unit test file with `blocTest` cases: idle+response starts recording; recording+response+expired remaining stops/records; prep-phase snapshot is a no-op; calling again after already `recorded` is a no-op (assert the recorder mock's stop is not called a second time); and idle+response+`remaining` already `Duration.zero` on the very first forwarded snapshot only starts recording (does not also stop in the same call) — covers the resume-after-expiry edge case (plan-reviewer NOTED finding), self-corrects on the next tick so no fix needed, just coverage.
5. Run `flutter analyze` and the touched/new test file, and resolve every warning before the phase is considered done.

## Success Criteria
- `flutter test test/unit/features/exam_attempt/read_aloud_cubit_test.dart` passes, including the four new `onTimerSnapshot` cases.
- Mocktail `verify(...).called(1)` confirms no duplicate `recorder.start()`/`recorder.stop()` calls occur when the new method is invoked repeatedly with the same or irrelevant snapshot.
- `ExamAppBar`'s rendered countdown text is unchanged after the extraction (same `mm:ss` output for the same `Duration`).
- `flutter analyze` reports no new warnings on `lib/core/utils/duration_format.dart`, `exam_app_bar.dart`, or `read_aloud_cubit.dart`.

## Risks
- Off-by-one at the `remaining == Duration.zero` boundary causing the stop to fire one tick early or never: mitigation — add a unit test asserting the exact `Duration.zero` snapshot triggers the stop, and a case just above zero does not.
- Subtle behavior change while extracting the formatter (e.g. rounding): mitigation — copy the existing `twoDigits`/`inMinutes`/`inSeconds % 60` logic verbatim rather than rewriting it.
