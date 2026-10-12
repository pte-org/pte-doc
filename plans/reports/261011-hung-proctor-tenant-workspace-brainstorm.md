# Brainstorm: Proctor workspace trong tenant web

**Date:** 2026-10-11
**Scope:** Thiết kế dựa trên backend hiện có; bổ sung API cần thiết. Chưa triển khai sản phẩm.

## Ideas Explored

1. Dùng màn hình Host và ẩn chức năng theo role: ít thay đổi shell nhưng không phù hợp tác vụ giám sát; nhiều API Host không được phép dùng cho Proctor.
2. Workspace riêng trong tenant web: giữ auth, tenant, UI kit, locale; có navigation và dữ liệu giới hạn theo phân công. Đây là hướng đề xuất theo yêu cầu người dùng.
3. Chỉ nối scaffold với API hiện có: có thể ghi vi phạm và gửi FORCE_SUBMIT, nhưng thiếu danh sách phân công và roster nên không tạo được luồng sử dụng hoàn chỉnh.
4. Bảng giám sát thí sinh kèm panel chi tiết: phù hợp dữ liệu attempt, heartbeat và sự kiện hiện có; hỗ trợ nhiều thí sinh bằng phân trang.
5. Lưới camera hoặc console video: backend chưa có media stream; không đưa vào phạm vi này.
6. Ứng dụng Proctor riêng: phát sinh shell, auth và vận hành mới; không cần thiết khi người dùng muốn tiếp tục dùng tenant web.

## User's Direction

- “Vẫn sử dụng tenant web nhưng phân quyền”.
- “dựa vào back-end và thiết kế màn hình riêng cho nó”.
- Khi được hỏi về phạm vi API, người dùng chọn: **“Giao diện hoàn chỉnh, bổ sung API cần thiết (Đề xuất)”**.
- Vì vậy spec bao gồm workspace, API đọc dữ liệu phân công/giám sát và các kiểm tra quyền cần thiết để dùng workspace an toàn.

## Verified Codebase Context

- Tenant app ở `pte-web/apps/tenant-web`, các thư mục `app`, `features`, `lib` nằm trực tiếp dưới app, không có `src` trung gian.
- `/proctor` đã có scaffold nhưng bị feature flag tắt; trang gốc chuyển đến profile, sidebar chỉ có profile. Query giám sát/audit trả dữ liệu rỗng; nút thao tác chưa nối backend.
- Login chấp nhận PROCTOR nhưng thiếu đích đến cho tài khoản chỉ có role này.
- Backend có phân công giám thị do HOST quản lý, mở phiên giám sát bằng STOMP, FORCE_SUBMIT, ghi vi phạm, đóng phiên giám sát và security audit.
- Backend chưa có API cho Proctor lấy các buổi thi được phân công và roster thí sinh/attempt/heartbeat.
- Attempt có CREATED / IN_PROGRESS / SUBMITTED. LEAD_PROCTOR và ASSISTANT_PROCTOR hiện có cùng quyền thao tác, chỉ khác metadata phân công.
- Security audit kết hợp vi phạm thủ công và sự kiện lockdown; không phải nhật ký đầy đủ mọi thao tác của giám thị.

## Decision

Thiết kế bảng giám sát trong workspace riêng: **Buổi thi được phân công → Phòng giám sát → Nhật ký sự kiện**; giữ Hồ sơ hiện có. Dùng snapshot REST có phân trang và cập nhật nền, STOMP cho các thao tác hiện có. UI chỉ xác nhận nộp bài khi trạng thái thực từ backend là SUBMITTED.

Các endpoint mới trong spec là đề xuất, không phải API đã tồn tại. Không dùng prefix cũ `/api/v1/proctor/...`, vốn bị contract test của api-client cấm.

## Open Questions

Không có câu hỏi nghiệp vụ chặn bước lập kế hoạch. Các lựa chọn kỹ thuật sau thuộc trách nhiệm bước plan: cấu trúc DTO cuối cùng, thư viện STOMP phù hợp dependency hiện tại, truy vấn batch qua facade, cơ chế thu hồi subscription và fixture kiểm thử. Các hành vi bắt buộc đã ghi trong spec.

## Risks

1. **Phạm vi truy cập realtime:** hiện CONNECT mới kiểm tra JWT; cần bảo vệ SUBSCRIBE, session ownership, assignment và attempt thuộc đúng buổi thi trước khi bật giao diện.
2. **Thành công giả:** command broadcast hiện không chứng minh attempt đã được submit; phải kiểm tra snapshot thực, không tự đổi trạng thái thành công.
3. **Nhầm hợp đồng dữ liệu:** scaffold đang dùng enum/DTO không khớp backend; thay bằng contract thật và giữ module boundaries, không gọi API HOST từ Proctor.

## Handoff

- Living spec: `../proctor-tenant-workspace/spec.md`.
- Prototype minh họa: `../proctor-tenant-workspace/proctor-workspace.html`.
- Sau khi duyệt thiết kế: `$ck:plan` theo spec rồi `$ck:cook` để triển khai và kiểm thử backend/frontend.

## Design Verification

- Lượt builder review độc lập: không còn câu hỏi quan trọng chặn lập plan.
- Đã đọc lại spec/report và kiểm tra cú pháp JavaScript, uniqueness của static DOM IDs và không có network API trong prototype.
- Không có browser khả dụng trong phiên, nên chưa kiểm tra render trực quan hoặc thao tác trong browser. Cần kiểm tra responsive/dialog/focus trong bước triển khai.
- Chỉ thêm design artifacts ở pte-doc; chưa thay đổi product source tại pte-api/pte-web và chưa chạy test sản phẩm.
