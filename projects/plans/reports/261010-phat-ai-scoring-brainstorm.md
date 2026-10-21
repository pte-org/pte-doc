# Brainstorm: Chấm điểm AI cho 10 dạng bài PTE (port từ ai-research)

**Date:** 2026-10-10

## Ideas Explored

1. **Port logic POC Python sang Java trong module `scoring`.** Azure Speech dùng Java SDK, Gemini gọi qua endpoint OpenAI-compatible bằng `OpenAiCompatibleChatClient` có sẵn. **Đã chọn.**
2. **Python worker riêng đọc RabbitMQ.** Tái dùng gần nguyên code POC. Bị loại vì phải deploy thêm 1 service, có contract giữa 2 ngôn ngữ, và phải tự lo auth để tải audio từ `media`.
3. **Java + Azure REST short-audio** (không cần native SDK). Bị loại làm hướng chính vì REST giới hạn 60 giây (Group Discussion cho trả lời tới 120 giây) và không có Prosody. Giữ làm phương án dự phòng nếu SDK native lỗi trong Docker.
4. **Giữ adapter OpenAI-compatible hiện tại.** Adapter này gửi audio thẳng vào chat model với 1 prompt chung cho mọi dạng. Bị loại vì không có pronunciation assessment và prompt không bám theo từng dạng. Chỉ tái dùng phần client chat để gọi Gemini.
5. **Tự chấm ngay khi nộp bài**, tức đổi quy tắc host-gated của ADR-002. User bác: giữ thời điểm chấm theo ADR-002.
6. **Cách examiner thấy điểm AI:** chấm mù, thấy sau khi tự chấm, hoặc luôn thấy. User chọn **luôn thấy**.

## Hiện trạng (scout)

- Cả 10 dạng đã có trong `PteTaskType`, runtime profile và ScoreTemplate: 7 dạng `AI_SPEECH`, 3 dạng `AI_TEXT`.
- Pipeline queue đã chạy:
  - `ScoringCommandService.requestScoring` (host bấm) → `AiScoringDispatcher` → exchange `scoring.ai-scoring` → `AiScoringWorker`.
  - Retry 3 lần (2–10s), sau đó vào DLQ và chuyển `SCORING_FAILED`. Worker idempotent theo `answerPublicId`.
  - Concurrency để mặc định (1 consumer).
- Vendor mặc định là stub. Adapter OpenAI-compatible chỉ có 2 prompt chung (speech/essay) và chỉ trả `rawScore`. `subScores` và `feedback` không được lưu ("documented scope cut").
- **Lỗi dữ liệu:** `AiScoringJob.referenceText` chỉ lấy từ `correctAnswerText`, mà trường này null với hầu hết các dạng. Bật provider thật thì Read Aloud lỗi ngay với `SPEECH_REFERENCE_TEXT_EMPTY`.
- Dữ liệu đề trong question bank đủ cho logic POC:

  | Dạng | Trường chứa dữ liệu |
  |---|---|
  | Read Aloud | `promptText` |
  | Repeat Sentence, Retell Lecture | `referenceAnswerText` (transcript) |
  | ASQ | `correctAnswerText` = `"a / b / c"` |
  | Respond to a Situation | `promptText` = tình huống |
  | SST | `promptText` = transcript |
  | SWT, Write Essay | `promptText` + `min/maxWordCount` |
  | Describe Image | `imagePromptRef` + `referenceAnswerText` (bài mẫu) |

- **Group Discussion không có câu nào** trong file import lẫn bộ seed 150.
- Phần chấm tay và chọn nguồn điểm đã có: `ExaminerAnswerScore`, `ScoreSource` AI/EXAMINER kèm audit, và `HostScoreReviewPanel` hiển thị `aiRawScore`. Màn examiner (`ExaminerWorkView`) chưa hiển thị điểm AI.
- App ghi âm `AudioEncoder.wav`, chưa set sample rate hay số kênh. Docker runtime là `eclipse-temurin:21-jre` (Ubuntu).

## User's Direction

- "đương nhiên triển khai ở phía backend": port sang Java trong `pte-api`.
- "dùng rabbitMQ để đưa message bài thi vào cho AI chấm dần. Tránh bị quá tải cho hệ thống cũng như quá tải cho bên phía AI". Thời điểm chấm giữ theo ADR-002: host bấm chấm thì mới enqueue.
- "Host và Examiner sẽ xem được điểm AI và có thể thêm 1 cột chấm tay": hiển thị điểm kèm chi tiết (tiêu chí, feedback, transcript). Examiner **luôn thấy** điểm AI.
- "Full 10 dạng bài PTE Academic dùng AI như project mẫu".
- Model Gemini cấu hình được, mặc định `gemini-flash-lite-latest`.
- Quy mô: **chỉ demo đồ án**, ưu tiên chạy đúng và ổn định hơn thông lượng.

## Open Questions

- **Định dạng audio.** Package `record` mặc định ghi 44.1 kHz, 2 kênh. Cần xác minh Azure Speech Java SDK có đọc thẳng được không. Nếu không, backend downmix và resample về 16 kHz mono PCM. Nên xử lý ở backend để chấm được cả bản ghi cũ.
- **Media ảnh Describe Image.**
  - Media câu hỏi trong DB local đang 404 vì folder Cloudinary đã bị xoá.
  - `MediaService.presignGet` scope theo tenant; cần xác minh tenant của session tải được ảnh câu hỏi của vendor hay không.
  - Fallback: chấm bằng `referenceAnswerText` (mô tả mẫu) khi không lấy được ảnh.
- **Dữ liệu Group Discussion.** Plan cần tạo 1–2 câu SGD, có thể dựa trên fixture POC `samples/remaining/group_discussion/source_labeled.txt` cộng audio.
- **Chỗ lưu chi tiết AI:** bảng riêng (vd `scoring_ai_assessment`) hay cột JSON trên `scoring_answer`.
- **Chấm lại câu `SCORING_FAILED`:** hiện đây là trạng thái cuối. Cần chốt lần bấm chấm sau có reset về `PENDING` rồi enqueue lại hay không.
- **Tác động lên ADR-002.** Không đổi thời điểm chấm, nhưng ADR cần ghi thêm phần chi tiết AI và việc examiner được thấy điểm AI.

## Risks

1. **Độ chính xác chưa được xác thực.** POC chỉ self-test xếp hạng, chưa đối chiếu với điểm PTE thật. flash-lite phân biệt yếu ở SWT và Describe Image (gap 2.2–7.5 điểm, chỉ ngang mức jitter). Giảm thiểu: gắn nhãn "AI ước lượng" trên UI; examiner và host có cột chấm tay cùng `ScoreSource` để thay điểm.
2. **Quota và độ ổn định của free tier.** POC đã gặp Gemini 503 và quota 20 request/ngày với model mạnh. Retry hiện tại (3 lần × 2–10s) quá ngắn cho 429/503, nên câu sẽ rơi vào `SCORING_FAILED` hàng loạt. Cần backoff dài hơn cho lỗi tạm thời, concurrency thấp, và cách chấm lại.
3. **Native lib của Azure Speech Java SDK trong Docker, cộng chuyện định dạng audio.** Lỗi ở đây chỉ lộ ra khi chạy container. Cần spike sớm ở phase đầu; nếu không chạy được thì chuyển sang REST cho câu ≤ 60 giây.
