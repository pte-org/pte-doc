# Spec: Examiner — AI hỗ trợ, người chấm quyết định

**Date:** 2026-10-11
**Status:** Thiết kế điều chỉnh v2 — chờ duyệt bố cục và handoff
**Scope:** Tenant web + API/phân quyền/quy tắc công bố cần thiết.
**Supersedes:** Bản blind marking và giả định “không cần API mới”.

## Problem Statement

Người dùng chốt: “Examiner xem điểm chấm AI để chấm có hỗ trợ có thể chấm lại nếu AI sai sót và examiner vẫn là người chấm và quyết định điểm cuối cùng, host sẽ công bố kết quả sau đó”.

Luồng sản phẩm: AI đưa điểm tham khảo → Examiner đọc/nghe câu trả lời, xác nhận điểm AI hoặc chấm lại → Examiner chốt điểm cuối cùng → Host kiểm tra đủ điều kiện và công bố. Điểm AI không tự trở thành điểm cuối cùng trong luồng cần Examiner.

Backend hiện có điểm AI và Examiner độc lập, queue/detail assignment-scoped, điểm Examiner bất biến và Host chọn nguồn AI/EXAMINER. Backend chưa cho Examiner đọc điểm AI hoặc đảm bảo Host không thay nguồn sau khi người chấm quyết định. Đây là thay đổi nghiệp vụ có backend, không chỉ thay UI.

## Decisions and Scope

- **AI là tham khảo:** chỉ điểm AI thật, hợp lệ 0–100; giữ dữ liệu AI gốc khi Examiner chấm lại.
- **Examiner là người quyết định:** cả dùng điểm AI và nhập điểm khác đều tạo quyết định EXAMINER; không chọn nguồn AI trực tiếp thay cho việc người chấm chốt.
- **Host công bố:** trong session cần Examiner, Host không ghi đè điểm đã chốt bằng teacherScore, không chọn lại nguồn AI và không dùng bulk source-selection để lách quy tắc.
- **Hai chế độ session:** dùng MANUAL_EXAMINER hiện hữu cho luồng có Examiner, dù AI vẫn chạy hỗ trợ; AI_ONLY hiện hữu tiếp tục dành cho session không cần Examiner. MANUAL_EXAMINER phải được xác lập trên grading cohort/session trước khi nhận quyết định cuối cùng và không đổi sang AI_ONLY để bỏ qua chấm người. Không tự chuyển mọi session/tenant cũ sang chế độ mới.
- MANUAL_EXAMINER cần phân công và chốt đủ mọi câu subjective trong cohort trước khi công bố; objective vẫn do bộ chấm objective hiện hữu xử lý. Không áp người chấm cho câu objective ngoài eligibility.
- Lifecycle thực: Host đóng session rồi freeze grading cohort với MANUAL_EXAMINER. Cohort FROZEN đã đủ để bắt đầu chốt từng câu; không chờ COMPLETED vì COMPLETED phụ thuộc điểm Examiner. Bài đã phân công nhưng chưa freeze có thể xem nội dung/AI read-only, với thông báo chờ Host chuẩn bị danh sách; không nhận quyết định mới.
- Quyết định mới chỉ cho attempt là thành viên không excluded của frozen cohort. Không thêm assignment vào cohort AI_ONLY hoặc cho chốt bài đã bị disposition/excluded; công bố MANUAL_EXAMINER dùng đúng tập thành viên frozen, không lấy lại mọi submitted attempt động.
- “Chấm lại” trong MVP nghĩa là chấm lại **điểm AI trước khi chốt**. Điểm đã chốt khóa theo hành vi bất biến hiện hữu. Sửa/reopen quyết định đã chốt là workflow riêng, chưa được yêu cầu.
- Giữ ẩn danh thí sinh và đáp án đúng. Quyền đọc điểm AI của Examiner được mở có chủ đích trong projection riêng; không cấp quyền Host.

## User Stories

- **[P1]** Examiner xem bài được phân công và nhận biết bài còn câu cần duyệt.
  Accepted when: server filter/page, progress đếm số câu đã chốt; “AI đã có điểm” không làm bài thành COMPLETED.
- **[P1]** Examiner xem đề, câu trả lời và điểm AI tham khảo trong một trang chấm có URL riêng.
  Accepted when: tenant/assignment/role kiểm tra tại backend; đủ sáu content kinds, media authorized, AI không khả dụng có trạng thái rõ.
