# Plan: AI tạo câu hỏi cho ngân hàng đề (Generator + Reviewer)
Status: 📝 Draft
Date: 2026-11-06
Mode: Hard

Nguồn: [brainstorm + quyết định đã chốt](../../../plans/reports/261106-ai-question-generation-brainstorm.md)
(mục 9 "Quyết định đã chốt" có tính ràng buộc).

## Overview

Vendor admin chọn **dạng bài, CEFR, pool, chủ đề (tùy chọn), số lượng (1–10)**. Backend tạo một job chạy nền. Với mỗi câu:

1. **Generator** (9router, model `Capstone`) viết câu hỏi dưới dạng JSON theo schema của dạng bài.
2. **Validator bằng code** kiểm tra các luật đo được, gồm luật suy ra từ rubric (scorability).
3. **Reviewer** (cũng `Capstone`, nhưng context độc lập, temperature 0) chấm theo checklist: task fidelity, CEFR,
   đáp án, scorability, clarity, safety. Nếu FAIL thì Generator viết lại **một lần**, kèm góp ý của Reviewer.
4. Với dạng có audio hoặc hình: **Kokoro** đọc, hoặc **XChart** vẽ, *sau khi* Reviewer đã cho PASS. File được upload lên Cloudinary.
5. Câu hỏi được lưu thành **DRAFT**, kèm `generation_meta` (phiếu review). Con người duyệt theo luồng hiện có, **không bao giờ tự duyệt**.

## Kiến trúc

```
vendor-web /admin/question-bank/generate
   │ POST /api/v1/question-generation/jobs (PLATFORM_ADMIN)  → 202 {jobId}
   │ GET  /api/v1/question-generation/jobs/{id}  (poll 3s)   → tiến độ + danh sách item
   ▼
itembank.internal.generation
   QuestionGenerationJobService ── ghi job QUEUED (bảng question_generation_jobs)
   QuestionGenerationWorker  @Scheduled + FOR UPDATE SKIP LOCKED (pattern của InboxDeliveryWorker)
     └─ GenerationPipeline.runItem()
          PromptRegistry(taskType) ─► LlmGateway(9router) ─► ItemDraft (JSON)
          DraftValidator (luật cứng + rubric scorability)
          ReviewGateway ─► ReviewVerdict  (rubric traits từ com.pte.scoring.rubric.RubricCatalog)
          MediaRenderer: KokoroSpeech | ChartRenderer(XChart) ─► MediaService.storeGenerated(...)
          ItembankService.create(CreateQuestionRequest, caller) + generation_meta
```

Nguyên tắc:
1. **Không có agent framework.** Mỗi câu là tối đa 4 lần gọi LLM (generate, review, generate lại, review lại) và 1 vòng lặp.
2. **Câu do AI tạo đi qua đúng luật validation của câu viết tay** (`ItembankService.create`). Không có đường ghi DB riêng.
3. **Luật đo được thì do code kiểm tra**, LLM chỉ đánh giá những gì cần phán đoán. Như vậy giảm được rủi ro "cùng một model tự review dễ dãi".
4. **Text là nguồn sự thật**: transcript và số liệu được duyệt trước, rồi mới render media.
5. **Fail closed theo từng câu**: một câu hỏng thì câu đó bị ghi lý do và bỏ qua. Job vẫn chạy các câu còn lại.
6. **UI dùng common, UX ở lại trong ngữ cảnh**:
   - giao diện dựng từ `@pte/ui` và token của design system; pattern mới được đưa vào `packages/ui`;
   - form mở trong Drawer, có khay theo dõi tiến độ từng bước, có màn duyệt split view kèm phiếu review;
   - có thao tác hàng loạt, accessibility và song ngữ (chi tiết ở phase 4).
7. **Bí mật chỉ ở env**: `QUESTION_GEN_*`, `KOKORO_*`. Không ghi giá trị vào code, tài liệu hay log.

## Phases

