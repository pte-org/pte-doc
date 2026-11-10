# Báo cáo nghiệp vụ tổ chức đề thi: thời gian, số câu, độ khó CEFR

Ngày: 2026-11-03
Người lập: quang (thực hiện cùng trợ lý AI)
Phạm vi: `pte-api` (assessment, itembank, media, session), `pte-web` (vendor-web, tenant-web, api-client, ui)
Kế hoạch gốc: `pte-doc/projects/plans/quang-pearson-exam-assembly/`
Người đọc dự kiến: hội đồng chấm đồ án, giảng viên hướng dẫn.

Quy ước trong báo cáo: **[Pearson]** là điều tài liệu của Pearson nói; **[Hệ thống]** là điều mã nguồn làm, có chỉ tới tệp; **[Suy luận]** là chỗ nhóm mô phỏng hoặc giả định, không phải điều Pearson xác nhận.

---

## 1. Tóm tắt

Một kỳ thi được dựng qua ba tầng quyết định, theo đúng mô tả của Pearson rằng đề được lấy "ngẫu nhiên phân tầng theo (a) kỹ năng cần đo, (b) độ khó, (c) thời lượng":

1. **Số câu mỗi dạng bài** (tầng a và c): bộ lập kế hoạch chọn số câu từng dạng sao cho thời lượng dự kiến của từng phần Pearson (Speaking & Writing, Reading, Listening) nằm trong khung của phần đó, tránh đề "toàn tối đa" hay "toàn tối thiểu".
2. **Câu hỏi cụ thể** (tầng b): các câu được bốc theo một tỉ lệ CEFR mục tiêu cho từng kỹ năng.
3. **Biên bản lắp đề**: mọi đề lưu kèm seed, phiên bản thuật toán, số câu, thời lượng dự kiến và phân bố CEFR thực tế để chứng minh lại được.

Kết quả đo chính, trên mẫu chuẩn hiện hành với 2000 seed khác nhau:

| Phần | Khung Pearson | Dự kiến trung bình | Nhỏ nhất đến lớn nhất |
|---|---|---|---|
| Speaking & Writing | 76–84 phút | 78,8 | 76,0 – 81,3 |
| Reading | 23–30 phút | 28,6 | 28,0 – 30,0 |
| Listening | 31–39 phút | 36,3 | 34,5 – 39,0 |
| Tổng | trần 135 phút | 143,6 | 138,5 – 150,3 |

Mọi phần đều nằm trong khung, nhưng **tổng dự kiến vượt trần 135 phút ở mọi đề**. Lý do và cách xử lý ở mục 5.4; đây là điểm cần trình bày thẳng thắn với hội đồng.

Giới hạn quan trọng: hệ thống **không** dùng IRT như Pearson. Độ khó là mức CEFR do người có chuyên môn gắn (mục 7).

---

## 2. Căn cứ từ Pearson

| # | Nội dung (nguyên văn rút gọn) | Nguồn |
|---|---|---|
| P1 | "PTE Academic … is a maximum of 2 hours 15 minutes long" | *PTE Academic Test Taker Score Guide*, phần giới thiệu |
| P2 | Part 1 Speaking and Writing (approx. 76–84 minutes); Part 2 Reading (approx. 23–30 minutes); Part 3 Listening (approx. 31–39 minutes) | Score Guide, mục 7 |
| P3 | "The minimum and maximum timings indicated for the sections of each part … do not add up to the total timings stated. This is because different versions of the test are balanced for total length. No test taker will get the maximum or minimum times indicated." | Score Guide, mục 7, ghi chú 1 |
| P4 | "Test forms are drawn from the item bank in a stratified random sampling procedure. Selections are stratified according to (a) aspect to be measured, (b) item difficulty, and (c) length of time. The selection according to difficulty ensures the selection meets target test information functions for each of the four skills." | *Aligning PTE Academic Test Scores to the CEFR* (Pearson, 2010) |
| P5 | Người soạn câu hướng tới "CEF levels from upper B1 to lower C2", ghi mức CEFR mục tiêu cho từng câu; người duyệt đánh giá lại; cả hai được lưu cùng câu trong ngân hàng | cùng tài liệu |
| P6 | Độ khó được hiệu chuẩn bằng mô hình Rasch sau hai đợt thi thử | cùng tài liệu; De Jong & Zheng (2016) |
| P7 | Mỗi thí sinh làm 52–64 câu, 20 dạng bài (phiên bản 2022) | *Specification for PTE Academic* V7 (06/2022) |

**Pearson không công bố thuật toán lắp đề.** Hai tài liệu duy nhất mô tả hành vi là P3 và P4. Hệ thống mô phỏng hành vi đó, không sao chép thuật toán.

Lưu ý về nguồn: khung thời gian trong bản Specification 2022 (Speaking & Writing 54–67 phút) khác Score Guide hiện hành (76–84 phút). Vì Pearson đã đổi cấu trúc đề giữa hai phiên bản, khung thời gian được lưu thành **dữ liệu sửa được trên mẫu**, không viết cứng trong mã.

---

## 3. Mô hình nghiệp vụ

### 3.1 Vai trò (theo `SecurityRoles`, `SecurityPolicy`)

