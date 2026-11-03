# Phase 5: Chọn câu phân tầng theo CEFR và thời lượng

Phụ thuộc: Phase 2 (đã có số câu mỗi dạng), Phase 4 (câu đã có CEFR)
Repo: `pte-api` (assessment)
Migration: `V28__cefr_target_mix.sql` (phần mẫu)
Căn cứ: P4 đầy đủ ba tầng (a) kỹ năng, (b) độ khó, (c) thời lượng

## 1. Tỉ lệ CEFR mục tiêu

Mẫu lưu tỉ lệ mục tiêu dạng phần trăm cho từng mức, tổng 100:

| Mẫu | Mặc định |
|---|---|
| Mẫu nền tảng (chuẩn) | **Chia đều B1–C2: 25% mỗi mức.** Pearson không công bố tỉ lệ CEFR theo phần trăm, nên mặc định không thiên vị mức nào. Sửa trên bản DRAFT theo quyền sửa mẫu (tác giả là Staff hoặc Manager, hoặc Platform Admin); Academic Manager (không phải tác giả) hoặc Platform Admin kích hoạt. Căn cứ xem mục 1a |
| Mẫu trung tâm | Kế thừa mẫu gốc khi clone; trung tâm sửa tự do |
| Kỳ thi | Ghi đè được ở Phase 6 |

### 1a. Căn cứ cho tỉ lệ mặc định

Những gì *Aligning PTE Academic Test Scores to the CEFR* (Pearson, 2010) có nói:

- Câu hỏi nhắm "CEF levels from upper B1 to lower C2".
- B2 là mức cần để theo học đại học bằng ngoại ngữ.
- Bài thi không nhằm đo dưới A2.
- Figure 1 vẽ phân bố câu hỏi theo mức CEFR qua hai đợt thi thử, nhưng chỉ là hình, không có bảng số.
- Ở đề thật, Pearson chọn câu theo "target test information functions" (IRT), không theo tỉ lệ CEFR.

Các phương án:

1. **Đều trong B1–C2 (25/25/25/25).** Không giả định gì thêm; dễ bảo vệ nhất khi chưa có dữ liệu.
2. **Đọc số từ Figure 1** của báo cáo Pearson rồi dùng phân bố đợt thi thử 2 làm mặc định. Có nguồn, nhưng đó là phân bố ngân hàng câu chứ không phải tỉ lệ trong một đề.
3. **Dồn quanh B2** (mức tuyển sinh). Hợp lý theo lập luận đo lường, nhưng tỉ lệ cụ thể vẫn là lựa chọn của nhóm, báo cáo phải ghi rõ là lựa chọn thiết kế.

**Đã chọn phương án 1.**

**Không dùng Table 4 của báo cáo Pearson** (A2 21%, B1 45%, B2 24%, C1 5%, C2 2%) làm tỉ lệ đề. Bảng đó là phân bố **thí sinh** thi thử theo CEFR ("the observed distribution of field test candidates over the CEF levels"), không phải phân bố câu hỏi. Dùng nó sẽ đưa 21% câu A2 vào đề, trái với phạm vi "upper B1 to lower C2". Báo cáo Phase 8 trình bày rõ điểm này.

`V28`: bảng `exam_definition_cefr_targets(exam_definition_id, level, percent)`. Không lưu JSON, để có CHECK và tổng hợp bằng SQL. Tổng 100 kiểm tra ở service.

Tỉ lệ áp **theo kỹ năng** (4 section), không theo từng dạng bài. Lý do: một dạng chỉ có 1–3 câu, chia tỉ lệ ở mức dạng sẽ làm tròn méo. Đây cũng là đơn vị Pearson dùng ("target test information functions for each of the four skills", P4).

## 2. Thuật toán `StratifiedQuestionPicker`

Vào: số câu `n_t` mỗi dạng (từ Phase 2), tỉ lệ CEFR mục tiêu, seed, tập câu APPROVED theo dạng bài và `cefr_level`.

