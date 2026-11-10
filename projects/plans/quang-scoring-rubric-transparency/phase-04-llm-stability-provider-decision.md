# Phase 4: Đo độ ổn định LLM (dữ liệu tổng hợp) + quyết định provider

## Mục tiêu

Đo xem Gemini có cho điểm tiêu chí ổn định trên thang Pearson nhỏ hay không bằng **chấm lặp 3 lần** trên **bộ dữ liệu tổng hợp** (mục tiêu **>= 90% điểm tiêu chí lệch không quá 1 mức giữa các lần chạy**), chốt phương án dự phòng
nếu hụt, và quyết định số phận provider `openai-compatible`. Biến thể schema đã chốt ở Phase 3; phase này **chỉ đo ổn định**. Độ ổn định không cần nhãn đúng.

## Stories/FR covered

- Success Criteria "Độ ổn định của LLM"; FR-03; câu hỏi mở 1 (provider `openai-compatible`)

## Files to read first

- `D:\GitHub\pte-org\docs\CODING_STANDARDS_API.md`
- `pte-api/app/src/test/java/com/pte/scoring/internal/vendor/AllScorersSpikeTest.java` (`@EnabledIfEnvironmentVariable("SCORING_AI_SPIKE")`, `SpikeSupport`, `SCORING_AI_SPIKE_DIR`, `SCORING_AI_SPIKE_WAV_DIR`, `SCORING_AI_GEMINI_API_KEY`, `SCORING_AI_GEMINI_MODEL`), `AzureGeminiSpikeTest.java`, `SpikeSupport.java`
- Phase 3: `RubricPromptBuilder`, `RubricSchemaBuilder` (đã chốt biến thể), thử lại có giới hạn, `GeminiWritingScorer`
- `.../scoring/internal/vendor/openai/OpenAiCompatibleEssayScoringClient.java` và client nói tương ứng (cần xác minh tên), `.../config/AzureGeminiProviderConfig.java`, `AiProviderProperties.java`, `AiJobBudget.java`

## Implementation steps

1. **Bộ dữ liệu tổng hợp (U2)**: trợ lý AI tạo trong lúc làm phase này (không cần dữ liệu người chấm): (a) khoảng 20 bài viết (7 SWT, 7 WE, 6 SST) và (b) khoảng 20 transcript nói (DI, RL, RTS, SGD, dùng cho Content của Gemini ở Phase 5), mỗi mẫu **nhắm vào một mức Pearson cụ thể cho từng tiêu chí**
   (phủ mức thấp/giữa/cao và ca biên: lạc đề, học thuộc, rất ngắn). Lưu dưới `pte-api/app/src/test/resources/scoring/rubric-spike/` (`writing-synthetic.json`, `speaking-transcripts-synthetic.json`) kèm `intendedBands` và `generationNotes` cho từng mẫu và tệp `README` ghi cách tạo; chỉ chứa nội dung tổng hợp,
   không bài làm hay transcript thật. (c) WAV TTS có chèn ngập ngừng/lặp, chỉ dùng ở Phase 5 để kiểm tra Fluency đơn điệu: sinh bằng TTS, **không commit tệp nhị phân lớn**; commit manifest và kịch bản tạo, đặt WAV tại `SCORING_AI_SPIKE_WAV_DIR`.
2. **Harness**: `RubricStabilitySpikeTest` cạnh `AllScorersSpikeTest` (cùng điều kiện `SCORING_AI_SPIKE=true`) gọi scorer thật 3 lần cho mỗi mẫu và tính: (a) **% điểm tiêu chí có độ chênh giữa 3 lần <= 1 mức** (chỉ số cổng); (b) % trùng mức dự định trong ±1 (chỉ số **phụ, báo cáo, KHÔNG phải cổng**);
   (c) tỉ lệ vi phạm schema/fail closed và số lần thử lại; (d) token và độ trễ. Chỉ in số liệu tổng hợp theo tiêu chí; không in nội dung bài.
3. **Ngưỡng và dự phòng**: nếu (a) >= 90% -> giữ gọi 1 lần. Nếu hụt: **trung vị của 3 lần chấm cho từng tiêu chí không ổn định** (lớp `MedianOfThreeScoring` trong `internal/rubric/prompt`), đo lại; nếu vẫn hụt thử model mạnh hơn qua `SCORING_AI_GEMINI_MODEL` hoặc thêm ví dụ few-shot lấy từ catalog (không từ bài thật).
   Mọi phương án nằm trong `AiJobBudget` (kiểm chứng chi phí x3 và độ trễ).