| Việc | Academic Staff | Academic Manager | Platform Manager | Platform Admin | Host Admin |
|---|---|---|---|---|---|
| Tạo câu hỏi, nhập `cefr_level` | ✔ | ✔ | — | ✔ | — |
| Sửa câu nháp | câu của mình | câu của mình | — | mọi câu | — |
| Duyệt câu (CEFR có hiệu lực khi câu được duyệt) | — | ✔, trừ câu của mình | — | ✔ | — |
| Tạo mẫu nền tảng, sửa bản DRAFT (dạng bài, khung thời gian, tỉ lệ CEFR) | ✔ | ✔ | — | ✔ | — |
| Duyệt và kích hoạt mẫu nền tảng | — | ✔, trừ mẫu của mình | — | ✔ | — |
| Sửa mẫu của trung tâm | — | — | — | — | ✔ |
| Chọn độ khó khi tạo kỳ thi | — | — | — | — | ✔ |

`PLATFORM_AUTHOR` chỉ là tên cũ, được quy về Academic Staff (`SecurityRoles.canonicalize`).

### 3.2 Vòng đời

```
Câu hỏi:  DRAFT ─ gửi duyệt (bắt buộc cefr_level nếu là câu thi) ─► PENDING_APPROVAL ─ duyệt ─► APPROVED
Mẫu nền tảng: DRAFT ─► PENDING_APPROVAL ─► ACTIVE (kích hoạt kiểm tra khung thời gian) ─► RETIRED
Mẫu trung tâm: clone từ mẫu nền tảng, sửa tự do; hệ thống tính nhãn "Chuẩn Pearson" / "Tùy chỉnh"
Kỳ thi:   tạo bản nháp (chọn mẫu, độ khó) ─► sinh đề (có seed, biên bản) ─► publish ─► thi ─► chấm
```

### 3.3 Mẫu chuẩn và mẫu trung tâm (quyết định sản phẩm 2026-11-03)

- **Admin** chỉ dựng mẫu chuẩn, nằm trong khung Pearson. Admin không tạo đề luyện tập.
- **Trung tâm** được tự do chọn số dạng bài và số câu, miễn dùng dạng bài nền tảng có. Hệ thống **không** thêm ràng buộc số câu hay thời gian lên mẫu trung tâm (`validateWithinBase` chỉ kiểm tra dạng bài thuộc mẫu gốc).
- Hệ thống **tự tính** mẫu trung tâm còn là "Chuẩn Pearson" hay đã "Tùy chỉnh" (mục 6).

---

## 4. Cách tính thời gian

### 4.1 Công thức

Thời lượng dự kiến của một câu `q` thuộc dạng bài `t` (tệp `ExamTimeModel`):

```
d(q) = prep(t) + response(t) + stimulus(q)   nếu dạng bài phát audio TRƯỚC khi đếm giờ
d(q) = prep(t) + response(t)                  với mọi dạng còn lại
```

- `prep`, `response`: lấy từ dòng của dạng bài trong mẫu.
- `stimulus`: độ dài audio đề phát trước khi đồng hồ trả lời chạy. Chỉ năm dạng bài có cờ `question_types.stimulus_before_timer = true`: Repeat Sentence, Re-tell Lecture, Answer Short Question, Summarize Group Discussion, Respond to a Situation.
- Với các dạng Listening, answer time trong bảng APEUni V5 ("≤ 1–1.5 phút", "≤ 2 phút", "2 phút mỗi câu", "10 phút mỗi câu") **đã gồm** thời gian nghe, nên không cộng thêm audio. Cộng thêm sẽ tính hai lần.
- Độ dài `stimulus` của một dạng bài là **trung vị** độ dài audio đo được (`media_objects.duration_seconds`) của các câu thi đã duyệt thuộc dạng đó (`TaskTypeStimulusService`, `StimulusLength.median`). Dạng nào chưa câu nào có độ dài đo được thì dùng `question_types.stimulus_estimate_seconds` làm dự phòng (6, 85, 5, 86, 18 giây theo thứ tự năm dạng trên).

Thời lượng một phần Pearson là tổng `d` theo số câu. Với mẫu cho trước, mỗi phần có một khoảng:

```
Phần_min = Σ  minCount(t) × d(t)        Phần_max = Σ  maxCount(t) × d(t)
```

Speaking và Writing gộp thành một phần (`ExamTimePart.SPEAKING_WRITING`), đúng như Pearson tính 76–84 phút cho cả hai.

**Đồng hồ khi thi không đổi** (`AttemptStartFlow`: `examEndTime = startedAt + Σ(prep + response)`; `TimerService`: chỉ Reading dùng ngân sách chung của cả phần). Mô hình trên chỉ dùng để **lập kế hoạch và báo cáo**. Lý do: audio được client phát trước đồng hồ trả lời, như ở đề Pearson.

### 4.2 Khung thời gian trên mẫu

Mỗi mẫu có thể mang khung (7 cột số giây trong `exam_definitions`, migration `V25`): `sw_min/max`, `reading_min/max`, `listening_min/max`, `total_max`. Mẫu nền tảng đang ACTIVE được nạp 4560–5040 (76–84 phút), 1380–1800 (23–30), 1860–2340 (31–39) và trần 8100 giây (135 phút). Có ràng buộc `CHECK` ở DB và kiểm tra ở `ExamTimeFrameRules` (mỗi phần `min ≤ max`; trần ≥ tổng ba mức tối thiểu).