**Bước 1. Hạn ngạch theo kỹ năng.** Với kỹ năng `s` có `N_s = Σ n_t`, hạn ngạch mức `ℓ` là `q(s, ℓ) = N_s × p(ℓ)`, làm tròn theo **phương pháp phần dư lớn nhất** (Hamilton) để tổng bằng đúng `N_s`.

**Bước 2. Phân hạn ngạch xuống dạng bài.** Duyệt các dạng của kỹ năng theo thứ tự cố định. Với mỗi câu cần lấy, chọn mức `ℓ` còn hạn ngạch lớn nhất **mà dạng đó còn câu ở mức ℓ**. Hòa thì rút theo seed.

**Bước 3. Thiếu câu ở một mức.** Lấy bù từ mức liền kề theo thứ tự cố định:

```
B2 → B1 → C1        C1 → B2 → C2
B1 → B2 → A2        C2 → C1 → B2
```

Cuối cùng mới lấy câu "chưa phân loại". Mỗi lần lấy bù ghi vào biên bản (`fallbacks`). Đề chuẩn không lấy bù xuống dưới B1; hết cách thì báo thiếu câu.

**Bước 4. Thời lượng thật (tầng c).** Trong cùng dạng và cùng mức, nếu có nhiều câu hơn cần, ưu tiên câu có `stimulus(q)` sao cho thời lượng thực của phần **tiến gần giữa khung**:

- Sắp ứng viên theo `|stimulus(q) − stimulus_avg(t)|`.
- Rút ngẫu nhiên có trọng số theo seed.

Đây không phải tối ưu toàn cục, mà là heuristic tham lam có seed. Báo cáo sẽ ghi rõ điều này.

**Bước 5. Tính lại thời lượng thật** của từng phần bằng `d(q)` (Phase 1) và ghi vào biên bản cùng thời lượng dự kiến. Nếu thời lượng thật vượt khung (do stimulus thật lệch xa trung bình):

- Đổi câu dài nhất của phần đó lấy một câu ngắn hơn cùng dạng, cùng mức, nếu có. Tối đa 3 lần.
- Vẫn vượt thì giữ đề, đánh dấu `timeFrameWarning` trong biên bản. Không chặn tạo đề.

**Tái lập:** mọi rút ngẫu nhiên dùng `Random(seed ^ hash(taskTypeKey) ^ hash(level))`, giống cách `drawDeterministic` hiện có.

## 3. Biên bản lắp đề (bổ sung vào `report`)

```json
{
  "cefr": {
    "target": {"B1": 20, "B2": 40, "C1": 30, "C2": 10},
    "bySkill": {
      "READING": {"quota": {"B1": 4, "B2": 7}, "actual": {"B1": 4, "B2": 6, "C1": 1}}
    },
    "fallbacks": [{"taskType": "RE_ORDER_PARAGRAPHS", "wanted": "C2", "used": "C1"}],
    "unclassifiedUsed": 0
  },
  "duration": {
    "planned": {"SW": 4810, "READING": 1590, "LISTENING": 2080},
    "actual":  {"SW": 4795, "READING": 1602, "LISTENING": 2101},
    "timeFrameWarning": false
  }
}
```

## 4. Readiness (độ phủ ngân hàng)

Endpoint feasibility thêm cho mỗi dạng bài: số câu APPROVED theo từng mức CEFR và số câu chưa phân loại. Đề chuẩn sẵn sàng khi mỗi kỹ năng có đủ câu để đạt hạn ngạch mà không cần lấy bù quá 1 mức.

## 5. Kiểm thử

- Làm tròn Hamilton: tổng hạn ngạch luôn bằng `N_s`.
- Đủ câu thì phân bố thực tế khớp hạn ngạch.
- Thiếu câu thì lấy bù đúng thứ tự, ghi đủ `fallbacks`.
- Đề chuẩn không bao giờ có câu dưới B1.
- Cùng seed cùng đề.
- Hồi quy: mẫu không có tỉ lệ CEFR thì chọn câu như `drawDeterministic` cũ.
- Không trùng câu trong cùng đề.

## 6. Xong khi

- Test xanh, container healthy.
- Tạo 20 đề local, xuất bảng phân bố CEFR và thời lượng thật làm phụ lục báo cáo.
