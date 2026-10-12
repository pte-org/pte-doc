# Spec: Tenant Exam Staff workspace

Ngày: 2026-10-10. Status: Product decisions confirmed; contract kỹ thuật chốt ở Phase 01 trước implementation.
Scope: `pte-api`, `pte-web`, `pte-doc`; không implementation mới trong lượt lập plan.

## Phase 01 technical refinement

Implementation contract: [contract.md](contract.md). Các route/filter và semantics kỹ thuật trong contract này supersede tên tham số đề xuất ban đầu dưới đây sau quality gate. Model ca thi hiện chỉ có sessionPublicId, không có examPublicId độc lập; selector ca/kỳ thi dùng sessionPublicId, không giả exam ID hoặc silently map sang template ID. Đây không phải thay đổi sang chấm bài hoặc sửa phân công.

## Stories và độ ưu tiên

| Story | Priority | Yêu cầu và acceptance |
| --- | --- | --- |
| US-01 | P1 | Host mở staff từ danh sách qua client router cùng tab; URL có thể load trực tiếp; breadcrumb Exam Staff > tên, không Home/back link thừa |
| US-02 | P1 | Host thấy Overview đầu tiên; query theo role, không lấy role đầu tiên trong array; target suspended vẫn đọc được |
| US-03 | P1 | Proctor có count ca và lịch filter API theo ngày/exam/session/status, có page/size và stable sort |
| US-04 | P1 | Examiner có một record/card mỗi ca được phân công, progress server-derived, xem được ca published, không command chấm điểm |
| US-05 | P1 | Account dùng common DescriptionList; xem trước, edit inline theo whitelist được duyệt; username/role read-only |
| US-06 | P1 | Header và lifecycle/credential actions dùng common; giữ confirmation và flow credential staff gửi email |
| US-07 | P1 | Learner và staff dùng presentation chung; field/query/domain riêng; không override visual defaults |
| US-08 | P2 | Examiner chuyển board/table; board có page độc lập từng cột và counts toàn filter, không suy count từ một page |
| US-09 | P2 | Route/query có loading, retry, empty, error; hidden tab không tự gọi work API; dữ liệu cũ không bị giả thành empty |

## Quyền

Tất cả API mới: HOST_ADMIN và tenant hiện tại. Account target nondeleted, có PROCTOR hoặc EXAMINER; cho phép suspended target.
Student/nonstaff, target tenant khác, session tenant khác và ID không tồn tại không tiết lộ dữ liệu; dùng error contract sẵn có.
Không dùng /me, queue cá nhân hay token nhân sự. Link chỉ đi Host-owned session route.
Suspension/credentials áp dụng cho toàn tài khoản, kể cả dual-role.

## UI contract

Header dùng Avatar/PageHeader/StatusBadge/default ActionMenu ellipsis; metadata là email và role badges, không student code/class/program.
Tabs: Overview, Lịch coi thi nếu PROCTOR, Theo dõi chấm bài nếu EXAMINER, Tài khoản.
Account: fullName/email/phone/dateOfBirth editable theo whitelist đã xác nhận; username/roles/status chỉ đọc trong form. Status thay qua action riêng.
Layout editing giữ vị trí field, nút Save/Cancel dùng common; lỗi validation/server qua constants+i18n.
Không override font, size, trigger, màu, padding mặc định của common để bắt chước ảnh.
Giữ light/dark hiện có; không đổi global tokens/typography.

## Proctor semantics

Unit chính = distinct ca được phân công. Distinct kỳ thi chỉ là số phụ.
Overview phải phân biệt upcoming/ongoing/ended từ lifecycle thực và schedule; canceled/unscheduled tách riêng nếu model có, không ép vào ended.
Lifecycle hiện có: DRAFT, PREPARING, READY, SCHEDULED, OPEN, CLOSED, CANCELLED. CLOSED không chứng minh attendance; SCHEDULED quá giờ không tự đổi thành CLOSED/đã coi. Phase 01 chốt riêng cách hiển thị preparation và stale schedule, không sửa lifecycle chỉ để phục vụ thống kê.
Không gọi ended assignment là đã coi/đã tham dự. Historical completeness giới hạn ở assignment còn tồn tại.
Query lọc theo overlap schedule với khoảng [fromInclusive, toExclusive) UTC, chuyển từ múi giờ hiển thị; khoảng ngày đến bao gồm cả ngày được chọn.
Ca không có đủ schedule: hiển thị chưa có lịch; chính sách loại khỏi date-filter phải thống nhất phase 01.
Filter options session/exam lấy từ API tenant-scoped, không suy từ một page kết quả.

