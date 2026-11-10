# Plan: Rubric chấm điểm minh bạch và cấu hình được
Status: ✅ Done (2026-11-05; còn tồn đọng: spike AI chưa chạy, bảng Azure chưa hiệu chỉnh, chưa kiểm trình duyệt)
Date: 2026-11-04
Mode: Hard

Nguồn: [spec.md](spec.md) (Ready, mục "Quyết định đã chốt" có tính ràng buộc, đã cập nhật),
[brainstorm](../../../plans/reports/261104-scoring-rubric-transparency-brainstorm.md),
[báo cáo đối chiếu Pearson (L1-L10)](../../../plans/reports/261104-pte-scoring-pearson-alignment-review.md),
Pearson PTE Academic Test Taker Score Guide 2025 (46 trang; số trang dùng làm trích dẫn trong catalog).

## Overview

Đưa luật chấm 22 task type chuẩn về **một rubric duy nhất, khai báo bằng code theo Pearson**, vừa điều khiển việc chấm
(AI chỉ trả điểm từng tiêu chí theo thang Pearson, backend tính điểm câu bằng một hàm thuần) vừa được hiển thị:
- **vendor-web**: trang luật chấm (A), bộ mô phỏng (C), màn chỉnh tham số có phiên bản và quy trình duyệt (D1);
- **tenant-web**: màn giải thích điểm một lượt thi (B) cho Host (lượt thi của trung tâm mình) và Examiner (lượt thi được phân công),
  cùng màn chấm theo tiêu chí của giám khảo.
Mọi dữ liệu gắn với lượt thi thật **không** đi qua vendor-web. Đồng thời sửa các điểm lệch L1-L10 so với Pearson.

## Kiến trúc (tóm tắt)

```
            +-----------------------------------------------------------+
            |  com.pte.scoring.rubric  (public, NamedInterface "rubric") |
            |  TaskRubric / TraitDefinition / FormRule.bandFor(metrics)  |
            |  EffectiveRubric (đọc từ HÀNG phiên bản, không từ code)    |
            |  RubricScorer.score(effectiveRubric, traitScores)          |
            |      -> ScoreTrace  (gate -> form -> sum(w*a/max)/sum(w))  |
            +----------------------+------------------------------------+
                                   ^ catalog trong code: mô tả mức, thang, trang Pearson, cấu trúc tiêu chí
   internal/rubric/catalog/*  -----+            internal/rubric/service|repository|controller
                                                scoring_rubric_versions: THAM SỐ SỐ HỌC ĐẦY ĐỦ (trọng số, Form band,
                                                cổng, phiên bản bảng Azure, catalog_version) được vật chất hóa vào hàng
                                                       ^
   exam_definitions.rubric_version_public_id ----------+  (ghim khi tạo mẫu đề; giống ghim trọng số)
                                                       |
   AI scorer (Gemini/Azure) --trait bands (Pearson)--> answer_evaluations.criteria_scores_json
                                                       |   {"scale":"PEARSON_V1","rubricVersion":...,"traits":{...}}
   RubricScorer <---- dùng chung: scorer thật | giải thích | mô phỏng | tính lại (0 lời gọi AI)
                                                       |
   ReportSnapshot v2: traitScores + rubricVersion + trace  --> API giải thích điểm (HOST_ADMIN, EXAMINER được phân công)
```

Nguyên tắc cốt lõi:
1. **Một nguồn sự thật cho mô tả và cấu trúc**: catalog trong code. Mô tả mức và thang Pearson KHÔNG sửa được (D2/D3 ngoài phạm vi).
2. **Một hàm tính điểm câu** (`RubricScorer`) và **một hàm tính band Form** (`FormRule.bandFor`), có architecture test cấm nơi khác tự tính.
3. **Tham số số học nằm trong hàng phiên bản DB, đầy đủ và bất biến**: đổi mặc định trong code không bao giờ làm đổi rubric hiệu lực của phiên bản đã có.
4. **AI fail closed**: thiếu/ngoài thang/không nguyên thì thử lại có giới hạn (cùng prompt, không làm tròn), hết lượt thì chấm thất bại.
5. **Điểm tiêu chí lưu theo thang Pearson có dấu phân biệt thang** (`scale`) để đổi rubric là tính lại được mà không gọi AI và phân biệt dữ liệu cũ.

## Phases