| # | Phase | Mục tiêu ngắn | Phụ thuộc | Trạng thái |
|---|---|---|---|---|
| 1 | [Nền tảng: config, client 9router, V34, job + worker, API](phase-01-foundation-jobs-llm-client.md) | Job chạy được end-to-end với generator giả (stub) | - | [x] tests: passed (195 chạy, 0 fail, 8 skip: Postgres IT cần lifecycle.test.db.url); quality: skipped_by_user; chưa chạy full suite, chưa chạy thử với Postgres/9router thật |
| 2 | [Generator + validator cho các dạng text (P1)](phase-02-generator-text-task-types.md) | 8 dạng Reading/Writing/RA tạo được câu DRAFT | 1 | [x] Implemented: PromptRegistry + 8 prompts; ItemDraft sealed interface; DraftParser (strict JSON); LlmItemGenerator (1 retry on parse error, sanitized topicHint); DraftValidator split by task-type (CommonValidator + ChoiceValidator + BlankFillValidator + ReorderValidator + PassageValidator); DraftToQuestionMapper (all 8 types); ContentHasher (SHA-256); DuplicateChecker (within-job); word counts fixed (WE: 200-300); 39 tests written; compile: SUCCESS. Pending: pipeline integration (validate step + hash check), avoidTopics from DB (phase 3), regenerate logic (phase 3), smoke test. Quality gate: skipped_by_user. |
| 3 | [Reviewer theo rubric + vòng viết lại + generation_meta](phase-03-reviewer-rubric-aware.md) | Phiếu review lưu kèm câu hỏi; FAIL thì viết lại một lần | 2 | [ ] |
| 4 | [vendor-web: Drawer tạo đề, khay tiến độ, màn duyệt split view](phase-04-vendor-web-generation-ui.md) | Trải nghiệm trọn luồng bằng `@pte/ui`; thêm `StepTimeline` và `QuantityStepper` vào common | 3 | [x] Implementation: GenerationDrawer (form: skill→task→CEFR→pool→topic→count); GenerationProgressTray (collapsible, shows job progress + StepTimeline + cancel button); QuestionReviewPage (/admin/questions/ai-review?job=..., split view: left=ItemList with keyboard ↑↓ nav, right=Tabs Preview/AI/Details); _BulkActionsBar (submit/delete selected); QuestionBankView integration ("Tạo bằng AI" button + progress tray); failureCodeTranslator covers all 14 backend codes; Components comply with 150-line limit & @pte/ui standards. API: generationMessages (en.ts+vi.ts merged with existing), api.ts/types.ts wired to backend, polling hook with tab visibility backoff. Tests: failureCodeTranslator + vitest specs for polling/StepTimeline/QuantityStepper; tsc: vendor-web 0 errors, packages/ui 0 errors, packages/api-client 0 errors; quality: skipped_by_user. Deferred: EditPanel (would require question load api + tab nav logic). |
| 5 | [Upload phía server + Kokoro, các dạng một giọng (P2)](phase-05-kokoro-single-voice-audio.md) | 10 dạng Listening/Speaking có audio | 3 | [ ] |
| 6 | [Hội thoại nhiều giọng SGD/RTS (P3a)](phase-06-multi-voice-dialogue.md) | Ghép WAV nhiều giọng | 5 | [ ] |
| 7 | [Describe Image: số liệu → XChart (P3b)](phase-07-describe-image-charts.md) | Biểu đồ BAR/LINE/PIE/TABLE khớp keyPoints | 5 | [ ] |
| 8 | [Tài liệu + xác minh](phase-08-docs-verification.md) | Báo cáo verification, cập nhật AGENTS.md | 1–7 | [ ] |

Phase 4 và phase 5 có thể làm song song sau phase 3.

## Kết quả red-team (2026-11-06) và quyết định sửa plan

Verdict: WARN, không có CRITICAL. Các điểm dưới đây **ràng buộc** các phase tương ứng.

