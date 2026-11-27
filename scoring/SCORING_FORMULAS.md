# Công thức chấm điểm

Tài liệu tóm tắt các công thức đang chạy trong `pte-api` (module `com.pte.scoring` và `com.pte.reporting`). Cơ chế và lý do thiết kế xem `AI_LOGIC.md`; chi tiết quy đổi Azure xem `plans/reports/261110-pte-scoring-and-azure-band-mapping-report.md`.

Cập nhật 2026-11-20: mục 1.2–1.4 viết lại theo `RubricScorer` (chấm theo tiêu chí, thay cho các công thức trung bình Azure/Gemini cũ).

Điểm đi qua ba tầng:

```
Câu trả lời ──► Điểm từng tiêu chí ──► Điểm câu 0–100 ──► Trung bình theo dạng ──► Điểm kỹ năng / Overall 10–90
                 (AI, Azure, máy, giám khảo)   RubricScorer         AggregationCore          AggregationCore
```

1. **Điểm câu (raw)**, thang 0–100. Câu khách quan do bộ chấm đáp án tính; câu nói/viết chấm theo tiêu chí rồi gộp bằng `RubricScorer`.
2. **Trung bình theo dạng bài.**
3. **Điểm kỹ năng và điểm tổng**, thang 10–90, theo trọng số của template đề thi.

---

## 1. Điểm câu (0–100)

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
- Kết quả làm tròn về số nguyên.

### 1.2 Câu chấm theo tiêu chí (`RubricScorer`, 10 dạng)

```
Điểm câu = làm tròn nửa lên( Σ(trọng số × đạt được / tối đa) ÷ Σ trọng số × 100 )
```

- Trọng số mặc định bằng điểm tối đa của tiêu chí, nên công thức rút gọn thành **Σ đạt được ÷ Σ tối đa × 100**.
- **Cổng điểm 0 (gate):** tiêu chí có gate bằng 0 thì cả câu được 0 (Score Guide tr. 8).
- Điểm tiêu chí phải là số nguyên trong thang; ngoài thang thì báo lỗi, không tự kẹp.
- Thang và gate theo PTE Academic Test Taker Score Guide (bản 2026, tr. 15–44).

| Dạng | Tiêu chí (tối đa · nguồn) | Σ tối đa | Gate |
|---|---|---|---|
| Read Aloud | Content (N từ · máy), Pronunciation (5 · Azure), Oral Fluency (5 · Azure) | N + 10 | Không |
| Repeat Sentence | Content (3 · máy), Pronunciation 5, Oral Fluency 5 | 13 | Không |
| Describe Image, Re-tell Lecture, Respond to a Situation, Summarize Group Discussion | Content (6 · LLM), Pronunciation 5, Oral Fluency 5 | 16 | Content |
| Answer Short Question | Vocabulary (1 · máy so đáp án) | 1 | Không |
| Summarize Written Text | Content 4, Form 1 (máy), Grammar 2, Vocabulary 2 | 9 | Content, Form |
| Summarize Spoken Text | Content 4, Form 2 (máy), Grammar 2, Vocabulary 2, Spelling 2 | 12 | Content, Form |
| Write Essay | Content 6, Form 2 (máy), Development/Structure/Coherence 6, Grammar 2, General Linguistic Range 6, Vocabulary Range 2, Spelling 2 | 26 | Content, Form |

Tiêu chí không ghi nguồn là do LLM chấm. Giám khảo có thể ghi đè điểm tiêu chí.

**Content do máy tính:**
- Read Aloud: N = số từ của đoạn văn; mỗi từ thay, bỏ sót hoặc chèn thêm là 1 lỗi; Content = `max(0, N − số lỗi)`.
- Repeat Sentence: đủ mọi từ đúng thứ tự = 3; ≥ 50% = 2; < 50% nhưng có ít nhất 1 từ = 1; không có = 0.
- Answer Short Question: transcript khớp một đáp án được chấp nhận = 1, ngược lại 0.

**Form do code đếm từ:**

| Dạng | Form 2 | Form 1 | Form 0 |
|---|---|---|---|
| Write Essay | 200–300 từ | 120–199 hoặc 301–380 từ | còn lại |
| Summarize Spoken Text | 50–70 từ | 40–49 hoặc 71–100 từ | còn lại |
| Summarize Written Text | (thang 1) | 5–75 từ và đúng một câu | còn lại |

