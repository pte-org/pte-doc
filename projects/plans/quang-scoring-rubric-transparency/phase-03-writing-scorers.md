# Phase 3: Scorer viết (SWT, WE, SST) theo rubric

## Mục tiêu

Chuyển ba task type viết chấm bằng Gemini sang rubric: prompt dựng từ mô tả mức của catalog, Gemini chỉ trả **điểm từng tiêu chí theo thang Pearson** (số nguyên 0..max, `temperature 0`), Form tính hoàn toàn bằng mã
(`FormCheck` tính metrics rồi gọi `FormRule.bandFor`), điểm câu do `RubricScorer` tính từ tham số của hàng phiên bản, điểm tiêu chí lưu theo thang Pearson có **dấu `scale`**. Phase mở đầu bằng smoke schema 1 giờ để chốt biến thể schema.
Sửa L1, L3, L4, L5, L10 cho SWT, WE, SST.

## Stories/FR covered

- S2; FR-03 (prompt từ rubric, fail closed), FR-05 (lưu điểm tiêu chí thang Pearson), FR-06: L1, L3, L4, L5, L10

## Files to read first

- `D:\GitHub\pte-org\docs\CODING_STANDARDS_API.md`
- `pte-api/app/src/main/java/com/pte/scoring/internal/vendor/gemini/scorer/GeminiWritingScorer.java`, `SummarizeWrittenTextScorer.java`, `WriteEssayScorer.java`, `SummarizeSpokenTextScorer.java`, `GeminiScorers.java`
  (`score()` 0-100 làm tròn; `GUARD`; `quoted`; schema helper)
- `.../gemini/FormCheck.java`, `GeminiRestClient.java` (dòng ~86: `temperature 0`, `responseMimeType`, `responseSchema`), `GeminiRequest.java`
- `.../scoring/internal/vendor/AiScoringRequest.java`, `AiScoreResult.java`, `AiAnswerScorer.java`
- `.../messaging/consumer/AiScoringWorker.java` (`callVendor` ~147; rơi về client chung khi không có scorer), `.../service/ai/AiScoringResultPersistenceService.java` (`persistAiScore`), `PracticeAiScoringService.java` (~123-150)
- Chấm lại câu thất bại có sẵn: `.../internal/controller/ScoringCommandController.java` (`POST /api/v1/sessions/{sessionPublicId}/score`), `.../service/ScoringCommandService.java`, `AiEvaluationRepository.findScoringWork`, `AiEvaluation.isRescorable`, `application.yml` (`scoring.ai.stale-dispatch-minutes`, dòng ~221)
- Test: `GeminiWritingScorersTest`, `GeminiScorersTest`, `FormCheckTest`, `AiScoringWorkerTest`, `AllScorersSpikeTest`, `SpikeSupport`
- `D:\GitHub\pte-org\docs\CODING_STANDARDS_WEB.md`; `pte-practice/features/practice/ScoreView.tsx`, `session/InlineResultCard.tsx`, `session-contracts.ts`; backend `PracticeScoringStateService`, `PracticeItemResultResponse`, `AiScoreDetailQueryService`
- Phase 1 (catalog, `RubricScorer`, `FormRule`), Phase 2 (`RubricResolver`, `RubricVersionService`)

## Implementation steps

1. **Smoke schema Gemini (đầu phase, ~1 giờ, MEDIUM-5)**: gọi thật `GeminiRestClient` với 3 biến thể `responseSchema` cho một tiêu chí thang 0-6: (a) INTEGER có `enum`, (b) INTEGER có `minimum/maximum`, (c) STRING enum "0".."6". Ghi: có chấp nhận schema không, có trả đúng kiểu/miền không (10 lần mỗi biến thể, một bài mẫu tổng hợp).
   **Chốt biến thể trong phase này** (ưu tiên a, rồi b, rồi c) và cập nhật `RubricSchemaBuilder`; Phase 4 không đổi schema nữa. Kiểm tra Java luôn bắt buộc bất kể biến thể.
