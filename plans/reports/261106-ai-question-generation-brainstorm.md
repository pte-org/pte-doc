# Brainstorm: AI tạo câu hỏi cho ngân hàng đề (2026-11-06)

## 1. Mục tiêu

Admin chọn dạng bài, cấp CEFR, chủ đề và số lượng. Hệ thống làm phần còn lại:

1. Agent Generator viết câu hỏi.
2. Agent Reviewer kiểm tra câu hỏi.
3. Kokoro TTS đọc thành audio nếu dạng bài cần audio.
4. Câu hỏi được lưu thành **DRAFT** trong ngân hàng đề.

Người duyệt vẫn là con người. AI chỉ giúp soạn nhanh hơn, không bao giờ tự duyệt.

## 2. Luồng đề xuất

```
vendor-web: form tạo đề
  (taskType, CEFR, topic?, count ≤ 10)
        │  POST /api/v1/itembank/generation-jobs  → 202 + jobId
        ▼
GenerationJob (1 bảng, chạy trong executor nội bộ)
  với mỗi item:
   1. Generator LLM  → JSON theo schema của task type
   2. Validator      → kiểm tra cứng bằng code (không dùng LLM)
   3. Reviewer LLM   → chấm theo checklist, trả verdict + góp ý
        • FAIL  → tạo lại 1 lần, kèm góp ý của Reviewer
        • FAIL lần 2 → bỏ item, ghi lý do vào job
   4. TTS Kokoro     → mp3 → upload Cloudinary (server-side) → MediaAsset
   5. Lưu Question DRAFT + generation_meta (model, review, điểm)
        ▼
vendor-web poll job → danh sách DRAFT kèm "phiếu review AI"
  → người sửa hoặc duyệt theo luồng hiện có
```

## 3. Các quyết định chính

| Vấn đề | Đề xuất | Lý do |
|---|---|---|
| Vị trí code | `itembank/internal/generation/*` | Contract của task type thuộc itembank; không phải mở module mới |
| Gọi 9router | Client OpenAI-compatible riêng, rất mỏng (`/v1/chat/completions`, `response_format: json_object`) | Không phụ thuộc vào `scoring.internal`, giữ ranh giới module |
| Model | Mỗi vai có config riêng; hiện cả hai đều dùng `Capstone` (xem mục 9) | Theo dõi chi phí trên 9router, đổi model không cần sửa code |
| Async | Bảng `question_generation_jobs` + `@Async` executor (1–2 thread) | Mỗi item mất 30–90 giây, không chạy đồng bộ được; chưa cần RabbitMQ |
| Lưu kết quả | Cột JSONB `generation_meta` trên `questions` (nullable) | Người duyệt thấy được lý do AI cho qua; dùng để lọc "đề do AI tạo" |
| Trạng thái | Luôn là `DRAFT`, `pool` theo lựa chọn của admin | Giữ nguyên luồng duyệt hiện có |
| Validation | Gọi lại đúng validator dùng cho `CreateQuestionRequest` | Đề AI phải qua cùng luật với đề viết tay |
| Giới hạn | Tối đa 10 item mỗi job; giới hạn số job mỗi ngày; timeout mỗi lần gọi | Kiểm soát chi phí API key |

## 4. Prompt và checklist review

**Generator**: system prompt riêng cho từng task type, lấy từ `TaskAuthoringRequirements` (số từ, số lựa chọn, có audio hay không...). Prompt kèm 1 ví dụ mẫu tự viết và yêu cầu đầu ra JSON đúng schema. Cấm sao chép đề Pearson thật.

**Validator bằng code**, các lỗi rẻ nên bắt trước khi tốn tiền gọi Reviewer:

- số từ nằm trong min/max;
- đáp án nằm trong các lựa chọn;
- MC_SINGLE có đúng 1 đáp án, MULTIPLE có từ 2 đáp án trở lên;
- số chỗ trống khớp số đáp án;
- RE_ORDER có thứ tự hợp lệ;
- WFD dài 8–14 từ (gợi ý).

**Reviewer**: trả JSON theo dạng sau:

```json
{ "verdict": "PASS|FAIL",
  "checks": {
    "taskFidelity":  {"ok": true, "note": ""},   // đúng format/độ dài dạng bài PTE
    "cefrFit":       {"ok": true, "estimated": "B2", "note": ""},
    "answerKey":     {"ok": true, "note": ""},   // đáp án đúng và duy nhất, distractor không đúng "một nửa"
    "clarity":       {"ok": true, "note": ""},   // ngữ pháp, không mơ hồ
    "safety":        {"ok": true, "note": ""}    // không thiên vị, nhạy cảm, không giống đề thật
  },
  "fixSuggestion": "..." }
```

