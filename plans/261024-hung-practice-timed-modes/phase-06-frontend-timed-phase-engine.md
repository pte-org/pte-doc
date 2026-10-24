# Phase 6: Frontend — bộ điều phối nhịp tính giờ

Status: Not started
User stories: US-3 (Speaking đúng nhịp thi), US-6 (đồng hồ theo câu cho Writing/Reading/Listening),
US-9 (vòng đếm ngược giai đoạn)
Tiêu chí §7: 4, 3 (UNTIMED không bị ảnh hưởng)

## Requirements

- Phiên `TIMED`, Speaking: *Đọc/chờ* (`preListenSeconds`, nếu có) → *Nghe đề* (audio tự phát **một lần**,
  không điều khiển) → *Chuẩn bị* (`preRecordSeconds`) → *Ghi âm* tự bật, đếm ngược `responseSeconds`, nút
  **Dừng sớm** → *Đang lưu* → *Xong* (sóng tĩnh + ▶, **không** ghi lại). Read Aloud / Describe Image bỏ bước nghe đề.
- Mic bị từ chối / lỗi **trước khi có bản ghi được lưu**: dừng đồng hồ, báo lỗi, nút "Thử lại câu này"
  chạy lại nhịp từ đầu (kể cả phát lại đề). Lưu lỗi sau khi đã ghi: giữ bản ghi, "Lưu lại", không ghi lại.
- Writing/Reading/Listening: Listening có audio → phát một lần rồi đếm `responseSeconds`; còn lại đếm ngay.
  Hết giờ: khoá ô trả lời, hiện "Hết giờ", học viên tự bấm Nộp (không tự nộp).
- Sang câu sau: nhịp chạy lại từ đầu. Thoát/tải lại: câu có `savedPayload.mediaPublicId` mở ở **Xong**
  (không phát lại đề, không ghi lại, vẫn nghe lại được); câu chưa có bản ghi / câu không phải Speaking
  chưa nộp chạy lại từ đầu, không khôi phục đồng hồ giữa chừng.
- Thanh giai đoạn dùng `Stepper`; đồng hồ dùng `CountdownTimer` (vòng + số giây). Bản ghi lưu qua
  `saveDraft` ngay sau upload (P3/P5).

## Design Constraints

- Engine là reducer **thuần** (`timed-phase.ts`), deadline tính từ timestamp (`nowMs + seconds*1000`), không
  giảm theo tick; hook `useTimedPhase` chỉ lập lịch `setTimeout` tới deadline gần nhất và tính lại khi
  `visibilitychange`. Đếm ngược ghi âm bắt đầu ở sự kiện `RECORD_STARTED` (sau khi `getUserMedia` resolve),
  không phải lúc vào giai đoạn — sai lệch dừng ≤ 1 s (tiêu chí 4).
