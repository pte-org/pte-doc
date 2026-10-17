# Phase 14: Guardrail hoạt động tenant & eligibility identity

Owner: **Quang**
Status: **In progress**
Depends on: **Phase 13**
Maps to: [ADR-006](../../architecture/ADR-006-commercialization-and-exam-templates.md) §4, §9 · [ADR-007](../../architecture/ADR-007-student-identity-and-login.md)

Preflight: Confirmed the existing tenant-active guard is already used by session creation/open and manual enrollment, while canonical orchestration, attempt-start, schedule/policy/subscription patch, explicit-student audience resolution, and proctor assignment still have bypasses. Existing constructor overloads and module facades remain compatibility boundaries; batch identity eligibility must be resolved without N+1 repository calls.

## Requirements

Phase 13 đã mô tả đúng boundary kinh doanh: tenant bị đình chỉ không tạo hoạt động mới, nhưng attempt đang chạy vẫn phải hoàn tất và report đã publish vẫn phải đọc được. Source hiện tại chưa khép boundary này ở canonical draft/orchestration flow và ở nhánh tạo attempt mới.

Phase này cũng phải biến điều kiện “đúng người, đúng tenant, đúng vai trò, còn active” thành một contract dùng chung cho enrollment, audience, class membership và proctor assignment.

## Design Constraints

- Dùng một operation policy có tên rõ ràng, không rải các điều kiện `tenant.status` tùy tiện trong controller. Mọi command boundary phải map về cùng machine code/HTTP semantics cho tenant bị đình chỉ (`403`, không lộ resource ngoài tenant).
- **New attempt** và **resume attempt** là hai nghiệp vụ khác nhau. Guard phải chặn việc tạo/pin attempt mới; không được đặt guard ở một service dùng chung khiến heartbeat, submit, close hoặc đọc report của attempt `IN_PROGRESS` bị chặn.
- Các thao tác state-changing để chuẩn bị hoặc phát hành kỳ thi phải bị chặn khi tenant đình chỉ, kể cả khi chúng đi qua `ExamOrchestrationService` thay vì `SessionLifecycleService`.
- Một audience member chỉ hợp lệ nếu identity tồn tại trong tenant của session, có role `STUDENT`, `deleted = false` và `status = ACTIVE`. Proctor assignment dùng cùng nguyên tắc với role `PROCTOR`.
- Không retroactively xoá enrollment/attempt chỉ vì identity bị đổi trạng thái sau đó. Rule về attempt đang chạy của Phase 13 vẫn giữ nguyên; thay đổi identity sau này phải được ghi nhận ở boundary khởi tạo nghiệp vụ mới.

### Operation matrix đề xuất

| Khi tenant `SUSPENDED` | Hành vi |
|---|---|
| Tạo attempt mới, kể cả request retry/idempotent chưa có attempt hiện hữu | **Block 403** |
| Resume attempt `IN_PROGRESS`, heartbeat, save answer, submit, close | **Allow** |
| Đọc report đã publish và dữ liệu cần để giải trình | **Allow** |
| Tạo/sửa draft, thêm/xoá audience source, rebuild audience có ghi persistence, preflight có side effect, generate, publish | **Block 403** |
| Tạo/mở kỳ thi, enroll/import, tạo order, redeem license | **Block 403** |
| Sửa schedule/policy/subscription hoặc assign proctor cho hoạt động mới | **Block 403** theo mặc định; nếu cho phép cleanup phải có decision gate riêng |
| Cancel/archive/unassign resource đã tồn tại | Chỉ **Allow** nếu chứng minh không tạo quyền thi, enrollment hoặc chi phí mới; phải chốt trong decision gate |

Read-only inspection và suspension-impact là control-plane read, không được biến thành write ngầm dưới tên `preview`.

## Steps

1. Ghi operation matrix thành policy contract và catalog lỗi dùng chung. Xác định operation nào là `forward-moving`, operation nào là cleanup, cùng response/translation key cho `TENANT_SUSPENDED`.

