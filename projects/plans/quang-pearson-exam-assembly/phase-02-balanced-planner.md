# Phase 2: Lập kế hoạch số câu theo khung

Phụ thuộc: Phase 1
Repo: `pte-api` (assessment)
Migration: `V26__exam_assembly_report.sql`
Căn cứ: P3 (các đề được cân bằng tổng độ dài, không ai gặp cực trị), P4 tầng (a) và (c)

## 1. Bài toán

Cho mẫu có khung. Với mỗi dạng bài `t` (gồm cả Personal Introduction ẩn) cần chọn số câu `n_t ∈ [min_t, max_t]` sao cho:

```
sw_min ≤ Part S&W ≤ sw_max
r_min  ≤ Part R   ≤ r_max
l_min  ≤ Part L   ≤ l_max
S&W + R + L ≤ total_max
```

và trong các tổ hợp hợp lệ, chọn **ngẫu nhiên theo seed, ưu tiên tổ hợp gần giữa khung**, không chọn cực trị khi còn lựa chọn khác.

## 2. Thuật toán `BalancedCountPlanner`

Hàm thuần, đặt trong `assessment/internal/service/assembly/`, không phụ thuộc Spring.

**Bước 1. Liệt kê theo từng phần.** Với một phần có `k` dạng bài, mỗi dạng 1–3 lựa chọn. Mẫu chuẩn có S&W 9 dạng, tối đa 2⁷ = 128 tổ hợp. Duyệt hết là đủ nhanh, không cần quy hoạch động. Giữ các tổ hợp có tổng nằm trong khung phần.

- Nếu số tổ hợp của một phần vượt 100.000 (mẫu tương lai lớn hơn), chuyển sang quy hoạch động trên tổng giây làm tròn 5 giây. Ghi vào ADR trong báo cáo.

**Bước 2. Ghép ba phần.** Tích Đề-các của ba danh sách, lọc theo trần tổng. Mẫu chuẩn có khoảng vài nghìn đến vài trăm nghìn tổ hợp. Sắp theo tổng giây để cắt sớm khi vượt trần.

**Bước 3. Trọng số.** Với tổ hợp `c`:

```
w(c) = Π_phần exp(-((T_phần(c) - giữa_phần) / nửa_độ_rộng_phần)² × α)
```

- `giữa_phần = (min + max) / 2`, `nửa_độ_rộng_phần = (max - min) / 2`.
- `α = 2` (hằng số, ghi trong `AssessmentConstants`). Tổ hợp sát biên có trọng số nhỏ nhưng khác 0.
- Loại tổ hợp "mọi dạng = min" hoặc "mọi dạng = max" nếu còn tổ hợp khác (P3).

**Bước 4. Chọn.** Rút một tổ hợp theo trọng số bằng `java.util.Random(seed)`. Cùng seed thì cùng kết quả.

**Không khả thi.** Trả `PlanResult.infeasible` kèm từng phần: tổng ngắn nhất và dài nhất đạt được so với khung, ví dụ "Listening: dài nhất 28,4 phút, khung yêu cầu ≥ 31".

## 3. Tích hợp

**`ExamBlueprintAssembler`**

- Mẫu có khung, hoặc mẫu trung tâm đạt chuẩn ở Phase 3: dùng planner thay `roll()`.
- Mẫu không khung: giữ `roll()`. Test hồi quy đảm bảo kết quả theo seed không đổi.
- Chọn một phần kỹ năng (ví dụ chỉ Reading): chỉ áp khung cho phần đã chọn, bỏ trần tổng.

**Kích hoạt mẫu admin** (`ExamDefinitionActivationValidator`)

- Mẫu nền tảng bắt buộc có khung, và planner phải khả thi.
- Lỗi: `TEMPLATE_TIME_FRAME_INFEASIBLE` với thông báo theo phần (đặt trong `ExamDefinitionConstants`).

**Biên bản lắp đề (`V26`)**

- Bảng `exam_assembly_reports` (1–1 với đề đã tạo, cột `exam_version_public_id` hoặc tương đương, xác nhận khi làm):
  - `algorithm_version` (chuỗi, ví dụ `balanced-v1`)
  - `seed bigint`
  - `template_public_id`, `template_version`
  - `report jsonb`: số câu từng dạng, thời lượng dự kiến từng phần, khung áp dụng, số tổ hợp hợp lệ, trọng số tổ hợp được chọn
- Phase 5 ghi thêm vào `report` phần CEFR.
- Endpoint đọc: `GET /api/v1/exams/{id}/assembly-report`, cho admin, host của tenant đó và giám khảo.

## 4. Kiểm thử

- Khung rộng thì luôn khả thi; khung không đạt được thì báo đúng phần và số phút thiếu hoặc dư.
- Tổng không bao giờ vượt trần (property test: 1.000 seed).
- Cùng seed cùng kết quả; seed khác cho phân phối nhiều tổ hợp.
- Không chọn cực trị khi còn tổ hợp khác. Assert theo tập: chạy 10.000 seed và kiểm không có cực trị.
- Hồi quy: mẫu không khung cho blueprint giống hệt trước khi đổi.
- Kích hoạt mẫu admin không khả thi bị từ chối với thông báo đúng.

## 5. Xong khi

- Test xanh, container healthy.
- Tạo 20 đề local từ mẫu chuẩn: mọi phần nằm trong khung, không đề nào cực trị. Lưu kết quả làm phụ lục cho báo cáo Phase 8.