CEFR do LLM đánh giá thì không thật sự chính xác. Kèm thêm 2 chỉ số cứng tính bằng code để người duyệt tham khảo, không dùng để chặn: độ dài câu trung bình và điểm Flesch–Kincaid. Không làm thêm hệ thống phân loại CEFR riêng.

## 5. Kokoro TTS

- Chạy Kokoro-FastAPI (endpoint OpenAI-compatible `/v1/audio/speech`), gọi qua HTTP từ `app`.
- Mỗi item chọn ngẫu nhiên một giọng trong danh sách giọng Mỹ và Anh (PTE dùng nhiều giọng), tốc độ khoảng 0.9–1.0.
- Dạng hội thoại hoặc thảo luận (SUMMARIZE_GROUP_DISCUSSION, RESPOND_TO_A_SITUATION): Generator trả về từng lượt `speaker`. Mỗi speaker được đọc bằng một giọng, rồi ghép các file mp3 (nối đơn giản, khoảng lặng 300ms).
- Cần thêm **upload phía server** vào `media` (`MediaService.storeGenerated(bytes, kind, tenant)`). Hiện tại chỉ có upload ký từ trình duyệt.
- **Cần lưu ý RAM**: Kokoro chạy CPU tốn khoảng 1–2 GB. VPS Oracle đang chạy cả stack, nên có 2 lựa chọn: (a) chạy Kokoro trên máy dev hoặc máy riêng và trỏ URL qua env; (b) thêm container có `mem_limit`. Nên bắt đầu với (a).

## 6. Phạm vi theo giai đoạn (để tránh over-engineering)

| Giai đoạn | Dạng bài | Cần |
|---|---|---|
| **P1: chỉ text** | MC_READING_SINGLE/MULTIPLE, FIB dropdown/drag-drop, RE_ORDER, SWT, WRITE_ESSAY, READ_ALOUD | LLM ×2, job, generation_meta, UI form + phiếu review |
| **P2: audio** | WFD, REPEAT_SENTENCE, ASQ, SST, MC_LISTENING, HCS, SMW, HIW, L-FIB, RE_TELL_LECTURE | Thêm Kokoro + upload server-side |
| **P3: nhiều giọng** | SGD, RTS | Ghép nhiều giọng |
| **Không làm** | DESCRIBE_IMAGE, PERSONAL_INTRODUCTION | DI cần sinh biểu đồ, làm thì phức tạp mà ít lợi; PI không có nội dung để generate |

Mẹo: các dạng listening dùng transcript làm "nguồn sự thật". Generator viết transcript, câu hỏi và đáp án; Reviewer chấm trên transcript. TTS chỉ chạy **sau khi** Reviewer cho PASS, nên không tốn tiền đọc audio cho đề hỏng.

## 7. Những thứ cố ý KHÔNG làm

- Không dùng agent framework (LangChain, multi-agent loop). Chỉ là 2 lần gọi HTTP và một vòng retry.
- Không tự động duyệt hay publish đề.
- Không dùng embedding để chống trùng lặp. P1 chỉ hash nội dung và gửi kèm danh sách 20 chủ đề gần nhất vào prompt để model né.
- Không làm queue hay worker riêng. Nếu sau này cần scale thì mới chuyển sang RabbitMQ.
- Không làm UI chỉnh prompt. Prompt nằm trong resources, có version, đổi bằng cách deploy.

## 8. Ước lượng thay đổi

- **Backend**:
  - migration V34 thêm bảng `question_generation_jobs` và cột `questions.generation_meta jsonb`;
  - khoảng 10–12 class: properties, client 9router, client Kokoro, registry prompt, validator, reviewer, job service, controller, constants;
  - test với LLM stub.
- **Media**: thêm 1 method upload phía server.
- **vendor-web**: trang "Tạo đề bằng AI" (form + bảng tiến độ job) và panel "Review AI" trong màn chi tiết câu hỏi.
- **Config** (env, không commit giá trị): `QUESTION_GEN_BASE_URL`, `QUESTION_GEN_API_KEY`, `QUESTION_GEN_GENERATOR_MODEL`, `QUESTION_GEN_REVIEWER_MODEL`, `KOKORO_BASE_URL`, `KOKORO_API_KEY`.

## 9. Quyết định đã chốt (2026-11-06)

1. **Kokoro** chạy trên server riêng của chủ dự án (`<host>/kokoro`), qua endpoint OpenAI-compatible
   `/v1/audio/speech` và `/v1/audio/voices`, xác thực bằng Bearer key. Vì vậy không chạy Kokoro trên VPS,
   và không còn rủi ro RAM.
