# Phase 1: Mô hình thời gian và khung Pearson

Phụ thuộc: không
Repo: `pte-api` (assessment, itembank, media)
Migration: `V25__exam_time_model.sql`

## 1. Vấn đề

Thời gian một câu hiện chỉ là `prep + response`. Như plan đã đo, mẫu chuẩn không thể đạt khung Pearson ở Speaking & Writing và Listening, vì thiếu:

- thời gian phát audio hoặc hiển thị đề (stimulus) trước khi làm, ví dụ đoạn hội thoại của Summarize Group Discussion hay bài nghe của Write From Dictation;
- thời gian cố định cho hướng dẫn và chuyển câu (overhead).

## 2. Mô hình thời gian mới

Thời lượng **dự kiến** của một câu `q` thuộc dạng bài `t`:

```
d(q) = overhead(t) + stimulus(q) + prep(t) + response(t)
```

| Thành phần | Nguồn | Ghi chú |
|---|---|---|
| `prep(t)`, `response(t)` | Dòng của dạng bài trong mẫu (`exam_definition_items`) | Đã có |
| `stimulus(q)` | `MediaAsset.durationSeconds` của audio đề, nếu có | Đã có dữ liệu cho audio upload qua Cloudinary |
| `stimulus(q)` khi thiếu dữ liệu | `stimulus_estimate_seconds(t)` lưu theo dạng bài | Mới; ví dụ Repeat Sentence ≈ 5s, Re-tell Lecture ≈ 90s |
| `overhead(t)` | `overhead_seconds(t)` lưu theo dạng bài | Mới; thời gian hướng dẫn và chuyển câu, mặc định nhỏ (ví dụ 5s) |

Thời lượng dự kiến của một **dạng bài với `n` câu** khi lập kế hoạch (Phase 2), lúc chưa biết sẽ chọn câu nào:

```
D(t, n) = n × (overhead(t) + stimulus_avg(t) + prep(t) + response(t))
```

trong đó `stimulus_avg(t)` là trung vị stimulus của các câu APPROVED thuộc dạng `t` (mẫu nhỏ thì dùng giá trị ước lượng). Phase 5 dùng `stimulus(q)` thật của câu đã chọn để tính lại chính xác.

Thời lượng một **phần** Pearson:

```
Part S&W  = Σ D(t, n_t) với t ∈ SPEAKING ∪ WRITING
Part R    = Σ D(t, n_t) với t ∈ READING
Part L    = Σ D(t, n_t) với t ∈ LISTENING
Tổng      = S&W + R + L
```

**Đồng hồ khi thi không đổi** (`AttemptStartFlow` và `TimerService` vẫn đếm `prep + response`). Mô hình trên chỉ dùng để **lập kế hoạch đề và báo cáo**. Lý do: phát audio là việc client làm trước khi đồng hồ trả lời chạy, như ở đề Pearson. Báo cáo sẽ ghi rõ sự khác biệt giữa thời lượng dự kiến và đồng hồ thi.

Ước lượng stimulus và overhead mặc định phải được hiệu chỉnh sao cho mẫu chuẩn rơi vào khung Pearson. Phase này xuất bảng tính so sánh cho bạn duyệt trước khi chốt số.

## 3. Khung thời gian trên mẫu

Thêm vào `exam_definitions` (nullable, đơn vị giây):

| Cột | Ý nghĩa | Giá trị nạp cho mẫu admin ACTIVE |
|---|---|---|
| `sw_min_seconds`, `sw_max_seconds` | Speaking & Writing | 4560 – 5040 (76–84 phút) |
| `reading_min_seconds`, `reading_max_seconds` | Reading | 1380 – 1800 (23–30) |
| `listening_min_seconds`, `listening_max_seconds` | Listening | 1860 – 2340 (31–39) |
| `total_max_seconds` | Trần tổng | 8100 (135) |

Ràng buộc:

- `CHECK (min > 0 AND min <= max)` cho từng phần.
- `total_max_seconds ≥ sw_min + reading_min + listening_min`. Kiểm tra ở service, vì CHECK nhiều cột trên dữ liệu nullable khó đọc.

Mẫu trung tâm **không có khung riêng**. Phase 3 đọc khung của mẫu gốc.

## 4. Thay đổi code

**itembank (theo dạng bài)**

- Bảng task type (`question_types` hoặc tương đương, xác nhận khi làm) thêm `stimulus_estimate_seconds int NOT NULL DEFAULT 0` và `overhead_seconds int NOT NULL DEFAULT 0`.
- `V25` nạp giá trị mặc định cho 22 dạng chuẩn sau khi bạn duyệt bảng hiệu chỉnh.
- `ItembankService` thêm API công khai `stimulusStatistics(Set<taskTypeKey>)` trả trung vị, số câu có dữ liệu và số câu thiếu, cho module assessment dùng. Không truy cập trực tiếp `internal` của itembank.
- Lấy `durationSeconds` qua API công khai của module media, không join chéo module trong JPA.

**assessment**

- `@Embeddable ExamTimeFrame` (7 trường) trên `ExamDefinition`.
- `ExamTimeModel`: hàm thuần, tính `D(t, n)`, thời lượng từng phần, tổng.
- `ExamDefinitionResponse.timeFrame` kèm constructor tương thích.
- Sửa khung: `PUT /api/v1/exam-definitions/{id}/time-frame`, chỉ trên DRAFT, cùng quyền sửa dạng bài của mẫu (`SecurityPolicy.canModifyAcademicDraft`): tác giả của mẫu là Academic Staff hoặc Academic Manager, hoặc Platform Admin. Platform Manager không có quyền. Ghi audit log.
- `cloneToDraft` chép khung.
- Mã lỗi và thông báo đặt trong `ExamDefinitionConstants`: `TIME_FRAME_INVALID_RANGE`, `TIME_FRAME_TOTAL_BELOW_MINIMUM`.

**Endpoint feasibility** (`/exam-definitions/{id}/feasibility`) trả thêm cho mỗi phần: `minSeconds`, `maxSeconds` (theo `min`, `max` số câu), `frameMinSeconds`, `frameMaxSeconds`, và số câu thiếu dữ liệu stimulus.

## 5. Kiểm thử

- `ExamTimeModelTest`: công thức `d(q)` và `D(t, n)`; dùng ước lượng khi thiếu dữ liệu; cộng đúng theo phần (S&W gộp hai section).
- Validator khung: từ chối `min > max`, giá trị âm, trần nhỏ hơn tổng các mức tối thiểu.
- Clone chép khung; mẫu trung tâm không có khung.
- Feasibility trả đúng thời lượng theo phần cho mẫu seed.
- `ModuleStructureTest` xanh (assessment chỉ gọi API công khai của itembank và media).

## 6. Xong khi

- Bảng hiệu chỉnh stimulus và overhead cho 22 dạng bài được duyệt, mẫu chuẩn rơi vào khung Pearson với ít nhất một tổ hợp ở mỗi phần.
- Toàn bộ test `app` xanh, container `app` healthy, migration áp bằng tay ở local.
- `GET` mẫu ACTIVE trả `timeFrame` đúng giá trị nạp.
