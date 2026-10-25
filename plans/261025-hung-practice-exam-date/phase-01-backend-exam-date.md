# Phase 1: Backend — V135 + API hồ sơ ngày thi
Preflight: In practice module; Clock injected; examDate validated in [today (Asia/Ho_Chi_Minh), today + 2y].

Status: Completed · FR-01, 02, 03

## Requirements
- `V135__practice_student_profiles.sql`: bảng `practice_student_profiles` (`id BIGINT IDENTITY PK`, `public_id UUID unique`, `created_at`, `updated_at`, `deleted`, `student_public_id UUID NOT NULL UNIQUE`, `tenant_id UUID NOT NULL`, `exam_date DATE`, `version BIGINT`).
- Entity `PracticeStudentProfile` (extends `BaseEntity`), repository `findByStudentPublicIdAndDeletedFalse`.
- `PracticeProfileService`: `get(caller)` → `PracticeProfileResponse(LocalDate examDate)` (null khi chưa có hàng); `update(caller, request)` upsert; validate `examDate` null hoặc trong [hôm nay theo `Asia/Ho_Chi_Minh`, hôm nay + 2 năm] → ngoài khoảng 422 `PRACTICE_EXAM_DATE_INVALID`. Kiểm tra entitlement như các API practice khác (`PracticeEntitlementService.assertUnlocked`).
- `PracticeProfileController`: `PRACTICE_PROFILE_PATH = "/api/v1/student/practice/profile"`, `GET`, `PUT` (`@Valid` body `PracticeProfileUpdateRequest(LocalDate examDate)`), `@PreAuthorize("hasRole('STUDENT')")`, `@ConditionalOnProperty` như controller practice khác.
- Upsert an toàn khi gọi song song: bắt `DataIntegrityViolationException` (unique student) → đọc lại và cập nhật.

## Design Constraints
- Chỉ module practice; `Clock` tiêm vào service để test được "hôm nay".
- Hằng mã lỗi/thông điệp ở `PracticeConstants`.

## Related files
`app/src/main/resources/db/migration/V135__practice_student_profiles.sql`, `practice/internal/{domain/PracticeStudentProfile.java, repository/PracticeStudentProfileRepository.java, service/PracticeProfileService.java, controller/PracticeProfileController.java, dto/request/PracticeProfileUpdateRequest.java, dto/response/PracticeProfileResponse.java, constant/PracticeConstants.java}`

## Steps
1. Migration + entity + repository.
2. Service + test (`PracticeProfileServiceTest`: chưa có hàng → null; đặt ngày hợp lệ → lưu; ngày quá khứ / > 2 năm → 422; null → xoá; hồ sơ của người khác không bị đụng).
3. Controller.
4. Build gate: compile + test practice + `ModuleStructureTest`.

## Success Criteria
- GET/PUT chạy local; test mới pass.

## Quality and Testing State
- Quality: skipped_by_user (user_confirmed_skip)
- Testing: passed (8 unit tests in PracticeProfileServiceTest, 3 Modulith tests)