## Examiner semantics

Record identity: (tenantId, examinerPublicId, sessionPublicId). Chỉ committed assignment; supplemental batches gộp cùng ca.
Trả assignedAttemptCount, eligibleAnswerCount, submittedAnswerCount, pending/inProgress/completedAttemptCount, batchCount.
Eligible count lấy snapshot assignment; submission count chỉ ExaminerAnswerScore hợp lệ đúng assignment/examiner/tenant, không AI/teacher.
Phase 01 phải chỉ rõ nguồn eligibility snapshot/pinned template và eligible answer identities, predicate đã nộp, soft-delete và deduplication key (answerPublicId trong attempt được phân công). Không chỉ đếm score rows: unrelated answers/duplicate rows không được numerically làm ca trông completed. Không tính lại eligibility từ template hiện hành thay cho snapshot được pin.
Attempt: zero eligible => COMPLETED (ghi rõ không có câu cần chấm); positive eligible & zero submitted => PENDING; một phần => IN_PROGRESS; đủ => COMPLETED.
Ca: tất cả attempt completed => COMPLETED; tất cả pending => PENDING; còn lại => IN_PROGRESS. Không có assignment => không tạo card.
Không có snapshot/dữ liệu hợp lệ => unavailable; không giả zero hoặc complete. Nếu submitted vượt eligible, đánh dấu inconsistency và không render progress >100%.
Record unavailable/inconsistent nằm trong danh sách ngoại lệ read-only có count riêng; không ép vào ba cột hoặc bỏ mất khỏi tổng. API trả totalSessions = số ca hợp lệ trong ba status + unavailableSessionCount; table có thể xem record ngoại lệ. Không tạo workflow state/mutation mới.
Contract paging đề xuất: API hỗ trợ workStatus=UNAVAILABLE như query bucket kỹ thuật read-only cho danh sách ngoại lệ, có page/size/total riêng; không thêm persisted workflow enum. Khi ALL, table gồm cả record ngoại lệ; totals/counts và overview dùng cùng base predicate. Hình dạng DTO/query name cuối cùng phải đóng băng phase 01.
Work status tách session lifecycle/publication. Không loại ca đã publish; không tự tạo deadline/overdue.
Board counts tính toàn filtered dataset trước paging, cùng predicate với table. Mỗi cột paging riêng; workStatus selector chỉ hiện cột được chọn.
Session summary không tiết lộ câu trả lời/điểm chi tiết học viên.

## Contract đề xuất

| Endpoint mới | Owner |
| --- | --- |
| GET /api/v1/exam-staff/{id} | examstaff composition qua Identity public facade |
| GET /api/v1/exam-staff/{id}/overview | composition qua Session/Scoring |
| GET /api/v1/exam-staff/{id}/proctor-sessions | Session-owned scoped query |
| GET /api/v1/exam-staff/{id}/examiner-sessions | Scoring-owned scoped query |
| PATCH /api/v1/users/{id}/exam-staff-profile | Identity-owned whitelist; route cuối cùng chốt phase 01 |

API filters đề xuất: from/to UTC bounds, examPublicId/sessionPublicId, sessionStatus cho Proctor; workStatus/publicationStatus cho Examiner; page/size.
Examiner date range V1 dùng overlap lịch ca opensAt/closesAt như Proctor, không phải assignedAt/submittedAt. Overview, board, table và totals dùng cùng interval predicate; ca thiếu schedule vẫn xem trong ALL không date-filter, không tự dùng assignedAt làm fallback. Phase 01 ghi rõ predicate đã chọn và tests boundary trước implementation.
Query params/timezone names cuối cùng chốt phase 01 theo convention source. Max page size, deterministic tie-breaker và response total/counts bắt buộc.
GET không viết/expire/tạo report; composition không gọi repository internal module khác.
