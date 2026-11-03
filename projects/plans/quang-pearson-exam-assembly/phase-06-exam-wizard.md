# Phase 6: Tạo kỳ thi ở trung tâm

Phụ thuộc: Phase 3 (nhãn), Phase 5 (tỉ lệ CEFR)
Repo: `pte-api` (session, assessment), `pte-web` (tenant-web exams, api-client)
Migration: phần kỳ thi của `V28__cefr_target_mix.sql`

## 1. Luồng hiện tại

Wizard 4 bước: **Exam details** (tên, mẫu, kỹ năng) → **Schedule & policy** → **Audience** → **Review & create**. Backend sinh đề ngẫu nhiên bằng `generateExam`.

## 2. Luồng mới

Bước **Exam details** thêm mục **"Độ khó"**, có ba lựa chọn:

| Lựa chọn | Hành vi | Nhãn đề |
|---|---|---|
| **Chuẩn Pearson** (mặc định nếu mẫu đạt chuẩn) | Dùng tỉ lệ CEFR của mẫu gốc, chỉ B1–C2 | Chuẩn Pearson (nếu mẫu đạt chuẩn) |
| **Theo trình độ lớp** | Chọn một dải liên tục, ví dụ A2–B1; chia đều trong dải | Tùy chỉnh |
| **Tùy chỉnh** | Nhập phần trăm từng mức; tổng phải bằng 100 | Tùy chỉnh |

Mẫu không đạt chuẩn thì ẩn lựa chọn "Chuẩn Pearson" và mặc định "Theo mẫu" (tỉ lệ của mẫu trung tâm).

Bước **Review & create** thêm khối **"Dự kiến đề thi"**:

- Thời lượng từng phần và tổng, dạng khoảng ngắn nhất–dài nhất, so với khung nếu có.
- Phân bố CEFR mục tiêu.
- Cảnh báo độ phủ, ví dụ "Ngân hàng thiếu câu C2 ở Reading; sẽ lấy bù từ C1".
- Nhãn Chuẩn Pearson / Tùy chỉnh và lý do.

Dữ liệu lấy từ endpoint preview mới, không tự tính ở web.

## 3. Backend

- `POST /api/v1/exam-definitions/{id}/assembly-preview` (host, theo tenant): nhận kỹ năng và tỉ lệ CEFR; trả khoảng thời lượng, hạn ngạch CEFR theo kỹ năng, cảnh báo độ phủ, nhãn. Không ghi gì vào DB.
- Request tạo kỳ thi thêm `cefrTarget` (tùy chọn): `{ mode: STANDARD | BAND | CUSTOM, levels: {B1: 20, ...} }`.
- `V28` (phần kỳ thi): bảng `exam_cefr_targets(exam_id, level, percent)` lưu tỉ lệ đã dùng.
- `generateExam` truyền tỉ lệ xuống `StratifiedQuestionPicker`. Ưu tiên: kỳ thi, rồi mẫu, rồi mặc định chuẩn.
- Kiểm tra: tổng 100; mức hợp lệ; mode STANDARD chỉ dùng khi mẫu đạt chuẩn (`EXAM_STANDARD_MODE_NOT_ALLOWED`).
- Thông báo lỗi và mã trong constants của module sở hữu. Tuân `docs/API_RESPONSE_SETUP.md`.

## 4. Web (tenant-web)

- Component `DifficultyPicker`: segmented control 3 lựa chọn, dải chọn bằng hai Select, ô phần trăm dùng component chung. Tách file để mỗi component ≤ 150 dòng.
- Khối `AssemblyPreviewCard` ở bước Review.
- Trang chi tiết kỳ thi: chip nhãn, phân bố CEFR thực tế và thời lượng thực tế đọc từ biên bản lắp đề.
- Chuỗi trong constants và messages Việt của tenant-web.

## 5. Kiểm thử

- Backend: mỗi mode tạo đúng tỉ lệ; STANDARD bị từ chối với mẫu không chuẩn; preview không ghi DB; tỉ lệ lưu cùng kỳ thi.
- Web: picker kiểm tổng 100; ẩn STANDARD khi mẫu không chuẩn; preview hiển thị cảnh báo.
- Hồi quy: tạo kỳ thi không gửi `cefrTarget` thì chạy như trước (dùng mẫu).

## 6. Xong khi

- Test backend và web xanh, container healthy.
- `host.e2e@test.local` tạo được ba kỳ thi theo ba mode, chi tiết kỳ thi hiển thị đúng biên bản.
