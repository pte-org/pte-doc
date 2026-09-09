# Brainstorm: Bỏ server-side per-task timer polling/enforcement, chuyển countdown về client

**Date:** 2026-09-07

## Bối cảnh

Xuất phát từ câu hỏi "tại sao cần poll `GET /attempts/{id}/timer` mỗi 10s" — qua nhiều vòng phản biện, đi tới việc rà lại toàn bộ lý do tồn tại của cơ chế server-authoritative timer hiện tại (mô tả đầy đủ ở [time_deadline.md](../../../research/time_deadline.md)). Tài liệu tổng hợp lý do + hướng thay đổi đã viết riêng tại [research/refactor_polling.md](../../../research/refactor_polling.md) — dùng làm nguồn chính, không lặp lại chi tiết ở đây.

## Ideas Explored

- **Giữ nguyên hiện trạng** (poll 10s + so deadline server-side mỗi lần nộp bài) — bị bác vì chi phí không tương xứng: đã gây 2 bug thật (label/progress-bar desync, late recording start — ghi lại ở [phat-speaking-dynamic-prep-timing/plan.md](../../../pte-app/plans/phat-speaking-dynamic-prep-timing/plan.md)) và 1 bug polling-sau-khi-complete.
- **Client tự đếm ngược hoàn toàn, không có gì từ server** (ý tưởng ban đầu của user, lấy cảm hứng từ mô hình TOEIC) — bị bác một phần: TOEIC per-question vẫn auto-advance theo nội dung (độ dài audio), không phải "1 deadline duy nhất cho cả bài" như hiểu ban đầu; cần giữ thời lượng riêng từng câu để đúng cấu trúc đề PTE thật.
- **1 deadline duy nhất cho toàn bộ bài thi** (đề xuất giữa buổi của user) — bị bác: xóa mất sự khác biệt cấu trúc thật giữa Reading (section-scoped, cho xem lại) và Speaking/Listening (ép tiến độ từng câu, không cho quay lại) — đề PTE thật không phát "1 pool thời gian tự chia" cho cả 4 kỹ năng.
- **Hybrid: giữ per-item duration, chỉ bỏ phần server xác nhận lại (poll) mỗi ranh giới** — hướng trung gian đã cân nhắc dựa trên bằng chứng nguyên tắc "trust server exclusively" trong `TimerService` (pte-app) — cuối cùng được thay bằng kết luận mạnh hơn ở dưới sau khi phân tích mô hình kinh doanh.
- **Phân tích lại động cơ chống-gian-lận theo đúng 2 mô hình bán hàng thực tế** (B2C tự luyện tại nhà; B2B bán cho tổ chức cấp bằng có giám thị + máy kiosk) — kết luận: động cơ ban đầu của toàn bộ cơ chế server-side enforcement không còn áp dụng ở cả hai kênh, miễn kênh B2B thật sự khóa OS máy thi (điều kiện, không phải mặc định).
- **Phát hiện xung đột với brainstorm khác cùng ngày**: [260907-attempt-connectivity-monitoring-brainstorm.md](../../../.claude/plans/reports/260907-attempt-connectivity-monitoring-brainstorm.md) đã chốt dùng chính `GET /timer` (10s) + `POST /answers` (30s) làm "heartbeat thụ động" cho tính năng giám sát kết nối thí sinh (dành cho giám thị, đúng kênh B2B). Xóa `/timer` mà không thay thế sẽ phá tín hiệu đó.
- **Dùng riêng `POST /answers` làm heartbeat thay cho `/timer`** — cân nhắc rồi bị bác: `SyncEngine` chủ động bỏ qua task đang hiển thị khi flush nền ([data_safety.md §4](../../../research/data_safety.md)), nên trong lúc thí sinh đang ở giữa 1 task sẽ không có `POST /answers` nào — gây false positive "mất kết nối" nếu task dài hơn ngưỡng phát hiện.

## User's Direction

Chốt cuối: **xóa hẳn** toàn bộ server-side per-task deadline enforcement, không giữ feature-flag bật/tắt theo gói (đã cân nhắc và bác phương án cờ, chấp nhận rủi ro phải làm lại nếu có khách B2B tương lai không đáp ứng điều kiện kiosk).

