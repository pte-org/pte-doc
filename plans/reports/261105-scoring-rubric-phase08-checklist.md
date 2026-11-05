# Phase 8 — checklist và bằng chứng

Quality: skipped_by_user. Không browser/install/commit/push. Toàn suite: **4543/0 failures/0 errors/73 skipped**, 514 XML; [số liệu](assets/261105-scoring-rubric-transparency-verification/phase08-surefire-summary.json), [full log](assets/261105-scoring-rubric-transparency-verification/phase08-full.log), [focused log](assets/261105-scoring-rubric-transparency-verification/phase08-focused.log).

- Backend clean test-compile qua; 78 test nhắm đích qua, gồm 12 test PostgreSQL V32 và 2 test chat migration.
- Vendor 287, api-client 678, UI 348 test qua. Typecheck api-client/UI qua. Vendor typecheck vẫn lỗi sinh cũ: `.next/types/validator.ts(62,39): error TS2307: Cannot find module ../../app/(auth)/login/page.js`. Lint vendor: 0 lỗi, 2 cảnh báo cũ.
- Bốn lớp test mới có 45 test, thêm 1 ratchet và 1 seed test = 47; tổng suite tăng 75 so với nền. Phần chênh 28 test còn lại chưa đối chiếu đầy đủ; không quy hết cho code mới.
- p95 fixture service: 10.5182 ms; chưa đo HTTP/DB thật. UI chưa chạy trình duyệt. AI thật/độ ổn định 90%/Azure hiệu chỉnh chưa kiểm chứng.
- Package/lockfile: MD5 9 tệp không đổi.
- Lệch kỹ thuật: dùng RubricResolver.effectiveFor + repository chỉ đọc thay cho lifecycle RubricVersionService; API này không ghi DB. Đóng góp được tính ngay trong RubricScorer, FE chỉ hiển thị.
- Sửa lỗi V32 có sẵn, được lộ ra khi Testcontainers chạy được: chỉ thêm newline sau dollar-quote; dữ liệu seed giữ nguyên. Lần full đầu đã dừng vì lỗi này, không coi là một full run hoàn tất. Lỗi nguyên văn: `Unable to parse statement in db/migration/V32__scoring_rubric_versions.sql at line 126 col 1. No value provided for placeholder: ${`. [Log gốc](assets/261105-scoring-rubric-transparency-verification/phase08-initial-full-failure.log).

## 1. Implementation steps

1. **API mô phỏng**: `POST /api/v1/scoring-rubrics/simulations` thân `{taskType, rubricVersionPublicId?, traitScores: {khóa: số nguyên}, textMetrics?: {wordCount, sentenceCount, allCaps, punctuationPresent, bulletOnly}, wordCount?}`.
   Mặc định phiên bản ACTIVE; chỉ cho phiên bản ACTIVE/RETIRED hoặc bản nháp do vendor đang soạn (đọc theo quyền vendor; dùng để thử trước khi kích hoạt). Với task type có Form, band Form do **`FormRule.bandFor(textMetrics)`** tính (cùng hàm với `FormCheck`); RA bắt buộc `wordCount` (N >= 1).
   Phản hồi: điểm câu 0-100 (= `rawScore` scorer thật sẽ cho) và `ScoreTrace` đầy đủ. Kiểm tra đầu vào trước khi chạy: **giới hạn số phần tử `traitScores` và kích thước thân theo `RubricConstants`** (LOW-3); thiếu/lạ/ngoài thang/N = 0 trả lỗi chuẩn (không 500). Quyền: các role vendor như API đọc.

**ĐÃ LÀM — bằng chứng: focused/full log; FE test serialization/render/hygiene; ratchet xanh. Với rủi ro: biện pháp giảm nhẹ có trong code/test, không khẳng định loại bỏ toàn bộ rủi ro.**

## 2. Implementation steps

