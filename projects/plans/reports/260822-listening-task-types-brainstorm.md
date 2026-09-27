# Brainstorm: PTE Listening — Task Type UI (Mock-First)

**Date:** 2026-08-22

## Ideas Explored

- **Toàn bộ 8 loại cùng lúc** vs **ưu tiên theo trọng số điểm trước** (Write From Dictation 5% → Summarize Spoken Text 4% / Highlight Incorrect Words 4% → Fill in the Blanks 3% → MC Multiple / Select Missing Word 1% → Highlight Correct Summary / MC Single <1%) — vẫn làm đủ 8 loại, chỉ khác thứ tự implement.
- **Audio playback UX:** phát đúng 1 lần như thi thật (không tua/pause/replay) vs cho phép replay để luyện tập dễ hơn — chọn theo thi thật, replay-mode có thể là setting sau này (không phải bây giờ).
- **Phạm vi BE+FE cùng lúc** vs **FE-only, mock trước, BE sau** — chọn FE-only. Lý do phát hiện được khi scout: `exam-delivery` (`task-timing.json`) hiện chỉ config timing cho 3 task type (`MC_READING_SINGLE`, `READ_ALOUD`, `WRITE_ESSAY` — "Milestone-1"), Listening chưa được backend route dù `PteTaskType` enum bên `authoring` đã định nghĩa đủ 8 loại. Do đó UI không thể test qua API thật ngay bây giờ — mock fixtures là lựa chọn khả thi duy nhất để thấy UI sớm.
- **Tái dùng pattern Reading đã có:** `TaskTypeDispatcher` switch + 1 screen/cubit/state riêng mỗi loại, cộng với tiền lệ `ReadingTaskFixtures` + `ReadingTaskPreviewScreen` (`kDebugMode`-gated dev screen render qua dispatcher thật) — nhân bản thành `ListeningTaskFixtures` + `ListeningTaskPreviewScreen`.
- **Audio player service:** hoàn toàn chưa tồn tại — `just_audio` có trong `pubspec.yaml` nhưng không có `AudioPlayer` nào được dùng trong code; `MediaRepository` chỉ có presign/upload, không có download/playback resolution. Cần thiết kế abstraction chơi asset cục bộ (mock) nhưng swap sang remote sau này không đổi UI.

## User's Direction

Làm UI + mock data cho toàn bộ 8 task type Listening trong `pte-app`, chưa đụng backend. Ưu tiên implement theo thứ tự trọng số điểm thi thật (Write From Dictation trước tiên). Audio phải phát đúng 1 lần, không có cách nào tua/pause/replay từ UI — khớp hành vi thi thật. Sau khi UI hoàn thiện hết mới làm phần backend.

## Open Questions

- `exam-delivery` chưa có timing config / TaskView field cho 8 loại Listening — cần 1 plan/phase backend riêng sau, không phải bây giờ.
- `HIGHLIGHT_INCORRECT_WORDS` được ghi "STILL OPEN" trong `pte-doc/projects/plans/quang-pte-pivot/phase-01-contract-draft.md` (không map rõ ràng vào `QuestionType` nào cho việc chấm điểm) — có thể ảnh hưởng field shape khi nối BE thật, không chặn việc làm UI mock.
- Convention format transcript có blank-markers (`FILL_BLANKS_LISTENING`) và transcript có từ-có-thể-click (`HIGHLIGHT_INCORRECT_WORDS`) chưa được thiết kế — đề xuất tái dùng `{{n}}` marker convention của `FILL_BLANKS_READING` cho loại đầu.

## Risks

- **Audio player abstraction sai thiết kế** → nếu không tách rõ interface (asset cục bộ vs remote presigned URL) sẽ phải viết lại khi nối BE thật sau này.
- **"Chỉ nghe 1 lần"** là ràng buộc UX nghiêm ngặt — dễ vô tình để lộ nút back/pause nếu không kiểm soát kỹ ở tầng widget dùng chung.
- **Highlight Correct Summary / Highlight Incorrect Words** là dạng click-to-toggle trên văn bản — chưa có pattern UI nào tương tự trong codebase (khác hẳn MC-click hay drag-drop đã có), rủi ro effort cao nhất trong 8 loại.
