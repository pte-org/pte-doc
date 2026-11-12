# Phase 10: Giám khảo chấm theo từng tiêu chí (P2, thay đổi phá vỡ hợp đồng, tenant-web)

## Mục tiêu

Thay việc giám khảo nhập **một điểm tổng 0-100** bằng nhập **điểm từng tiêu chí** trên cùng schema rubric với AI (L8). Tiêu chí chỉ máy chấm (Pronunciation, Oral Fluency) để trống thì lấy giá trị Azure từ bản chấm AI của cùng câu; Content = 0 kích hoạt cổng như AI.
**Điểm câu do server tính** (`RubricScorer`) và trả về trong phản hồi lưu nháp/nộp để UI hiển thị. Phạm vi tenant-web đã được spec duyệt.

## Stories/FR covered

- S6 (L8); liên quan FR-04, FR-05, FR-07 (vết giải thích cho nguồn EXAMINER ở Phase 6)

## Files to read first

- `D:\GitHub\pte-org\docs\CODING_STANDARDS_API.md`, `CODING_STANDARDS_WEB.md`, `API_RESPONSE_SETUP.md`, `COMMON_EXCEPTION_SETUP.md`, `TEST_SCENARIOS_IAM.md`
- Backend giám khảo:
  - `pte-api/app/src/main/java/com/pte/scoring/dto/request/SubmitExaminerScoreRequest.java`, `SaveExaminerDraftRequest.java`, `FinalizeExaminerWorkRequest.java` (cần xác minh nội dung)
  - `scoring/internal/service/examiner/ExaminerDirectScoreSubmitter.java`, `ExaminerDraftCommandService.java`, `ExaminerFinalizeSubmitter.java`, `ExaminerReviewVersionService.java` (`computeReviewVersion`, `computeRequestFingerprint`, `buildAiReference`), `ExaminerScoringService.java`, `ExaminerWorkflowCommandService.java`, `ExaminerAttemptDetailReader.java`, `ExaminerWorkRecorder.java`
  - `scoring/domain/ExaminerEvaluation.java`, `AnswerEvaluation.java`, `ScoringDomainConstants.java`
  - `scoring/dto/response/ExaminerAiReferenceResponse.java`, `ExaminerDecisionResponse.java`, `ExaminerScoreSubmissionResponse.java`, `ExaminerAnswerDetailResponse.java`, `ExaminerCommandResponse.java`, `AiScoreDetailResponse.java`
  - `scoring/internal/service/selection/ScoreSourceSelectionService.java`, `AttemptService.selectScoreSource(...)`; `internal/constant/ExaminerScoringConstants.java`, `internal/exception/examiner/*`
- **Mật độ gói**: `scoring/internal/service/examiner` đã **15 file** -> mọi class mới vào `scoring/internal/service/examiner/trait`.
- Frontend tenant-web: `pte-web/apps/tenant-web/features/examiner/` — `components/DecisionPanel.tsx`, `AiReferencePanel.tsx`, `ExaminerAttemptDetailView.tsx`, `ExaminerWorkView.tsx`, `useExaminerDraftState.ts`, `useExaminerSubmissionActions.ts`, `useExaminerSubmissions.ts`, `submissionTypes.ts`, `api.ts`, `constants.ts`, `messages/vi.ts`, `en.ts`, `workVi.ts`; test `tests/unit/features/examiner/examinerQueue.test.ts`
- Phase 1-6 (catalog, `RubricScorer`, `FormRule`, trait JSON có `scale`, `RubricRescoreService`, snapshot v2, `ExplanationFixtureBuilder`)

## Implementation steps