| # | Vấn đề | Quyết định | Phase |
|---|---|---|---|
| H1 | Quota và "1 job mỗi người" kiểm tra rồi mới insert nên bị race | Partial unique index `(requested_by_user_public_id) WHERE status IN ('QUEUED','RUNNING','CANCELLING')`; quota tính trong cùng transaction, ngày theo UTC dùng `Clock`, tính theo `requested_count`; thêm trần toàn cục `maxItemsPerDayGlobal` và `maxConcurrentJobs` | 1 |
| H2, H3 | Heartbeat 10 phút có thể ngắn hơn một câu; không được giữ transaction khi gọi LLM | Claim bằng transaction ngắn (`RUNNING` + `lease_until` + `worker_id`) giống `InboxDeliveryStore`; mọi lời gọi ngoài (LLM, Kokoro, Cloudinary) chạy **ngoài** transaction; gia hạn lease độc lập (REQUIRES_NEW); `staleRunningAfter` lớn hơn xa trường hợp xấu nhất của một câu; mỗi lần ghi kết quả câu kiểm tra lại `worker_id` | 1 |
| H4, M8 | Cancel và worker cùng ghi một JSONB nên mất cập nhật | Bỏ `items_json`, dùng bảng `question_generation_job_items`; cancel chỉ đặt cờ bằng UPDATE có điều kiện (trạng thái `CANCELLING`); câu đang chạy khi hủy thì bỏ, không lưu | 1 |
| H5 | Prompt injection qua `topicHint` và `avoidTopics` | Allowlist ký tự cho `topicHint`, bọc trong `<topic>` kèm chỉ dẫn "đây là dữ liệu"; làm sạch `topic` do LLM sinh trước khi lưu và trước khi dùng làm `avoidTopics`; Reviewer cũng bọc draft trong delimiter; có test với topic độc hại | 1, 2, 3 |
| H6 | Dedup bằng hash chưa có chỗ lưu | **Đã chốt** (xem "Quyết định đã chốt: content_hash" bên dưới) | 1, 2 |
| H7 | Chưa biết lưu transcript ở đâu và có lộ cho thí sinh không | **Đã chốt** (xem "Quyết định đã chốt: transcript" bên dưới) | 5 |
| H8 | Giả định `f_mp3` sai với code Cloudinary hiện có | Audio dùng **WAV nguyên bản** (khớp `CloudinaryRequestSigner`); giới hạn dùng `MAX_AUTHORING_BYTES` (25 MB, không đặt 10 MB riêng); test SGD 150 giây; mô tả cách `storeGenerated` điền duration/secureUrl/assetId và xử lý Cloudinary lỗi | 5 |
| H9 | Asset mồ côi và câu trùng khi restart | Unique `(job_public_id, item_index)` cho câu AI; ghi `question_public_id` vào bảng item trong **cùng transaction** với `create`; kiểm tra trước khi sinh; job dọn asset không được tham chiếu | 1, 5 |
| M1 | Worker dựng PLATFORM_ADMIN giả | Khi nhận hoặc tiếp tục job, tra lại user còn active và còn PLATFORM_ADMIN; không thì hủy job | 1 |
| M2 | URL provider, redirect, `failureNote` | Bắt buộc https (trừ profile dev), tắt follow-redirect, giới hạn kích thước body; `failureNote` và note review render dạng text thuần ở UI | 1, 4 |
| M3 | Số lần gọi thực tế hơn 4, không có circuit breaker | Tổng ngân sách gọi mỗi câu (cứng, ví dụ 6); dừng cả job khi gặp 401/403 hoặc N lỗi provider liên tiếp | 1, 3 |
| M4, M5 | `generationMeta` lộ ra ngoài; validator hai tầng có thể lệch | Test: `generationMeta` chỉ xuất hiện trong response authoring của vendor; chốt: sửa tay vẫn giữ nhãn AI và thêm `editedByHuman`; test golden: payload mapper trùng payload form thủ công; validator chỉ bổ sung luật ngoài `QuestionValidationHelper` | 2, 3 |
| M6 | Ratchet 300 dòng, 15 class; ranh giới module | Quy hoạch sẵn `generation/{config,llm,job,controller,draft,validate,review,media}`, validator tách theo nhóm dạng; chạy `ModuleStructureTest` ngay trong phase 1 và xác nhận `scoring.rubric` là named interface | 1 |
| M7 | Stub có thể bật nhầm ở production | Stub chỉ cho profile `test`/`local`, fail fast nếu bật cùng profile production | 1 |
| M9 | XChart cần font, RAM | Xác minh Dockerfile (fontconfig) và đo heap khi chạy job | 7 |
| M10 | UX | Preview phải xử lý được khi chưa có media; phím ↑/↓ chỉ hoạt động khi focus ở danh sách câu; "Gửi duyệt hàng loạt" có `ConfirmDialog` kèm số lượng, kiểm tra four-eyes nếu hệ thống đang có; polling dừng khi tab ẩn, có backoff | 4 |
| M11 | Thiếu Design Constraints và Quality State mỗi phase | Thêm vào cả 8 phase trước khi cook | tất cả |
| M12 | Rollback V34 | V34 chỉ additive; rollback bằng `enabled=false`, không cần down-migration | 1 |