### 4.3 Mẫu chuẩn hiện hành (migration `V24`)

Mẫu ACTIVE trước đây sai so với bảng APEUni V5. `V24` thay bằng một **phiên bản mới**, bản cũ chuyển `RETIRED` (không sửa tại chỗ, vì đề đã xuất bản được ghim theo mẫu cũ). Các giá trị "≤ N phút" của bảng được lưu bằng cận trên (1–1,5 phút = 90 giây; 1,5–2 phút và ≤ 2 phút = 120 giây). Đây là **giả định** [Suy luận]: nếu hiểu khác thì chỉ cần một migration mới.

Thời lượng dự kiến của mẫu này, tính qua API `GET /exam-definitions/{id}/feasibility` (ngày 2026-11-03):

| Phần | Chỉ prep + response | Cộng audio phát trước giờ (mô hình mới) | Khung |
|---|---|---|---|
| Speaking & Writing | 63,4 – 70,2 phút | **71,1 – 81,3** | 76–84 |
| Reading | 28,0 – 37,0 | 28,0 – 37,0 | 23–30 |
| Listening | 34,5 – 46,5 | 34,5 – 46,5 | 31–39 |

Chỉ riêng cộng audio phát trước giờ đã đưa Speaking & Writing từ dưới khung vào trong khung. Cả ba phần đều có tổ hợp số câu nằm trong khung (`canFitFrame = true`).

---

## 5. Cách phân chia số câu

### 5.1 Bài toán

Chọn `n_t ∈ [min_t, max_t]` cho mỗi dạng bài `t` sao cho thời lượng dự kiến của từng phần nằm trong khung của phần, và trong các tổ hợp hợp lệ chọn ngẫu nhiên theo seed, ưu tiên gần giữa khung, tránh cực trị. Tệp: `BalancedCountPlanner`, `PartCombos`, `JointSearch`.

### 5.2 Thuật toán

1. **Liệt kê theo từng phần.** Duyệt sâu các số câu của các dạng trong phần, cắt nhánh ngay khi không thể chạm khung (`PartCombos.extend`). Chỉ giữ tổ hợp có tổng thời gian trong khung của phần. Với mẫu chuẩn, mỗi phần chỉ có vài trăm đến vài nghìn tổ hợp.
2. **Ghép các phần.** Duyệt tích Đề-các của các danh sách đã lọc (`JointSearch`). Nếu tích vượt 5.000.000 thì không lập kế hoạch và quay về cách bốc độc lập.
3. **Trọng số.** Với một tổ hợp, trọng số của một phần là `exp(−2 · z²) / m`, trong đó `z = (T − giữa khung) / (nửa độ rộng khung)` và `m` là số tổ hợp cùng tổng thời gian `T`. Trọng số cả đề là tích ba phần. Phép chia cho `m` là bắt buộc: không có nó, rất nhiều tổ hợp ở mép ngắn của khung lấn át vài tổ hợp ở giữa (đã quan sát: trước khi sửa, Speaking & Writing gần như luôn rơi vào 76,2 phút).
4. **Loại cực trị.** Tổ hợp "mọi dạng đều ở mức tối thiểu" hoặc "mọi dạng đều ở mức tối đa" có trọng số 0 nếu còn tổ hợp khác. Đây là điều P3 mô tả: "no test taker will get the maximum or minimum".
5. **Rút theo seed.** Rút một tổ hợp theo trọng số. Seed được trộn bằng SplitMix64 (`Seeds`) vì `java.util.Random` với seed nhỏ liên tiếp cho các giá trị đầu gần như giống nhau. Cùng seed luôn cho cùng kết quả.

### 5.3 Khi nào dùng bộ lập kế hoạch

Chỉ khi mẫu có khung thời gian **và** đề gồm cả bốn kỹ năng (`CountSelector`). Khung của một phần mô tả cả phần, nên vô nghĩa với đề chỉ có một kỹ năng. Trường hợp còn lại giữ cách bốc độc lập cũ (`roll()`), có test hồi quy. Nếu khung không thể đạt, đề vẫn được tạo bằng cách cũ và biên bản ghi `fallbackReason = TIME_FRAME_INFEASIBLE:<phần>`.

### 5.4 Trần tổng 135 phút là ràng buộc mềm

Cộng ba mức tối thiểu của khung từng phần, 76 + 28 + 34,5, đã bằng 138,5 phút, lớn hơn trần 135. Nguyên nhân: các answer time "≤ N phút" được lưu bằng cận trên, tức là thời gian *tối đa* cho phép của câu chứ không phải thời gian dùng thật. Vì vậy kế hoạch dự kiến (cận trên) có thể vượt trần trên giấy trong khi thời gian thật vẫn dưới trần.

