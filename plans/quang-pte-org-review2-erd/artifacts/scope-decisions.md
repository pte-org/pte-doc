# Quyết định phạm vi ERD

## Core

Overview gồm 11 khái niệm: Organization, User, Subscription, Question, ScoreTemplate, ExamSession, ExamSnapshot, ExamAttempt, AttemptAnswer, ScoringAnswer, AttemptReport. Đây là mô hình nghiệp vụ giản lược, không phải schema đầy đủ.

Organization trong overview ánh xạ tenants + organizations. Giữ hai entity riêng trong trang identity; mỗi Organization có đúng một Tenant, một Tenant có tối đa một Organization theo unique index V33. DB cho phép Tenant chưa có Organization. Không suy luận nhiều chi nhánh từ @ManyToOne.

User gồm các actor theo roles, Student là User có role STUDENT. user_roles là collection table; không dựng thêm thực thể Student/Host/Role như bảng độc lập.

Question -> ExamSnapshot ở overview là provenance qua snapshot_items.source_question_public_id; ScoreTemplate -> ExamSession và ExamSnapshot -> ExamSession là quan hệ tham chiếu nội dung. Không dùng chúng để mô tả bước xử lý theo thời gian.

## Detail

10 trang logical theo manifest, bổ sung practice/rubric vì có source hiện tại. Mỗi trang tối đa 12 entity. Entity lặp lại giữa các trang là anchor cùng ID, không là bảng mới.

Giữ ClassMembership, LecturerAssignment, Enrollment, FormAssignment, ExaminerAttemptAssignment, ExaminerGradingWork, ExamSessionIncidentHistory và PracticeSessionAttemptLink vì có dữ liệu quan hệ, provenance hoặc lịch sử riêng. Không gộp những entity này thành một bảng chung.

## Các thành phần kỹ thuật

Theo yêu cầu bổ sung ngày 2026-10-24, 31 bảng auth hashes/tokens/challenges, heartbeat/security log, technical receipts, job/outbox, runtime profile/contract/publication usage, notification/inbox, audit và support đã được vẽ thành 7 trang trong [bộ field thiết yếu](../mermaid-essential-fields/README.md). Các bảng nghiệp vụ xuất hiện lại làm anchor; không tính thêm vào 31 bảng kỹ thuật. Không gọi các bảng này dư thừa hay đề nghị xóa code.

MediaObject là asset quản lý riêng. Media refs và JSON snapshots được giải thích trong mapping, không vẽ thành một entity mới cho từng trường. Audit aggregate_type/id và audience source_type/id có tính đa hình; không nối đại tới tất cả bảng.

Quyết định core/detail/technical áp dụng vào từng inventory item trong disposition.json. Tổng 62 bảng nghiệp vụ và 31 bảng kỹ thuật bao phủ 93 bảng hiện có trong source. Chưa xác minh relation thì không đưa vào baseline. Bộ sơ đồ không claim live DB consistency.