1. **Hợp đồng mới (breaking)**: `SubmitExaminerScoreRequest` và `SaveExaminerDraftRequest` thêm `traitScores` (map khóa -> số nguyên thang Pearson; `null` cho Pronunciation/Oral Fluency nghĩa "lấy từ máy"; **giới hạn số phần tử theo `RubricConstants`** — LOW-3). Task type có rubric AI (DI, RL, RTS, SGD, SWT, WE, SST, RA, RS): `traitScores` bắt buộc; `score` do **server tính**
   (client gửi `score` thì phải bằng giá trị tính được, nếu không từ chối). Task type không có rubric AI giữ `score` như cũ. Client cũ chỉ gửi `score` cho task type rubric bị từ chối với mã riêng (`ExaminerScoringConstants`), không đoán.
2. **Lưu trữ** (migration **số tiếp theo còn trống, kiểm tra lúc làm**; V32 dành cho rubric): thêm cột cho `ExaminerEvaluation` trong `answer_evaluations`: `trait_scores_json` (JSON có `scale = PEARSON_V1` và `rubricVersion`, cùng định dạng điểm AI) và `rubric_version_public_id`; cần xác minh nơi lưu bản nháp (`ExaminerEvaluation` trạng thái draft hay bảng khác). `score` vẫn là điểm câu đã tính (tương thích mọi nơi đọc `examinerScore`). Migration additive.
3. **Gói `examiner/trait`**: `ExaminerTraitScoreResolver` (kết hợp `traitScores` của giám khảo, `AiEvaluation` cùng câu và `EffectiveRubric` theo phiên bản ghim của câu; điền tiêu chí `null` nguồn `AZURE` từ Azure; **từ chối** nếu cần điền mà AI vắng/thất bại), `ExaminerTraitValidator` (đủ tiêu chí, nguyên, trong thang, không ghi đè tiêu chí chỉ máy chấm ngoài `null`; Form do mã tính, giám khảo không nhập),
   và lớp gọi `RubricScorer`. Giám khảo chấm CONTENT = 0 thì cổng kích hoạt, điểm câu = 0 (tiêu chí khác vẫn lưu).
4. **Điểm câu server-side trong phản hồi (MEDIUM-7)**: `ExaminerCommandResponse`/`ExaminerScoreSubmissionResponse` (phản hồi lưu nháp và nộp) trả thêm `itemScore` và `scoreTrace` (từ `RubricScorer`); `ExaminerAnswerDetailResponse` mang thêm mô tả mức và thang từng tiêu chí của rubric ghim (từ catalog) để giám khảo thấy tại chỗ **mà không mở rộng quyền endpoint rubric vendor**.
   Không có API mô phỏng cho giám khảo. FE hiển thị điểm câu **từ phản hồi lưu nháp** (lưu nháp tự động khi đổi bộ chọn), không tự tính.
5. **Cập nhật luồng**: `ExaminerDirectScoreSubmitter`, `ExaminerDraftCommandService`, `ExaminerFinalizeSubmitter` dùng `ExaminerTraitScoreResolver`; **dấu vân tay yêu cầu (`computeRequestFingerprint`) và phiên bản xem lại (`computeReviewVersion`) gồm `traitScores` và phiên bản rubric** (thử lại idempotent và phát hiện dữ liệu cũ vẫn đúng); `CONFIRM_AI` so sánh điểm tiêu chí/điểm câu tính được thay vì `score` thô;
   `ExaminerAiReferenceResponse` mang điểm tiêu chí AI và thang. Thông điệp lỗi mới vào `ExaminerScoringConstants`.