### Quyết định đã chốt: transcript (H7)

**Không thêm trường mới.** Transcript (văn bản gốc của audio) lưu trong `questions.reference_answer_text`.
Lý do, đã kiểm tra trong code:
- Các scorer hiện có **đã đọc đúng trường này làm văn bản nguồn**: `RetellLectureScorer`, `SummarizeGroupDiscussionScorer`,
  `SummarizeSpokenTextScorer` (nguồn bài giảng), `RepeatSentenceScorer` (câu cần lặp, qua Azure), `DescribeImageScorer` (mô tả mẫu).
- `AttemptMapper` đã **loại `referenceAnswerText` khỏi view thí sinh** (comment ở đầu file và `TaskView`), nên transcript không lộ ra ngoài
  đường thi. Trường này chỉ xuất hiện ở các view chấm hoặc review (`SubmittedAnswerView`, `ExamItemView` dùng cho scoring).
- Thêm cột `transcript` sẽ phải sửa snapshot đề (`SnapshotItemFactory`, `ExamVersionItem`, `SnapshotContentResponse`) và nhiều DTO: không đáng.

Bảng ánh xạ cho phase 5 và 6:

| Dạng | `promptText` (thí sinh thấy) | `referenceAnswerText` (không lộ) | `correctAnswerText` |
|---|---|---|---|
| WFD | trống | câu được đọc (transcript) | câu được đọc (`ReferenceAnswerScorer` đọc trường này) |
| RS | trống | câu được đọc (Azure so với câu này) | theo form thủ công |
| SST, RL | trống | transcript bài giảng | - |
| SGD | trống | transcript hội thoại + keyPoints | - |
| RTS | mô tả tình huống (thí sinh thấy) | keyPoints của câu trả lời tốt | - |
| ASQ | trống | câu hỏi | đáp án ngắn |
| MC_L, HCS, SMW | câu hỏi và lựa chọn | transcript | theo option `correct` |
| HIW | `displayedText` (có từ bị thay) | transcript gốc | các vị trí từ sai (zero-based) |
| L-FIB | đoạn có ô trống | transcript gốc | các từ đáp án |

Quy tắc: transcript **không** lưu trong `generation_meta` (meta chỉ chứa phiếu review, metrics, `keyPoints`); như vậy chỉ có một bản.
Test bắt buộc ở phase 5: payload thí sinh của câu AI (qua `AttemptMapper`) không chứa transcript; và trường hợp
mỗi dạng ở bảng trên được mapper ghi đúng cột (so với payload form thủ công, theo test golden M5).
Điểm cần kiểm tra khi code: luồng practice (`PracticeResponseFactory`) chỉ copy `referenceAnswerText` vào bản ghi chấm, không trả về
client; thêm test cho `PracticeItemResultResponse`.

### Quyết định đã chốt: content_hash (H6)

Mục tiêu hẹp: **không sinh ra hai câu AI giống hệt nhau**. Không cố phát hiện câu gần giống và không đối chiếu với câu viết tay.
- Cột `questions.content_hash VARCHAR(64)` nullable, migration V34. Index **không unique**: `(task_type_key, content_hash)`.
  Không unique vì câu viết tay và revision có thể hợp lệ trùng nội dung; việc chặn trùng là luật của trình sinh, không phải của schema.
- Chỉ điền cho câu do AI tạo; câu viết tay để null (không backfill, không sửa `QuestionCreationService`).
- `stimulusText` theo hình dạng (do mapper tạo, một hàm): choice và passage → `passage` (không có thì `essayPrompt`/`question`);
  blank-fill → đoạn có ô trống; reorder → các đoạn theo thứ tự đúng; listening và dialogue → transcript; chart → tiêu đề + nhóm + số liệu.
