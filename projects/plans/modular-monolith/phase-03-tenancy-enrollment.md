# Phase 03 — Tenancy + Enrollment

**Plan:** [plan.md](plan.md) · **Spec:** [spec.md](spec.md)
**Covers:** P1 "đọc dữ liệu bằng một câu truy vấn", FR-04, FR-11
**Nguồn:** `services/admin` (149 file — service lớn nhất)

---

## Mục tiêu

Xoá sổ cơ chế projection đã gây ra bug production ngày 2026-09-15, thay bằng một câu
JOIN trực tiếp.

Đây là phase có giá trị chứng minh cao nhất: nó biến lập luận "gộp lại thì đơn giản
hơn" thành một thay đổi đo được. `admin` tách đôi vì nó đang chứa hai bounded context
khác nhau — quản trị người thuê, và tổ chức lớp học.

---

## Design Constraints

> Preflight: convention observed from Phase 02 is public module APIs at the root package, implementation under `internal/`, shared `BaseEntity`/security/web types, constructor injection, stable `DomainException` codes, and Spring Modulith boundary verification. Applicable rules for this phase: tenant scope on every tenant-data query, one-way module dependencies, direct roster reads through an identity-owned read-only view, bounded pagination, service-level transaction boundaries, and database constraints for ownership/uniqueness.

- `admin` chia theo ranh giới nghiệp vụ, **không** theo file:
  - `tenancy` ← `Tenant`, `Organization`, `QuotaTransaction`
  - `enrollment` ← `Program`, `StudentClass`, `ClassMembership`, `Enrollment`,
    `LecturerAssignment`, `ProgramCoordinatorAssignment`
  - `shared/audit` ← `AuditLog` (hạ tầng xuyên suốt, không phải nghiệp vụ riêng)
- `enrollment` phụ thuộc `tenancy` và `identity`, **không** có chiều ngược lại.
- Giữ nguyên hợp đồng API mà `tenant-web` đang gọi: `/student-roster`,
  `/organizations`, `/organizations/{id}/programs` — kể cả tên tham số truy vấn.
- **FR-11:** mọi truy vấn có dữ liệu theo tenant phải giữ kiểm tra `tenantId`. Phase
  này chạm nhiều truy vấn nhất nên là chỗ dễ nới lỏng nhất.

---

## Việc cần làm

1. **Port `tenancy`** — `Tenant`, `Organization`, `QuotaTransaction`, service,
   controller, mapper tương ứng. Bỏ ghi outbox.

2. **Port `enrollment`** — `Program`, `StudentClass`, `ClassMembership`,
   `LecturerAssignment`, `ProgramCoordinatorAssignment`, cùng `ProgramService`,
   `ClassService`, `AssignmentService`. Bỏ ghi outbox.

3. **Xoá toàn bộ cơ chế student roster projection** — đây là trọng tâm phase:

   | Xoá | Lý do |
   |---|---|
   | `StudentRosterEntry` | Bản sao dữ liệu của `identity.User` |
   | `StudentRosterConsumer` | Không còn event để tiêu thụ |
   | `StudentRosterRebuildService` | Không còn gì để rebuild |
   | `StudentRosterBackfillRunner` | Bản vá cho vấn đề nay không tồn tại |
   | `ProjectionBackfill` + repository + `V3__create_projection_backfills.sql` | Như trên |
   | `StudentExportClient` | Không còn gọi xuyên service |
   | `InternalRebuildController` | Không còn rebuild thủ công |
   | `EventIdempotencyGuard`, `ProcessedEvent`, `OutboxEntry` | Hạ tầng đồng bộ |

   > Ghi chú: `StudentRosterBackfillRunner` và `ProjectionBackfill` là bản vá viết
   > ngày 2026-09-15 (`3bb9670`) cho chính con bug này. Chúng biến mất cùng với
   > nguyên nhân. Đây là kết quả đúng, không phải mất công.

4. **Viết lại truy vấn roster thành JOIN trực tiếp**
   - Cũ: `StudentRosterEntryRepository.findPageForTenant` JOIN
     `StudentRosterEntry` (bản sao) với `ClassMembership`.
   - Mới: JOIN thẳng `identity` `users` với `enrollment` `class_memberships`.
   - **Giữ nguyên toàn bộ hành vi truy vấn**: tìm theo tên/email/phone/mã HV,
     lọc theo program/class, lọc `assignmentStatus` ALL/ASSIGNED/UNASSIGNED, sắp xếp
     CREATED_AT/FULL_NAME/STUDENT_CODE × ASC/DESC, phân trang, và **khoá sắp xếp phụ
     theo `studentPublicId`** để phân trang ổn định.
   - Ranh giới module: `enrollment` không được truy cập bảng `users` trực tiếp. Hai
     lựa chọn, quyết khi thực thi:
     - (a) view/projection đọc-chỉ do `identity` phơi ra, `enrollment` JOIN vào; hoặc
     - (b) truy vấn đặt trong `identity`, nhận tham số lọc từ `enrollment`.
     Ưu tiên (a) — giữ được một câu SQL duy nhất, đúng mục tiêu của phase.

