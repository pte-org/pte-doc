# Phase 4: Frontend — tách `PracticeSessionView`, common components, contract

Status: Not started
User stories: US-8 (UI dùng component chung, view đạt chuẩn kích thước), US-9 (`ProgressRing`, `CountdownTimer`);
nền cho US-1, US-3, US-6
Tiêu chí §7: 9 (`tsc`, eslint, vitest xanh)

## Requirements

- Tách `features/practice/PracticeSessionView.tsx` (501 dòng) thành component/hook **không đổi hành vi**
  (vẫn có Overview, đồng hồ cũ — gỡ ở P5) để phase sau thêm tính năng mà không vượt chuẩn.
- Tạo common components một lần ở `common/components`, props bám theo `@pte/ui` để sau chỉ đổi import:
  `Modal`, `Stepper`, `ProgressRing`, `CountdownTimer`.
- Chuyển `AppIcon` sang Material Design Icons qua `@mdi/js` (spec §5.4 mục 4), **giữ nguyên API**
  `AppIcon name size` và kiểu `IconName`; thêm icon mới cho trình ghi âm/đồng hồ.
- Cập nhật contract/API client cho các trường P1–P3: `timingMode`, `questionCount`, `task.timing`,
  `catalogTask.timedAvailable/timedUnavailableReason`, `startSession` nhận `timingMode`/`questionCount`,
  `saveDraft`, `getRecordingPlayback`.

## Design Constraints

- File ≤ 300 dòng, component ≤ 150 dòng, không inline style mới, không chuỗi cứng (mọi chữ qua
  `common/i18n` — thêm key vào `types.ts`, `en.ts`, `vi.ts` cùng lúc), không thêm thư viện —
  ngoại lệ duy nhất là `@mdi/js` (chỉ path SVG; ghim phiên bản chính xác, import từng icon `mdiXxx`
  để tree-shaking, không dùng `@mdi/react`/icon font). Không dùng `pearsonicons`/`memorangicons`.
- CSS chỉ ở `app/globals.css`, dùng token theme (`--accent`, `--line`, `--line-strong`, `--surface`,
  `--red`, `--green`, `--muted`…) và có biến thể dark/light như các khối hiện có; không tạo class "na ná"
  `.button`, `.state-badge`, `.session-progress`.
- `contracts.ts` đã 499 dòng: **không** làm dài thêm — chuyển type + normalizer của session/task sang
  file mới và re-export từ `contracts.ts` để import cũ không gãy.
- Props bám `@pte/ui`: `Modal` (`open`, `onClose`, `title`, `titleIcon?`, `children`, `footer?`,
  `size?: "sm"|"md"|"lg"|"xl"`, `closeOnBackdropClick?`, `isDismissDisabled?`) theo
  `pte-web/packages/ui/src/components/Modal.tsx`; `Stepper` (`steps: {id,label,description?}[]`, `currentStep`)
  theo `Stepper.tsx`. Không chép code Tailwind của `pte-web`.
- `ProgressRing`: dựng lại hình học từ `C:\Users\Hung Pham\Downloads\pearson-inline-icons.json` (chỉ đọc):
  size/thickness mẫu 90/10, 56/6, 48/5, 40/5; biến thể `progress` (vòng nền + cung `value/max`),
  `segmented` (4 đoạn bo tròn — đang tải / chưa có dữ liệu), `empty` (chỉ vòng nền). Không dùng
  `rgb(81,46,171)`, không chép `<div>` lồng trong `<svg>`, không style inline, không class RN Web.
- Vitest chạy môi trường node (không jsdom) → logic phải nằm ở hàm thuần để test được.

## Related files

- `pte-practice/features/practice/PracticeSessionView.tsx`
- `pte-practice/features/practice/session/` (mới): `useSessionLifecycle.ts`, `useSessionMutations.ts`,
  `useHeartbeat.ts`, `SessionStateCards.tsx`, `SessionResultCard.tsx`, `SessionTaskView.tsx`,
  `ConfidencePanel.tsx`, `SessionOverview.tsx` (tạm, xoá ở P5), `session-draft.ts`, `session-draft.test.ts`,
  `background-mutation.ts`, `background-mutation.test.ts`
- `pte-practice/common/components/{Modal,Stepper,ProgressRing,CountdownTimer}.tsx`, `index.ts`,
  `ring-geometry.ts`, `ring-geometry.test.ts`, `countdown.ts`, `countdown.test.ts` (mới)
