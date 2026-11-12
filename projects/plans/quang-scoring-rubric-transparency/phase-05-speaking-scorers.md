# Phase 5: Scorer nói (RA, RS, DI, RL, RTS, SGD, ASQ) theo rubric

## Mục tiêu

Chuyển 7 task type Speaking sang rubric: Pronunciation và Oral Fluency thang 0-5 (Azure, qua bảng ánh xạ **chưa hiệu chỉnh** có nhãn), Content theo thang Pearson (Gemini cho DI, RL, RTS, SGD; mã cho RA và RS), cổng Content cho 4 task type mở,
một quy tắc duy nhất khi Azure không trả prosody, Read Aloud có Content phạt từ chèn, Repeat Sentence Content 0-3 và không tính Fluency hai lần. Sửa L1, L2, L5, L6, L7, L10 phần Speaking.

## Stories/FR covered

- S2; FR-03, FR-05, FR-06: L1 (cổng DI/RL/RTS/SGD), L2, L5, L6, L7, L10

## Files to read first

- `D:\GitHub\pte-org\docs\CODING_STANDARDS_API.md`, `docs\CODING_STANDARDS_WEB.md` (pte-practice)
- `pte-api/app/src/main/java/com/pte/scoring/internal/vendor/gemini/scorer/GeminiSpeakingScorer.java` (công thức cũ; `missingProsodyScoresZero()`; `noSpeech`; `Prepared`) và 4 lớp con `DescribeImageScorer`, `RetellLectureScorer`, `RespondToSituationScorer`, `SummarizeGroupDiscussionScorer`
- `.../scoring/internal/vendor/azure/ReadAloudScorer.java`, `RepeatSentenceScorer.java`, `ShortQuestionScorer.java`, `AzureScorers.java`, `PronunciationFormula.java`, `PronunciationScores.java`, `SpeechAssessment.java`, `SpeechAggregator.java`, `ReferenceSplitter.java`
- `.../vendor/speech/TokenAlignment.java`
- Test: `ReadAloudScorerTest`, `RepeatSentenceScorerTest`, `ShortQuestionScorerTest`, `GeminiSpeakingScorersTest`
- Báo cáo đối chiếu L2, L6, L7; Pearson tr.15-31, 45-46 (`fresh.txt`)
- Phase 3 (`scale`, thử lại giới hạn, biến thể schema đã chốt), Phase 4 (bộ dữ liệu tổng hợp, `RubricStabilitySpikeTest`)
- `pte-practice/features/practice/ScoreView.tsx`

## Implementation steps

1. **Bảng ánh xạ Azure -> 0-5 chưa hiệu chỉnh (U2)**: khai báo trong catalog `azureBandMapping` (có số phiên bản; hàng phiên bản rubric lưu `azureBandMappingVersion`) cho Pronunciation và Oral Fluency, điểm Azure 0-100 -> band 0-5. Pronunciation lấy từ `accuracy` của Azure (DI/RL/RTS/SGD hiện bỏ không dùng) và quy tắc đã có cho RA/RS;
   Oral Fluency từ `fluency` (và `prosody` khi có, công thức ghi rõ trong catalog). Ngưỡng ban đầu là đề xuất của nhóm, **phát hành ở trạng thái "chưa hiệu chỉnh với dữ liệu người chấm"**: cờ `calibrated=false` và nhãn hằng trong `RubricConstants` trả trong API đọc rubric (Phase 2),
   hiển thị trên vendor-web (màn A) và trong phản hồi/màn giải thích tenant-web (Phase 6, 7), và nêu trong báo cáo xác minh (Phase 11).
2. **Prosody thiếu — một quy tắc**: nếu Azure không trả prosody thì Oral Fluency chỉ dựa trên `fluency` (không prosody = 0, không chia 2/3 khác nhau); cờ `prosodyUnavailable` trong `detailJson`. Xóa `missingProsodyScoresZero()`.
3. **DI, RL, RTS, SGD**: Gemini chỉ chấm CONTENT (số nguyên 0-6, mô tả mức từ catalog, transcript từ Azure, `GUARD`, thử lại có giới hạn như Phase 3); Pronunciation và Oral Fluency từ Azure qua bảng ánh xạ; điểm câu = `RubricScorer` với cổng CONTENT. `noSpeech`: ba tiêu chí 0, điểm 0.
4. **Read Aloud** (L6, MEDIUM-4): CONTENT thang động N = số từ của đoạn văn (`promptText`), **N tối thiểu 1; item không có đoạn văn hoặc N = 0 là lỗi dữ liệu đề** (thất bại cố định với mã trong `ScoringConstants`, không chấm); đạt = max(0, N − (thay + bỏ sót + chèn)) tính bằng mã từ kết quả căn chỉnh
   (bỏ qua ngập ngừng/từ đệm, tr.16); có phạt từ chèn. **N được lưu trong tập điểm tiêu chí** (`wordCount` trong JSON `traits`/`detailJson`) để tính lại và giải thích không cần đoạn văn. Pronunciation/Oral Fluency qua bảng ánh xạ. Xóa công thức `PronunciationFormula` 0.4/0.2/0.2/0.2 khỏi quyết định điểm câu;
   khóa cũ `ACCURACY`, `COMPLETENESS`, `PROSODY` thành khóa tiêu chí (`CONTENT`, `PRONUNCIATION`, `ORAL_FLUENCY`), dữ liệu thô Azure vào `detailJson`.
