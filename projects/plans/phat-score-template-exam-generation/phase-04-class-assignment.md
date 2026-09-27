# Phase 4: Enrollment + Session — Assign/unassign Class vào kỳ thi

Covers FR-16 (assign Class → enroll toàn bộ học sinh, không trùng enrollment) và FR-17 (chỉ assign/unassign khi session SCHEDULED), cộng User Decision 3 (unassign chỉ xóa enrollment của học sinh không còn Class nào đang assign che phủ).

## Ràng buộc schema đã xác minh (red-team, 2026-09-17)

`class_memberships.student_public_id` là **UNIQUE toàn hệ thống** (`V4__enrollment.sql:62`, `ClassMembership` `@UniqueConstraint(columnNames = {"student_public_id"})`) — mỗi học sinh thuộc **tối đa 1 Class** tại một thời điểm. Hệ quả:

- Kịch bản "2 Class có 1 học sinh chung" **không thể dựng được với dữ liệu thật**. Success criterion tương ứng của spec chỉ kiểm chứng được ở mức unit test với mock — ghi rõ, không giả vờ đã verify tích hợp.
- User Decision 3 **không đổi**, nhưng với schema này nó tương đương đúng với: "unassign xóa enrollment của các thành viên **hiện tại** của Class bị unassign". Không cần tính hợp các Class còn lại — bỏ phần tính tập hợp phức tạp, giảm rủi ro xóa nhầm.
- Nếu sau này schema cho phép 1 học sinh thuộc nhiều Class, phải quay lại bổ sung phép trừ tập hợp — ghi vào Risks.

## Requirements

Host assign một hoặc nhiều Class vào một kỳ thi SCHEDULED → mọi thành viên hiện tại của các Class đó được enroll đúng 1 lần; assign lại một Class đã assign → enroll bổ sung thành viên mới vào Class sau lần assign trước (spec Assumption: "host assign lại để bổ sung"), không tạo trùng enrollment hay dòng assignment; unassign một Class xóa enrollment của thành viên hiện tại của Class đó; assign/unassign ngoài trạng thái SCHEDULED bị từ chối.

## Files

**Thêm**
- `pte-api/app/src/main/java/com/pte/enrollment/EnrollmentModuleService.java` — facade công khai mới (root package, giống `ItembankService`/`AssessmentService`), method `findActiveStudentPublicIds(UUID tenantId, UUID classPublicId)` — verify Class thuộc đúng tenant (tái dùng logic tương đương `ClassService.loadClassForTenant`) rồi trả danh sách `studentPublicId` từ `ClassMembershipRepository.findByTenantIdAndStudentClass_PublicId`.
- `pte-api/app/src/main/java/com/pte/session/domain/SessionClassAssignment.java` — entity mới (`session_id` FK, `tenant_id`, `class_public_id`, unique `(session_id, class_public_id)`).
- `pte-api/app/src/main/java/com/pte/session/internal/repository/SessionClassAssignmentRepository.java`
- `pte-api/app/src/main/java/com/pte/session/internal/service/SessionClassAssignmentService.java`
- `pte-api/app/src/main/java/com/pte/session/internal/controller/SessionClassAssignmentController.java` — `POST /sessions/{sessionPublicId}/classes`, `GET /sessions/{sessionPublicId}/classes`, `DELETE /sessions/{sessionPublicId}/classes/{classPublicId}`.
- `pte-api/app/src/main/java/com/pte/session/internal/dto/request/AssignClassRequest.java`
- `pte-api/app/src/main/java/com/pte/session/internal/dto/response/SessionClassAssignmentResponse.java`
- `pte-api/app/src/main/java/com/pte/session/internal/exception/ClassAssignmentNotAllowedException.java` — session không ở trạng thái SCHEDULED.
- `pte-api/app/src/main/java/com/pte/session/internal/exception/ClassAssignmentNotFoundException.java`
- `pte-api/app/src/main/resources/db/migration/V20__session_class_assignment.sql` — tạo bảng `session_class_assignments` (xác nhận lại `V19` là migration mới nhất trước khi đặt tên `V20`).

**Sửa**
- `pte-api/app/src/main/java/com/pte/session/internal/repository/EnrollmentRepository.java` — thêm query xóa enrollment theo `(sessionId, studentPublicId IN ...)` để phục vụ unassign.
- `pte-api/app/src/main/java/com/pte/session/internal/constant/SessionConstants.java` — thêm mã lỗi mới.

## Steps

