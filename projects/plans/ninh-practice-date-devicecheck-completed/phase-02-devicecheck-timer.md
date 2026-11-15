# Phase 2: Hủy timer kiểm tra micro khi đóng dialog

Status: Completed

## Requirements

- Đóng dialog trong lúc đang thu 5 giây thì không còn timer nào chạy sau đó, không tạo Blob URL, không gọi `stop()` trên bản ghi đã hủy.

## Design Constraints

- Lưu id timer trong `useRef`; cleanup khi unmount hủy timer và đặt `recorder.current = null` sau `cancel()`.
- Bản ghi bình thường (không đóng dialog) giữ nguyên hành vi.

## Related files

- `pte-practice/features/deviceCheck/DeviceCheckDialog.tsx`

## Steps

1. Thêm `timer = useRef<number | null>(null)`; gán khi `setTimeout`, xóa id khi timer chạy xong.
2. Cleanup unmount: `clearTimeout`, `recorder.current?.cancel()`, `recorder.current = null`.

## Quality/Testing State

- Không có test component cho `MicCheck` (cần Web Audio); kiểm bằng `tsc`, eslint và bộ test hiện có.