Form cũng bằng 0 khi bài viết toàn chữ in hoa, không có dấu câu, hoặc chỉ gồm gạch đầu dòng.

### 1.3 Quy đổi Azure sang mức Pearson 0–5 (bảng phiên bản 1)

- **Pronunciation** dùng `AccuracyScore`.
- **Oral Fluency** dùng `(FluencyScore + ProsodyScore) / 2`; không có Prosody thì chỉ dùng Fluency.
- Thiếu điểm Azure tính là 0; không làm tròn trước khi so ngưỡng.

| Điểm Azure | ≥ 90 | 75–< 90 | 60–< 75 | 45–< 60 | 30–< 45 | < 30 |
|---|---|---|---|---|---|---|
| Mức | 5 | 4 | 3 | 2 | 1 | 0 |

Bảng do nhóm tự đặt, **chưa hiệu chỉnh với điểm người chấm** (`calibrated = false`).

### 1.4 Ví dụ

- Describe Image: Content 4, Pronunciation 3, Oral Fluency 2 → (4 + 3 + 2) / 16 = 56,25% → **56**. Content = 0 thì cả câu **0**.
- Read Aloud đoạn 50 từ, 5 lỗi, Pronunciation 3, Oral Fluency 2 → (45 + 3 + 2) / 60 = 83,3% → **83**.

---

## 2. Gộp thành điểm kỹ năng và điểm tổng (`AggregationCore`)

### 2.1 Trung bình theo loại task

```
avgRaw(taskType) = Σ raw / (số câu có điểm + số câu bỏ trống)
```

- Câu bỏ trống (không có bản ghi trả lời) tính **0 điểm**.
- Câu AI đang chấm, hoặc dạng không chấm điểm (ví dụ Personal Introduction), không tính vào cả tử lẫn mẫu.

### 2.2 Điểm từng kỹ năng (10–90)

```
điểm kỹ năng = 10 + 80 × Σ( w × avgRaw / 100 ) / Σw
```

- `w` là trọng số của loại task theo kỹ năng đang tính: `speakingWeight`, `writingWeight`, `readingWeight`, `listeningWeight`.
- Chỉ tính loại task có `w > 0` và đã có `avgRaw`.
- Loại task bỏ trống hoàn toàn vẫn nằm trong công thức với `avgRaw = 0`.
- Kỹ năng bỏ trống hoàn toàn ra **10 điểm**.
- `Σw ≤ 0` thì hiển thị "—" (thiếu dữ liệu).
- Dạng tích hợp (ví dụ Write From Dictation: Writing 26, Listening 14) góp cùng một `avgRaw` vào mỗi kỹ năng với trọng số riêng; không chia đôi.

### 2.3 Điểm tổng

- Cùng công thức nhưng dùng `overallWeight` (trung bình 4 trọng số kỹ năng của loại task).
- Không phải trung bình cộng của 4 điểm kỹ năng (Score Guide tr. 6 cũng nêu điều này).
- Chỉ tính khi cả 4 kỹ năng đều được thi.

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
- Báo cáo đã phát hành mà không có snapshot trả về `AttemptScoreSummary(null, Map.of())`, tức không có điểm.

## 4. Nguồn mã

| Nội dung | File |
|---|---|
| Câu có đáp án sẵn | `scoring/internal/service/objective/*Scorer.java`, `ObjectiveScoringService.java` |
| Điểm câu theo tiêu chí | `scoring/rubric/RubricScorer.java` |
| Thang, gate, Form | `scoring/internal/rubric/catalog/**` |
| Quy đổi Azure | `scoring/internal/rubric/speech/SpeechBands.java`, `AzureBandMapping.java`, `catalog/AzureBandMappingCatalog.java` |
| Content đo bằng máy | `scoring/internal/rubric/speech/ReadAloudContent.java`, `RepeatSentenceContent` |
| Câu nói Azure, Azure + LLM, câu viết | `scoring/internal/vendor/azure/*`, `scoring/internal/vendor/gemini/scorer/*` |
| Gộp điểm, trọng số | `reporting/internal/service/aggregation/AggregationCore.java` |
