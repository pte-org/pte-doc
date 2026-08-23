# Phase 3: Repeat Sentence Screen + Wiring

## Requirements
A `RepeatSentenceScreen` reachable from the task-type dispatcher that renders the confirmed layout (fixed instruction text, decorative listening card during prep, reused recorded-answer card during response/recorded) and auto-advances with zero manual buttons, matching the reference screenshot.

## Steps
1. Build a purely presentational listening-status card as `AudioListeningStatusCard` in `lib/features/exam_attempt/presentation/widgets/audio_listening_status_card.dart` (generic name, intentional — the same shape would suit any future audio-prompt task type, e.g. Retell Lecture, but it is Repeat-Sentence-only content-wise for now, no shared base yet per the "extract at 3rd occurrence" rule): a status-label line, a decorative "Volume" row (static meter, not driven by any real signal), and a progress bar underneath, reusing the existing (now-renamed) progress-bar styling tokens.
2. Build `RepeatSentenceScreen` mirroring the Read Aloud screen's structure: cubit created/closed in `initState`/`dispose`, the `ExamAttemptBloc` timer-bridge subscription duplicated with its mandatory task-identity guard, and a body composing the fixed instruction text, the listening card during prep, and the reused recorded-answer card during response/recorded — no prompt/passage text anywhere.
3. Add a Repeat Sentence dev fixture: `prepSeconds: 12` (a 3-part real-world sequence the UI does **not** visually distinguish — 3s pre-listen prep + 6s mocked audio playback + 3s pre-record prep, all rendered as one continuous "Beginning in N seconds" countdown per the user's confirmed decision, so the fixture's `prepSeconds` is the *sum*, not a single stage's duration), `responseSeconds: 15`; register it alongside the existing Read Aloud fixture.
4. Route the new task type through the task-type dispatcher.
5. Write the listening-status-card widget test (status label and progress render correctly).
6. Write the Repeat Sentence screen test mirroring the Read Aloud screen test's full structure — prep-phase card text, response-phase auto-start and card text, the full prep-to-response-to-recorded transition — and the mandatory mismatched-task identity-guard case (a snapshot for a different task must never be forwarded).
7. Run `flutter analyze` and the full `test/unit test/widget` suite; confirm the passing count only grows from Phase 2's baseline, with zero regressions.

## Success Criteria
- `flutter test test/widget/features/exam_attempt/repeat_sentence_screen_test.dart` passes, including a dedicated case asserting a mismatched `pinnedItemPublicId` snapshot never starts recording.
- `flutter test test/widget/features/exam_attempt/audio_listening_status_card_test.dart` passes.
- Selecting a task fixture with `taskType: 'REPEAT_SENTENCE'` through `TaskTypeDispatcher` renders `RepeatSentenceScreen`, not the unsupported-task-type placeholder.
- `flutter analyze` reports zero issues; full suite passing count strictly exceeds Phase 2's baseline with zero regressions.
- No file introduced in this phase exceeds 300 lines.

## Risks
- Omitting the identity guard when duplicating the timer-bridge reintroduces the previously-fixed cross-task recorder-misfire bug: mitigate by treating the mismatched-task test case as a hard release gate, not an optional extra.
- The decorative volume meter is implemented as if it were data-driven (e.g. accidentally wired to a real stream), contradicting the confirmed "mock completely" decision: mitigate with a doc comment on the card stating explicitly that the meter is decorative-only and a widget test that doesn't assert any animation/data-driven behavior.
- `RepeatSentenceScreen` exceeds the 300-line limit once the body/status-card logic is inlined: mitigate by extracting private widget classes in the same file, mirroring `read_aloud_screen.dart`'s own `_ReadAloudBody`/`_StatusCard` split.
