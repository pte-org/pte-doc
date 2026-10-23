# Specification: hoàn thiện PTEPrep Practice và Gemini explanation

Date: 2026-10-22
Owner: Ngô Đăng Quang
Status: Ready for Phase 01 — D01–D03/D05–D06 được user xác nhận ngày 2026-10-22; policy/evidence gates còn lại áp dụng đúng phase.
Registered title: **PTEPrep: An AI-Powered PTE Practice Platform and Realistic Exam Simulator**.
Scope: `pte-practice`, `pte-api`, `pte-web` academic/vendor surfaces và `pte-doc`; tương thích `pte-app` là ràng buộc, chỉ sửa client khi contract thực sự bị ảnh hưởng và thêm reading gate tương ứng.

## Problem Statement

Ứng dụng đã có auth/session/media/progress nền nhưng thiếu delivery đủ bốn kỹ năng, result/review, rubric học thuật và giải thích AI có thể kiểm tra, lưu và đọc lại nhất quán. Hoàn thiện theo Report 3–6; không dùng kết quả của plan cũ làm bằng chứng hiện trạng đầy đủ.

## User Stories

| ID | Priority | Nhu cầu | Acceptance |
|---|---|---|---|
| US-01 | P1 | Student đăng nhập và chọn đúng context | OTP lỗi/expired/reused/throttled không cấp session sai; context ngoài membership bị từ chối; không leak tổ chức qua email challenge |
| US-02 | P1 | Student luyện các task thuộc catalog được xác nhận | Mỗi task có row delivery/media/answer/evaluator/AI rõ; mọi task in-scope đạt E2E hoặc release bị block, không gọi unavailable là hoàn thiện |
| US-03 | P1 | Student lưu, resume và nộp không mất dữ liệu | Text/selection/confidence/recording đồng bộ; retry không trùng bài; xung đột version rõ; namespace local theo account/context |
| US-04 | P1 | Academic Staff/Manager quản lý rubric/reference | Draft/submit/review/publish có quyền và audit; published immutable; staff không tự publish; pin version trên session |
| US-05 | P1 | Student nhận kết quả khách quan đúng | Server evaluator dùng key/policy đã pin; Gemini không thay correctness; không leak keys trước submit |
| US-06 | P1 | Student nhận giải thích Gemini nhất quán | Cùng evaluation identity trả cùng explanation ID/content; GET/reopen không gọi model; output có rubric evidence và provenance; không đọc chéo Student/context |
| US-07 | P1 | Student dùng được khi AI lỗi | Submitted answer vẫn đọc được; pending/failure/retry/unsupported/limited phân biệt; recovery tự chạy sau crash, không đợi Host |
| US-08 | P1 | Student xem kết quả và Progress thật | Resume/review link, cursor pagination, không hiển thị điểm giả hoặc biến confidence thành performance; đọc lịch sử sau mất entitlement theo policy |
| US-09 | P1 | Platform kiểm soát chất lượng/chi phí | Rubric corpus có review, model/prompt eval, budget và bounded retries; worker lease chống ghi đè kết quả; không key ở browser/log |
| US-10 | P1 | Hai channel lấy đúng câu hỏi | Độc lập flags theo D04, preserve phạm vi dữ liệu cũ khi backfill, không fallback, không thay snapshot đang dùng |
| US-11 | P2 | Student báo vấn đề giải thích/nội dung | Đề xuất workflow category/status/handler rõ; chỉ triển khai sau chốt policy, không giả định Host support là Student feedback |
| US-12 | P3 | Student được tutor chat/adaptive plan | Ngoài đợt này; không cần cho core completion |

## Functional Requirements

