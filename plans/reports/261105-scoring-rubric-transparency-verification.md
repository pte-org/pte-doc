# Báo cáo xác minh: Rubric chấm điểm minh bạch và cấu hình được

Ngày: 2026-11-05. Kế hoạch: `pte-doc/projects/plans/quang-scoring-rubric-transparency` (Phase 1-11).
Nhánh: `quang/feat/maintain-v2` ở `pte-api`, `pte-web`, `pte-practice`, `pte-doc` (Phase 1-10 đã commit; worktree sạch lúc kiểm tra).
Số liệu máy đọc: [assets/261105-scoring-rubric-transparency-verification/phase11-final-verification-summary.json](assets/261105-scoring-rubric-transparency-verification/phase11-final-verification-summary.json)
(cùng thư mục có tóm tắt surefire của Phase 8, 9). Không lưu log thô.

## 1. Phạm vi và ranh giới đã kiểm tra

| Hạng mục | Đã chạy | Ghi chú |
|---|---|---|
| `pte-api` toàn suite `app` | Có (lần chạy cuối Phase 10, đọc lại 522 file `TEST-*.xml` ở Phase 11) | 4641 test, 0 failures, 0 errors, 73 skipped |
| Postgres IT của rubric | Có (Docker sẵn có ở Phase 8-10) | `RubricVersionMigrationPostgresTest` 12/12, Flyway áp V32 + V33 |
| Postgres IT khác (billing, notification, enrollment) | **Không** | 44 test bị bỏ qua vì cần `lifecycle.test.db.url`; không thuộc kế hoạch này |
| Spike AI (Gemini/Azure) | **Không** | 29 test bỏ qua: không có key. Độ ổn định LLM và tính đơn điệu Fluency trên WAV TTS **chưa có số đo** |
| FE `vendor-web`, `tenant-web`, `pte-practice` | Có (chạy lại ở Phase 11) | vitest, eslint, tsc |
| Trình duyệt, `next build` | **Không** | Theo yêu cầu người dùng |
| `/ck:quality --gate` | Chỉ Phase 1-2 | Phase 3-11: `skipped_by_user` |

Bộ đếm 73 test bỏ qua: 29 spike AI (`AllScorersSpikeTest` 12, `AzureGeminiSpikeTest` 5, `RubricSchemaSmokeSpikeTest` 3,
`RubricStabilitySpikeTest` 9), 44 Postgres IT ngoài phạm vi, 1 `ChatPromptSuiteLiveTest`.

## 2. Lệnh đã chạy và kết quả

```powershell
cd D:\GitHub\pte-org\pte-api
.\mvnw.cmd -pl app test            # Phase 10, build sạch; Phase 11 đọc lại XML: 4641 / 0 / 0 / 73
.\mvnw.cmd -pl app test -Dtest=ApiInventoryExportTest -Dinventory.out=<tạm>   # Phase 11: 285 endpoint REST, 3 STOMP

cd D:\GitHub\pte-org\pte-web
pnpm --filter vendor-web test      # 50 file, 303 passed
pnpm --filter tenant-web test      # 54 file, 649 passed
pnpm --filter vendor-web lint      # 0 lỗi, 2 cảnh báo no-img-element (questionbank, có từ trước)
pnpm --filter tenant-web lint      # sạch
pnpm --filter vendor-web typecheck # 1 lỗi, chỉ ở file sinh .next/types/validator.ts (có từ trước)
pnpm --filter tenant-web typecheck # 2 lỗi, chỉ ở .next/types/validator.ts (có từ trước)

cd D:\GitHub\pte-org\pte-practice
pnpm test:unit                     # 74 file, 636 passed
pnpm lint                          # 0 lỗi, 2 cảnh báo có từ trước
pnpm typecheck                     # 0 lỗi
```

Ratchet (trong toàn suite): `PackageDensityTest` 1, `SourceFileSizeTest` 1, `NoDirectClockAccessTest` 2, `ModuleStructureTest` 3,
`RubricScoreSingleSourceTest` 4: tất cả xanh. Bốn file allowlist trong `app/src/test/resources/architecture/` chỉ chứa chú thích (0 mục).
Lưu ý: lần chạy `ApiInventoryExportTest` ở Phase 11 ghi đè XML của chính test đó (vẫn xanh); không chạy lại toàn suite ở Phase 11.

## 3. Đối chiếu Success Criteria

