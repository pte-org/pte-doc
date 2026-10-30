# Plan: hoàn thiện PTEPrep Practice và Gemini explanation

Owner: Ngô Đăng Quang. Ngày: 22 October 2026. Mode: `ck:plan --hard`. Status: **Ready for Phase 01 — đã review thiết kế; D01–D03/D05–D06 đã xác nhận**. Không có application code, test hay live Gemini call được thực hiện trong lượt lập kế hoạch.

Tên đề tài giữ nguyên: **PTEPrep: An AI-Powered PTE Practice Platform and Realistic Exam Simulator**.

## Mục tiêu và phạm vi

Hoàn thiện toàn bộ hành trình Student: đăng nhập/context → catalog đúng quyền → luyện task có nội dung/media thật → lưu/resume/nộp → kết quả khách quan → giải thích chuẩn và nhận xét Gemini theo rubric → review/progress. Đồng thời bổ sung nghiệp vụ academic để dữ liệu, rubric, references và quyền dùng câu hỏi thực sự sẵn sàng. Đây không phải kế hoạch chỉ thêm một nút AI vào màn hoàn tất.

Source baseline đã có lifecycle/session/media/auth, nhưng renderer allowlist mới có 9 mục; blanks, media projection, review/progress/Study-Pack và rubric chưa đủ. Tái sử dụng lifecycle và module facade hiện có, không dựng hệ thống session/song song. Báo cáo 3–6 là yêu cầu đích, không phải bằng chứng implementation hoàn tất.

Đây là work package tiếp nối phạm vi đã sửa trong Report 3–6 và gaps hiện tại của `quang-pte-practice-student-web`; không chạy lại các phase lịch sử hoặc coi plan cũ đã hoàn tất là bằng chứng hoàn thiện scope mới. Adaptive learning ở `quang-learning-quality-adaptive-practice/feedback-resolution.md` là đề xuất riêng, chưa được nhập vào scope này.

## Bằng chứng và ràng buộc đầu vào

- [Specification](spec.md): US-01..12, PR-01..15, acceptance và D01..08.
- [AI explanation contract](ai-explanation-contract.md) và [rubric/task matrix](rubric-and-task-matrix.md): **mandatory design references** cho các phase; chi tiết API, input artifacts, rubric và task applicability trong hai tài liệu này là một phần của plan.
- [Brainstorm](../../../plans/reports/261022-quang-pte-practice-completion-brainstorm.md).
- [Primary research](../../../plans/reports/261022-quang-pte-practice-completion-primary-research.md).
- [Alternative research](../../../plans/reports/261022-quang-pte-practice-completion-alternative-research.md).
- Source: `pte-practice/features/practice`, `features/progress`, `features/studyPack`; `pte-api/app/src/main/java/com/pte/{practice,itembank,identity,scoring}`; vendor academic/question-bank surfaces.

Trước code, đọc toàn bộ `docs/CODING_STANDARDS_API.md`, `docs/CODING_STANDARDS_WEB.md`; thêm `API_RESPONSE_SETUP.md`, `COMMON_EXCEPTION_SETUP.md`, `TEST_SCENARIOS_IAM.md` cho phần contract/auth. Chỉ đọc `CODING_STANDARDS_APP.md` và mở rộng scope `pte-app` nếu consumer audit chứng minh phải sửa Flutter. Không coi nghiên cứu hiện tại là thay thế reading gate.

## Các quyết định và khả năng bắt đầu

