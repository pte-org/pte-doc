# Brainstorm: Refactor giao diện exam + xây common layer (pte-app)

**Date:** 2026-09-12
**Author:** quang
**Design source:** `pte-doc/design/stitch-pte-exam-app`
**Target codebase:** `pte-app/lib/features/exam_attempt` + `pte-app/lib/core`

---

## Bối cảnh scan được

**Target là `pte-app` (Flutter desktop), không phải `pte-web`.**
`pte-web/packages/ui` đã có common layer riêng phục vụ host/vendor dashboard (Next.js).
Stitch design mô tả exam delivery shell — header fixed 56px, footer fixed 56px, content
`max-w-[960px]` — và `core/platform/` của Flutter app có `window_manager_channel`,
`process_manager_channel`, `shortcut_interceptor_channel` → lockdown desktop. Design này
thuộc về `pte-app`.

**23/23 task type đã có screen.** `task_type_dispatcher.dart` (323 dòng) dispatch đủ:
`READ_ALOUD`, `REPEAT_SENTENCE`, `DESCRIBE_IMAGE`, `RE_TELL_LECTURE`,
`ANSWER_SHORT_QUESTION`, `PERSONAL_INTRODUCTION`, `RESPOND_TO_A_SITUATION`,
`SUMMARIZE_GROUP_DISCUSSION`, `SUMMARIZE_WRITTEN_TEXT`, `WRITE_ESSAY`,
`SUMMARIZE_SPOKEN_TEXT`, `WRITE_FROM_DICTATION`, `MC_READING_SINGLE`,
`MC_READING_MULTIPLE`, `MC_LISTENING_SINGLE`, `MC_LISTENING_MULTIPLE`,
`SELECT_MISSING_WORD`, `HIGHLIGHT_CORRECT_SUMMARY`, `HIGHLIGHT_INCORRECT_WORDS`,
`FILL_BLANKS_READING`, `FILL_BLANKS_READING_WRITING`, `FILL_BLANKS_LISTENING`,
`RE_ORDER_PARAGRAPHS`.

**Thiếu 12 màn pre-exam / transition:** candidate sign-in, identity confirmation,
terms & conditions, test introduction, headset check, microphone check, keyboard check,
final confirmation NDA, 3 part-transition, test completion & score submission.
Flutter hiện chỉ có `auth/presentation/pages/login_page.dart` và
`device_check/presentation/pages/test_mic_and_sound_screen.dart`.

**Duplication hiện tại — bằng chứng cách cắt module đang sai:**

| Trùng lặp | Nguyên nhân |
|---|---|
| `McOptionList` vs `ListeningOptionList` | bản Reading hardcode `BlocBuilder<McReadingSingleCubit>` bên trong → không tái sử dụng được |
| `McMultipleOptionList` vs `ListeningMultipleOptionList` | cùng lý do |
| `readingTaskHeaderTitle()` vs `listeningTaskHeaderTitle()` | cùng một `switch` shape, tách theo feature |
| `WordCountLabel` vs `ListeningWordCountLabel` | cùng logic đếm từ |
| `write_essay_screen.dart` + `write_essay_v2_screen.dart` | version drift, cả hai còn sống |
| `core/widgets/exam/`, `core/widgets/resizable/` | thư mục rỗng — common layer đã được dự định nhưng chưa từng dựng |

Comment trong `listening_option_list.dart` ghi thẳng đây là *phase-03 red-team finding* —
vấn đề đã được phát hiện, nhưng cách xử lý là **copy sang bản mới** thay vì sửa gốc.

**Token layer lệch design:**
- `AppColors` đặt tên theo component (`readingPageBackground`, `dragChipBackground`,
  `examHeaderGradientStart`); design system dùng role Material-3
  (`surface-container-low`, `on-surface-variant`, `primary-container`).