4. **Quyết định `openai-compatible`** (ghi vào `plan.md`, câu hỏi mở 1): (A) định tuyến qua cùng prompt/schema từ catalog (chỉ đổi lớp HTTP) hoặc (B) đánh dấu không hỗ trợ task type có rubric (fail closed, mã trong `ScoringConstants`).
   Mặc định đề xuất B nếu cấu hình triển khai chỉ dùng `azure-gemini`, nếu không thì A. Triển khai phương án đã chọn kèm test; không còn đường nào để task type có rubric nhận `rawScore` do LLM tự trả.
5. **Báo cáo** `pte-doc/plans/reports/<YYMMDD>-scoring-rubric-llm-stability-spike-report.md` (ngày theo ngày chạy): số liệu theo tiêu chí, chỉ số phụ "khớp mức dự định" kèm lưu ý đây là dữ liệu tổng hợp do AI tạo nên **không phải bằng chứng độ chính xác**, quyết định provider; số liệu thô trong `pte-doc/plans/reports/assets/<tên-báo-cáo>/`.
6. **Nếu vẫn < 90% sau dự phòng**: ghi nhận là tiêu chí chưa đạt trong báo cáo và báo người dùng trước khi tiếp Phase 5; không hạ ngưỡng ngầm.

## Acceptance criteria

- Bộ dữ liệu tổng hợp có `intendedBands` + `generationNotes`, không dữ liệu thật; harness chạy được khi `SCORING_AI_SPIKE=true`.
- Báo cáo có % điểm tiêu chí lệch <= 1 mức giữa 3 lần theo từng tiêu chí và tổng; đạt >= 90% với cấu hình chốt (một lần gọi hoặc trung vị 3 lần), hoặc ghi rõ chưa đạt.
- Chỉ số "khớp mức dự định" được báo cáo nhưng không gây fail phase.
- Schema không bị đổi ở phase này (đã chốt ở Phase 3); lớp kiểm tra Java và thử lại giới hạn vẫn bật.
- Quyết định `openai-compatible` (A hoặc B) đã triển khai và có test.
- Spike không in/lưu nội dung bài vào log hay báo cáo.

## Validation commands

```powershell
cd D:\GitHub\pte-org\pte-api
.\mvnw.cmd -pl app -DskipTests compile
$env:SCORING_AI_SPIKE='true'; $env:SCORING_AI_SPIKE_DIR='<thư mục>'; $env:SCORING_AI_GEMINI_API_KEY='<khóa>'
.\mvnw.cmd -pl app test -Dtest="RubricStabilitySpikeTest#<method>"
.\mvnw.cmd -pl app test -Dtest="MedianOfThreeScoringTest,AiScoringWorkerTest,OpenAiCompatible*Test"
.\mvnw.cmd -pl app test -Dtest="PackageDensityTest,SourceFileSizeTest,NoDirectClockAccessTest,ModuleStructureTest"
```

## Design Constraints

- `docs/CODING_STANDARDS_API.md` bắt buộc: file <= 300 dòng, gói <= 15 class, `Clock` inject (harness dùng đồng hồ test), message trong `*Constants`.
- Spike chỉ chạy khi `SCORING_AI_SPIKE=true`; không khóa API, bài làm thật hay transcript thật trong mã, log, báo cáo (`AGENTS.md` secrets rule).
- Không hạ ngưỡng 90% hay nới "một mức"; không clamp; mọi dự phòng vẫn fail closed và qua `RubricScorer`.
- Dự phòng không vượt `AiJobBudget` và không đổi ngữ nghĩa dispatch token/idempotency của worker.
- Báo cáo lưu ở `pte-doc/plans/reports/` theo quy ước tên; dữ liệu máy đọc ở `reports/assets/<tên>/`, liên kết tương đối.
- Dữ liệu tổng hợp chỉ chứng minh độ ổn định, không chứng minh độ chính xác chấm; không phát biểu khác trong báo cáo.

## Quality and Testing State

- Quality: not evaluated
- Testing: not started

## Risks

- Dữ liệu tổng hợp không phản ánh phân bố thực (ghi nhận, giảm nhẹ): chỉ dùng cho độ ổn định; nêu giới hạn trong báo cáo.
- Chi phí gọi x3 trung vị: đo trong spike, áp dụng chọn lọc theo tiêu chí.
- Kết quả phụ thuộc phiên bản model: ghi tên/phiên bản model, chạy lại khi đổi model.
- 20 mẫu ít: dùng làm cổng sớm, không phải bằng chứng cuối.