6. **Báo cáo và giải thích**: `ReportScoringAnswerView.traitScores` lấy từ `ExaminerEvaluation` khi nguồn là EXAMINER; snapshot v2 ghi chúng; API giải thích (Phase 6) hiển thị đủ vết, không còn "không phân rã" cho dữ liệu mới; chấm giám khảo cũ (chỉ `score`) vẫn hiển thị "điểm giám khảo, không phân rã".
7. **Frontend tenant-web** (không chạm vendor-web): `DecisionPanel.tsx` thay ô 0-100 bằng bộ chọn từng tiêu chí (rời rạc 0..max, tooltip mô tả mức lấy từ `ExaminerAnswerDetailResponse`; tiêu chí chỉ máy hiện giá trị Azure chỉ đọc và nút "Dùng của máy"), hiển thị `itemScore` và cảnh báo CONTENT = 0 từ phản hồi lưu nháp; `AiReferencePanel.tsx` hiện điểm tiêu chí AI;
   cập nhật `submissionTypes.ts`, `api.ts`, `useExaminerDraftState.ts`, `useExaminerSubmissionActions.ts`, `useExaminerSubmissions.ts`, `constants.ts`, thông điệp `vi.ts`/`en.ts`/`workVi.ts`; tách `_TraitScorePicker`, `_TraitReferenceRow`; component <= 150 dòng.
8. **Test backend** (dùng `ExplanationFixtureBuilder`): bộ ca bảng theo task type rubric (đủ/thiếu/ngoài thang/quá số phần tử), điền Azure khi `null` (và từ chối khi không có AI), CONTENT = 0 -> 0, `CONFIRM_AI` theo điểm tiêu chí, thử lại idempotent, dấu vân tay và `reviewVersion` đổi khi đổi `traitScores`, client cũ chỉ `score` bị từ chối đúng mã, `itemScore` trong phản hồi nháp khớp `RubricScorer`,
   chọn nguồn EXAMINER rồi publish: snapshot chứa điểm tiêu chí giám khảo và giải thích khớp (chênh lệch 0); cập nhật test giám khảo hiện có (`src/test/java/com/pte/scoring/internal/service/examiner`, `ExaminerWorkController`); cập nhật `ApiInventoryExportTest` nếu đổi endpoint.
9. **Test FE**: dựng thân yêu cầu từ bộ chọn, "Dùng của máy", hiển thị `itemScore` từ phản hồi, trạng thái vô hiệu khi thiếu tiêu chí; `tests/unit/features/examiner/*`.

## Acceptance criteria

- Giám khảo nộp theo từng tiêu chí cho task type rubric; điểm câu do server tính; `score` khác giá trị tính được bị từ chối; client cũ bị từ chối rõ ràng.
- Tiêu chí chỉ máy chấm để `null` lấy từ Azure của cùng câu; thiếu AI thì từ chối; giám khảo không nhập được Form; CONTENT = 0 -> điểm câu 0.
- Phản hồi lưu nháp/nộp có `itemScore` và `scoreTrace` khớp `RubricScorer`; UI hiển thị từ phản hồi, không tự tính.
- Thử lại (cùng `requestPublicId`, cùng `traitScores`) idempotent; đổi `traitScores` đổi dấu vân tay và `reviewVersion`; dữ liệu cũ phát hiện đúng `StaleReviewVersionException`.
- Chọn nguồn EXAMINER rồi publish: snapshot v2 chứa điểm tiêu chí giám khảo; giải thích khớp (chênh lệch 0).
- Không mở rộng quyền đọc endpoint rubric vendor cho giám khảo; không API mô phỏng cho giám khảo.
- `PackageDensityTest` xanh (class mới ở `examiner/trait`); FE `typecheck/lint/test` tenant-web xanh; toàn suite `app` xanh.

## Validation commands

```powershell
cd D:\GitHub\pte-org\pte-api
.\mvnw.cmd -pl app -DskipTests compile
.\mvnw.cmd -pl app test -Dtest="Examiner*Test,ExaminerTraitScoreResolverTest,ExaminerTraitValidatorTest,ExaminerTraitSubmitIT,ScoreSourceSelection*Test,ApiInventoryExportTest"
.\mvnw.cmd -pl app test -Dtest="PackageDensityTest,SourceFileSizeTest,NoDirectClockAccessTest,ModuleStructureTest"
.\mvnw.cmd -pl app test

cd D:\GitHub\pte-org\pte-web
pnpm --filter tenant-web typecheck; pnpm --filter tenant-web lint; pnpm --filter tenant-web test
pnpm --filter @pte/api-client typecheck      # cần xác minh tên script
```

