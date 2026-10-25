# Phase 5: Frontend — hộp chọn chế độ, luồng không tính giờ, trình ghi âm + sóng âm, ProgressRing

Status: Completed (fast mode, uncommitted)
User stories: US-1, US-2, US-5, US-7, US-9 (vòng ở Home, Progress, vòng câu x/y)
Tiêu chí §7: 1, 3, 5, 6, 7

## Requirements

- Bấm một dạng bài ở Home / Practice tests / Skill list luôn mở hộp chọn: Tính giờ / Không tính giờ,
  số câu 5 / 10 / Tất cả (= 50), nút Bắt đầu. TIMED bị vô hiệu kèm lý do khi `timedAvailable = false`.
- Nhớ chế độ + số câu theo từng dạng bài trong `localStorage` (US-7).
- Bắt đầu = `start` (có `timingMode`, `questionCount`) rồi `begin` ngay; bỏ màn Overview; phiên `OVERVIEW`
  cũ khi resume cũng tự `begin`. Gỡ đồng hồ chung (`session-timer`, `formatRemaining`, interval `clockNow`).
- Chế độ không tính giờ: không có đếm ngược nào; audio đề có trình phát đầy đủ.
- Trình ghi âm mới (thay `RecordingRenderer`): Ghi âm / Dừng, sóng sống khi ghi, sóng tĩnh + ▶/⏸ + tua khi
  đã ghi, `0:03 / 0:07`, ↺ Ghi âm lại (chỉ khi `allowRetake`), trần 120 s tự dừng + báo, "Đang lưu…",
  lỗi lưu giữ bản ghi + nút "Lưu lại". Mỗi bản ghi upload xong được lưu qua `saveDraft` (bản cuối thắng).
