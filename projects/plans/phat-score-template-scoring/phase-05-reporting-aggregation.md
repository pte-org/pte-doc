# Phase 5: Reporting tính điểm có trọng số (FR-18/19/20) + xóa task-skill-mapping.json

Covers spec FR-18, FR-19, FR-20, và phần reporting của FR-07 ("xóa `task-skill-mapping.json`"). Đây là phase thay đổi công thức chấm điểm cốt lõi — cần review kỹ trước khi coi là xong (xem Risk ở `plan.md`).

## Requirements

`ScoreAggregationService` tính điểm mỗi skill theo công thức trọng số FR-18 (`10 + 80 × Σ(w×avgRaw/100) / Σw`, chỉ tính trên các dạng có mặt trong đề và có ≥1 câu SCORED), chỉ báo điểm cho skill thuộc `selectedSkills`/tested-skills của snapshot (FR-19), và Overall chỉ tính khi đủ cả 4 skill (FR-20). `config/task-skill-mapping.json` và `TaskSkillMappingConfig` bị xóa hoàn toàn — bao gồm cả nơi dùng chung ở `itembank` (xem quyết định trong `plan.md`).

## Files

**Sửa**
- `pte-api/app/src/main/java/com/pte/reporting/internal/service/ScoreAggregationService.java` — viết lại `aggregate()`: input đổi từ `(attemptPublicId, tenantId)` sang thêm gọi `attemptService.getScoreContext(attemptPublicId)` (Phase 3) lấy `scoreTemplatePublicId` + `testedSections`; gọi `scoreTemplateService.getByPublicId(scoreTemplatePublicId)` lấy toàn bộ item + weight; group `ScoredAnswerView` (đã có từ `scoringService.getScoredAnswersForAttempt`) theo `taskType`, tính `avgRaw_type`; với mỗi skill ∈ `{SPEAKING, WRITING, READING, LISTENING}` ∩ `testedSections`, áp công thức FR-18 dùng `BigDecimal` (tránh sai số double khi chia trọng số phần trăm); Overall dùng `overallWeight`, chỉ tính khi `testedSections` có đủ 4 giá trị.
- `pte-api/app/src/main/java/com/pte/reporting/domain/enums/Skill.java` — rút còn 4 giá trị (`LISTENING, READING, SPEAKING, WRITING`), bỏ hẳn `isCommunicative()` (không còn ý nghĩa khi mọi giá trị còn lại đều communicative).
- `pte-api/app/src/main/java/com/pte/reporting/internal/mapper/ReportMapper.java` — `communicativeSkills` = **chỉ các skill đã thi** (tested sections của snapshot); `overall` = `null` khi kỳ thi không đủ 4 skill. Sửa kèm `pte-api/app/src/main/java/com/pte/reporting/internal/dto/response/ReportResponse.java` — **xóa field `enablingSkills`** (quyết định user: xóa hẳn + sửa app mobile ở Phase 7).
- `pte-api/app/src/main/java/com/pte/reporting/internal/service/AttemptScoreSummary.java`, `SkillScore.java` — kiểm tra không còn tham chiếu gì tới enabling skill hay `TaskSkillMappingConfig`.
- `pte-api/app/src/main/java/com/pte/itembank/ItembankService.java` — bỏ tham số/field `PteTaskTypeSkillMapping skillMapping`, bỏ tính `skills` trong `toResponse()`.
- `pte-api/app/src/main/java/com/pte/itembank/internal/mapper/QuestionMapper.java` — bỏ tham số `skills` khỏi `toResponse(...)`.
- `pte-api/app/src/main/java/com/pte/itembank/dto/response/QuestionResponse.java` — bỏ field `skills`.
- `pte-web/packages/api-client/src/types/question/index.ts` — bỏ `skills: string[]` khỏi `QuestionResponse` (đã xác nhận không nơi nào tiêu thụ field này).

**Xóa**
- `pte-api/app/src/main/java/com/pte/reporting/internal/config/TaskSkillMappingConfig.java`.
- `pte-api/app/src/main/java/com/pte/itembank/internal/config/PteTaskTypeSkillMapping.java`.
- `pte-api/app/src/main/java/com/pte/itembank/domain/enums/Skill.java` (không còn ai dùng sau khi bỏ `skills` khỏi `QuestionResponse` — xác nhận lại bằng grep trước khi xóa).
- `pte-api/app/src/main/resources/config/task-skill-mapping.json`.

## Steps

1. Viết lại `ScoreAggregationService` theo công thức FR-18/19/20 dùng `BigDecimal`, làm tròn cuối bằng `RoundingMode.HALF_UP` (tương đương `Math.round` hiện tại với số dương); phép chia trung gian dùng `MathContext.DECIMAL64`. **Guard bắt buộc:** nếu `Σw == 0` cho một skill (chưa có câu SCORED nào trong các dạng có trọng số của skill đó — tình huống thường gặp khi AI đang chấm bất đồng bộ) → trả `SkillScore.insufficientData()`, không bao giờ chia; áp dụng tương tự cho Overall; group `ScoredAnswerView` theo `taskType` (không còn khái niệm "1 answer đóng góp nhiều skill" của mapping cũ — nay 1 `taskType` chỉ đóng góp qua đúng các cột weight khác 0 của dòng template tương ứng).
2. Đổi `reporting.domain.enums.Skill` còn 4 giá trị; sửa mọi nơi dùng `isCommunicative()`/`GRAMMAR`/`ORAL_FLUENCY`/... (chỉ còn trong `ReportMapper` và test) để hết lỗi biên dịch.
3. Xóa `enablingSkills` khỏi `ReportResponse` + `ReportMapper`; `communicativeSkills` chỉ gồm skill đã thi; `overall` null khi không đủ 4 skill (FR-20 — "không áp dụng", khác với `sufficientData=false` = "chưa đủ dữ liệu"). Phía `pte-app` sửa ở Phase 7, chạy liền sau phase này.
4. Gỡ `PteTaskTypeSkillMapping`/`skills` khỏi `itembank` (service, mapper, DTO) và khỏi `QuestionResponse` phía `pte-web` — xác nhận lại bằng grep rằng không còn nơi nào tiêu thụ trước khi xóa `itembank.domain.enums.Skill`.
5. Xóa `TaskSkillMappingConfig`, `PteTaskTypeSkillMapping`, `config/task-skill-mapping.json`; grep toàn repo xác nhận sạch.
6. Viết lại toàn bộ `ScoreAggregationServiceTest` theo bộ ví dụ số của FR-18/19/20 (thay hoàn toàn bộ test cũ dựa trên `TaskSkillMappingConfig`, không giữ lại test nào giả định "mọi câu trọng số bằng nhau").
7. Chạy `mvnw test`, xác nhận không còn lỗi biên dịch ở `itembank`/`reporting` sau khi xóa 2 config + 1 enum.

