# Spec: PTE Listening — Task Type UI (Mock-First)

**Date:** 2026-08-22
**Status:** Draft

---

## Problem Statement

`pte-app` đã có UI đầy đủ cho Reading (5 loại) và Speaking/Writing cơ bản, nhưng **Listening — 1 trong 4 kỹ năng thi PTE — chưa có UI nào**. `TaskTypeDispatcher` hiện fallback về `_UnsupportedTaskTypePlaceholder` cho mọi task type Listening. Backend (`exam-delivery`) cũng chưa route được 8 loại này (chỉ config timing cho 3 loại Milestone-1), nên phần này cần làm UI + mock data trước, nối backend thật sau ở 1 plan riêng.

---

## User Stories

<!-- P1 = MVP (must ship), P2 = nice-to-have, P3 = future/out-of-scope -->

- **[P1]** As a học viên, I want nghe audio và gõ lại đúng câu vừa nghe (Write From Dictation) so that tôi luyện được dạng câu hỏi có trọng số điểm cao nhất (5% overall theo bảng blueprint).
  Accepted when: audio phát đúng 1 lần rồi khoá lại, ô nhập text nhận input, submit ghi answer vào outbox giống các task khác.

- **[P1]** As a học viên, I want nghe audio và viết tóm tắt trong giới hạn từ (Summarize Spoken Text) so that tôi luyện dạng chiếm 4% overall.
  Accepted when: word-count validate theo `minWordCount`/`maxWordCount` của `TaskView` (tái dùng pattern `write_essay_cubit`), audio phát đúng 1 lần.

- **[P1]** As a học viên, I want nghe audio + đọc transcript và click chọn từ sai so với audio (Highlight Incorrect Words) so that tôi luyện dạng chiếm 4% overall.
  Accepted when: có thể click từng từ trong đoạn text để toggle chọn/bỏ chọn, submit ghi nhận đúng danh sách từ đã chọn.

- **[P2]** As a học viên, I want làm Fill in the Blanks (Type-In), Multiple Choice Multiple Answers, Select Missing Word so that tôi luyện các dạng trọng số trung bình (1–3% overall).

- **[P2]** As a học viên, I want làm Highlight Correct Summary, Multiple Choice Single Answer so that tôi hoàn thiện đủ 8/8 dạng dù trọng số thấp nhất (<1% overall).

- **[P3]** _(out of scope)_ Nối vào `exam-delivery` thật (task-timing.json, TaskView Java DTO mapping) — plan/phase riêng sau khi FE xong.

- **[P3]** _(out of scope)_ Setting cho phép pause/replay audio (chế độ luyện tập lỏng hơn thi thật).

---

## Functional Requirements

