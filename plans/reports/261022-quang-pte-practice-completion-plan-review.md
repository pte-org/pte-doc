# Review kế hoạch hoàn thiện PTEPrep Practice

Date: 2026-10-22
Target: [plan.md](../../projects/plans/quang-pte-practice-completion/plan.md), spec, 9 phase files và 2 thiết kế bổ sung.
Method: ck:plan hard research/planner + independent red-team document review; source audit và static document checks.

## Verdict

Không còn BLOCK/HIGH/MEDIUM design findings sau correction review. Kế hoạch vẫn **Draft** vì D01–D03/D05–D06/D08 chưa được xác nhận; review kiến trúc không thay quyết định của người dùng hoặc phê duyệt học thuật. Công việc độc lập có thể chuẩn bị theo gate của Phase 01; chưa tuyên bố sẵn sàng cook toàn bộ.

## Findings và adjudication

| ID | Severity | Finding | Resolution |
|---|---|---|---|
| R01 | MEDIUM | Audio giống nhau nhưng ASR/assessor chạy lại có thể làm đổi input mà job vẫn gọi là same evaluation | ACCEPTED: pin derived artifact revisions/hashes, assessor provider/config/model/policy; retry không re-ASR âm thầm; WAITING_EVIDENCE bounded và explicit new evidence lineage |
| R02 | MEDIUM | Active prompt/model đổi có thể làm POST mặc định tạo giải thích mới dù bài cũ không đổi | ACCEPTED: freeze policy tại first accepted request, default resolve stored slot, explicit new language/regeneration có sequence và audit |
| R03 | MEDIUM | Objective evaluation identity và explanation policy fingerprint dễ bị lẫn | ACCEPTED: Phase 04 tách submission identity, deterministic evaluation identity và per-language explanation slot; đổi prompt không tự rescore objective |
| R04 | MEDIUM | Phase 06 dùng PROCESSING/FAILED_FINAL và LIMITED như job states khác contract | ACCEPTED: normative persisted states WAITING_EVIDENCE/QUEUED/RUNNING/RETRY_WAIT/AVAILABLE/FAILED/CANCELLED; readiness, coverage, failure category/canRetry riêng; Phase 07 cùng vocabulary |
| R05 | MEDIUM | Lookup-before-policy chưa đủ chống hai first POST đồng thời khi policy activation | ACCEPTED: DB-unique resolver slot owner/context/submission/language/generation sequence, atomic winner freeze + reservation + outbox; loser nhận canonical request; thêm policy-switch concurrency acceptance |

Final reviewer đã đọc lại các correction của R04/R05 và xác nhận đóng. Các vấn đề R01–R03 đã được kiểm trong full phase review. Không có finding bị bác bỏ hoặc để unresolved dưới tên khác.

## Những điểm nguồn đã được đưa thành ràng buộc

- Current EXAM/PRACTICE enum pool không tương đương hai flags D04; additive migration và exam consumer audit bắt buộc.
- Chỉ 9 renderer nằm trong runnable allowlist hiện tại; 23 canonical task IDs là inventory, applicability phải chốt D01.
- Snapshot cũ thiếu grading/rubric evidence không được chấm bằng current keys giả như pinned history.
- Broken academic reference trả content issue/NOT_ASSESSABLE; không gán lỗi nguồn thành điểm 0 của Student.
- Gemini credential đã có ở env nhưng bean hiện gắn Azure/exam; practice provider phải có public module seam và config độc lập.
- Post-submit audio evidence reads phải khác live upload permission IN_PROGRESS/PENDING.
- Existing Host-triggered scoring recovery không đủ cho practice; plan dùng durable jobs/outbox/reconciler/fencing.
- Stored repeated reads, schema-valid output và model quality/calibration là ba phép kiểm khác nhau.

## Phạm vi kiểm tra

Đối chiếu Report 3 practice/content/academic requirements; source backend/frontend; role/context/ownership; objective scoring; rubric/revision governance; response and media snapshots; provider configuration; async recovery; budget; UI review/progress; task coverage; release boundaries.

Static document validation: đủ 13 Markdown trong plan bundle (plan + spec + 9 phases + 2 supplements), UTF-8 không replacement characters, balanced code fences và local Markdown links tồn tại. Tất cả 9 phases có `Design Constraints` và `Quality and Testing State`. Research/brainstorm/review reports ở đúng `pte-doc/plans/reports/`.

Không thực thi application tests, builds, database migrations, browser checks hoặc live Gemini calls. Không xác minh key validity/quota/model availability bằng việc chỉ kiểm nonempty status. Không sửa application repositories; outputs là tài liệu mới trong pte-doc. Chưa commit/push/deploy trong lượt plan.

## Handoff

Subsequent user confirmation, 2026-10-22: D01–D03/D05–D06 are now resolved in [decisions.md](../../projects/plans/quang-pte-practice-completion/decisions.md), spec, plan and affected reports. The Draft verdict above records the review before those answers. Current readiness is Ready for Phase 01; D08 policy and academic/runtime evidence remain phase-specific gates. No numeric AI score is required for the initial qualitative-feedback release. This confirmation does not mark any product test or provider call as executed.

Decision-propagation review: no BLOCK/HIGH/MEDIUM findings. The LOW stale “D03 pending” wording in Phase 07 was accepted and corrected to the confirmed quick-group scope. Follow-up static validation checked 38 Markdown files, including the 14-file plan bundle: UTF-8, balanced fences, existing local links, all 9 required phase sections and contiguous change-table rows passed. DOCX exports were not regenerated for this decision follow-up; their README identifies the boundary.

Ghi câu trả lời ngôn ngữ, numeric AI feedback và D01–D03 vào decision register. D08 tách thành budget, history/retention/data handling và Student feedback ownership trước phase phụ thuộc. Các giá trị đề xuất chưa là phê duyệt sản phẩm. Khi cook, lựa chọn TDD/tests/quality phải theo flags hoặc câu trả lời thực tế; không suy từ plan này rằng checks đã chạy hay AI đã được kiểm định.