2. **Tái dùng tuyệt đối**: service mô phỏng chỉ gọi `RubricVersionService` + `FormRule.bandFor` + `RubricScorer`; test `verifyNoInteractions` với mọi client vendor/Gemini/Azure; không ghi DB. Mở rộng `RubricScoreSingleSourceTest` để cấm tính điểm câu/band Form ở lớp mô phỏng.

**LỆCH PLAN — đọc qua RubricResolver/repository, tách khỏi service lifecycle; RubricScorer và FormRule là nguồn duy nhất. ScorerSimulatorPipelineParityTest xác nhận verifyNoInteractions(Gemini, Azure, audio) sau scorer thật; repo chỉ đọc.**

## 3. Implementation steps

3. **Test độ khớp**: bộ ca bảng dùng chung cho scorer thật (Phase 3 và 5, điểm tiêu chí cố định thay LLM) và mô phỏng, khẳng định bằng nhau 100%: cổng của cả 7 task type (DI, RL, RTS, SGD: Content = 0; SWT, WE, SST: Content = 0 và Form = 0), tắt cổng, đổi trọng số (phiên bản khác), Form band 0/1/2 qua `textMetrics` (kể cả quy tắc phụ toàn hoa/không dấu câu/gạch đầu dòng), RA N = 1, 30, 80. Test hiệu năng p95 < 300 ms.

**ĐÃ LÀM — bằng chứng: focused/full log; FE test serialization/render/hygiene; ratchet xanh. Với rủi ro: biện pháp giảm nhẹ có trong code/test, không khẳng định loại bỏ toàn bộ rủi ro.**

## 4. Implementation steps

4. **Hợp đồng và quyền**: cập nhật `ApiInventoryExportTest`; test phân quyền theo `TEST_SCENARIOS_IAM.md` (role ngoài danh sách 403; Host/Examiner không gọi được).

**ĐÃ LÀM — bằng chứng: focused/full log; FE test serialization/render/hygiene; ratchet xanh. Với rủi ro: biện pháp giảm nhẹ có trong code/test, không khẳng định loại bỏ toàn bộ rủi ro.**

## 5. Implementation steps

5. **api-client**: `simulateScore` và kiểu trong `packages/api-client/src/requests/scoringrubric/`.

**ĐÃ LÀM — bằng chứng: focused/full log; FE test serialization/render/hygiene; ratchet xanh. Với rủi ro: biện pháp giảm nhẹ có trong code/test, không khẳng định loại bỏ toàn bộ rủi ro.**

## 6. Implementation steps

6. **Màn C** (`vendor-web/features/scoringsimulator/`, route `app/(dashboard)/admin/scoring-simulator/page.tsx`, mục "Mô phỏng chấm", `requiredRoles: ACADEMIC_ROLES`): chọn task type/phiên bản (mặc định ACTIVE); mỗi tiêu chí là **bộ chọn rời rạc 0..max** kèm tooltip mô tả mức (từ API Phase 2); Form: thanh kéo số chữ và các công tắc quy tắc phụ (toàn hoa, thiếu dấu câu, chỉ gạch đầu dòng) thay vì nhập số; RA: thanh kéo N.
   Đổi điều khiển -> gọi API (`useMutation` có debounce) -> hiển thị vết: tiêu chí đánh dấu khi cổng kích hoạt, dòng "Điểm câu = 0 vì Content = 0 (điều kiện chặn)", cột đóng góp, điểm trước/sau làm tròn. Nút "Dùng ví dụ trong Score Guide" nạp đầu vào mẫu (chỉ dữ liệu vào, không phải luật).

**ĐÃ LÀM — bằng chứng: focused/full log; FE test serialization/render/hygiene; ratchet xanh. Với rủi ro: biện pháp giảm nhẹ có trong code/test, không khẳng định loại bỏ toàn bộ rủi ro.**

## 7. Implementation steps

7. **Test FE** (`tests/unit/features/scoringsimulator/`): dựng thân yêu cầu từ trạng thái bộ chọn, map vết sang hàng, ví dụ mẫu hợp lệ theo thang của API; hygiene như Phase 7.

