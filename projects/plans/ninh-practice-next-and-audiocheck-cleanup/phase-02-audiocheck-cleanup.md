# Phase 2: Dọn timer và giọng đọc khi đóng kiểm tra âm thanh

Status: Completed

## Requirements

- Dialog bị unmount lúc đang phát thử: timer cập nhật tiến độ dừng ngay và giọng đọc bị hủy.
- Phát thử bình thường (bấm phát, dừng, xác nhận) giữ nguyên.

## Design Constraints

- Lưu timer bằng helper hủy được (không dùng biến cục bộ), dọn trong cleanup của `useEffect` khi unmount.
- `speechSynthesis.cancel()` chỉ gọi khi API có sẵn (trình duyệt hoặc môi trường không có thì bỏ qua).

## Related files

- `pte-practice/features/deviceCheck/one-shot-timer.ts` (thêm `createIntervalTimer`)
- `pte-practice/features/deviceCheck/AudioPlaybackCheckDialog.tsx`
- `pte-practice/tests/unit/features/deviceCheck/one-shot-timer.test.ts`

## Steps

1. `createIntervalTimer`: `start(callback, everyMs)` thay lần chạy cũ, `cancel()`, `pending`.
2. `AudioPlaybackCheckDialog`: dùng nó cho tiến độ, tự hủy khi giọng đọc hết; cleanup unmount hủy timer và giọng đọc.
3. Test với fake timers: chạy đều, hủy thì dừng, khởi động lại thay lần cũ.

## Quality/Testing State

- Test đơn vị cho helper; dialog chỉ kiểm bằng `tsc` và eslint (chưa có test render).