| # | Phase | Mục tiêu ngắn | Story / FR | Phụ thuộc | Trạng thái |
|---|---|---|---|---|---|
| 1 | [Catalog rubric + RubricScorer + FormRule + golden test](phase-01-rubric-catalog-pure-scorer.md) | Khai báo 22 task type, hàm thuần, test theo ví dụ Pearson | S2; FR-01, FR-04, FR-10 | - | [x] quality: approved; tests: passed (114) |
| 2 | [Lưu trữ rubric (tham số đầy đủ), V32, ghim vào mẫu đề, API đọc](phase-02-rubric-persistence-pinning.md) | Bảng phiên bản, audit kích hoạt, seed vật chất hóa, ghim, API đọc | S1 (backend), S5 (nền); FR-02, FR-11 | 1 | [x] quality: approved; tests: unit passed, Postgres IT written but skipped (no Docker) |
| 3 | [Scorer viết (SWT, WE, SST) theo rubric](phase-03-writing-scorers.md) | Smoke schema 1 giờ, L1, L3, L4, L5, L10, thử lại có giới hạn, lưu điểm tiêu chí có `scale` | S2; FR-03, FR-05, FR-06 | 1, 2 | [x] tests: passed (full suite 4255, 0 fail; Gemini smoke not run: no key); quality: skipped_by_user |
| 4 | [Đo độ ổn định LLM (dữ liệu tổng hợp) + quyết định provider](phase-04-llm-stability-provider-decision.md) | Chấm lặp 3 lần, >= 90% lệch <= 1 mức; chốt openai-compatible | Success Criteria "ổn định LLM" | 3 | [x] tests: passed (công cụ đo; spike chưa chạy: không có key Gemini, chưa có số đo); quality: skipped_by_user |
| 5 | [Scorer nói (RA, RS, DI, RL, RTS, SGD, ASQ) theo rubric](phase-05-speaking-scorers.md) | L2, L5, L6, L7, L1; bảng Azure -> 0-5 chưa hiệu chỉnh | S2; FR-03, FR-06 | 1, 2, 4 | [x] tests: passed (full suite 4410, 0 fail, 137 skip; spike nói chưa chạy: không key Gemini/Azure); quality: skipped_by_user |
| 6 | [Vết tổng hợp, snapshot v2, API giải thích (Host/Examiner), tính lại](phase-06-aggregation-trace-explanation-api.md) | Mọi con số 10-90 giải thích được, khớp snapshot, cách ly tenant | S3; FR-02, FR-05, FR-07 | 3, 5 | [x] tests: passed (full suite 4468, 0 fail, 137 skip; Postgres IT/AI spike chưa chạy); quality: skipped_by_user |
| 7 | [vendor-web trang luật chấm (A) + tenant-web màn giải thích (B)](phase-07-web-rubric-viewer-explanation.md) | Màn A trên vendor, màn B trên tenant | S1, S3; FR-01, FR-07, FR-10 | 2, 6 | [x] tests: passed (vitest api-client 675, vendor-web 281, tenant-web 635, ui 348; tsc/eslint sạch ngoài lỗi `.next/types` cũ; chưa chạy trình duyệt); quality: skipped_by_user |
| 8 | [Bộ mô phỏng (API + màn C vendor-web)](phase-08-simulator.md) | Nhập điểm tiêu chí giả định, xem vết | S4; FR-08 | 1, 2, 7 | [x] tests: 4543/0 failures/0 errors/73 skipped; vendor 287; api-client 678; ui 348; tsc vendor limited by existing generated types; quality: skipped_by_user; decision: user_confirmed_skip |
| 9 | [Chỉnh rubric D1 + quy trình duyệt + audit](phase-09-rubric-editing-workflow.md) | Nháp/duyệt = kích hoạt/từ chối, diff xác nhận trước khi kích hoạt, audit | S5; FR-09 | 2, 7 | [x] tests: 4602/0 failures/0 errors/73 skipped; Postgres IT 4 passed; vendor 303; api-client 685; existing generated tsc error; quality: skipped_by_user; decision: user_confirmed_skip |
| 10 | [Giám khảo chấm theo từng tiêu chí (P2, breaking, tenant-web)](phase-10-examiner-trait-scoring.md) | L8: điểm tiêu chí, fallback Azure, điểm câu tính ở server | S6 | 3, 5, 6 | [x] tests: 4641/0 failures/0 errors/73 skipped (Postgres IT chạy, V33 áp dụng 15 lần); tenant-web 649, api-client 685; tsc tenant-web chỉ còn 2 lỗi `.next/types` cũ; chưa chạy trình duyệt; ExaminerTraitSubmitIT không viết (thay bằng unit); quality: skipped_by_user; decision: user_confirmed_skip |
| 11 | [Tài liệu, báo cáo xác minh, snapshot AGENTS](phase-11-docs-verification.md) | Đóng kế hoạch, cập nhật báo cáo đối chiếu | tất cả | 1-10 | [x] tests: đọc lại XML toàn suite 4641/0/0/73; FE vitest vendor 303, tenant 649, practice 636; tsc chỉ lỗi `.next/types` cũ; spike AI chưa chạy; báo cáo `261105-scoring-rubric-transparency-verification.md`; quality: skipped_by_user |

