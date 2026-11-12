# Cách hệ thống tính điểm bài thi PTE và quy đổi điểm Azure

Ngày: 2026-11-10. Nguồn: mã nguồn `pte-api` (nhánh `main` sau PR #104) và mẫu đề đang ACTIVE trên production
(`PTE 22 task type` v5, rubric `6f1c2b7e-…-000000000001`, bảng quy đổi Azure phiên bản 1).

## 1. Tổng quan ba tầng

```
Câu trả lời ──► Điểm từng tiêu chí (trait) ──► Điểm câu 0-100 ──► Trung bình theo dạng bài ──► Điểm kỹ năng / Overall 10-90
                 (AI, Azure, máy, giám khảo)    RubricScorer        AggregationCore              AggregationCore
```

| Tầng | Ai tính | Mã nguồn |
|---|---|---|
| Điểm tiêu chí | LLM (gateway Capstone), Azure Speech, luật máy, hoặc giám khảo | `scoring/internal/vendor/*`, `scoring/internal/rubric/speech/*` |
| Điểm câu 0-100 | Duy nhất `RubricScorer` (dạng chấm theo tiêu chí) hoặc bộ chấm khách quan | `scoring/rubric/RubricScorer.java` |
| Điểm kỹ năng và Overall 10-90 | Duy nhất `AggregationCore` | `reporting/internal/service/aggregation/AggregationCore.java` |

## 2. Điểm câu (0-100)

### 2.1. Dạng chấm theo tiêu chí (10 dạng)

```
Điểm câu = làm tròn nửa lên( Σ(trọng số × đạt được / tối đa) ÷ Σ trọng số × 100 )
```

- Trọng số mặc định bằng chính điểm tối đa của tiêu chí. Vì vậy công thức rút gọn thành **Σ đạt được ÷ Σ tối đa × 100**.
- **Cổng điểm 0 (gate):** nếu một tiêu chí có gate bị 0 thì cả câu được 0 (Score Guide tr.8).
- Điểm tiêu chí phải là số nguyên trong thang. Hệ thống không tự kẹp giá trị, ngoài thang thì báo lỗi.

| Dạng bài | Tiêu chí (tối đa · nguồn) | Σ tối đa | Gate |
|---|---|---|---|
| Read Aloud | Content (N từ · máy đếm), Pronunciation (5 · Azure), Oral Fluency (5 · Azure) | N + 10 | Không |
| Repeat Sentence | Content (3 · máy đếm), Pronunciation (5 · Azure), Oral Fluency (5 · Azure) | 13 | Không |
| Describe Image | Content (6 · LLM), Pronunciation (5 · Azure), Oral Fluency (5 · Azure) | 16 | Content |
| Re-tell Lecture | như Describe Image | 16 | Content |
| Respond to a Situation | như Describe Image | 16 | Content |
| Summarize Group Discussion | như Describe Image | 16 | Content |
| Answer Short Question | Vocabulary (1 · máy so đáp án) | 1 (100 hoặc 0) | Không |
| Summarize Written Text | Content 4, Form 1 (máy), Grammar 2, Vocabulary 2 | 9 | Content, Form |
| Summarize Spoken Text | Content 4, Form 2 (máy), Grammar 2, Vocabulary 2, Spelling 2 | 12 | Content, Form |
| Write Essay | Content 6, Form 2 (máy), Development/Structure/Coherence 6, Grammar 2, General Linguistic Range 6, Vocabulary Range 2, Spelling 2 | 26 | Content, Form |

Những tiêu chí không ghi nguồn trong bảng là do LLM chấm.

**Form (máy tính theo số từ):**

| Dạng | Form 2 | Form 1 | Form 0 |
|---|---|---|---|
| Write Essay | 200-300 từ | 120-199 hoặc 301-380 từ | còn lại |
| Summarize Spoken Text | 50-70 từ | 40-49 hoặc 71-100 từ | còn lại |
| Summarize Written Text | (thang 1) | 5-75 từ và đúng **một câu** | còn lại |

Form cũng bằng 0 khi bài viết toàn chữ in hoa, không có dấu câu, hoặc chỉ gồm gạch đầu dòng.

**Content tính bằng máy:**
- **Read Aloud:** N là số từ của đoạn văn. Mỗi từ đọc thay, bỏ sót hoặc chèn thêm tính 1 lỗi. Content = max(0, N − số lỗi). Từ ngập ngừng được bỏ qua. Mỗi từ nặng 1 trọng số, nên đoạn văn dài thì Content chiếm phần lớn điểm câu.
- **Repeat Sentence:** đếm số từ được lặp lại đúng thứ tự. Đủ mọi từ được 3; từ 50% trở lên được 2; dưới 50% nhưng có ít nhất 1 từ được 1; không có từ nào được 0.
- **Answer Short Question:** toàn bộ câu trả lời (Azure chuyển giọng nói thành chữ) khớp một đáp án được chấp nhận (`a / b`) thì được 1, ngược lại 0. Không chấm phát âm.

**Ví dụ:**
- Describe Image với Content 4, Pronunciation 3, Oral Fluency 2: (4+3+2)/16 = 56,25%, làm tròn thành **56**. Nếu Content bằng 0 thì cả câu được **0**.
- Read Aloud với đoạn 50 từ, 5 lỗi, Pronunciation 3, Oral Fluency 2: (45+3+2)/60 = 83,3%, làm tròn thành **83**.

### 2.2. Dạng khách quan (12 dạng)

Điểm câu = làm tròn(100 × điểm đạt ÷ điểm tối đa), không nhỏ hơn 0.

| Quy tắc | Dạng bài |
|---|---|
| Đúng 1, sai 0 | MC Reading Single, MC Listening Single, Highlight Correct Summary, Select Missing Word |
| Mỗi lựa chọn đúng +1, sai −1, tối thiểu 0 | MC Reading Multiple, MC Listening Multiple, Highlight Incorrect Words |
| Mỗi ô trống đúng 1 | Fill in the Blanks: Drag and Drop, Dropdown, Type-in (nghe) |
| Mỗi cặp đoạn liền kề đúng thứ tự 1 | Re-order Paragraphs |
| Mỗi từ đúng chính tả 1 (so khớp chuỗi con chung dài nhất) | Write From Dictation |

## 3. Azure Speech chấm ra gì

### 3.1. Cấu hình gọi Azure

REST short-audio, `language=en-US`, `GradingSystem=HundredMark`, `Granularity=Word`, `EnableProsodyAssessment=true`,
`EnableMiscue=false`.

| Điểm Azure trả về | Ý nghĩa | Hệ thống dùng cho |
|---|---|---|
| `AccuracyScore` 0-100 | Phát âm từng âm, từng từ có đúng không | **Pronunciation** |
| `FluencyScore` 0-100 | Nhịp nói, ngắt nghỉ, ngập ngừng | **Oral Fluency** |
| `ProsodyScore` 0-100 | Ngữ điệu, trọng âm, nhịp câu | **Oral Fluency** (lấy trung bình với Fluency) |
| `CompletenessScore` | Mức độ đọc đủ văn bản tham chiếu | Không dùng trực tiếp; độ đầy đủ đo bằng lượt nhận dạng riêng |
| Lỗi từng từ | Thay, bỏ, chèn | Hiển thị cho giám khảo |

### 3.2. Cách gọi theo dạng bài

- **Có kịch bản (Read Aloud, Repeat Sentence):** gọi hai lượt.
  1. Lượt nhận dạng nghe xem học viên nói gì.
  2. Từng đoạn âm thanh được chấm so với đúng phần văn bản đã nghe thấy. Đoạn im lặng, hoặc đoạn không khớp từ nào, được 0. Đoạn đó không được gửi đi chấm "không kịch bản", vì Azure chấm kiểu đó sẽ cho nói lạc đề điểm cao.
- **Không kịch bản (Describe Image, Re-tell Lecture, Respond to a Situation, Summarize Group Discussion):** chấm với văn bản tham chiếu rỗng. Azure trả Accuracy, Fluency và Prosody của lời nói tự do, kèm bản chữ để LLM chấm Content.
- **Answer Short Question:** chỉ nhận dạng giọng nói, không chấm phát âm.
- **Bản ghi dài:** được cắt theo khoảng lặng thành nhiều đoạn rồi gộp lại.
  - Accuracy lấy trung bình theo số từ, nên đoạn ngắn ít ảnh hưởng.
  - Fluency và Prosody lấy trung bình theo thời lượng, nên đoạn im lặng kéo điểm xuống.
  - Bản ghi rỗng được 0.

### 3.3. Quy đổi 0-100 sang thang Pearson 0-5 (bảng phiên bản 1)

Đầu vào:
- **Pronunciation** dùng `Accuracy`.
- **Oral Fluency** dùng `(Fluency + Prosody) / 2`. Nếu Azure không trả Prosody thì chỉ dùng `Fluency`.
- Thiếu điểm Azure thì tính là 0. Không làm tròn trước khi so ngưỡng.

| Điểm Azure (đầu vào) | Mức Pearson |
|---|---|
| ≥ 90 | 5 |
| 75 – < 90 | 4 |
| 60 – < 75 | 3 |
| 45 – < 60 | 2 |
| 30 – < 45 | 1 |
| < 30 | 0 |

Hai tiêu chí dùng chung một bảng ngưỡng. **Bảng này do nhóm tự đặt, chia đều và chưa hiệu chỉnh với điểm người chấm**
(`calibrated = false`). Mọi màn hình hiển thị điểm này đều ghi chú "chưa hiệu chỉnh".

**Ví dụ:** Azure trả Accuracy 61,5, Fluency 52 và Prosody 40.
- Pronunciation: 61,5 ≥ 60, nên được **mức 3**.
- Oral Fluency: (52 + 40) / 2 = 46 ≥ 45, nên được **mức 2**.

Gộp với Content của Describe Image bằng 4 thì điểm câu là (4+3+2)/16, làm tròn thành **56**.

Từ 2026-11-10, giám khảo được chọn mức khác để ghi đè hai mức Azure này. Để trống thì hệ thống dùng mức Azure. Nếu lệch
từ 2 mức trở lên thì giám khảo phải ghi lý do.

## 4. Từ điểm câu sang điểm kỹ năng và Overall (10-90)

1. **Trung bình theo dạng bài:**
   - Lấy trung bình điểm câu của từng dạng.
   - Câu bỏ trống, tức không có bản ghi trả lời, tính là 0.
   - Câu đã nộp nhưng chưa có điểm (ví dụ AI đang chấm) không được tính vào trung bình.
2. **Điểm kỹ năng:**

   ```
   Kỹ năng = làm tròn nửa lên( 10 + 80 × Σ(w × TB_dạng / 100) / Σw )
   ```

   - Chỉ cộng các dạng bài có trọng số kỹ năng lớn hơn 0 và đã có điểm trung bình.
   - Dạng có trọng số nhưng chưa có điểm bị loại khỏi cả tử số lẫn mẫu số, không bị tính là 0.
3. **Overall:** cùng công thức nhưng dùng trọng số `overall`. Chỉ tính khi bài thi có đủ cả 4 kỹ năng.

### Trọng số của mẫu ACTIVE trên production

| Dạng bài | Speaking | Writing | Reading | Listening | Overall |
|---|---|---|---|---|---|
| Read Aloud | 14 | – | – | – | 3,50 |
| Repeat Sentence | 20 | – | – | 19 | 9,75 |
| Describe Image | 34 | – | – | – | 8,50 |
| Re-tell Lecture | 11 | – | – | 10 | 5,25 |
| Answer Short Question | – | – | – | 5 | 1,25 |
| Summarize Group Discussion | 13 | – | – | 15 | 7,00 |
| Respond to a Situation | 8 | – | – | – | 2,00 |
| Summarize Written Text | – | 25,5 | 19 | – | 11,13 |
| Write Essay | – | 25,5 | – | – | 6,38 |
| FIB Dropdown | – | – | 28 | – | 7,00 |
| MC Reading Multiple | – | – | 6 | – | 1,50 |
| Re-order Paragraphs | – | – | 8 | – | 2,00 |
| FIB Drag and Drop | – | – | 18 | – | 4,50 |
| MC Reading Single | – | – | 2 | – | 0,50 |
| Summarize Spoken Text | – | 23 | – | 10 | 8,25 |
| MC Listening Multiple | – | – | – | 4 | 1,00 |
| FIB Type-in | – | – | – | 9 | 2,25 |
| Highlight Correct Summary | – | – | 3 | 1 | 1,00 |
| MC Listening Single | – | – | – | 1 | 0,25 |
| Select Missing Word | – | – | – | 1 | 0,25 |
| Highlight Incorrect Words | – | – | 16 | 11 | 6,75 |
| Write From Dictation | – | 26 | – | 14 | 10,00 |
| **Tổng** | **100** | **100** | **100** | **100** | **100** |

Một dạng bài có thể góp điểm cho nhiều kỹ năng. Ví dụ Repeat Sentence góp cho cả Speaking và Listening, Write From
Dictation góp cho Writing và Listening.

**Ví dụ Speaking:** giả sử trung bình các dạng là RA 80, RS 60, DI 56, RL 50, SGD 40, RTS 70.

- Σ(w × TB/100) = 14×0,80 + 20×0,60 + 34×0,56 + 11×0,50 + 13×0,40 + 8×0,70 = 58,54
- Σw = 100
- Speaking = 10 + 80 × 0,5854 = 56,83, làm tròn thành **57**

## 5. Giới hạn cần biết

- **Bảng quy đổi Azure chưa hiệu chỉnh.** Ngưỡng 30/45/60/75/90 chia đều theo đề xuất của nhóm, chưa đối chiếu với điểm người
  chấm hay điểm Pearson thật. Lý do lệch AI mà giám khảo ghi lại (V41) là nguồn dữ liệu để hiệu chỉnh bảng phiên bản 2.
- **Azure không đọc rubric hay prompt.** Azure chỉ đo âm thanh. Hai mức 0-5 có được là nhờ bảng quy đổi ở mục 3.3, không
  phải Azure tự đánh giá theo mô tả mức của Pearson.
- **Content của Read Aloud chiếm phần lớn điểm câu khi đoạn văn dài**, vì mỗi từ nặng 1 trọng số. Pearson thực tế phân bổ
  khác.
- **Thang 10-90 là quy đổi tuyến tính** (`10 + 80 × tỉ lệ`), không phải thang chuẩn hóa thống kê của Pearson. Điểm này dùng
  để luyện tập và tham khảo, không tương đương điểm PTE chính thức.
- **Content và các tiêu chí ngôn ngữ do LLM chấm** (gateway Capstone). Model review cùng loại với model chấm, và chưa đo độ
  ổn định giữa các lần chấm.
- Giám khảo có thể sửa mọi tiêu chí trừ Form. Điểm câu luôn được tính lại bằng `RubricScorer`, không ai nhập tay điểm 0-100.
