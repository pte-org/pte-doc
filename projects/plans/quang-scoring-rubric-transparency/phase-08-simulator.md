# Phase 8: Bộ mô phỏng (API + màn C trên vendor-web)

## Mục tiêu

Cho người trình bày bảo vệ nhập **điểm tiêu chí giả định** cho một task type và một phiên bản rubric rồi xem điểm câu cùng các bước tính (tiêu chí nào kích hoạt điều kiện chặn, Form ở mức nào, đóng góp từng tiêu chí).
Kết quả do **chính `RubricScorer`** và **`FormRule.bandFor`** tính (không AI, không bản sao công thức ở FE) nên bằng kết quả scorer thật với cùng đầu vào. Chỉ vendor-web; không có dữ liệu lượt thi.

## Stories/FR covered

- S4; FR-08; Success Criteria "độ khớp mô phỏng 100%, gồm ca cổng của 7 task type có Content/Form"

## Files to read first

- `D:\GitHub\pte-org\docs\CODING_STANDARDS_API.md`, `API_RESPONSE_SETUP.md`, `COMMON_EXCEPTION_SETUP.md`, `TEST_SCENARIOS_IAM.md`, `CODING_STANDARDS_WEB.md`
- Phase 1 (`RubricScorer`, `FormRule.bandFor`, `TextMetrics`, `TraitScoreSet`, `ScoreTrace`, `RubricConstants`), Phase 2 (`RubricVersionService`, controller `/api/v1/scoring-rubrics`), Phase 7 (feature `scoringrubric`, `_TraitTable`)
- Ghi nhớ người dùng: bộ chọn/kéo thả thay ô nhập số; mockup nếu cần là HTML cục bộ, không tạo Docs artifact

## Implementation steps

1. **API mô phỏng**: `POST /api/v1/scoring-rubrics/simulations` thân `{taskType, rubricVersionPublicId?, traitScores: {khóa: số nguyên}, textMetrics?: {wordCount, sentenceCount, allCaps, punctuationPresent, bulletOnly}, wordCount?}`.
   Mặc định phiên bản ACTIVE; chỉ cho phiên bản ACTIVE/RETIRED hoặc bản nháp do vendor đang soạn (đọc theo quyền vendor; dùng để thử trước khi kích hoạt). Với task type có Form, band Form do **`FormRule.bandFor(textMetrics)`** tính (cùng hàm với `FormCheck`); RA bắt buộc `wordCount` (N >= 1).
   Phản hồi: điểm câu 0-100 (= `rawScore` scorer thật sẽ cho) và `ScoreTrace` đầy đủ. Kiểm tra đầu vào trước khi chạy: **giới hạn số phần tử `traitScores` và kích thước thân theo `RubricConstants`** (LOW-3); thiếu/lạ/ngoài thang/N = 0 trả lỗi chuẩn (không 500). Quyền: các role vendor như API đọc.
2. **Tái dùng tuyệt đối**: service mô phỏng chỉ gọi `RubricVersionService` + `FormRule.bandFor` + `RubricScorer`; test `verifyNoInteractions` với mọi client vendor/Gemini/Azure; không ghi DB. Mở rộng `RubricScoreSingleSourceTest` để cấm tính điểm câu/band Form ở lớp mô phỏng.
3. **Test độ khớp**: bộ ca bảng dùng chung cho scorer thật (Phase 3 và 5, điểm tiêu chí cố định thay LLM) và mô phỏng, khẳng định bằng nhau 100%: cổng của cả 7 task type (DI, RL, RTS, SGD: Content = 0; SWT, WE, SST: Content = 0 và Form = 0), tắt cổng, đổi trọng số (phiên bản khác), Form band 0/1/2 qua `textMetrics` (kể cả quy tắc phụ toàn hoa/không dấu câu/gạch đầu dòng), RA N = 1, 30, 80. Test hiệu năng p95 < 300 ms.
4. **Hợp đồng và quyền**: cập nhật `ApiInventoryExportTest`; test phân quyền theo `TEST_SCENARIOS_IAM.md` (role ngoài danh sách 403; Host/Examiner không gọi được).
5. **api-client**: `simulateScore` và kiểu trong `packages/api-client/src/requests/scoringrubric/`.
6. **Màn C** (`vendor-web/features/scoringsimulator/`, route `app/(dashboard)/admin/scoring-simulator/page.tsx`, mục "Mô phỏng chấm", `requiredRoles: ACADEMIC_ROLES`): chọn task type/phiên bản (mặc định ACTIVE); mỗi tiêu chí là **bộ chọn rời rạc 0..max** kèm tooltip mô tả mức (từ API Phase 2); Form: thanh kéo số chữ và các công tắc quy tắc phụ (toàn hoa, thiếu dấu câu, chỉ gạch đầu dòng) thay vì nhập số; RA: thanh kéo N.
   Đổi điều khiển -> gọi API (`useMutation` có debounce) -> hiển thị vết: tiêu chí đánh dấu khi cổng kích hoạt, dòng "Điểm câu = 0 vì Content = 0 (điều kiện chặn)", cột đóng góp, điểm trước/sau làm tròn. Nút "Dùng ví dụ trong Score Guide" nạp đầu vào mẫu (chỉ dữ liệu vào, không phải luật).
7. **Test FE** (`tests/unit/features/scoringsimulator/`): dựng thân yêu cầu từ trạng thái bộ chọn, map vết sang hàng, ví dụ mẫu hợp lệ theo thang của API; hygiene như Phase 7.

## Acceptance criteria

