# Plan: Nút Tiếp theo không kẹt ở câu unsupported, dọn timer và giọng đọc của kiểm tra âm thanh

Status: Ready
Date: 2026-11-15
Mode: Fast
Test: default
Owner/slug: Ninh — `ninh-practice-next-and-audiocheck-cleanup`
Scope: `pte-practice`, `pte-doc`
Related: [ninh-practice-review-and-labels](../ninh-practice-review-and-labels/plan.md)

## Mục tiêu

Hai điểm đã đối chiếu là đúng trong đợt review `pte-practice`:

1. `SessionTaskView` khóa nút Tiếp theo khi câu `unsupported` (renderer chưa hỗ trợ hoặc không có `fixture`). Một câu như vậy bị
   Bỏ qua rồi được xem lại từ lịch sử sẽ hiện Next nhưng không bấm được: học viên chỉ lùi được, không đi tiếp.
2. `AudioPlaybackCheckDialog`: `setInterval` là biến cục bộ của `play()`, không có cleanup khi unmount, và giọng đọc
   (`speechSynthesis`) không bị hủy. Rời trang giữa lúc phát thì giọng vẫn đọc nốt vài giây ở trang khác.

Không làm: `WorkspaceProgressProvider` và `StudentShell` (đã kiểm tra: provider chỉ mount khi đã đăng nhập, shell đã chặn frame
của `signed-out`).

## Scope challenge

### Đã có gì?

- `footerActions` (đợt trước) quyết định nút nào hiện; còn việc nút nào bị khóa vẫn là biểu thức nằm trong JSX của `SessionTaskView`.
- `deviceCheck/one-shot-timer.ts` và test fake timers cho `MicCheck`.
- Câu live chưa trả lời chỉ có Skip, không có Next; Next chỉ xuất hiện khi đã trả lời hoặc đang xem lịch sử.

### Tối thiểu là gì?

- Tách các cờ khóa của footer thành hàm thuần `footerDisabled` (cạnh `footerActions`), không còn `unsupported` ở `nextDisabled`, rồi test.
- Thêm `createIntervalTimer` cạnh `createOneShotTimer`, dùng trong dialog, và hủy cả giọng đọc khi unmount.

### Độ phức tạp

Fast. Rủi ro thấp; không có test render (chưa có jsdom), nên quy tắc quyết định được tách ra để test.

## Phases

- [x] Phase 1: Nút Tiếp theo không phụ thuộc `unsupported` — [phase-01-next-not-blocked.md](./phase-01-next-not-blocked.md)
- [x] Phase 2: Dọn timer và giọng đọc khi đóng kiểm tra âm thanh — [phase-02-audiocheck-cleanup.md](./phase-02-audiocheck-cleanup.md)

## Kết quả thực hiện (2026-11-15)

- Phase 1: `footerDisabled` trong `session/footer-actions.ts` thay các biểu thức khóa nút trong JSX của `SessionTaskView`;
  `unsupported` chỉ còn khóa Nộp, không khóa Next. 5 test mới (13 test trong file).
- Phase 2: `createIntervalTimer` trong `deviceCheck/one-shot-timer.ts`; `AudioPlaybackCheckDialog` dùng nó cho tiến độ phát
  và hủy cả timer lẫn `speechSynthesis` khi unmount (và khi dừng phát). 3 test mới với fake timers.

Kiểm chứng: `pte-practice` tsc sạch, 106 file và 829 test qua, eslint không lỗi (còn cảnh báo `locale` không dùng đã có sẵn).

Chưa làm: thử trên giao diện (cần một câu unsupported và trình duyệt có speech synthesis); test render cho dialog (cần jsdom); commit.