5. **Repeat Sentence** (L7): CONTENT 0-3 bằng mã theo Pearson tr.16 (3 = đủ từ đúng thứ tự; 2 = >= 50%; 1 = < 50%; 0 = gần như không), dựa trên `TokenAlignment`, bỏ qua ngập ngừng/từ đệm; Pronunciation và Oral Fluency 0-5; Fluency chỉ một lần.
6. **Answer Short Question**: VOCABULARY 0/1 (khớp đáp án trên transcript, MECHANICAL); điểm câu 0 hoặc 100 qua `RubricScorer`.
7. **Lưu và hiển thị**: cùng định dạng JSON có `scale = PEARSON_V1` và `rubricVersion` như Phase 3; `rubric_version_public_id` được ghi. pte-practice: hiển thị `đạt/tối đa` khi có `subScoreMax`, và hiển thị số thô cho dòng cũ; cập nhật `subScoreLabel` (`ORAL_FLUENCY`; khóa cũ giữ nhãn cũ cho dữ liệu cũ).
8. **Kiểm tra bằng dữ liệu tổng hợp (U2)**: mở rộng `RubricStabilitySpikeTest` cho Content của DI/RL/RTS/SGD trên transcript tổng hợp (Phase 4), 3 lần/mẫu, cùng ngưỡng 90% độ ổn định; chạy `AllScorersSpikeTest` với WAV TTS có chèn ngập ngừng để kiểm tra **tính đơn điệu của Fluency**
   (nhiều ngập ngừng/lặp hơn thì band Oral Fluency không tăng); kết quả vào báo cáo spike ở Phase 4. Việc này **không** hiệu chỉnh bảng ánh xạ; bảng giữ nhãn chưa hiệu chỉnh.
9. **Test**: cập nhật bốn test scorer hiện có; thêm: DI CONTENT = 0 nhưng fluency cao -> 0; không prosody cho cùng kết quả ở cả 4 task type; RA có từ chèn bị trừ, **N = 1, 30, 80**, N = 0 -> thất bại cố định, N lưu trong JSON; RS 3/2/1/0 theo ngưỡng 50% và Fluency một lần; ngưỡng bảng Azure (từng biên) và cờ `calibrated=false`;
   LLM ngoài thang -> thử lại rồi `SCORING_FAILED`. Allowlist `RubricScoreSingleSourceTest` về **rỗng**.

## Acceptance criteria

- DI Content = 0, fluency 80, prosody 75 -> điểm câu 0 (trước ~52).
- DI/RL/RTS/SGD chấm Pronunciation (Azure) và Oral Fluency; không còn `PROSODY` trong điểm câu; prosody thiếu cho cùng kết quả ở 4 task type.
- RA có CONTENT phạt thay/bỏ/chèn, N >= 1 và được lưu; RS có CONTENT 0-3 và Fluency một lần.
- Điểm câu mọi task type Speaking = `RubricScorer` với điểm tiêu chí Pearson; trọng số mặc định cho `Σ đạt / Σ tối đa` (DI 16, RS 13).
- Bảng Azure có phiên bản, test biên, `calibrated=false`, nhãn "chưa hiệu chỉnh với dữ liệu người chấm" xuất hiện trong API đọc rubric.
- Content của Gemini fail closed có thử lại; kiểm tra tính đơn điệu Fluency chạy trên WAV tổng hợp; báo cáo spike bổ sung độ ổn định Speaking.
- Allowlist `RubricScoreSingleSourceTest` rỗng; pte-practice hiển thị Speaking cả dữ liệu cũ lẫn mới.

## Validation commands