**ĐÃ LÀM — bằng chứng: focused/full log; FE test serialization/render/hygiene; ratchet xanh. Với rủi ro: biện pháp giảm nhẹ có trong code/test, không khẳng định loại bỏ toàn bộ rủi ro.**

## 8. Acceptance criteria

- API trả điểm câu và vết, không gọi AI (mock xác nhận), không ghi DB.

**ĐÃ LÀM — bằng chứng: focused/full log; FE test serialization/render/hygiene; ratchet xanh. Với rủi ro: biện pháp giảm nhẹ có trong code/test, không khẳng định loại bỏ toàn bộ rủi ro.**

## 9. Acceptance criteria

- Với cùng đầu vào, mô phỏng **bằng 100%** scorer thật trên bộ ca (7 task type có cổng, tắt cổng, đổi trọng số, Form 3 mức gồm quy tắc phụ, RA N = 1/30/80).

**ĐÃ LÀM — bằng chứng: focused/full log; FE test serialization/render/hygiene; ratchet xanh. Với rủi ro: biện pháp giảm nhẹ có trong code/test, không khẳng định loại bỏ toàn bộ rủi ro.**

## 10. Acceptance criteria

- Band Form do `FormRule.bandFor` (architecture test); đầu vào vượt giới hạn kích thước hoặc ngoài thang bị từ chối có mã chuẩn.

**ĐÃ LÀM — bằng chứng: focused/full log; FE test serialization/render/hygiene; ratchet xanh. Với rủi ro: biện pháp giảm nhẹ có trong code/test, không khẳng định loại bỏ toàn bộ rủi ro.**

## 11. Acceptance criteria

- Màn C: đặt điểm tiêu chí bằng bộ chọn và thấy điểm cùng vết cập nhật; ca Content = 0 hiển thị rõ lý do.

**ĐÃ LÀM — bằng chứng: focused/full log; FE test serialization/render/hygiene; ratchet xanh. Với rủi ro: biện pháp giảm nhẹ có trong code/test, không khẳng định loại bỏ toàn bộ rủi ro.**

## 12. Acceptance criteria

- p95 < 300 ms; `pnpm --filter vendor-web typecheck/lint/test` và `ApiInventoryExportTest` xanh.

**LỆCH PLAN — chạy trực tiếp node_modules/.bin theo yêu cầu; vendor tsc chỉ lỗi .next sinh cũ; p95 chỉ trên fixture service. Các giới hạn và bằng chứng ở trên.**

## 13. Validation commands

.\mvnw.cmd -pl app -DskipTests compile

**ĐÃ LÀM — bằng chứng: focused/full log; FE test serialization/render/hygiene; ratchet xanh. Với rủi ro: biện pháp giảm nhẹ có trong code/test, không khẳng định loại bỏ toàn bộ rủi ro.**

## 14. Validation commands

.\mvnw.cmd -pl app test -Dtest="RubricSimulationServiceTest,RubricSimulationControllerTest,ScorerSimulatorParityTest,RubricScoreSingleSourceTest,ApiInventoryExportTest"

**ĐÃ LÀM — bằng chứng: focused/full log; FE test serialization/render/hygiene; ratchet xanh. Với rủi ro: biện pháp giảm nhẹ có trong code/test, không khẳng định loại bỏ toàn bộ rủi ro.**

## 15. Validation commands

.\mvnw.cmd -pl app test -Dtest="PackageDensityTest,SourceFileSizeTest,NoDirectClockAccessTest,ModuleStructureTest"

**ĐÃ LÀM — bằng chứng: focused/full log; FE test serialization/render/hygiene; ratchet xanh. Với rủi ro: biện pháp giảm nhẹ có trong code/test, không khẳng định loại bỏ toàn bộ rủi ro.**

## 16. Validation commands

pnpm --filter vendor-web typecheck; pnpm --filter vendor-web lint; pnpm --filter vendor-web test

