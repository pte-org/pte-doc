# Phase 5: API host/examiner và web UI

Covers: P1-3, P1-4, P2-1, FR-09, FR-10, FR-13

## Requirements
Host thấy chi tiết AI trong modal câu trả lời và score review; examiner luôn thấy điểm AI và chi tiết cho câu được giao; mọi nơi hiển thị có nhãn "AI ước lượng"; bảng host có cột AI và chấm tay cạnh nhau với highlight lệch lớn.

## Steps
1. Mở rộng response chi tiết câu trả lời và score review của host để trả thêm tiêu chí, feedback, transcript, chi tiết JSON, cờ fallback và mã lý do lỗi từ bảng chi tiết AI.
2. Mở rộng response chi tiết câu của examiner.
   - Trả điểm AI và chi tiết bất kể examiner đã chấm hay chưa, kèm trạng thái chấm (đang chấm, lỗi, đã chấm).
   - Chỉ thêm dữ liệu AI bên trong đường xử lý đã kiểm assignment. Tra chi tiết AI theo answer và tenant của bản ghi đã qua kiểm tra, không theo id client gửi lên.
3. Cập nhật kiểu dữ liệu trong api-client để khớp response mới của host và examiner.
4. Tenant-web phía host: hiển thị chi tiết AI trong modal chi tiết câu trả lời và trong panel score review, kèm nhãn "AI ước lượng", transcript cho dạng nói và thông báo khi dùng fallback.
5. Tenant-web phía examiner: hiển thị điểm AI và chi tiết cạnh ô nhập điểm tay; câu chưa có điểm AI hiển thị trạng thái; ô chấm tay vẫn hoạt động độc lập.
6. Host có nút chấm lại khi kỳ thi còn câu `SCORING_FAILED` hoặc câu kẹt `AI_SCORING` (dùng lệnh chấm đã mở rộng ở Phase 2), kèm số câu sẽ được chấm lại. Nút bị ẩn khi kỳ thi đã publish.
7. P2: bảng câu trả lời của host có hai cột điểm AI và chấm tay cạnh nhau, highlight câu lệch >= 20 điểm trên thang 0–100. Câu DI chấm không có ảnh mang dấu "độ tin cậy thấp".
8. Test và kiểm tra:
   - Test API: host; examiner trong và ngoài assignment.
   - Test xác nhận response cho học sinh và cho reporting không chứa chi tiết AI.
   - Test thành phần web nếu dự án đã có.
   - Chạy lint, type-check, build. Format chỉ file đã đổi.
   - Báo user những chỗ cần tự kiểm UI.

## Success Criteria
- Test API xác nhận host nhận chi tiết AI và examiner nhận điểm AI trước khi tự chấm; examiner ngoài assignment bị từ chối như hiện tại.
- Type-check và build của tenant-web và api-client pass; test hiện có của module scoring và examiner pass.
- User tự kiểm UI và xác nhận: modal host, score review, màn examiner đều hiển thị tiêu chí, feedback, transcript và nhãn "AI ước lượng"; câu lệch >= 20 điểm được highlight.
- Câu `SCORING_FAILED` hiển thị mã lý do ở cả host và examiner. Host bấm chấm lại thì các câu đó quay lại hàng đợi.
- Test xác nhận API học sinh và dữ liệu reporting không lộ chi tiết AI.

## Risks
- Lộ điểm AI cho học sinh: không đổi API học sinh; test xác nhận chỉ host và examiner được giao nhận dữ liệu.
- Response lớn do transcript/JSON: chỉ trả ở endpoint chi tiết, không trả trong danh sách.
- Examiner bị ảnh hưởng quyết định chấm do luôn thấy AI: đã chốt theo yêu cầu user, nhãn "AI ước lượng" làm rõ tính tham khảo.
- Không tự chạy kiểm UI: nhờ user check và nêu rõ cần xem màn nào.

## Execution Log
<!-- Filled by /ck:cook at the end of this phase — leave placeholders when planning -->

### Errors Encountered
- code-reviewer lần 1: REQUEST CHANGES. (1) HIGH: sau khi host bấm chấm lại, bảng score review vẫn hiện "Mã lý do" cũ của câu đã quay lại hàng đợi. (2) MEDIUM: examiner không thấy trạng thái AI cho câu hợp lệ chưa có bản ghi chi tiết AI. (3) MEDIUM: modal host hiện điểm AI hai lần; nhãn "AI ước lượng" gắn cho cả câu không có AI.
- simplify (4 agent): logic "câu nào chấm lại được" nằm hai nơi (JPQL và Java); `findFlags` trả cả các dòng không có cờ; hai bảng lặp cùng JSX ô điểm AI và cùng điều kiện tô hàng; nhãn "AI ước lượng" khai báo hai nơi.
- Khi sửa simplify, một lần mình rút gọn `aiFallback` thành `containsKey` là sai (sau khi lọc DB, dòng chỉ có `failureReason` vẫn có trong map); phát hiện ngay và sửa lại trước khi chạy test.

