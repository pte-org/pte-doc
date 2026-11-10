# Phase 10 — checklist trước triển khai

## 1. Implementation steps

1. **Hợp đồng mới (breaking)**: `SubmitExaminerScoreRequest` và `SaveExaminerDraftRequest` thêm `traitScores` (map khóa -> số nguyên thang Pearson; `null` cho Pronunciation/Oral Fluency nghĩa "lấy từ máy"; **giới hạn số phần tử theo `RubricConstants`** — LOW-3). Task type có rubric AI (DI, RL, RTS, SGD, SWT, WE, SST, RA, RS): `traitScores` bắt buộc; `score` do **server tính**
   (client gửi `score` thì phải bằng giá trị tính được, nếu không từ chối). Task type không có rubric AI giữ `score` như cũ. Client cũ chỉ gửi `score` cho task type rubric bị từ chối với mã riêng (`ExaminerScoringConstants`), không đoán.

**CHƯA LÀM — chưa triển khai/xác minh.**

## 2. Implementation steps

2. **Lưu trữ** (migration **số tiếp theo còn trống, kiểm tra lúc làm**; V32 dành cho rubric): thêm cột cho `ExaminerEvaluation` trong `answer_evaluations`: `trait_scores_json` (JSON có `scale = PEARSON_V1` và `rubricVersion`, cùng định dạng điểm AI) và `rubric_version_public_id`; cần xác minh nơi lưu bản nháp (`ExaminerEvaluation` trạng thái draft hay bảng khác). `score` vẫn là điểm câu đã tính (tương thích mọi nơi đọc `examinerScore`). Migration additive.

**CHƯA LÀM — chưa triển khai/xác minh.**

## 3. Implementation steps

3. **Gói `examiner/trait`**: `ExaminerTraitScoreResolver` (kết hợp `traitScores` của giám khảo, `AiEvaluation` cùng câu và `EffectiveRubric` theo phiên bản ghim của câu; điền tiêu chí `null` nguồn `AZURE` từ Azure; **từ chối** nếu cần điền mà AI vắng/thất bại), `ExaminerTraitValidator` (đủ tiêu chí, nguyên, trong thang, không ghi đè tiêu chí chỉ máy chấm ngoài `null`; Form do mã tính, giám khảo không nhập),
   và lớp gọi `RubricScorer`. Giám khảo chấm CONTENT = 0 thì cổng kích hoạt, điểm câu = 0 (tiêu chí khác vẫn lưu).

**CHƯA LÀM — chưa triển khai/xác minh.**

## 4. Implementation steps

4. **Điểm câu server-side trong phản hồi (MEDIUM-7)**: `ExaminerCommandResponse`/`ExaminerScoreSubmissionResponse` (phản hồi lưu nháp và nộp) trả thêm `itemScore` và `scoreTrace` (từ `RubricScorer`); `ExaminerAnswerDetailResponse` mang thêm mô tả mức và thang từng tiêu chí của rubric ghim (từ catalog) để giám khảo thấy tại chỗ **mà không mở rộng quyền endpoint rubric vendor**.
   Không có API mô phỏng cho giám khảo. FE hiển thị điểm câu **từ phản hồi lưu nháp** (lưu nháp tự động khi đổi bộ chọn), không tự tính.

**CHƯA LÀM — chưa triển khai/xác minh.**

## 5. Implementation steps

5. **Cập nhật luồng**: `ExaminerDirectScoreSubmitter`, `ExaminerDraftCommandService`, `ExaminerFinalizeSubmitter` dùng `ExaminerTraitScoreResolver`; **dấu vân tay yêu cầu (`computeRequestFingerprint`) và phiên bản xem lại (`computeReviewVersion`) gồm `traitScores` và phiên bản rubric** (thử lại idempotent và phát hiện dữ liệu cũ vẫn đúng); `CONFIRM_AI` so sánh điểm tiêu chí/điểm câu tính được thay vì `score` thô;
   `ExaminerAiReferenceResponse` mang điểm tiêu chí AI và thang. Thông điệp lỗi mới vào `ExaminerScoringConstants`.

**CHƯA LÀM — chưa triển khai/xác minh.**

## 6. Implementation steps

6. **Báo cáo và giải thích**: `ReportScoringAnswerView.traitScores` lấy từ `ExaminerEvaluation` khi nguồn là EXAMINER; snapshot v2 ghi chúng; API giải thích (Phase 6) hiển thị đủ vết, không còn "không phân rã" cho dữ liệu mới; chấm giám khảo cũ (chỉ `score`) vẫn hiển thị "điểm giám khảo, không phân rã".