- Chuẩn hóa: chữ thường, bỏ mọi ký tự không phải chữ hoặc số, gộp khoảng trắng; hash SHA-256 hex.
- Dùng ở hai nơi: (1) validator từ chối nếu đã có câu cùng `task_type_key` và `content_hash`, hoặc trùng với câu khác trong cùng job;
  (2) danh sách `avoidTopics` lấy từ `generation_meta.topic` của 20 câu AI gần nhất cùng dạng.
- Giới hạn đã biết, ghi trong báo cáo phase 8: không bắt được câu gần giống hoặc paraphrase, và không bắt được trùng với câu viết tay.
  Nếu sau này cần, mới cân nhắc embedding (đang nằm trong backlog).

## Phạm vi theo dạng bài

| Nhóm | Dạng | Phase |
|---|---|---|
| Text | MC_READING_SINGLE, MC_READING_MULTIPLE, FIB_DROPDOWN, FIB_DRAG_AND_DROP, RE_ORDER_PARAGRAPHS, SUMMARIZE_WRITTEN_TEXT, WRITE_ESSAY, READ_ALOUD | 2 |
| Audio một giọng | WRITE_FROM_DICTATION, REPEAT_SENTENCE, ANSWER_SHORT_QUESTION, SUMMARIZE_SPOKEN_TEXT, MC_LISTENING_SINGLE/MULTIPLE, HIGHLIGHT_CORRECT_SUMMARY, SELECT_MISSING_WORD, HIGHLIGHT_INCORRECT_WORDS, FILL_IN_THE_BLANKS_TYPE_IN, RE_TELL_LECTURE | 5 |
| Audio nhiều giọng | SUMMARIZE_GROUP_DISCUSSION, RESPOND_TO_A_SITUATION | 6 |
| Biểu đồ | DESCRIBE_IMAGE (BAR, LINE, PIE, TABLE) | 7 |
| Không làm | PERSONAL_INTRODUCTION (không có nội dung để sinh); DI dạng bản đồ hoặc ảnh chụp (admin tự upload) | - |

## Ngoài phạm vi (backlog)

- HOST_ADMIN tự sinh đề cho trung tâm (cần quota theo gói).
- Kiểm tra audio bằng ASR (so WER với transcript), khi có key Azure. Nên làm đầu tiên cho HIW và WFD.
- Chống trùng bằng embedding. Hiện chỉ dùng hash nội dung và đưa danh sách chủ đề gần đây vào prompt.
- Giao diện chỉnh prompt. Prompt nằm trong `resources/question-generation/prompts/` và được version theo deploy.
- Model sinh ảnh, sơ đồ quy trình, bản đồ.

## Rủi ro

| Rủi ro | Giảm thiểu |
|---|---|
| Generator và Reviewer cùng model nên review dễ dãi | Context độc lập, temperature 0, luật cứng do code kiểm tra, người duyệt luôn là chốt cuối; có thể đổi model reviewer qua env |
| LLM trả JSON sai schema | `response_format: json_object`, parse chặt; lỗi parse thì thử lại 1 lần rồi mới tính là FAIL |
| Chi phí hoặc lạm dụng | Tối đa 10 câu mỗi job, tối đa 1 job chạy cùng lúc mỗi người, trần số câu mỗi ngày (config), timeout mỗi lần gọi |
| Kokoro đọc sai số hoặc tên riêng | Prompt yêu cầu viết số bằng chữ và tránh từ viết tắt; đo thời lượng; ASR để backlog |
| App restart giữa chừng | Mỗi câu commit riêng; job RUNNING có heartbeat quá 10 phút thì được worker nhận lại và chạy tiếp từ câu chưa làm |
| Ranh giới module | itembank chỉ gọi `com.pte.scoring.rubric` (public) và `MediaService` (public) |

## Cổng chuẩn mực

Trước khi code phải đọc đủ `docs/CODING_STANDARDS_API.md`, `docs/API_RESPONSE_SETUP.md`, `docs/COMMON_EXCEPTION_SETUP.md`
(phase 1–3, 5–7) và `docs/CODING_STANDARDS_WEB.md` (phase 4). Các ratchet sau phải giữ nguyên: file tối đa 300 dòng,
package `internal/**` tối đa 15 class (nên `generation` tách thành các package con), dùng `Clock` được inject,
thông điệp và mã lỗi đặt trong `QuestionGenerationConstants`.
