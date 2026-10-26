# Báo cáo chạy lại toàn bộ test maintainability (2026-10-26)

**Kết quả: PASS.** Chạy lại sau bản sửa của người dùng, chỉ kiểm thử và ghi báo cáo.

| Lượt | Kết quả | Tests / failures / errors / skipped | Exit | Giây |
|---|---|---|---:|---:|
| unit | PASS | 2865 / 0 / 0 / 58 | 0 | 113.15 |
| postgres | PASS | 2865 / 0 / 0 / 16 | 0 | 159.29 |

- 29/29 invocation từng lỗi đã tìm thấy và PASS trong cả hai lượt; không tính test bị skip là đã sửa.
- Bộ mặc định bỏ các biến INBOX_TEST_DB_* và không bật AI spike. Bộ Postgres đặt DB URL/role theo runbook và system property lifecycle.test.db.url; không ghi mật khẩu hoặc env ra log.
- Docker Desktop ban đầu chưa chạy; đã mở Docker Desktop và khởi động đúng container pte-test-pg. Xác nhận DB lifecycle_test, role lifecycle/inbox và schema migration_clean có Flyway V1 success. Không xóa container/volume.
- Maven tự compile/test-compile theo thay đổi; không chạy riêng bước clean compile. Ba ratchet chạy trong cả hai bộ test đầy đủ; không thay allowlist.
- Phạm vi lần này là hai lượt test được yêu cầu, tương ứng bước 3 và 5 của plan cũ. Không chạy lại audit quality độc lập hoặc full application boot; không dùng kết quả này để tuyên bố chất lượng production hay mọi Spring bean đều khởi động được.
- Bảo toàn source: PASS. So SHA-256 các tracked file với thời điểm bắt đầu lần rerun. Giữ nguyên 9 file Java người dùng đã sửa; không commit/push, không sửa code hoặc test.

## Lệnh và bằng chứng

```powershell
mvnw.cmd -pl app test
```

- [Log unit](assets/261026-quang-api-maintainability-cleanup-test-report/rerun-20261026-095920/qa-unit.log.gz) · [Kết quả lệnh](assets/261026-quang-api-maintainability-cleanup-test-report/rerun-20261026-095920/unit-result.json) · [Testcase JSON](assets/261026-quang-api-maintainability-cleanup-test-report/rerun-20261026-095920/unit-tests.json)

```powershell
mvnw.cmd -pl app test -Dlifecycle.test.db.url=jdbc:postgresql://127.0.0.1:55439/lifecycle_test?currentSchema=migration_clean
```

- [Log postgres](assets/261026-quang-api-maintainability-cleanup-test-report/rerun-20261026-095920/qa-postgres.log.gz) · [Kết quả lệnh](assets/261026-quang-api-maintainability-cleanup-test-report/rerun-20261026-095920/postgres-result.json) · [Testcase JSON](assets/261026-quang-api-maintainability-cleanup-test-report/rerun-20261026-095920/postgres-tests.json)

## Đối chiếu 29 invocation từng lỗi