| Decision | Quyết định / policy | Gate công việc |
|---|---|---|
| D01 | Các dạng bài Academic đã có trong ngân hàng, đối chiếu canonical IDs | User confirmed 2026-10-22; không mở Core riêng. Task/timing/rubric/media readiness được kiểm trước release từng task. |
| D02 | Verified email và Student chọn context được phép | User confirmed 2026-10-22; membership/ownership mỗi tổ chức vẫn tách biệt, không auto-merge Student. |
| D03 | Study-Pack là nhóm luyện nhanh với filter thật | User confirmed 2026-10-22; curated ordered packs/progress riêng ngoài đợt này. |
| D04 | Hai flags độc lập practice/exam | Đã xác nhận; migration EXAM → practice=false/exam=true, PRACTICE → practice=true/exam=false. Không tự backfill cả hai true. |
| D05 | VI mặc định, cho chọn EN; pin language | User confirmed 2026-10-22; lời giải mỗi ngôn ngữ lưu riêng; UI locale switch không tự gọi Gemini. |
| D06 | Objective có numeric result; Writing/Speaking rubric feedback trước, điểm AI sau kiểm định | User confirmed 2026-10-22; numeric AI chưa đạt calibration không block qualitative release. |
| D07 | Gemini qua backend dùng secret đã có | Đã yêu cầu; chỉ xác nhận key nonempty, chưa chứng minh credential/model/quota chạy thật. |
| D08 | Feedback handler, quyền xem lịch sử, retention, data handling, budget | Cần product/academic/ops duyệt trước phase phụ thuộc; không biến quyền Host support thành Student feedback. |

Xem [bản ghi xác nhận](decisions.md). Có thể bắt đầu Phase 01 với năm quyết định đã chốt, không hỏi lại D01–D03/D05–D06. Content/rubric publication, quality, budget và live readiness vẫn là implementation gates đúng phase; approval sản phẩm không thay bằng chứng kiểm định. D08 tách nhỏ để policy nào ảnh hưởng phần nào được giải quyết tại phần đó; P2 feedback chưa chốt không block core P1.

## Kiến trúc đề xuất

`Published question revision + published rubric/reference → pinned safe/restricted snapshots → immutable submission → deterministic evaluation → unique explanation job/outbox → leased worker → Gemini → schema + evidence validation → one accepted immutable explanation → read-only review`.

“Đồng bộ” là cùng bản nộp và cùng bundle phiên bản đọc cùng explanation đã lưu; không gọi Gemini lại mỗi lần mở. Bundle gồm owner/context, canonical submission hash, question/rubric/reference/evaluator/prompt/schema/model-policy/language. Lưu requested model và actual modelVersion; model alias không bảo đảm kết quả lặp lại. Không hứa exactly-once external request/billing; database bảo đảm một canonical accepted result và fencing chặn worker cũ.

## Phases và dependencies

| Phase | Nội dung | Dependency | Stories |
|---|---|---|---|
| [01](phase-01-contracts-decisions-task-matrix.md) | Quyết định, task matrix, contract, IAM/context | Không | US-01,02,03,09 |
| [02](phase-02-channel-flags-academic-rubrics.md) | Hai flags, exam consumers, rubric/reference governance | 01; D01 cho release task | US-04,10 |
| [03](phase-03-delivery-renderers-session-media.md) | Delivery đủ kỹ năng, lifecycle/drafts/media | 01,02 contracts | US-02,03 |
| [04](phase-04-submissions-objective-results-evidence.md) | Immutable submit, evaluator, result và audio read facade | 02,03 | US-03,05,08 |
| [05](phase-05-gemini-rubric-explanation-contract.md) | Gemini independent config, prompt/schema/evidence | 02,04; D05/06/08 | US-04,06,09 |
| [06](phase-06-durable-jobs-recovery-budget.md) | Outbox, lease/fencing, retries, budget | 04,05 | US-06,07,09 |
| [07](phase-07-review-progress-study-pack-feedback.md) | Result/review, progress, Study-Pack, feedback | 03..06; D03/08 | US-07,08,11 |
| [08](phase-08-quality-corpus-security-release-evidence.md) | Academic corpus, security/races, synthetic live smoke | 01..07 | US-01..11 in scope |
| [09](phase-09-docs-runbook-coordinated-release.md) | Reports, runbook, migration/release staging | 08 và approvals | US-09,10 |

## Acceptance toàn đợt

1. Mọi task **được xác nhận in-scope** có content fixture, media, save/resume/submit/result/review đầy đủ; không dùng Unsupported screen để tuyên bố hoàn thiện.
2. Objective gold cases khớp policy đã duyệt; không lộ answer key/reference bị hạn chế trước nộp. Writing/Speaking hiển thị đúng evidence/limitations; Personal Introduction không có tổng điểm.
3. 20 lần GET/reopen cùng evaluation trả cùng ID/hash và 0 provider calls mới; 20 POST đồng thời với Idempotency-Key khác nhau tạo một logical job. Worker cũ không overwrite.
4. Crash/broker downtime không mất job và recovery trong 2 configured reconciliation cycles, không cần Host/Student mở lại. AI lỗi không làm mất bài nộp.
5. Quyền owner/context, current entitlement POST và historical GET rõ; không secret trong frontend/log; review recording không nới live upload permission.
6. Rubric/corpus đã Academic Manager duyệt; chất lượng AI có bằng chứng độc lập với JSON parsing và caching. Numeric score nếu chọn phải qua calibration riêng.
7. Flags được migrate an toàn cho exam/practice; snapshots cũ giữ nguyên; không lộ câu thi do chuyển pool tùy tiện.