1. FR-01: Thêm `AudioPlayerService` (domain interface `lib/features/exam_attempt/domain/`) + impl dùng `just_audio` — phát 1 file audio đúng 1 lần, không expose seek/pause/replay ra UI, expose trạng thái đã-phát-xong.
2. FR-02: Impl mock của `AudioPlayerService` phát audio từ Flutter asset bundle cục bộ (không qua `MediaRepository`/network). Interface phải tách rời để sau này thêm impl remote (presigned URL) không đổi UI layer.
3. FR-03: Mở rộng `TaskTypeDispatcher` (`lib/features/exam_attempt/presentation/widgets/task_type_dispatcher.dart`) thêm 8 case, đúng string constant khớp `PteTaskType` enum bên `pte-api/services/authoring/.../PteTaskType.java`: `WRITE_FROM_DICTATION`, `SUMMARIZE_SPOKEN_TEXT`, `HIGHLIGHT_INCORRECT_WORDS`, `FILL_BLANKS_LISTENING`, `MC_LISTENING_MULTIPLE`, `SELECT_MISSING_WORD`, `HIGHLIGHT_CORRECT_SUMMARY`, `MC_LISTENING_SINGLE`.
4. FR-04: Mỗi task type có screen + cubit/state riêng trong `presentation/{pages,cubit}/`, theo đúng pattern Reading hiện có (file ≤300 dòng, `dispose()` cho `AudioPlayerService`, mounted-check sau await, sealed/immutable state — theo `CODING_STANDARDS_APP.md`).
5. FR-05: `WRITE_FROM_DICTATION`, `SUMMARIZE_SPOKEN_TEXT` dùng text input + word-count validate (tái dùng `word_count.dart` / pattern `write_essay_cubit`).
6. FR-06: `HIGHLIGHT_INCORRECT_WORDS`, `HIGHLIGHT_CORRECT_SUMMARY` cần widget click-to-toggle trên đoạn text — thành phần UI mới, chưa có tiền lệ trong codebase (khác MC-click và drag-drop đã có). `HIGHLIGHT_INCORRECT_WORDS`: toggle tự do (click chọn/click lại bỏ chọn), không giới hạn số từ được chọn.
7. FR-07: `MC_LISTENING_SINGLE`, `MC_LISTENING_MULTIPLE`, `SELECT_MISSING_WORD` tái dùng UI pattern từ `mc_reading_single_screen.dart`/`mc_reading_multiple_screen.dart`, chỉ đổi phần prompt từ text sang audio player.
8. FR-08: `FILL_BLANKS_LISTENING` — gõ tự do (type-in), không gợi ý/không word-bank, khác hẳn `FILL_BLANKS_READING` (kéo-thả). So khớp đáp án dạng string case-insensitive. Format transcript-có-chỗ-trống đề xuất tái dùng `{{n}}` marker convention đã có.
9. FR-09: Tạo `ListeningTaskFixtures` (mirror `ReadingTaskFixtures`, `lib/features/exam_attempt/dev/`) — 1 fixture mẫu cho mỗi loại trong 8 loại, `taskType` khớp đúng string enum thật.
10. FR-10: Tạo `ListeningTaskPreviewScreen` (`kDebugMode`-gated, mirror `ReadingTaskPreviewScreen`) — xem từng loại qua `TaskTypeDispatcher` thật, không cần backend.
11. FR-11: Audio asset mock (file `.mp3`) bundle trong `pte-app/assets/audio/`, khai báo trong `pubspec.yaml`.

---

## Non-Functional Requirements

- Performance: audio bắt đầu phát trong <1s sau khi task load (asset cục bộ, không network).
- Hành vi đúng thi thật: audio chỉ phát được đúng 1 lần / mỗi task; không có nút play lại, không seek bar tương tác được, không pause.
- File size: mỗi screen/cubit/state file ≤300 dòng theo `CODING_STANDARDS_APP.md`.

---

## Success Criteria

- [ ] 8/8 task type Listening render đúng qua `TaskTypeDispatcher` với dữ liệu mock — không loại nào rơi vào `_UnsupportedTaskTypePlaceholder`.
- [ ] Audio phát đúng 1 lần cho mỗi loại; không có thao tác UI nào phát lại được.
- [ ] `ListeningTaskPreviewScreen` cho phép xem cả 8 loại không cần backend, giống `ReadingTaskPreviewScreen`.
- [ ] Word-count validate hoạt động đúng cho Write From Dictation / Summarize Spoken Text.
- [ ] Click-to-toggle từ hoạt động đúng cho Highlight Incorrect Words / Highlight Correct Summary, submit ghi đúng lựa chọn.

---

## Out of Scope

- Mọi thay đổi backend (`exam-delivery` task-timing.json, TaskView Java DTO, nội dung authoring thật cho 8 loại) — plan riêng sau khi FE xong.
- Setting cho phép pause/replay audio (chế độ luyện tập lỏng hơn thi thật).
- pte-web (browser) — chỉ pte-app Flutter theo yêu cầu hiện tại.

---

## Assumptions

- 8 string task-type constant dùng đúng tên hiện có trong `PteTaskType.java` (authoring service) — nếu BE đổi tên khi triển khai thật, FE switch-case phải đổi theo.
- Mock audio asset là file tiếng Anh ngắn, không cần đúng nội dung thi PTE thật — chỉ cần đủ để test playback + luồng UI.
- `TaskView` Dart model hiện tại (`promptText`, `audioPromptRef`, `options`, `blankGroups`) đủ field để biểu diễn cả 8 loại Listening — không cần thêm field mới ở tầng domain model cho giai đoạn mock.

