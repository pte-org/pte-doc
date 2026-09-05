# Phase 1: Windows Backend Spike

## Requirements
Determine, cheaply and fast, whether `just_audio_windows` can be wired in as just_audio's Windows backend with zero changes to `AudioPlayerServiceImpl` or `DeviceCheckAudioPlayerImpl` — producing a clear go/no-go decision that determines whether Phase 2a or Phase 2b runs next. This phase is a gate, not the full implementation; do not polish or finalize anything here.

## Steps
1. Add `just_audio_windows` as a dependency and, since just_audio does not declare it as the Windows `default_package` today, attempt the minimal wiring needed to force it in for Windows builds (e.g. a `dependency_overrides` entry or equivalent manual registration) — try the simplest approach first.
2. Resolve dependencies and confirm there is no version conflict between `just_audio_windows`, the pinned `just_audio: ^0.10.6`, and everything else in the pubspec.
3. Run the app on Windows with no other code changes and open the existing dev-only "Test Mic and Sound" screen.
4. Trigger the "Play test sound" button and listen for actual audible output — not just a correct state transition, which the app already produces today even with silent no-op playback.
5. Record the outcome plainly (succeeded / failed) and note the exact failure mode if it failed, so Phase 2b's implementer knows what was tried and ruled out.
6. Revert or discard any spike-only wiring that would conflict with Phase 2a or Phase 2b if this spike's outcome sends the plan down the other branch.

## Success Criteria
- Dependency resolution step completes cleanly with a recorded pass/fail result.
- A recorded, unambiguous answer to "did tapping Play test sound produce audible sound on Windows": yes or no.
- If yes: nothing else in the app was changed beyond pubspec/override wiring — confirmed by diffing changed files against `AudioPlayerServiceImpl`/`DeviceCheckAudioPlayerImpl` (expected: no changes).
- If no: the specific failure point (resolution error, plugin not registered, still silent) is documented for Phase 2b.

## Risks
- The override mechanism could appear to resolve cleanly but silently fail to register the plugin at runtime (still a no-op) — mitigated by the manual audible-sound check in step 4 being the actual gate, not dependency resolution alone.
- Time-box this phase — if wiring attempts start requiring non-trivial code changes or forking just_audio itself, treat that as a "no" outcome and move to Phase 2b rather than continuing to invest here.