Story: S1 = trang luật chấm (P1); S2 = điểm tính từ rubric (P1); S3 = giải thích một lượt thi (P1); S4 = mô phỏng (P2);
S5 = chỉnh tham số, phiên bản, gắn mẫu đề (P2); S6 = giám khảo chấm theo tiêu chí (P2).

## Thứ tự phụ thuộc

```
1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7 -> 8
                         \-> 10        7 -> 9
                                       (1..10) -> 11
```

Mỗi phase biên dịch và test độc lập. Phase 1-7 là P1 (S1, S2, S3); Phase 8-10 là P2. Phase 7 chỉ cần Phase 2 (API đọc) và Phase 6 (API giải thích).
Việc commit và triển khai do người dùng tự xử lý; kế hoạch không chứa bước release.

## Nhịp kiểm tra chung (mọi phase backend)

- Đọc đủ `docs/CODING_STANDARDS_API.md` trước khi sửa mã; phase có endpoint/lỗi đọc thêm `docs/API_RESPONSE_SETUP.md`,
  `docs/COMMON_EXCEPTION_SETUP.md`; phase đổi role/quyền đọc `docs/TEST_SCENARIOS_IAM.md`. Phase frontend đọc `docs/CODING_STANDARDS_WEB.md`.
- Lệnh (từ `D:\GitHub\pte-org\pte-api`): `.\mvnw.cmd -pl app -DskipTests compile`, test nhắm đích `-Dtest=`, và bộ ratchet
  `-Dtest="PackageDensityTest,SourceFileSizeTest,NoDirectClockAccessTest,ModuleStructureTest"`. Allowlist trong
  `app/src/test/resources/architecture/` phải giữ rỗng.
- Ghi nhớ dev: sau thay đổi `pte-api` cần build lại container `app` local; profile `local-schema` bỏ qua Flyway nên áp tay migration.
- Frontend: `pnpm --filter vendor-web|tenant-web typecheck | lint | test` (từ `D:\GitHub\pte-org\pte-web`). KHÔNG Playwright/trình duyệt.

## Research Summary

Không có researcher riêng; kết luận dựa trên hai báo cáo đầu vào, kiểm tra mã và các quyết định đã chốt của người dùng.

1. **Số hiệu migration**: `db/migration` hiện có V1..V31 (V12 không tồn tại). Migration rubric là **V32**; migration của Phase 10 lấy
   **số tiếp theo còn trống (kiểm tra lúc làm)**. V32 mang tính **cộng thêm (additive)**, chạy được trên DB hiện có; reset DB chỉ là tùy chọn để có dữ liệu demo sạch.
2. **Ghim phiên bản**: lượt thi ghim `examDefinitionPublicId` (`AttemptScoreContextView`), `answer_evaluations` có `exam_definition_public_id`;
   rubric ghim qua `exam_definitions.rubric_version_public_id`. Việc chấm resolve rubric **tại thời điểm thực thi job** (worker), không lúc xếp hàng.
3. **Vòng phụ thuộc module**: `scoring` đã phụ thuộc `assessment`; `assessment` không phụ thuộc `scoring` => cổng ghim khai báo ở `assessment`, `scoring` hiện thực.
4. **Mật độ gói**: `scoring/internal/repository` 14 file, `scoring/internal/service/examiner` 15 file, `scoring/internal/vendor/azure` 14 file => class mới vào gói con riêng.
5. **Luồng luyện tập** (`pte-practice`) dùng cùng scorer, không có mẫu đề (dùng bản ACTIVE) và hiển thị `subScores`: đọc được cả dữ liệu cũ (0-100) lẫn mới (Pearson) nhờ trường `scale`.
6. **Phạm vi dữ liệu lượt thi**: spec đã chốt màn giải thích ở tenant-web; chỉ `HOST_ADMIN` (tenant mình) và `EXAMINER` (lượt thi được phân công, dùng
   `ScoringService.isAttemptAssignedToExaminer` -> `ExaminerWorkQueryService.isAssignedToExaminer`) gọi được API giải thích; vendor không có đường đọc dữ liệu lượt thi.