```powershell
cd D:\GitHub\pte-org\pte-api
.\mvnw.cmd -pl app -DskipTests compile
.\mvnw.cmd -pl app test -Dtest="ReadAloudScorerTest,RepeatSentenceScorerTest,ShortQuestionScorerTest,GeminiSpeakingScorersTest,AzureBandMappingTest,RubricScoreSingleSourceTest,Practice*Test"
.\mvnw.cmd -pl app test -Dtest="PackageDensityTest,SourceFileSizeTest,NoDirectClockAccessTest,ModuleStructureTest"
# Spike thật (từng method): SCORING_AI_SPIKE=true, SCORING_AI_SPIKE_DIR, SCORING_AI_SPIKE_WAV_DIR, SCORING_AI_GEMINI_API_KEY
.\mvnw.cmd -pl app test -Dtest="AllScorersSpikeTest#<method>"
.\mvnw.cmd -pl app test -Dtest="RubricStabilitySpikeTest#<method nói>"

cd D:\GitHub\pte-org\pte-practice
pnpm typecheck; pnpm lint; pnpm test   # cần xác minh tên script
```

## Design Constraints

- `docs/CODING_STANDARDS_API.md` (và `docs/CODING_STANDARDS_WEB.md` cho pte-practice) bắt buộc: file <= 300 dòng; **`vendor/azure` đang 14 file** nên class mới (bảng ánh xạ, bộ tính Content RA/RS) vào gói con mới như `internal/rubric/speech`; `Clock` inject; message trong `*Constants`.
- Không làm tròn/cắt Content của LLM; không tính điểm câu ngoài `RubricScorer`; không tính band Form ngoài `FormRule`.
- Pronunciation và Oral Fluency chỉ do máy chấm; LLM chỉ chấm Content.
- Không trường văn bản tự do trong prompt; transcript qua `quoted` kèm `GUARD`; không in transcript vào log hay báo cáo.
- Bảng ánh xạ Azure là xấp xỉ chưa hiệu chỉnh và phải được gắn nhãn ở mọi nơi hiển thị; không trình bày như phương pháp của Pearson.
- Không đổi khóa `subScores` mà không cập nhật mọi nơi đọc (practice, `AiScoreDetailQueryService`, `PracticeScoringStateService`); bộ đọc hai dạng theo `scale`.
- Không có bước release/deploy.
- Preflight (2026-11-05): đã đọc đủ `docs/CODING_STANDARDS_API.md`, `docs/CODING_STANDARDS_WEB.md`, `docs/API_RESPONSE_SETUP.md`, `docs/COMMON_EXCEPTION_SETUP.md`. Quyết định khi làm:
  - Gói mới `com.pte.scoring.internal.rubric.speech` (6 lớp: `AzureBandMapping`, `AzureBandThreshold`, `SpeechBands`, `SpokenWords`, `ReadAloudContent`, `RepeatSentenceContent`); bảng khai báo ở `internal/rubric/catalog/AzureBandMappingCatalog` (phiên bản 1, `calibrated=false`, ngưỡng đề xuất band 1..5 = 30/45/60/75/90, dùng chung cho Pronunciation và Oral Fluency). `vendor/azure` giảm còn 13 lớp (xóa `PronunciationFormula` và test của nó).
  - Pronunciation = band của Azure `accuracy`; Oral Fluency = band của trung bình `fluency` và `prosody`, hoặc chỉ `fluency` khi không có prosody (một quy tắc cho cả 7 task type; cờ `prosodyUnavailable` trong `detailJson`). Thiếu điểm Azure tính là 0. Bảng không tồn tại -> `AI_AZURE_BAND_MAPPING_UNKNOWN` (fail closed, trước khi tải audio); thiếu rubric -> `AI_RUBRIC_MISSING`.
  - RA: N = số từ của `promptText` (N = 0 -> `SPEECH_REFERENCE_TEXT_EMPTY`, không chấm); lỗi = thay + bỏ sót + chèn từ các khối căn chỉnh `TokenAlignment`, bỏ từ đệm (`ScoringConstants.SPEECH_FILLER_WORDS`). **N lưu trong `detailJson`** (`wordCount`, `readAloudContent`), không thêm vào `criteria_scores_json` (tránh đổi `AiScoreResult`/`CriteriaScores`; Phase 6 đọc N từ `detailJson`). `AiScoreResult` cho phép trait > 100 khi có `rubricVersionPublicId` (Content RA thang N).
  - RS: 3 = mọi từ đúng thứ tự; 2 = >= 50%; 1 = có ít nhất 1 từ; 0 = không từ nào (diễn giải "almost nothing").
  - ASQ: `VOCABULARY` 0/1, điểm câu qua `RubricScorer`.
  - API đọc rubric: `AzureMappingResponse` giữ 3 trường cũ (`version`, `calibrated`, `label`) và thêm `pronunciationInput`, `oralFluencyInput`, `pronunciationBands`, `oralFluencyBands` (tương thích ngược, chỉ cộng thêm); `calibrated` lấy từ bảng khai báo.
  - `RUBRIC_SCORED_TASK_TYPES` gồm thêm 7 task type nói (quyết định B: `stub`/`openai-compatible` -> `AI_RUBRIC_SCORER_UNAVAILABLE`; local mặc định `stub` sẽ fail mọi câu nói chuẩn). Xóa `GeminiScorers.score` (0-100, làm tròn). `SpeechAggregator` không còn `.average()`; allowlist `rubric-single-source.allowlist` rỗng.
  - pte-practice: `PEARSON_TRAIT_LABELS` cho khóa Pearson, khóa cũ giữ nhãn sinh tự động. RA Content không có `subScoreMax` (thang theo N) nên hiển thị số thô.

