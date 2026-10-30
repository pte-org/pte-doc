# Phase 4: Sóng âm cho audio đề + kiểm chứng trực quan

Preflight: Unit tests created and run: yes · ck:quality gate: skipped_by_user
Status: Completed (Prompt audio waveform reverted per user request, kiểm chứng hoàn tất) · FR-09

## Requirements
- `PromptMedia`: audio đề hiện `VoiceWaveform` + nút phát/tạm dừng + thời gian `mm:ss / mm:ss`; giữ thẻ `<audio>` ẩn làm nguồn phát (giữ hành vi phát một lần của chế độ tính giờ: `playPrompt`, `onPromptEnded`, `onPromptBlocked`, `onPromptError`).
- `usePromptPeaks(url)`: `fetch` → `AudioContext.decodeAudioData` → peaks 48 thanh; cache Map theo URL trong module; lỗi/CORS → sóng giả lập tất định (seed từ URL).
- Kiểm chứng (Playwright): ảnh 390 / 1280 / 1920 px × light/dark cho Trang chủ, Study-Pack, Luyện đề, phiên Read Aloud (ghi âm), phiên Listening (audio đề); kiểm tra toast sau đăng nhập; không cuộn ngang.
- Báo cáo `pte-doc/projects/plans/reports/261025-hung-practice-ui-polish-report.md` (ảnh trước/sau, gate, việc tồn). Cập nhật `plan.md`. Xoá `.playwright-mcp`.

## Design Constraints
- Không đổi hợp đồng phát-một-lần của `TimedTaskFrame`.
- Giải phóng `AudioContext` sau decode (`close()`).

## Related files
`features/practice/renderers/PromptMedia.tsx`, `features/practice/media/usePromptPeaks.ts` (+ test phần thuần), `app/globals.css`

## Steps
1. Hook peaks + fallback + test phần thuần (seed tất định).
2. Giao diện audio đề.
3. Kiểm chứng ảnh + báo cáo.

## Success Criteria
- Mọi tiêu chí trong spec §Success Criteria có bằng chứng; tsc/eslint/vitest xanh.

## Quality and Testing State
- Quality: skipped_by_user
- Testing: passed (3 new unit tests, 184 total passing, visual verification passed, build passed)
