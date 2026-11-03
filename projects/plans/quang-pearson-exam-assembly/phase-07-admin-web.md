# Phase 7: Giao diện admin

Phụ thuộc: Phase 1, 2, 4 (và 5 cho tỉ lệ CEFR)
Repo: `pte-web` (vendor-web: scoretemplate, examstudio, questionbank)
Chuẩn: `docs/CODING_STANDARDS_WEB.md`. Dùng component chung (`DashboardCard`, `Chip`, `Tabs`, `DescriptionList`, `Modal`...), không inline style, chuỗi trong constants, bản dịch Việt trong `adminCopy.ts`. Kiểm tra bằng `tsc`, `eslint`, `vitest`, không mở trình duyệt.

## 1. Trình soạn mẫu (`scoretemplate`)

**Khung thời gian.** Mục mới trong menu "…" là "Khung thời gian", mở Modal gồm:

- 3 hàng (Speaking & Writing, Reading, Listening), mỗi hàng có ô phút tối thiểu và tối đa.
- Ô trần tổng tính bằng phút.
- Nút "Khôi phục khung Pearson" để nạp lại 76–84 / 23–30 / 31–39 / 135.

**Thanh thời lượng.** Thanh tóm tắt đặt cạnh bảng dạng bài:

- Mỗi phần hiện ngắn nhất / dự kiến / dài nhất so với khung, màu xanh khi trong khung và cam khi lệch.
- Dữ liệu lấy từ endpoint feasibility (Phase 1–2).
- Khi không khả thi thì hiện câu giải thích từ backend, ví dụ "Listening dài nhất 28,4 phút < 31".

**Tỉ lệ CEFR.** Mục "Độ khó" trong menu "…", Modal nhập phần trăm B1–C2:

- Kiểm tổng 100.
- Kèm bảng độ phủ: số câu APPROVED theo mức và kỹ năng.

**Kích hoạt.** Lỗi `TEMPLATE_TIME_FRAME_INFEASIBLE` hiện thành thông báo theo phần.

## 2. Content Hub (`examstudio`)

- Tab Timeline: đổi "About X minutes" thành "X–Y phút", tính theo mô hình mới.
- Tab Coverage: thêm chiều CEFR, dạng heatmap theo dạng bài × mức, đếm câu APPROVED.
- Kanban: chip CEFR trên thẻ; kéo vào cột Approved mở hộp xác nhận CEFR (Phase 4).

## 3. Ngân hàng câu hỏi (`questionbank`)

Đã mô tả ở Phase 4 mục 4 (form, chi tiết, danh sách, bộ lọc, hộp duyệt). Phase này chỉ hoàn thiện phần giao diện còn lại và test.

## 4. Kiểm thử

- Unit test: modal khung (kiểm min ≤ max, trần ≥ tổng tối thiểu), thanh thời lượng (màu theo trạng thái), modal CEFR (tổng 100), heatmap coverage.
- `tsc` cho vendor-web và tenant-web; `vitest` toàn bộ.

## 5. Xong khi

- Tất cả kiểm tra tĩnh và unit test xanh.
- Danh sách màn hình đã đổi được ghi vào báo cáo Phase 8 (kèm ảnh chụp, do người dùng tự chụp).
