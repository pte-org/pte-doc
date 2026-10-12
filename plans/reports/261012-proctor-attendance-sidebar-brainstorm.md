# Brainstorm: Sidebar chức năng và điểm danh Proctor

Date: 2026-10-12. No implementation code written.

## User direction

Overview hiện tại được chấp nhận. Các chức năng tiếp tục truy cập qua thẻ và phải có mục tương ứng ở sidebar trái theo role. Người dùng yêu cầu xây điểm danh theo backend hiện hữu; đã chọn điểm danh chỉ ghi nhận/cảnh báo, không chặn bắt đầu thi, và sau CLOSED chỉ Host sửa với lý do/audit.

## Ideas explored

- Thay sidebar bằng các thẻ: rejected; user requires both entry points.
- Sidebar dùng route/filter hiện có, thêm trang chọn ca cho điểm danh/nhật ký: preferred; giảm trùng UI và không hard-code session ID.
- Tự điểm danh từ attempt/heartbeat: rejected as attendance authority. Những tín hiệu này chỉ hỗ trợ quan sát.
- Attendance theo từng attempt: rejected; một sinh viên có thể nhiều lượt thi trong cùng ca.
- Manual attendance per session/student with audit: preferred; gắn với roster enrollment và quyền phân công.
- Gate bắt đầu thi theo attendance: explicitly excluded by user for MVP.

## Backend evidence

Enrollment đã có session/student/tenant với unique(session_id,student_public_id), chưa có attendance fields. MonitoringQueryService đọc enrollment phân trang, Identity display names và latest attempts theo batch. ProctorAccessPolicy và SessionService có assigned-session/Host-tenant checks. Sidebar Proctor chưa có entry nhật ký tổng, Examiner chỉ có queue entry; audit deep links hiện cần session UUID.

## Validated decisions

1. Attendance independent of login/attempt/heartbeat; no change to start/finalize/scoring/publication.
2. Closed session: Proctor reads only; Host corrects with reason and append-only audit.
3. Cards and sidebar resolve to the same function; state-sensitive role filtering, no Host permission expansion.
4. Proctor attendance editing begins exactly30minutes before opensAt; before that it is read-only.
5. Initial absence reason optional. Reset to UNMARKED is allowed during editing with mandatory reason and history.

## Proposed bounded MVP

Three statuses UNMARKED/PRESENT/ABSENT; roster search/page/filter, immediate per-student writes, full-roster summary, conflict handling, authoritative refresh, Host correction tab. No auto-absence or bulk marking every unmarked student absent. No biometrics/QR/offline replay.

## Risks

- Physical attendance and system activity disagree: warn visibly without changing either state automatically.
- Concurrent proctors/session close/revocation: revalidate scope and lifecycle inside transaction; detect stale row versions.
- Enrollment removal: keep audit independently of current enrollment deletion; exclude removed enrollment from current roster/summary.

## Handoff

Spec: plans/proctor-attendance-sidebar/spec.md. Architecture and exact persistence/locking/request-replay strategy belong to ck:plan; no deployment or implementation performed here.
