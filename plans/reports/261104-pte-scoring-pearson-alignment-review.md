# Đối chiếu cơ chế chấm điểm PTE của hệ thống với Pearson Score Guide

Ngày: 2026-11-04
Người lập: quang (thực hiện cùng trợ lý AI)
Phạm vi: `pte-api` — module `scoring` (chấm từng câu), `reporting` (quy đổi 10–90), seed `V1__baseline.sql` (trọng số mẫu chuẩn)
Tài liệu gốc: *PTE Academic Test Taker Score Guide*, Pearson, © 2025, 46 trang —
<https://www.pearsonpte.com/content/dam/ELL/pte/pearsonpte/pdfs/pte-academic-pdfs/PTE-Academic-Test-Taker-Score-Guide.pdf>
Người đọc dự kiến: nhóm phát triển (để quyết định và sửa), giảng viên hướng dẫn (để nắm mức độ bám chuẩn).

Quy ước: **[Pearson]** là điều tài liệu nói, kèm số trang; **[Hệ thống]** là điều mã nguồn làm, kèm đường dẫn;
**[Suy luận]** là chỗ tài liệu không nói rõ và báo cáo tự diễn giải.

---

## 1. Tóm tắt

Hệ thống chấm theo ba tầng: chấm từng câu ra thang 0–100, chọn nguồn điểm (AI hoặc giám khảo), rồi quy đổi sang thang 10–90
theo trọng số của mẫu đề. So với Pearson:

- **Khớp:** việc gán dạng bài vào kỹ năng (22/22 dạng), số câu mỗi dạng, toàn bộ quy tắc chấm câu khách quan
  (Reading, Listening), và nguyên tắc "điểm Overall không phải trung bình bốn kỹ năng".
- **Lệch đáng kể (cần sửa trước):**
  1. Không có **cổng Content/Form**: Pearson cho cả câu 0 điểm khi Content = 0 hoặc Form = 0; hệ thống chỉ cho tiêu chí đó
     0 rồi vẫn lấy trung bình. Một bài luận 50 chữ hoặc bài nói lạc đề vẫn có thể được khoảng 50–60/100.
  2. Bốn dạng Speaking mở (Describe Image, Re-tell Lecture, Respond to a Situation, Summarize Group Discussion) **không chấm
     Pronunciation**; hệ thống chấm Prosody thay vào.
- **Lệch nhỏ hơn:** Form của Essay/SST chỉ có đạt/không đạt thay vì ba mức; LLM chấm lại Form của SWT/Essay; tỉ trọng
  các tiêu chí bằng nhau thay vì theo điểm tối đa; Read Aloud không có tiêu chí Content riêng; Repeat Sentence tính
  Fluency hai lần; quy trình chấm đôi AI + người khác Pearson.
- **Tài liệu không công bố** trọng số kỹ năng và công thức quy đổi 10–90. Trọng số trong seed và công thức tuyến tính
  `10 + 80 × tỉ lệ` là thiết kế riêng của nhóm, không thể "đúng/sai" theo tài liệu này.

---

## 2. Căn cứ từ Pearson

| # | Nội dung (rút gọn) | Trang |
|---|---|---|
| P1 | Overall 10–90, dựa trên toàn bài; **không phải trung bình** các điểm kỹ năng | 6 |
| P2 | Câu tích hợp (ví dụ Listening + Speaking) đóng góp vào **cả hai** kỹ năng | 6 |
| P3 | Hai kiểu cho điểm: đúng/sai (1 hoặc 0) và partial credit (đúng một phần được một phần điểm) | 7 |
| P4 | Một số câu Speaking/Writing có điểm **Content**; một số câu Writing có điểm **Form** (ví dụ số chữ) | 7 |
| P5 | **Content = 0 hoặc Form = 0 thì cả câu không được điểm.** Ví dụ: essay lạc đề; essay dưới 120 chữ; câu trả lời học thuộc | 8 |
| P6 | Describe Image: chấm Content trước; Content = 0 thì **dừng**; Content > 0 mới chấm Pronunciation và Oral Fluency | 8 |
| P7 | Content do AI và người cùng chấm; bất đồng thì người thứ hai quyết định. Pronunciation và Oral Fluency chỉ do AI chấm | 8 |
| P8 | Người chấm còn xử lý "bất thường" (câu trả lời quá nhỏ, không rõ) mà máy không chấm tin cậy được | 7 |
| P9 | Bảy dạng có người duyệt Content: DI, RL, RTS, SGD, SWT, WE, SST. Write Essay thêm DSC và General Linguistic Range | 15 |
| P10 | Bảng tiêu chí chi tiết từng dạng bài (thang điểm, kỹ năng được tính, số câu) | 15–44 |
| P11 | Thang Pronunciation 0–5 và Oral Fluency 0–5, mô tả từng mức | 45–46 |