### Root Cause
- (1) `findFlags` trả `failureReason` còn lưu từ lần lỗi trước, `toHostReview` chép thẳng sang response mà không xét trạng thái câu. `markAiDispatched` không xoá dòng chi tiết nên lý do cũ còn đến khi lần chấm mới ghi kết quả.
- (2) `statusOf` trả null cho câu PENDING chưa có dòng chi tiết, và examiner UI chỉ vẽ khối AI khi `ai` khác null.
- (3) Modal giữ ô điểm `rawScore` cũ bên cạnh khối `AiScoreDetail` cũng hiện điểm; ô cũ dùng nhãn AI cho mọi câu.

### Resolution
- (1) `toHostReview` chỉ trả `aiFailureReason` khi trạng thái là `SCORING_FAILED`. Test mới `hostReview_dropsTheOldFailureReasonOnceTheAnswerIsQueuedAgain` (viết trước, chạy thấy fail, rồi sửa).
- (2) `AiScoreDetailResponse.pending()`; `ExaminerScoringService` dùng `getOrDefault(..., pending())` sau bước kiểm assignment. Test mới `anAnswerTheHostHasNotQueuedYetShowsAsPendingRatherThanMissing` (cũng viết trước, thấy fail).
- (3) Modal chỉ hiện ô điểm riêng khi `answer.ai === null`, nhãn trung tính "Score"; bỏ `AI_SCORE_TEXT.SCORE_LABEL`.
- Simplify: thêm `ScoringAnswer.isRescorable(staleBefore)` làm nơi duy nhất cho rule chấm lại phía Java; `findFlags` lọc `fallback = true OR failureReason IS NOT NULL` ngay trong JPQL; hằng trạng thái `private`; sửa Javadoc; thêm `AiScoreCell` và `aiGapRowClass`; bỏ `ANSWER_TABLE_HEADERS.AI_SCORE`, `scoreGap`, các export thừa; gọn `RescoreAiButton`.
- Không làm (ghi nhận): `DataTable.rowClassName` giữ lại (đáp ứng yêu cầu tô hàng, prop thêm vào không phá cũ); logic cờ lệch >= 20 vẫn ở web; `aiDetails == null` ở constructor tương thích test giữ nguyên vì phải giữ chữ ký test dùng; không tách thêm `canRescore` từ backend; không memo `JSON.stringify` của khối chi tiết.
- Sau khi user trả lời: thêm cờ `aiScored` vào `AnswerListItemResponse` (tính bằng `ScoringEligibilityQueryService.isAiEligible`, test `listRowsSayWhichAnswersAreAiScored` viết trước). Bảng câu trả lời chỉ hiện điểm AI và tô lệch >= 20 khi `aiScored`; câu trắc nghiệm hiện "—". Bảng score review chỉ tô lệch khi `scoringMethod` là AI (`isAiScoringMethod`).
- Còn tồn tại, user đã chấp nhận: câu SCORED trước V93 không có dòng chi tiết hiện "Chờ AI chấm" ở examiner (chỉ dữ liệu local cũ). Kiểm tra RS thiếu `referenceAnswerText` lúc soạn đề đã chuyển sang Phase 6 (bước 0).

### Test Results After Fix
- Scoring suite (`com.pte.scoring.**`): tests=558, failures=0, errors=0, skipped=4 (trước phase 5 là 530); hai test mới của lượt review thấy fail trước khi sửa; test `aiScored` mới không chạy riêng ở trạng thái đỏ (chỉ biết chưa biên dịch được vì thiếu trường). Các suite attempt, reporting, session đã chạy exit=0 ở lượt trước khi thêm code simplify/review (không chạy lại sau lượt sửa cuối).
- `AiDetailNotLeakedTest` (phản chiếu record học sinh, reporting, examiner mù): pass.
- api-client: vitest 419 passed, typecheck sạch. tenant-web: tsc, eslint, next build sạch sau thêm `aiScored`.
- tenant-web: `tsc --noEmit` sạch, eslint sạch trên `features/aiScore`, `features/exams`, `features/examiner`, `next build` exit=0. Prettier: các file mới và file vốn đã sạch ở HEAD đã format; 3 file vốn lệch format từ HEAD (`ExaminerWorkView`, `AnswerDetailModal`, `HostScoreReviewPanel`) giữ nguyên.
- Không có test thành phần web (tenant-web không có test runner). Chưa kiểm UI thật, chưa gọi Azure/Gemini thật.
- code-reviewer lần 2: APPROVE (còn 2 mục LOW đã ghi ở trên).