2. **Đưa rubric vào đầu vào scorer**: `AiScoringRequest` thêm `EffectiveRubric` và `rubricVersionPublicId` (giữ `toString` chỉ in task type). `AiScoringWorker.callVendor` resolve phiên bản theo `AiEvaluation.examDefinitionPublicId` qua `RubricResolver` **tại thời điểm thực thi job**
   (job xếp hàng trước đó vẫn dùng phiên bản ghim của mẫu đề, không phụ thuộc thời điểm xếp hàng); `PracticeAiScoringService` dùng bản ACTIVE. Task type có rubric mà không resolve được -> thất bại `AiFailureReason` phù hợp (mã trong `ScoringConstants`), không rơi về client chung.
3. **Form bằng mã** (L3, L4, MEDIUM-6): `FormCheck` chỉ **tính `TextMetrics`** (số từ, số câu, toàn chữ hoa, có dấu câu, chỉ gạch đầu dòng/câu rất ngắn — tái dùng bộ đếm hiện có) rồi gọi `FormRule.bandFor`; xóa các hằng 200/300/50/70/40/100/5/75 và `modelScoresForm`;
   LLM không bao giờ được hỏi Form (schema không có trường `form`). Giới hạn số chữ riêng của item (`minWordCount/maxWordCount`) không còn quyết định band của task type chuẩn (rubric quyết định); ghi trong test.
4. **Prompt và schema dựng từ catalog** (L10): `RubricPromptBuilder`, `RubricSchemaBuilder` ở gói mới `com.pte.scoring.internal.rubric.prompt` (không thêm vào `vendor/gemini/scorer`, 9 file). Prompt hệ thống gồm vai trò giám khảo, **mô tả từng mức 0..max của tiêu chí AI_LLM lấy nguyên văn từ catalog**,
   `GUARD`; bài làm và đề đi qua `quoted`. Giữ `feedback` và `errors`.
5. **Fail closed có thử lại giới hạn** (HIGH-4): thay `GeminiScorers.score(content, field)` (0-100, làm tròn) bằng bộ đọc điểm tiêu chí: thiếu trường, không phải số, không nguyên hoặc ngoài [0, max] là **vi phạm schema**. Khi vi phạm: gọi lại **tối đa 2 lần thêm** với cùng prompt và schema (không làm tròn, không cắt, không sửa prompt);
   mỗi lần thử ghi vào `detailJson` (`schemaAttempts`: số lần, trường lỗi, không ghi nội dung bài). Hết lượt -> `AiProviderException` với `AiFailureReason.PROVIDER_RESPONSE_INVALID` và message `GEMINI_FIELD_INVALID`; worker `markScoringFailed` -> `SCORING_FAILED`. Tổng thời gian nằm trong `AiJobBudget`.
   **Chấm lại câu thất bại** dùng đường có sẵn: Host gọi `POST /api/v1/sessions/{sessionPublicId}/score`, `ScoringCommandService` lấy lại các câu `SCORING_FAILED` (và AI_SCORING quá `stale-dispatch-minutes`) qua `findScoringWork` rồi đưa về `AI_SCORING` với dispatch token mới; không thêm hành động mới (có test xác nhận câu thất bại do vi phạm schema được đưa lại hàng đợi).
6. **Điểm câu từ `RubricScorer`** (L1, L5): ghép điểm tiêu chí Gemini với band Form (mã) thành `TraitScoreSet`, gọi `RubricScorer.score` với `EffectiveRubric` từ hàng phiên bản; dùng kết quả làm `rawScore`; xóa mọi `average()` khỏi scorer viết. Bài trống: điểm 0 hợp lệ, mọi tiêu chí 0, không gọi Gemini.
7. **Lưu điểm tiêu chí có dấu thang** (U3, HIGH-5): `answer_evaluations.criteria_scores_json` lưu `{"scale":"PEARSON_V1","rubricVersion":"<uuid>","traits":{"CONTENT":4,...}}` (khóa tiêu chí theo catalog, chữ hoa). Dòng cũ (map phẳng 0-100, không có `scale`) vẫn đọc được;
   mọi bộ đọc (`AiScoringResultPersistenceService`, `AiScoreDetailQueryService`, `PracticeScoringStateService`, `PracticeItemResultResponse`) phân biệt theo `scale`. `AiScoreResult.subScores` giữ map phẳng cho tương thích, thêm `rubricVersionPublicId`; cột `answer_evaluations.rubric_version_public_id` được ghi.
   Ghi `formCheck` (metrics, band, quy tắc phụ) vào `detailJson`.