Hệ thống xử lý như sau: khung từng phần là ràng buộc **cứng**; trần tổng là ràng buộc **mềm**, bộ lập kế hoạch ưu tiên các tổ hợp dưới trần và chỉ bỏ qua trần khi không tổ hợp nào đạt. Khi bỏ qua, biên bản ghi `totalCeilingMet = false`. Với mẫu chuẩn hiện hành điều này xảy ra ở mọi đề. Kích hoạt mẫu (`ExamTimeFrameActivationCheck`) cũng chỉ kiểm khung từng phần, không kiểm trần. Đây là hạn chế đã biết, ghi ở mục 10.

### 5.5 Kết quả chạy

Mười hai đề đầu trong 20 đề mẫu (seed 1–20), phút:

| Seed | S&W | Reading | Listening | Tổng | Số câu |
|---|---|---|---|---|---|
| 1 | 79,9 | 28,0 | 36,5 | 144,4 | 72 |
| 2 | 77,0 | 29,5 | 36,5 | 143,0 | 70 |
| 3 | 78,4 | 28,0 | 38,0 | 144,4 | 72 |
| 4 | 80,2 | 28,0 | 34,5 | 142,7 | 72 |
| 5 | 80,7 | 28,0 | 34,5 | 143,2 | 71 |
| 6 | 78,1 | 29,5 | 38,5 | 146,1 | 72 |
| 7 | 80,2 | 28,0 | 38,5 | 146,7 | 74 |
| 8 | 79,1 | 28,0 | 34,5 | 141,6 | 72 |
| 9 | 79,6 | 28,0 | 36,5 | 144,1 | 71 |
| 10 | 79,5 | 28,0 | 34,5 | 142,0 | 70 |
| 11 | 79,6 | 28,0 | 38,0 | 145,6 | 72 |
| 12 | 78,9 | 28,0 | 36,0 | 142,9 | 71 |

Trên 2000 seed: **1390 kế hoạch khác nhau**; S&W trung bình 78,8 (76,0–81,3), Reading 28,6 (28,0–30,0), Listening 36,3 (34,5–39,0). Có 20.394 tổ hợp hợp lệ để chọn. Số câu mỗi đề khoảng 70–75, cao hơn 52–64 của bản đề 2022 (P7) vì mẫu APEUni V5 có nhiều câu hơn.

### 5.6 Ví dụ tính tay (seed 7)

Seed 7 cho: Read Aloud 7, Repeat Sentence 12, Describe Image 6, Re-tell Lecture 3, Answer Short Question 6, Summarize Group Discussion 3, Respond to a Situation 2, Summarize Written Text 2, Write Essay 1. Thời lượng Speaking & Writing:

| Dạng | Số câu | d (giây) | Cộng (giây) |
|---|---|---|---|
| Read Aloud | 7 | 35+35 = 70 | 490 |
| Repeat Sentence | 12 | 0+15+6 = 21 | 252 |
| Describe Image | 6 | 25+40 = 65 | 390 |
| Re-tell Lecture | 3 | 10+40+85 = 135 | 405 |
| Answer Short Question | 6 | 0+10+5 = 15 | 90 |
| Summarize Group Discussion | 3 | 10+120+86 = 216 | 648 |
| Respond to a Situation | 2 | 10+40+18 = 68 | 136 |
| Summarize Written Text | 2 | 600 | 1200 |
| Write Essay | 1 | 1200 | 1200 |
| **Tổng** | | | **4811** (80,2 phút) |

4811 giây nằm trong khung 4560–5040. Con số này khớp dòng seed 7 ở bảng trên.

---

## 6. Nhãn "Chuẩn Pearson" cho mẫu trung tâm

Hệ thống tính (không lưu) mẫu trung tâm `H`, clone từ mẫu nền tảng `B`, còn là "Chuẩn Pearson" khi đồng thời (tệp `HostTemplateStandardCheck`):

| # | Điều kiện | Mã lý do khi không đạt |
|---|---|---|
| R1 | `H` có đủ mọi dạng bài của `B` | `MISSING_TASK_TYPE:<dạng>` |
| R2 | `prep`, `response` mỗi dạng bằng `B` | `TIMING_CHANGED:<dạng>` |
| R3 | `[min, max]` mỗi dạng nằm trong `[min, max]` của `B` | `COUNT_OUTSIDE_STANDARD:<dạng>` |
| R4 | Các phần của `H` vẫn có thể chạm khung của `B` | `TIME_FRAME_INFEASIBLE:<phần>` |
| R6 | Trọng số Overall và bốn kỹ năng mỗi dạng bằng `B` (so bằng `compareTo`, nên 4.0 và 4.00 là một) | `WEIGHTS_CHANGED:<dạng>` |

Trọng số được tính vào chuẩn vì nó quyết định cách điểm từng câu dồn thành điểm kỹ năng và Overall: hai đề cùng nhãn mà khác thang điểm thì nhãn mất nghĩa. **Thứ tự dạng bài không tính**, vì khi lắp đề các câu luôn được sắp theo thứ tự chuẩn của từng phần (`TemplateTaskOrder`). Quy tắc về CEFR (kế hoạch ghi là R5) không nằm trong `HostTemplateStandardCheck` mà ở **mức kỳ thi**: wizard coi một đề là "Chuẩn Pearson" chỉ khi mẫu đạt chuẩn **và** trung tâm để độ khó "theo mẫu" (`isStandardExam`). Chọn dải hay mix tùy chỉnh thì đề hiện nhãn "Tùy chỉnh". Nhãn của đề được tính để hiển thị ở wizard; **chưa được lưu vào biên bản lắp đề** (xem hạn chế 8, mục 10).

