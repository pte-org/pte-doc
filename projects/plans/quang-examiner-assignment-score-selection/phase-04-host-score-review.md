# Phase 04 — Host review và chọn score source

**Plan:** [plan.md](plan.md) · **Spec:** [spec.md](spec.md)  
**Covers:** P1 Host review/source selection; FR-11–15, FR-18 (review/selection portion).  
**Depends on:** Phase 01–03.  
**Outcome:** Host xem đủ AI/Examiner scores, trạng thái phân công/chấm, preview và áp dụng nguồn cho đúng answer set, với audit.

## Mục tiêu

Mở rộng per-session Host review hiện tại mà không làm mất `teacherScore` legacy. Host có thể đối chiếu AI và Examiner, chọn source theo toàn bộ eligible answers, section hoặc task type. Narrower action chạy sau chỉ override đúng answers khớp.

## Backend/API work

1. **Session review query**
   - Mở rộng query/facade trả answer, task type/section, pinned scoring method, AI score + provenance/availability, Examiner score + submit status, assignment/examiner summary, selected source và publish lock status.
   - Host-only; giữ tenant-scoped 404/no-existence-leak semantics hiện hành.
   - `teacherScore` legacy được thể hiện có nhãn/ý nghĩa riêng, không tự đồng nhất với Examiner score. Spec publish source chỉ AI/Examiner; host-entered legacy score không được âm thầm đưa vào selected source.

2. **Source selection preview/apply**
   - API nhận scope `ALL`, `SECTION`, hoặc `TASK_TYPE`, selector tương ứng, source AI/EXAMINER và expected review version.
   - Preview trả match count, score-available count, missing/unavailable count, current-source breakdown và conflict/version status.
   - Apply xác thực source availability cho từng answer; stub/legacy AI bị từ chối. Chưa có Examiner score cũng không cho apply source đó lên answer thiếu score.
   - Apply cập nhật current selection trên answer set đang tồn tại và tạo audit có actor/time/selector/count/previous-new source. Scope hẹp không xóa score gốc hay thay câu ngoài scope.
   - Batch apply nguyên tử: nếu conflict/version stale thì không áp dụng một phần; thao tác retry có request key/version để chống duplicate audit/mutation.

3. **Readiness UX và status**
   - Host nhìn thấy assignment coverage, unassigned attempt, pending Examiner scores, missing/invalid selected score, AI stub status và published/locked state.
   - Host review có thể bắt đầu trước khi Examiner hoàn tất; chọn source không đồng nghĩa với approval/publish.
   - Chưa publish trong phase này; không thêm nút giả hoặc gọi Reporting trước readiness gate Phase 05.

4. **Host web UI**
   - Bổ sung review/source panel trong session detail/AnswersSection hiện có.
   - Render hai cột score độc lập, selected source, eligibility/provenance status, examiner/status.
   - Cho chọn ALL/section/task type; trước apply mở preview confirmation với impacted/missing counts.
   - Khi thao tác rộng rồi hẹp, reload server state xác nhận đúng subset. Disable mutations khi session report đã publish/lock; Host chỉ đọc lịch sử.

## Kiểm chứng và acceptance

- Test source apply với ALL, từng section, task type; thao tác hẹp sau rộng chỉ update intersection đúng; ngoài scope giữ nguyên.
- AI selection chấp nhận real/complete/range-valid provenance; từ chối stub, missing provenance, failed/incomplete score; Examiner source yêu cầu score đã submit.
- Preview count khớp số answer thực tế; score unavailable phân biệt rõ với zero score (0 là score hợp lệ).
- Stale version/concurrent source apply không overwrite âm thầm; atomic batch và idempotency không tạo audit trùng.
- Tenant/role authorization và Host-vs-Examiner contract regression; published source không editable.
- UI tests xác nhận source action, preview, missing score, empty state, audit/locked state; không lộ host-only data sang Examiner DTO.

**Acceptance:** Host có thể ra quyết định nguồn cho mọi answer eligible và thấy rõ answer chưa sẵn sàng; publication vẫn bị khóa cho đến Phase 05.

## Design Constraints

- Source được lưu per-answer; commands ALL/SECTION/TASK_TYPE là bulk mutation trên current matching set, không phải rule cho câu tương lai.
- Chỉ source publishable mới được apply; không biến “selected” thành mặc định hợp lệ nếu score thiếu.
- Mọi nguồn gốc (raw AI, Examiner, legacy Host teacher score) vẫn được giữ riêng; source selection audit append-only.
- Host-only API; toàn bộ mutation tenant-scoped, versioned/atomic và bị chặn sau publication lock.
- Approval/publication logic thuộc Reporting/Phase 05, không sao chép readiness logic ở FE.

## Quality and Testing State

- quality: not evaluated
- testing: not started
- Kế hoạch: scoring service/controller tests; transaction/version tests; Host review component tests và role-isolation regression.
