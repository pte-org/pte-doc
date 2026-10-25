# Phase 2: Backend — đề luyện: generate, danh sách, phiên MOCK_TEST, điểm ước lượng

Status: Not started
User stories: danh sách + làm đề (P1), tiếp tục (P1), tạo đề (P1), điểm ước lượng (P2), làm lại (P2)
FR: FR-03, FR-04, FR-05, FR-06 · Tiêu chí §9: generate 3 đề × 65 câu PRACTICE; hai học viên cùng đề; tiếp tục ở câu 6; 4 điểm kỹ năng + tổng

## Requirements

### Generate (admin)
- `POST /api/v1/admin/practice/mock-tests:generate` body `{ "count": 1..20 }`, `@PreAuthorize("hasRole('PLATFORM_ADMIN')")`.
- Lấy Score Template active (`ScoreTemplateService.findActive()`); không có → 422 `PRACTICE_MOCK_TEST_TEMPLATE_MISSING`.
- Với mỗi đề mới: `sequence_no = max + 1`, `seed = sequence_no`, `title = "PTE Academic Full Mock Test {n}"`.
  - Duyệt item template theo section (SPEAKING → WRITING → READING → LISTENING) rồi `sequence`; với mỗi dạng lấy `minCount` câu bằng `PracticeQuestionPicker(() -> new Random(seed ^ hash(taskCode)))`, `seen` = câu đã ghim ở mọi đề trước (D6).
  - Dạng nào có ít hơn `minCount` câu PRACTICE → 422 `PRACTICE_MOCK_TEST_BANK_INSUFFICIENT` liệt kê dạng thiếu; **không tạo đề nào** trong lần gọi (một transaction).
  - `item_count` = tổng câu; `estimated_minutes` = làm tròn lên bội số 5 của Σ(preListen + prep + response) theo template + task-timing (dùng `PracticeTimingService.activeTimings()`), tối thiểu 5.
  - `template_public_id`, `template_version` ghi lại.
- Trùng `sequence_no` khi gọi song song → bắt `DataIntegrityViolationException`, thử lại tối đa 3 lần.

### Danh sách (học viên)
- `GET /api/v1/student/practice/mock-tests` → đề `PUBLISHED`, không xoá, theo `sequence_no`; mỗi đề: `publicId, title, sequenceNo, itemCount, estimatedMinutes, latestAttempt?` với `latestAttempt = { sessionPublicId, status, answeredItemCount, totalItemCount, estimatedOverall? }` của lượt mới nhất của chính học viên (một truy vấn cho mọi đề, không N+1).
- Yêu cầu entitlement như catalog (`PracticeEntitlementService.assertUnlocked`).

### Phiên MOCK_TEST
- Start với `mockTestId`: `taskTypeCodes`/`skillCode` phải rỗng (400). Đề không tồn tại / HIDDEN → 404 `PRACTICE_MOCK_TEST_NOT_FOUND`.
- Có lượt OVERVIEW/IN_PROGRESS của đề này và `restart != true` → trả lượt đó (FR-04). `restart = true` → lượt cũ chuyển `DISCARDED` (dùng cơ chế discard sẵn có nếu có, nếu không đặt status + `discarded_at`), tạo lượt mới.
- Phiên: `kind = MOCK_TEST`, `timing_mode = TIMED` (bỏ qua giá trị client gửi), `question_count = item_count`, `selected_task_types` = các mã trong đề.
- `createItemsIfNeeded` với MOCK_TEST: đọc `practice_mock_test_items` theo `order_index`, ghim nội dung bằng `findPublishedQuestionsForPinning` (một lô), timing theo `PracticeTimingService`; câu không còn published → bỏ qua + WARN (R2). Không gọi picker.
- Template không còn timing cho một dạng trong đề → item đó không có timing (FE chạy untimed cho câu đó) + WARN; không chặn cả đề.

### Điểm ước lượng
- `PracticeScoreEstimator` (thuần): input = danh sách (taskCode, rawScore 0–100 | null, scored?) + item template; output `{overall, speaking, writing, reading, listening: Integer|null, excludedItemCount, pending: boolean}` theo FR-18 (A4). Kỹ năng không có trọng số đã chấm → null.
- `GET {PRACTICE_SESSION_PATH}/{publicId}/review`: nếu `kind = MOCK_TEST` thêm `estimatedScores`; khác → `null`.
- `rawScore` của item = `aiScore` nếu có, ngược lại `objectiveScore`; item FAILED → excluded; SCORING/chưa chấm → pending.