7. **Chấm lại câu thất bại có sẵn**: Host gọi `POST /api/v1/sessions/{sessionPublicId}/score` (`ScoringCommandController` -> `ScoringCommandService`,
   `AiEvaluationRepository.findScoringWork`) đưa lại các câu `SCORING_FAILED` và câu AI_SCORING quá hạn (`scoring.ai.stale-dispatch-minutes`, mặc định 10) về hàng đợi; không cần thêm hành động mới.
8. **Tổng điểm tiêu chí Pearson**: DI/RL/RTS/SGD = 16; WE = 26; SWT = 9; SST = 12; RS = 13; RA = N + 10 (N = số từ đoạn văn).

## Dependencies

- Gemini (`SCORING_AI_GEMINI_API_KEY`) và Azure Speech key thật cho smoke schema (Phase 3), đo độ ổn định (Phase 4) và hiệu chỉnh sơ bộ Fluency (Phase 5); biến `SCORING_AI_SPIKE=true`, `SCORING_AI_SPIKE_DIR`, `SCORING_AI_SPIKE_WAV_DIR` (xem `SpikeSupport`).
- Bộ dữ liệu **tổng hợp** do trợ lý AI tạo trong lúc làm Phase 4/5 (không cần dữ liệu người chấm, không chặn phase).
- Postgres throwaway cho test tích hợp (runbook `pte-doc/projects/plans/quang-entity-consolidation/local-dev-runbook.md`): trigger bất biến, chỉ mục ACTIVE, thứ tự retire-rồi-activate.

## Câu hỏi mở

1. **Provider `openai-compatible`**: ĐÃ CHỐT phương án B (Phase 4): không hỗ trợ task type có rubric, fail closed `AI_RUBRIC_SCORER_UNAVAILABLE`. Báo cáo: `pte-doc/plans/reports/261105-scoring-rubric-llm-stability-spike-report.md`.
2. **Spelling của Write Essay**: ĐÃ CHỐT giữ LLM đếm lỗi; chưa có số liệu dao động vì spike chưa chạy (Phase 11).

Các câu hỏi đã chốt (ghi để truy vết): ai xem giải thích (U1), dữ liệu hiệu chỉnh (U2), trạng thái phiên bản = approve là activate (U4),
Read Aloud Content động theo số từ N (nêu rõ ở Phase 1 và 5), trọng số số nguyên 0-10 (MEDIUM-3), schema Gemini chốt bằng smoke ở đầu Phase 3 (MEDIUM-5).

## Risks

- HIGH: Phạm vi lớn (11 phase, đổi thang điểm tiêu chí, đổi hợp đồng với pte-practice và tenant-web giám khảo) — mỗi phase biên dịch/test độc lập, không gộp phase.
- HIGH: LLM không ổn định hoặc không theo schema số nguyên — smoke schema 1 giờ ở đầu Phase 3; thử lại có giới hạn (tối đa 2 lần gọi thêm, không làm tròn); Phase 4 đo ổn định trên dữ liệu tổng hợp; nếu < 90% thì trung vị 3 lần cho tiêu chí không ổn định.
- HIGH: Đổi rubric làm đổi điểm đã công bố hoặc làm đổi rubric hiệu lực của phiên bản cũ — tham số đầy đủ vật chất hóa vào hàng phiên bản (HIGH-3), ghim vào mẫu đề, snapshot v2, trigger + service guard, test "đổi mặc định trong code không đổi rubric hiệu lực của phiên bản đã có".
- HIGH: Vòng phụ thuộc Spring Modulith — cổng ghim ở `assessment`, hiện thực ở `scoring`; `ModuleStructureTest` cuối Phase 2.
- HIGH (đã giảm): Dữ liệu chấm cũ thang 0-100 lẫn dữ liệu mới — dấu `scale` trong JSON điểm tiêu chí từ Phase 3, pte-practice đọc được cả hai (HIGH-5).
- HIGH (ghi nhận, giảm nhẹ): Không có dữ liệu người chấm — dùng dữ liệu tổng hợp chỉ để đo ổn định; bảng Azure -> 0-5 phát hành ở trạng thái **chưa hiệu chỉnh** có nhãn hiển thị (HIGH-6, HIGH-7).
- MEDIUM: Rò dữ liệu lượt thi xuyên tenant hoặc giữa giám khảo — chỉ `HOST_ADMIN` (kiểm tra tenant) và `EXAMINER` (kiểm tra phân công); test cách ly tenant và giám khảo không được phân công.
- MEDIUM: `PackageDensityTest` và `SourceFileSizeTest` — catalog nhiều văn bản: tách file theo task type.
- MEDIUM: Snapshot cũ (schemaVersion 1) phải giải mã được — codec nhận 1 và 2; test với fixture v1.
- MEDIUM: Hai lần kích hoạt đồng thời hoặc thứ tự flush làm vi phạm chỉ mục một ACTIVE — retire bản cũ bằng câu lệnh native + flush trước khi kích hoạt bản mới; Postgres IT.
- MEDIUM: Số endpoint thay đổi làm `ApiInventoryExportTest` lệch — cập nhật ở mỗi phase thêm endpoint.
- LOW: Đổi tên khóa `subScores` (`ORAL_FLUENCY`...) làm hỏng nhãn FE — cập nhật `pte-practice` ở Phase 3 và 5.
- LOW: AGENTS.md lệch với thực tế (số migration) — Phase 11 cập nhật.

