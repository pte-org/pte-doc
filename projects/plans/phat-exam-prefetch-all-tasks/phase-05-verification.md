# Phase 5: Verification

## Requirements
End-to-end confirmation that the prefetch design works correctly across both modes, all sections, and the resume path. All prior phases must be complete and deployed.

## Steps
1. **Full test suite**: `flutter test` (all passing), `exam-delivery` module `mvn test` (all passing).

2. **Manual — Practice mode full walk:**
   - Enter a Practice attempt. Confirm `GET /attempts/{id}/tasks` is called once on entry (check network logs or Spring `DEBUG` request logging).
   - Navigate Prev/Next through at least 5 tasks. Confirm: (a) no `GET /next-task` or `POST /navigate` server calls on each tap, (b) header item counter updates immediately, (c) global timer counts down continuously (no reset on navigation).
   - On a speaking task: record, press Next. Confirm answer is saved (audio upload starts). Navigate back via Prev. Navigate forward again. Confirm original recording is preserved (not re-recorded).
   - On a reading task: type a partial answer, navigate away, return. Confirm answer is preserved in the text field.
   - Background the app mid-exam, resume. Confirm `fetchAllTasks` is called again on resume and the student resumes on the correct task.

3. **Manual — Test mode full walk:**
   - Enter a Test attempt. Confirm `GET /tasks` called once.
   - Speaking section: confirm auto-advance fires after recording upload — no navigation buttons visible, timer counts down correctly, auto-advance moves to next task (no server navigation call).
   - Reading section: confirm Prev/Next are visible and work locally (no server calls). Confirm global timer continues counting; no per-task timer visible.
   - Writing section: same as reading.
   - Confirm exam auto-submits when `examEndTime` expires (global timer hits zero → `ForceSubmitRequested`).

4. **Regression — existing behavior unchanged:**
   - Test mode speaking tasks still auto-advance on timer expiry (no regression from `processAnswer` relaxation).
   - Listening tasks auto-advance as before.
   - Force-submit button still works.
   - Answer outbox still flushes in background for non-active tasks.

5. **Edge cases:**
   - `fetchAllTasks` returns 404 or 500 (simulate by temporarily breaking the endpoint): confirm fallback to single-task mode (or graceful error state, per Phase 3's fallback decision).
   - Network goes offline mid-exam: local navigation still works, answers queue in outbox, reconnect and flush succeeds.

## Success Criteria
- Zero `GET /next-task` or `POST /navigate` calls during in-session navigation (confirmed via network log).
- Practice mode Prev/Next respond in <100ms (no round-trip).
- Test mode speaking/listening auto-advance succeeds and moves to the correct next task.
- Global timer shows consistent countdown across Prev/Next navigation.
- Resume re-fetches and lands on the correct task.
- Full `flutter test` and `exam-delivery` test suite pass.