## Design Constraints

- `docs/CODING_STANDARDS_API.md`, `CODING_STANDARDS_WEB.md`, `API_RESPONSE_SETUP.md`, `COMMON_EXCEPTION_SETUP.md`, `TEST_SCENARIOS_IAM.md` bắt buộc; file <= 300 dòng; `internal/**` <= 15 class (`service/examiner` đã đầy: chỉ thêm vào gói con); `Clock` inject; message/mã lỗi trong `ExaminerScoringConstants`; cross-module chỉ qua API công khai.
- Thay đổi phá vỡ hợp đồng có chủ đích (spec: S6); không giữ đường ghi điểm tổng cho task type có rubric; client cũ bị từ chối rõ ràng.
- Điểm câu chỉ do `RubricScorer` tính ở server; không tin `score` từ client; Pronunciation/Oral Fluency chỉ do máy; Form chỉ do mã.
- Giữ nguyên tính bất biến, idempotent, khóa phiên/đáp án/xuất bản và thứ tự khóa của luồng giám khảo; không làm yếu `reviewVersion` và dấu vân tay (phải gồm `traitScores`).
- Cách ly tenant và phân công giám khảo như hiện tại; giám khảo không thấy phiên bản rubric nháp.
- FE chỉ dùng bộ chọn rời rạc, không tự tính điểm câu; không Playwright. Không có bước release/deploy.

## Quality and Testing State

- Quality: skipped_by_user (decision: user_confirmed_skip)
- Testing: passed (2026-11-05). `.\mvnw.cmd -pl app clean test-compile` sạch; toàn bộ `.\mvnw.cmd -pl app test`: **4641 test, 0 failures, 0 errors, 73 skipped**, BUILD SUCCESS (đọc từ 522 file surefire XML; nền phase 9: 4602/73, +39). Docker có: Postgres IT chạy, Flyway áp V32 và V33 (15 lần). Lần chạy đầu có 1 lỗi `RubricRescoreServiceTest.everyAnswerGetsItsExplanationKind`: fixture dùng dòng EXAMINER có 1 tiêu chí để mô tả "điểm giám khảo cũ"; sau Phase 10 dòng có tiêu chí được truy vết theo rubric nên fixture đổi thành dòng chỉ có `score` (đúng ý ca test), không đổi mã sản phẩm.
- FE (chỉ `node_modules/.bin`, không install; `pnpm-lock.yaml` md5 `efb47b60...` không đổi): tenant-web vitest **649** (54 file), eslint sạch, `tsc --noEmit` chỉ 2 lỗi `.next/types/validator.ts` cũ (lỗi kiểu trong `traitComponents.test.tsx` đã sửa); `@pte/api-client` tsc exit 0, vitest 685.
- Checklist:
  - B1 hợp đồng mới: DONE (`traitScores` Map BigDecimal, giới hạn `RubricConstants.MAX_TRAIT_SCORE_ENTRIES`; client cũ -> `EXAMINER_TRAITS_REQUIRED`; `score` lệch -> `EXAMINER_TRAIT_SCORE_MISMATCH`; task không rubric giữ `score`).
  - B2 lưu trữ: DONE (V33 thêm `trait_scores_json`; tái dùng `rubric_version_public_id` của V32; nháp là `ExaminerEvaluation` trạng thái DRAFT).
  - B3 gói `examiner/trait` (7 class; gói cha giữ 15): DONE; điểm câu chỉ qua `RubricScorer`, Form qua `FormRule.bandFor`.
  - B4 `itemScore`/`scoreTrace` trong phản hồi nháp/nộp, `ExaminerAnswerDetailResponse.rubric` có mức/thang: DONE; quyền rubric vendor không mở rộng (controller rubric vẫn chỉ 4 role vendor); không API mô phỏng cho giám khảo.
  - B5 luồng nộp trực tiếp/nháp/finalize, vân tay + reviewVersion gồm traits + phiên bản, CONFIRM_AI theo tiêu chí, AI reference có điểm tiêu chí + `traitMaxima`: DONE (`ExaminerTraitCommandTest`).
  - B6 báo cáo/giải thích nguồn EXAMINER: DONE (`ExaminerTraitSnapshotTest` 16 ca = 9 task type + 7 ca CONTENT=0 cho task có cổng; RA/RS không có cổng theo Pearson; `ScoreExplanationServiceTest` chênh lệch 0; dòng cũ chỉ `score` -> EXAMINER_SCORE).
  - B7 FE: DONE có lệch: bộ chọn nằm trong `ExaminerTraitFields.tsx` thay vì `_TraitScorePicker`/`_TraitReferenceRow`; chuỗi trong `traitText.ts` thay vì `messages/vi.ts`/`en.ts`; không có nút "Dùng của máy" riêng từng tiêu chí: tiêu chí máy luôn chỉ đọc và tự gửi `null`, nút "Dùng điểm AI" ở `AiReferencePanel` áp toàn bộ tiêu chí AI cùng phiên bản. Điểm câu chỉ từ phản hồi (`applySavedDraft`), tự lưu debounce 350 ms, giữ `expectedDraftVersion`; cảnh báo thiếu điểm máy hiển thị.
  - B8 test backend: DONE trừ `ExaminerTraitSubmitIT` (NOT DONE: không viết IT Postgres riêng; phủ bằng unit với logic thật + V33 được Flyway áp trong IT hiện có). `ApiInventoryExportTest` đã cập nhật.
  - B9 test FE: DONE (`traitDraft.test.ts`, `traitComponents.test.tsx`).
  - Ràng buộc: allowlist (kể cả rubric-single-source) rỗng; `assessment` không import `scoring`; `PackageDensityTest`, `SourceFileSizeTest`, `NoDirectClockAccessTest`, `ModuleStructureTest`, `RubricScoreSingleSourceTest` xanh trong suite đầy đủ.
