# Phase 6: Đào tạo (6a) — Program & Class

## Requirements

Chuyển `Program`, `StudentClass` (+ `ClassMembership`, `LecturerAssignment`) trong module `enrollment` thành `Program` và `Class` (students, lecturers là bảng con). Phase này tách khỏi ExamSession để giảm quy mô; chức năng merge/split/bulk assign, roster, dashboard giữ nguyên.

## Design Constraints

- Đọc đầy đủ `docs/CODING_STANDARDS_API.md`, `docs/API_RESPONSE_SETUP.md`, `docs/COMMON_EXCEPTION_SETUP.md`, `docs/HOST_STUDENT_IMPORT_FLOW.md` (roster/import); nếu đổi endpoint thì đọc thêm `docs/CODING_STANDARDS_WEB.md`. Ghi standards-read note vào progress update đầu tiên.
- `ClassStudent` và `ClassLecturer` là bảng con có FK + unique (class, user); lọc/đếm theo trạng thái nên không dùng jsonb.
- Mọi bảng có `organizationId`; tên class/program unique trong tổ chức (giữ `StudentClassNameAlreadyUsedException`, `ProgramNameAlreadyUsedException`).
- Cross-module chỉ qua public service: `session` (audience resolve CLASS/PROGRAM) và `reporting` đọc qua `EnrollmentOverviewService`/public API enrollment.

## Steps

1. Thiết kế `Program` và `Class` trong `enrollment/domain` thay `Program`, `StudentClass`, `ClassMembership`, `LecturerAssignment`; trạng thái `ClassStatus`/`ProgramStatus` giữ.
2. Cập nhật `ProgramService`, `ProgramController`, `ClassController`, `ClassMembershipController`, `LecturerAssignmentController`, `AssignmentService`, `StudentRosterQueryService`, `StudentRosterController`, `EnrollmentOverviewService` cùng mapper (`ProgramMapper`, `StudentClassMapper`, `ClassMembershipMapper`).
3. Giữ hành vi merge/split/bulk assign và exception tương ứng; message trong constants của module.
4. Cập nhật consumer (`session` `SessionClassAssignmentService`, identity roster, reporting) qua public API; adapter tạm trong phase.
5. Nếu endpoint/DTO đổi: ghi vào bảng spec, sửa client call site trong phase này và chạy lint/typecheck/build theo `CODING_STANDARDS_WEB.md`; nếu không đổi, ghi "không đổi" trong progress update.
6. Test: chuyển test enrollment, bảo toàn hành vi roster/merge/split; thêm test tenant isolation cho class/program.
7. Seed V1: program và class mẫu; cập nhật `V1__baseline.sql` (`program`, `class`, `class_student`, `class_lecturer`, unique/index).
8. Chạy compile, test toàn app, `ModuleStructureTest`, gate Postgres.

## Success Criteria

- Hành vi program/class/roster/merge/split giữ nguyên (test chuyển hoặc thay thế).
- Không còn `StudentClass`, `ClassMembership`, `LecturerAssignment` (và `Program` cũ).
- Gate dev DB (profile `local-schema`): từ `D:\GitHub\pte-org\pte-api`, DB `pte` trống trên Docker Postgres 17; `APP_SPRING_PROFILES=local-schema` trong `.env.local`; `docker compose --env-file .env.local -f docker-compose.yml -f docker-compose.services.yml up -d --no-deps --build app` khởi động (health UP) với Hibernate dựng schema, `db/dev-seed/*.sql` chạy xong, và `POST /api/v1/auth/login` thành công với `admin@test.local` và `host.e2e@test.local`. Ràng buộc chỉ Postgres phải có trong `db/dev-seed/000-postgres-objects.sql`. Không chạy được thì ghi "not verified", không bỏ qua im lặng.
- `.\mvnw.cmd -pl app -DskipTests compile`, `.\mvnw.cmd -pl app test`, `ModuleStructureTest` xanh; ghi số `@Entity` và số bảng do Hibernate dựng.

## Quality and Testing State

- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementing this phase)
- Testing: not started

## Risks

- Session audience resolve đang dùng `ClassMembership`: adapter tạm phải nằm sau public API enrollment và được xoá ở phase 7.
- Roster pagination plan đang tạm dừng có thể muốn đổi cùng bảng: chỉ tiếp tục sau phase này.
