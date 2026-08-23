# Phase 2: Presentational Widgets

## Requirements
Two new, purely prop-driven widgets exist — a bordered passage panel with dynamic prep/response-second instructions, and a recording indicator with a pulsing dot, mm:ss/mm:ss label, and decorative looping waveform — styled entirely through `AppColors`/`AppDimensions`/`AppStrings`, each covered by a widget test, with the recording indicator's animation controllers verified to dispose cleanly.

## Steps
1. Add every new `AppColors`/`AppDimensions` token the passage panel (border/spacing/radius) and recording indicator (dot size, pulse timing, waveform bar sizing/spacing) need, following the exact naming/style pattern of the existing `readingHeader*`/`examBottomBar*` tokens — reuse `AppColors.error` for the record dot, do not add a new red.
2. Add new `AppStrings` entries: a templated prep/response instruction string that takes the task's actual `prepSeconds`/`responseSeconds` (no hardcoded "40 seconds"), and a prep-phase "recording starts automatically" hint.
3. Build the passage panel widget: a bordered card showing the templated instruction text above a scrollable prompt-text region, matching the mockup's bordered-card composition.
4. Build the recording indicator widget as a stateful, purely presentational widget taking `isRecording`/`elapsed`/`total` constructor props: a record dot that pulses only while recording, an `mm:ss / mm:ss` label using the Phase 1 formatter, and a row of bars that loop only while recording and sit static otherwise — every `AnimationController` created in `initState` and disposed in `dispose`.
5. Write a widget test for the passage panel asserting the instruction text reflects a given task's actual prep/response seconds (not a fixed string) and that the prompt text renders.
6. Write a widget test for the recording indicator asserting the elapsed/total text renders correctly for fixed props, and that pumping the widget then removing it from the tree leaves no leaked `AnimationController`/ticker.
7. Run `flutter analyze` and both new test files, resolving every warning before the phase is considered done.

## Success Criteria
- `flutter test test/widget/features/exam_attempt/read_aloud_passage_panel_test.dart` and `read_aloud_recording_indicator_test.dart` both pass.
- The recording indicator test demonstrates no animation-controller leak after teardown (no `flutter_test` leaked-ticker failure).
- Passage panel instruction text changes correctly for two different `prepSeconds`/`responseSeconds` inputs in the test, proving no hardcoding.
- `flutter analyze` is clean on both new widget files — no `Color(0xFF...)`, no literal `TextStyle` magic numbers, no bare strings outside `AppStrings`.

## Risks
- Two `AnimationController`s (dot pulse + waveform) makes it easy to dispose only one: mitigation — dispose both explicitly, cover with the leak-detection widget test from Step 6.
- Passage panel's scrollable text overflows an unbounded test harness: mitigation — wrap the widget under test in a bounded `SizedBox`, matching how `ReadingPassageLayout` already constrains its `passage` child.
