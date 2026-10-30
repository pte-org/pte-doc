# Phase 1: Theme xám tối + bố cục rộng, cỡ chữ/thẻ lớn

Status: Completed · Stories: Layout rộng (P1), Dark Gray (P1) · FR-01, 02, 03, 07

## Requirements
- Dark token (khối `:root` tối đầu `app/globals.css`): `--bg #1e1e1e`, `--surface #252526`, `--surface-raised #2d2d30`, `--line #3c3c3c`, `--line-strong #4a4a4f`, `--text #e6e6e6`, `--muted #a0a0a0`, `--muted-strong #c8c8c8`; giữ `--accent`. Không màu nền nào < `#181818` (kể cả sidebar, modal, input).
- `.main-content` `width: min(100%, 1440px)`, padding 32px (16px ≤ 760px). Phiên làm bài/review tối đa 1100px; `.task-source-text`, `.session-task-prompt` `max-width: 75ch`.
- Thang cỡ: `html { font-size: 16px }` cơ sở; chữ thân 1rem, tiêu đề trang ≥ 1.75rem, thẻ padding ≥ 20px, nút ≥ 44px cao, icon thẻ kỹ năng 24px.
- Lưới: thẻ kỹ năng 4 cột ≥ 1280px / 2 cột / 1 cột ≤ 480px; danh sách đề và Study-Pack 2 cột ≥ 1280px; Tiến trình 2 cột (tổng quan | lịch sử) ≥ 1100px; Trang chủ: khối thẻ kỹ năng + gợi ý + danh sách dạng bài lấp chiều ngang.

## Design Constraints
- Chỉ sửa `app/globals.css` và className tối thiểu trong view; không đổi logic.
- Dùng token, không hard-code màu trong component.
- Light mode giữ nguyên màu, chỉ hưởng thay đổi kích thước/bố cục.
- Preflight: CSS tokens in globals.css (dark palette #1e1e1e, #252526, #2d2d30, #3c3c3c, #e6e6e6, #a0a0a0); layout scale max 1440px; font-size 16px base; responsive grid at 1280px / 1100px; verified no logic mutations and light mode colors preserved.

## Related files
`app/globals.css`, `features/home/HomeView.tsx`, `features/studyPack/StudyPackView.tsx`, `features/mockTests/MockTestListView.tsx`, `features/progress/ProgressView.tsx`, `features/catalog/SkillTaskList.tsx`

## Steps
1. Đổi token dark; quét `globals.css` tìm màu nền cứng tối (`#0`, `#1[0-7]`, `rgb(0 0 0` cho nền) → thay bằng token.
2. Bề rộng + thang cỡ chữ/khoảng cách.
3. Lưới responsive cho 4 trang.
4. Build gate: `npx tsc --noEmit`, `npx eslint features common app`.

## Success Criteria
- 1920px: nội dung 1440px canh giữa; 1280px: ≥ 90% chiều ngang trừ sidebar; không cuộn ngang ở 390px.
- Dark mode nền `#1e1e1e`, thẻ `#252526`.

## Quality and Testing State
- Quality: skipped_by_user
- Testing: skipped_by_user