2. **9router**: endpoint OpenAI-compatible `/v1/chat/completions`. **Generator và Reviewer đều dùng model
   `Capstone`** để chủ dự án theo dõi được chi phí trên 9router. Tên model là config riêng cho từng vai
   (`QUESTION_GEN_GENERATOR_MODEL`, `QUESTION_GEN_REVIEWER_MODEL`), nên sau này đổi model không cần sửa code.
   - Rủi ro: dùng cùng một model thì Reviewer dễ dễ dãi với bài do chính nó viết.
   - Giảm rủi ro bằng 3 cách: Reviewer chạy ở context độc lập (không thấy prompt hay lập luận của
     Generator), dùng temperature 0, và mọi luật đo được đều do validator bằng code kiểm tra, không giao cho LLM.
3. **Người dùng**: giai đoạn này chỉ vendor admin (ngân hàng đề chuẩn). HOST_ADMIN để sau.
4. **Pool**: admin chọn PRACTICE hoặc EXAM ngay trên form tạo đề, dùng cờ availability như hiện có.
5. Key và URL chỉ để trong `.env.local` hoặc `.env` của VPS. Không ghi vào tài liệu, không commit.

## 10. Tiêu chí câu hỏi suy ra từ rubric chấm

Rubric chấm câu trả lời, nhưng từ đó suy ra được câu hỏi cần thỏa điều kiện gì để **chấm được và
chấm công bằng** (scorability). Rubric không cho biết độ khó, nên CEFR vẫn kiểm tra riêng.

| Dạng | Rubric | Ràng buộc với câu hỏi |
|---|---|---|
| RA | Content, Pronunciation, Fluency | 50–60 từ, ít tên riêng hoặc số khó đọc |
| RS | Content theo % từ đúng thứ tự | 8–15 từ |
| WFD | Mỗi từ đúng 1 điểm | 8–14 từ, không có từ đồng âm gây mơ hồ |
| SWT / SST / RL | Content theo ý chính | Có 3–4 ý chính rõ, xuất ra `keyPoints` |
| WE | Content, Form 200–300 từ, Development... | Đề tranh luận được, không cần kiến thức chuyên môn |
| ASQ | Đúng hoặc sai | Đáp án 1–2 từ, kiến thức phổ thông, chỉ có một đáp án |
| MC Multiple | +1 / −1 | 2–3 đáp án đúng; distractor phải sai hẳn theo văn bản |
| RO | Chấm theo cặp liền kề | 4–5 đoạn có dấu nối logic, chỉ một thứ tự hợp lý |
| HIW | +1 / −1 theo từng từ | Đúng N (4–7) từ bị thay, từ thay không trùng âm với từ gốc |
| FIB | Mỗi ô trống 1 điểm | Mỗi ô trống chỉ có một đáp án đúng |

- Reviewer nhận thêm danh sách trait và level descriptor của dạng bài, lấy từ `com.pte.scoring.rubric.RubricCatalog`
  (package public). Checklist thêm mục `scorability`.
- Các luật đo được trong bảng trên do validator bằng code kiểm tra.

## 11. Dạng có audio hoặc hình

Nguyên tắc: AI chỉ sinh **dữ liệu gốc dạng text** (transcript, số liệu). Reviewer duyệt trên dữ liệu đó.
Sau khi duyệt, code mới đọc thành audio hoặc vẽ thành ảnh.

- **Listening**:
  - Generator trả về `transcript`, câu hỏi và đáp án. Code kiểm tra độ dài và tính nhất quán
    (các ô trống của L-FIB nằm trong transcript; HIW có đúng N từ khác).
  - Kokoro đọc transcript, chọn ngẫu nhiên giọng Mỹ hoặc Anh.
  - Code đo thời lượng audio.
  - Tùy chọn: chạy ASR rồi so với transcript (loại nếu WER > 5%). Bật trước cho HIW và WFD khi có key Azure.
- **Speaking**:
  - RA chỉ là text.
  - RS, ASQ, RL, RTS dùng Kokoro.
  - SGD: hội thoại `[{speaker, text}]`, mỗi speaker một giọng cố định, ghép file kèm 300ms khoảng lặng.
  - `keyPoints` và đáp án mẫu được lưu vào `referenceAnswerText` để AI scorer chấm Content ổn định hơn.
- **Describe Image**:
  - Generator trả về số liệu biểu đồ (BAR / LINE / PIE / TABLE) và `keyPoints`.
  - Code kiểm tra: pie có tổng 100%, có 3–8 nhóm, keyPoint khớp max/min và xu hướng.
  - Backend vẽ PNG bằng **XChart** (Java, headless, Apache 2.0), rồi upload Cloudinary phía server.
  - Có thể cho Reviewer (model có vision) xem lại ảnh.
  - Bản đồ và ảnh chụp: không sinh, admin tự upload.

## 12. Phạm vi cập nhật

- **P1**: Reading, Writing, Read Aloud. Chỉ text.
- **P2**: Listening và Speaking có audio (Kokoro, upload server-side).
- **P3**: SGD nhiều giọng, Describe Image theo cách dữ liệu → XChart.

→ Bước tiếp theo: `/ck:plan`.
