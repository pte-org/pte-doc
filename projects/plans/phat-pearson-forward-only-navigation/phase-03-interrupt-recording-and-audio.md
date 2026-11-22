# Phase 3: Interrupt Recording and Audio on Next

## Requirements
Pressing Next while a Speaking recording is running saves the partial recording as the answer; pressing Next while Listening or prompt audio plays stops the audio and moves on immediately.

## Files to touch (pte-app)
- `lib/features/exam_attempt/presentation/widgets/task_advance_button.dart` — optional "before leaving" hook awaited after the draft flush and before the submit-for-advance helper.
- `lib/features/exam_attempt/speaking_writing/presentation/cubit/read_aloud_cubit.dart` (holds `AutoRecordCubit`; `stopRecording` ~l.136, `close` ~l.157) and `AutoRecordTimerBridgeMixin` — finalize-for-advance behaviour.
- `lib/features/exam_attempt/speaking_writing/presentation/cubit/audio_prompt_cubit.dart` — stop prompt playback (Repeat Sentence, Re-tell Lecture, Answer Short Question, Summarize Group Discussion, Respond to a Situation).
- `lib/features/exam_attempt/speaking_writing/presentation/widgets/auto_advance_on_upload_ready.dart` — advance only if its task is still active (also done in Phase 2; verify).
- Speaking screens (8) — pass the hook to the shared button.
- Listening cubits/screens in `lib/features/exam_attempt/listening/presentation/`, `listening/data/audio_player_service_impl.dart`, `domain/audio_player_service.dart` — playback stops and the player is released when the screen leaves.
- `lib/core/sync/media_upload_coordinator.dart` — read only; confirm the answer is queued once the upload is ready and sent as a save (`advance:false`, pointer untouched).

## Steps
1. Add the "before leaving" hook to the shared button; it must be cheap, bounded in time, and must not wait for network upload.
2. Recording in progress: stop the recorder, persist the media row for the partial file, start the background upload without waiting, then continue.
3. Not recording yet (prep, pre-listen): nothing to finalize; the task advances with a blank payload (Phase 2 helper).
4. Prompt audio playing: stop it as part of leaving so the next task starts with a free player and recorder.
5. Listening audio playing: guarantee the player is stopped and released on teardown including Next during playback; no wait for completion.
6. Upload-ready auto-advance only dispatches for the still-active task (no second advance after a late upload of the previous task).
7. Confirm the late partial answer is saved against the earlier task after the pointer moved (`saveAnswer` accepts any item) and that final submit waits for pending media.

## Tests
- Cubit tests: stop-for-advance while recording creates the media row once and is idempotent with the close-time stop; no recording started → no media row.
- Widget test: Next during recording awaits the hook, then dispatches exactly once.
- Test: upload-ready auto-advance for an inactive task does not dispatch.
- Listening cubit test: closing during playback releases the player.

## Success Criteria
- New cubit/widget tests pass; `flutter test test/unit/features/exam_attempt test/widget/features/exam_attempt` green.
- Manual (user performs): Read Aloud, Next mid-recording → next task opens, the partial answer appears server-side for the first task after upload. Listening, Next while audio plays → audio stops and the next item loads. No "recorder/player already in use" error.

## Risks
- Recorder stop is slow or fails: bounded wait, fall back to the cubit's close-time stop; the task still advances (blank on the server, partial may arrive later).
- Partial recording is lost if the exam is submitted before the upload finishes (plan Risks).
- Real-device recorder behaviour differs from tests: Android build check required.

## Execution Log
<!-- Filled by /ck:cook at the end of this phase — leave placeholders when planning -->

### Errors Encountered
- `Error: Undefined name 'responseExpiredSnapshot'` in `auto_record_cubit_test.dart` — the const was local to another test group.
- Process slip: ran `dart format` on a whole directory, which reformatted `lib/.../countdown_timer.dart` (format-only change, unrelated file).
- Review MEDIUM-1: a blank advance request still in flight when the real recording was queued made `markSynced` mark the real answer as synced, so it was never sent.
- Review MEDIUM-2: Next (or close) during an in-flight `startRecording` saw phase `idle`, skipped the stop and left the shared recorder running; emits after close would throw.
- Review LOW-2: the timer-path `unawaited(_stopOnce())` had no error handler.

### Root Cause
- The new test referenced a group-local constant.
- Formatting a directory instead of the specific touched files.
- MEDIUM-1: `markSynced` updated by key only, ignoring the payload that was sent.
- MEDIUM-2: start was tracked only by a bool and the phase flips after the awaits; finalize/close checked the phase alone.
- LOW-2: missing error handler on a fire-and-forget future.

### Resolution
- Declared the `TimerSnapshot` inline in the new test.
- Restored `countdown_timer.dart` with `git checkout --` (only the accidental format change); later formatting limited to specific files.
- MEDIUM-1: `AnswerOutboxDao.markSyncedIfUnchanged(attempt, item, sentPayload)` replaces `markSynced`; `SyncEngine._flushOne` passes the sent payload, so a newer row stays pending.
- MEDIUM-2: `AutoRecordCubit` tracks `_startRun`; `finalizeForAdvance`/`close` await it, set `_leaving` (timer can no longer start a recording), and the start path checks `_leaving`/`isClosed` and frees the recorder if closed.
- LOW-2: `_stopOnce().catchError` on the timer path.
- Not fixed, kept in plan Risks: LOW-1 (close-time retry stop on the shared recorder after a failed stop), LOW-3 (stale-tap guard on Speaking screens, Phase 2 area).

### Test Results After Fix
- `flutter analyze lib` -> No issues found
- `flutter test -r failures-only` -> 858 passed (before review fixes)
- After review fixes: `flutter analyze lib` -> No issues found; `flutter test -r failures-only` -> 864 passed, 0 failed (+4 cubit tests for start-in-flight/leaving/close/failing stop, +2 DAO tests for `markSyncedIfUnchanged`)
- code-reviewer: first review APPROVED 8/10 (2 MEDIUM, 3 LOW); re-review after fixes APPROVED 9/10 (0 MEDIUM, 4 LOW accepted into plan Risks).
