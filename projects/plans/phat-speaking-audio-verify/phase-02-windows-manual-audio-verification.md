# Phase 2: Windows Manual Audio Verification

## Requirements
Confirm, on the one platform currently available (Windows), that a real speaking task records microphone audio to a valid non-empty file and audibly plays its prompt audio — giving one fully verified platform before macOS/Linux are revisited. Maps to spec P1 story: "As the developer, I want to confirm on the one platform I can actually run (Windows) that a speaking task truly records mic audio to a valid file and plays prompt audio" (FR-03).

## Steps
1. Launch the app on Windows via `flutter run -d windows` from the `pte-app` directory.
2. Navigate to a speaking task screen that uses the existing recording/playback flow (e.g. Read Aloud) — no new screens or flows needed, this is exercising already-implemented behavior.
3. Confirm the task's prompt/listening audio plays and is audibly clear through the system's speakers/headphones before recording starts.
4. Let the auto-record window run its full course — speak into the microphone during the recording window and let it complete without manually interrupting it.
5. Locate the resulting recorded audio file on disk (or check the pending-upload queue state) and confirm it is a `.wav` file with size greater than 0 bytes.
6. Record the pass/fail outcome of each checklist item (steps 3–5) so the manual verification is auditable and repeatable later.

## Success Criteria
- [x] App launches successfully on Windows via `flutter run -d windows` with no crash. (Confirmed — required an unplanned fix first: a pre-existing `onReorderItem` build error in `re_order_paragraphs_list.dart` blocked every Windows build regardless of this plan's changes; reverted to `onReorder` with standard index adjustment.)
- [x] Live prep countdown ("Beginning in N seconds") confirmed genuinely ticking down (30→0), not frozen. (Required a second unplanned fix: the dev-preview harness never seeded `ExamAttemptBloc` into `AttemptInProgress`, so the timer bridge had nothing to forward. Added `DevPreviewAttemptSeeded` — see plan.md Session Notes.)
- [ ] Prompt/listening audio confirmed audible — not reached this round (developer stopped verification once the countdown-wiring finding was confirmed).
- [ ] A `.wav` file produced after the auto-record window ends, confirmed on disk with size > 0 bytes — **not achieved**. Root cause identified, not fixed: `TimerService` only transitions `prep`→`response` phase on a successful server-poll reconciliation; the dev-preview's fake attempt ID can never poll successfully, so the phase (and therefore `AutoRecordCubit`'s call into `record`'s `start()`) never fires. Needs either a fake `TimerRepository` for dev-preview or a real backend attempt — developer chose not to pursue either this round (see plan.md Risks, spec.md Follow-up).

**Net for this phase:** partially verified. The build compiles and runs on Windows, and the auto-record timer's bloc/bridge wiring is now confirmed live and correct. The actual mic-open/record-to-file step is unconfirmed — tracked as a residual risk, not silently assumed working.

## Risks
- Manual verification is inherently non-repeatable/non-automated: mitigation — checklist is explicit and can be re-run identically by any developer with a Windows machine and a working mic; CI/build-matrix automation is explicitly deferred (spec Out of Scope).
- A false negative (e.g., wrong input device selected in OS mic settings) could be mistaken for an app bug: mitigation — checklist step 3 confirms playback works first, isolating mic-input issues from general audio-pipeline issues.