## Lịch sử sửa đổi

Bản sửa đổi 2026-11-04 (sau đánh giá phản biện và quyết định của người dùng):

| Mã | Thay đổi | Nơi áp dụng |
|---|---|---|
| U1 | Màn giải thích (B) chuyển sang tenant-web; chỉ `HOST_ADMIN` (tenant mình) và `EXAMINER` (được phân công, dùng `ScoringService.isAttemptAssignedToExaminer`); bỏ `PLATFORM_ADMIN` và mọi truy cập vendor vào dữ liệu lượt thi; Host thấy tham số phiên bản ACTIVE/RETIRED đã ghim ngay trong phản hồi giải thích, không bao giờ thấy bản nháp; yêu cầu test cách ly tenant và giám khảo không được phân công | plan.md, Phase 6, 7, 10 |
| HIGH-2 | Bỏ hoàn toàn tham số `compareRubricVersion` và mọi so sánh xuyên phiên bản trong API giải thích | Phase 6, 7, 9 |
| U2 | Bỏ phụ thuộc "dữ liệu có nhãn của nhóm học thuật"; dùng bộ dữ liệu tổng hợp (khoảng 20 bài viết + 20 transcript nói theo từng mức Pearson; WAV TTS có chèn ngập ngừng chỉ để kiểm tra tính đơn điệu của Fluency); đo ổn định (không cần nhãn) và "khớp mức dự định" chỉ báo cáo, không phải cổng; bảng Azure -> 0-5 phát hành chưa hiệu chỉnh kèm nhãn "chưa hiệu chỉnh với dữ liệu người chấm" trên vendor-web, tenant-web và báo cáo xác minh | plan.md, Phase 4, 5, 6, 7, 11 |
| HIGH-6, HIGH-7 | Ghi nhận rủi ro thiếu dữ liệu người chấm/mẫu có nhãn; giảm nhẹ bằng U2 | plan.md |
| U3 | Bỏ thứ tự release, điểm dừng cho production, xả hàng đợi, thứ tự triển khai, runbook rollback và bước commit; giữ an toàn mức mã: trường `scale` ("PEARSON_V1") và `rubricVersion` trong JSON điểm tiêu chí từ Phase 3, pte-practice đọc cả hai dạng (`subScoreMax` tùy chọn, dự phòng số thô) | tất cả phase |
| HIGH-5, MEDIUM-10 | Giảm HIGH-5 theo U3; tương thích ngược pte-practice theo U3 | plan.md, Phase 3, 5 |
| U4 | Duyệt = kích hoạt (không có APPROVED riêng); trước khi kích hoạt hiện diff với bản ACTIVE và bắt xác nhận; ghi một dòng audit cho mỗi lần kích hoạt (ai, khi nào, tóm tắt diff); `approver_user_public_id` được đặt ở đường `PATCH status ACTIVATE` | Phase 2, 9 |
| MEDIUM-9, LOW-1 | Nội dung của U4 (audit, `approver_user_public_id`, xác nhận diff) | Phase 2, 9 |
| HIGH-3 | Vật chất hóa đầy đủ tham số hiệu lực (trọng số, Form band, cổng, phiên bản bảng Azure, `catalog_version`) vào hàng phiên bản lúc seed/tạo; không dùng `'{}'` nghĩa "theo code"; tính lại và giải thích đọc tham số từ hàng; quy tắc `catalog_version` lệch code chỉ bị từ chối khi cấu trúc (khóa/thang tiêu chí) khác; test đổi mặc định code không đổi rubric hiệu lực | Phase 1, 2, 6, 9 |
| HIGH-4 | Thử lại có giới hạn khi vi phạm schema (tối đa 2 lần gọi thêm, cùng prompt, không làm tròn), ghi số lần thử trong `detailJson`, hết lượt thì fail closed với lý do hiện có; nêu rõ đường chấm lại câu thất bại có sẵn (`POST /api/v1/sessions/{sessionPublicId}/score`) | Phase 3, plan.md |
| MEDIUM-1 | Kích hoạt: retire bản ACTIVE cũ bằng câu lệnh native + flush trước khi kích hoạt bản mới; trigger nêu đúng cột và chuyển trạng thái cho phép; Postgres IT gồm ca thứ tự flush | Phase 2, 9 |
| MEDIUM-2 | `exam_definitions.rubric_version_public_id` nullable ở mức DB; bắt buộc khác null ở service cho mẫu đề mới | Phase 2 |
| MEDIUM-3 | Trọng số số nguyên 0-10; tiêu chí cổng phải > 0; tổng trọng số mỗi task type > 0 | Phase 1, 2, 9 |
| MEDIUM-4 | Read Aloud: N tối thiểu 1, N = 0 là lỗi đề; N lưu trong tập điểm tiêu chí; trình chỉnh nêu RA Content dựa theo độ dài (trọng số chỉnh được, thang động); test vàng N = 1, 30, 80 | Phase 1, 5, 9 |
| MEDIUM-5 | Smoke schema Gemini 1 giờ (chấp nhận enum số nguyên) ở ĐẦU Phase 3; Phase 3 chốt biến thể schema; Phase 4 chỉ đo ổn định | Phase 3, 4 |
| MEDIUM-6 | `FormRule.bandFor(TextMetrics)` thuần trong gói rubric (TextMetrics: số từ, số câu, toàn chữ hoa, có dấu câu, chỉ gạch đầu dòng); `FormCheck` tính metrics rồi gọi; mô phỏng gọi cùng hàm; mở rộng architecture test một nguồn | Phase 1, 3, 8 |
| MEDIUM-7 | Màn giám khảo nhận điểm câu tính ở server trong phản hồi lưu nháp/nộp; dấu vân tay và `reviewVersion` gồm `traitScores`; phạm vi tenant-web đã được spec duyệt; bỏ phương án gọi API mô phỏng từ giám khảo | Phase 10 |
| MEDIUM-8 | V32 additive chạy trên DB hiện có (reset DB tùy chọn); job đang chạy resolve rubric tại thời điểm thực thi, ghi tài liệu, không có thủ tục triển khai | plan.md, Phase 2, 3 |
| LOW-2 | Phase 6 giao bộ dựng fixture phủ 22 task type, câu bỏ trống, nguồn giám khảo, giải mã snapshot v1, các độ dài Read Aloud | Phase 6 |
| LOW-3 | Giới hạn số phần tử `traitScores` và kích thước JSON tham số trong `RubricConstants`, kiểm tra trước khi lưu | Phase 2, 8, 9, 10 |
| LOW-4 | Bỏ hành động `PATCH /exam-definitions/{id}/rubric` (ghim lại mẫu DRAFT) | Phase 9 |
| (số migration) | Kiểm tra lại: V31 là cao nhất; V32 cho rubric; Phase 10 lấy số tiếp theo còn trống lúc làm | plan.md, Phase 2, 10 |
| (câu hỏi mở) | Chỉ còn 2 câu hỏi mở: provider `openai-compatible` và Spelling của Write Essay | plan.md |

## Kết luận rủi ro (Phase 11, 2026-11-05)

- Đã đóng: cổng/Form/tỉ trọng (L1-L7, L10), ghim phiên bản và bất biến (Postgres IT 12/12), cách ly tenant/giám khảo, tính lại không gọi AI, vòng phụ thuộc module, ratchet.
- Còn mở: độ ổn định LLM chưa đo (không key); bảng Azure -> 0-5 chưa hiệu chỉnh; dữ liệu tổng hợp không chứng minh độ chính xác; chưa kiểm trình duyệt/`next build`;
  quality gate chỉ chạy Phase 1-2; L8 làm một phần (không có người phân xử). Chi tiết: `pte-doc/plans/reports/261105-scoring-rubric-transparency-verification.md`.
