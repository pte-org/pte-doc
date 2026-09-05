# Phase 3: Dev-Preview Wiring, Tests, and Regression Gate

## Requirements
The Test Mic and Sound screen is reachable from this app's existing dev-preview entry points (both the always-on debug routes and the `DEV_SKIP_AUTH` standalone menu), fully covered by cubit and widget tests, and the full test/analyze/standards suite passes clean with no new findings.

## Steps
1. Add a `kDebugMode`-gated route (`'/dev/device-check-preview'` — matches the existing `/dev/{feature}-preview` naming convention exactly, not `/dev/device-check`) for the new screen and a corresponding `_buildTestMicAndSoundScreen()` builder in `lib/app.dart`, resolving `AudioRecorderService` from `GetIt` the same way every other dev-preview builder does; construct `DeviceCheckAudioPlayer` directly inside the screen, not through this builder.
2. Add a matching entry (icon distinct from the existing Reading/Listening/Speaking-Writing ones, title, subtitle) to the `_DevStandaloneMenu` list and its corresponding `/dev/standalone/device-check` route, following the existing three entries' exact shape.
3. Establish the pre-Phase-1 `flutter test` baseline count fresh (run the full suite once, record the actual pass count — do not reuse any previously reported number) before adding new tests, so the final regression comparison is against a real number.
4. Write cubit tests covering: full idle→recording→recorded→playing-back progression for the mic sub-flow, the same playing progression for the sound sub-flow, a "Yes" confirmation locking in each sub-flow's answer, a "No" confirmation resetting only that sub-flow back to idle, and explicit proof that acting on one sub-flow never mutates the other's state.
5. Write widget tests against mocked `AudioRecorderService`/`DeviceCheckAudioPlayer` covering: correct initial render of both sections and button enabled/disabled states, that tapping Record/Stop calls the recorder's start/stop and unlocks the play-my-recording button, that Play-my-recording and Play-test-sound each invoke the correct player method with the correct path/asset argument, and that a "No" answer on either section visibly resets only that section's buttons.
6. Run `flutter analyze`, `flutter test` (full suite), and `.github/scripts/check-standards.sh`, and resolve any new issue introduced by this feature's files (pre-existing, unrelated findings are out of scope to fix).
7. Manually smoke-test the screen once (debug build, dev route) to confirm the microphone permission prompt appears as expected and record→stop→play→confirm and play-test-sound→confirm both work end-to-end on a real or emulated device.

## Success Criteria
- `flutter analyze`: 0 issues.
- `flutter test`: 100% pass, total count equal to the fresh pre-Phase-1 baseline plus every new test added in this phase (no regressions, no skipped tests).
- `.github/scripts/check-standards.sh`: no new findings beyond the documented pre-existing ones; specifically, no hardcoded `Text('literal')` in any new file.
- The new screen is reachable both from `flutter run --dart-define=DEV_SKIP_AUTH=true` (via the standalone menu) and via `Navigator.pushNamed('/dev/device-check')` in a plain debug build.

## Risks
- `check-standards.sh` flagging something unanticipated in the new files (e.g. a missed literal string, an import-order rule): mitigate by running it locally before considering the phase done, not only in CI.
- Manual mic-permission smoke test being skipped or unreliable on the developer's machine/emulator: mitigate by treating it as a required manual step in this phase's checklist, not an optional nice-to-have, and noting the platform/device it was verified on.