- API trả điểm câu và vết, không gọi AI (mock xác nhận), không ghi DB.
- Với cùng đầu vào, mô phỏng **bằng 100%** scorer thật trên bộ ca (7 task type có cổng, tắt cổng, đổi trọng số, Form 3 mức gồm quy tắc phụ, RA N = 1/30/80).
- Band Form do `FormRule.bandFor` (architecture test); đầu vào vượt giới hạn kích thước hoặc ngoài thang bị từ chối có mã chuẩn.
- Màn C: đặt điểm tiêu chí bằng bộ chọn và thấy điểm cùng vết cập nhật; ca Content = 0 hiển thị rõ lý do.
- p95 < 300 ms; `pnpm --filter vendor-web typecheck/lint/test` và `ApiInventoryExportTest` xanh.

## Validation commands

```powershell
cd D:\GitHub\pte-org\pte-api
.\mvnw.cmd -pl app -DskipTests compile
.\mvnw.cmd -pl app test -Dtest="RubricSimulationServiceTest,RubricSimulationControllerTest,ScorerSimulatorParityTest,RubricScoreSingleSourceTest,ApiInventoryExportTest"
.\mvnw.cmd -pl app test -Dtest="PackageDensityTest,SourceFileSizeTest,NoDirectClockAccessTest,ModuleStructureTest"

cd D:\GitHub\pte-org\pte-web
pnpm --filter vendor-web typecheck; pnpm --filter vendor-web lint; pnpm --filter vendor-web test
```

## Design Constraints

- `docs/CODING_STANDARDS_API.md`, `API_RESPONSE_SETUP.md`, `COMMON_EXCEPTION_SETUP.md`, `TEST_SCENARIOS_IAM.md`, `CODING_STANDARDS_WEB.md` bắt buộc.
- Không gọi AI/Azure/Gemini; không ghi DB; chỉ khóa tiêu chí và số/boolean (không văn bản tự do); giới hạn kích thước đầu vào.
- Một hàm tính điểm (`RubricScorer`) và một hàm tính band Form (`FormRule.bandFor`); FE không tự tính.
- Giá trị ngoài thang bị từ chối, không làm tròn/cắt.
- Chỉ vendor-web; không dữ liệu lượt thi; Examiner không dùng API này (điểm câu của giám khảo do server tính ở Phase 10).
- Ưu tiên bộ chọn/kéo thả cho đầu vào số; component <= 150 dòng; không Playwright.

## Quality and Testing State

- Quality: skipped_by_user (decision: user_confirmed_skip)
- Testing: passed with boundaries (2026-11-05). Clean test-compile: BUILD SUCCESS. Focused: 78/78, including 12 V32 PostgreSQL tests and 2 chat migration regressions, 0 skipped. Full app: **4543 tests, 0 failures, 0 errors, 73 skipped**, from 514 Surefire XML files (baseline 4468/0/137; +75 total, -64 skipped; 47 new tests/assertion methods, remaining count delta not fully reconciled). Vendor vitest 287/287; api-client 678/678 and tsc exit 0; ui 348/348 and tsc exit 0. Vendor eslint: 0 errors, 2 existing warnings. Vendor tsc has only the existing `.next/types/validator.ts(62,39) TS2307` login/page.js error. No browser/build/live AI. p95 service fixture 10.5182 ms, not HTTP/real-DB latency. Evidence: `../../../plans/reports/261105-scoring-rubric-phase08-checklist.md` and assets/261105-scoring-rubric-transparency-verification/.

## Risks

- Ví dụ Score Guide gắn cứng ở FE lệch catalog: chỉ lưu đầu vào, kiểm hợp lệ theo thang API khi nạp.
- Quy tắc phụ Form bằng công tắc thay vì đếm từ văn bản: chấp nhận cho mô phỏng; `FormCheck` vẫn đếm thật từ bài làm.
- Gọi API mỗi lần đổi điều khiển: debounce; API rẻ.

## Preflight / quyết định khi làm (2026-11-05)

- Đã đọc AGENTS.md, plan/spec, phase 1-7 và đủ CODING_STANDARDS_API.md, CODING_STANDARDS_WEB.md, API_RESPONSE_SETUP.md, COMMON_EXCEPTION_SETUP.md, TEST_SCENARIOS_IAM.md.
- Tests: yes; quality: skipped_by_user; decision: user_confirmed_skip. Không browser/install/commit/push.
- Tái dùng RubricResolver.effectiveFor thay vì RubricVersionService (lifecycle); repository chỉ đọc; FormRule.bandFor + RubricScorer quyết định toàn bộ điểm. Map BigDecimal kiểm intValueExact để không bị Jackson cắt số lẻ. weightedContribution được tính trong RubricScorer và trả qua ScoreTrace.

- Môi trường thực tế khác bàn giao: Testcontainers khởi động được PostgreSQL. Lần full đầu dừng sau lỗi Flyway `No value provided for placeholder: ${` trong V32; sửa khoảng trắng sau dollar-quote, giữ nguyên JSON seed; fixture regex chấp nhận whitespace. 12 V32 IT đã chạy và qua, không còn thuộc phần chưa kiểm chứng. Các Postgres IT cần cấu hình DB riêng và AI spike vẫn skipped; xem JSON tổng hợp.
- Giới hạn body thô 64 KiB bằng RequestBodyAdvice trước parse (kể cả không Content-Length); trait số lẻ bị từ chối, không cắt. FE chỉ gửi các tiêu chí ngoài FORM; band FORM luôn do server tính.
- Checklist đầy đủ: [báo cáo phase 8](../../../plans/reports/261105-scoring-rubric-phase08-checklist.md).