- **[P1]** Examiner chủ động chọn dùng điểm AI hoặc chấm lại rồi chốt.
  Accepted when: field ban đầu trống; dùng AI chỉ điền điểm, không gửi; chấm lại cho nhập số nguyên 0–100; confirm hiển thị đúng target/điểm trước ghi.
- **[P1]** Host công bố đúng điểm Examiner đã chốt.
  Accepted when: nguồn dùng cho report là EXAMINER kể cả điểm bằng AI; chưa đủ câu chốt thì chặn công bố; Host đổi nguồn AI/ghi đè bị backend từ chối.
- **[P1]** AI về muộn, timeout hoặc media lỗi không làm mất quyết định/draft hay báo success giả.
  Accepted when: late AI không thay điểm đã chốt, unknown outcome reconcile từ backend, retry cùng request idempotent.
- **[P2]** AI rubric, nhận xét hoặc transcript chỉ hiển thị khi backend/provider thực sự có contract; không dựng dữ liệu giả.
- **[P3]** Reopen điểm đã chốt, hội đồng phân xử, hai người chấm, grading rubric mới và lý do sửa điểm bắt buộc nằm ngoài MVP.

## Screen Design

### Bài cần duyệt — /examiner/work

- Reuse tenant DashboardChrome và nav Examiner, không tạo tenant app khác.
- Mã bài/kỳ thi UUID rút gọn, assignedAt, đã chốt/tổng câu, trạng thái Chưa duyệt / Đang duyệt / Đã chốt.
- ALL/PENDING/IN_PROGRESS/COMPLETED vẫn là filter server, page mặc định20/max100. Không hiển thị KPI từ một trang queue.
- Progress chỉ lấy quyết định Examiner. Bài đủ câu chốt mang nhãn “Đã chốt”, không “Đã công bố”.
- Queue không bịa AI completion toàn bài, student name, session title hoặc publication status khi DTO thiếu. Thông tin mới phải có safe projection.
- Deep link từ Mở duyệt/Xem bài tới /examiner/work/[sessionPublicId]/[attemptPublicId].

### Trang duyệt và chấm

- Header: bài ẩn danh, session, tiến độ đã chốt, nhãn luồng “AI hỗ trợ → Examiner chốt → Host công bố”.
- **Trái:** navigator câu, task type, Cần duyệt / Đã chốt; không tự lọc theo whitelist Speaking/Writing.
- **Giữa:** đề frozen và câu trả lời; text, prompt media, response audio/image/options phân biệt rõ.
- **Phải:** khối “Điểm AI tham khảo” read-only; phía dưới “Điểm cuối cùng” do Examiner quyết định.
- Có AI hợp lệ: button “Dùng điểm AI” điền đúng điểm tham khảo vào field; button “Chấm lại” mở nhập điểm mới và focus input. Không tự lấy AI làm default, không bulk accept tất cả câu.
- Chấm lại hiển thị chênh lệch có dấu giữa điểm Examiner đang chọn và AI, chỉ khi cả hai hợp lệ. Đây là chênh lệch điểm, không confidence/quality score.
- AI chưa có/thất bại/không hợp lệ: không hiển thị 0 giả; tắt Dùng điểm AI, vẫn cho chấm thủ công khi nội dung cần chấm khả dụng.
- “Chốt điểm” mở ConfirmDialog: target, AI tham khảo nếu có, điểm cuối cùng, lựa chọn dùng AI/chấm lại và thông báo chốt xong không thể sửa.
- Sau success authoritative: khóa field, hiển thị điểm cuối cùng, ai/when chốt theo dữ liệu cho phép; nhãn “Đã chốt · Chờ Host công bố” chỉ khi backend xác nhận chưa publication.
- Nếu tất cả câu đã chốt, banner bài “Đã chốt đủ câu”; không thêm mutation complete giả.
- Không tự chuyển câu sau success; có button Câu cần duyệt tiếp theo.
- Mobile stack: navigator → đề/câu trả lời → điểm AI + điểm cuối cùng. Keyboard/focus/error labels đầy đủ.

### Host: sẵn sàng công bố

- Trong MANUAL_EXAMINER, review read-only AI và Examiner, nguồn cuối cùng EXAMINER được khóa.
- Hiển thị số câu chưa chốt/số bài thiếu phân công và link nghiệp vụ hiện hữu; publication dùng preview/cohort/report checks thật.
- Nút công bố chỉ khả dụng khi backend xác nhận mọi điều kiện hiện hữu và mọi câu cần Examiner đã chốt.
- Giữ hành vi AI_ONLY hiện hữu ở phạm vi đó; không dùng UI disabled làm biện pháp bảo vệ duy nhất.