## Design Constraints

- Module ownership: practice chỉ gọi public facades của identity/itembank/scoring/media; không import `scoring.internal`. Extract evaluator seam do scoring sở hữu, không tạo exam attempt giả.
- Published revisions bất biến; changes tạo version mới. Historical submissions luôn giữ bundle cũ và metadata; thay prompt/model không ghi đè history.
- Rule dữ liệu đã duyệt quyết định readiness; không fallback lấy câu EXAM khi practice thiếu. Hai flags cùng true chỉ sau academic release rõ và chấp nhận rủi ro Student đã thấy câu trước exam.
- Không open chatbot, training, adaptive planner, score PTE chính thức hay Pearson affiliation. Không đổi tên đề tài.
- Tách consistency of reads, model quality và numeric calibration thành ba yêu cầu kiểm định khác nhau.

## Quality and Testing State

- Plan review: đã qua independent red-team review và correction review, không còn BLOCK/HIGH/MEDIUM design findings. Xem [review/adjudication](../../../plans/reports/261022-quang-pte-practice-completion-plan-review.md). Quality của implementation vẫn **not evaluated**; `ck:quality` là lựa chọn pending theo phase khi cook.
- Testing: not started; không viết/chạy tests hay provider calls trong planning. Các mục test trong phase là đề xuất coverage, không phải kết quả đã đạt.
- TDD: **chưa được user chọn**. Khuyến nghị `--tdd` cho migrations/evaluator/idempotency/recovery; không tự thêm cờ.
- Khi implementation, `ck:cook` hỏi lựa chọn test/quality từng phase theo skill. Compile/build/check bắt buộc từ coding standards phải hoàn thành; không báo production-ready từ compile hoặc mocks.

## Rủi ro và release controls

| Rủi ro | Xử lý / bằng chứng cần có |
|---|---|
| Academic content không đủ | Content readiness gate từng task; không che bằng allowlist mở rộng. |
| Shared question làm mất tính mới của đề | Chỉ both flags sau approval/disclosure, kiểm tra mọi exam selector. |
| Provider trả giải thích sai nhưng schema hợp lệ | Corpus học thuật, semantic validation, contradiction review, revoke future generation theo version. |
| Audio không đủ đánh giá pronunciation/fluency | State limited/NA; audio assessor chỉ bật sau evidence/calibration. |
| Timeout gây thêm provider call | Reservation/budget, bound attempts, fencing, metrics; không hứa một lần tính phí. |
| Historical access/retention còn policy chi tiết | D02 đã chốt explicit context; D08 xử lý history/data handling, không tự merge Student giữa tổ chức. |
| Model alias thay đổi | Pin version nếu provider hỗ trợ, lưu actual version, evaluate lại khi drift. |

## Handoff

Đã có xác nhận D01–D03/D05–D06 và review thiết kế. Có thể dùng lệnh sau để bắt đầu Phase 01; D08 được đóng theo từng phase trước enable chức năng phụ thuộc, không cần hỏi lại các quyết định đã có:

```text
/ck:cook --hard pte-doc/projects/plans/quang-pte-practice-completion/plan.md
```

Nếu user đồng ý TDD thì dùng riêng lựa chọn sau; hiện chưa được chọn:

```text
/ck:cook --hard --tdd pte-doc/projects/plans/quang-pte-practice-completion/plan.md
```

Evidence của implementation lưu tại `pte-doc/plans/reports/YYMMDD-quang-pte-practice-<topic>-<type>.md`; assets dưới `plans/reports/assets/<report-name>/`. Không ghi token, raw answer/audio nhạy cảm hoặc giá trị `.env` vào evidence.
