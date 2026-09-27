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

- [ ] Host tạo, cấu hình, mở và đóng session qua app. **(logic port xong, path/
      contract giữ nguyên; chưa gọi qua HTTP thật, chưa có Postgres)**
- [x] Composition lấy từ assessment summary, không có snapshot ref cache
      (`CompositionService` gọi `AssessmentService.getSummary` mỗi lần, không có
      bảng `SnapshotRef`/`SnapshotRefItem`).
- [x] Attempt có thể nhận entitlement qua public API (`SessionService.checkEntitlement`
      sẵn sàng; chưa có consumer thật — Phase 07).
- [x] Bulk enrollment không vượt capacity dưới race (pessimistic write lock giữ
      suốt check-then-insert, kiểm chứng bằng unit test 2 lời gọi tuần tự).
- [x] Proctoring có thể kiểm tra assignment mà không dùng HTTP client
      (`SessionService.checkProctorAssignment` sẵn sàng; chưa có consumer thật —
      Phase 09).
- [ ] `V8__session.sql` chạy được trên Postgres monolith. **(chưa chạy thật —
      không có Postgres daemon trong phiên này)**
- [x] Test scheduling nguồn và test app xanh (services/scheduling giữ nguyên,
      không đổi; `app` 209/209).
- [x] `ApplicationModules.verify()` pass (thêm `@NamedInterface` cho
      `assessment.dto.response` và `session.dto.response`).

---

## Quality and Testing State

**Testing: passed.** 28 test mới (`SessionLifecycleServiceTest` 8 — ported từ
`SessionServiceLockdownTest`, `EnrollmentServiceTest` 12 — ported, bỏ phần verify
outbox, `EntitlementServiceTest` 6 mới, `CompositionServiceTest` 2 mới). Full
`mvn -pl app test`: 209/209 xanh. `ApplicationModules.verify()` pass.
Report: [phase-06-session-test-report.json](tests/phase-06-session-test-report.json).

**Quality gate: APPROVED** (0 blocker/high/medium/low/noted sau khi sửa 1 finding
HIGH — thiếu `@NamedInterface` cho `session.dto.response`, cùng mẫu với
itembank/assessment). Report: [phase-06-session-quality-report.json](quality/phase-06-session-quality-report.json).

Receipt cơ học **chưa phát hành được** — cùng giới hạn đa-repo đã ghi ở Phase A
(`pte-doc` và `pte-api` là hai Git repo tách biệt trong môi trường này).

Deviation: `HostCommandService` (`requestScoring`/`requestPublish`) và 2 endpoint
`/score`, `/publish` trên `SessionController` **chưa port** — trong source chỉ phát
outbox event cho `scoring`/`reporting`, hai module chưa tồn tại. Sẽ port khi làm
Phase 08 và Phase 10. `SnapshotFetchFailedException` và `EmptyCompositionException`
(dead code, không nơi nào throw trong source) không port.