5. **Tra soát phân tách tenant** — rà từng truy vấn đã port, xác nhận không mất điều
   kiện `tenantId`. Có test hiện có cho việc này (`ClassMembershipRepositoryTest
   .findByTenantAndProgram_crossTenantProgramId_returnsEmptyNeverTheOtherTenantsRoster`)
   — port sang và giữ nguyên.

5b. **Sửa lỗ hổng ghi chéo tenant trong `bulkAssign`** *(phát hiện khi red-team
   review 2026-09-15 — lỗi có sẵn trong code hiện tại, không do migration sinh ra)*

   `ClassService.bulkAssign` hiện xác thực **lớp** thuộc tenant người gọi, nhưng
   **không** xác thực **học viên**:

   ```java
   StudentClass studentClass = findOwned(..., caller);   // kiểm tra tenant của LỚP
   ...
   membership.setStudentPublicId(studentPublicId);        // KHÔNG kiểm tra tenant của HỌC VIÊN
   ```

   Hệ quả: tenant B truyền publicId học viên của tenant A, học viên đó chưa ở lớp nào
   → tạo membership gắn học viên tenant A vào lớp tenant B.

   `ClassMembershipRepository.findByStudentPublicIdIn` cũng thiếu lọc `tenantId`, dù
   chính file đó có chú thích cảnh báo rất rõ ở phương thức bên cạnh rằng *"a
   cross-tenant leak here poisons Phase 10's bulk-enroll input"*. Lời cảnh báo có,
   nhưng không áp cho phương thức này.

   Cần làm:
   - Xác thực mọi `studentPublicId` trong yêu cầu thuộc tenant người gọi, trước khi
     tạo membership. Dùng `IdentityService` (API công khai của module `identity`).
   - Thêm biến thể có lọc tenant cho `findByStudentPublicIdIn`.
   - Rà các phương thức cùng nhóm cũng thiếu lọc: `findByPublicId`,
     `existsByStudentPublicId`.

6. **Flyway** `V3__tenancy.sql`, `V4__enrollment.sql`. **Không** có bảng nào tên
   `student_roster_entries`, `processed_events`, `outbox_entries`,
   `projection_backfills`.

---

## Tests to Write First

- Test phân trang roster: xác nhận trang 2 không lặp lại bản ghi của trang 1 khi có
  hai student trùng `createdAt` — chứng minh khoá sắp xếp phụ còn nguyên sau khi đổi
  từ projection sang JOIN. Đây là hành vi dễ đánh rơi nhất khi viết lại truy vấn.

- `bulkAssignCrossTenantStudentId_rejectsAndCreatesNothing()` — tenant B gửi publicId
  học viên của tenant A. Chạy trên code **hiện tại** phải **đỏ** (chứng minh lỗ hổng
  có thật), xanh sau bước 5b.

---

## Acceptance (original criteria)

- [x] `/student-roster` trả đúng kết quả như bản projection, với **một** câu JOIN
- [x] Các test nghiệp vụ của `admin` đã port và xanh, gồm cả test cách ly cross-tenant; test rebuild projection đã bị loại bỏ cùng hạ tầng tương ứng
- [x] Test phân trang mới xanh
- [x] Scan các tên artifact projection/event-synchronization cũ trong `app/src/main` và `app/src/test` không có kết quả
- [x] Số bảng kiểu đồng bộ trong schema monolith: **0**
- [x] `ApplicationModules.verify()` pass — `enrollment → tenancy → identity` một chiều
- [x] `services/admin` vẫn build được

---

## Quality and Testing State

- Quality: APPROVED — inline `ck:quality --gate` contract review; no open BLOCKER/HIGH findings and no introduced MEDIUM findings.
- Testing: PASSED — `mvn -pl app test`, 142 tests, 0 failures/errors/skips.

## Completion Evidence

- [x] `/student-roster` keeps the existing filters, sorting, pagination, and tie-break behavior through a single data JOIN against the identity-owned read-only view.
- [x] Enrollment and tenancy business tests were ported; the obsolete projection-rebuild test was intentionally removed with that infrastructure. Cross-tenant bulk assignment is covered and passes.
- [x] Deterministic roster pagination test passes when students share the same `createdAt`.
- [x] Legacy projection/event-synchronization artifact scan returns no matches in `app/src/main` or `app/src/test`.
- [x] The monolith migrations create zero synchronization tables (`student_roster_entries`, `processed_events`, `outbox_entries`, `projection_backfills`).
- [x] `ApplicationModules.verify()` passes with enrollment depending one way on tenancy and identity.
- [x] `services/admin` compiles successfully.