**CHƯA LÀM — chưa triển khai/xác minh.**

## 7. Implementation steps

7. **Frontend tenant-web** (không chạm vendor-web): `DecisionPanel.tsx` thay ô 0-100 bằng bộ chọn từng tiêu chí (rời rạc 0..max, tooltip mô tả mức lấy từ `ExaminerAnswerDetailResponse`; tiêu chí chỉ máy hiện giá trị Azure chỉ đọc và nút "Dùng của máy"), hiển thị `itemScore` và cảnh báo CONTENT = 0 từ phản hồi lưu nháp; `AiReferencePanel.tsx` hiện điểm tiêu chí AI;
   cập nhật `submissionTypes.ts`, `api.ts`, `useExaminerDraftState.ts`, `useExaminerSubmissionActions.ts`, `useExaminerSubmissions.ts`, `constants.ts`, thông điệp `vi.ts`/`en.ts`/`workVi.ts`; tách `_TraitScorePicker`, `_TraitReferenceRow`; component <= 150 dòng.

**CHƯA LÀM — chưa triển khai/xác minh.**

## 8. Implementation steps

8. **Test backend** (dùng `ExplanationFixtureBuilder`): bộ ca bảng theo task type rubric (đủ/thiếu/ngoài thang/quá số phần tử), điền Azure khi `null` (và từ chối khi không có AI), CONTENT = 0 -> 0, `CONFIRM_AI` theo điểm tiêu chí, thử lại idempotent, dấu vân tay và `reviewVersion` đổi khi đổi `traitScores`, client cũ chỉ `score` bị từ chối đúng mã, `itemScore` trong phản hồi nháp khớp `RubricScorer`,
   chọn nguồn EXAMINER rồi publish: snapshot chứa điểm tiêu chí giám khảo và giải thích khớp (chênh lệch 0); cập nhật test giám khảo hiện có (`src/test/java/com/pte/scoring/internal/service/examiner`, `ExaminerWorkController`); cập nhật `ApiInventoryExportTest` nếu đổi endpoint.

**CHƯA LÀM — chưa triển khai/xác minh.**

## 9. Implementation steps

9. **Test FE**: dựng thân yêu cầu từ bộ chọn, "Dùng của máy", hiển thị `itemScore` từ phản hồi, trạng thái vô hiệu khi thiếu tiêu chí; `tests/unit/features/examiner/*`.

**CHƯA LÀM — chưa triển khai/xác minh.**

## 10. Acceptance criteria

- Giám khảo nộp theo từng tiêu chí cho task type rubric; điểm câu do server tính; `score` khác giá trị tính được bị từ chối; client cũ bị từ chối rõ ràng.

**CHƯA LÀM — chưa triển khai/xác minh.**

## 11. Acceptance criteria

- Tiêu chí chỉ máy chấm để `null` lấy từ Azure của cùng câu; thiếu AI thì từ chối; giám khảo không nhập được Form; CONTENT = 0 -> điểm câu 0.

**CHƯA LÀM — chưa triển khai/xác minh.**

## 12. Acceptance criteria

- Phản hồi lưu nháp/nộp có `itemScore` và `scoreTrace` khớp `RubricScorer`; UI hiển thị từ phản hồi, không tự tính.

**CHƯA LÀM — chưa triển khai/xác minh.**

## 13. Acceptance criteria

- Thử lại (cùng `requestPublicId`, cùng `traitScores`) idempotent; đổi `traitScores` đổi dấu vân tay và `reviewVersion`; dữ liệu cũ phát hiện đúng `StaleReviewVersionException`.

**CHƯA LÀM — chưa triển khai/xác minh.**

## 14. Acceptance criteria

- Chọn nguồn EXAMINER rồi publish: snapshot v2 chứa điểm tiêu chí giám khảo; giải thích khớp (chênh lệch 0).

**CHƯA LÀM — chưa triển khai/xác minh.**

## 15. Acceptance criteria

- Không mở rộng quyền đọc endpoint rubric vendor cho giám khảo; không API mô phỏng cho giám khảo.

**CHƯA LÀM — chưa triển khai/xác minh.**

## 16. Acceptance criteria