1. PR-01: giữ auth/entitlement canonical và hiện rõ unavailable/locked/context selection; không unlock bằng client.
2. PR-02: implement revision-level independent channel eligibility, approval/readiness filters và selection diversity trong ngân hàng đủ nội dung; lưu actual selected revisions. Không hứa no-repeat vĩnh viễn.
3. PR-03: safe content projection đủ image/audio/passage/options/blanks/tokens/timing; restricted evaluation snapshot chứa answer keys/rubric/reference không trả trước submit.
4. PR-04: session/item state machine có draft/save/submit/skip/resume/deadline/discard, media ownership, stale version và idempotency; answer đã nộp bất biến.
5. PR-05: rubric revision có task compatibility, descriptor levels, applicability, evidence, invalid/zero/NA policy, examples, reference provenance và approval history. Weight/profile không thay thế descriptor.
6. PR-06: objective evaluator canonical cho từng family; xử lý multiple choice penalties/partial credit, blank normalization, reorder policy theo cấu hình đã duyệt, không tự invent scoring.
7. PR-07: submit lưu evaluation identity cùng evidence snapshot; request explanation có budget/current entitlement. Default đề xuất: tạo readiness/evaluation khi submit, gọi Gemini theo yêu cầu Student để tiết kiệm; auto-generation chỉ khi policy được bật.
8. PR-08: identity gồm owner/context + submission hash/revision + question/rubric/reference/evaluator/prompt/schema/model-policy/language + derived transcript/assessor artifact revisions/hashes. Unique index ngoài Idempotency-Key. Default request resolve bản đã có trước active policy mới; re-transcription/regeneration/new-language là explicit versioned action. Không chia sẻ personalized output giữa Students.
9. PR-09: Gemini qua backend public module boundary; config riêng cho practice, dùng secret env hiện có qua mapping phù hợp, không yêu cầu đổi exam scoring provider.
10. PR-10: durable job/outbox, leased dispatch, fencing token, bounded retry và scheduled reconciliation; một kết quả canonical được chấp nhận, không hứa exactly-once provider billing.
11. PR-11: schema + semantic/evidence validation trước available; nguồn/criterion IDs phải có thật; input không thể sửa instruction/rubric. AI chỉ trả teaching feedback, không có tool access.
12. PR-12: rubric criteria feedback cho Writing; Speaking chỉ đánh giá điều có bằng chứng audio/transcript; thiếu assessor thì partial/limited, không fabricated pronunciation/fluency. Personal Introduction unscored.
13. PR-13: GET explanation/result là read-only; thất bại AI không rollback submission; explicit versioned regeneration có quyền/lý do, giữ bản cũ.
14. PR-14: UI hiển thị answer, verified result/reference, rubric feedback, AI label/state/evidence/limitations, next actions; poll bounded và tiếp tục khi focus; không expose nguyên internal prompt.
15. PR-15: history/progress tách submitted/activity/confidence/objective accuracy/rubric level/AI availability, hỗ trợ pagination và review media đã nộp.

## Non-Functional Requirements và success criteria

Đây là tiêu chí acceptance đề xuất cho implementation, chưa là số đo production hay cam kết SRS.

- 100% task được xác nhận in-scope có delivery→answer→review case và content fixture hợp lệ; task thiếu content hoặc media là release blocker của task đó.
- 100% objective gold cases khớp expected evaluator; 0 answer-key leaks trong pre-submit API/UI fixtures.
- 20 GET/reopen liên tiếp cùng evaluation ID trả cùng stored content/hash và 0 provider calls mới.
- 20 concurrent identical POST requests dù dùng header keys khác nhau tạo 1 logical job; stale worker không overwrite accepted result.
- Hai first POST đồng thời qua thời điểm nâng policy vẫn chỉ có 1 default resolver slot/request/reservation/outbox; uniqueness slot không phụ thuộc model/prompt hiện hành.
- 100% tests cross-owner/cross-context, draft/rejected rubric, no evidence pronunciation, prompt-injection instruction, invalid criterion/evidence bị chặn hoặc hiển thị đúng limited state.
- Corpus tối thiểu đề xuất 8 bài chuẩn / scored task, phân bố tốt/trung bình/yếu/empty/invalid/edge; học thuật duyệt labels/evidence; 3 independent calls cho subset để đo variability. Không coi việc read cached result là kiểm định model.
- Release explanation quality: 0 critical factual/answer contradiction, 100% emitted evidence references hợp lệ; ngưỡng pedagogical usefulness do Academic Manager chốt trước evaluation gate.
- Timeouts/retries/concurrency/daily budget là config có giá trị cụ thể khi Phase 01 hoàn tất; tham khảo 45s/call, 120s/job, tối đa 3 external attempts gồm first call. Kiểm tra theo model/audio workload và quota thực trước bật; không lấy mặc định thành SLA.
- Recovery experiment: DB commit rồi Rabbit down, worker crash và late response đều hồi phục bằng scheduler trong 2 reconciliation cycles được cấu hình mà không cần Student/Host revisit.