---

## 7. Cách phân chia độ khó CEFR

### 7.1 Thang và phạm vi

CEFR có sáu mức A1–C2. Câu hỏi của PTE Academic chỉ nhắm một đoạn: Pearson nói người soạn nhắm "upper B1 to lower C2" (P5) và bài thi "không nhằm đo dưới A2". Hệ thống lưu đủ sáu mức để trung tâm dạy học viên trình độ thấp có câu A1–A2 cho đề của họ, nhưng **mix chuẩn chỉ dùng B1–C2**.

### 7.2 Gắn mức cho câu hỏi

- Một cột duy nhất `questions.cefr_level` (migration `V28`), `NULL` nghĩa là "chưa phân loại"; câu có trước migration giữ `NULL`, không bị gán B2 theo mặc định (mặc định sẽ làm sai phân bố mà người dùng không biết).
- Người soạn nhập khi soạn. Câu thi (`availableForExam`) **bắt buộc** có mức khi gửi duyệt (`QUESTION_CEFR_REQUIRED`). Khi Academic Manager duyệt câu thì mức đó có hiệu lực luôn. Không có "mức đề xuất", không có bước xác nhận riêng.
- Quyết định này dựa trên việc tin người có vai trò chuyên môn, như Pearson giao việc cho người soạn và người duyệt đã được huấn luyện (P5). Với bản sửa câu (revision), `cefr_level` được chép như mọi trường khác.

### 7.3 Vì sao không dùng IRT

Pearson hiệu chuẩn độ khó bằng Rasch sau hai đợt thi thử (P6) và chọn câu theo "target test information function" (P4). Việc đó cần dữ liệu bài làm lớn (Pearson thi thử mỗi câu hơn 200 lượt). Hệ thống chưa có dữ liệu đó, nên thay bằng nhãn CEFR do chuyên gia gắn và tỉ lệ mục tiêu. Đây là điểm khác chính với Pearson (mục 9).

### 7.4 Không dùng Table 4 của Pearson làm tỉ lệ đề

Table 4 của báo cáo Pearson (A2 21%, B1 45%, B2 24%, C1 5%, C2 2%) là phân bố **thí sinh** thi thử theo CEFR ("the observed distribution of field test candidates over the CEF levels"), không phải phân bố câu hỏi. Dùng nó sẽ đưa 21% câu A2 vào đề, trái với phạm vi "upper B1 to lower C2". Giá trị thật của bảng là cột ngưỡng θ giữa các mức, dùng để quy độ khó IRT sang CEFR khi sau này có dữ liệu.

### 7.5 Tỉ lệ mục tiêu mặc định

Pearson không công bố tỉ lệ phần trăm theo mức CEFR. Mix mặc định của mẫu nền tảng là **chia đều B1–C2, mỗi mức 25%** (migration `V29`, bảng `exam_definition_cefr_targets`). Đây là **lựa chọn thiết kế**, không phải số của Pearson [Suy luận]: không thiên vị mức nào khi chưa có dữ liệu. Academic Staff/Manager sửa được trên bản DRAFT (`PUT /exam-definitions/{id}/cefr-targets`; tổng phải bằng 100).

### 7.6 Thuật toán chọn câu (`StratifiedQuestionPicker`)

Áp cho mẫu có mix (hoặc kỳ thi có mix riêng, mục 8) trên đường sinh đề có seed:

1. **Hạn ngạch theo kỹ năng.** Với kỹ năng có `N` câu, hạn ngạch mức `ℓ` là `N × p(ℓ)/100`, làm tròn theo phần dư lớn nhất để tổng bằng đúng `N`. Ví dụ `N = 7`, mix 25% bốn mức cho hạn ngạch 2, 2, 2, 1.
2. **Bốc theo dạng bài.** Duyệt từng dạng bài trong kỹ năng; mỗi câu lấy từ mức còn nhiều hạn ngạch nhất mà dạng đó còn câu. Hòa thì theo thứ tự trộn bằng seed. Trong một mức, câu được chọn ngẫu nhiên theo seed.
3. **Lấy bù.** Nếu dạng đó không còn câu ở mức cần, lấy từ mức gần nhất (cách đều thì lấy mức thấp hơn); mix chuẩn (chỉ B1–C2) không bao giờ lấy bù xuống dưới B1; câu chưa phân loại là phương án cuối. Mỗi lần lấy bù được ghi vào `fallbacks`; câu chưa phân loại được đếm ở `unclassifiedUsed`. Hết cách thì báo thiếu câu như trước (`InsufficientQuestionBankException`).
4. Cùng seed cho cùng đề; không câu nào lặp trong một đề.

---

## 8. Tạo kỳ thi ở trung tâm

Bước "Exam details" của wizard (`tenant-web`) có mục **Độ khó** với ba lựa chọn (`DifficultyPicker`):

