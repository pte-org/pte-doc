# Phase 2: Toast (port từ @pte/ui) thay banner/notice

Preflight: Unit tests created and run: no (skipped_by_user) · ck:quality gate: skipped_by_user
Status: Completed · Story: Toast (P1) · FR-04, 05, 06, 10

## Requirements
- `common/components/Toast.tsx`: port `pte-web/packages/ui/src/components/Toast.tsx` — `ToastProvider`, `useToast`, `showToast(message, { tone: info|success|warning|error, title, durationMs = 5000, dismissible = true })`, tối đa 3 toast, portal vào `document.body`, góc trên phải (dưới header), `role="status"`/`"alert"` theo tone. Style bằng class CSS + token practice; icon `AppIcon` (`info`, `check`, `close`); nhãn nút đóng qua i18n.
- Mount `ToastProvider` trong `app/layout.tsx`.
- `usePracticeAccessToast()` (thay `AccessStatusBanner`): unlocked → toast success "Practice unlocked" **một lần mỗi phiên đăng nhập** (cờ sessionStorage, xoá khi đăng xuất); locked/unavailable/unknown → toast warning mỗi lần trạng thái đổi. Gọi một lần trong `StudentShell`.
- Xoá `AccessStatusBanner` và mọi chỗ dùng (Home, Study-Pack, Luyện đề, Tiến trình).
- Chuyển sang toast: `notice` lỗi trong `SessionTaskView` (error), "Hết giờ" `TimedTaskFrame` (warning), lỗi tải danh sách đề (error; giữ nút "Thử lại" trong trang). Giữ trong trang: trạng thái trống, `quiet-note`.

## Design Constraints
- API giống hệt `@pte/ui` để sau đổi import; comment đầu file ghi nguồn port.
- Không setState trong effect trái luật React Compiler: toast gọi từ effect là gọi hàm context (được phép), cờ "đã hiện" dùng ref/sessionStorage.
- i18n `toast.*` (en/vi) cho nhãn nút đóng.

## Related files
`common/components/{Toast.tsx,index.ts}`, `app/layout.tsx`, `features/practice/AccessStatusBanner.tsx` (xoá), `features/practice/useAccessToast.ts` (mới), `features/shell/StudentShell.tsx`, `features/practice/session/SessionTaskView.tsx`, `features/practice/timed/TimedTaskFrame.tsx`, `features/mockTests/MockTestListView.tsx`, các view có banner, `app/globals.css`, `common/i18n/*`

## Steps
1. Port Toast + CSS + test thuần cho hàng đợi (giới hạn 3, tự ẩn) nếu tách được logic.
2. Provider ở layout; hook access toast; xoá banner.
3. Chuyển notice/hết giờ/lỗi tải sang toast.
4. Build gate: tsc, eslint, vitest.

## Success Criteria
- `grep AccessStatusBanner` = 0; sau đăng nhập hiện đúng 1 toast "Practice unlocked", chuyển trang không hiện lại.

## Quality and Testing State
- Quality: skipped_by_user
- Testing: skipped_by_user