## Out of Scope

Official Pearson/PTE score equivalence/affiliation; training AI; open chatbot; adaptive/IRT/diagnostic planner; LMS; Student checkout; curated ordered pack và completion riêng theo pack (D03 đã chọn nhóm luyện nhanh); WRITE_EMAIL/video khi chưa có canonical contract. Production write/deploy không được thực hiện trong lượt lên plan.

## Decision register và assumptions

| ID | Quyết định / policy | Tình trạng và phần phụ thuộc |
|---|---|---|
| D01 | Dùng các dạng bài Academic đã có trong ngân hàng, giữ canonical task IDs; đối chiếu inventory/registry | User confirmed 2026-10-22; không mở catalog Core riêng; readiness/timing/rubric từng task vẫn cần thực hiện |
| D02 | Verified email + explicit authorized org context, không auto-merge membership | User confirmed 2026-10-22; mọi phiên/dữ liệu giữ ownership trong context đã chọn |
| D03 | Study-Pack là nhóm luyện nhanh có filter | User confirmed 2026-10-22; không triển khai curated ordered pack/completion riêng |
| D04 | Hai independent usage flags | Đã user xác nhận trong report scope; migration/default và reuse disclosure là thiết kế phải ghi rõ |
| D05 | VI explanation default + EN option, language pin trong identity | User confirmed 2026-10-22; variants VI/EN lưu riêng, đổi UI locale không tự regenerate |
| D06 | Objective numeric; Writing/Speaking rubric feedback trước, numeric AI sau calibration | User confirmed 2026-10-22; qualitative release không bị block bởi numeric AI chưa kiểm định |
| D07 | Gemini provider | User yêu cầu; env key presence xác nhận, validity/quota/model chưa live verify |
| D08 | Feedback reporting handler, retention/data handling, generation budget | Product/academic/ops closure trước phase phụ thuộc; draft concrete policy, không assume approvals |

Xem [bản ghi xác nhận](decisions.md). D01–D03/D05–D06 đã đóng theo câu trả lời async, không hỏi lại. Có thể bắt đầu Phase 01; D08 cần được tách/chốt theo phase trước bật policy phụ thuộc. Academic content approval, chất lượng model và implementation evidence chưa được xác nhận chỉ bằng việc chốt sản phẩm.

## Traceability và evidence

- Report 3: FR-PRACTICE-001..009; FR-CONTENT-006; FR-ACADEMIC-001..002; BR-PRACTICE-001..007; NFR-AI-001..002.
- Report 4: §§2.8, 3.10; proposed practice/evidence/AI entities không phải proof code đã có.
- [Brainstorm](../../../plans/reports/261022-quang-pte-practice-completion-brainstorm.md).
- [Primary research](../../../plans/reports/261022-quang-pte-practice-completion-primary-research.md).
- [Alternative research](../../../plans/reports/261022-quang-pte-practice-completion-alternative-research.md).

Plan/spec chỉ là tài liệu đề xuất. Không gọi Gemini live, không thực thi tests hoặc sửa app trong lượt này.