| Lựa chọn | Hành vi | Nhãn đề |
|---|---|---|
| Theo mẫu bài thi (mặc định) | Dùng mix của mẫu; không gửi gì lên | "Chuẩn Pearson" nếu mẫu đạt chuẩn, ngược lại "Tùy chỉnh" |
| Một dải trình độ | Chia đều trong dải (từ mức A đến mức B); phần dư chia cho các mức thấp trước | Tùy chỉnh |
| Tỉ lệ tùy chỉnh | Trung tâm nhập phần trăm từng mức; tổng phải bằng 100 | Tùy chỉnh |

Mix chọn ở đây được lưu trên kỳ thi (`exam_session_cefr_targets`, migration `V30`) và **ghi đè** mix của mẫu khi sinh đề. Bước Review hiện tóm tắt độ khó đã chọn. Danh sách mẫu của trung tâm hiện chip "Chuẩn Pearson"/"Tùy chỉnh" kèm lý do khi rê chuột.

Endpoint feasibility của mẫu (`/exam-definitions/{id}/feasibility`, cũng dùng cho trung tâm) trả thêm cho từng dạng bài số câu sẵn sàng theo mức CEFR (`cefrCounts`) và thời lượng từng phần so với khung (`parts`), để giao diện cảnh báo thiếu câu.

---

## 9. Tái lập và kiểm chứng

Mỗi đề sinh qua đường có seed lưu kèm `exam_versions.assembly_report` (JSON, migration `V27`) cùng `generation_seed` và `generation_algorithm_version`:

```json
{
  "algorithmVersion": "PTE_SEEDED_BALANCED_V1",
  "seed": 123456789,
  "method": "BALANCED",
  "counts": { "READ_ALOUD": 7, "REPEAT_SENTENCE": 12, "...": 0 },
  "partSeconds": { "SPEAKING_WRITING": 4811, "READING": 1680, "LISTENING": 2190 },
  "totalSeconds": 8681,
  "candidateCombinations": 20394,
  "totalCeilingMet": false,
  "fallbackReason": null,
  "cefr": {
    "target": { "B1": 25, "B2": 25, "C1": 25, "C2": 25 },
    "quotaBySkill": { "READING": { "B1": 4, "B2": 4 } },
    "actualBySkill": { "READING": { "B1": 4, "B2": 4 } },
    "fallbacks": [ { "taskTypeKey": "RE_ORDER_PARAGRAPHS", "wanted": "C2", "used": "C1" } ],
    "unclassifiedUsed": 0
  }
}
```

(Số liệu trong khối trên là minh họa cấu trúc, không phải một đề thật.)

`algorithmVersion` là `PTE_SEEDED_BALANCED_V1` khi dùng bộ lập kế hoạch và `PTE_SEEDED_V2` (cách cũ) khi không. Để kiểm một đề, hội đồng chạy lại với cùng mẫu, cùng seed và cùng ngân hàng câu hỏi và so với `counts`.

---

## 10. So sánh với Pearson, giới hạn

| Khía cạnh | Pearson | Hệ thống |
|---|---|---|
| Lấy mẫu | Ngẫu nhiên phân tầng theo kỹ năng, độ khó, thời lượng (P4) | Phân tầng theo số câu và thời lượng dự kiến (bộ lập kế hoạch), rồi theo mức CEFR (bộ chọn câu) |
| Độ khó | IRT/Rasch, hàm thông tin mục tiêu | Nhãn CEFR do chuyên gia gắn, tỉ lệ mục tiêu theo kỹ năng |
| Quy điểm giữa các đề (equating) | Có, trên thang θ | Không |
| Cân bằng thời lượng | Tổng ép quanh trần; các phần bù trừ cho nhau (P3) | Mỗi phần nằm trong khung; trần tổng là ràng buộc mềm |
| Kiểm soát lộ đề (exposure) | Có (ngân hàng lớn, thi thử) | Chưa |

**Hạn chế và hướng phát triển:**

1. **Trần 135 phút không đạt được trên giấy** với mẫu chuẩn hiện hành (mục 5.4). Nếu muốn đạt, cần đổi các answer time "≤" sang thời gian dùng thật điển hình thay vì cận trên.
2. **Thời lượng thật của từng audio chưa dùng để chọn câu.** Kế hoạch ban đầu có bước "tầng (c)": khi chọn câu trong cùng dạng và mức, ưu tiên câu có audio sao cho thời lượng phần tiến gần giữa khung, rồi tính lại thời lượng thật. Bước này **chưa làm**. Hiện thời lượng dự kiến dùng trung vị audio theo dạng bài, không phải audio của câu được chọn.
3. **Personal Introduction** (câu giới thiệu ẩn của phần Speaking) chưa tính vào thời lượng dự kiến.
4. **Chưa có IRT, equating, kiểm soát exposure.** Hướng phát triển: thu bài làm, hiệu chuẩn Rasch, dùng bảng ngưỡng θ của Pearson (Table 4) để quy độ khó thực nghiệm sang CEFR.
5. **Tỉ lệ CEFR mặc định 25/25/25/25 là lựa chọn thiết kế**, không phải số của Pearson.
6. Bộ lập kế hoạch và bộ chọn câu chỉ áp cho **đường sinh đề có seed** (luồng tạo kỳ thi hiện tại). Đường `generate` không seed (`generateAndPublish`) giữ nguyên cách cũ.
7. Khung thời gian chỉ áp cho đề gồm cả bốn kỹ năng.
8. Nhãn "Chuẩn Pearson" của **đề** (khác nhãn của mẫu) chỉ tính và hiển thị ở wizard, chưa lưu vào biên bản lắp đề; mẫu thì được tính ở backend mỗi lần đọc.
9. Mục "Dự kiến đề thi" ở bước Review của wizard mới có tóm tắt độ khó; khối so sánh thời lượng và độ phủ CEFR dùng dữ liệu `feasibility` đã có ở API nhưng **chưa được dựng thành thẻ riêng ở giao diện**.
10. Content Hub chưa có bản đồ độ phủ theo CEFR và chưa đổi dòng "About X minutes" sang khoảng; thanh thời lượng nằm ở trình soạn mẫu.