2. Gắn policy vào các đường canonical hiện đang bỏ qua guard: `ExamOrchestrationService.createDraft/updateDraft/addSource/removeSource/preflight/generate/publish`, các patch schedule/policy/subscription, và proctor assignment nếu operation đó vẫn làm thay đổi hoạt động mới.

3. Sửa attempt start flow theo boundary nghiệp vụ: kiểm tenant active ngay trước nhánh tạo attempt mới; nhánh tìm thấy attempt đang chạy phải đi tiếp theo contract resume. Test cả request đầu tiên, retry cùng idempotency key và resume sau khi tenant bị đình chỉ.

4. Tạo identity eligibility facade có các hàm tương đương `requireActiveStudentInTenant` và `requireActiveProctorInTenant`. Dùng facade tại:

   - `EnrollmentService.enrollStudent/bulkEnroll/assignProctor`;
   - `ClassService` khi thêm member;
   - `EnrollmentModuleService` khi mở rộng class/program thành audience;
   - `ExamOrchestrationService` khi resolve explicit `STUDENT` source;
   - các notification recipient query nếu đang chọn account đã deleted/suspended.

5. Chuẩn hoá lỗi cho cross-tenant, sai role, deleted và suspended user. Với bulk audience, loại member không hợp lệ theo reason có thể giải thích được; với command một người, trả lỗi rõ ràng nhưng không tiết lộ dữ liệu tenant khác.

6. Bổ sung contract tests cho ma trận operation và identity cases. Test phải chứng minh đường cũ đã có guard không bị duplicate side effect, không tạo order/enrollment/audience member trước khi trả `403`.

## Success Criteria

- Tenant bị đình chỉ không thể tạo attempt mới qua bất kỳ entry point nào, nhưng attempt `IN_PROGRESS` vẫn heartbeat, submit và close được.
- Draft/orchestration flow không còn bypass suspension policy; publish không thể tiến hành khi policy nói phải block.
- Student/proctor sai tenant, sai role, deleted hoặc không active không thể được enroll/assign; audience expansion không tạo member hợp lệ giả.
- Mọi response bị chặn dùng một machine code ổn định và không làm lộ resource ngoài tenant.
- Operation matrix được link từ phase master và có owner cho các dòng còn cần quyết định.

## Files

