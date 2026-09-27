# Brainstorm: Phân công examiner và duyệt nguồn điểm

**Date:** 2026-09-23

## Ideas Explored

1. **Giao theo câu trả lời hay theo bài làm:** Chọn giao nguyên attempt của một student cho một examiner; toàn bộ câu trả lời Speaking/Writing đủ điều kiện trong attempt đi cùng nhau.
2. **Phạm vi và cách phân công:** Host lọc theo Program/Class trong một exam/session. Có thể gán thủ công theo phạm vi hoặc chọn nhiều examiner rồi random các attempt trong pool chung; không random lớp. 40 attempt và 2 examiner phải thành 20/20.
3. **Cấu hình một lần hay tái sử dụng:** Chọn áp dụng riêng cho exam/session hiện tại; chưa lưu quy tắc mặc định cho kỳ thi sau.
4. **Ai quyết định điểm cuối:** Examiner gửi điểm nhưng không tự chốt. Host xem điểm AI và Examiner, chọn nguồn sẽ dùng, duyệt rồi mới publish.
5. **Độ hạt khi chọn nguồn điểm:** Host áp dụng nguồn AI/Examiner theo task type, section hoặc toàn bộ câu đủ điều kiện. Áp dụng phạm vi hẹp sau phạm vi rộng sẽ ghi đè lựa chọn trong tập câu hẹp đó.
6. **Thiếu điểm:** Không publish một phần; publish bị chặn nếu câu đủ điều kiện chưa có nguồn điểm được chọn và điểm hợp lệ.
7. **Nguồn AI ở local:** Provider mặc định hiện là stub trả điểm placeholder; các điểm này không được xem là điểm AI thật hoặc cho phép publish.

## User's Direction

- Trong session hiện tại, Host chọn Program/Class làm bộ lọc bài dự thi và chọn một hoặc nhiều examiner.
- Có thể phân công thủ công theo lớp/program; chế độ random lấy tất cả attempt thuộc các lớp đã chọn làm một pool, trộn attempt của student rồi chia đều giữa các examiner. Mỗi attempt chỉ thuộc một examiner.
- Host duyệt điểm bằng cách chọn AI hoặc Examiner theo task type, section hoặc hàng loạt; các thao tác hẹp hơn áp dụng sau ghi đè lựa chọn trên các câu tương ứng.
- Không publish đến khi mọi câu AI-eligible trong phạm vi cần publish có nguồn điểm hợp lệ được host chọn.
- Cấu hình phân công chỉ sống trong một exam/session; không tự áp dụng cho kỳ thi sau.

## Existing-Code Fit

- ScoringAnswer hiện giữ rawScore và teacherScore độc lập; teacherScore hiện không lưu examiner identity, assignment, hay trạng thái host approval.
- ScoringReviewController hiện chỉ cho HOST_ADMIN truy cập; examiner cần API và authorization chỉ cho attempt được giao, cùng tenant.
- ScoreAggregationService hiện tổng hợp rawScore; chọn điểm Examiner để publish đòi hỏi reporting đọc selected score thay vì luôn dùng rawScore.
- ReportPublishService hiện publish reports cho các submitted attempts mà không kiểm tra nguồn điểm được duyệt; cần thêm readiness gate.
- Attempt hiện chỉ lưu session/student/tenant IDs; Class/Program thuộc enrollment/session-assignment và phải được tra qua module API/query boundary, deduplicate khi một student thuộc nhiều lớp.
- Runtime scoring method đã được resolve từ ScoreTemplate được pin cho attempt; assignment eligibility và section filter cần dựa vào snapshot/template này, không hardcode task names.

## Open Questions

- Examiner có được xem AI score trước khi submit điểm không? Đề xuất mặc định ẩn để giảm anchoring; Host luôn xem cả hai nguồn.
- Nếu manual rules khớp cùng một attempt do student thuộc nhiều class, Host phải chọn một examiner/class mapping trước khi xác nhận.
- MVP dùng một điểm tổng 0–100 trên mỗi câu theo contract hiện tại; rubric chi tiết theo từng tiêu chí/task type để giai đoạn sau.

## Risks

- Mở rộng sai quyền review có thể cho examiner xem bài ngoài assignment hoặc ngoài tenant; bắt buộc kiểm tra assignment ở backend trên từng API.
- Random phải ổn định sau khi xác nhận và không tạo assignment trùng; lớp chỉ là filter, không phải đơn vị random.
- Nếu giữ nguyên report aggregation dựa trên rawScore, lựa chọn Examiner của Host sẽ không tác động đến report Student; nếu cho đổi lựa chọn sau publish, điểm đã công bố có thể thay đổi.
- Điểm từ provider stub có status SCORED nhưng không phải kết quả chấm thật; cần provenance và chặn xuất bản nguồn stub.
