# Phase 3: `VoiceWaveform` dùng chung cho ghi âm, nghe lại, kiểm tra mic

Preflight: Unit tests created and run: yes · ck:quality gate: skipped_by_user
Status: Reverted per user request · Giữ nguyên AudioWaveform gốc

## Requirements
- `features/practice/media/VoiceWaveform.tsx` thay `AudioWaveform.tsx` (xoá file cũ):
  - Props: `peaks: number[]`, `progress?: number (0..1)`, `live?: boolean`, `onSeek?: (fraction) => void`, `label: string`, `size?: "md" | "lg"`.
  - Kiểu tham chiếu (Adobe Stock "minimalist microphone icon with grey voice waveform bar"): ~48 thanh dọc bo tròn đầu (`rx` = nửa bề rộng), đối xứng quanh trục giữa, khoảng cách đều; chiều cao tối thiểu 8% để "im lặng" vẫn thấy chấm; màu `--wave-idle` (xám) và `--wave-active` (accent) cho phần đã phát/đang ghi.
  - `live`: icon mic tròn ở giữa (vòng accent nhạt), thanh hai bên nảy theo mức âm; chuyển cao độ mượt (CSS transition 80ms).
  - `onSeek`: bấm/kéo để tua, phím ←/→ tua 5%; `role="slider"` khi tua được.
- Logic thuần `voice-waveform.ts` (+ test): resample peaks về N thanh, chuẩn hoá, chiều cao tối thiểu, số thanh đã phát theo progress, đối xứng.
- Dùng ở: `SpeakingRecorder` (live + nghe lại), `DeviceCheckDialog` (kiểm tra mic).

## Design Constraints
- SVG thuần, không canvas, không thư viện; token màu mới `--wave-idle`, `--wave-active` cho cả light/dark.
- Giữ API seek/progress hiện có của `useRecordingPlayback`.

## Related files
`features/practice/media/{VoiceWaveform.tsx,voice-waveform.ts,voice-waveform.test.ts,AudioWaveform.tsx (xoá),waveform.ts}`, `features/practice/renderers/SpeakingRecorder.tsx`, `features/deviceCheck/DeviceCheckDialog.tsx`, `app/globals.css`

## Steps
1. Logic thuần + test.
2. Component + CSS token.
3. Thay ở recorder và kiểm tra mic; xoá `AudioWaveform`.
4. Build gate: tsc, eslint, vitest.

## Success Criteria
- Recorder và kiểm tra mic hiện cùng kiểu sóng; nghe lại đổi màu theo tiến trình; tua bằng chuột và phím.

## Quality and Testing State
- Quality: skipped_by_user
- Testing: passed (5 new unit tests, 181 total passing)
