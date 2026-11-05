# Phase 11: Tài liệu, báo cáo xác minh, cập nhật AGENTS.md

## Mục tiêu

Đóng kế hoạch: đối chiếu Success Criteria của spec bằng chứng chạy thật, cập nhật trạng thái báo cáo đối chiếu Pearson (L1-L10), viết báo cáo xác minh, và cập nhật `AGENTS.md` (kiến trúc, số migration, số endpoint, quy tắc mới).

## Stories/FR covered

- Tất cả (S1-S6, FR-01..FR-11); Success Criteria: độ phủ 22/22, giải thích chênh lệch 0, mô phỏng 100%, hồi quy Pearson, ghim phiên bản, tính lại 0 lời gọi AI, độ ổn định LLM >= 90%

## Files to read first

- `D:\GitHub\pte-org\AGENTS.md` ("Review reports and documentation location", "Current work snapshot", "Backend development", "Mandatory coding-standards gate")
- `spec.md` (Success Criteria, Quyết định đã chốt), `plan.md` (trạng thái phase, "Lịch sử sửa đổi")
- `D:\GitHub\pte-org\pte-doc\plans\reports\261104-pte-scoring-pearson-alignment-review.md` (L1-L10, mục 8)
- Báo cáo spike Phase 4: `pte-doc/plans/reports/*scoring-rubric-llm-stability-spike-report.md` và `assets/`
- Kết quả test Phase 1-10; `ApiInventoryExportTest` (số endpoint hiện 258); allowlist `app/src/test/resources/architecture/` (phải rỗng)
- Quy ước báo cáo: `YYMMDD-<topic>-<report-type>.md`; assets ở `reports/assets/<tên-báo-cáo-không-đuôi>/`

## Implementation steps

1. **Chạy bộ kiểm tra cuối** và lưu kết quả thật: toàn suite `app`, ratchet (`PackageDensityTest`, `SourceFileSizeTest`, `NoDirectClockAccessTest`, `ModuleStructureTest`, `RubricScoreSingleSourceTest`), test Postgres IT (V32 và migration Phase 10, trigger, chỉ mục ACTIVE, ca thứ tự flush, kích hoạt đồng thời, audit),
   FE (`vendor-web`, `tenant-web`, `pte-practice`: `typecheck`, `lint`, `test`). Ghi chính xác ranh giới đã kiểm tra và test bị bỏ qua (spike vendor cần khóa thật).
2. **Bảng đối chiếu Success Criteria**: từng tiêu chí -> bằng chứng (test, kết quả, số liệu): 22/22 trang luật chấm; giải thích chênh lệch 0 trên bộ fixture phủ 22 task type; mô phỏng 100% gồm cổng 7 task type; ví dụ Pearson (essay < 120 chữ = 0, essay 150 chữ Form = 1, DI Content = 0 = 0);
   đổi rubric không đổi snapshot đã publish; **đổi mặc định trong code không đổi rubric hiệu lực của phiên bản đã có**; tính lại 0 lời gọi vendor; **cách ly tenant và giám khảo không được phân công** (API giải thích); độ ổn định LLM theo báo cáo spike. Tiêu chí chưa đạt ghi rõ, không ghi "đạt" khi thiếu bằng chứng.
3. **Đo p95** API luật chấm và mô phỏng < 300 ms, giải thích < 800 ms trên môi trường local với fixture; ghi điều kiện đo; không API nào gọi AI.
4. **Cập nhật báo cáo đối chiếu** `261104-pte-scoring-pearson-alignment-review.md`: thêm mục "Trạng thái xử lý" L1-L10 (phase đã sửa, phần còn lại; L9 giữ "không quy định"; L8 mức đã làm) và đính chính mô tả hệ thống cũ không còn đúng (công thức trung bình 0-100, khóa `subScores` cũ). Giữ nội dung gốc, thêm phần cập nhật có ngày.
5. **Báo cáo xác minh** `pte-doc/plans/reports/<YYMMDD>-scoring-rubric-transparency-verification.md`: phạm vi, lệnh đã chạy và kết quả, bảng Success Criteria, số liệu ổn định, điểm chưa đạt hoặc đổi so với kế hoạch (quyết định `openai-compatible`, câu hỏi mở đã chốt), việc tồn đọng. **Nêu rõ**: (a) bảng Azure -> 0-5 **chưa hiệu chỉnh với dữ liệu người chấm**;
   (b) bộ dữ liệu kiểm tra là **tổng hợp do AI tạo**, chỉ chứng minh độ ổn định, không chứng minh độ chính xác chấm; (c) WAV TTS chỉ kiểm tra tính đơn điệu của Fluency. Ảnh/số liệu máy đọc trong `reports/assets/<tên-báo-cáo>/`, liên kết tương đối; không để ở Temp hay trong repo ứng dụng.