1. Thêm `EnrollmentModuleService` ở root package `com.pte.enrollment` (không phải `internal`) — chỉ 1 method đọc, verify tenant ownership trước khi trả danh sách; đây là facade đầu tiên của module `enrollment` cho module khác gọi tới (`session → enrollment` là cạnh một chiều mới, hợp lệ vì `enrollment` không phụ thuộc ngược `session`).
2. Thêm entity `SessionClassAssignment` + repository + migration tạo bảng, unique `(session_id, class_public_id)`.
3. `SessionClassAssignmentService.assign(sessionPublicId, classPublicId, caller)`: lock session (tái dùng `SessionLifecycleService.findOwnedWithLock`), từ chối nếu `status != SCHEDULED`; gọi `EnrollmentModuleService.findActiveStudentPublicIds(...)` rồi **luôn** gọi `EnrollmentService.bulkEnroll(sessionPublicId, new BulkEnrollRequest(studentIds), caller)` có sẵn — kể cả khi assignment đã tồn tại, vì `bulkEnroll` đã tự bỏ qua học sinh đã enroll (`EnrollmentService.java:90-99`), nên assign lại chính là cách bổ sung thành viên mới vào Class. Chỉ lưu dòng `SessionClassAssignment` khi chưa tồn tại. Class rỗng (0 thành viên) vẫn assign được, không lỗi.
4. `SessionClassAssignmentService.unassign(sessionPublicId, classPublicId, caller)`: lock session, từ chối nếu `status != SCHEDULED`; 404 nếu Class chưa được assign; lấy thành viên hiện tại của Class qua `EnrollmentModuleService`, xóa đúng các `Enrollment` của session thuộc tập đó, rồi xóa dòng `SessionClassAssignment`. Không tính hợp các Class còn lại (xem "Ràng buộc schema").
5. Thêm controller `SessionClassAssignmentController` với 3 endpoint (assign/list/unassign), `@PreAuthorize` giống `SessionController` (`HOST_ADMIN`, `HOST_AUTHOR`).
6. Verify tay migration `V20` trên Postgres thật.

## Tests

- `EnrollmentModuleServiceTest`:
  - `findActiveStudentPublicIds_returnsAllMembersOfClass`.
  - `findActiveStudentPublicIds_classFromOtherTenant_throwsNotFound`.
  - `findActiveStudentPublicIds_unknownClass_throwsNotFound`.
- `SessionClassAssignmentServiceTest`:
  - `assign_singleClass_enrollsAllItsStudents`.
  - `assign_sessionNotScheduled_rejected`.
  - `assign_sameClassTwice_noDuplicateAssignmentRow_stillCallsBulkEnroll` — lần 2 không lưu thêm dòng assignment nhưng vẫn gọi `bulkEnroll`.
  - `assign_againAfterNewMemberJoined_enrollsOnlyTheNewMember` — Class có thêm 1 thành viên sau lần assign đầu → assign lại chỉ tạo 1 enrollment mới.
  - `assign_twoClasses_enrollmentCountEqualsDistinctStudents_allOnSameSnapshot` — dùng mock, bao gồm trường hợp danh sách trả về trùng 1 id (chỉ kiểm chứng được qua mock, xem "Ràng buộc schema").
  - `assign_emptyClass_succeedsWithNoEnrollment`.
  - `unassign_removesEnrollmentsOfCurrentClassMembersOnly` — học sinh enroll qua Class khác không bị đụng.
  - `unassign_classNotAssigned_throwsNotFound`.
  - `unassign_sessionNotScheduled_rejected`.
- `mvn test -pl app` xanh; `ModuleStructureTest.modules_have_no_boundary_violations()` vẫn xanh (xác nhận `session → enrollment` không tạo chu trình).

## Success Criteria

- Assign nhiều Class → số enrollment = số học sinh distinct; mọi enrollment trỏ cùng 1 `snapshotPublicId` (trường hợp "học sinh chung" chỉ kiểm chứng qua unit test mock — schema hiện tại không cho phép dữ liệu thật như vậy).
- Assign lại một Class đã assign bổ sung đúng các thành viên mới, không trùng enrollment/assignment.
- Unassign một Class xóa enrollment của thành viên hiện tại của Class đó, không đụng enrollment khác.
- Assign/unassign ngoài trạng thái SCHEDULED bị từ chối (409/400 tùy convention hiện có).
- `ModuleStructureTest` xanh — không phát sinh vi phạm boundary Spring Modulith mới.

## Risks

- MEDIUM: Nếu schema `class_memberships` sau này bỏ unique `student_public_id` (cho phép 1 học sinh nhiều Class), `unassign()` sẽ xóa nhầm enrollment của học sinh vẫn còn thuộc một Class khác đang assign — lúc đó phải bổ sung phép trừ tập hợp các Class còn lại. Ghi comment ngay tại `unassign()` trỏ về ràng buộc `V4__enrollment.sql:62`.
- MEDIUM: Học sinh được **chuyển** từ Class A (đang assign) sang Class C (không assign) sau lần assign vẫn giữ enrollment cũ; unassign A không còn thấy học sinh đó trong thành viên hiện tại của A nên không xóa. Chấp nhận (host xóa lẻ bằng API enrollment có sẵn) — nêu trong UI help text ở Phase 7/8 nếu cần.
- MEDIUM: `SessionClassAssignmentService.assign()` gọi `EnrollmentService.bulkEnroll()` vốn tự lock session bên trong (`findOwnedWithLock`) — cùng transaction, cùng row lock Postgres là re-entrant với chính transaction đó, nhưng review kỹ để không lock qua 2 connection khác nhau.
- LOW: Tên `EnrollmentModuleService` (root `com.pte.enrollment`) dễ nhầm với `session.internal.service.EnrollmentService` đã có sẵn — khác package, không đụng compile, nhưng cần nêu rõ trong code review.