| Tiêu chí (spec) | Bằng chứng | Kết luận |
|---|---|---|
| Trang luật chấm 22/22, mỗi tiêu chí có trang Pearson | `RubricCatalogCoverageTest` (`allTwentyTwoStandardTaskTypesHaveARubric`, `everyTraitHasNamesPagesAndALevelDescriptorForEveryLevel`), `RubricReadServiceTest.listsAll22TaskTypesOfTheActiveVersionWithItsNumbers` | Đạt (mức API/unit; màn A chưa xem trên trình duyệt) |
| Giải thích chênh lệch 0 so với snapshot | `ScoreExplanationServiceTest.aPublishedAttemptIsReadFromItsSnapshotWithZeroDifferenceAcrossTheWholeFixture`, `publishedExaminerTraitsAreExplainedWithZeroDifferenceAndRemainFrozen`, `ExaminerTraitSnapshotTest` (16) | Đạt trên fixture unit phủ 22 task type; **chưa** kiểm trên lượt thi thật qua Postgres IT |
| Mô phỏng 100% khớp scorer, gồm cổng 7 task type | `ScorerSimulatorParityTest` (14, `allSevenGatedTasksMatch...`), `ScorerSimulatorPipelineParityTest` (10), `RubricSimulationServiceTest` (10) | Đạt |
| Hồi quy ví dụ Pearson | `RubricScorerGoldenTest`: `essayOf50Words_hasFormZero_andScoresZeroByTheFormGate`, `essayOf150Words_hasFormOne_andScores62`, `describeImageWithContentZero_scoresZeroByTheContentGate`; `FormRuleBandTest` 42 | Đạt (essay < 120 chữ kiểm bằng ca 50 chữ) |
| Đổi rubric không đổi snapshot đã publish | Điểm công bố đọc từ snapshot bất biến (`ReportSnapshotCodecTest`, `ScoreExplanationServiceTest`, `ExaminerTraitSnapshotTest` "remain frozen"); ghim phiên bản: `PinnedRubricParametersServiceTest`, `ExamDefinitionRubricPinTest`, `HostExamTemplateRubricPinTest` | Đạt gián tiếp: không có một test riêng "kích hoạt phiên bản mới rồi so snapshot" |
| Đổi mặc định trong code không đổi rubric hiệu lực của phiên bản đã có | `DefaultsDoNotChangeEffectiveRubricTest` (3), `RubricSeedParityTest` (7), `RubricReadServiceTest.weightsShownAreTheStoredOnesNotTheCodeDefaults` | Đạt |
| Tính lại 0 lời gọi vendor | `RubricRescoreServiceTest.theRescorePathHasNoDependencyOnAnyVendorClient`, `theAnswersOwnPinnedVersionIsUsedNotTheCodeDefaults` | Đạt (kiểm bằng phụ thuộc/mock) |
| Cách ly tenant và giám khảo không được phân công | `ScoreExplanationAccessTest` (13: Host tenant khác 404, Examiner tenant khác 404, Examiner không được phân công 404, role khác bị từ chối), `ScoreExplanationControllerTest` (11) | Đạt |
| Độ ổn định LLM >= 90% (20 bài x 3 lần) | Công cụ: `StabilityMetricsTest` 11, `SyntheticDatasetTest` 8, `MedianOfThreeScoringTest` 11; spike `RubricStabilitySpikeTest` **bị bỏ qua** | **Chưa đạt: chưa có số đo** (không có key Gemini) |
| p95 giải thích < 800 ms | `ScoreExplanationServiceTest.p95StaysUnder800MillisecondsOnTheFixture` | Đạt trên fixture, không có DB/HTTP |
| p95 mô phỏng < 300 ms | `fixtureLatencyP95Below300msWithoutADatabase` | Đạt trên fixture, không có DB/HTTP |
| p95 API đọc luật chấm < 300 ms | Không có phép đo | **Chưa đo** |
| Các API luật chấm/mô phỏng/giải thích không gọi AI | `contentGateAndTraceComeFromTheScorerWithoutWritingOrReadingExamData`, `aDraftPinIsNeverShownAndTheLivePathCallsNothingButTheScoringReadModel` | Đạt |

Postgres IT rubric (`RubricVersionMigrationPostgresTest`, 12): seed đúng một bản ACTIVE v1 cho 22 task type, backfill mẫu đề,
cột ghim nullable, chặn ACTIVE thứ hai, trigger bất biến cho bản RETIRED, audit chỉ được thêm, thứ tự retire-rồi-activate trong
một giao dịch (thứ tự ngược thất bại). Không có test kích hoạt đồng thời hai luồng riêng ở mức Postgres.