## Proposed API Contracts — Changes Required

Ba route Examiner hiện có là điểm mở rộng, chưa coi fields dưới đây đã tồn tại:

| Route | Thay đổi đề xuất |
| --- | --- |
| GET /api/v1/examiner/work | Giữ filter/page/count; trạng thái và submitted count tiếp tục dựa trên quyết định người chấm. |
| GET /api/v1/examiner/work/{sessionPublicId}/{attemptPublicId} | Bổ sung gradingMarkingMode/publicationState có phân quyền; từng answer có aiReference và decision, reviewVersion để phát hiện dữ liệu cũ. |
| POST /api/v1/examiner/work/answers/{answerPublicId}/score | Mở rộng request chốt với decisionKind, expectedReviewVersion, requestPublicId; cùng score nguyên0..100. |

Proposed aiReference: { availability, score, scoredAt, version }. score chỉ non-null khi AI thật/hợp lệ; availability rõ AVAILABLE/PENDING/FAILED/UNAVAILABLE theo dữ liệu server thực tế. Không suy ra FAILED chỉ vì rawScore null. Không lộ provider secrets, student PII hoặc reference answer. Không giả rubric/feedback/transcript từ một raw score.

Proposed decision: { status, score, decisionKind, finalizedAt, reviewedAiScore, reviewedAiVersion }. Quyết định mới có decisionKind CONFIRM_AI hoặc MANUAL; điểm đã chốt là EXAMINER. Dữ liệu backfill có LEGACY_IMPORTED read-only, không cho client chọn. reviewedAiScore/version ghi snapshot AI thật sự Examiner đã xem, không thay theo AI chạy lại. Availability/status enums và serialization cụ thể chốt ở plan dựa trên scorer state thực.

Đề xuất request: { score, decisionKind, expectedReviewVersion, reviewedAiVersion, requestPublicId }. reviewedAiVersion lấy từ reference đã hiển thị, nullable khi không có AI khả dụng. CONFIRM_AI phải khớp AI available và version/score server; MANUAL không yêu cầu AI có điểm. Không cho client tự gửi selectedScoreSource hay actorPublicId.

reviewVersion theo từng answer, bao gồm frozen content identity, AI availability/version, quyết định hiện tại và policy/publication state; không bao gồm URL media tạm thời. MANUAL cũng phải khớp AI snapshot đã xem nếu có. AI đổi trong lúc nhập điểm trả409, giữ điểm draft để Examiner xem dữ liệu mới và xác nhận lại; không ghi AI mới nhất vào audit rồi gọi là AI đã xem.

Response chốt: answerPublicId, decision, selectedScoreSource=EXAMINER và reviewVersion cập nhật. plan xác định cách giữ tương thích request/DTO cũ, cập nhật client và validation; không âm thầm chấp nhận payload mới trên route chỉ có {score}.

## Functional Requirements