---

## 11. Câu hỏi hội đồng có thể đặt

**Vì sao đề có tổng thời gian này, có vượt 2h15 không?** Mỗi phần nằm trong khung Pearson (Speaking & Writing 76–84, Reading 23–30, Listening 31–39), kiểm bằng `canFitFrame`. Tổng *dự kiến* trên giấy cao hơn 135 phút vì answer time "≤ N phút" được tính theo cận trên; thời gian thật dùng thường thấp hơn. Mục 5.4 giải thích và nêu hướng khắc phục.

**Hai học viên làm hai đề khác nhau có công bằng không?** Mỗi đề đều nằm trong khung thời gian từng phần và theo cùng tỉ lệ CEFR mục tiêu theo kỹ năng; biên bản cho thấy độ lệch. Hệ thống không quy điểm giữa các đề như Pearson, nên chưa bảo đảm tương đương về độ khó ở mức thống kê.

**Vì sao không làm IRT như Pearson?** IRT cần dữ liệu thi thử rất lớn (Pearson hơn 200 lượt mỗi câu). Hệ thống chưa có; mục 7.3 và hướng phát triển ở mục 10.

**CEFR do người gắn thì có chủ quan không, kiểm soát thế nào?** Có. Kiểm soát bằng quy trình: câu thi bắt buộc có mức trước khi gửi duyệt; chỉ Academic Manager hoặc Platform Admin duyệt, và không được duyệt câu của chính mình; mọi thao tác có audit. Pearson cũng bắt đầu từ đánh giá của người soạn và người duyệt (P5).

**Trung tâm sửa mẫu tùy ý thì còn gọi là chuẩn PTE được không?** Được tự do sửa, nhưng nhãn "Chuẩn Pearson" chỉ giữ khi thỏa R1–R6 (mục 6): đủ dạng bài, giữ nguyên thời gian và trọng số, số câu nằm trong khoảng của mẫu gốc, còn chạm được khung. Nếu không, đề mang nhãn "Tùy chỉnh" kèm lý do.

**Ngân hàng thiếu câu thì sao?** Với mix CEFR, thiếu ở một mức thì lấy bù từ mức gần nhất và ghi vào `fallbacks`; mix chuẩn không xuống dưới B1; thiếu hẳn thì báo lỗi thiếu câu như trước. Endpoint feasibility trả số câu theo mức để cảnh báo trước.

**Làm sao chứng minh đề này sinh ra đúng quy trình?** Biên bản lắp đề lưu cùng đề (mục 9) kèm seed và phiên bản thuật toán; chạy lại cùng seed cho cùng kết quả.

**Nếu Pearson đổi cấu trúc đề thì hệ thống xử lý thế nào?** Khung thời gian, số câu, thời gian và trọng số đều là dữ liệu trên mẫu. Admin tạo phiên bản mẫu mới theo cấu trúc mới và kích hoạt; bản cũ được giữ ở `RETIRED`. Không cần sửa mã.

---

## 12. Phụ lục

### 12.1 Mẫu chuẩn (migration `V24`, theo bảng APEUni V5)