## 4. Ba giới hạn bắt buộc nêu rõ

1. **Bảng Azure -> 0-5 (v1) chưa hiệu chỉnh với dữ liệu người chấm.** Nhãn "chưa hiệu chỉnh" hiển thị ở API luật chấm
   (`aTraitScoredSpeakingTaskShowsTraitsLevelsGateAndTheUncalibratedAzureLabel`), vendor-web và tenant-web. Điểm Pronunciation/Oral Fluency
   của câu nói là ước lượng.
2. **Bộ dữ liệu kiểm tra là dữ liệu tổng hợp do AI tạo** (20 bài viết, 20 transcript nói). Nó chỉ dùng để đo độ ổn định, không chứng minh
   độ chính xác chấm. Ngay cả độ ổn định hiện **chưa đo**.
3. **WAV TTS chỉ dùng để kiểm tra tính đơn điệu của Fluency** (nhiều ngập ngừng hơn thì điểm không cao hơn). Phép kiểm này **chưa chạy**.

## 5. Thay đổi hoặc lệch so với kế hoạch

- Provider: **phương án B**. `openai-compatible` và `stub` không có scorer rubric; câu thuộc task type rubric (SWT, WE, SST, RA, RS, DI, RL,
  RTS, SGD, ASQ) fail closed với `AI_RUBRIC_SCORER_UNAVAILABLE`. Hệ quả: môi trường local dùng `stub` sẽ làm các câu đó chấm thất bại
  cho tới khi cấu hình `azure-gemini`.
- Câu hỏi mở 2 (Spelling của Write Essay do LLM đếm): giữ nguyên; chưa có số liệu dao động vì spike chưa chạy.
- Phase 6: vết điểm câu đi qua facade `RubricTraceService` thay vì thêm vào `ScoringService`.
- Phase 7: màn giải thích tenant-web không có cột "đóng góp" riêng từng tiêu chí.
- Phase 10: các component màn giám khảo được gộp, chuỗi hiển thị nằm trong `traitText.ts`; không có nút "dùng điểm máy" cho từng tiêu chí;
  `ExaminerTraitSubmitIT` không viết, thay bằng unit test (`ExaminerTraitCommandTest`, `ExaminerTraitValidatorTest`, `ExaminerTraitScoreResolverTest`, `ExaminerTraitSnapshotTest`).
- Quality gate chỉ chạy Phase 1-2; Phase 3-11 người dùng chọn bỏ qua.

## 6. Việc tồn đọng

1. Chạy `RubricSchemaSmokeSpikeTest`, `RubricStabilitySpikeTest`, `AllScorersSpikeTest` với key Gemini/Azure thật; ghi số đo vào
   [báo cáo spike](261105-scoring-rubric-llm-stability-spike-report.md). Nếu < 90%: bật trung vị 3 lần cho tiêu chí không ổn định.
2. Hiệu chỉnh bảng Azure khi có dữ liệu người chấm.
3. Xem màn A, B, C, D1 và màn giám khảo trên trình duyệt; chạy `next build`.
4. Đo p95 API đọc luật chấm; cân nhắc Postgres IT cho luồng giải thích và nộp điểm tiêu chí của giám khảo.
5. Sửa lỗi tsc cũ ở `.next/types/validator.ts` (do trang đã xóa còn trong type sinh ra).

## 7. Ghi chú vận hành

- **Thêm task type hoặc đổi mô tả mức**: sửa catalog trong `com.pte.scoring.rubric` (`internal/rubric/catalog/*`), tăng `catalogVersion`,
  rồi tạo phiên bản rubric mới (nháp -> kích hoạt trên vendor-web). Phiên bản cũ giữ nguyên tham số đã vật chất hóa.
- **Đổi model Gemini**: chạy lại smoke schema và spike ổn định (`SCORING_AI_SPIKE=true`, key thật) trước khi dùng.
- **Hiệu chỉnh bảng Azure**: tạo `azureBandMappingVersion` mới trong code, rồi tạo phiên bản rubric mới trỏ tới nó và kích hoạt;
  mẫu đề đã ghim phiên bản cũ không bị đổi. Chỉ bỏ nhãn "chưa hiệu chỉnh" khi có dữ liệu người chấm.
- Tính lại điểm sau khi đổi rubric không gọi AI; chấm lại câu thất bại dùng `POST /api/v1/sessions/{sessionPublicId}/score`.