6. **Cập nhật `AGENTS.md`**: snapshot: rubric catalog (`com.pte.scoring.rubric`, `RubricScorer`, `FormRule.bandFor`), bảng `scoring_rubric_versions` và `scoring_rubric_activation_audits`, số migration thực tế (V32 và số của Phase 10), `exam_definitions.rubric_version_public_id`, snapshot v2, dấu `scale = PEARSON_V1`, quyền xem giải thích (Host/Examiner được phân công),
   số endpoint mới (cập nhật số 258 theo `ApiInventoryExportTest`), số test, quy tắc "mọi điểm câu AI qua `RubricScorer`, band Form qua `FormRule`" và ratchet `RubricScoreSingleSourceTest` (allowlist rỗng). Sửa mô tả "V1 baseline + V2+" cho khớp thực tế (đã có V1..V31 trước kế hoạch). Không thêm bí mật, khóa hay giá trị `.env`.
7. **Đóng kế hoạch**: cập nhật `plan.md` (đánh dấu từng phase, Status, quyết định cho 2 câu hỏi mở còn lại, kết luận rủi ro); mỗi phase có "Quality and Testing State" phản ánh đúng sau khi chạy `/ck:quality --gate`.
8. **Ghi chú vận hành ngắn** (trong báo cáo xác minh): cách thêm task type hoặc đổi mô tả mức (đổi catalog, tăng `catalogVersion`, tạo phiên bản rubric mới), chạy lại spike khi đổi model Gemini, cách hiệu chỉnh bảng Azure khi có dữ liệu người chấm (tạo `azureBandMappingVersion` mới + phiên bản rubric mới).

## Acceptance criteria

- Báo cáo xác minh ở `pte-doc/plans/reports/` đúng quy ước tên, có lệnh đã chạy, kết quả thật, bảng Success Criteria; nêu rõ ba giới hạn (Azure chưa hiệu chỉnh, dữ liệu tổng hợp, TTS); không tiêu chí nào "đạt" thiếu bằng chứng.
- Toàn suite `app` xanh (hoặc test đỏ không liên quan được báo cáo rõ); ratchet xanh với allowlist rỗng; FE `typecheck/lint/test` xanh cho ứng dụng đã sửa.
- Báo cáo đối chiếu Pearson có trạng thái L1-L10 và đính chính.
- `AGENTS.md` phản ánh đúng kiến trúc, số migration, số endpoint; không bí mật.
- `plan.md` ở trạng thái cuối đúng thực tế.

## Validation commands

```powershell
cd D:\GitHub\pte-org\pte-api
.\mvnw.cmd -pl app -DskipTests compile
.\mvnw.cmd -pl app test
.\mvnw.cmd -pl app test -Dtest="PackageDensityTest,SourceFileSizeTest,NoDirectClockAccessTest,ModuleStructureTest,RubricScoreSingleSourceTest,ApiInventoryExportTest"

cd D:\GitHub\pte-org\pte-web
pnpm --filter vendor-web typecheck; pnpm --filter vendor-web lint; pnpm --filter vendor-web test
pnpm --filter tenant-web typecheck; pnpm --filter tenant-web lint; pnpm --filter tenant-web test
```

## Design Constraints

- `AGENTS.md`: báo cáo audit/xác minh ở `pte-doc/plans/reports/`, tên `YYMMDD-<topic>-<report-type>.md`, assets ở `reports/assets/<tên>/` với liên kết tương đối; không đặt ở Temp hay repo ứng dụng.
- Không ghi bí mật, khóa API, giá trị `.env`, bài làm/transcript thật vào báo cáo, `AGENTS.md` hay assets.
- Nếu phase sửa mã (test, ratchet) phải đọc đủ `docs/CODING_STANDARDS_API.md`/`CODING_STANDARDS_WEB.md`; báo cáo nêu đúng ranh giới đã kiểm tra, không khẳng định tuân thủ khi chưa chạy lệnh; test đỏ không liên quan phải được báo cáo.
- Không viết lại lịch sử: báo cáo đối chiếu gốc giữ nguyên, chỉ thêm phần cập nhật có ngày.
- Mọi cam kết "đạt" dựa trên số liệu chạy thật; không mô tả dữ liệu tổng hợp như bằng chứng độ chính xác.
- Plan không chứa bước commit, release, triển khai hay rollback (người dùng tự xử lý).

## Quality and Testing State

- Quality: not evaluated
- Testing: not started

## Risks

- Thiếu khóa thật nên không chạy lại spike: dùng số liệu Phase 3-5, ghi ngày và model.
- Con số test/endpoint trong `AGENTS.md` lỗi thời nhanh: lấy từ lần chạy cuối, ghi ngày.
- Test Postgres IT không chạy được: ghi rõ chưa chạy kèm lệnh; không đánh dấu hoàn tất tiêu chí phụ thuộc.
- Quên cập nhật `plan.md` cuối: bước 7 là mục nghiệm thu.
