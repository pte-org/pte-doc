# Phase 05 — Readiness, report aggregation và publish snapshot

**Plan:** [plan.md](plan.md) · **Spec:** [spec.md](spec.md)  
**Covers:** P1 Host approval và Student report; FR-12, FR-15–18.  
**Depends on:** Phase 01–04.  
**Outcome:** Host chỉ publish cohort có đủ score hợp lệ; report lấy selected scores + pinned weights, và Student thấy snapshot ổn định sau publication.

## Mục tiêu

Khép vòng từ Host approval tới Student report. Reporting không còn aggregate `rawScore` trực tiếp cho answer AI-eligible; objective scoring hiện có giữ nguyên. Publish không tạo report một phần và report đã hiển thị không thay đổi do scoring/source update sau này.

## Backend work

1. **Readiness/preflight contract**
   - Reporting gọi scoring public facade cho tập submitted attempts thuộc session/cohort và nhận selected score + publishability, không đọc scoring repositories.
   - AI-eligible answer cần selected source và score tồn tại/complete/range-valid/provider-valid; Examiner source cần submitted score hợp lệ.
   - Trả structured blocking summary: attempt/answer-safe reference, section/task type, reason (no source, missing score, stub/nonpublishable); không publish bất kỳ report nào khi có blocker.
   - Objective answers vẫn lấy objective score theo cách cũ; UNSCORED không đóng góp.

2. **Selected-source aggregation**
   - Điều chỉnh `ScoreAggregationService` để resolve score per answer từ selected source trước khi group/average theo task type.
   - Áp dụng template weights/revision đã pin; không dùng active/current template mới hơn.
   - Giữ nguyên scale/rounding và objective semantics hiện hành; thêm test golden values cho mixed objective + AI-selected.
   - Không để report query re-run aggregation từ mutable live scores sau khi đã published.

3. **Approval và publication state machine**
   - Host command preflight → lấy version/lock → xác nhận toàn cohort vẫn đủ score/source → tạo snapshot → publish visibility barrier.
   - Audit approver, timestamp, cohort/version, score source decisions và kết quả publish; đảm bảo thao tác idempotent khi retry.
   - Concurrent score submit/source change không được chen vào giữa preflight và snapshot; dùng session/cohort lock hoặc compare-and-set versions, revalidate ngay trước commit.
   - Chặn source/score mutations sau khi publish cho các answers được snapshot; không làm report Student đổi dù có lỗi mutation ngoài luồng.
   - Nếu batch snapshot staging nhiều transaction, trạng thái session phải remain non-visible cho tới khi mọi report snapshot hoàn tất; retry tiếp tục hoặc rollback staging. Không expose partial reports.

4. **Stable report snapshot**
   - Lưu dữ liệu report cần cho Student một cách bất biến: overall/section scores, template revision, cohort/publication version và selected per-answer inputs hoặc snapshot đủ tái tạo/audit.
   - Chốt với `AttemptReport`/report read model hiện hành cách thêm snapshot không phá API tương thích; report reads của Student dùng snapshot đã publish, không gọi live aggregation.
   - Ngăn duplicate report/publication races bằng unique keys và state transition có transaction semantics.

5. **Host/Student UI integration**
   - Host review panel nhận readiness summary, nút approve/publish chỉ bật khi đủ điều kiện, confirmation nêu cohort count và version/cutoff.
   - Publish failure trả actionable missing answer summary; không báo thành công giả hoặc publish một phần.
   - Student report visibility tiếp tục ẩn trước Host publish; sau publish hiển thị snapshot. Không expose source/provenance nội bộ cho Student trừ khi API đã có yêu cầu rõ.

## Publication cutoff — điểm cần quyết định trước khi triển khai

Spec không bắt buộc exam/session đóng trước khi publish, nhưng session có thể nhận attempt nộp sau preflight. Plan không tự thêm `CLOSED` làm điều kiện. Trước P05, Host/Product cần chọn một contract:

- **Phương án A — publish sau khi đóng session:** cohort ổn định; readiness bao phủ mọi submitted attempt của session; đơn giản nhất để giữ nghĩa “toàn session”.
- **Phương án B — snapshot cohort theo cutoff:** Host publish mọi attempt đã submit tại cutoff; attempt nộp sau không có report cho tới một đợt approval/publish tiếp theo. Cần định nghĩa rõ đợt bổ sung không bị xem là sửa/re-publish score đã công bố.

Không triển khai một trong hai theo suy đoán. Chọn phương án ảnh hưởng acceptance, state machine, Student visibility và test publish atomicity.

## Kiểm chứng và acceptance

- Readiness tests cho thiếu selected source, missing AI/Examiner score, stub, invalid score, zero hợp lệ, và đủ dữ liệu.
- Publish bị reject toàn bộ khi có blocker; không có `AttemptReport` Student-visible nào mới/partial.
- Aggregation golden tests: AI selected, Examiner selected, mixed source trong cùng task type, pinned template weights, objective unchanged, UNSCORED excluded.
- Snapshot stability: sau publish cố thay raw AI score, Examiner score hoặc selected source thì Student API vẫn trả snapshot cũ; mutation bị reject hoặc không ảnh hưởng snapshot.
- Transaction/race tests: Host publish song song với examiner submit/source apply hoặc attempt submission; chỉ một consistent publication wins, retry idempotent.
- Student report hidden pre-publish, visible post-publish; session multi-attempt publish có visibility barrier; host audit ghi actor/time/cohort/count.
- E2E P1: host assignment → examiner grading → source selection → readiness → approval/publish → student report.

**Acceptance:** report chỉ publish khi toàn cohort theo cutoff có selected publishable score cho mỗi AI-eligible answer; aggregate đúng template đã pin và Student-visible report không drift.

## Design Constraints

- Không yêu cầu session `CLOSED` nếu chưa có quyết định product; cutoff semantics phải được xác nhận trước phase.
- Readiness là backend invariant, không phải FE-only disable state.
- Publish không partial; snapshot visibility chỉ bật sau khi toàn cohort snapshot thành công.
- Report dùng selected score per answer và pinned template weights; objective/UNSCORED semantics không đổi.
- Student read path đọc immutable snapshot; report không được tính lại từ mutable scores.
- Lock/version coordination giữa source selection, Examiner submission và publication phải được kiểm thử concurrent.

## Quality and Testing State

- quality: not evaluated
- testing: not started
- Kế hoạch: aggregation/report unit tests; DB migration + transaction/concurrency integration; Host/Student route tests; full end-to-end workflow.
