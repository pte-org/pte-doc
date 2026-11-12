# Báo cáo phase 4: độ ổn định LLM và quyết định provider

Plan: `pte-doc/projects/plans/quang-scoring-rubric-transparency` (phase 4). Ngày: 2026-11-05.

## Kết luận ngắn

- **Chưa đo được độ ổn định.** Máy này không có `SCORING_AI_GEMINI_API_KEY`, nên `RubricStabilitySpikeTest` (4 test) bị bỏ qua. Mục tiêu "≥ 90% điểm tiêu chí lệch ≤ 1 mức qua 3 lần chấm" **chưa có số liệu**. Không có con số nào trong báo cáo này là kết quả đo.
- **Công cụ đo đã xong và test được phần không cần key**: bộ dữ liệu tổng hợp, `StabilityMetrics` (11 test), `MedianOfThreeScoring` (11 test), spike test.
- **Quyết định provider: phương án B** (đã có code và test từ phase 3): `openai-compatible` và `stub` không hỗ trợ các task type chấm bằng rubric; câu trả lời fail-closed với mã `AI_RUBRIC_SCORER_UNAVAILABLE`.

## Dữ liệu

Toàn bộ là **dữ liệu tổng hợp do AI viết** (không có bài của thí sinh thật, không có nhãn người chấm). Thư mục `pte-api/app/src/test/resources/scoring/rubric-spike/`:

- `writing-synthetic.json`: 20 mẫu (7 SWT, 7 WE, 6 SST).
- `speaking-transcripts-synthetic.json`: 20 transcript nói cho phase 5.
- `tts-manifest.json`, `generate-tts.ps1`: kịch bản TTS cho phase 5.

Độ ổn định không cần nhãn đúng. `intendedBands` chỉ là mức tác giả nhắm tới, không dùng để khẳng định độ chính xác.

## Cách chạy phép đo (cần người có key)

```powershell
$env:SCORING_AI_SPIKE='true'
$env:SCORING_AI_GEMINI_API_KEY='<key>'
$env:SCORING_AI_SPIKE_OUT='D:\somewhere\stability.json'   # tùy chọn
.\mvnw.cmd -pl app test -Dtest=RubricStabilitySpikeTest
```

Tốn quota Gemini: 20 mẫu × 3 lần, mỗi lần tối đa 3 lượt schema. Chỉ in số tổng hợp, không in bài, feedback hay id mẫu. Form do code tính nên không nằm trong phép đo.

Nếu dưới 90%: đặt `SCORING_AI_SPIKE_MEDIAN_TRAITS` (danh sách trait hoặc `ALL`) để đo phương án dự phòng "trung vị của 3 lần gọi" (`MedianOfThreeScoring`). Lưu ý phương án này nhân 3 chi phí gọi AI; việc nối nó vào scorer chỉ nên làm khi số đo cho thấy cần.

## Quyết định `openai-compatible` (câu hỏi mở 1)

Chọn **B**: không hỗ trợ task type có rubric.

- `ScoringConstants.RUBRIC_SCORED_TASK_TYPES` (hiện SWT, WE, SST; phase 5 thêm các task nói).
- Provider không có scorer rubric cho task type đó thì `AiScoringWorker` và `PracticeAiScoringService` fail câu trả lời với `AI_RUBRIC_SCORER_UNAVAILABLE` thay vì để client generic sinh điểm 0–100.
- Test: `RubricScorerProviderGateTest`, `AiScoringWorkerRubricProviderTest`.
- Lý do: client generic không có schema trait theo thang Pearson; giữ nó sẽ tạo hai đường chấm khác nghĩa. Hệ quả: với provider mặc định `stub`, SWT/WE/SST sẽ lỗi cho tới khi cấu hình `azure-gemini`.

## Kiểm chứng đã chạy

Build sạch (`clean test`) các lớp: `MedianOfThreeScoringTest` 11, `StabilityMetricsTest` 11, `RubricStabilitySpikeTest` 4 (bỏ qua, không key), `ModuleStructureTest` 3, `PackageDensityTest` 1, `SourceFileSizeTest` 1: 0 lỗi. Chưa chạy lại toàn bộ suite sau khi dừng phase 4 giữa chừng.

## Việc còn lại

1. Chạy spike với key thật và ghi số đo vào mục này.
2. Chạy toàn bộ `.\mvnw.cmd -pl app test` (nền: 4255 test, 0 lỗi, 127 bỏ qua trước phase 4).

## Bổ sung phase 5 (Speaking): công cụ đã viết, CHƯA có số đo

Phase 5 mở rộng hai spike, cả hai chỉ chạy khi `SCORING_AI_SPIKE=true` và **chưa được chạy** (máy làm phase không có
key Gemini lẫn Azure Speech). Mục này chỉ ghi cách đo; không có con số nào được ghi ở đây cho tới khi có người chạy.

- **Độ ổn định Content nói**: `RubricStabilitySpikeTest#allSpeaking` (và `#describeImage`, `#retellLecture`,
  `#respondToSituation`, `#summarizeGroupDiscussion`) chấm 20 transcript tổng hợp trong
  `speaking-transcripts-synthetic.json`, 3 lần mỗi mẫu, bằng scorer DI/RL/RTS/SGD thật (Gemini thật, prompt và schema
  từ catalog); bước Azure được thay bằng stub trả về transcript nên chỉ đo Gemini. Cùng cổng 90% như phần viết.
  Describe Image dùng nhánh dự phòng (mô tả tham chiếu thay ảnh), nên số đo DI không đại diện cho nhánh có ảnh.
- **Tính đơn điệu của Oral Fluency**: `AllScorersSpikeTest#oralFluencyIsMonotonicOnSyntheticHesitations` đánh giá
  12 WAV TTS trong `tts-manifest.json` (4 mẫu x FLUENT / MILD_HESITATION / HEAVY_HESITATION) bằng Azure thật và bảng
  ánh xạ phiên bản 1, khẳng định band FLUENT >= MILD >= HEAVY cho từng mẫu. Đây chỉ là kiểm tra đơn điệu: nó
  **không** hiệu chỉnh bảng ánh xạ, bảng vẫn mang nhãn "chưa hiệu chỉnh với dữ liệu người chấm".
- Lệnh chạy: xem `pte-api/app/src/test/resources/scoring/rubric-spike/README.md`.