- Tên trường/giai đoạn bám `pte-app` (`preListenSeconds`, `responseSeconds`); riêng thời gian chuẩn bị là `preRecordSeconds` (không phải `prepSeconds` tổng của `PinnedItem`).
- Autoplay / activation (red-team #2): cả `audio.play()` của đề **và** `AudioContext.resume()` của recorder
  (`audio-recorder.ts` dòng ~44–46) cần user activation. Dùng **một** cổng duy nhất **"Bắt đầu câu"** trước
  giai đoạn đầu mỗi khi không có activation (`navigator.userActivation?.hasBeenActive === false`, hoặc sau
  reload/resume) — áp cho **mọi** dạng Speaking kể cả Read Aloud/Describe Image không có audio đề. Bấm cổng thì
  trong cùng gesture: tạo/`resume()` AudioContext và "mồi" phần tử `<audio>`. `play()` reject `NotAllowedError`
  hoặc `resume()` không xong trong `RESUME_TIMEOUT_MS = 1500` → quay về cổng (dừng đồng hồ), không coi là lỗi mic.
- StrictMode chạy effect đôi: guard một-lần bằng `ref` cho cả lần phát đề **và** lệnh tự bật ghi âm
  (`command: "start"` chỉ được phát một lần cho mỗi lần chạy nhịp; `RETRY_ITEM` mới reset).
- Play-once + link hết hạn (red-team #4): guard chỉ được **claim sau khi `play()` resolve**; `play()`/`<audio>` lỗi
  tải trước khi phát → `getSession` lấy link mới rồi thử lại, vẫn tính là **một** lần phát. Trước khi vào item,
  link quá cũ (`isPromptMediaStale` của P5) → tải lại session trước.
- `PromptMedia` thêm `mode="once"` thay vì component mới; ở `once` không render `controls`, không cho seek.
- Phiên `UNTIMED` không mount bất kỳ phần nào của engine/`CountdownTimer` (tiêu chí 3).
- Không ép thời gian ở server (spec §5.5); component ≤ 150 dòng, file ≤ 300, i18n cho mọi nhãn giai đoạn.

## Related files

- `pte-practice/features/practice/timed/timed-phase.ts`, `timed-phase.test.ts` (mới)
- `pte-practice/features/practice/timed/useTimedPhase.ts`, `TimedTaskFrame.tsx`, `TimedStartGate.tsx`, `TimedPhaseStepper.tsx`, `timed-frame.ts`, `timed-frame.test.ts`,
  `play-once.ts`, `play-once.test.ts` (mới)
- `pte-practice/features/practice/renderers/PromptMedia.tsx`, `TaskRenderer.tsx`, `RendererTypes.ts`
- `pte-practice/features/practice/recorder/SpeakingRecorder.tsx`, `useRecorder.ts`, `recorder-state.ts` (từ P5)
- `pte-practice/features/practice/session/SessionTaskView.tsx` (từ P4)
- `pte-practice/common/components/{Stepper,CountdownTimer}.tsx` (từ P4)
- `pte-practice/common/i18n/{types,en,vi}.ts`, `app/globals.css`

## Steps

1. `timed-phase.ts`: `buildPhasePlan({ timing, isSpeaking, hasPromptAudio })` → danh sách giai đoạn
   (`preListen?`, `prompt?`, `prep?`, `recording` | `answering`); state `{ phase, deadlineMs, plan, recorded }`;
   sự kiện `START(now)`, `TICK(now)` (chỉ chuyển khi `now ≥ deadlineMs`), `PROMPT_ENDED(now)`,
   `RECORD_STARTED(now)`, `STOP_EARLY`, `RESPONSE_ELAPSED`, `SAVED`, `SAVE_FAILED`, `MIC_ERROR`, `RETRY_ITEM`;
   `initialTimedState({ hasSavedRecording, isSpeaking })` — có bản ghi → `done`; giai đoạn 0 giây bị bỏ qua.
   Trạng thái `done`/`saveFailed` không nhận sự kiện ghi lại.
2. `play-once.ts`: `createPlayOnceGuard()` với `canAttempt()`, `markPlayed()` (gọi khi `play()` resolve),
   `hasPlayed()`, `reset()` cho `RETRY_ITEM`; `createOnceCommand()` cho lệnh tự bật ghi âm. Reducer có thêm
   giai đoạn `gate` (chờ "Bắt đầu câu") và sự kiện `ACTIVATED`, `ACTIVATION_LOST` (play/resume bị chặn hoặc timeout).
3. `useTimedPhase(task, { hasSavedRecording })`: reducer + timer tới deadline; reset theo `task.publicId`;
   trả `{ phase, deadlineMs, totalSeconds, dispatch }`.
4. `PromptMedia mode="once"`: nhận `playSignal`, `onEnded`, `onBlocked`, `onMediaError`; `markPlayed` sau khi
   `play()` resolve; `onBlocked` → `ACTIVATION_LOST` (về cổng "Bắt đầu câu"); `onMediaError` trước khi phát →
   refetch session + thử lại; ảnh (Describe Image) vẫn hiện trong mọi giai đoạn.
5. `SpeakingRecorder` nhận chế độ điều khiển: `command: "start" | "stop" | null`, `allowRetake={false}`,
   `maxSeconds = responseSeconds`; báo `onStarted(now)` → `RECORD_STARTED`, `onSaved` → `SAVED`, lỗi mic → `MIC_ERROR`.
   Lưu draft đi qua `runBackgroundMutation` (P4, red-team #1): `{ ok: false }` → `SAVE_FAILED`, blob giữ lại, nút
   "Lưu lại"; không bao giờ đưa phiên sang phase `error`. `durationSeconds` kẹp số nguyên `[1,120]` như P5.
6. Cổng "Bắt đầu câu" (`TimedStartGate`, trong `TimedTaskFrame`) + `TimedPhaseStepper` (dùng `Stepper` với id `preListen/prompt/prep/recording/done`, chỉ các bước có trong plan)
   và `TimedTaskFrame` (Stepper + `CountdownTimer` theo `deadlineMs/totalSeconds` + nút Dừng sớm / Thử lại câu này).
7. Non-speaking: `answering` → `timeUp` khi hết giờ; `SessionTaskView` truyền `disabled` cho renderer và hiện
   notice "Hết giờ" (`role="status"`); Nộp bài vẫn bật.
8. `SessionTaskView`: `shouldMountTimedFrame(session)` (thuần: `timingMode === "TIMED"` và `currentTask.timing != null`)
   → bọc renderer bằng `TimedTaskFrame`; ngược lại render như P5 (red-team #10, tiêu chí 3).
9. i18n: tên giai đoạn, "Bắt đầu câu", "Dừng sớm", "Thử lại câu này", "Hết giờ", aria của đồng hồ.

## Tests to add

- `timed-phase.test.ts`:
  - Repeat Sentence (3/3/15): `START` → preListen 3 s → prompt → `PROMPT_ENDED` → prep 3 s → recording,
    deadline = `RECORD_STARTED.now + 15000`; `TICK` trước deadline không chuyển.
  - Read Aloud không có audio: bỏ prompt; prep 35 → recording 40.
  - `STOP_EARLY` khi recording → saving; `SAVED` → done; `RETAKE`/`START` ở done bị bỏ qua.
  - `MIC_ERROR` trước khi lưu → error; `RETRY_ITEM` → quay về giai đoạn đầu.
  - `SAVE_FAILED` → saveFailed (không về recording).
  - `initialTimedState({ hasSavedRecording: true })` → done; không có bản ghi → idle (chạy lại từ đầu).
  - Listening MC: prompt → answering 20 s → timeUp; Writing: answering ngay.
  - Giai đoạn `preRecordSeconds = 0` bị bỏ qua.
- `timed-phase.test.ts` thêm (red-team #2): không có activation → bắt đầu ở `gate` cho Repeat Sentence **và** Read Aloud;
  `ACTIVATED` → giai đoạn đầu; `ACTIVATION_LOST` khi đang prompt/prep/chờ ghi → về `gate`, deadline xoá;
  `resume()` timeout → `ACTIVATION_LOST` (không phải `MIC_ERROR`); `MIC_ERROR` sau khi đã `SAVED` bị bỏ qua.
- `play-once.test.ts`: `canAttempt` vẫn true khi `play()` chưa resolve; `markPlayed` gọi 2 lần (StrictMode) vẫn một
  lần; chuỗi lỗi tải → refetch → play thành công tính **đúng một** lần (red-team #4); `createOnceCommand` chỉ phát
  `start` một lần dù effect chạy đôi; `reset` cho phép chạy lại khi thử lại câu.
- `timed-frame.test.ts`: `shouldMountTimedFrame` false cho `UNTIMED`, phiên cũ (`timingMode` thiếu), item không có `timing`.
- `countdown.test.ts` (P4) bổ sung: deadline chênh ≤ 1 s khi tick 250 ms.

## Success criteria

- Tiêu chí 4 (kiểm tay ở P7): Repeat Sentence TIMED phát đề đúng một lần, không có nút phát lại, ghi âm tự bật
  sau chờ, tự dừng ở `responseSeconds` (±1 s), không có nút ghi lại.
- Reload ở giữa giai đoạn ghi âm khi chưa lưu → câu chạy lại từ đầu; reload sau khi lưu → mở ở Xong.
- UNTIMED không có `CountdownTimer` ở bất kỳ dạng bài nào.
- `typecheck`, `lint`, `test:unit` xanh.

## Quality and Testing State

- quality: not evaluated
- testing: not started
