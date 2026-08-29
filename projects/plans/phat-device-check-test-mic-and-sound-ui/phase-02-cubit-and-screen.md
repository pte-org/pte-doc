# Phase 2: Device-Check Cubit, State, and Screen UI

## Requirements
A candidate can open the "Test Mic and Sound" screen and independently: (1) record their own voice, play it back, and confirm whether they heard themselves clearly, retrying on "No"; and (2) play a fixed sample clip and confirm whether they heard it clearly, retrying on "No" — with no timer, no exam chrome, and no dependency between the two sub-flows.

## Steps
1. Define the device-check state shape: two independent sub-states (a mic-check phase progressing idle → recording → recorded → playing-back, and a sound-check phase progressing idle → playing), each carrying its own nullable "confirmed heard clearly" answer.
2. Build the cubit owning both sub-flows: start/stop mic recording (via the existing `AudioRecorderService`, resolving a fixed, always-overwritten temp file path the same way `read_aloud_cubit.dart`'s path resolver does but without any attempt/item context), play back the recording and play the bundled test sound (via the new `DeviceCheckAudioPlayer`), and record each Yes/No confirmation. Explicitly handle the two failure paths `AudioRecorderService`'s interface allows: if `stop()` returns `null` ("nothing was recorded" per the interface doc), stay in `idle` rather than transitioning to `recorded` — never advance to a state that implies a playable file exists when none does; if `start()` throws (e.g. mic permission denied), catch it and stay in `idle` rather than getting stuck showing "recording" with no way back.
3. Wire the "No" answer on either sub-flow to reset only that sub-flow back to its starting point so the candidate can retry, leaving the other sub-flow's state completely untouched.
4. Build the screen as a plain, non-exam `Scaffold` with an app bar and two stacked sections ("Test your microphone", "Test your sound"), each following this app's established spacing/color conventions (padding via the shared spacing constants, body text styled with the shared primary text color) rather than inventing new visual style.
5. Wire each section's buttons to the cubit: record/stop button whose label reflects the current mic phase, a play-my-recording button enabled only once something has been recorded, a play-test-sound button always enabled, and Yes/No confirmation buttons that appear once the relevant playback has finished.
6. Have the screen own the cubit and the new audio player's full lifecycle explicitly — construct both in `initState`, dispose both in `dispose` — with no hidden creation elsewhere.
7. Make every user-facing label, instruction, and prompt on the screen pull from the Phase 1 strings class — no literal `Text('...')` calls.

## Success Criteria
- `flutter analyze` reports 0 issues for the new cubit, state, and screen files.
- Manually exercising the screen (or via the Phase 3 widget tests) confirms: recording enables playback, playback enables the confirmation prompt, "No" resets only its own sub-flow, and the mic and sound sections never affect each other's state.
- No hardcoded `Text('literal')` strings exist in the new screen file (spot-checked against `docs/CODING_STANDARDS_APP.md`'s rule, formally verified in Phase 3's `check-standards.sh` run).

## Risks
- Accidentally coupling the two sub-flows (e.g. sharing one "confirmed" flag or one phase enum) would silently violate the "sound test usable independently of mic test" requirement: mitigate by keeping the state class's two halves structurally separate and covering independence explicitly in Phase 3's cubit tests.
- Forgetting to reset the mic recording file state (stale "recorded" phase) after a "No" answer, leaving the candidate unable to re-record cleanly: mitigate by routing every reset through one shared code path in the cubit rather than duplicating reset logic per sub-flow.