Cụ thể:
- **Giữ nguyên**: `prepSeconds`/`responseSeconds`/`preListenSeconds`/`preRecordSeconds` per-item, section-scoped deadline cho Reading (đúng cấu trúc đề thật) — chỉ đổi *nơi* dùng chúng để đếm ngược/auto-advance, từ server-confirmed sang hoàn toàn client-driven. Toàn bộ outbox/`SyncEngine` local-first không đổi.
- **Xóa hẳn**: `TimerController` (`GET /attempts/{id}/timer`), `TimerState` + bảng `timer_states`, poll định kỳ + one-shot poll trong `TimerService` (pte-app), check `isResponseWindowExpired` + grace 15s trong `AttemptService.processAnswer`.
- **Thêm mới**: 1 endpoint heartbeat riêng, nhẹ, tách hoàn toàn khỏi mọi logic timer/deadline — chỉ để cập nhật tín hiệu "còn sống" cho tính năng giám sát kết nối (đã brainstorm ở report khác cùng ngày), gọi định kỳ bởi pte-app trong suốt lúc `IN_PROGRESS`, kể cả giữa lúc đang làm 1 task dài.
- Phiên thi đóng lại (`submitAttempt`) do **client tự quyết định** kích hoạt (hết giờ tổng theo đồng hồ local, hoặc thí sinh force-submit) — không còn bị chặn bởi so sánh deadline phía server.

## Open Questions

- **Endpoint heartbeat mới**: khoảng cách gọi cụ thể (đề xuất 20-30s, thưa hơn `/timer` cũ) — cần đối chiếu lại với ngưỡng phát hiện mất kết nối 45-60s đã chốt ở report connectivity-monitoring, và **report đó cần cập nhật lại để trỏ vào endpoint mới này thay vì `/timer`/`POST /answers`** trước khi cả hai cùng vào `/ck:plan`.
- **Task hết giờ mà không nộp gì (blank/timeout) báo lên server bằng cách nào** khi không còn deadline lưu ở server để tự động expire? Cần 1 tín hiệu tường minh từ client (tái dùng `submitAnswer` với payload rỗng, hay thêm 1 endpoint "skip/timeout" riêng) — chưa quyết, để `/ck:plan` xử lý.
- **Số phận `AttemptService.advanceUntilLiveOrComplete`**: hiện dùng để tự động "dọn" các task đã hết hạn theo deadline lưu trong DB. Một khi không còn deadline nào lưu ở server, vòng lặp catch-up dựa-trên-thời-gian này không còn gì để kích hoạt — cần xác định lại: bỏ hẳn, hay giữ lại 1 phần để xử lý answer tới không đúng thứ tự do `SyncEngine` sync nền (độc lập với timing).
- **Thứ tự triển khai** giữa refactor này và tính năng giám sát kết nối — vì cả hai cùng động vào đúng 1 vùng endpoint (`/timer`, `/answers`), nên cùng cần 1 điểm phối hợp (endpoint heartbeat mới) làm tiền đề chung, tránh việc 1 bên lên `/ck:plan` trước làm sai giả định của bên kia.

## Risks

1. **Điều kiện "máy B2B phải khóa kiosk OS thật" không được code này verify hay enforce được** — đây là rủi ro hợp đồng/triển khai, không phải rủi ro kỹ thuật; cần đưa vào checklist bàn giao cho khách B2B, không phải giả định mặc định (nêu chi tiết ở [refactor_polling.md §7](../../../research/refactor_polling.md#7-rủi-ro--điều-kiện-cần-lưu-ý-trước-khi-chốt)).
2. **Đụng vùng code dùng chung với brainstorm connectivity-monitoring** (cùng ngày, cùng endpoint family) — nếu không phối hợp thứ tự plan/implement, một bên có thể làm hỏng giả định của bên kia (report kia giả định `/timer` vẫn tồn tại).
3. **`advanceUntilLiveOrComplete`/`processAnswer` là code dùng chung** cho cả STANDARD lẫn STRICT-encrypted submission path — xóa phần deadline cần cẩn thận không đụng nhầm sang phần kiểm tra thứ tự task (`NotCurrentTaskException`) hay phần mã hóa, vốn không liên quan tới thay đổi lần này.