1. **FR-01 Auth:** EXAMINER active tenant/assignment cho queue, detail, AI reference và finalize. Không gọi Host review API từ Examiner. Giữ login precedence/multi-role hiện hữu và route guard; wrong role Forbidden.
2. **FR-02 Blind identity:** mở quyền đọc điểm AI có chủ đích; vẫn giữ ẩn danh PII, Host teacherScore, correct answers, other examiner data và provider secrets.
3. **FR-03 Reference validity:** aiReference chỉ chứa AI có nguồn thật/hợp lệ. AI unavailable không cản chấm tay khi nội dung khả dụng; pending AI không tự làm quyết định Examiner bị thay đổi.
4. **FR-04 Explicit decision:** Dùng AI chỉ điền, Chấm lại chỉ nhập; finalize luôn explicit confirm. Trống/-1/101/thập phân invalid, 0/100 valid. Nếu nhập điểm khác sau Dùng AI, chuyển decisionKind sang MANUAL.
5. **FR-05 Atomic finalize:** một transaction kiểm tra actor/assignment/policy/publication, optimistic version, ghi quyết định Examiner + chọn EXAMINER + audit; không hai bước “lưu điểm rồi client gọi chọn nguồn”. Khóa/vai trò/thứ tự lock thống nhất với Host selection/publication và AI persistence.
6. **FR-06 Immutable and idempotent:** điểm Examiner đã chốt không update. Thứ tự: kiểm tra quyền đọc hiện tại → tra request đã commit và đối chiếu fingerprint → trả quyết định cũ nếu khớp → chỉ kiểm tra expected version/publication cho quyết định mới. requestPublicId chống duplicate/replay, phạm vi tenant/actor; fingerprint gồm answer/score/kind/expectedReviewVersion/reviewedAiVersion. Cùng key khác intent trả conflict. Retry đã commit không bị409 chỉ vì chính finalize trước đã đổi reviewVersion; không lấy AI version mới thay quyết định cũ. Quyền đọc bị mất vẫn chặn response, không lộ dữ liệu sau publication.
7. **FR-07 AI snapshot:** CONFIRM_AI stale/version changed trả409, refetch và yêu cầu duyệt lại; không tự thay score. AI chạy lại sau finalize không đổi source hoặc điểm cuối cùng. MANUAL vẫn ghi đúng snapshot AI đã xem nếu có.
8. **FR-08 Host boundary:** MANUAL_EXAMINER không cho Host chọn AI, bỏ source EXAMINER hoặc dùng teacherScore làm final. Chặn trên service/API kể cả bulk ALL/SECTION/TASK_TYPE, không chỉ ẩn control. Không cho chuyển mode sang AI_ONLY sau khi đã nhận quyết định để bypass.
9. **FR-09 Publication:** mọi câu subjective trong MANUAL_EXAMINER cohort phải có assignment và quyết định publishable EXAMINER; report dùng đúng Examiner score. Không dùng AI fallback khi thiếu chốt. Giữ POST preflight và bodyless POST publish hiện hữu; transaction publish kiểm tra lại readiness dưới session mutex. Không có expectedVersion publication protocol hiện hữu, không chỉ dựa vào nút disabled hoặc preflight cũ.
10. **FR-10 Existing sessions:** AI_ONLY và mọi published snapshot không đổi. MANUAL_EXAMINER chưa công bố dùng quy tắc mới: backfill nguồn EXAMINER từ điểm người chấm đã lưu, kiểm tra ownership/assignment, audit LEGACY_IMPORTED với AI snapshot unknown/null; không suy diễn đã dùng AI hay chấm lại. Thiếu quyết định hoặc policy/provenance mơ hồ thì chặn finalize/publication, không fallback AI. Không giữ hai contract trái nhau trong cùng MANUAL_EXAMINER; plan phải xác định các trạng thái legacy cần migration trước rollout.
11. **FR-11 Content/media:** đủ AUDIO/TEXT/SELECTION/POSITIONAL_SELECTION/WORD_INDICES/UNRECOGNIZED, frozen prompt; native audio no autoplay. Nội dung/audio/image cần chấm lỗi thì khóa finalize, giữ draft và refetch authorized detail để cấp media URL mới. Không bắt phát hết audio. detail không focus-refetch reset player.
12. **FR-12 Draft/navigation:** draft điểm chỉ memory theo actor/session/attempt/answer; chuyển câu/media refresh giữ draft. App-managed leave confirm; không hứa giữ qua reload. Logout/tenant/identity change clear immediately.
13. **FR-13 Unknown outcome:** timeout giữ nguyên request id/value/kind/version; refetch authoritative decision. GET PENDING không chứng minh POST trước bị hủy, không cho đổi giá trị khi còn unknown; manual resend cùng fingerprint. Không mutation retry tự động hoặc success optimistic chưa có backend proof.
14. **FR-14 Conflicts/access:** 409 refresh quyết định/version, không tự đổi intent; 403/404 khóa controls, nhãn Bài không còn khả dụng. Sau publication không hứa Examiner history nếu backend hiện cấm; không dùng cache làm quyền mutation.
15. **FR-15 Queue/detail:** deep link, query keys tenant/actor/session/attempt; pagination server, progress đếm đã chốt. Restore queue filter/page, optional answer selection qua URL an toàn. Đủ route loading/error/empty.
16. **FR-16 UI conventions:** locale vi/en, shared primitives, semantic tokens/Tailwind, TanStack APIs; no any, không import Host scoring view vào Examiner. Không tự thêm feature flag hoặc bật rollout.

### Research constraints trước implementation

Các writer AI/Examiner/Host, objective ingest và grading reconciliation phải thống nhất serialize theo session trước khi lấy answer/state/cohort locks. Listener BEFORE_COMMIT hiện chạy reconcile trong transaction writer; chỉ giữ comment answer→state không đủ chứng minh an toàn vì reconcile có cohort/member locks. Kế hoạch cần lock matrix đầy đủ, transaction scheduler theo từng session và kiểm tra publication/concurrent AI/finalize; không chuyển listener phase ngầm mà chưa xử lý transaction boundary.

