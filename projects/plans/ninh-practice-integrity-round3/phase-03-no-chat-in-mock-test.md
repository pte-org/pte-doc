# Phase 3: Tắt Pip trong Mock Test

Status: Completed

## Requirements

- Trong phiên `MOCK_TEST` không có khung chat, không có phím tắt mở chat, Pip và mục "practice companion" không mở được chat.
- Đề bài không được gửi vào ngữ cảnh chat trong lúc thi thử.
- Các phiên luyện tập khác giữ nguyên.

## Design Constraints

- `ChatLayout` nhận prop `enabled` (mặc định `true`); khi `false` chỉ render `children`, không gọi quota, không gắn phím tắt.
- `ChatLauncherContext` không có giá trị khi tắt; `useChatLauncher()` trả `null` và các nơi dùng đã xử lý được.
- Chỉ ẩn ở giao diện: backend chat không biết ngữ cảnh phiên nên không cưỡng chế được.

## Related files

- `pte-practice/features/chat/ChatLayout.tsx`
- `pte-practice/features/practice/PracticeSessionView.tsx`
- `pte-practice/tests/unit/features/chat/` (test mới nếu có sẵn thư mục test chat)

## Steps

1. Thêm `enabled` vào `ChatLayout`; nếu `!CHAT_ENABLED || !enabled` trả `children`.
2. `PracticeSessionView` truyền `enabled={session.kind !== "MOCK_TEST"}`.
3. Test `ChatLayout` với `enabled={false}`.

## Quality/Testing State

- Test đơn vị; chạy `tsc` và eslint.