- `D:/GitHub/pte-org/pte-api/app/src/main/java/com/pte/tenancy/TenancyService.java`
- `D:/GitHub/pte-org/pte-api/app/src/main/java/com/pte/identity/IdentityService.java`
- `D:/GitHub/pte-org/pte-api/app/src/main/java/com/pte/identity/internal/constant/IdentityConstants.java`
- `D:/GitHub/pte-org/pte-api/app/src/main/java/com/pte/identity/internal/repository/UserRepository.java`
- `D:/GitHub/pte-org/pte-api/app/src/main/java/com/pte/enrollment/EnrollmentModuleService.java`
- `D:/GitHub/pte-org/pte-api/app/src/main/java/com/pte/enrollment/internal/service/ClassService.java`
- `D:/GitHub/pte-org/pte-api/app/src/main/java/com/pte/session/internal/service/EnrollmentService.java`
- `D:/GitHub/pte-org/pte-api/app/src/main/java/com/pte/session/internal/service/EntitlementService.java`
- `D:/GitHub/pte-org/pte-api/app/src/main/java/com/pte/session/internal/service/SessionOperationGuardService.java`
- `D:/GitHub/pte-org/pte-api/app/src/main/java/com/pte/session/internal/service/SessionLifecycleService.java`
- `D:/GitHub/pte-org/pte-api/app/src/main/java/com/pte/session/SessionService.java`
- `D:/GitHub/pte-org/pte-api/app/src/main/java/com/pte/session/internal/service/ExamOrchestrationService.java`
- `D:/GitHub/pte-org/pte-api/app/src/main/java/com/pte/session/internal/service/SessionClassAssignmentService.java`
- `D:/GitHub/pte-org/pte-api/app/src/main/java/com/pte/session/internal/service/lifecycle/SessionScheduleService.java`
- `D:/GitHub/pte-org/pte-api/app/src/main/java/com/pte/session/internal/service/lifecycle/SessionPolicyService.java`
- `D:/GitHub/pte-org/pte-api/app/src/main/java/com/pte/session/internal/service/lifecycle/SessionSubscriptionService.java`
- `D:/GitHub/pte-org/pte-api/app/src/main/java/com/pte/attempt/internal/service/AttemptLifecycleService.java`
- `D:/GitHub/pte-org/pte-api/app/src/main/java/com/pte/notification/internal/listener/StudentEnrollmentConflictNotificationListener.java`
- `D:/GitHub/pte-org/pte-api/app/src/main/java/com/pte/notification/internal/listener/ViolationNotificationListener.java`
- `D:/GitHub/pte-org/pte-api/app/src/test/java/com/pte/identity/IdentityServiceTest.java`
- `D:/GitHub/pte-org/pte-api/app/src/test/java/com/pte/enrollment/EnrollmentModuleServiceTest.java`
- `D:/GitHub/pte-org/pte-api/app/src/test/java/com/pte/enrollment/internal/service/ClassServiceTest.java`
- `D:/GitHub/pte-org/pte-api/app/src/test/java/com/pte/session/internal/service/EnrollmentServiceTest.java`
- `D:/GitHub/pte-org/pte-api/app/src/test/java/com/pte/session/internal/service/ExamOrchestrationServiceTest.java`
- `D:/GitHub/pte-org/pte-api/app/src/test/java/com/pte/session/internal/service/lifecycle/SessionScheduleServiceTest.java`
- `D:/GitHub/pte-org/pte-api/app/src/test/java/com/pte/session/internal/service/SessionLifecycleServiceTest.java`
- `D:/GitHub/pte-org/pte-api/app/src/test/java/com/pte/attempt/internal/service/AttemptLifecycleServiceTest.java`

## Quality and Testing State

- Decision checkpoint: unit tests = yes; quality gate = yes (`ck:cook --hard`). Completion confirmation after these checks is still pending.
- Quality gate: **APPROVED** — no blocking findings; report: `quality/phase-14-tenant-activity-and-identity-guardrails-quality-report.json`; receipt: `quality/phase-14-tenant-activity-and-identity-guardrails-receipt.json`.
- Testing: **PASSED** — focused Phase 14 API suite `151/151` plus HTTP suspension and notification regression `16/16`; report: `tests/phase-14-tenant-activity-and-identity-guardrails-test-report.json`.

## Session Notes

- Added one forward-moving tenant activity guard path while keeping the attempt resume path tenant-activity-neutral for `IN_PROGRESS` attempts.
- Applied active identity eligibility to enrollment, class/program audience expansion, explicit student sources, proctor assignment, and notification recipient fan-out; preview audience computation is now read-only.
- Build gate `mvn -pl app -DskipTests compile`, focused tests, HTTP contract tests, notification regressions, and `git diff --check` passed.
- Phase completion is intentionally held at the hard checkpoint until Quang confirms the evidence; no push/deploy was performed.

## Decision Record and Remaining Gate

- Tenant `SUSPENDED` vẫn được login/refresh để đọc report và tiếp tục attempt đang chạy; các command forward-moving vẫn bị block.
- Cancel/archive/unassign resource đang tồn tại chỉ được mở nếu chứng minh là cleanup thuần tuý, không tạo quyền thi/enrollment/chi phí mới; nếu không, giữ block và xử lý qua support/admin path riêng.
- User `SUSPENDED` sau khi đã enroll vẫn theo rule attempt đang chạy của Phase 13; identity suspension trở thành security revoke riêng chỉ khi có policy/command riêng được phê duyệt.