8. **Chặn provider không hỗ trợ**: provider khác `azure-gemini` mà task type viết có rubric không có scorer -> thất bại rõ ràng (mã trong `ScoringConstants`), không để client chung tự trả `rawScore` (mặc định cho tới khi Phase 4 quyết định).
9. **pte-practice (tương thích ngược)**: `PracticeItemResultResponse` thêm `subScoreMax` **tùy chọn** (khóa -> thang tối đa) khi dòng có `scale = PEARSON_V1`; FE (`ScoreView.tsx`, `InlineResultCard.tsx`, `session-contracts.ts`) hiển thị `đạt/tối đa` khi có `subScoreMax`, và hiển thị **số thô như hiện nay** khi không có (dữ liệu cũ). Cập nhật theo `CODING_STANDARDS_WEB.md` và test FE.
10. **Test**: cập nhật `GeminiWritingScorersTest`, `FormCheckTest`, `GeminiScorersTest`, `AiScoringWorkerTest`; thêm: Essay 50 chữ -> 0 dù LLM chấm cao; Essay 150 chữ Form = 1; SST 45 chữ Form = 1; SWT 2 câu/toàn hoa -> 0; LLM trả 7 cho thang 0-6 hoặc 3.5 hoặc thiếu: thử lại tối đa 2 lần rồi `SCORING_FAILED`, không làm tròn, `schemaAttempts` ghi đúng;
   lần thử thứ 2 hợp lệ thì thành công; payload gửi đi có `temperature = 0` và schema đúng biến thể đã chốt; prompt chứa mô tả mức; JSON lưu có `scale` và `rubricVersion`, bộ đọc đọc được dòng cũ; practice đọc cả hai dạng. Thu allowlist `RubricScoreSingleSourceTest` (bỏ 3 scorer viết).

## Acceptance criteria

- Smoke schema đã chạy, biến thể được chốt và ghi lại; Phase 4 không đổi biến thể.
- Essay < 120 chữ -> 0; Essay 150 chữ có Form = 1 và điểm > 0; Essay 50 chữ với LLM cao vẫn 0; SST 45 chữ Form = 1; SWT sai một câu/toàn hoa Form = 0 -> 0.
- LLM không được hỏi Form; mọi tiêu chí AI_LLM là số nguyên thang Pearson; vi phạm được thử lại tối đa 2 lần rồi fail closed với `PROVIDER_RESPONSE_INVALID`, không làm tròn; số lần thử ghi trong `detailJson`; câu thất bại chấm lại được qua `POST /api/v1/sessions/{id}/score`.
- `rawScore` = kết quả `RubricScorer` (test bằng nhau với cùng điểm tiêu chí); WE: Spelling 2/26, Content 6/26.
- `criteria_scores_json` có `scale = PEARSON_V1` và `rubricVersion`; dòng cũ đọc được; pte-practice hiển thị được cả hai.
- Band Form chỉ do `FormRule.bandFor` (architecture test); prompt có mô tả mức; `temperature = 0`.
- Bộ test scoring cũ xanh sau cập nhật; ratchet kiến trúc xanh.

## Validation commands

```powershell
cd D:\GitHub\pte-org\pte-api
.\mvnw.cmd -pl app -DskipTests compile
.\mvnw.cmd -pl app test -Dtest="GeminiWritingScorersTest,GeminiScorersTest,FormCheckTest,AiScoringWorkerTest,RubricSchemaBuilderTest,RubricScoreSingleSourceTest,ScoringCommand*Test,Practice*Test"
.\mvnw.cmd -pl app test -Dtest="PackageDensityTest,SourceFileSizeTest,NoDirectClockAccessTest,ModuleStructureTest"
# Smoke schema thật (SCORING_AI_SPIKE=true, SCORING_AI_GEMINI_API_KEY, từng method):
.\mvnw.cmd -pl app test -Dtest="RubricSchemaSmokeSpikeTest#<method>"

cd D:\GitHub\pte-org\pte-practice
pnpm typecheck; pnpm lint; pnpm test   # cần xác minh tên script
```

## Design Constraints

