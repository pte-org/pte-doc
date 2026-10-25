# Plan: Làm đẹp UI pte-practice — layout rộng, sóng âm tối giản, toast, dark mode xám

Status: Ready
Date: 2026-10-25
Mode: Hard (bỏ research: domain quen thuộc; tự rà soát thay agent review để tiết kiệm token)
Test: default
Owner/slug: Hung — `261025-hung-practice-ui-polish`
Scope: chỉ `pte-practice` (đọc `pte-web/packages/ui/src/components/Toast.tsx` làm nguồn port)
Related: [spec](./spec.md), [brainstorm](../reports/261025-hung-practice-ui-polish-brainstorm.md)

Làm trên nhánh `hung/feat/practice-revamp`, trên các thay đổi chưa commit hiện có. Không commit khi Hung chưa bảo.

## Phases

- [x] Phase 1: Theme xám tối + bố cục rộng, cỡ chữ/thẻ lớn — [phase-01-theme-and-layout-scale.md](./phase-01-theme-and-layout-scale.md) [quality: skipped_by_user; decision: user_confirmed_skip]
- [x] Phase 2: Toast (port từ @pte/ui) thay banner/notice — [phase-02-toast.md](./phase-02-toast.md) [quality: skipped_by_user; testing: skipped_by_user]
- [x] Phase 3: Sóng âm ghi âm/nghe lại — [phase-03-voice-waveform.md](./phase-03-voice-waveform.md) [giữ nguyên AudioWaveform gốc theo yêu cầu]
- [x] Phase 4: Kiểm chứng trực quan — [phase-04-prompt-waveform-and-verification.md](./phase-04-prompt-waveform-and-verification.md) [quality: skipped_by_user; testing: passed]

## Phase → user story

| Phase | Stories (spec) | FR |
|---|---|---|
| 1 | Layout rộng (P1), Dark Gray (P1) | FR-01, 02, 03, 07 |
| 2 | Toast (P1) | FR-04, 05, 06, 10 |
| 3 | Sóng âm ghi/nghe lại/kiểm tra mic (P1) | FR-08, 10 |
| 4 | Sóng âm audio đề (P2) + mọi tiêu chí thành công | FR-09 |

## Architecture decisions
- **A1.** Chỉ đổi CSS token + vài class bố cục; không thêm thư viện UI, không Tailwind trong component mới.
- **A2.** Toast port giữ đúng API `@pte/ui` (`ToastProvider`, `useToast().showToast(message, options)`), mount trong `app/layout.tsx` (bao cả trang đăng nhập).
- **A3.** `VoiceWaveform` thay hẳn `AudioWaveform` (xoá file cũ), một component cho 4 chỗ; logic thuần (tính thanh, tiến trình) tách ra file `.ts` có test.
- **A4.** Đỉnh sóng audio đề tính bằng `decodeAudioData`, cache theo URL trong module; lỗi → sóng giả lập tất định theo URL (cùng đề luôn cùng hình).

## Risks
- **R1** Phóng to làm vỡ bố cục ở 1280px/mobile → phase 4 chụp 3 mốc × 2 theme.
- **R2** Bản sao Toast lệch với `@pte/ui` → comment ghi nguồn + giữ API.
- **R3** Audio đề Cloudinary chặn CORS khi `fetch` → fallback sóng giả lập; audio vẫn phát qua thẻ `<audio>`.
- **R4** Toast "Practice unlocked" lặp khi đổi trang → khoá theo sessionStorage mỗi phiên đăng nhập.
