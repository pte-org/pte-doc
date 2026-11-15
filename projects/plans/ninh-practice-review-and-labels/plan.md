# Plan: Nhãn và icon đúng ở trang Review, nghe lại bản ghi Speaking, dọn prop thừa

Status: Ready
Date: 2026-11-15
Mode: Fast
Test: default
Owner/slug: Ninh — `ninh-practice-review-and-labels`
Scope: `pte-practice`, `pte-doc`
Related: [ninh-practice-date-devicecheck-completed](../ninh-practice-date-devicecheck-completed/plan.md)

## Mục tiêu

Bốn điểm đã đối chiếu từ đợt review `pte-practice`:

1. Trang Review đánh số ô trống của Fill in the Blanks từ 0 (`0. answer`), trong khi `blanks` và `order` đánh từ 1.
4. `SkillTaskList` luôn đặt icon `reading` trong vòng tiến độ của mọi kỹ năng.
5. Trang Review chỉ ghi "Đã ghi âm bài làm · N giây", chưa nghe lại được dù `api.getRecordingPlayback` đã có.
6. `HomeView` truyền `contentState` luôn là `"loading"` khi không lỗi; `DashboardTaskTypes` đã ghi đè theo `ready` nên không sai kết quả, chỉ gây khó hiểu.

Không làm: điểm 2 (phân loại section của 4 dạng bài, quyết định sản phẩm, chờ bạn chốt) và điểm 3 (câu hướng dẫn Read Aloud
có chủ ý, đã có test khóa).

## Scope challenge

### Đã có gì?

- `iconForSection` (icon-mapping.ts) đã dùng ở đầu nhóm trong cùng `SkillTaskList`.
- `api.getRecordingPlayback(sessionId, itemId)` trả link ngắn hạn tới bản ghi của chính học viên, hoạt động ở mọi trạng thái phiên
  (kể cả `COMPLETED`), không cần kiểm tra quyền sử dụng.
- `PromptAudioPlayer` (trình phát có sóng âm, hỗ trợ `autoPlay`) đã dùng ở `SpeakingRecorder` và kiểm tra micro.
- Test `review-answer.test.ts` đã có cho `describeSavedAnswer`.

### Tối thiểu là gì?

- Ba chỗ sửa một dòng (1, 4, 6) kèm cập nhật test.
- Một component nhỏ `ReviewRecordingPlayer`: bấm "Nghe lại" mới tải link (link ngắn hạn nên không tải sớm), rồi hiện `PromptAudioPlayer`.

### Độ phức tạp

Fast. Rủi ro thấp; phần nghe lại chạm API thật nhưng chỉ khi học viên bấm.

## Phases

- [x] Phase 1: Nhãn 1-based, icon kỹ năng và prop `contentState` — [phase-01-labels-icon-contentstate.md](./phase-01-labels-icon-contentstate.md)
- [x] Phase 2: Nghe lại bản ghi trên trang Review — [phase-02-review-playback.md](./phase-02-review-playback.md)

## Kết quả thực hiện (2026-11-15)

- Phase 1: `describeSavedAnswer` đánh số ô trống từ 1 (key không phải số nguyên giữ nguyên); test dùng key `"0"`, `"1"` như payload thật;
  `SkillTaskList` dùng `iconForSection`; `HomeView` truyền `contentState` đủ `ready`, `loading`, `error`.
- Phase 2: `ReviewRecordingPlayer` (bấm "Nghe lại" mới tải link, rồi `PromptAudioPlayer` tự phát; lỗi thì báo và cho thử lại);
  `PracticeReviewView` dùng nó ở nhánh bản ghi âm; thêm 3 khóa i18n `review.listenBack`, `review.listenLoading`, `review.playbackError` (EN, VI).
  Test: trạng thái đầu có nút, không có `<audio>`, không gọi API khi render.

Kiểm chứng: `pte-practice` tsc sạch, 106 file và 821 test qua, eslint không lỗi (còn cảnh báo `locale` không dùng đã có sẵn).

Chưa làm: thử trên giao diện với bản ghi thật; test cho luồng tải link (cần jsdom); commit. Điểm 2 và 3 cố ý không sửa.