- `pte-practice/common/components/AppIcon.tsx`, `icon-paths.ts` (mới, bảng `IconName → path MDI`),
  `icon-paths.test.ts` (mới), `pte-practice/package.json` + `package-lock.json` (`@mdi/js`)
- `pte-practice/features/practice/contracts.ts`, `session-contracts.ts` (mới), `contracts.test.ts`
- `pte-practice/features/practice/api.ts`
- `pte-practice/common/i18n/{types,en,vi}.ts`, `pte-practice/app/globals.css`
- Tham chiếu: `pte-web/packages/ui/src/components/Modal.tsx`, `Stepper.tsx`

## Steps

1. Chuyển helper thuần ra `session/session-draft.ts`: `parsePayload`, `effectiveDraft`,
   `effectiveConfidence`, `hasAnswer`, `progressFor`, `currentTaskPosition`, `sessionErrorMessage`.
2. Tách hook: `useSessionLifecycle` (loadSession, init effect, `hydrateDraft`, retry),
   `useSessionMutations` (`runMutation`, begin/submit/skip/saveAndExit, idempotency key map,
   `reloadAfterHeartbeatFailure`), `useHeartbeat` (interval 15 s, `heartbeatInFlight/Promise/SyncRequired`).
   Thêm `runBackgroundMutation(scope, action): Promise<{ ok: true; session } | { ok: false; error }>` trong
   `useSessionMutations` (red-team #1): chờ `heartbeatPromise` và `reloadAfterHeartbeatFailure` y như `runMutation`,
   đặt `mutationInFlight` để heartbeat không chen vào, dùng lại idempotency key theo scope khi thử lại, khi thành công
   cập nhật `sessionRef` + `version` và dispatch `mutation_succeeded` **không** `hydrateDraft` lại item đang làm;
   **không** dispatch `mutation_started`/`failed` (màn hình không chuyển sang submitting/error), trả lỗi cho
   caller để trình ghi âm vào `SAVE_FAILED` và giữ blob trong bộ nhớ. P5 bước 8 và P6 bước 5 gọi `saveDraft` qua hàm này.
   Logic tách thành hàm thuần `background-mutation.ts` (nhận các phụ thuộc làm tham số) để test được trong node.
3. Tách view: `SessionStateCards` (loading/error/exited/completed), `SessionResultCard` (ScoreView),
   `SessionTaskView` (thanh tiến độ + header + task card + footer), `ConfidencePanel`, `SessionOverview`.
   `PracticeSessionView.tsx` chỉ còn ghép (< 120 dòng). Chạy lại tay luồng cũ để xác nhận không đổi hành vi.
4. `ring-geometry.ts`: `ringGeometry(size, thickness)` → `{ radius, circumference, center }`;
   `progressDash(value, max, circumference)` → `strokeDasharray/offset` (kẹp 0..1, `max <= 0` → 0);
   `segmentDashes(circumference, segments = 4, gapRatio)`; preset `RING_PRESETS = { lg: [90,10], md: [56,6], sm: [48,5], xs: [40,5] }`.
5. `ProgressRing.tsx`: props `value?`, `max?`, `size?: number | keyof RING_PRESETS`, `thickness?`,
   `variant?: "progress"|"segmented"|"empty"`, `tone?: "accent"|"green"|"amber"|"red"|"muted"`,
   `label: string` (aria), `children?` (nội dung giữa vòng). SVG `role="img"` hoặc `role="progressbar"` với
   `aria-valuenow/min/max` khi `progress`; `stroke-dasharray` qua thuộc tính SVG (không phải style);
   màu qua class `progress-ring-tone-*`; `segmented` có class xoay chậm khi `prefers-reduced-motion: no-preference`.
6. `countdown.ts`: `remainingSeconds(deadlineMs, nowMs)` (làm tròn lên, không âm), `formatClock(seconds)` (`m:ss`),
   `fractionRemaining(deadlineMs, totalSeconds, nowMs)`.
7. `CountdownTimer.tsx`: props `deadlineMs: number | null`, `totalSeconds: number`, `label: string`,
   `onElapsed?`, `size?`, `warnBelowSeconds?` — render `ProgressRing` (variant `progress`, tone `red` khi dưới
   ngưỡng, kèm chữ "sắp hết" không chỉ bằng màu) + số giây ở giữa, `role="timer"`, `aria-live="off"` +
   thông báo polite ở mốc 10 s. Tick bằng `requestAnimationFrame`/interval 250 ms, tính từ timestamp, gọi `onElapsed` đúng một lần.
8. `Modal.tsx`: overlay + `role="dialog"` `aria-modal` `aria-labelledby`, Escape/backdrop đóng (trừ khi
   `isDismissDisabled`), trả focus về phần tử mở, khoá cuộn `body` bằng class; `Stepper.tsx`: `<ol>`
   với trạng thái `done/current/upcoming` (icon check `AppIcon` + số thứ tự, `aria-current="step"`).
9. Export cả 4 từ `common/components/index.ts`; thêm CSS `.modal-*`, `.stepper-*`, `.progress-ring-*`, `.countdown-*`.
10. Contract: tạo `session-contracts.ts` chứa `PracticeTimingMode`, `PracticeItemTiming`, `PracticeSession`,
    `PracticeTaskResponse`, `normalizePracticeSessionResponse` (+ `timingMode` mặc định `"UNTIMED"` khi thiếu,
    `questionCount: number | null`, `timing` null-safe, gồm `preListenSeconds | null`, `preRecordSeconds`, `responseSeconds` —
    `preRecordSeconds` là thời gian chờ trước khi ghi theo template, **không** phải `prepSeconds` tổng như `PinnedItem` của đề thi, red-team #7); `PracticeCatalogTask` thêm `timedAvailable` (mặc định
    `false` khi thiếu) và `timedUnavailableReason`. Re-export từ `contracts.ts`.
11. Icon: `npm install --save-exact @mdi/js` (phiên bản ổn định, ≥ 2 tuần tuổi); tạo `icon-paths.ts` ánh xạ
    **mọi** `IconName` hiện có sang path MDI theo bảng spec §5.4 mục 4 (glyph còn lại chọn gần nghĩa) + icon mới
    `record`, `stop`, `pause`, `retake`, `timer`; `AppIcon` render `<svg viewBox="0 0 24 24" fill="currentColor"
    aria-hidden>` với `<path d={...}>`, giữ prop `size` và `className`. Không đổi chỗ gọi nào; kiểm tay Home,
    Practice tests, Progress, Study-Pack, shell ở theme sáng/tối.
12. `api.ts`: `startSession` body thêm `timingMode?`, `questionCount?`; `saveDraft(publicId, itemPublicId,
    { clientVersion, payload, confidence }, key)` → `POST .../items/{id}/draft`; `getRecordingPlayback(publicId, itemPublicId)`
    → `GET .../items/{id}/recording` trả `{ url, expiresInSeconds, durationSeconds }`.

## Tests to add

- `session/session-draft.test.ts`: `hasAnswer` (mảng rỗng, chuỗi trắng, object), `effectiveDraft` ưu tiên draft
  local đúng item, `progressFor`/`currentTaskPosition` biên, `sessionErrorMessage` 409/410.
- `common/components/ring-geometry.test.ts`: chu vi đúng với 90/10, `progressDash` 0/50/100 % và kẹp `value > max`,
  `max = 0`, 4 đoạn chia đều có khe.
- `common/components/countdown.test.ts`: làm tròn lên, không âm sau deadline, `formatClock(75) === "1:15"`, fraction.
- `common/components/icon-paths.test.ts`: mọi `IconName` (kể cả icon mới) có path MDI không rỗng — bắt lỗi
  thêm `IconName` mà quên ánh xạ.
- `session/background-mutation.test.ts` (red-team #1): chờ heartbeat đang chạy rồi mới gửi; heartbeat lỗi → reload
  session rồi gửi với `version` mới; thành công cập nhật `sessionRef.version`; lỗi trả `{ ok: false }` và **không**
  gọi dispatch `mutation_started`/`failed`; gọi lại cùng scope dùng lại idempotency key.
- `contracts.test.ts`: session thiếu `timingMode` → `"UNTIMED"`; `timing` được giữ với đúng tên
  `preListenSeconds`/`preRecordSeconds`/`responseSeconds` (không có `prepSeconds`); catalog task thiếu
  `timedAvailable` → `false`; response playback được normalize.
- Giữ xanh toàn bộ test cũ (`session-state.test.ts`, `renderer-registry.test.tsx`…).

## Success criteria

- `npm run typecheck`, `npm run lint`, `npm run test:unit` xanh; mọi file đụng tới ≤ 300 dòng, component ≤ 150.
- Luồng phiên hiện tại chạy y như trước khi tách (kiểm tay một câu Read Aloud và một câu MC).
- 4 common component render được ở cả theme sáng/tối, không có style inline mới.

## Quality and Testing State

- quality: not evaluated
- testing: not started