| Test | Trước đây | Mặc định | Postgres |
|---|---|---|---|
| `com.pte.attempt.internal.service.AttemptLifecycleServicePlayAudioTest.playAudio_audioUrlExpired_throws` | R3 | PASS | PASS |
| `com.pte.attempt.internal.service.HeartbeatServiceTest.recordHeartbeat_stampsLastSeenAt` | R3 | PASS | PASS |
| `com.pte.attempt.internal.service.TimerServiceTest.startTask_enteringReadingAfterAnotherSection_startsFreshSectionClock` | R3 | PASS | PASS |
| `com.pte.attempt.internal.service.TimerServiceTest.startTask_firstReadingItem_setsActiveSectionAndStartsSectionClock` | R3 | PASS | PASS |
| `com.pte.proctoring.internal.service.IncidentEvidenceServiceTest.standardPolicy_recordsAnAutoIncidentWithWarningAndServerOwnership` | R3 | PASS | PASS |
| `com.pte.scoring.internal.service.examiner.ExaminerScoringServiceTest.acceptsInclusiveScoreBoundariesAndKeepsOtherScoresUntouched(int)[1]` | R1 | PASS | PASS |
| `com.pte.scoring.internal.service.examiner.ExaminerScoringServiceTest.acceptsInclusiveScoreBoundariesAndKeepsOtherScoresUntouched(int)[2]` | R1 | PASS | PASS |
| `com.pte.session.internal.service.ExamWorkflowServicesTest.createDraft_defaultsOfficialExamToStartedSeriesExclusion` | R3 (nghi nguyên nhân) | PASS | PASS |
| `com.pte.session.internal.service.ExamWorkflowServicesTest.updateDraft_rescheduleKeepsSessionCode` | R3 (nghi nguyên nhân) | PASS | PASS |
| `com.pte.session.internal.service.ExamWorkflowServicesTest.createDraft_partialSkillSelection_isRejected` | R3 (nghi nguyên nhân) | PASS | PASS |
| `com.pte.session.internal.service.ExamWorkflowServicesTest.createDraft_withRetries_isRejectedBecauseEveryStudentSitsOnce` | R3 (nghi nguyên nhân) | PASS | PASS |
| `com.pte.session.internal.service.ExamWorkflowServicesTest.createDraft_officialWithNonStrictLockdown_isRejected` | R3 (nghi nguyên nhân) | PASS | PASS |
| `com.pte.session.internal.service.ExamWorkflowServicesTest.updateDraft_legacyDraftWithoutModeOrLockdown_derivesOfficialStrictDefault` | R3 (nghi nguyên nhân) | PASS | PASS |
| `com.pte.session.internal.service.ExamWorkflowServicesTest.updateDraft_withoutLockdown_preservesStrictAfterRetryPatch` | R3 (nghi nguyên nhân) | PASS | PASS |
| `com.pte.session.internal.service.SessionLifecycleServiceTest.create_translatesDatabaseOverlapRaceToConflict` | R3 (nghi nguyên nhân) | PASS | PASS |
| `com.pte.session.internal.service.SessionLifecycleServiceTest.create_delegatesToAssessmentGenerateAndPublish_usesReturnedSnapshotPublicId` | R3 (nghi nguyên nhân) | PASS | PASS |
| `com.pte.session.internal.service.SessionLifecycleServiceTest.changeSubscription_rejectsActualEnrollmentCountAboveNewCap` | R3 (nghi nguyên nhân) | PASS | PASS |
| `com.pte.session.internal.service.SessionLifecycleServiceTest.patchPolicy_isRejected_whenScheduledWindowHasAlreadyStarted` | R3 | PASS | PASS |
| `com.pte.session.internal.service.SessionLifecycleServiceTest.changeSubscription_updatesSessionAndAllEnrollmentLicenseKeys` | R3 (nghi nguyên nhân) | PASS | PASS |
| `com.pte.session.internal.service.SessionLifecycleServiceTest.create_rejectsWindowOutsideSubscription_asUnprocessable` | R3 (nghi nguyên nhân) | PASS | PASS |
| `com.pte.session.internal.service.SessionLifecycleServiceTest.create_rejectsApplicationLevelOverlap_withConflictingSession` | R3 (nghi nguyên nhân) | PASS | PASS |
| `com.pte.session.internal.service.SessionLifecycleServiceTest.create_persistsGeneratedSnapshotAndSubscriptionLicense` | R3 (nghi nguyên nhân) | PASS | PASS |
| `com.pte.session.internal.service.SessionLifecycleServiceTest.create_rejectsCapacityAboveSubscriptionCap_withBothValues` | R3 (nghi nguyên nhân) | PASS | PASS |
| `com.pte.session.internal.service.SessionLifecycleServiceTest.create_allowsSameWindowForDifferentSubscription` | R3 (nghi nguyên nhân) | PASS | PASS |
| `com.pte.session.internal.service.SessionLifecycleServiceTest.create_setsLockdownModeToStrict_whenExamModeIsRealExam` | R3 (nghi nguyên nhân) | PASS | PASS |
| `com.pte.session.internal.service.SessionLifecycleServiceTest.changeSubscription_requestsSubscriptionLocksInPublicIdOrder` | R3 (nghi nguyên nhân) | PASS | PASS |
| `com.pte.session.internal.service.SessionLifecycleServiceTest.create_withoutExamMode_defaultsToOfficialStrict` | R3 (nghi nguyên nhân) | PASS | PASS |
| `com.pte.session.internal.service.SessionLifecycleServiceTest.create_withTeacherOverride_nonStrictOnOfficial_rejectedBeforeSave` | R3 (nghi nguyên nhân) | PASS | PASS |
| `com.pte.session.internal.service.SessionLifecycleServiceTest.create_generationFails_noSessionSaved` | R3 / Mockito (nghi nguyên nhân) | PASS | PASS |

## Ratchet trong toàn bộ suite

| Lượt | Lớp | Tests / failures / errors / skipped |
|---|---|---|
| unit | `com.pte.architecture.NoDirectClockAccessTest` | 2 / 0 / 0 / 0 |
| unit | `com.pte.architecture.PackageDensityTest` | 1 / 0 / 0 / 0 |
| unit | `com.pte.architecture.SourceFileSizeTest` | 1 / 0 / 0 / 0 |
| postgres | `com.pte.architecture.NoDirectClockAccessTest` | 2 / 0 / 0 / 0 |
| postgres | `com.pte.architecture.PackageDensityTest` | 1 / 0 / 0 / 0 |
| postgres | `com.pte.architecture.SourceFileSizeTest` | 1 / 0 / 0 / 0 |

## Lỗi mới

Không có failure/error.

## Tài liệu và giới hạn

- [Summary JSON](assets/261026-quang-api-maintainability-cleanup-test-report/rerun-20261026-095920/summary.json) · [Đối chiếu lỗi cũ](assets/261026-quang-api-maintainability-cleanup-test-report/rerun-20261026-095920/previous-failures-comparison.json) · [Bảo toàn file](assets/261026-quang-api-maintainability-cleanup-test-report/rerun-20261026-095920/preservation-check.json)
- [Báo cáo lần đầu](261026-quang-api-maintainability-cleanup-test-report.md) giữ lại bằng chứng 15 failure + 14 error trước bản sửa.
- Test bị skip không được coi là PASS. Không bật 16 AI spike cần khóa/chi phí thật. Không chạy trên production; kiểm tra này giới hạn ở code hiện tại, môi trường test local và DB dedicated.
- Snapshot ban đầu và cuối nằm cùng thư mục assets; log đã lọc giá trị nhạy cảm, JSON không sao chép Surefire system properties.

> L?u trong Git: b?o c?o, k?t qu? JSON c?n cho ??i chi?u v? log l?n ?? n?n gzip. Snapshot hash ??y ??, diff tr?ng l?ch s? Git, log th? v? script ch?y m?t l?n gi? local; kh?ng ph?i n?i dung commit.