- `primary` hiện `#1E88E5` — design `#004787`.
- `AppDimensions` có 40+ hằng số rời rạc thay vì một spacing scale.
- `screens/36-.../tokens.json` (694 dòng), `screens/37-.../tokens.css` (274 dòng),
  `screens/35-.../component-spec.md` (280 dòng, 8 component có variant spec) — **chưa ai consume**.

---

## Ideas Explored

**A. Common = chỉ design tokens** — map `AppColors`/`AppDimensions` sang `tokens.json`.
Rẻ, không rủi ro. Nhưng không chạm được duplication; thêm task type mới vẫn copy-paste.
*Bị loại: giải quyết triệu chứng nhẹ nhất, bỏ qua nguyên nhân.*

**B. Common = tokens + shared components** — gộp 4 option list thành 1, gộp header mapper,
gộp word count. Giải quyết duplication hiện hữu. Nhưng 23 screen vẫn tự lắp ráp layout
riêng → screen thứ 24 vẫn phải viết từ đầu. *Bị loại: dừng nửa chừng.*

**C. Template cắt theo kỹ năng** (ReadingTemplate / ListeningTemplate / SpeakingTemplate) —
chính là cấu trúc hiện tại. *Bị loại thẳng: đây là nguyên nhân sinh ra 4 bản MCQ option list.
`MC_READING_SINGLE` và `MC_LISTENING_SINGLE` có cùng hình dạng tương tác nhưng nằm ở hai
module khác nhau.*

**D. Template cắt theo hình dạng tương tác** (được chọn) — 23 task type gom thành 7 family:

```
Record-audio   (8)  READ_ALOUD, REPEAT_SENTENCE, DESCRIBE_IMAGE, RE_TELL_LECTURE,
                    ANSWER_SHORT_QUESTION, PERSONAL_INTRODUCTION,
                    RESPOND_TO_A_SITUATION, SUMMARIZE_GROUP_DISCUSSION
Free-text      (4)  SUMMARIZE_WRITTEN_TEXT, WRITE_ESSAY,
                    SUMMARIZE_SPOKEN_TEXT, WRITE_FROM_DICTATION
Select-one     (4)  MC_READING_SINGLE, MC_LISTENING_SINGLE,
                    SELECT_MISSING_WORD, HIGHLIGHT_CORRECT_SUMMARY
Fill-blanks    (3)  FILL_BLANKS_READING (drag), FILL_BLANKS_READING_WRITING (dropdown),
                    FILL_BLANKS_LISTENING (typed)
Select-many    (2)  MC_READING_MULTIPLE, MC_LISTENING_MULTIPLE
Ordering       (1)  RE_ORDER_PARAGRAPHS
Token-toggle   (1)  HIGHLIGHT_INCORRECT_WORDS
```

Trục thứ hai vuông góc — **stimulus**: passage / audio / image / none.
Template thật = `StimulusSlot × ResponseSlot`, khớp chính xác layout mockup
(`lg:grid-cols-12`, cột trái stimulus, cột phải response).

**E. Rewrite toàn bộ từ đầu** — bỏ `exam_attempt` hiện tại, dựng lại trên common mới.
*Bị loại: 23 screen đang chạy được, phần lớn logic (cubit, timer bridge, outbox submit)
không có vấn đề — chỉ lớp trình bày mới cần factoring lại.*

---

## User's Direction

Chọn **D**, thực hiện đủ 3 tầng: **Token → Component → Template**, rồi viết lại 23 screen
trên nền template. 12 màn pre-exam làm **sau khi common xong**, build trực tiếp trên common
để không phải refactor lần hai.

Navigation: **forward-only**, khớp `ExamAttemptBloc` + `task_advance_button` hiện có —
không đụng vào state layer. Nút `Previous` trong mockup giữ ở trạng thái `disabled` vĩnh viễn
(mockup vốn đã render nó disabled).

Chrome: **giữ nguyên như mockup**, kể cả các badge chưa có nguồn dữ liệu.

---

## Open Questions (chuyển sang /ck:plan)