## Design Constraints

- Module practice: controller admin mới `PracticeMockTestAdminController` ở `practice/internal/controller`, service `PracticeMockTestService` (generate + list), `PracticeMockTestRepository`, `PracticeMockTestItemRepository`; entity ở `practice/internal/domain`.
- Không import `reporting.internal`, `assessment.*`; chỉ `scoretemplate.ScoreTemplateService` + DTO.
- `PracticeQuestionPicker` thêm constructor/phương thức nhận `RandomGenerator` trực tiếp cho generate (không đổi hành vi hiện có).
- Không phát sinh N+1: danh sách đề = 2 truy vấn (đề + lượt mới nhất theo student bằng window/`DISTINCT ON` hoặc JPQL max(created_at) group by mock_test_id).
- Mã lỗi + thông điệp ở `PracticeConstants`; path ở hằng mới `PRACTICE_MOCK_TEST_PATH`, `PRACTICE_MOCK_TEST_ADMIN_PATH`.
- Security config: đảm bảo `/api/v1/admin/practice/**` không bị chặn bởi filter practice-student (kiểm tra `SecurityConfig`/practice auth filter hiện có).

## Related files

- `practice/internal/domain/PracticeMockTest.java`, `PracticeMockTestItem.java`, `enums/PracticeMockTestStatus.java` (mới)
- `practice/internal/repository/PracticeMockTestRepository.java`, `PracticeMockTestItemRepository.java` (mới)
- `practice/internal/service/PracticeMockTestService.java`, `PracticeScoreEstimator.java` (mới)
- `practice/internal/controller/PracticeMockTestController.java`, `PracticeMockTestAdminController.java` (mới)
- `practice/internal/dto/request/PracticeMockTestGenerateRequest.java`, `dto/response/PracticeMockTestResponse.java`, `PracticeEstimatedScoresResponse.java` (mới)
- `practice/internal/service/PracticeSessionService.java`, `PracticeSessionItemService.java`, `PracticeReviewService.java`
- `practice/internal/dto/response/PracticeReviewResponse.java`
- `practice/internal/service/PracticeQuestionPicker.java`
- `practice/internal/constant/PracticeConstants.java`
- tham chiếu công thức: `reporting/internal/service/ScoreAggregationService.java` (chỉ đọc)

## Steps

1. Entity + repository cho đề và câu ghim; `PracticeMockTestStatus`.
2. `PracticeScoreEstimator` + test đối chiếu FR-18 (bộ số tay: 2 dạng, trọng số khác nhau, 1 câu pending, 1 FAILED).
3. `PracticeMockTestService.generate(count)`: transaction, retry sequence, ước tính phút; test: đủ câu → 2 đề × đúng minCount mỗi dạng, mọi câu từ candidate PRACTICE; cùng seed → cùng danh sách; thiếu câu → 422 và không lưu gì; đề sau ưu tiên câu chưa ghim.
4. Admin controller + test `@WebMvcTest`/security: STUDENT → 403, PLATFORM_ADMIN → 200.
5. `list(caller)` + controller học viên; test: đề HIDDEN không xuất hiện; latestAttempt đúng lượt mới nhất.
6. `PracticeSessionService.start` nhánh `mockTestId` (resume/restart, TIMED cưỡng bức, hash gồm mockTestId+restart); `createItemsIfNeeded` nhánh MOCK_TEST; test: resume trả cùng session; restart discard lượt cũ; item theo đúng order; câu bị gỡ publish bị bỏ qua.
7. Review: thêm `estimatedScores`; test mapper.
8. Build gate: compile, test practice package, `ModuleStructureTest`; sau đó full suite `./mvnw -q -pl app -am test`.

## Success Criteria

- Generate count=3 trên seed `-PerTask 12` → 3 đề, mỗi đề 65 item, mọi `question_public_id` thuộc pool PRACTICE (SQL kiểm tra).
- Hai học viên start cùng đề → cùng danh sách `source_question_id` cùng thứ tự.
- Start lại đề đang làm → cùng `sessionPublicId`; `restart=true` → session mới, cũ DISCARDED.
- Review của phiên MOCK_TEST đã chấm hết trả 4 điểm kỹ năng + overall trong [10, 90].
- Test mới xanh; full suite xanh; `ModuleStructureTest` xanh.

## Quality and Testing State

- Quality: not evaluated
- Testing: not started
