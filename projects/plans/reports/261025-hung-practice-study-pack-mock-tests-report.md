# Báo cáo: Study-Pack theo kỹ năng và Luyện đề

Ngày: 2026-10-25 · Nhánh `hung/feat/practice-revamp` · Trạng thái: **chưa commit**

## Đã làm
- BE: V134 (kind/skill_code/mock_test_id, bảng đề + câu ghim, CHECK question_count cho MOCK_TEST, unique lượt đang làm), phiên theo kỹ năng, đếm câu theo kỹ năng, tạo đề (admin, advisory lock), danh sách đề, phiên MOCK_TEST (resume/restart, TIMED), điểm ước lượng (`PracticeScoreEstimator`).
- FE: Study-Pack 4 kỹ năng + dialog chế độ cho kỹ năng; danh sách đề (Bắt đầu / Tiếp tục + Làm lại từ đầu / Làm lại + điểm); khối điểm ước lượng ở review.
- Seed `-MockTests N`; mẫu lặp theo 3 biến thể nên `-PerTask` tới 12.
- Sửa theo red-team: B1, H1–H6 (xem bảng trong plan.md).

## Kết quả lệnh
| Lệnh | Kết quả |
|---|---|
| `./mvnw -q -pl app -am test` (sau phase 2) | EXIT 0 |
| test mới BE: Allocation, SessionService (skill/mock), SkillStats, ScoreEstimator, MockTestService | pass |
| `npx tsc --noEmit` / eslint / vitest | sạch / 0 lỗi / 170 pass |
| Seed `-PerTask 12 -MockTests 3` | 3 đề × 65 câu, ~110 phút ước tính, 100% câu thuộc pool practice (SQL) |

## Bằng chứng trên trình duyệt
- Study-Pack: 67 câu, "1 trên 15 câu đã trả lời"; Reading, không tính giờ, 10 câu → 10 item / 5 dạng (SQL).
- Luyện đề: 3 đề; Start Đề 1 → câu 1/65 Speaking, Read Aloud tính giờ; quay lại danh sách → "Tiếp tục 0/65" + "Làm lại từ đầu".

## Chưa chạy
- Làm hết một đề / điểm ước lượng thực tế; hai học viên cùng đề; STUDENT gọi generate → 403; phiên legacy trước V134 trên UI; đo thời gian begin 65 item.
- Lỗi lúc seed: Cloudinary upload thỉnh thoảng thất bại (chạy lại được, script idempotent).

## Rủi ro
- Câu ghim bị gỡ/sửa revision thì bị bỏ qua (WARN), itemCount thực < 65.
- Công thức ước lượng chép từ `reporting` (xem Javadoc), phải giữ đồng bộ.
