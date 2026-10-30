# Phase 03: delivery, renderers, session và media đủ kỹ năng

Status: planned. Dependencies: 01 và contracts/readiness 02. Stories: US-02, US-03. Requirements: PR-03,04.

## Work packages

1. Mở rộng `PracticeQuestionService` projection và snapshot builder bằng content thật: prompt text/image/audio, passage, stable options/blanks/tokens, source playback policy, preparation/response timing và media revision. Tách safe delivery projection khỏi restricted evaluator/reference snapshot. Source transcript nếu tiết lộ đáp án chỉ nằm phía restricted. Không chỉ thêm fields TypeScript mà bỏ mapper/backend.
2. Reading: `BlankRenderer` render theo blank definitions, giữ blankIndex/stable ID, option reuse theo task; không hardcode 2 blanks. Choice giữ IDs thay vì order index; multiple choice xác thực selections, không leak correct option. Order phải dùng opaque shuffled paragraph IDs, server-only map về correct order; không lộ `orderIndex` gốc qua IDs/payload. Thiết kế compatibility path cho draft/old answers trước đổi IDs, hỗ trợ keyboard reorder. Highlight giữ token IDs/positions, phân biệt punctuation/whitespace theo canonical tokenizer.
3. Listening: source audio có loading/failed/retry/playback policy rõ; đáp án text/choice/blank/highlight đồng bộ task matrix. Write from Dictation xử lý Unicode/normalization qua evaluator, không tự normalize destructive trên client. Audio replay/seek chỉ theo approved practice mode, không tự áp timing exam.
4. Writing: word count/draft/resume theo Unicode policy; paste/word limit được chốt theo task. Timing dựa canonical session state, không reset khi refresh. Empty answer có confirmation và invalid policy riêng; không giả bài chưa nộp thành đã chấm.
5. Speaking: phối hợp preparation → source playback → recording → preview → upload grant/upload/bind → ready-to-submit. Read Aloud/Repeat Sentence/Describe Image/Retell Lecture có content và media khác nhau; renderer shared chỉ tái dùng capture controls. Permission denied, missing device, changed device, audio quá ngắn/empty, upload timeout/expired grant, network retry giữ blob có kiểm soát. Không mất recording chỉ vì một lần upload lỗi.
6. `PracticeSessionView` tiếp tục lifecycle hiện có: save drafts/text/selection/confidence/recording binding; optimistic version; submit/skip/discard/resume/deadline. Namespace local theo account/context/session/item/schema; TTL/clear khi logout/context switch, không lưu keys hoặc restricted content. Reconcile local pending draft với server version; hiện conflict thay overwrite âm thầm. Session pending uploads không cho submit thiếu evidence.
7. Mỗi task được mở allowlist **sau** fixture → delivery → answer validation → save/resume → submit → result contract đã sẵn sàng. UI catalog chỉ advertise supported/ready tasks; unavailable có nguyên nhân nhưng không tính vào completion của task đã cam kết.

## Proposed files

- `pte-practice/features/practice/{contracts.ts,task-content.ts,renderer-allowlist.ts,PracticeSessionView.tsx,PracticeProvider.tsx,session-storage.ts,session-state.ts}`.
- `renderers/{BlankRenderer,ChoiceRenderer,OrderRenderer,HighlightRenderer,TextRenderer,RecordingRenderer,TaskRenderer}.tsx`; `media/{api.ts,contracts.ts,audio-recorder.ts}`.
- Backend `practice/internal/service/PracticeSession{Service,PersistenceService,ItemService}.java`, `PracticeAnswerValidationService.java`, practice snapshots/DTOs và `itembank/PracticeQuestionService.java`.

## Failure paths

Missing media/publication, unsupported content schema, source audio fails mid-task, stale drafts in tab thứ hai, submit trước upload bind, stale grant, microphone disconnect, browser sleep/deadline, offline save, context logout khi upload đang chạy. Server state quyết định final outcome; UI luôn có retry/review/return phù hợp.

## Design Constraints

Reuse session services và recorder hiện có; không xây lifecycle thứ hai. Không mở renderer chỉ bằng bỏ allowlist. Safe content không có answers/transcripts/rubric worked examples trước submit. Playback/timing tuân D01/task policy. Public media URL/grant phải đúng asset scope, không nhận arbitrary external URL cho worker fetch.

## Tests to Consider

Renderer contract cho từng row task matrix; stable IDs khi shuffle; 1/n blanks; reused options; keyboard accessibility; image/audio failure; recording permission/grant/retry; confidence/text resume; account/context isolation; race save vs submit; refresh deadline. Fixtures cần source content thực hợp lệ, không placeholder. Chưa viết/chạy.

## Exit criteria

Mọi confirmed in-scope task có end-to-end delivery/save/resume/submit fixture; không còn hardcoded blank count hoặc answer ID dựa vị trí. Recording retry không làm mất bài. Task thiếu content chưa được tính hoàn tất.

## Quality and Testing State

Quality: not evaluated. Testing: not started. TDD chưa chọn; cook xác nhận optional checks. Required frontend/backend compile/check theo standards. Visual/interaction verification là coverage đề xuất, chưa thực hiện.
