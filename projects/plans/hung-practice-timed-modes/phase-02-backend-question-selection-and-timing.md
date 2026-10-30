# Phase 2: Backend — chọn câu, đóng băng theo lô, ghim timing

Status: Not started
User stories: US-4 (nhiều câu khác nhau, ưu tiên chưa làm), US-3 / US-6 (timing ghim cho TIMED),
US-1 (catalog cho biết TIMED có dùng được không)
Tiêu chí §7: 2, 9 (chọn câu không trùng + ưu tiên chưa làm, timing ghim vào item)

## Requirements

- `begin` tạo tối đa `questionCount` item **khác nhau** cho mỗi dạng bài được chọn, ngẫu nhiên,
  ưu tiên câu học viên chưa từng có trong bất kỳ phiên practice nào; thiếu thì bù câu đã làm.
  Kho ít hơn số chọn → lấy hết, `totalItemCount` phản ánh tổng thật.
- Không dùng `RANDOM()` SQL; chọn trong Java bằng lớp thuần có `RandomGenerator` tiêm vào.
- Đóng băng nội dung theo lô: một truy vấn lấy nhiều câu kèm options (+ phần đánh giá), không
  còn 2 truy vấn / item trong lúc giữ khoá session.
- Phiên `TIMED`: ghim `preListenSeconds` (task-timing.json), `preRecordSeconds` (cột `prep` của template), `responseSeconds`
  (Score Template active) vào **mọi** item, kể cả dạng không ghi âm. `UNTIMED`: để null.
- Không có template active / template thiếu dạng bài → `start` TIMED bị từ chối (422), catalog
  báo `timedAvailable = false` + lý do; UNTIMED không bị ảnh hưởng.
- `PracticeTaskResponse` trả `timing` (null với UNTIMED).

## Design Constraints

- Ranh giới Modulith: practice chỉ gọi API ở gốc module (`com.pte.itembank.PracticeQuestionService`,
  `com.pte.scoretemplate.ScoreTemplateService`, facade mới ở `com.pte.attempt`), DTO ở `dto/`;
  không import `*.internal.*`. `ModuleStructureTest.modules_have_no_boundary_violations` phải xanh.
- Không có module nào phụ thuộc `practice` (media dùng `shared.practice.PracticeMediaBindingPort`),
  nên practice → attempt/scoretemplate không tạo vòng; xác nhận lại bằng `grep -rl "com.pte.practice"`
  ngoài thư mục `practice` trước khi merge.
- Mã dạng bài: so khớp qua `TaskTypeCodeCompatibility.normalizeTaskTypeKey` ở cả hai phía
  (`ScoreTemplateItemResponse.taskTypeKey` vs `PracticeSessionItem.taskCode`) — V40 đã đổi tên
  `FILL_BLANKS_*` nhưng không giả định mọi môi trường đã sạch.
- Giữ `findPublishedQuestion` / `findPublishedQuestionForEvaluation` (không xoá API công khai đang có).
- Trần ứng viên `PRACTICE_CANDIDATE_CAP = 500` / dạng bài (rủi ro thiên UUID nhỏ ghi ở plan.md).
- Diễn giải `prep` cho 5 dạng Speaking có audio giống đề thi: `preRecordSeconds` ghim = cột `prep` của
  template (preRecord, xem `SnapshotPinService.toPinnedItem`); FE chạy preListen → audio → prep → ghi.

## Related files

- `pte-api/app/src/main/java/com/pte/itembank/PracticeQuestionService.java`
- `pte-api/app/src/main/java/com/pte/itembank/internal/repository/QuestionRepository.java`
  (`findPublishedPracticeQuestionIdsByTaskTypeKey`, `findWithOptionsByPublicIdIn`)
- `pte-api/app/src/main/java/com/pte/itembank/dto/response/PracticeQuestionPin.java` (mới)
- `pte-api/app/src/main/java/com/pte/attempt/TaskTimingCatalog.java` (mới, facade công khai)
- `pte-api/app/src/main/java/com/pte/attempt/internal/config/TaskTimingConfig.java`
- `pte-api/app/src/main/java/com/pte/scoretemplate/ScoreTemplateService.java` (`getActive()`)
- `pte-api/app/src/main/java/com/pte/practice/internal/service/PracticeSessionItemService.java`
- `pte-api/app/src/main/java/com/pte/practice/internal/service/PracticeQuestionPicker.java` (mới)
- `pte-api/app/src/main/java/com/pte/practice/internal/service/PracticeTimingService.java` (mới)
- `pte-api/app/src/main/java/com/pte/practice/internal/repository/PracticeSessionItemRepository.java`
- `pte-api/app/src/main/java/com/pte/practice/internal/service/PracticeCatalogService.java`,
  `internal/controller/PracticeCatalogController.java`
- `pte-api/app/src/main/java/com/pte/practice/internal/dto/response/PracticeCatalogTaskResponse.java`,
  `PracticeTaskResponse.java`, `PracticeItemTimingResponse.java` (mới), `internal/mapper/PracticeSessionResponseMapper.java`