- `docs/CODING_STANDARDS_API.md` (và `docs/CODING_STANDARDS_WEB.md` cho `pte-practice`) bắt buộc; message/mã lỗi trong `ScoringConstants`/`RubricConstants`; giữ nội dung message ngoài đã có khi gom hằng; file <= 300 dòng; `Clock` inject; gói <= 15 class.
- AI chỉ trả điểm tiêu chí; không nhận điểm câu hay Form từ LLM; mọi điểm câu qua `RubricScorer`, band Form qua `FormRule.bandFor`.
- Fail closed: không làm tròn, không cắt, không mặc định giá trị thiếu; thử lại chỉ cùng prompt/schema, tối đa 2 lần thêm, trong `AiJobBudget`.
- Bài làm và đề luôn trong khối `quoted` kèm `GUARD`; không trường văn bản tự do nào vào phần hướng dẫn hệ thống; `detailJson` không chứa nội dung bài.
- Đổi thang tiêu chí là thay đổi hợp đồng có chủ đích với pte-practice, được bảo vệ bằng `scale` và bộ đọc hai dạng; dòng cũ không chuyển đổi.
- Không có bước release/deploy trong phase này (người dùng tự xử lý).
- Preflight (2026-11-05): đã đọc đủ `docs/CODING_STANDARDS_API.md`, `docs/COMMON_EXCEPTION_SETUP.md`, `docs/API_RESPONSE_SETUP.md`, `docs/CODING_STANDARDS_WEB.md`. Quyết định khi làm:
  - **Biến thể schema: (b) INTEGER có `minimum/maximum`**, chọn theo tài liệu Gemini REST `responseSchema` (`enum` chỉ được tài liệu hóa cho STRING; INTEGER hỗ trợ `minimum/maximum`). **Smoke không chạy (không có `SCORING_AI_GEMINI_API_KEY` trên máy làm phase)**: `RubricSchemaSmokeSpikeTest` (3 method a/b/c, 10 lần/biến thể, chạy khi `SCORING_AI_SPIKE=true`) đã viết để người dùng chạy sau; nếu smoke cho thấy (b) bị từ chối thì đổi `RubricSchemaBuilder.traitSchema`. Kiểm tra Java (`TraitScoreReader`) luôn bắt buộc. `temperature 0` giữ ở `GeminiRestClient` (xác nhận bằng `RubricWritingWireTest`).
  - Lớp mới: gói `com.pte.scoring.internal.rubric.prompt` (`RubricPromptBuilder`, `RubricSchemaBuilder`, `TraitScoreReader`, `TraitScoreCollector`); trường schema/prompt dùng khóa catalog chữ hoa (`CONTENT`, ...). GUARD vẫn chỉ ở `GeminiScorers` (scorer ghép vai trò + mục rubric rồi `GeminiScorers.system`).
  - `RubricResolver.resolveForExamDefinition(examDefinitionPublicId, taskType)` (QUAL-002): đọc ghim qua `ExamDefinitionService.getByPublicId(..).rubricVersionPublicId()`; mẫu đề cũ ghim null hoặc dòng không có `examDefinitionPublicId` dùng bản ACTIVE (cùng quy tắc phase 2); ghim trỏ tới phiên bản không đọc được thì thất bại đóng. `resolveActive(String)` gộp vào `resolveActiveVersion` (giữ <= 5 method public). `RubricVersionService.activate` kiểm lại tham số bằng validator trước `retireActive` (QUAL-001, 400).
  - Worker/practice: task type trong `ScoringConstants.RUBRIC_SCORED_TASK_TYPES` (SWT, WE, SST) bắt buộc có scorer riêng; không có (mọi provider khác `azure-gemini`, **kể cả `stub` mặc định ở local**) -> `AiProviderException(INTERNAL_ERROR, AI_RUBRIC_SCORER_UNAVAILABLE)` -> `SCORING_FAILED`; rubric không resolve được -> `INTERNAL_ERROR` (`AI_RUBRIC_UNRESOLVED`). Đường `essayScoringClient` chỉ còn cho task type AI_TEXT ngoài catalog.
  - `FormCheck` chỉ đếm (`measure` -> `TextMetrics`, `detail`); "câu rất ngắn" = >= 2 câu và mọi câu <= 3 từ; gạch đầu dòng = mọi dòng bắt đầu bằng `-`, `*`, `•`, `1.`, `1)`. Không còn đọc `minWordCount/maxWordCount` của item.
  - Lưu trữ: lớp công khai `com.pte.scoring.CriteriaScores` (đọc/ghi hai dạng, phân biệt bằng `scale`) dùng chung cho `answer_evaluations` và cột sub-score của practice; `AiEvaluation.recordDetail(.., rubricVersionPublicId)` ghi `answer_evaluations.rubric_version_public_id` (kết quả không qua rubric xóa ghim cũ). `AiScoreDetailResponse` thêm tùy chọn `criteriaScale`, `rubricVersionPublicId`. `PracticeItemResultResponse.subScoreMax` lấy từ `com.pte.scoring.RubricScaleService` (cache theo phiên bản vì ACTIVE/RETIRED bất biến; lỗi đọc -> không có `subScoreMax`).
  - Khi hết lượt thử lại, câu thất bại chỉ lưu `failure_reason`; `schemaAttempts` chỉ nằm trong `detailJson` của lần chấm thành công (cơ chế `recordFailure` giữ nguyên chi tiết của lần thành công trước).