- `PackageDensityTest` xanh (class mới ở `examiner/trait`); FE `typecheck/lint/test` tenant-web xanh; toàn suite `app` xanh.

**CHƯA LÀM — chưa triển khai/xác minh.**

## 17. Validation commands

.\mvnw.cmd -pl app -DskipTests compile

**CHƯA LÀM — chưa triển khai/xác minh.**

## 18. Validation commands

.\mvnw.cmd -pl app test -Dtest="Examiner*Test,ExaminerTraitScoreResolverTest,ExaminerTraitValidatorTest,ExaminerTraitSubmitIT,ScoreSourceSelection*Test,ApiInventoryExportTest"

**CHƯA LÀM — chưa triển khai/xác minh.**

## 19. Validation commands

.\mvnw.cmd -pl app test -Dtest="PackageDensityTest,SourceFileSizeTest,NoDirectClockAccessTest,ModuleStructureTest"

**CHƯA LÀM — chưa triển khai/xác minh.**

## 20. Validation commands

.\mvnw.cmd -pl app test

**CHƯA LÀM — chưa triển khai/xác minh.**

## 21. Validation commands

pnpm --filter tenant-web typecheck; pnpm --filter tenant-web lint; pnpm --filter tenant-web test

**CHƯA LÀM — chưa triển khai/xác minh.**

## 22. Validation commands

pnpm --filter @pte/api-client typecheck      # cần xác minh tên script

**CHƯA LÀM — chưa triển khai/xác minh.**

## 23. Design Constraints

- `docs/CODING_STANDARDS_API.md`, `CODING_STANDARDS_WEB.md`, `API_RESPONSE_SETUP.md`, `COMMON_EXCEPTION_SETUP.md`, `TEST_SCENARIOS_IAM.md` bắt buộc; file <= 300 dòng; `internal/**` <= 15 class (`service/examiner` đã đầy: chỉ thêm vào gói con); `Clock` inject; message/mã lỗi trong `ExaminerScoringConstants`; cross-module chỉ qua API công khai.

**CHƯA LÀM — chưa triển khai/xác minh.**

## 24. Design Constraints

- Thay đổi phá vỡ hợp đồng có chủ đích (spec: S6); không giữ đường ghi điểm tổng cho task type có rubric; client cũ bị từ chối rõ ràng.

**CHƯA LÀM — chưa triển khai/xác minh.**

## 25. Design Constraints

- Điểm câu chỉ do `RubricScorer` tính ở server; không tin `score` từ client; Pronunciation/Oral Fluency chỉ do máy; Form chỉ do mã.

**CHƯA LÀM — chưa triển khai/xác minh.**

## 26. Design Constraints

- Giữ nguyên tính bất biến, idempotent, khóa phiên/đáp án/xuất bản và thứ tự khóa của luồng giám khảo; không làm yếu `reviewVersion` và dấu vân tay (phải gồm `traitScores`).

**CHƯA LÀM — chưa triển khai/xác minh.**

## 27. Design Constraints

- Cách ly tenant và phân công giám khảo như hiện tại; giám khảo không thấy phiên bản rubric nháp.

**CHƯA LÀM — chưa triển khai/xác minh.**

## 28. Design Constraints

- FE chỉ dùng bộ chọn rời rạc, không tự tính điểm câu; không Playwright. Không có bước release/deploy.

**CHƯA LÀM — chưa triển khai/xác minh.**

## 29. Risks

- Luồng giám khảo lớn (nộp trực tiếp, nháp, finalize nguyên tử, phiên bản xem lại, dấu vân tay, chọn nguồn): đọc đủ các file trước khi sửa; chia theo từng đường ghi; test từng đường.

**CHƯA LÀM — chưa triển khai/xác minh.**

## 30. Risks

- Cần Azure fallback nhưng AI chưa chạy xong/thất bại: chặn nộp với thông điệp rõ; không lấp bằng 0.

**CHƯA LÀM — chưa triển khai/xác minh.**

## 31. Risks

- Lưu nháp tự động mỗi lần đổi bộ chọn tăng tải: debounce ở FE, giữ `expectedDraftVersion`.

**CHƯA LÀM — chưa triển khai/xác minh.**

## 32. Risks

- Giám khảo kỳ vọng ghi đè Pronunciation/Fluency: không cho (Pearson: chỉ máy chấm); nếu muốn khác cần quyết định rõ trước.

**CHƯA LÀM — chưa triển khai/xác minh.**