Publication MANUAL_EXAMINER phải revalidate frozen cohort và pinned expected coverage trước snapshot. Hiện ReportPublishService chỉ duyệt scoring inputs có sẵn và mọi submitted attempts, nên chỉ khóa Host chọn nguồn chưa đủ bảo vệ yêu cầu “chốt đủ mọi câu”. AI_ONLY giữ hành vi hiện hữu theo phạm vi đã chốt.

## Codebase Placement

- Current ExaminerWorkView.tsx tại pte-web/apps/tenant-web/features/examiner/ (không nằm dưới components).
- Split feature-local components ExaminerQueueView, ExaminerAttemptView, _AnswerNavigator, _AiReferencePanel, _ExaminerDecisionPanel và response renderers.
- New frontend route app/(dashboard)/examiner/work/[sessionPublicId]/[attemptPublicId]/{page,loading,error}.tsx, thin wrappers; giữ tenant shell.
- API/DTO shared tại packages/api-client/src/requests/scoring/examiner.ts và types/scoring/index.ts; mở rộng đồng bộ frontend/backend.
- Locale packages/ui/src/i18n/LocaleProvider.tsx; ConfirmDialog/DataTable/Pagination/ErrorState/ForbiddenState/EmptyState/useToast theo exports thật.
- Backend scoring public DTO dưới scoring/dto/request,response, internal controller/service/domain/repository giữ convention. AI projection không tái sử dụng HostScoreReviewView.
- Tích hợp ExaminerScoringService, ScoreSourceSelectionService, GradingCompletionEvaluator/cohort, reporting input/publication và audit đúng ownership/module facades. Plan xác định schema migration/version strategy/lock order từ code thật.
- File≤300/component≤150 theo frontend standards; không tạo apps/tenant-web/src. Trước product code đọc AGENTS và guide Next trong apps/tenant-web/node_modules/next/dist/docs.

## Non-Functional Requirements

- Keyboard/audio/dialog/focus restore, labels/status có chữ; light/dark, widths320/768/1024.
- Queue20/max100, không tải mọi page tạo KPI; AI read không kéo Host payload.
- Một nguồn final EXAMINER trong human-required session; zero automatic score replay; zero AI overwrite sau finalize.
- Audit lưu actor, time, decision kind, AI snapshot, final score và request id; không log presigned URL/PII.
- Không chốt latency SLA khi chưa đo; giữ content/pagination bounds hiện hữu.

## Success Criteria

- [ ] Examiner assigned đọc AI reference qua API của mình; wrong role/tenant/assignment bị chặn.
- [ ] Dùng AI và Chấm lại đều cần explicit finalize; không có automatic accept.
- [ ] Chốt điểm bằng AI vẫn tạo EXAMINER decision; điểm khác giữ AI gốc và snapshot đã xem.
- [ ] AI missing/failure cho chấm tay; required media failure khóa chốt.
- [ ] AI version đổi trước finalize bị phát hiện; AI về muộn sau finalize không thay final.
- [ ] Host source-selection/teacherScore không thay điểm cuối trong MANUAL_EXAMINER.
- [ ] Publication thiếu1 quyết định Examiner bị chặn; đủ quyết định công bố đúng report EXAMINER.
- [ ] AI_ONLY giữ hành vi hiện hữu; published snapshots cũ không bị sửa.
- [ ] 0/100 valid, invalid inputs không POST; timeout/idempotency/conflict không tạo success giả.
- [ ] Sáu content kinds, locale, responsive và code placement được kiểm tra ở implementation.

## Out of Scope

Reopen quyết định đã chốt; hội đồng phân xử; nhiều Examiner trên một answer; rubric/feedback AI chưa có contract; mandatory correction comment; server draft/bulk accept; student identity/answer key; tự lấy trung bình AI-người; Examiner tự publish.

## Assumptions

User đã chốt mô hình quyền AI hỗ trợ/Examiner final/Host publish. Bố cục và contract đề xuất còn chờ duyệt. “Chấm lại” áp điểm AI trước finalize, không suy diễn quyền sửa điểm Examiner đã chốt. Cấu hình MANUAL_EXAMINER áp rõ theo session; không đổi mọi legacy session ngầm. Quyết định dừng test/quality của Proctor không tự áp vào Examiner.
