# Member 3 — Flutter: Host Mini-Console

*[English version](tasks.md)*

## Thống nhất với Member 2 trước

Quyết định mở giống hệt bên trên (giữ `pte-app/core/` hay làm mới — xem file task của Member 2, đừng bàn lại từ đầu, chỉ cần thống nhất cùng 1 câu trả lời). Auth (Task 1 bên dưới) nên là **cùng 1 module** với Member 2 — đừng làm 2 luồng login riêng. Chia việc: ai làm tới đó trước thì build, người kia review.

## Nguồn contract chuẩn

Lưu ý giống Member 2 — chưa có OpenAPI sinh sẵn, đọc thẳng controller:
- `pte-api/services/authoring/src/main/java/com/pte/authoring/controller/{QuestionController,BlueprintController,SnapshotController}.java`
- `pte-api/services/scheduling/src/main/java/com/pte/scheduling/controller/{SessionController,EnrollmentController,ProctorAssignmentController}.java`
- `pte-api/services/scoring/src/main/java/com/pte/scoring/controller/ScoringReviewController.java`
- `pte-api/services/notification/src/main/java/com/pte/notification/controller/NotificationLogController.java`
- `pte-api/services/proctor/src/main/java/com/pte/proctor/controller/{ProctorSessionController,ViolationAuditController}.java` (chỉ phần REST — phần lệnh qua STOMP là stretch goal, xem Task 6)

## Task 1 — Auth (dùng chung với Member 2)

- Login host → xử lý token/refresh giống nhau. JWT của host có role `HOST_ADMIN`/`HOST_AUTHOR` — dùng để gate các màn/hành động chỉ host mới thấy (server vẫn re-validate lại toàn bộ, đây chỉ là phân nhánh UI).

## Task 2 — Author nội dung & đề thi

- Màn tạo câu hỏi theo từng loại task (tối thiểu 3 loại của Milestone 1: `MC_READING_SINGLE` có options, `READ_ALOUD` có prompt audio/text tham chiếu, `WRITE_ESSAY` có prompt + giới hạn số từ).
- Builder blueprint: chọn câu hỏi vào 1 blueprint.
- Publish snapshot: 1 hành động, biến blueprint thành snapshot bất biến có version để service khác tham chiếu.
- Nhớ phần phân quyền hiển thị: nội dung admin tạo là tenant-global (`tenant_id=NULL`, host chỉ đọc); nội dung host tạo là riêng cho tenant của họ. Cùng 1 màn, khác scope tùy role người gọi — đừng làm 2 màn riêng cho việc này.

## Task 3 — Compose session & enrollment

- Tạo session từ snapshot đã publish; composition full-mock vs. practice-subset (chọn loại task nào được đưa vào, khớp với `SessionComposition`).
- Enroll student (tìm theo lookup — scope Milestone 1 chỉ add từng người, không có bulk import).
- Gán proctor cho session.

## Task 4 — Trigger chấm điểm & publish

- Hành động "Chấm session này" → `POST /sessions/{id}/score`. Về phía UI đây là fire-and-forget (chạy async qua RabbitMQ ở nền); hiện trạng thái đang xử lý, đừng hiện spinner chặn màn hình chờ 1 response đồng bộ không bao giờ phản ánh đủ việc đã xong.
- Hàng chờ review essay: liệt kê các answer đang ở trạng thái `AI_SCORED_PENDING_REVIEW`, host review và duyệt qua endpoint review của scoring — **đây là cổng human-in-the-loop cho Write Essay** (ADR-002: Pearson yêu cầu human-review-on-top-of-AI cho 1 số loại task nhạy cảm; không có gì tới được student cho các loại task đó nếu thiếu bước này).
- Hành động "Publish" → `POST /sessions/{id}/publish`. Sau khi publish, điểm hiện ra cho student thấy; làm cho hành động này khác biệt rõ ràng về mặt UI so với "chấm điểm" (đây là điểm không thể quay lại về mặt hiển thị, host không nên bấm nhầm).

## Task 5 — Review notification & violation

- `GET /notifications` (tenant-scoped) — màn list/audit đơn giản xem email nào đã gửi và trạng thái gửi (`PENDING`/`SENT`/`FAILED`).
- `GET /exam-sessions/{sessionPublicId}/violations` (service proctor) — list violation đã bị flag cho 1 session, tenant-scoped, dành cho `HOST_ADMIN`/`HOST_AUTHOR`.

## Task 6 — Console giám thị live (stretch goal, chỉ làm nếu còn thời gian)

Toàn bộ mặt live-proctoring (kết nối STOMP, mở `ProctorSession`, gửi lệnh `FORCE_SUBMIT`/`EXTEND_TIME`, flag violation, thấy broadcast live từ proctor khác) là real-time và không đơn giản trong Flutter (cần package STOMP-over-WebSocket, ví dụ `stomp_dart_client`). Coi đây là scope riêng, ưu tiên thấp hơn phần còn lại của host console — host/proctor vẫn dùng được cho demo Milestone 1 mà không cần live WS proctoring (các màn audit REST ở Task 5 đã đủ cho review sau khi xảy ra). Xác nhận với leader xem có nằm trong scope không trước khi đầu tư thời gian vào đây.

## Sản phẩm bàn giao

- Host làm được: author 1 kho câu hỏi nhỏ, publish snapshot, tạo session, enroll student, trigger chấm điểm sau khi student làm bài, duyệt 1 essay đang chờ review, publish, và xem được audit trail violation/notification.
- `flutter analyze` và `flutter test` sạch, cùng chuẩn với Member 2 (`pte-app/CLAUDE.md`).