## Quality and Testing State

- Quality: skipped_by_user (decision: user_confirmed_skip)
- Testing: partial (2026-11-05). After `clean test-compile`, the full `./mvnw.cmd -pl app test` ran 4255 tests: 0 failures, 0 errors, 127 skipped, BUILD SUCCESS (counts read from `surefire-reports`). The only new skip class in this phase is `RubricSchemaSmokeSpikeTest` (3 tests, `SCORING_AI_SPIKE`). The other 124 skips belong to existing Postgres, live and spike classes that this phase did not touch. Of those, `RubricVersionMigrationPostgresTest` (12) is already skipped. Nobody checked why the total differs from the 112 recorded in phase 2. Targeted run: 227 tests passed. The new and changed tests are `RubricSchemaBuilderTest` 4, `RubricPromptBuilderTest` 3, `TraitScoreCollectorTest` 9, `FormCheckTest` 29, `GeminiWritingScorersTest` 26, `RubricWritingWireTest` 2, `AiScoringWorkerTest` 22, `CriteriaScoresTest` 6, `RubricScaleServiceTest` 4, `AiScoreDetailQueryServiceTest` 8, `AiScoringResultPersistenceServiceTest` 13, `PracticeAiScoringServiceTest` 18, `PracticeScoringStateServiceTest` 25, `ScoringCommandServiceTest` 9, `SchemaViolationRescoreDatabaseTest` 1 (H2 `@DataJpaTest`), `RubricResolverTest` 15 and `RubricVersionServiceTest` 16. These ran and are green: the scoring and practice packages, the phase 1-2 rubric tests, the assessment pin tests, `ModuleStructureTest`, `PackageDensityTest`, `SourceFileSizeTest`, `NoDirectClockAccessTest`, `RubricScoreSingleSourceTest` and `ApiInventoryExportTest` (1147 tests, 0 failures, 31 skipped). pte-practice: `tsc --noEmit` passes. `eslint` has 0 errors and 2 warnings, both in files this phase did not touch. `vitest run`: 74 files, 634 tests, all pass. These ran straight from `node_modules/.bin`, because `pnpm <script>` stops at the pnpm install check (`ERR_PNPM_IGNORED_BUILDS`). **Not executed:** the real Gemini smoke and the AI spikes (there is no key), and the Postgres IT (there is no Docker). The phase acceptance item "Smoke schema đã chạy" is therefore not met.

## Risks

- Không biến thể schema nào chấp nhận enum số nguyên: dùng (b) hoặc (c); lớp kiểm tra Java vẫn là bảo vệ chính.
- Bỏ giới hạn số chữ theo item đổi hành vi với item có giới hạn riêng: kiểm tra dữ liệu item hiện có trước khi bỏ.
- Spelling do LLM đếm lỗi dao động: đo ở Phase 4, chỉ ghi nhận (câu hỏi mở 2).
- Thử lại làm tăng độ trễ/chi phí: giới hạn 2 lần, trong `AiJobBudget`, ghi `schemaAttempts` để theo dõi.
- Prompt lớn do mô tả mức dài: chỉ nhúng mô tả của tiêu chí AI_LLM.
