# Phase 1: Backend — V134, phiên theo kỹ năng, số câu theo kỹ năng

Status: Not started
User stories: Study-Pack (P1) phần BE
FR: FR-01, FR-02 · Tiêu chí §9: "Phiên kỹ năng Reading 10 câu → đúng 10 item, ≥ 2 dạng bài"

## Requirements

- Migration **V134** (một file, cả phần phase 2 dùng để không phải migration thứ hai):
  - `practice_sessions`: thêm `kind varchar(16) null` (null = TASK), `skill_code varchar(16) null`, `mock_test_id bigint null` FK → `practice_mock_tests(id)`; index `(student_public_id, mock_test_id, status)`.
  - `practice_mock_tests`: `id`, `public_id uuid unique`, `sequence_no int unique not null`, `title varchar(128)`, `seed bigint not null`, `template_public_id uuid`, `template_version int`, `status varchar(16) not null` (`PUBLISHED`|`HIDDEN`), `item_count int not null`, `estimated_minutes int not null`, audit cột như bảng practice khác, `deleted boolean default false`.
  - `practice_mock_test_items`: `id`, `mock_test_id` FK, `question_public_id uuid not null`, `task_code varchar(64) not null`, `section varchar(16) not null`, `order_index int not null`; unique `(mock_test_id, order_index)`.
- Start request: thêm `skillCode` (tuỳ chọn, `SPEAKING|WRITING|READING|LISTENING`). Có `skillCode`:
  - `taskTypeCodes` phải rỗng, nếu không 400 `PRACTICE_SESSION_REQUEST_INVALID`.
  - Server lấy mọi dạng bài RUNNABLE của section đó cho client capabilities (`PracticeCatalogService.resolveStartableTasks`); không có dạng nào → 422 `PRACTICE_CONTENT_NOT_READY`.
  - TIMED chỉ khi `PracticeTimingService.covers` mọi dạng (D10), nếu không 422 như hiện tại.
  - Lưu `kind = SKILL`, `skill_code`, `selected_task_types` = các mã đã resolve.
- `pickAndPin`: với `kind = SKILL`, số câu mỗi dạng theo A5 (chia đều, dư cho dạng đầu). `kind = TASK` giữ nguyên.
- Catalog student: mỗi section thêm `practiceQuestionCount` (tổng câu PRACTICE published của các dạng bài trong section) và `answeredQuestionCount` (số `source_question_id` khác nhau mà học viên có item `ANSWERED`, thuộc các dạng đó). Catalog không có user (admin preview) → 0.
- Hash idempotency start gồm `skillCode` (R5).

## Design Constraints

- Ranh giới Modulith: practice chỉ gọi API gốc `com.pte.itembank.PracticeQuestionService`; thêm `Map<String, Long> countPublishedByTaskTypeKeys(Collection<String>)` ở đó (một truy vấn GROUP BY, pool PRACTICE, cùng điều kiện với `findPublishedCandidateIds`).
- Đếm đã trả lời: một truy vấn ở `PracticeSessionItemRepository` (`count distinct source_question_id ... where session.student = ? and item.status = ANSWERED and task_code in (...)`), không lặp theo dạng bài.
- Mọi chỗ đọc kind qua `PracticeSession.effectiveKind()` (null → TASK) (R6).
- Enum mới `PracticeSessionKind` ở `internal/domain/enums`; hằng mã lỗi/thông điệp ở `PracticeConstants`.
- `PracticeCatalogSectionResponse` thêm 2 trường cuối có giá trị mặc định 0 (constructor tương thích cho test/caller cũ, như cách `PracticeSessionStartRequest` làm).
- Flyway: không sửa V133; V134 idempotent không cần (chạy một lần) nhưng dùng `IF NOT EXISTS` cho index theo convention repo.

## Related files

- `pte-api/app/src/main/resources/db/migration/V134__practice_skill_sessions_and_mock_tests.sql` (mới)
- `practice/internal/domain/PracticeSession.java`, `domain/enums/PracticeSessionKind.java` (mới)
- `practice/internal/dto/request/PracticeSessionStartRequest.java`
- `practice/internal/service/PracticeSessionService.java` (`start`, `startRequestHash`)
- `practice/internal/service/PracticeSessionItemService.java` (`pickAndPin`)
- `practice/internal/service/PracticeCatalogService.java` (`getStudentCatalog`), `controller/PracticeCatalogController.java`
- `practice/internal/dto/response/PracticeCatalogSectionResponse.java`
- `practice/internal/repository/PracticeSessionItemRepository.java`
- `itembank/PracticeQuestionService.java`, `itembank/internal/repository/QuestionRepository.java`
- `practice/internal/constant/PracticeConstants.java`

## Steps

1. Viết V134 theo Requirements; chạy app local để Flyway áp dụng; kiểm tra bằng `\d practice_sessions`.
2. Thêm `PracticeSessionKind`, cột `kind`, `skillCode`, `mockTestId` vào entity + `effectiveKind()`.
3. `PracticeSessionStartRequest`: thêm `skillCode` (`@Pattern` 4 giá trị), `mockTestId` (UUID), `restart` (Boolean) — hai trường sau dùng ở phase 2 nhưng thêm luôn để hash ổn định; constructor tương thích cũ.
4. `PracticeSessionService.start`: nhánh `skillCode` → validate loại trừ, resolve tasks, timed check, set kind/skill/selected types; cập nhật hash.
5. Tách hàm thuần `distributeQuestionCount(int total, int taskCount) → int[]` (A5) trong `PracticeSessionItemService` hoặc lớp nhỏ `PracticeQuestionAllocation`; `pickAndPin` dùng theo kind.
6. itembank: `countPublishedByTaskTypeKeys`; repository item: `countAnsweredSourceQuestions`.
7. Catalog: điền 2 trường mới cho student catalog.
8. Test (viết cùng code): `PracticeQuestionAllocationTest` (10/3 → 4,3,3; 2/3 → 1,1,0; total < 1 → lỗi), `PracticeSessionServiceTest` (skillCode + taskTypeCodes → 400; skill không có dạng RUNNABLE → 422; hash khác khi skillCode khác), `PracticeCatalogServiceTest` (số đếm điền đúng).
9. Build gate: `./mvnw -q -pl app -am compile` + chạy các test liên quan + `ModuleStructureTest`.

## Success Criteria

- Start `skillCode=READING, questionCount=10, UNTIMED` trên seed local → begin tạo 10 item thuộc ≥ 2 dạng Reading.
- Gửi cả `skillCode` và `taskTypeCodes` → 400.
- Catalog student trả `practiceQuestionCount` > 0 cho 4 section và `answeredQuestionCount` tăng sau khi trả lời 1 câu.
- Phiên cũ (kind null) vẫn mở/làm/review được.
- `ModuleStructureTest` xanh; test mới xanh.

## Quality and Testing State

- Quality: not evaluated
- Testing: not started
