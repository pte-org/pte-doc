# Phase 1: Backend — V133, chế độ phiên, bỏ deadline chung

Status: Not started
User stories: US-1 (trường request, bỏ đồng hồ 60 phút), US-8 (phiên cũ vẫn mở được)
Tiêu chí §7: 1 (phần BE), 3 (không còn hạn phiên), 8, 9 (mặc định chế độ, hash idempotency)

## Requirements

- `PracticeSessionStartRequest` nhận thêm `timingMode` (`TIMED` | `UNTIMED`, mặc định `UNTIMED`)
  và `questionCount` (1–50, mặc định 10); thiếu thì áp mặc định, không phá client cũ.
- Phiên lưu `timing_mode`, `question_count`; item có 3 cột timing nullable (dùng ở phase 2).
- Không còn hạn chung: `begin` không đặt `deadlineAt`, phiên mới có `timeLimitSeconds = 0`.
- Phiên cũ (trước V133) không có `timing_mode` → coi là `UNTIMED`; phiên `OVERVIEW`/`IN_PROGRESS`
  cũ được xoá `deadline_at` để không bị `EXPIRED` khi mở.
- `startRequestHash` gồm `timingMode` và `questionCount` **sau khi áp mặc định**.
- Link tạm của audio/ảnh đề không còn suy ra từ giới hạn phiên.
- Response session trả `timingMode` và `questionCount`.

## Design Constraints

- Layout module `practice`: enum mới ở `internal/domain/enums`, hằng/mã lỗi ở `PracticeConstants`.
- Không đổi `int timeLimitSeconds` sang `Integer` (quyết định D1 trong plan.md); giữ field trên
  wire với giá trị `0`, `deadlineAt` luôn `null` cho phiên mới.
- Migration chỉ thêm cột/ràng buộc và một `UPDATE` có điều kiện; không `DROP`, không đụng
  phiên `EXPIRED`/`COMPLETED`/`DISCARDED`.
- Test chạy H2 với Flyway tắt (`app/src/test/resources/application.yml`), schema sinh từ entity
  → mọi cột mới phải khai báo trên entity, nullable đúng như SQL.
- Kiểm số V cao nhất trên `origin/dev` trước khi tạo file; hiện local cao nhất là V132.

## Related files

- `pte-api/app/src/main/resources/db/migration/V133__practice_timing_mode.sql` (mới)
- `pte-api/app/src/main/java/com/pte/practice/internal/domain/enums/PracticeTimingMode.java` (mới)
- `pte-api/app/src/main/java/com/pte/practice/internal/domain/PracticeSession.java`
- `pte-api/app/src/main/java/com/pte/practice/internal/domain/PracticeSessionItem.java`
- `pte-api/app/src/main/java/com/pte/practice/internal/dto/request/PracticeSessionStartRequest.java`
- `pte-api/app/src/main/java/com/pte/practice/internal/dto/response/PracticeSessionResponse.java`
- `pte-api/app/src/main/java/com/pte/practice/internal/mapper/PracticeSessionResponseMapper.java`
- `pte-api/app/src/main/java/com/pte/practice/internal/service/PracticeSessionService.java`
- `pte-api/app/src/main/java/com/pte/practice/internal/service/PracticeCatalogService.java` (`getCatalog` dùng `PRACTICE_TIME_LIMIT_SECONDS`)
- `pte-api/app/src/main/java/com/pte/practice/internal/constant/PracticeConstants.java`
- `pte-api/app/src/main/java/com/pte/practice/PracticeMediaBindingService.java`
- Test: `PracticeSessionServiceTest`, `PracticeSessionResponseMapperTest` (đang assert TTL > 3600),
  `PracticeMediaBindingServiceTest`, `PracticeMigrationVersionTest`

## Steps

1. `git fetch && git ls-tree origin/dev app/src/main/resources/db/migration` — xác nhận chưa có V133;
   nếu có, lấy số kế tiếp và đổi tên ở mọi chỗ trong plan/test.
2. Viết `V133__practice_timing_mode.sql`:
   - `ALTER TABLE practice_sessions ADD COLUMN IF NOT EXISTS timing_mode VARCHAR(16)`,
     `ADD COLUMN IF NOT EXISTS question_count INTEGER`;
     `ALTER COLUMN time_limit_seconds SET DEFAULT 0`.
   - `ADD CONSTRAINT ck_practice_sessions_timing_mode CHECK (timing_mode IS NULL OR timing_mode IN ('TIMED','UNTIMED'))`
     và `ck_practice_sessions_question_count CHECK (question_count IS NULL OR question_count BETWEEN 1 AND 50)`.
   - `ALTER TABLE practice_session_items ADD COLUMN IF NOT EXISTS pre_listen_seconds INTEGER,
     ADD COLUMN IF NOT EXISTS pre_record_seconds INTEGER, ADD COLUMN IF NOT EXISTS response_seconds INTEGER`.
   - `UPDATE practice_sessions SET deadline_at = NULL WHERE status IN ('OVERVIEW','IN_PROGRESS') AND deadline_at IS NOT NULL`.
   - Comment `-- Rollback policy: columns are additive; restoring deadlines is not required (practice is unstaked).`
