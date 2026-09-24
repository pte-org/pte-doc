# Phase 02 — Host tạo assignment theo session

**Plan:** [plan.md](plan.md) · **Spec:** [spec.md](spec.md)  
**Covers:** P1 Host manual/random assignment; FR-01–08, FR-18.  
**Depends on:** Phase 01.  
**Outcome:** Host preview, sửa conflict và xác nhận batch; allocation đã commit không bị reload/retry làm thay đổi.

## Mục tiêu

Thêm workflow Host vào session detail để chọn Class/Program và Examiner, xem trước phạm vi/khối lượng, rồi commit manual mapping hoặc pooled random assignment. Assignment áp dụng cho whole attempt và chỉ trong session hiện tại.

## Backend work

1. **Resolve scope, attempts và eligible work qua public APIs**
   - Lấy session tenant/state/class scope từ `session`; roster/membership qua `enrollment`; submitted attempts qua `attempt`; AI-eligible answers qua scoring resolver/facade.
   - Candidate pool = submitted attempt trong session ∩ các Program/Class được chọn ∩ attempt có ít nhất một answer AI-eligible.
   - Union scope và deduplicate theo attempt ID trước count/allocation; response trả attempt count và eligible-answer count.
   - Không query `SessionClassAssignmentRepository`, enrollment repository hoặc attempt/scoring internals xuyên module.

2. **Examiner validation**
   - Examiner list có tenant-scoped query qua public identity facade.
   - Preview và confirm đều xác minh mỗi Examiner tồn tại, active, cùng tenant, role EXAMINER; revalidate ngay trước commit.
   - API chỉ nhận examiner public IDs và scope/config cần thiết; không tin tenant ID hoặc membership do client gửi.

3. **Manual mapping**
   - Host ánh xạ từng selected Program/Class tới Examiner.
   - Attempt thuộc nhiều scope được hợp nhất; nếu các scope gán attempt đó tới Examiner khác nhau, trả conflict list gồm attempt/student-safe identity và scopes gây conflict, không ghi assignment một phần.
   - Nếu các scope cùng chọn một Examiner, attempt xuất hiện đúng một lần.

4. **Random pooled mode và durable preview**
   - Gộp toàn bộ scope thành một pool; shuffle attempt cá nhân, không chia class/program thành pool riêng; chia count lệch tối đa 1.
   - Persist batch preview/snapshot hoặc token tham chiếu đến snapshot có expiry và version; confirm dùng đúng phân bổ đã preview, không random lại.
   - Preview trả tổng attempts, eligible answers, assignments per Examiner và pool version/snapshot reference.
   - Commit trong transaction với unique `(session, attempt)`, locking/version check và audit creator/time/mode/scope/count.

5. **Supplemental batch, retry và state transitions**
   - Attempt đã assigned bị loại khỏi batch bổ sung; attempt nộp sau chỉ được đưa vào supplemental preview.
   - Confirm retry idempotent: trả lại batch đã commit; không tạo assignment trùng.
   - Nếu candidate đổi status, session/scope/Examiner không còn hợp lệ hoặc attempt đã được assign giữa preview và confirm, trả conflict rõ ràng và yêu cầu Host preview lại; không âm thầm đổi phân bổ.
   - Assignment committed không sửa examiner trong UI MVP; lỗi cần xử lý ngoài hệ thống theo out-of-scope cho đến khi có transfer workflow.

## Frontend work

- Thêm section/card vào Host `SessionDetailView` (reuse page/session identifier; không thêm global reusable template).
- Form mode: manual by Program/Class mapping hoặc random pooled; chọn một/nhiều scope và active Examiners.
- Preview table hiển thị scope, attempts, eligible answer count, predicted count per Examiner, conflict/error states.
- Confirm chỉ bật khi preview hợp lệ; sau xác nhận hiển thị committed assignment summary và trạng thái batch.
- Cho phép tạo supplemental batch chỉ trên unassigned submitted attempts.
- Bảo vệ role `HOST_ADMIN`; các route hiện tại của Proctor/Examiner không mở quyền host assignment.

## Quy tắc scope overlap

- Không giả định Student đồng thời thuộc nhiều Class; `ClassMembership` hiện có unique constraint trên `student_public_id`.
- Một attempt vẫn có thể khớp nhiều scope được Host chọn, chẳng hạn scope Program và Class cùng bao phủ attempt đó. Lấy quan hệ qua Enrollment API, union candidate sets rồi deduplicate theo attempt ID.
- Test dùng overlap giữa các selected scopes hợp lệ theo schema/API hiện tại; không sửa membership constraint hay mở rộng enrollment trong phase này.
- Với manual mapping, cùng attempt khớp nhiều scope nhưng được map tới cùng Examiner thì chỉ tạo một assignment; map tới Examiner khác nhau thì trả conflict cho Host và reject toàn batch.