**LỆCH PLAN — chạy trực tiếp node_modules/.bin theo yêu cầu; vendor tsc chỉ lỗi .next sinh cũ; p95 chỉ trên fixture service. Các giới hạn và bằng chứng ở trên.**

## 17. Design Constraints

- `docs/CODING_STANDARDS_API.md`, `API_RESPONSE_SETUP.md`, `COMMON_EXCEPTION_SETUP.md`, `TEST_SCENARIOS_IAM.md`, `CODING_STANDARDS_WEB.md` bắt buộc.

**ĐÃ LÀM — bằng chứng: focused/full log; FE test serialization/render/hygiene; ratchet xanh. Với rủi ro: biện pháp giảm nhẹ có trong code/test, không khẳng định loại bỏ toàn bộ rủi ro.**

## 18. Design Constraints

- Không gọi AI/Azure/Gemini; không ghi DB; chỉ khóa tiêu chí và số/boolean (không văn bản tự do); giới hạn kích thước đầu vào.

**ĐÃ LÀM — bằng chứng: focused/full log; FE test serialization/render/hygiene; ratchet xanh. Với rủi ro: biện pháp giảm nhẹ có trong code/test, không khẳng định loại bỏ toàn bộ rủi ro.**

## 19. Design Constraints

- Một hàm tính điểm (`RubricScorer`) và một hàm tính band Form (`FormRule.bandFor`); FE không tự tính.

**ĐÃ LÀM — bằng chứng: focused/full log; FE test serialization/render/hygiene; ratchet xanh. Với rủi ro: biện pháp giảm nhẹ có trong code/test, không khẳng định loại bỏ toàn bộ rủi ro.**

## 20. Design Constraints

- Giá trị ngoài thang bị từ chối, không làm tròn/cắt.

**ĐÃ LÀM — bằng chứng: focused/full log; FE test serialization/render/hygiene; ratchet xanh. Với rủi ro: biện pháp giảm nhẹ có trong code/test, không khẳng định loại bỏ toàn bộ rủi ro.**

## 21. Design Constraints

- Chỉ vendor-web; không dữ liệu lượt thi; Examiner không dùng API này (điểm câu của giám khảo do server tính ở Phase 10).

**ĐÃ LÀM — bằng chứng: focused/full log; FE test serialization/render/hygiene; ratchet xanh. Với rủi ro: biện pháp giảm nhẹ có trong code/test, không khẳng định loại bỏ toàn bộ rủi ro.**

## 22. Design Constraints

- Ưu tiên bộ chọn/kéo thả cho đầu vào số; component <= 150 dòng; không Playwright.

**ĐÃ LÀM — bằng chứng: focused/full log; FE test serialization/render/hygiene; ratchet xanh. Với rủi ro: biện pháp giảm nhẹ có trong code/test, không khẳng định loại bỏ toàn bộ rủi ro.**

## 23. Risks

- Ví dụ Score Guide gắn cứng ở FE lệch catalog: chỉ lưu đầu vào, kiểm hợp lệ theo thang API khi nạp.

**ĐÃ LÀM — bằng chứng: focused/full log; FE test serialization/render/hygiene; ratchet xanh. Với rủi ro: biện pháp giảm nhẹ có trong code/test, không khẳng định loại bỏ toàn bộ rủi ro.**

## 24. Risks

- Quy tắc phụ Form bằng công tắc thay vì đếm từ văn bản: chấp nhận cho mô phỏng; `FormCheck` vẫn đếm thật từ bài làm.

**ĐÃ LÀM — bằng chứng: focused/full log; FE test serialization/render/hygiene; ratchet xanh. Với rủi ro: biện pháp giảm nhẹ có trong code/test, không khẳng định loại bỏ toàn bộ rủi ro.**

## 25. Risks

- Gọi API mỗi lần đổi điều khiển: debounce; API rẻ.

**ĐÃ LÀM — bằng chứng: focused/full log; FE test serialization/render/hygiene; ratchet xanh. Với rủi ro: biện pháp giảm nhẹ có trong code/test, không khẳng định loại bỏ toàn bộ rủi ro.**