3. Tạo enum `PracticeTimingMode { TIMED, UNTIMED }`.
4. `PracticeSession`: thêm `@Enumerated(STRING) @Column(name="timing_mode", length=16) timingMode`,
   `@Column(name="question_count") Integer questionCount`, và `effectiveTimingMode()` trả `UNTIMED`
   khi null (dùng ở mapper/service, không dùng getter thô).
5. `PracticeSessionItem`: thêm `Integer preListenSeconds`, `preRecordSeconds`, `responseSeconds` (tên `preRecord`, không `prep` — red-team #7)
   (cột tương ứng, nullable). Chưa ghi ở phase này.
6. `PracticeConstants`: thêm `PRACTICE_DEFAULT_QUESTION_COUNT = 10`, `PRACTICE_MAX_QUESTION_COUNT = 50`,
   `PRACTICE_LEGACY_QUESTION_COUNT = 1`, `PRACTICE_NO_SESSION_TIME_LIMIT_SECONDS = 0`,
   mã/tin lỗi `PRACTICE_QUESTION_COUNT_INVALID`; thay `PRACTICE_TIME_LIMIT_SECONDS` và đặt
   `PRACTICE_PROMPT_MEDIA_TTL_SECONDS = 900L` độc lập (javadoc: bằng trần ký của media; FE tải lại
   session khi link hết hạn).
7. `PracticeSessionStartRequest`: thêm `PracticeTimingMode timingMode`,
   `@Min(1) @Max(50) Integer questionCount` (message từ hằng) và hai accessor
   `effectiveTimingMode()` / `effectiveQuestionCount()` áp mặc định.
8. `PracticeSessionService.start`: set `timingMode`/`questionCount` đã áp mặc định,
   `setTimeLimitSeconds(PRACTICE_NO_SESSION_TIME_LIMIT_SECONDS)`; `startRequestHash` nối thêm
   `effectiveTimingMode().name()` và `effectiveQuestionCount()`.
9. `PracticeSessionService.begin`: xoá `session.setDeadlineAt(...)`. Giữ nguyên `expireIfNeeded`,
   `requireLiveInProgress`, `heartbeat`, `saveAndExit`, `isPastDeadline` (null = không hết hạn).
10. `PracticeCatalogService.getCatalog`: truyền `PRACTICE_NO_SESSION_TIME_LIMIT_SECONDS` cho
    `timeLimitSeconds` (javadoc "deprecated, always 0").
11. `PracticeSessionResponse`: thêm `PracticeTimingMode timingMode`, `Integer questionCount`; cập nhật
    `withItemResult`; mapper điền `session.effectiveTimingMode()` và `questionCount`.
12. Cập nhật test hiện có bị ảnh hưởng (mapper TTL, fixture dùng `PRACTICE_TIME_LIMIT_SECONDS`).

## Tests to add

- `PracticeSessionServiceTest`
  - `start_withoutTimingFields_defaultsToUntimedAndTenQuestions`
  - `start_sameKeyOmittedVsExplicitDefaults_returnsSameSession` (hash bằng nhau)
  - `start_sameKeyDifferentTimingMode_throwsIdempotencyReused`
  - `start_sameKeyDifferentQuestionCount_throwsIdempotencyReused`
  - `start_newSession_storesZeroTimeLimit`
  - `begin_overviewSession_leavesDeadlineNull`
  - `heartbeat_nullDeadlineFarInFuture_staysInProgress`, `answer_nullDeadline_isAccepted`,
    `saveAndExit_nullDeadline_doesNotExpire`, `get_legacyInProgressWithPastDeadline_expires` (giữ hành vi)
  - Tiêu chí 8 (red-team #10): `answer_legacyInProgressNullModeNullDeadline_isAcceptedAsUntimed`
    (phiên `timingMode = null`, `questionCount = null`, `deadlineAt = null` như sau V133 nhận câu trả lời và
    response báo `UNTIMED`). Ca "phiên `OVERVIEW` cũ begin ra 1 item" nằm ở P2 vì logic tạo item ở đó.
- `PracticeMediaBindingServiceTest.assertCanUseResponseAudio_nullDeadline_allowsUpload`
- `PracticeSessionResponseMapperTest.toResponse_legacySessionWithoutTimingMode_reportsUntimed`,
  `toResponse_promptMedia_usesStandaloneTtl` (thay assert `> 3600`)
- `PracticeMigrationVersionTest.timingModeMigrationIsAdditiveAndClearsLiveDeadlines`: chứa
  `timing_mode VARCHAR(16)`, `question_count INTEGER`, `pre_listen_seconds`, `pre_record_seconds`, `status IN ('OVERVIEW','IN_PROGRESS')`,
  `-- Rollback policy`, không chứa `DROP TABLE`/`DROP COLUMN`.
- Bean Validation: `PracticeSessionStartRequestTest.questionCount_outOfRange_isRejected` (0, 51).

## Success criteria

- Suite `com.pte.practice.*` và `ModuleStructureTest` xanh.
- Request start không có trường mới vẫn tạo phiên `UNTIMED`, 10 câu, `deadlineAt = null` sau `begin`.
- V133 chạy được trên DB local có phiên cũ (kiểm ở P7): phiên `IN_PROGRESS` cũ mở lại không bị `EXPIRED`.

## Quality and Testing State

- quality: not evaluated
- testing: not started