## Kiểm chứng và acceptance

- Unit/property test: N attempts/M examiners luôn lệch tối đa 1; 40/2 cho 20/20; 1 hoặc nhiều examiner và phần dư chia ổn định.
- Integration test: selected scope union đúng; ngoài-session/không submitted/không AI-eligible bị loại; duplicate attempt chỉ xuất hiện một lần.
- Manual conflict bị reject toàn batch và trả conflict detail; mapping đồng examiner được dedupe.
- Persisted preview confirm giữ đúng phân bổ sau refresh/retry; confirm race không tạo double assignment; supplemental không đổi assignment cũ.
- Reject Examiner sai tenant/inactive/sai role và session không thuộc Host tenant.
- Benchmark integration local 40 attempts/2 Examiners: preview + commit p95 ≤ 2 giây (không tính media/AI).
- UI test cho preview, conflict, balancing summary, confirm retry/error và supplemental flow.

**Acceptance:** Host có thể tạo hai chế độ và assignment data chính xác/idempotent; Examiner queue có thể được triển khai ở Phase 03.

## Design Constraints

- Mọi assignment là per-session, whole-attempt; unique/session+attempt và không có multi-Examiner.
- Manual mapping conflict phải fail closed và không commit assignment dở dang.
- Random shuffle pool hợp nhất rồi balance; persist preview allocation để confirm exact result.
- Audience/membership/attempts/examiner identities lấy qua module APIs; tenant scope ở server.
- Roster thay đổi sau commit không làm đổi assignment; không thay `ClassMembership` schema nếu không có quyết định riêng.

## Phase Checkpoint

- Unit/integration tests: yes (`ck:cook --hard` default)
- `ck:quality`: yes (`ck:cook --hard` default)
- Hard-mode confirmation: confirmed by the user's `ck-cook --hard` request; implementation may proceed.
- Preflight: reviewed `SessionService`, `SessionClassAssignmentService`, `EnrollmentModuleService`, `AttemptService`/`AttemptSummaryQueryService`, `ScoringService`/eligibility query, `IdentityService` and existing assignment entities/migrations. Cross-module access must remain via public facades; assignment creation will serialize on the tenant-owned session row and persist the exact preview snapshot.
- Working-tree preservation: tenant-web already has user changes in `SessionDetailView.tsx` plus class/exam operations; preserve these and patch only the minimum integration points.

## Files