- Sau reload: bản ghi đã lưu phát lại được và có sóng (link playback P3 → `fetch` → `decodeAudioData`);
  lỗi tải/CORS/`decodeAudioData` → ẩn sóng, **vẫn phát được** bằng `<audio>`. Ghi âm cần Web Audio (WAV được mã hoá
  từ PCM của `AudioContext`): trình duyệt không có Web Audio → báo `UNSUPPORTED`, không ghi được. Đây là **lệch so với
  spec §4** ("thiếu Web Audio vẫn ghi/nghe lại được") — ghi vào report P7 để Hung duyệt (red-team #6).
- US-9: `ProgressRing` thay `progress-empty-ring` ở Progress; vòng nhỏ trên 4 ô kỹ năng ở Home; vòng câu
  x/y ở thanh tiến độ phiên.

## Design Constraints

- Dùng lại: `.button*`, `.state-badge*`, `.reference-card`, `AppIcon`, `ErrorState`, `uploadPracticeRecording`,
  `startWavRecording`, `renderer-registry`, `PromptMedia`, `ConfidenceHint`; common `Modal`, `ProgressRing` từ P4.
- `audio-recorder.ts` chỉ được **mở rộng** (không viết recorder thứ hai): giữ WAV/ScriptProcessor vì backend
  chỉ nhận `audio/wav`; thử `AudioContext({ sampleRate: 16000 })`, lỗi thì fallback mặc định.
- `AudioWaveform` ở `common/components`: SVG `<rect>` với `height`/`y` là thuộc tính SVG, màu qua class
  (`waveform-bar`, `waveform-bar-played`, `waveform-live`), `role="slider"` + phím ←/→ để tua; sóng phải
  phản ánh biên độ thật (im lặng gần phẳng).
- Chuỗi `RECORDING_TEXT` cứng ở `media/constants.ts` chuyển sang i18n (`recording.*`) cho component mới.
- localStorage bọc try/catch; thiếu/hỏng → mặc định UNTIMED + 10.
- Progress/Home: **không đổi logic/số liệu** (spec §2). `PracticeProgressEntry` không có section. Quyết định của
  Hung (red-team #8, 2026-10-24), không bịa số:
  - Mọi vòng **tiến độ theo kỹ năng** ở Progress dùng biến thể `empty` cho tới khi có spec dữ liệu tiến độ theo
    kỹ năng (`segmented` chỉ khi đang tải).
  - Vòng đang hiện `latest.answeredItemCount/totalItemCount` giữ số liệu đó nhưng đổi nhãn thành **"Phiên gần nhất"**
    (i18n `progress.latestSession`, en "Latest session"), không còn gắn nhãn "Speaking"; không có phiên → `empty`.
  - Ô kỹ năng Home = số dạng bài sẵn sàng / tổng dạng bài của kỹ năng đó (từ catalog), nhãn aria nói rõ ý nghĩa;
    catalog đang tải → `segmented`.

## Related files

- `pte-practice/features/practice/mode/PracticeModeDialog.tsx`, `usePracticeStart.ts`, `mode-preference.ts`,
  `mode-preference.test.ts` (mới)
- `pte-practice/features/home/HomeView.tsx`, `features/catalog/CatalogGrid.tsx`, `CatalogCard.tsx`,
  `SkillTaskList.tsx`, `PracticeTestsView.tsx`, `features/progress/ProgressView.tsx`
- `pte-practice/features/practice/session/*` (từ P4), `PracticeSessionView.tsx`, `session-state.ts`
- `pte-practice/features/practice/media/audio-recorder.ts`, `waveform.ts`, `waveform.test.ts` (mới), `media/api.ts`, `media/constants.ts`
- `pte-practice/features/practice/recorder/SpeakingRecorder.tsx`, `useRecorder.ts`, `useRecordingPlayback.ts`,
  `recorder-state.ts`, `recorder-state.test.ts` (mới)
- `pte-practice/common/components/AudioWaveform.tsx` (mới)
- `pte-practice/features/practice/renderers/{RendererTypes.ts,renderer-registry.tsx,RecordingRenderer.tsx,PromptMedia.tsx,TaskRenderer.tsx}`
- `pte-practice/common/i18n/{types,en,vi}.ts`, `app/globals.css`

## Steps

1. `mode-preference.ts`: `readModePreference(taskCode)` / `writeModePreference(taskCode, { timingMode, questionCount })`,
   key `pte.practice.mode.<TASK_CODE>`, xác thực giá trị (`questionCount ∈ {5,10,50}`), mọi truy cập trong try/catch.
2. `PracticeModeDialog` (dùng `Modal`): tiêu đề = kỹ năng + tên dạng bài, 2 thẻ lựa chọn dạng `radiogroup`
   (mô tả ngắn từ i18n), nhóm số câu, nút Bắt đầu; TIMED `aria-disabled` + `timedUnavailableReason` đã dịch.
3. `usePracticeStart()` trả `{ openFor(task), dialog }`; thay `handleStartIntent` ở `HomeView` và `CatalogGrid`
   (Skill list đi qua `onStartIntent` sẵn có). Bắt đầu → ghi preference → `router.push(practiceSession?task=X&mode=TIMED&count=10)`.
4. Session: `useSessionLifecycle` đọc `mode`/`count` từ query, đưa vào `startSession`, idempotency key theo
   `task|mode|count`; nhận phiên `OVERVIEW` (mới hoặc cũ) → gọi `begin` ngay. Xoá `SessionOverview`, `session-timer`,
   `formatRemaining`, `clockNow`, i18n `ui.sessionTimeLimit`/`ui.sessionTimeRemaining`; `session-state.ts` coi
   `OVERVIEW` là "đang bắt đầu" (loading) thay vì phase riêng.
5. Thanh tiến độ phiên: thay chỉ số `x/y` bằng `ProgressRing size="xs"` (`value = vị trí`, `max = totalItemCount`,
   chữ `x/y` ở giữa); thay `style={{ width }}` của `.session-progress` bằng thuộc tính `value` trên `<progress>`
   hoặc giữ nguyên nếu tốn công — không thêm inline style mới.
6. `waveform.ts` (thuần): `chunkPeak(chunk)`, `computePeaks(chunks, bars)` (max |x| theo cột, chuẩn hoá 0..1
   theo trần cố định để im lặng vẫn phẳng), `peaksFromChannelData(data, bars)`, `appendLivePeak(peaks, value, maxBars)`.
7. `audio-recorder.ts`: `startWavRecording({ onLevel?, sampleRate? })`; `onaudioprocess` gọi `onLevel(chunkPeak)`;
   `stop()` trả `{ blob, peaks, durationSeconds }` (duration = số mẫu / sampleRate).
   Red-team #3: `durationSeconds` gửi lên upload và ghi vào payload phải là **số nguyên** kẹp `[1, 120]`
   (`clampRecordingDuration(raw) = min(120, max(1, round(raw)))`) — backend từ chối số lẻ/ngoài khoảng
   (`PracticeAnswerValidationService` dòng ~180–187, `CloudinaryMediaService` dòng ~192–194); `peaks`/hiển thị
   vẫn dùng giá trị thực.
8. `recorder-state.ts` (reducer thuần): `idle → recording → saving → recorded | saveFailed`, `error`; sự kiện
   `RETAKE` chỉ hợp lệ khi `allowRetake`; `SAVE_RETRY` dùng lại blob đang giữ. `useRecorder` nối reducer với
   recorder, upload (`uploadPracticeRecording`), `onSaved(media)` → `onChange` + `saveDraft` gọi qua
   `runBackgroundMutation` của P4 (red-team #1): không đổi phase màn hình, chờ heartbeat, cập nhật `version`;
   `{ ok: false }` → `SAVE_FAILED`, blob giữ trong bộ nhớ cho "Lưu lại"; auto-stop ở 120 s.
9. `useRecordingPlayback`: nguồn = object URL (bản vừa ghi) hoặc `getRecordingPlayback` (bản trên server);
   `HTMLAudioElement` cho play/pause/seek/`timeupdate`; decode lấy peaks khi có thể; thu hồi object URL khi đổi/unmount.
10. `AudioWaveform` (props `peaks`, `progress?`, `live?`, `onSeek?`, `label`, `valueText?`) và
    `SpeakingRecorder` (props `allowRetake`, `maxSeconds`, + các prop renderer) ≤ 150 dòng; đăng ký cho 7 renderer
    ghi âm trong `renderer-registry.tsx`, xoá `RecordingRenderer.tsx`. `TaskRendererProps` thêm `allowRetake?`, `onPersistDraft?`, `onLoadPlayback?`.
11. `PromptMedia`: thêm `onMediaError` → session gọi lại `getSession` một lần để lấy link mới (D3 trong plan).
    Red-team #4: `useSessionLifecycle` lưu `mediaFetchedAtMs` mỗi lần nhận session; trước khi vào một item mới
    (sau answer/skip) nếu `now - mediaFetchedAtMs > PROMPT_MEDIA_TTL_MS - 60_000` thì `getSession` trước rồi mới
    render item — hàm thuần `isPromptMediaStale(fetchedAtMs, nowMs)` trong `session-draft.ts`.
12. Progress: thay `progress-empty-ring` bằng `ProgressRing size="lg"` nhãn "Phiên gần nhất" (value/max = answered/total
    của phiên gần nhất, không có → `empty`); các vòng theo kỹ năng render `variant="empty"` kèm chữ "Chưa có dữ liệu";
    xoá CSS cũ. Home: thêm `ProgressRing size="xs"` vào `.skill-tile` (ready/total task types, `segmented` khi catalog đang tải).
13. i18n vi/en cho hộp chọn, trình ghi âm, sóng âm (aria), lỗi lưu, "Lưu lại", nhãn vòng.

## Tests to add

- `mode-preference.test.ts`: đọc mặc định khi trống/hỏng/`localStorage` ném lỗi; ghi rồi đọc theo từng task; giá trị lạ bị bỏ.
- `waveform.test.ts`: im lặng → mọi cột ≈ 0; sóng sin biên độ 0.5 → cột ≈ 0.5; số cột đúng `bars`; dữ liệu ngắn hơn số cột; `appendLivePeak` cắt cửa sổ.
- `recorder-state.test.ts`: luồng ghi → lưu → recorded; `RETAKE` bị bỏ khi `allowRetake=false`; lưu lỗi giữ blob và
  `SAVE_RETRY` không cần ghi lại; ghi lại thay media (payload gửi `saveDraft` là bản cuối).
- `audio-recorder.test.ts`: `encodeWav` + duration tính từ số mẫu; `clampRecordingDuration` (0.4 → 1, 7.5 → 8,
  119.6 → 120, 130 → 120, NaN → 1) và payload/upload nhận số nguyên (red-team #3).
- `waveform.test.ts` thêm `seekFraction(clickX, width)` (0, giữa, ngoài biên kẹp 0..1, width 0) — tiêu chí 6 (red-team #10);
  `AudioWaveform` dùng hàm này cho click và phím.
- `session-draft.test.ts` thêm `isPromptMediaStale` (red-team #4).
- `recorder-state.test.ts` thêm: `saveDraft` trả `{ ok: false }` → `saveFailed`, blob còn, `SAVE_RETRY` gửi lại đúng blob.
- `session-state.test.ts`: phiên `OVERVIEW` không còn trả phase `overview`.
- `progress-rings.test.ts` (thuần): `latestSessionRing(loadState, latest)` → `segmented` khi tải, `empty` khi không có
  phiên, `progress` answered/total khi có; `skillProgressRing()` luôn `empty` (red-team #8); `skillTileRing(section)` =
  ready/total dạng bài, `max = 0` → `empty`.

## Success criteria

- Tiêu chí 1: mọi nút bắt đầu mở hộp chọn; Bắt đầu vào thẳng câu 1. Tiêu chí 3: không có phần tử đếm ngược ở UNTIMED.
- Tiêu chí 5–7: ghi → nghe lại → ghi lại; `savedPayload.mediaPublicId` = bản cuối; upload lỗi không mất bản ghi.
- Reload giữa chừng: bản ghi đã lưu phát lại được; decode lỗi → ẩn sóng nhưng vẫn phát (red-team #6).
- Lưu draft lỗi không đưa màn hình sang trạng thái lỗi phiên; bản ghi còn và "Lưu lại" dùng được.
- Progress/Home hiển thị `ProgressRing` đúng 3 biến thể, không bịa số liệu: vòng kỹ năng `empty`, vòng "Phiên gần nhất"
  đúng answered/total, ô Home đúng ready/total.
- `typecheck`, `lint`, `test:unit` xanh; file/component trong giới hạn.

## Quality and Testing State

- quality: not evaluated
- testing: not started
