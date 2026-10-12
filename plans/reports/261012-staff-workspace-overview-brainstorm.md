# Brainstorm: Trang tổng quan công việc Proctor và Examiner

Date: 2026-10-12.

## Ideas explored

1. Dashboard riêng nhiều biểu đồ: thêm trang/luồng điều hướng, không giúp thao tác chính đủ để đưa vào MVP.
2. Nâng cấp trang công việc hiện tại: thẻ tổng hợp chính xác, ưu tiên công việc, nút đi thẳng vào thao tác; phương án đề xuất và được người dùng chốt.
3. Chỉ giữ bảng hiện tại: chi phí thấp nhưng chưa giúp nhìn ngay lịch hôm nay và khối lượng chấm.
4. Thống kê toàn tenant/xếp hạng/historical analytics: ngoài phạm vi quyền và nhu cầu hiện tại.

## User direction

Người dùng trả lời “oke chốt” và yêu cầu ck-plan sau đề xuất nâng cấp `/proctor/sessions` và `/examiner/work`: 3–4 thẻ, danh sách ưu tiên, không dashboard BI riêng. AI tham khảo, Examiner quyết định cuối, Host công bố vẫn giữ nguyên.

## Boundaries

- Chỉ phân công của actor hiện tại trong tenant; số tổng hợp không tính từ trang hiện tại.
- Proctor thấy lịch, không đưa roster/vi phạm/kết nối đa phòng lên trang tổng quan.
- Examiner thấy tiến độ quyết định người chấm và lý do chờ Host; AI pending không chặn manual khi điều kiện khác đủ.
- Không triển khai trong lượt lập kế hoạch; không bật flag Proctor hay deploy.

## Validated execution choices

User selected browser timezone for Proctor, Today counts only sessions beginning on that local date (not sessions opened yesterday), and Examiner completed totals only for unpublished assigned work. Existing no-test/no-quality preference is retained; compile/typecheck/build remain planned verification.

## Risks

- Đếm khác policy queue hoặc tính từ pagination tạo KPI sai.
- Session OPEN nhưng ngoài cửa sổ giờ không được quảng cáo là vào giám sát ngay.
- Aggregate có join scores/member gây nhân bản hoặc query tăng theo số assignment.