- `pte-api/app/src/main/java/com/pte/identity/IdentityService.java`
- `pte-api/app/src/main/java/com/pte/identity/internal/repository/UserRepository.java`
- `pte-api/app/src/main/java/com/pte/identity/internal/service/UserService.java` (suspend/reactivate share the Examiner row lock)
- `pte-api/app/src/main/java/com/pte/identity/dto/response/ExaminerIdentityView.java`
- `pte-api/app/src/main/java/com/pte/identity/dto/response/package-info.java`
- `pte-api/app/src/main/java/com/pte/session/SessionService.java`
- `pte-api/app/src/main/java/com/pte/session/internal/service/SessionLifecycleService.java`
- `pte-api/app/src/main/java/com/pte/scoring/domain/enums/AssignmentScopeType.java`
- `pte-api/app/src/main/java/com/pte/scoring/domain/enums/AssignmentBatchStatus.java`
- `pte-api/app/src/main/java/com/pte/scoring/domain/ExaminerAssignmentBatch.java`
- `pte-api/app/src/main/java/com/pte/scoring/domain/ExaminerAttemptAssignment.java`
- `pte-api/app/src/main/java/com/pte/scoring/dto/request/CreateExaminerAssignmentPreviewRequest.java`
- `pte-api/app/src/main/java/com/pte/scoring/dto/response/ExaminerAssignmentBatchSummaryResponse.java`
- `pte-api/app/src/main/java/com/pte/scoring/dto/response/ExaminerAssignmentConflictResponse.java`
- `pte-api/app/src/main/java/com/pte/scoring/dto/response/ExaminerAssignmentLoadResponse.java`
- `pte-api/app/src/main/java/com/pte/scoring/dto/response/ExaminerAssignmentOverviewResponse.java`
- `pte-api/app/src/main/java/com/pte/scoring/dto/response/ExaminerAssignmentPreviewResponse.java`
- `pte-api/app/src/main/java/com/pte/scoring/dto/response/ExaminerAssignmentScopeReferenceResponse.java`
- `pte-api/app/src/main/java/com/pte/scoring/internal/controller/ExaminerAssignmentController.java`
- `pte-api/app/src/main/java/com/pte/scoring/internal/exception/InvalidExaminerAssignmentException.java`
- `pte-api/app/src/main/java/com/pte/scoring/internal/exception/StaleExaminerAssignmentPreviewException.java`
- `pte-api/app/src/main/java/com/pte/scoring/internal/repository/ExaminerAssignmentBatchRepository.java`
- `pte-api/app/src/main/java/com/pte/scoring/internal/repository/ExaminerAttemptAssignmentRepository.java`
- `pte-api/app/src/main/resources/db/migration/V60__bound_examiner_assignment_history.sql`
- `pte-api/app/src/main/resources/db/migration/V61__mark_stale_examiner_assignment_previews.sql`
- `pte-api/app/src/main/java/com/pte/scoring/internal/service/AssignmentScopeKey.java`
- `pte-api/app/src/main/java/com/pte/scoring/internal/service/ExaminerAssignmentAllocator.java`
- `pte-api/app/src/main/java/com/pte/scoring/internal/service/ExaminerAssignmentService.java`
- `pte-api/app/src/test/java/com/pte/scoring/internal/service/ExaminerAssignmentAllocatorTest.java`
- `pte-api/app/src/test/java/com/pte/scoring/internal/service/ExaminerAssignmentServiceTest.java`
- `pte-api/app/src/test/java/com/pte/scoring/internal/service/ExaminerAssignmentDatabaseIntegrationTest.java`
- `pte-api/app/src/test/java/com/pte/scoring/internal/repository/ExaminerAssignmentRepositoryTest.java`
- `pte-api/app/src/test/java/com/pte/identity/internal/repository/UserRepositoryTest.java`
- `pte-api/app/src/test/java/com/pte/identity/internal/service/UserServiceTest.java`
- `pte-web/apps/tenant-web/features/exams/api/index.ts`
- `pte-web/apps/tenant-web/features/exams/components/ExaminerAssignmentSection.tsx`
- `pte-web/apps/tenant-web/features/exams/components/SessionDetailView.tsx` (Phase 02 import/render integration only; preserve the user's existing roster/class edits)
- `pte-web/apps/tenant-web/features/exams/components/index.ts`
- `pte-web/apps/tenant-web/features/exams/constants/index.ts`
- `pte-web/packages/api-client/src/requests/index.ts`
- `pte-web/packages/api-client/src/requests/scoring/assignments.ts`
- `pte-web/packages/api-client/src/requests/scoring/assignments.test.ts`
- `pte-web/packages/api-client/src/requests/user/index.ts` (load all bounded active-Examiner pages)
- `pte-web/packages/api-client/src/requests/user/index.test.ts`
- `pte-web/packages/api-client/src/types/scoring/index.ts`

## Quality and Testing State

- quality: APPROVED via ck:quality inline fallback; QUAL-026 and the preview/overview UI findings are resolved; zero open blocking findings
- testing: passed — 169 backend regression tests plus 2 H2 database-backed service integration tests
- test report: [phase-02-host-assignment-test-report.json](tests/phase-02-host-assignment-test-report.json)
- Testing detail: the earlier targeted backend regression suite passed 169 tests; the added H2 integration suite passed 2 tests, including concurrent confirm (one persisted assignment) and 40-attempt/2-Examiner preview+commit p95 of 129 ms across 20 measured runs after 3 warmups. The concurrency case exercises the real batch-row `PESSIMISTIC_WRITE` lock; the session-row lock facade is mocked and not covered. The assignment service and JPA repositories were real; session/enrollment/attempt/eligibility/identity facades were mocked, so this is not HTTP/full-stack or PostgreSQL performance evidence. The 283 API-client tests, tenant-web production build, targeted ESLint, H2 repository checks, and isolated PostgreSQL V60/V61 checks also passed. Host browser smoke passed (login, session detail, Examiner directory, assignment preview); preview remains unconfirmed and no assignment was committed to the seeded local session.
- Quality remediation: confirm locks active Examiner user rows through assignment commit; identity suspend/reactivate use the same aggregate lock. Overview bounds batch history by page, aggregates loads in SQL, expires overdue previews, and stores per-attempt eligible-answer counts. Stale candidate/Examiner previews and previews whose per-attempt eligible-answer counts change persist terminal STALE state. Host UI distinguishes query failures from empty data, exposes retry, clears stale confirmation feedback, identifies the affected batch, loads all bounded Examiner pages, and disables previews when their expiry time passes.
- Quality report: [phase-02-host-assignment-quality-report.json](quality/phase-02-host-assignment-quality-report.json); receipt verification is recorded after issuance.