- Chưa kiểm chứng: chạy trên trình duyệt, gọi API thật end-to-end, `next build`.

## Risks

- Luồng giám khảo lớn (nộp trực tiếp, nháp, finalize nguyên tử, phiên bản xem lại, dấu vân tay, chọn nguồn): đọc đủ các file trước khi sửa; chia theo từng đường ghi; test từng đường.
- Cần Azure fallback nhưng AI chưa chạy xong/thất bại: chặn nộp với thông điệp rõ; không lấp bằng 0.
- Lưu nháp tự động mỗi lần đổi bộ chọn tăng tải: debounce ở FE, giữ `expectedDraftVersion`.
- Giám khảo kỳ vọng ghi đè Pronunciation/Fluency: không cho (Pearson: chỉ máy chấm); nếu muốn khác cần quyết định rõ trước.

## Preflight / quyết định khi làm (2026-11-05)

- Đã đọc chuẩn API/WEB và API_RESPONSE_SETUP/COMMON_EXCEPTION_SETUP/TEST_SCENARIOS_IAM; plan/spec và phase 1-9; đang truy vết ba đường ghi giám khảo, hợp đồng FE và báo cáo. Không sửa ranh giới tenant/phân công hay mở rubric vendor.
- `answer_evaluations.rubric_version_public_id` đã có ở Base AnswerEvaluation (V32), tái dùng; migration tiếp theo chỉ thêm trait_scores_json. Lấy số lớn nhất thực tế trước tạo.
- Class mới ở examiner/trait (gói cha đã đủ 15); score/trace do RubricScorer, FormRule.bandFor; null AZURE chỉ lấy từ AI hợp lệ của cùng câu/phiên bản.