1. **Chrome không có nguồn dữ liệu.** `TaskView` cung cấp: `taskType`, `title`, `section`,
   `orderIndex`/`totalTasks`, `promptText`, `audioPromptRef`, `imagePromptRef`, `imageUrl`,
   `minWordCount`/`maxWordCount`, `options`, `blankGroups`, `prepSeconds`,
   `responseSeconds`, `examEndTime`, `preListenSeconds`, `preRecordSeconds`.
   Mockup còn hiển thị: `Ref: PTE-MCSA-0501`, `Checksum: 0x88FE2C`,
   `Pearson VUE Secure Engine v4.28.1`, `Standard Binary Scoring: 1 mark correct / 0 incorrect`,
   `Topic: Astrobiology & Extremophiles`, footnote nguồn trích dẫn, `Passage: 194 words`,
   `Skills Assessed`.
   → Quyết định: tập trung vào một `ExamChromeConfig` (giá trị tĩnh, một file duy nhất),
   không rải hardcode qua 23 screen. Khi API bổ sung field thì chỉ sửa một chỗ.
   Chuỗi cuối cùng cho từng badge cần chốt với teacher/BA trước khi ship.

2. **Breakpoint responsive.** `AppDimensions.readingPassageLayoutBreakpoint = 720.0` đang
   tồn tại nhưng design chỉ đặc tả desktop (`lg:grid-cols-12`). Template có cần nhánh
   narrow-layout, hay khoá min-width cho lockdown desktop?

3. **`write_essay_v2_screen.dart`.** Bản nào là bản sống? Refactor phải xoá bản còn lại.

4. **2 file design hỏng.** `screens/04-terms-conditions-82dd1c1b/screen.html` và
   `screens/12-read-aloud-b98b86bb/screen.html` là ảnh chụp nhầm trang đăng nhập Google
   (939KB mỗi file). Màn 12 còn `01-read-aloud-fa73d757` thay thế; màn 04 T&C thì mất —
   cần export lại từ Stitch trước khi làm nhóm 12 màn pre-exam.

---

## Risks

1. **Record-audio family (8 task) có state machine riêng nằm rải rác.**
   `auto_record_timer_bridge_mixin.dart`, `auto_advance_on_upload_ready.dart`,
   `countdown_timer.dart`, `audio_prompt_record_body.dart` (259 dòng — file lớn nhất repo)
   cùng điều phối chuỗi: beep → countdown chuẩn bị → auto-record → auto-stop → upload →
   auto-advance. Template hoá phần trình bày mà không kéo state machine này lên cùng sẽ tạo
   ra một template rỗng, 8 screen vẫn tự xoay xở → duplication tái diễn ở tầng cao hơn.
   *Đây là rủi ro số một của toàn bộ refactor.*

2. **Retheme đổi `primary` `#1E88E5` → `#004787` chạm mọi màn hình, kể cả ngoài
   `exam_attempt`** (`auth`, `host_console`, `report`, `scoring_review`, `live_proctor`,
   `authoring`, `scheduling`, `host_users`, `host_audit`, `speaking`). Nếu chỉ retheme
   `exam_attempt`, app sẽ có hai bảng màu song song.

3. **Giữ nguyên chrome mockup tạo slot không có dữ liệu thật.** Khi API bổ sung field,
   nếu các giá trị tĩnh đã bị rải trong screen thay vì tập trung ở `ExamChromeConfig`,
   chi phí nối API sẽ nhân với 23. Ràng buộc "một file duy nhất" phải được enforce ở
   quality gate.

4. **Rule `CLAUDE.md` file ≤ 300 dòng** — `task_type_dispatcher.dart` đã 323 dòng và sẽ
   phải mở rộng để map 23 task type → 7 template × stimulus variant. Cần tách thành
   registry theo family thay vì một `switch` phẳng.

---

## Next

→ `/ck:plan pte-doc/projects/plans/quang-exam-ui-design-system/spec.md`