## Steps

1. **itembank:** thêm `List<UUID> findPublishedCandidateIds(String taskTypeKey)` dùng lại JPQL hiện có
   với `PageRequest.of(0, PRACTICE_CANDIDATE_CAP)`; thêm `List<PracticeQuestionPin>
   findPublishedQuestionsForPinning(Collection<UUID> publicIds)` dùng `findWithOptionsByPublicIdIn`
   + cùng bộ lọc với `findPublishedQuestionForEvaluation`, trả record gồm `PracticeQuestionContent`
   và `PracticeQuestionEvaluationContent`. Refactor `toContent`/evaluation mapping thành private helper dùng chung.
2. **attempt:** tạo `@Service TaskTimingCatalog` ở gốc `com.pte.attempt` với
   `OptionalInt preListenSecondsFor(String taskTypeCode)` gọi `TaskTimingConfig.timingForIfConfigured`.
3. **practice seen-set:** thêm query vào `PracticeSessionItemRepository`:
   `select distinct item.sourceQuestionPublicId from PracticeSessionItem item, PracticeSession owner
   where item.practiceSessionId = owner.id and owner.studentPublicId = :studentPublicId
   and item.taskCode in :taskCodes and item.sourceQuestionPublicId is not null and item.deleted = false`.
4. **Picker thuần:** `PracticeQuestionPicker` (`@Component`). Wiring (red-team #5): **không** đăng ký bean
   `RandomGenerator`; lớp có ctor công khai không tham số đánh `@Autowired` dùng `ThreadLocalRandom::current`
   (an toàn đa luồng), và ctor package-private `PracticeQuestionPicker(Supplier<RandomGenerator>)` cho test
   (`() -> new Random(42)`). API: `List<UUID> pick(List<UUID> candidates, Set<UUID> seen, int count)`
   — khử trùng, tách unseen/seen, xáo riêng từng nhóm (Fisher–Yates trên bản sao), nối unseen + seen, cắt `count`.
5. **Timing:** thêm `Optional<ScoreTemplateResponse> findActive()` vào `ScoreTemplateService`
   (`getActive()` ném `scoretemplate.internal.exception.NoActiveScoreTemplateException` — practice không
   được import lớp `internal` đó). `PracticeTimingService` (internal/service):
   `Map<String, PracticeItemTiming> activeTimings()` gọi `findActive()` một lần, rỗng → map rỗng
   (log warn), key = mã đã normalize; `preListenSeconds` lấy từ
   `TaskTimingCatalog`. Thêm `requireTimedAvailable(Collection<String> taskCodes)` ném
   `PracticeSessionException(422, PRACTICE_TIMED_MODE_UNAVAILABLE)` (hằng mới).
6. **start:** khi `effectiveTimingMode() == TIMED` gọi `timingService.requireTimedAvailable(...)` sau
   `catalogService.requireStartable` và trước khi lưu.
7. **createItemsIfNeeded (viết lại):** lấy tasks như cũ; `count = session.getQuestionCount() ?? PRACTICE_LEGACY_QUESTION_COUNT`;
   một lần lấy seen-set cho mọi task code; mỗi task: candidates → `picker.pick` → gom ID; một lần
   `findPublishedQuestionsForPinning(allIds)`; task nào 0 câu → `PRACTICE_CONTENT_NOT_READY` (giữ hành vi);
   tạo item với `orderIndex` chạy liên tục theo thứ tự task rồi thứ tự pick; `pinQuestionContent(item, pin)`
   nhận pin đã có thay vì tự truy vấn; nếu TIMED, `timings.get(normalize(task.code()))` → set 3 cột.
   `itemRepository.saveAll(items)` một lần.
   - **Constructor / fixture (red-team #5):** `PracticeQuestionPicker` và `PracticeTimingService` chỉ thêm vào
     ctor `@Autowired`; hai ctor tương thích (3 và 4 tham số) truyền `new PracticeQuestionPicker()` và `null` timing.
     Giữ **đường null-safe**: `practiceQuestionService == null` → tạo 1 item không nội dung / dạng bài như hiện nay
     (đúng cái `PracticeSessionServiceTest` đang dựa vào khi dựng `new PracticeSessionItemService(itemRepository,
     catalogService, answerValidationService)`), nên fixture đó không phải sửa. Cập nhật lời gọi 9 tham số trong
     `PracticeSessionItemServiceScoringTest.setUp` (thêm picker + timing `null`). `PracticeSessionService` nhận
     thêm `PracticeTimingService` ở ctor chính; giữ ctor 8 tham số hiện tại (dùng ở `PracticeSessionServiceTest`,
     `PracticeSessionServiceScoringTest`) gọi qua với `null` — `null` nghĩa là "TIMED không khả dụng".
   - **Template mất giữa `start` và `begin` (red-team #9):** trong `begin`, trước `createItemsIfNeeded`, nếu phiên
     TIMED mà `activeTimings()` thiếu bất kỳ dạng bài nào đã chọn → đặt `session.setTimingMode(UNTIMED)` (lưu cùng
     transaction, log warn + đếm qua `PracticeObservability` nếu có sẵn counter), rồi tạo item không timing.
     `begin` không bao giờ ném lỗi vì template, nên phiên không kẹt ở `OVERVIEW`; FE đọc `timingMode` từ response.
8. **Response:** record `PracticeItemTimingResponse(Integer preListenSeconds, int preRecordSeconds, int responseSeconds)` — javadoc ghi rõ `preRecordSeconds` chỉ là preRecord của template; `PinnedItem.prepSeconds` của đề thi = preListen + độ dài audio + preRecord, practice không gộp vì FE chờ audio phát xong (red-team #7);
   `PracticeTaskResponse` thêm `timing` (giữ constructor tương thích); mapper điền khi
   `session.effectiveTimingMode() == TIMED` và item có `responseSeconds`.
9. **Catalog:** `PracticeCatalogTaskResponse` thêm `boolean timedAvailable`, `String timedUnavailableReason`;
   thêm `PracticeCatalogService.getStudentCatalog()` (làm giàu bằng `activeTimings()`) và chỉ
   `PracticeCatalogController.get` dùng nó — `getCatalog()` mà mapper gọi mỗi response giữ nguyên,
   tránh thêm một truy vấn template vào mọi session read.
10. Chạy `ModuleStructureTest`; nếu Modulith báo dependency chưa khai báo, chỉ sửa bằng API gốc module, không mở `internal`.

## Tests to add

- `PracticeQuestionPickerTest` (seed `new Random(42)`): `pick_poolLargerThanCount_returnsDistinctIds`,
  `pick_unseenEnough_returnsOnlyUnseen`, `pick_unseenShort_fillsWithSeen`, `pick_poolSmallerThanCount_returnsWholePool`,
  `pick_duplicateCandidates_areDeduplicated`, `pick_sameSeed_isDeterministic`.
- `PracticeSessionItemServiceSelectionTest`: `createItemsIfNeeded_tenRequested_createsTenDistinctItems`,
  `createItemsIfNeeded_secondSession_prefersUnseen`, `createItemsIfNeeded_legacyNullCount_createsOnePerTask`,
  `createItemsIfNeeded_fetchesContentInOneBatch` (verify `findPublishedQuestionsForPinning` 1 lần,
  `findPublishedQuestion` 0 lần), `createItemsIfNeeded_timed_pinsTemplateAndPreListenTiming`,
  `createItemsIfNeeded_untimed_leavesTimingNull`, `createItemsIfNeeded_noCandidates_throwsContentNotReady`.
- `PracticeTimingServiceTest`: `activeTimings_noActiveTemplate_returnsEmpty`, `activeTimings_legacyTaskTypeKey_isNormalized`,
  `requireTimedAvailable_taskMissingFromTemplate_throwsUnavailable`.
- `PracticeSessionServiceTest.start_timedWithoutActiveTemplate_rejects422`,
  `begin_timedTemplateRemovedAfterStart_fallsBackToUntimedAndBegins` (red-team #9: status `IN_PROGRESS`,
  `timingMode = UNTIMED`, item không timing), `begin_legacyOverviewNullModeNullCount_beginsWithOneItemPerTask`
  (tiêu chí 8, red-team #10).
- Contract BE (red-team #7): `PracticeSessionResponseMapperTest.toResponse_timedItem_serializesPreRecordSeconds`
  — JSON có `preListenSeconds`, `preRecordSeconds`, `responseSeconds`, không có `prepSeconds`.
- `ScoreTemplateServiceTest.findActive_noActiveTemplate_returnsEmpty`.
- `PracticeQuestionServiceTest` (itembank, file đã có): `findPublishedQuestionsForPinning_filtersUnpublished`,
  `findPublishedCandidateIds_capsAtFiveHundred`.
- `TaskTimingCatalogTest.preListenSecondsFor_repeatSentence_returnsThree`, `..._readAloud_isEmpty`.
- `PracticeCatalogServiceTest.getStudentCatalog_taskMissingFromTemplate_marksTimedUnavailable`.
- `PracticeSessionResponseMapperTest.toResponse_timedItem_includesTiming`.
- Repository (H2 `@DataJpaTest`): `findSeenSourceQuestionIds_otherStudent_isExcluded`.

## Success criteria

- 10 câu Repeat Sentence khi kho ≥ 10: không trùng; phiên thứ hai ưu tiên câu chưa làm (unit + P7 tay).
- `begin` 50 câu chỉ phát sinh O(số dạng bài) truy vấn itembank, không O(số câu).
- Catalog cho FE biết TIMED có dùng được không cho từng dạng bài.
- `ModuleStructureTest`, suite `practice`, `itembank`, `attempt` xanh.

## Quality and Testing State

- quality: not evaluated
- testing: not started
