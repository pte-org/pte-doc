# Công thức chấm điểm

Tài liệu tóm tắt các công thức đang chạy trong `pte-api` (module `com.pte.scoring` và `com.pte.reporting`). Cơ chế và lý do thiết kế xem `AI_LOGIC.md`.

Điểm đi qua hai bước:

1. **Điểm thô (raw)** của từng câu, thang 0–100. Do bộ chấm đáp án sẵn hoặc AI tính.
2. **Điểm kỹ năng và điểm tổng**, thang 10–90. Gộp điểm thô theo loại task, rồi theo trọng số của template đề thi.

---

## 1. Điểm thô của từng câu (0–100)

### 1.1 Câu có đáp án sẵn (`ObjectiveScoringService`)

| Dạng | Công thức |
|---|---|
| Chọn 1 đáp án (MC Reading/Listening single, Highlight Correct Summary, Select Missing Word) | Đúng = 100, sai = 0 |
| Chọn nhiều đáp án (MC multiple) | `max(đúng − sai, 0) / số đáp án đúng × 100` |
| Re-order Paragraphs | `số cặp liền kề đúng / (số đoạn − 1) × 100`. Cặp đúng khi `đoạn[i+1] = đoạn[i] + 1` |
| Fill-blanks kéo thả / dropdown | `số ô đúng / tổng số ô × 100` |
| Fill-blanks gõ tay (Listening) | `số ô đúng / tổng số ô × 100`. Bỏ qua hoa thường và khoảng trắng thừa |
| Highlight Incorrect Words | `max(từ chọn đúng − từ chọn sai, 0) / số từ đúng × 100` |
| Write From Dictation | `LCS(từ chuẩn, từ đã viết) / số từ chuẩn × 100` |

- LCS là dãy con chung dài nhất, nên từ sai thứ tự hoặc lặp lại không được tính.
- Đáp án chuẩn bị lỗi định dạng thì câu đó ra 0, không bao giờ ra 100.

### 1.2 Câu nói chấm bằng Azure

| Dạng | Công thức |
|---|---|
| Read Aloud | Có prosody: `0.4×Accuracy + 0.2×Fluency + 0.2×Prosody + 0.2×Completeness`. Không có prosody: `0.5×Accuracy + 0.25×Fluency + 0.25×Completeness` |
| Repeat Sentence | `(Content + Pronunciation + Fluency) / 3` |
| Answer Short Question | Nói đúng một trong các đáp án chấp nhận = 100, còn lại = 0 |

- Completeness của Read Aloud do backend tự đo, bằng recall khi so lời nói với đoạn văn.
- Content của Repeat Sentence là điểm F1 khi so khớp từ với câu gốc.

### 1.3 Câu nói chấm bằng Azure + Gemini

Áp dụng cho Describe Image, Retell Lecture, Summarize Group Discussion, Respond to Situation.

- Azure nghe và trả transcript, Fluency, Prosody. Gemini chấm nội dung theo transcript.
- Điểm = `trung bình(Content, Fluency, Prosody)`.
- Thiếu prosody:

| Dạng | Cách xử lý |
|---|---|
| Describe Image, Retell Lecture | Vẫn chia cho 3, tức prosody tính 0 |
| Summarize Group Discussion, Respond to Situation | Chỉ lấy trung bình hai thành phần còn lại |

- Không nói gì thì ra 0, không tính là lỗi.
- Respond to Situation có thêm các sub-score TASK_FULFILMENT, RELEVANCE, REGISTER. Chúng chỉ để hiển thị, không vào công thức.

### 1.4 Câu viết chấm bằng Gemini (`GeminiWritingScorer`)

Điểm = trung bình các tiêu chí của dạng bài. Bỏ trống thì ra 0.

| Dạng | Tiêu chí |
|---|---|
| Summarize Written Text | content, form, grammar, vocabulary |
| Write Essay | content, form, development, grammar, general_linguistic_range, vocabulary, spelling |
| Summarize Spoken Text | content, form, grammar, vocabulary, spelling |

**Tiêu chí Form do code đếm từ**, vì mô hình đếm từ không chính xác. Đạt = 100, trượt = 0.

| Dạng | Khoảng hợp lệ mặc định |
|---|---|
| Summarize Written Text | 5–75 từ và đúng 1 câu |
| Write Essay | 200–300 từ |
| Summarize Spoken Text | 50–70 từ |

- Nếu câu hỏi tự đặt min/max từ thì dùng giá trị đó.
- Summarize Written Text và Write Essay: Gemini vẫn chấm Form, nhưng trượt kiểm tra từ thì Form bằng 0.
- Summarize Spoken Text: Form lấy luôn kết quả kiểm tra từ của code.

---

## 2. Gộp thành điểm kỹ năng và điểm tổng (`ScoreAggregationService`)

### 2.1 Trung bình theo loại task

```
avgRaw(taskType) = Σ raw / (số câu có điểm + số câu bỏ trống)
```

- Câu bỏ trống (không có bản ghi trả lời) tính **0 điểm**. Đây là quy tắc "phương án B".
- Câu AI đang chấm, hoặc dạng không chấm điểm (ví dụ Personal Introduction), không tính vào cả tử lẫn mẫu.

### 2.2 Điểm từng kỹ năng (10–90)

```
điểm kỹ năng = 10 + 80 × Σ( w × avgRaw / 100 ) / Σw
```

- `w` là trọng số của loại task đó trong template, theo kỹ năng đang tính: `speakingWeight`, `writingWeight`, `readingWeight`, `listeningWeight`.
- Chỉ tính loại task có `w > 0` và đã có `avgRaw`.
- Loại task bỏ trống hoàn toàn vẫn nằm trong công thức với `avgRaw = 0`.
- Kỹ năng bỏ trống hoàn toàn ra **10 điểm**, không còn là "—".
- `Σw ≤ 0` thì hiển thị "—" (thiếu dữ liệu).

### 2.3 Điểm tổng

- Cùng công thức nhưng dùng `overallWeight`.
- Chỉ tính khi cả 4 kỹ năng đều được thi. Kỹ năng không thi thì không hiện.

### 2.4 Làm tròn

HALF_UP về số nguyên.

### 2.5 Ví dụ

Writing có Summarize Written Text (w = 1, avgRaw = 60) và Write Essay (w = 2, avgRaw = 30):

```
10 + 80 × (1×0.6 + 2×0.3) / 3 = 10 + 80 × 0.4 = 42
```

---

## 3. Báo cáo đã phát hành

- Báo cáo phát hành lưu snapshot (`reportSnapshotJson`) và luôn đọc từ snapshot, không tính lại.
- Báo cáo đã phát hành mà không có snapshot trả về `AttemptScoreSummary(null, Map.of())`, tức không có điểm. Đường tính điểm cũ (`aggregateLegacyPublished`) đã bị xoá.

## 4. Nguồn mã

| Nội dung | File |
|---|---|
| Câu có đáp án sẵn | `scoring/internal/service/objective/*Scorer.java`, `ObjectiveScoringService.java` |
| Câu nói Azure | `scoring/internal/vendor/azure/{ReadAloud,RepeatSentence,ShortQuestion}Scorer.java`, `PronunciationFormula.java` |
| Câu nói Azure + Gemini, câu viết | `scoring/internal/vendor/gemini/scorer/*`, `FormCheck.java` |
| Gộp điểm, trọng số | `reporting/internal/service/ScoreAggregationService.java` |
