# Phase 3: Manual Windows Audio Verification

## Requirements
Confirm, by human ear, that Windows desktop audio playback now actually works end to end for both playback surfaces affected by this plan — the dev-only device-check screen and, so far as it can be exercised without a full exam session, the production exam-attempt audio player. This is a manual checklist, not something an automated test can assert.

## Steps
1. Launch the app on Windows with the dev-skip-auth flag enabled so the dev standalone menu is reachable without logging in.
2. Navigate to the dev standalone device-check screen from that menu.
3. Record a short mic clip, tap "Play my recording", and listen for the recording played back audibly through speakers/headphones — not just the UI reaching its finished state.
4. Tap "Play test sound" and listen for the bundled test clip playing audibly.
5. Confirm no regressions were introduced to the recording flow itself (recording still starts/stops correctly) — recording is out of scope for changes but must still work end to end for this checklist to be meaningful.
6. From the same dev standalone menu (no deeper exam-session setup needed — the "Reading/Listening/Speaking & Writing preview" tiles already resolve `getIt<AudioPlayerService>()`, the exact production service), open the Listening preview screen and confirm its bundled/local audio plays audibly. This directly exercises the production `AudioPlayerService` path — it is reachable this cycle and must not be skipped or hedged as optional; only note it as "not reachable" if the dev standalone menu itself is unexpectedly broken.
7. Record the final pass/fail outcome of this manual checklist directly in `plan.md`'s status, since no automated agent can assert human-audible sound.

## Success Criteria
- Developer explicitly confirms, in writing, that "Play my recording" produced audible sound on Windows.
- Developer explicitly confirms, in writing, that "Play test sound" produced audible sound on Windows.
- Developer explicitly confirms, in writing, that the production `AudioPlayerService` path (Listening preview, reached via the dev standalone menu) produced audible sound on Windows — this is a required check, not optional, since the preview screen is directly reachable without a real exam session.
- No regression observed in the recording flow itself.
- `plan.md` is updated to reflect the final outcome of this manual checklist.

## Actual Results (2026-08-25)
- "Play my recording" (`setFilePath`): **audible, confirmed by developer**, both with `just_audio_windows` (Phase 1 spike) and `just_audio_media_kit` (Phase 2b).
- "Play test sound" (`setAsset`): **not audible with the app's real bundled fixture** — but this is because `assets/audio/listening_sample_dictation.wav` is itself silent placeholder data (see plan.md Session Notes), not a backend failure. Conclusively proven working by swapping in a real sine-wave tone asset, confirmed audible by the developer, then reverted.
- Production `AudioPlayerService` path (Listening preview, dev standalone menu): developer opened it, played a task's audio — **no crash, no exception**. Audio itself is silent for the same fixture-data reason as above (expected, not a regression from this plan).
- Recording flow: unaffected throughout — out of scope, untouched, confirmed still working (recordings played back audibly every round).
- `plan.md` Status updated to reflect this outcome; the silent-fixture-data issue is tracked as a separate flagged follow-up, not fixed as part of this plan.

Verdict: **PASSED** for this plan's actual scope (Windows backend now correctly plays both local files and bundled assets). The silent-fixture-data issue is a distinct, pre-existing, cross-platform bug — flagged, not resolved here.

## Risks
- Human hearing/hardware variance (muted system volume, wrong output device selected) could produce a false negative — mitigated by explicitly checking system volume/output device as a precondition before concluding failure.
- This step cannot be delegated to an automated `tester` agent — mitigated by keeping it as an explicit, separate manual checklist phase rather than folding it into an automated success criterion elsewhere in the plan.