Những gì tài liệu **không** có: trọng số của từng dạng bài trong từng kỹ năng, cách cộng điểm tiêu chí thành điểm câu,
cách quy đổi điểm thô sang 10–90. Bảng CEFR ở trang 11 là hình, không ảnh hưởng tới công thức chấm.

---

## 3. Cơ chế chấm hiện tại của hệ thống

### 3.1. Tầng 1 — chấm từng câu, thang 0–100

**Câu khách quan** — [Hệ thống] [ObjectiveScoringService.java](../../../pte-api/app/src/main/java/com/pte/scoring/internal/service/objective/ObjectiveScoringService.java),
[OptionAnswerScorer.java](../../../pte-api/app/src/main/java/com/pte/scoring/internal/service/objective/OptionAnswerScorer.java),
[ReferenceAnswerScorer.java](../../../pte-api/app/src/main/java/com/pte/scoring/internal/service/objective/ReferenceAnswerScorer.java):

| Dạng bài | Công thức |
|---|---|
| MC single (Reading, Listening), Highlight Correct Summary, Select Missing Word | đúng 100, sai 0 |
| MC multiple (Reading, Listening), Highlight Incorrect Words | max(đúng − sai, 0) / số đáp án đúng × 100 |
| Re-order Paragraphs | số cặp liền kề đúng / (số đoạn − 1) × 100 |
| FIB Drag and Drop, FIB Dropdown | số ô đúng / số ô × 100 |
| FIB Type In (Listening) | số ô khớp chính xác (không phân biệt hoa thường, gộp khoảng trắng) / số ô × 100 |
| Write From Dictation | độ dài dãy con chung dài nhất (LCS) theo từ / số từ đáp án × 100 |

**Câu chấm bằng AI** — [Hệ thống] thư mục `scoring/internal/vendor/`:

| Dạng bài | Công thức điểm câu (`rawScore`) |
|---|---|
| Read Aloud | `pronunciation = 0.4·accuracy + 0.2·fluency + 0.2·prosody + 0.2·completeness` (không có prosody: `0.5 / 0.25 / 0.25`); completeness = tỉ lệ từ của đoạn văn được nói ra ([PronunciationFormula.java](../../../pte-api/app/src/main/java/com/pte/scoring/internal/vendor/azure/PronunciationFormula.java), [ReadAloudScorer.java:62](../../../pte-api/app/src/main/java/com/pte/scoring/internal/vendor/azure/ReadAloudScorer.java#L62)) |
| Repeat Sentence | `(content + pronunciation + fluency) / 3`; content = F1 giữa câu gốc và lời nói, so khớp có thứ tự ([RepeatSentenceScorer.java:47](../../../pte-api/app/src/main/java/com/pte/scoring/internal/vendor/azure/RepeatSentenceScorer.java#L47), [TokenAlignment.java](../../../pte-api/app/src/main/java/com/pte/scoring/internal/vendor/speech/TokenAlignment.java)) |
| Answer Short Question | khớp đáp án 100, không khớp 0 |
| DI, RL, RTS, SGD | trung bình `content` (Gemini) + `fluency` (Azure) + `prosody` (Azure) ([GeminiSpeakingScorer.java:105](../../../pte-api/app/src/main/java/com/pte/scoring/internal/vendor/gemini/scorer/GeminiSpeakingScorer.java#L105)) |
| SWT, WE, SST | trung bình cộng các tiêu chí, mỗi tiêu chí 0–100 ([GeminiWritingScorer.java:107](../../../pte-api/app/src/main/java/com/pte/scoring/internal/vendor/gemini/scorer/GeminiWritingScorer.java#L107)) |

Tiêu chí của các dạng viết: SWT = content, form, grammar, vocabulary; WE = content, form, development, grammar,
general_linguistic_range, vocabulary, spelling; SST = content, form, grammar, vocabulary, spelling.

### 3.2. Tầng 2 — chọn nguồn điểm

[Hệ thống] Với câu chấm bằng AI, Host chọn điểm **AI** hoặc điểm **Examiner** (giám khảo nhập 0–100)
cho từng câu ([ScoreSourceSelectionService.java](../../../pte-api/app/src/main/java/com/pte/scoring/internal/service/selection/ScoreSourceSelectionService.java)).
Câu chấm bằng AI mà chưa được chọn nguồn thì **chặn publish**
([ScoringReviewReadQueryService.java](../../../pte-api/app/src/main/java/com/pte/scoring/internal/service/review/ScoringReviewReadQueryService.java), hàm `blockingReason`;
[ReportPublishService.java](../../../pte-api/app/src/main/java/com/pte/reporting/internal/service/ReportPublishService.java)).
Màn hình xem trước của Host dùng tạm điểm AI cho câu chưa chọn; báo cáo đã publish thì không.

### 3.3. Tầng 3 — quy đổi 10–90

[Hệ thống] [ScoreAggregationService.java](../../../pte-api/app/src/main/java/com/pte/reporting/internal/service/ScoreAggregationService.java):

```
avgRaw(dạng bài) = Σ điểm các câu đã có điểm / (số câu đã có điểm + số câu bỏ trống)
Điểm kỹ năng     = làm tròn( 10 + 80 × Σ(w × avgRaw / 100) / Σw )
```

- `w` lấy từ các cột `speaking_weight / writing_weight / reading_weight / listening_weight` của `exam_definition_items`.
  Mẫu đề được ghim vào lượt thi nên đổi mẫu sau này không làm đổi điểm đã công bố.
- Câu bỏ trống tính 0. Dạng bài chưa có điểm bị loại khỏi cả tử và mẫu. `Σw = 0` cho kết quả "không đủ dữ liệu".
- Overall dùng cột `overall_weight` riêng và chỉ được tính khi bài thi có đủ bốn kỹ năng.

---

## 4. Những điểm khớp với Pearson

### 4.1. Gán dạng bài vào kỹ năng và số câu

Cột "Kỹ năng theo Pearson" lấy từ cột *Communicative skills scored* (trang 15–44). Cột trọng số lấy từ seed của mẫu chuẩn.
Một dạng bài có trọng số khác 0 ở đúng những kỹ năng Pearson liệt kê thì ghi "khớp".

| Dạng bài | Số câu (Pearson / seed) | Kỹ năng theo Pearson | Trọng số seed S / W / R / L | Kết quả |
|---|---|---|---|---|
| Read Aloud | 6–7 / 6–7 | Speaking | 9 / 0 / 0 / 0 | khớp |
| Repeat Sentence | 10–12 / 10–12 | Listening, Speaking | 16 / 0 / 0 / 17 | khớp |
| Describe Image | 5–6 / 5–6 | Speaking | 31 / 0 / 0 / 0 | khớp |
| Re-tell Lecture | 2–3 / 2–3 | Listening, Speaking | 13 / 0 / 0 / 13 | khớp |
| Answer Short Question | 5–6 / 5–6 | **Listening** | 0 / 0 / 0 / 4 | khớp |
| Summarize Group Discussion | 2–3 / 2–3 | Listening, Speaking | 19 / 0 / 0 / 20 | khớp |
| Respond to a Situation | 2–3 / 2–3 | Speaking | 13 / 0 / 0 / 0 | khớp |
| Summarize Written Text | 2 / 2 | Reading, Writing | 0 / 28 / 23 / 0 | khớp |
| Write Essay | 1 / 1 | Writing | 0 / 31 / 0 / 0 | khớp |
| FIB Dropdown (Reading) | 5–6 / 5–6 | Reading | 0 / 0 / 25 / 0 | khớp |
| MC Multiple (Reading) | 2–3 / 2–3 | Reading | 0 / 0 / 5 / 0 | khớp |
| Re-order Paragraphs | 2–3 / 2–3 | Reading | 0 / 0 / 9 / 0 | khớp |
| FIB Drag and Drop | 4–5 / 4–5 | Reading | 0 / 0 / 20 / 0 | khớp |
| MC Single (Reading) | 2–3 / 2–3 | Reading | 0 / 0 / 3 / 0 | khớp |
| Summarize Spoken Text | 1 / 1 | Listening, Writing | 0 / 18 / 0 / 10 | khớp |
| MC Multiple (Listening) | 2–3 / 2–3 | Listening | 0 / 0 / 0 / 3 | khớp |
| FIB Type In | 2–3 / 2–3 | Listening | 0 / 0 / 0 / 8 | khớp |
| Highlight Correct Summary | 2–3 / 2–3 | Listening, Reading | 0 / 0 / 3 / 2 | khớp |
| MC Single (Listening) | 2–3 / 2–3 | Listening | 0 / 0 / 0 / 2 | khớp |
| Select Missing Word | 1–2 / 1–2 | Listening | 0 / 0 / 0 / 1 | khớp |
| Highlight Incorrect Words | 2–3 / 2–3 | Listening, Reading | 0 / 0 / 13 / 8 | khớp |
| Write From Dictation | 3–4 / 3–4 | Listening, Writing | 0 / 23 / 0 / 13 | khớp |

### 4.2. Quy tắc chấm câu khách quan

Quy tắc chấm của tất cả các dạng ở trang 40 và 44 đều khớp với bảng ở mục 3.1: chấm theo từng ô; +1/−1 và thấp nhất 0
cho MC Multiple và HIW; chấm theo cặp liền kề cho Re-order; đúng/sai cho MC Single, HCS, SMW, ASQ.

### 4.3. Tổng hợp

Overall dùng bộ trọng số riêng (khớp P1). Câu tích hợp có trọng số ở cả hai kỹ năng (khớp P2).

---

## 5. Những điểm lệch

Mức độ: **Cao** = làm sai lệch điểm câu một cách có hệ thống; **Trung bình** = lệch ở một số trường hợp biên;
**Thấp** = lệch về cách làm, ít ảnh hưởng điểm.

### L1. Không có cổng Content/Form — **Cao**

- [Pearson] Content = 0 hoặc Form = 0 thì cả câu không có điểm (P5). Với Speaking, Content = 0 thì không chấm tiếp (P6).
- [Hệ thống] Không có nhánh nào đưa điểm câu về 0 khi Content = 0. Với dạng viết, Form không đạt chỉ làm tiêu chí form bằng 0
  ([FormCheck.java](../../../pte-api/app/src/main/java/com/pte/scoring/internal/vendor/gemini/FormCheck.java) `score()`),
  rồi vẫn lấy trung bình với các tiêu chí còn lại.
- Ví dụ:
  - Essay 50 chữ, sáu tiêu chí còn lại mỗi tiêu chí 70 → hệ thống cho `(0 + 6×70) / 7 = 60`, Pearson cho 0.
  - Describe Image nói lạc đề: content 0, fluency 80, prosody 75 → hệ thống cho khoảng 52, Pearson cho 0.
- Áp dụng cho: DI, RL, RTS, SGD (Content); SWT, WE, SST (Content và Form).

### L2. Speaking mở không chấm Pronunciation — **Cao**

- [Pearson] DI, RL, RTS, SGD chấm Content, **Pronunciation**, Oral Fluency (trang 18–31).
- [Hệ thống] Chấm `content + fluency + prosody` ([GeminiSpeakingScorer.java:91-105](../../../pte-api/app/src/main/java/com/pte/scoring/internal/vendor/gemini/scorer/GeminiSpeakingScorer.java#L91-L105)).
  Azure trả về `accuracy` (độ chính xác phát âm) nhưng nhánh này không dùng. Prosody đo nhịp điệu và ngữ điệu, phần lớn
  trùng với Oral Fluency.
- Thêm một điểm không nhất quán: khi Azure không trả về prosody, DI và RL tính prosody = 0 (vẫn chia 3), còn RTS và SGD chỉ
  lấy trung bình các tiêu chí còn lại (chia 2) — hàm `missingProsodyScoresZero()` của từng scorer.

### L3. Form của Essay và SST chỉ có đạt/không đạt — **Trung bình**

- [Pearson] Essay: 200–300 chữ = 2; 120–199 hoặc 301–380 chữ = 1; ngoài khoảng đó = 0 (trang 35).
  SST: 50–70 chữ = 2; 40–49 hoặc 71–100 chữ = 1; ngoài khoảng đó = 0 (trang 42).
- [Hệ thống] Essay: trong 200–300 chữ thì đạt, ngoài khoảng đó form = 0. SST có tính trạng thái `INVALID_BOUNDARY`
  cho trường hợp ngoài 40–100 chữ nhưng `score()` không dùng trạng thái đó, nên 45 chữ cũng bị form = 0.
- Hậu quả: essay 150 chữ, đáng được 1/2 điểm form, lại bị 0. Khi sửa L1 thì lỗi này còn nặng hơn: không sửa L3 trước thì essay
  150 chữ sẽ bị 0 cả bài.
- Các quy tắc phụ của Pearson chưa được kiểm tra: viết toàn chữ hoa, không có dấu câu, chỉ toàn gạch đầu dòng hoặc câu rất ngắn (form = 0).

### L4. LLM chấm lại tiêu chí Form của SWT và Essay — **Trung bình**

- [Pearson] Form là đặc điểm hình thức: số chữ, một câu duy nhất (trang 7, 33, 35).
- [Hệ thống] Với SWT và WE (`modelScoresForm = true`), khi đạt kiểm tra cơ học thì tiêu chí form bằng **điểm LLM chấm**
  theo "chất lượng câu" (0–100), không phải điểm tối đa. Một quy tắc lẽ ra cố định thì lại thành chủ quan và có thể dao động
  giữa các lần chấm.

### L5. Tỉ trọng các tiêu chí bằng nhau — **Trung bình** [Suy luận]

- [Pearson] Mỗi tiêu chí có thang riêng. Tổng điểm tối đa: DI/RL/RTS/SGD = 6 + 5 + 5 = 16; WE = 6 + 2 + 6 + 2 + 6 + 2 + 2 = 26;
  SWT = 4 + 1 + 2 + 2 = 9; SST = 4 + 2 + 2 + 2 + 2 = 12.
- [Hệ thống] Mọi tiêu chí quy về 0–100 rồi lấy trung bình ngang nhau.
- [Suy luận] Tài liệu không ghi công thức cộng tiêu chí, nhưng mô hình partial credit (P3) gợi ý điểm câu là tổng số điểm
  đạt được. Nếu đúng như vậy thì Spelling trong Essay đang chiếm 1/7 ≈ 14% thay vì 2/26 ≈ 8%, còn Content chiếm 14% thay vì 23%.

### L6. Read Aloud không có tiêu chí Content riêng — **Trung bình**

- [Pearson] Read Aloud chấm Content (mỗi từ bị thay, bỏ sót hoặc **chèn thêm** là một lỗi), Pronunciation và Oral Fluency (trang 15–16).
- [Hệ thống] Điểm câu chỉ là điểm phát âm tổng hợp. Content chỉ thể hiện qua completeness, tức là recall, nên chiếm 20%.
  Recall không phạt từ chèn thêm.

### L7. Repeat Sentence: Content không chia mức và Fluency bị tính hai lần — **Thấp**

- [Pearson] Content chia bốn mức: 3 = đủ từ, đúng thứ tự; 2 = ít nhất 50% từ; 1 = dưới 50%; 0 = gần như không có (trang 16).
  Ngập ngừng và từ đệm không tính lỗi.
- [Hệ thống] Content là F1 liên tục, so khớp có thứ tự (gần với tinh thần của Pearson). Nhưng
  `overall = (content + pronunciation + fluency) / 3`, trong đó `pronunciation` đã chứa `0.2·fluency`, nên Fluency chiếm
  khoảng 40% điểm câu.

### L8. Quy trình chấm đôi AI và người — **Thấp** (lệch về quy trình)

- [Pearson] Content của bảy dạng (P9) do cả AI và người chấm; bất đồng thì người thứ hai quyết định. Pronunciation và Fluency
  chỉ do AI chấm (P7).
- [Hệ thống] Giám khảo nhập **một điểm tổng 0–100** cho cả câu. Host chọn dùng nguyên điểm AI hoặc nguyên điểm giám khảo.
  Không có bước chỉ cho người chấm lại Content trong khi giữ Pronunciation/Fluency của AI, và không có người phân xử.

### L9. Cách gộp điểm giữa các câu trong một dạng bài — **Thấp** [Suy luận]

- [Pearson] Partial credit cho 1 điểm mỗi ô hoặc mỗi từ đúng (trang 40, 44), nên câu FIB 6 ô có tối đa 6 điểm, câu 3 ô có tối đa 3 điểm.
- [Hệ thống] Mỗi câu quy về 0–100 trước khi lấy trung bình trong dạng bài, nên câu 3 ô có sức nặng bằng câu 6 ô.
- Tài liệu không mô tả cách gộp, nên đây chỉ là khác biệt có thể có, không phải lỗi đã xác định.

---

## 6. Những điều tài liệu không quy định

Những phần dưới đây là thiết kế của nhóm. Khi trình bày cần nói rõ là mô phỏng, không phải phương pháp của Pearson.

| Nội dung | Hệ thống | Ghi chú |
|---|---|---|
| Trọng số từng dạng bài theo kỹ năng | Bảng seed ở mục 4.1 | Không lấy từ tài liệu này. Tổng các cột không đúng 100 (S = 101, R = 101, L = 101, Overall = 100,5); kết quả vẫn đúng vì chia cho Σw |
| Quy đổi sang 10–90 | Tuyến tính `10 + 80 × tỉ lệ` | Pearson dùng mô hình thống kê không công bố; điểm của hệ thống chỉ là xấp xỉ |
| Write From Dictation có tính thứ tự từ hay không | Có (LCS) | Tài liệu chỉ ghi "mỗi từ đúng chính tả được 1 điểm" |
| Chấm các trường hợp bất thường (P8) | Chưa thấy luồng riêng trong phần mã đã đọc; câu không có tiếng nói được AI chấm 0 | Có thể đưa câu có cờ `lowConfidence` vào hàng chờ giám khảo |

---

## 7. Đính chính so với phân tích trước

- Phân tích trước cho rằng Answer Short Question thiếu trọng số Speaking. **Sai.** Theo trang 24, ASQ chỉ tính cho Listening,
  nên seed đặt `speaking_weight = 0` là đúng.
- Phân tích trước lo rằng publish khi còn câu AI chưa chọn nguồn điểm sẽ thổi phồng điểm kỹ năng. **Không xảy ra.**
  Những câu đó bị đánh dấu không publish được và chặn việc công bố (mục 3.2).

---

## 8. Đề xuất thứ tự xử lý

| Bước | Nội dung | Lệch | Phạm vi sửa |
|---|---|---|---|
| 1 | Form chia ba mức cho Essay và SST, thêm các quy tắc chữ hoa, dấu câu, gạch đầu dòng | L3 | `FormCheck` |
| 2 | Cổng Content/Form: Content = 0 hoặc Form = 0 thì `rawScore = 0` | L1 | `GeminiSpeakingScorer`, `GeminiWritingScorer` |
| 3 | Thêm Pronunciation cho DI, RL, RTS, SGD; thống nhất cách xử lý khi thiếu prosody | L2 | `GeminiSpeakingScorer` và các lớp con |
| 4 | Form của SWT và Essay lấy từ kiểm tra cơ học, bỏ điểm LLM | L4 | `SummarizeWrittenTextScorer`, `WriteEssayScorer` |
| 5 | Tỉ trọng tiêu chí theo điểm tối đa của Pearson | L5 | `GeminiWritingScorer`, `GeminiSpeakingScorer` |
| 6 | Content riêng cho Read Aloud (có phạt từ chèn); bỏ tính hai lần Fluency ở Repeat Sentence | L6, L7 | `ReadAloudScorer`, `RepeatSentenceScorer` |
| 7 | Cân nhắc giám khảo chỉ chấm lại Content, có người phân xử | L8 | Luồng examiner, cần thiết kế riêng |

Bước 1 phải làm trước bước 2. Nếu không, essay 150 chữ sẽ bị 0 cả bài. Các bước 3, 5 và 6 làm thay đổi khóa của `subScores`,
nên phải kiểm tra phần hiển thị chi tiết điểm AI ở FE. Mọi bước đều làm đổi điểm của các câu chấm lại; điểm đã publish nằm
trong snapshot báo cáo nên không bị ảnh hưởng.

---

## 9. Phạm vi kiểm tra

- Đã đọc toàn bộ 46 trang của Score Guide (bản text trích bằng `pdftotext`; bảng CEFR ở trang 11 là hình nên không đọc được dạng chữ).
- Đã đọc mã nguồn chấm khách quan, các scorer Azure/Gemini, `FormCheck`, `TokenAlignment`, `ScoreAggregationService`,
  luồng chặn publish, và seed `exam_definition_items` của mẫu chuẩn trong `V1__baseline.sql`.
- Chưa đọc: luồng chấm tham chiếu dùng OpenAI-compatible (`OpenAiCompatible*ScoringClient`, LLM tự trả `rawScore`), các stub,
  và mẫu đề do trung tâm tự tạo.
- Không chạy test và không sửa mã. Các ví dụ số ở mục 5 được tính tay theo công thức trong mã, không phải kết quả chạy thật.
