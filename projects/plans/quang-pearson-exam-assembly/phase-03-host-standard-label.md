# Phase 3: Nhãn "Chuẩn Pearson" cho mẫu trung tâm

Phụ thuộc: Phase 2
Repo: `pte-api` (assessment)
Migration: không

## 1. Quyết định sản phẩm

- Trung tâm được tự do chọn dạng bài, số câu và thời gian, miễn dùng dạng bài nền tảng có. Không thêm validation chặn nào.
- Hệ thống **tự tính** mẫu đó còn "Chuẩn Pearson" hay đã thành "Tùy chỉnh", để trung tâm, học viên và báo cáo biết đề nào sát thi thật.

## 2. Quy tắc (tính ra, không lưu)

Mẫu trung tâm `H` với mẫu gốc `B` là **Chuẩn Pearson** khi đồng thời:

| # | Điều kiện | Mã lý do khi không đạt |
|---|---|---|
| R1 | `H` có đủ mọi dạng bài của `B` | `MISSING_TASK_TYPE:<key>` |
| R2 | `prep`, `response` của mỗi dạng bằng `B` | `TIMING_CHANGED:<key>` |
| R3 | `[min, max]` của mỗi dạng nằm trong `[min, max]` của `B` | `COUNT_OUTSIDE_STANDARD:<key>` |
| R4 | Planner với khung của `B` vẫn khả thi | `TIME_FRAME_INFEASIBLE:<part>` |
| R5 | Tỉ lệ CEFR mục tiêu (Phase 5) chỉ dùng mức B1–C2 | `CEFR_OUTSIDE_STANDARD` |
| R6 | Trọng số Overall, Speaking, Writing, Reading, Listening của mỗi dạng bằng `B` | `WEIGHTS_CHANGED:<key>` |

**Trọng số tính vào chuẩn (R6, quyết định 2026-11-03).** Trọng số quyết định cách điểm từng câu dồn thành điểm kỹ năng và Overall. Nhãn "Chuẩn Pearson" cam kết cả cấu trúc đề lẫn cách quy điểm; đổi trọng số mà giữ nhãn thì hai đề cùng nhãn có hai thang điểm khác nhau.

**Thứ tự không tính vào chuẩn.** Khi lắp đề, câu luôn được sắp theo thứ tự chuẩn của từng phần (`TemplateTaskOrder`), nên thứ tự trong mẫu trung tâm không làm đổi đề học viên nhận.

Trung tâm vẫn tự do đổi trọng số; đề của họ mang nhãn "Tùy chỉnh" kèm lý do `WEIGHTS_CHANGED`.

R5 chỉ áp dụng sau khi Phase 5 xong. Trước đó R5 coi như đạt.

## 3. Thay đổi code

- `HostTemplateStandardCheck` (hàm thuần): nhận `H`, `B`, kết quả planner; trả `pearsonStandard` và danh sách mã lý do.
- `ExamDefinitionResponse` thêm `pearsonStandard: Boolean` (null với mẫu admin) và `standardDeviations: List<String>`.
- `HostExamTemplateService.list/get` tính nhãn. Danh sách tính một lần cho mỗi mẫu gốc, không gọi planner lặp lại cho từng mẫu (cache theo `B.publicId + B.version` trong phạm vi request).
- Lắp đề từ `H` đạt chuẩn: dùng planner với khung của `B`. Không đạt: dùng `roll()`.
- Biên bản lắp đề ghi `standardLabel` và các mã lý do tại thời điểm tạo đề. Nhãn được "đóng băng" cùng đề, mẫu đổi sau đó không làm đổi nhãn của đề cũ.

## 4. Kiểm thử

- Mỗi quy tắc R1–R4 và R6 có một test làm mất chuẩn với đúng mã lý do; so sánh trọng số dùng `BigDecimal.compareTo`, không dùng `equals` (tránh lệch scale như `4.0` và `4.00`).
- Clone nguyên mẫu gốc thì đạt chuẩn.
- Đổi thứ tự vẫn đạt chuẩn.
- Đổi trọng số một dạng thì mất chuẩn với `WEIGHTS_CHANGED:<key>`.
- Mẫu gốc đổi phiên bản (khung mới) thì nhãn của `H` được tính lại theo khung mới.
- Đề đã tạo giữ nhãn cũ khi mẫu thay đổi.

## 5. Xong khi

- Test xanh, container healthy.
- `host.e2e@test.local` clone mẫu chuẩn thì thấy `pearsonStandard = true`. Bỏ Read Aloud thì thành `false` với `MISSING_TASK_TYPE:READ_ALOUD`.
