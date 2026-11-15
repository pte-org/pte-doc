# Phase 2: Nghe lại bản ghi trên trang Review

Status: Completed

## Requirements

- Với câu Speaking đã ghi âm, Review hiện nút "Nghe lại" bên cạnh dòng "Đã ghi âm · N giây".
- Bấm nút thì tải link bản ghi, rồi hiện trình phát (có sóng âm) và tự phát.
- Lỗi tải link: thông báo ngắn và cho bấm thử lại. Không tải link khi mở trang, chỉ khi học viên bấm.

## Design Constraints

- Link bản ghi ngắn hạn, nên tải theo yêu cầu, không tải sớm cho mọi câu.
- Dùng `PromptAudioPlayer` có sẵn; không tạo trình phát mới.
- Chuỗi hiển thị nằm trong `common/i18n` (types, en, vi); không hiện lỗi thô của API.
- Không gọi `setState` sau khi component đã unmount.

## Related files

- `pte-practice/features/practice/ReviewRecordingPlayer.tsx` (mới)
- `pte-practice/features/practice/PracticeReviewView.tsx`
- `pte-practice/common/i18n/{types,en,vi}.ts`
- `pte-practice/tests/unit/features/practice/review-recording-player.test.tsx`

## Steps

1. `ReviewRecordingPlayer({ api, sessionId, itemId })` với bốn trạng thái: chưa tải, đang tải, sẵn sàng, lỗi.
2. `PracticeReviewView`: `SavedAnswerView` nhận `api` và `sessionId`, dùng player ở nhánh `audio`.
3. Thêm khóa `review.listenBack` và `review.playbackError`.
4. Test: trạng thái đầu hiện nút và không gọi API khi render.

## Quality/Testing State

- Test render tĩnh (không có jsdom); hành vi tải link kiểm bằng `tsc` và đọc code.