| Dạng bài | Phần | Số câu | Prep (s) | Answer (s) | Overall | Spk | Wri | Rea | Lis |
|---|---|---|---|---|---|---|---|---|---|
| Read Aloud | Speaking | 6–7 | 35 | 35 | 3,50 | 14 | 0 | 0 | 0 |
| Repeat Sentence | Speaking | 10–12 | 0 | 15 | 9,75 | 20 | 0 | 0 | 19 |
| Describe Image | Speaking | 5–6 | 25 | 40 | 8,50 | 34 | 0 | 0 | 0 |
| Re-tell Lecture | Speaking | 2–3 | 10 | 40 | 5,25 | 11 | 0 | 0 | 10 |
| Answer Short Question | Speaking | 5–6 | 0 | 10 | 1,25 | 0 | 0 | 0 | 5 |
| Summarize Group Discussion | Speaking | 2–3 | 10 | 120 | 7,00 | 13 | 0 | 0 | 15 |
| Respond to a Situation | Speaking | 2–3 | 10 | 40 | 2,00 | 8 | 0 | 0 | 0 |
| Summarize Written Text | Writing | 2 | 0 | 600 | 11,13 | 0 | 25,5 | 19 | 0 |
| Write Essay | Writing | 1 | 0 | 1200 | 6,38 | 0 | 25,5 | 0 | 0 |
| Fill in the Blanks (Dropdown) | Reading | 5–6 | 0 | 120 | 7,00 | 0 | 0 | 28 | 0 |
| Multiple Choice, Multiple Answer | Reading | 2–3 | 0 | 90 | 1,50 | 0 | 0 | 6 | 0 |
| Re-order Paragraphs | Reading | 2–3 | 0 | 120 | 2,00 | 0 | 0 | 8 | 0 |
| Fill in the Blanks (Drag and Drop) | Reading | 4–5 | 0 | 120 | 4,50 | 0 | 0 | 18 | 0 |
| Multiple Choice, Single Answer | Reading | 2–3 | 0 | 90 | 0,50 | 0 | 0 | 2 | 0 |
| Summarize Spoken Text | Listening | 1 | 0 | 600 | 8,25 | 0 | 23 | 0 | 10 |
| Multiple Choice, Multiple Answer | Listening | 2–3 | 0 | 90 | 1,00 | 0 | 0 | 0 | 4 |
| Fill in the Blanks (Type In) | Listening | 2–3 | 0 | 120 | 2,25 | 0 | 0 | 0 | 9 |
| Highlight Correct Summary | Listening | 2–3 | 0 | 90 | 1,00 | 0 | 0 | 3 | 1 |
| Multiple Choice, Single Answer | Listening | 2–3 | 0 | 90 | 0,25 | 0 | 0 | 0 | 1 |
| Select Missing Word | Listening | 1–2 | 0 | 90 | 0,25 | 0 | 0 | 0 | 1 |
| Highlight Incorrect Words | Listening | 2–3 | 0 | 120 | 6,75 | 0 | 0 | 16 | 11 |
| Write From Dictation | Listening | 3–4 | 0 | 120 | 10,00 | 0 | 26 | 0 | 14 |

Mỗi cột kỹ năng cộng đúng 100; cột Overall cộng 100,01 do bảng gốc làm tròn 11,13.

### 12.2 Migration (thứ tự áp dụng)

| Phiên bản | Nội dung |
|---|---|
| `V24` | Mẫu nền tảng ACTIVE mới theo bảng APEUni V5; bản cũ RETIRED |
| `V25` | Khung thời gian trên mẫu; nạp khung Pearson |
| `V26` | `question_types.stimulus_before_timer`, `stimulus_estimate_seconds` |
| `V27` | `exam_versions.assembly_report` |
| `V28` | `questions.cefr_level` |
| `V29` | `exam_definition_cefr_targets`; mix đều B1–C2 cho mẫu nền tảng |
| `V30` | `exam_session_cefr_targets` (mix riêng của kỳ thi) |

### 12.3 Endpoint mới hoặc đổi

| Endpoint | Việc |
|---|---|
| `PUT /api/v1/exam-definitions/{id}/time-frame` | Sửa khung thời gian của bản DRAFT |
| `PUT /api/v1/exam-definitions/{id}/cefr-targets` | Sửa mix CEFR của bản DRAFT |
| `GET /api/v1/exam-definitions/{id}/feasibility` | Thêm `parts`, `totalMaxSeconds`, `slots[].cefrCounts` |
| `GET /api/v1/exam-definitions/{id}` | Thêm `timeFrame`, `cefrTargets`, `createdAt`, `updatedAt`, `authorName` |
| Host templates (list, get) | Thêm `pearsonStandard`, `standardDeviations` |
| Câu hỏi (tạo, sửa, trả về) | Thêm `cefrLevel` |
| Tạo/sửa bản nháp kỳ thi | Thêm `cefrTargets` |

### 12.4 Phạm vi đã kiểm tra

- Backend: bộ test `app` chạy toàn bộ (kết quả cuối ghi ở mục 12.5), gồm test mới cho mô hình thời gian, quy tắc khung, bộ lập kế hoạch (trong đó chạy 2000 seed), bộ chọn câu, nhãn chuẩn, CEFR trên câu hỏi, kiểm tra kích hoạt, tích hợp bộ lắp đề; test kiến trúc (`ModuleStructureTest`, kích thước tệp, mật độ gói) đều đạt.
- Web: `tsc`, `eslint`, `vitest` cho `vendor-web` và `tenant-web`.
- API chạy thật ở local: `feasibility` của mẫu ACTIVE trả đúng khung và thời lượng từng phần; mix CEFR của mẫu đọc được.
- **Chưa kiểm:** giao diện trên trình duyệt (người dùng tự kiểm); luồng tạo kỳ thi đầu-cuối với dữ liệu CEFR thật (ngân hàng local chưa có câu nào gắn `cefr_level`, nên `cefrCounts` toàn `UNCLASSIFIED`); kiểm tra Flyway chạy cả chuỗi migration trên cơ sở dữ liệu trống (local dùng profile `local-schema`, các migration được áp tay).

### 12.5 Kết quả chạy test cuối

Lần chạy toàn bộ cuối cùng của `./mvnw.cmd -pl app test` (2026-11-03): 4011 test, 0 lỗi, 60 bỏ qua theo mặc định (spike AI cần khóa thật và test Postgres cần cơ sở dữ liệu riêng). Web: `vendor-web` 249 test, `tenant-web` 601 test, `packages/ui` 348 test đều đạt.