## Tests

`ScoreAggregationServiceTest` viết lại hoàn toàn, dùng dữ liệu template giả lập (mock `ScoreTemplateService.getByPublicId` trả về vài dòng template tối giản, không cần đủ 22 dòng), tối thiểu các case:

- Một skill có đúng 1 dạng đóng góp, 1 câu SCORED → điểm khớp tính tay theo FR-18.
- Một skill có 2 dạng đóng góp, mỗi dạng nhiều câu → `avgRaw_type` đúng trung bình, tổng trọng số đúng `Σw`.
- Một dạng có mặt trong đề nhưng 0 câu SCORED → dạng đó bị loại khỏi cả tử và mẫu của công thức (không tính là `avgRaw = 0`).
- Skill được thi nhưng **mọi** dạng có trọng số của nó đều 0 câu SCORED (AI chưa chấm xong) → skill đó "insufficient data", không `ArithmeticException`; Overall đủ 4 skill nhưng `Σw_overall == 0` → "insufficient data".
- Ranh giới làm tròn: bộ số cho kết quả trước làm tròn đúng `x.5` → làm tròn lên (HALF_UP).
- `testedSections` chỉ có 2/4 skill (thi 2 skill) → kết quả **chỉ chứa** 2 skill đó, dù có dữ liệu thô đóng góp cho skill khác (vd RS có weight Listening) (FR-19; spec: "kết quả chỉ có skill thuộc section đã chọn").
- `testedSections` đủ 4 → Overall tính theo `overallWeight`; `testedSections` thiếu 1 → `overall == null` (FR-20).
- Case tổng hợp dùng đúng bộ số trong bảng seed V5 (Phase 1) cho 1 skill, đối chiếu tay bằng máy tính, gắn liền với success criterion "Unit test FR-18: bộ rawScore đã biết → skill/Overall score đúng từng điểm" của spec.
- `ReportMapperTest` (nếu chưa có, viết mới): JSON không còn key `enablingSkills`; thi 2 skill → `communicativeSkills` có 2 phần tử, `overall` null.
- `./mvnw test -pl app`.

## Success Criteria

- `mvnw test` xanh, `ScoreAggregationServiceTest` phủ đủ các case FR-18/19/20 ở trên.
- `grep -rn "task-skill-mapping" pte-api/app/src` không còn kết quả (khớp trực tiếp success criterion của spec).
- `grep -rn "TaskSkillMappingConfig\|PteTaskTypeSkillMapping" pte-api/app/src` không còn kết quả.
- Kịch bản thủ công (hoặc test tích hợp mức service): kích hoạt một `ScoreTemplate` mới (weight khác), gọi lại `getReport` cho một attempt cũ đã pin template V5 → điểm không đổi (vì `ScoreAggregationService` luôn tra theo `scoreTemplatePublicId` đã pin, không phải template ACTIVE hiện tại) — khớp trực tiếp success criterion "Kích hoạt template mới → điểm của 100% attempt đã có không đổi".
- `pte-web` build không lỗi kiểu sau khi bỏ `skills` khỏi `QuestionResponse` (chạy `tsc`/`next build` cho `vendor-web` nếu có script sẵn — xác nhận không nơi nào còn đọc `response.skills`).

## Risks

- Đây là thay đổi công thức chấm điểm cốt lõi, ảnh hưởng mọi report — không có cách nào rollback tự động nếu công thức triển khai sai lệch so với FR-18; yêu cầu review kỹ + test số liệu tay trước khi merge (đã nêu ở `plan.md`).
- Gỡ `itembank.PteTaskTypeSkillMapping`/`skills` là mở rộng phạm vi ngoài FR-01..FR-20 nhưng cần thiết để thỏa mãn đúng nghĩa đen success criterion "xóa task-skill-mapping.json" — nếu người review muốn giữ tính năng gắn nhãn skill của `itembank` (dù đang dead trên FE), phải tách file JSON thành 2 file riêng thay vì xóa, và chấp nhận không đạt 100% success criterion đó.
- HIGH: Xóa `enablingSkills` + `overall` nullable phá hợp đồng với `pte-app` hiện tại (`json['enablingSkills'] as List` crash) — phải chạy Phase 7 ngay sau phase này, không dùng app bản cũ với backend mới.
- Cache của `ScoreTemplateService` (nếu Phase 4 đã thêm) cần đủ nhất quán để `ScoreAggregationService` và `scoring` không đọc lệch nhau trong cùng 1 request — nếu có cache, đảm bảo scope cache là theo `scoreTemplatePublicId` (bất biến), không theo thời gian.
