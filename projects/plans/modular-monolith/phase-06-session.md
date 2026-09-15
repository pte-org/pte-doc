# Phase 06 — Session

**Plan:** [plan.md](plan.md) · [kế hoạch tổng hợp](remaining-modules-refactor-plan.md) · **Spec:** [spec.md](spec.md)
**Covers:** Session lifecycle, composition, exam enrollment, proctor assignment
**Nguồn:** `services/scheduling` (89 file)
**Đích:** `com.pte.session`

---

## Mục tiêu

Đưa scheduling vào module `session`, đồng thời bỏ snapshot cache trung gian. Session
phải dùng assessment canonical để kiểm tra đề, và expose entitlement cho attempt
qua public in-process API.

---

## Design Constraints

- Dependency: `session → assessment`, `session → enrollment`, tất cả qua public API.
- Phân biệt `session.Enrollment` (học viên của ca thi) với
  `enrollment.ClassMembership` (học viên của lớp); không gộp aggregate.
- Mọi session/enrollment/assignment query phải scope tenant khi use case có caller.
- Giữ pessimistic lock cho open, patch policy và bulk capacity.
- Giữ unique constraint cho enrollment theo session/student và assignment theo
  session/proctor; xử lý race như service nguồn.
- Session chỉ được dùng snapshot đã tồn tại; composition chỉ chọn task type có trong
  snapshot.
- Không tạo `snapshot_refs` hoặc `snapshot_ref_items` trong monolith.
- Không port `SessionScheduledEvent`, outbox, relay, processed event hoặc cache
  consumer; enrollment notification sẽ dùng application event ở Phase 09.
- Không gọi bảng/repository trực tiếp của assessment, enrollment hoặc identity.

---

## Việc cần làm

1. **Port aggregate**
   - Port `ExamSession`, `SessionComposition`, `ExamPolicy`, exam-session
     `Enrollment`, `ProctorAssignment` và enum.
   - Giữ policy mặc định theo `PRACTICE`, `MOCK_TEST`, `REAL_TEST`, lockdown,
     replay, device check, proctor và answer integrity.
   - Giữ backfill legacy defaults nếu entity nguồn cần `@PostLoad`.

2. **Port session lifecycle**
   - Port create/list/get/open/close và patch policy.
   - Giữ validation cửa sổ `opensAt < closesAt`, host context và policy lock sau
     khi session không còn `SCHEDULED`.
   - Giữ mapper/response contract và role guard.

3. **Thay SnapshotRefService**
   - Khi create, gọi `AssessmentService.getSummary(snapshotPublicId)`.
   - Khi set composition, validate task type từ summary canonical.
   - Xóa local `SnapshotRef`/item khỏi app; không dựng bản sao metadata.

4. **Port entitlement và roster ca thi**
   - Tạo public query tương đương `checkEntitlement`: session OPEN, student đã
     enroll, đúng tenant, trả snapshot ID, policy và composition.
   - Tạo public query tương đương `checkProctorAssignment` cho proctoring.
   - Enroll/bulk-enroll phải giữ capacity lock, duplicate handling và tenant scope.

5. **Flyway**
   - Viết `V8__session.sql` cho các bảng session, composition, exam enrollment,
     proctor assignment và policy columns/embeddable.
   - Không tạo snapshot ref hoặc synchronization table.

6. **Chuẩn bị Phase 07**
   - Chốt DTO entitlement/composition ổn định.
   - Chốt public method để attempt gọi một lần khi start và không gọi lại sau khi pin.

---

## Tests to Write First

- Create với snapshot không tồn tại/không accessible.
- Invalid session window, default policy, policy patch và lock sau open.
- Composition từ chối task type không có trong assessment snapshot.
- Entitlement yêu cầu session OPEN + enrollment đúng student + tenant.
- Bulk capacity dưới concurrent request; duplicate enroll/assignment.
- Cross-tenant session, enrollment và proctor assignment không lộ dữ liệu.
- Proctor assignment check success/failure.
- Modulith chặn session truy cập repository nội bộ module khác.

---

## Acceptance

- [ ] Host tạo, cấu hình, mở và đóng session qua app.
- [ ] Composition lấy từ assessment summary, không có snapshot ref cache.
- [ ] Attempt có thể nhận entitlement qua public API.
- [ ] Bulk enrollment không vượt capacity dưới race.
- [ ] Proctoring có thể kiểm tra assignment mà không dùng HTTP client.
- [ ] `V8__session.sql` chạy được trên Postgres monolith.
- [ ] Test scheduling nguồn và test app xanh.
- [ ] `ApplicationModules.verify()` pass.

---

## Quality and Testing State

Chưa thực thi. Cập nhật sau khi entitlement/composition boundary ổn định để bắt đầu
Phase 07 — mốc luồng thi đầu-cuối.