## Quality and Testing State

- Quality: skipped_by_user (decision: user_confirmed_skip)
- Testing: passed (2026-11-05), với giới hạn bên dưới. Sau `clean test-compile`, chạy nhắm đích `com.pte.scoring.**`, `com.pte.practice.**`, `com.pte.architecture.*`, `ModuleStructureTest`, `ApiInventoryExportTest`: 1287 test, 0 lỗi, 41 bỏ qua. Toàn bộ `.\mvnw.cmd -pl app clean test`: **4410 test, 0 failures, 0 errors, 137 skipped**, BUILD SUCCESS (đọc từ `surefire-reports`, 503 lớp). So với nền 4255/127 trước phase 4: bỏ qua tăng 10, trong đó phase 5 thêm 6 (`RubricStabilitySpikeTest` 4 -> 9, `AllScorersSpikeTest` 11 -> 12); 4 còn lại chưa được đối chiếu (có thể từ phase 4). Test mới/đổi: `AzureBandMappingTest` (mọi biên, `calibrated=false`, phiên bản không tồn tại), `SpeakingContentTest` (RA chèn/thay/bỏ, N = 1, 30, 80, N = 0; RS 3/2/1/0), `ReadAloudScorerTest`, `RepeatSentenceScorerTest`, `ShortQuestionScorerTest`, `GeminiSpeakingScorersTest` (DI Content 0 + fluency 80 + prosody 75 -> 0; prosody thiếu cùng kết quả ở 4 task type; ngoài thang -> thử lại 2 lần rồi `PROVIDER_RESPONSE_INVALID`; lần 2 hợp lệ), `GeminiSpeakingTaskScorersTest`, `RubricReadServiceTest`/`RubricReadControllerTest` (bảng ánh xạ trong API đọc), `AiScoreResultTest`, `RubricSchemaBuilderTest`, `RubricPromptBuilderTest`, `RubricScorerProviderGateTest`, và cập nhật `AiScoringWorkerTest`, `PracticeAiScoringServiceTest`, `AiScoringPipelineDatabaseTest`, `SyntheticDatasetTest`. `RubricScoreSingleSourceTest` xanh với allowlist rỗng. pte-practice: `tsc --noEmit` exit 0; `eslint` 0 lỗi, 2 cảnh báo ở file không đụng tới; `vitest run` 74 file, 636 test pass (chạy từ `node_modules/.bin`, không `pnpm install`, `pnpm-lock.yaml` không đổi). **Chưa chạy:** `RubricStabilitySpikeTest#allSpeaking` (và 4 method nói) và `AllScorersSpikeTest#oralFluencyIsMonotonicOnSyntheticHesitations` (không có key Gemini/Azure, chưa sinh WAV TTS); Postgres IT (không Docker). Vì vậy tiêu chí "kiểm tra tính đơn điệu Fluency chạy trên WAV tổng hợp; báo cáo spike bổ sung độ ổn định Speaking" **chưa đạt** (chỉ có công cụ và mục hướng dẫn trong báo cáo spike).

## Risks

- Ngưỡng Azure chưa hiệu chỉnh làm điểm lệch kỳ vọng học thuật (ghi nhận): nhãn hiển thị, bảng có phiên bản để chỉnh sau khi có dữ liệu người chấm.
- `vendor/azure` sát trần 15 class: tách gói con từ đầu; chạy `PackageDensityTest` sau mỗi lớp mới.
- RA Content theo N áp đảo với đoạn dài (RA tổng N + 10): golden test N = 1, 30, 80; trình chỉnh nêu rõ RA Content theo độ dài.
- Căn chỉnh Azure bỏ sót/chèn sai làm lệch Content RA/RS: giữ `wordErrors` trong `detailJson` để giải thích.
- TTS không tái hiện đúng ngập ngừng thực: chỉ dùng kiểm tra đơn điệu, không kết luận độ chính xác.
