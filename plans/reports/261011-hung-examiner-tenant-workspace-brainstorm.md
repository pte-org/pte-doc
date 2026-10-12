# Brainstorm: Examiner — AI hỗ trợ, người chấm quyết định

**Date:** 2026-10-11
**Status:** V2 đề xuất; mô hình quyền đã chốt, bố cục/contract chờ duyệt. Chưa triển khai sản phẩm.

## User's Direction

“Examiner xem điểm chấm AI để chấm có hỗ trợ có thể chấm lại nếu AI sai sót và examiner vẫn là người chấm và quyết định điểm cuối cùng, host sẽ công bố kết quả sau đó”.

Thiết kế trước theo blind scoring và Host chọn nguồn đã bị người dùng yêu cầu sửa. Không giữ giả định Examiner không được xem AI hoặc MVP không cần API mới.

## Ideas Explored

1. Chấm độc lập, Host so sánh AI/người: khớp backend cũ nhưng không khớp lựa chọn mới của người dùng.
2. Examiner xem AI để chấm hỗ trợ, Host vẫn chọn nguồn: giải quyết UI nhưng không đảm bảo Examiner quyết định cuối cùng; loại.
3. Examiner duyệt AI hoặc chấm lại, chốt quyết định EXAMINER; Host công bố: hướng đã chốt về nghiệp vụ.
4. Trung bình/trọng số AI-người: không được yêu cầu, không có ScoreSource tương ứng; loại.
5. Reopen/sửa điểm Examiner đã chốt: khác việc sửa điểm AI trước khi chốt, giữ ngoài MVP.
6. Dashboard/rubric AI/feedback/transcript: không bịa dữ liệu từ rawScore; chỉ mở rộng khi có contract thật.

## Verified Baseline

- ExaminerWorkController cung cấp queue/detail/POST score theo EXAMINER + active tenant + assignment.
- ExaminerAnswerDetailResponse hiện chỉ prompt/response/myScore/submittedAt, không có AI reference.
- ExaminerScoringService.submitScore lưu điểm bất biến; không atomically chọn nguồn EXAMINER.
- HostScoreReviewView có aiRawScore/examinerScore/teacherScore/selectedScoreSource; không dùng nó làm Examiner DTO.
- ScoreSourceSelectionService hiện cho Host chọn AI/EXAMINER theo ALL/SECTION/TASK_TYPE; cần chặn chọn lại AI trong MANUAL_EXAMINER.
- ScoringAnswer.hasPublishableAiScore yêu cầu điểm thật, hợp lệ, provider category REAL; không đưa placeholder AI thành điểm tham khảo hợp lệ.
- GradingMarkingMode AI_ONLY/MANUAL_EXAMINER xác định completion; ScoreSource AI/EXAMINER xác định report input. Hai khái niệm không đồng nhất.
- GradingCompletionEvaluator đã kiểm tra đủ assignment/Examiner score trong MANUAL_EXAMINER, nhưng quyền chọn nguồn/report/publication phải thống nhất theo mô hình mới.
- Tenant web đã có workspace Examiner với real APIs; đặt file tại features/examiner và Next app routes hiện hữu.

## Recommended Design

Queue bài cần duyệt → trang duyệt có URL riêng. Ba vùng: navigator câu / đề và câu trả lời / AI tham khảo + điểm cuối cùng. Dùng điểm AI chỉ điền ô; Chấm lại cho nhập khác; Chốt điểm có xác nhận rồi khóa theo backend. Điểm bằng AI vẫn là quyết định EXAMINER, không source AI tự động. Host đọc và công bố sau khi đủ mọi quyết định.

Backend mở rộng projection AI, immutable decision metadata/snapshot/request id, atomic finalize + nguồn EXAMINER + audit, guards Host bulk selection và publication/report, cùng migration cho unpublished MANUAL_EXAMINER. AI_ONLY và published snapshots giữ nguyên.

## Open Questions

Không còn câu hỏi chặn draft sau lựa chọn nghiệp vụ của người dùng. Bố cục và contract V2 chờ duyệt. “Chấm lại” áp điểm AI trước finalize, chưa bao gồm sửa quyết định đã chốt.

Plan cần kiểm tra ownership/lock order/schema migrations/version serialization/tương thích request cũ bằng code thật. Không tự thêm rubric, comment bắt buộc, bulk accept hay feature flag.

## Risks

1. UI nói Examiner final nhưng Host API vẫn đổi nguồn hoặc report fallback AI; cần service/publication enforcement.
2. Audit lưu AI mới thay AI đã xem, hoặc retry đã commit bị conflict do version đổi; cần intent snapshot và idempotency trước optimistic version.
3. Migration làm thay kết quả đã publication hoặc chuyển legacy AI_ONLY ngầm; giới hạn backfill unpublished MANUAL_EXAMINER, unknown data chặn công bố.

## Independent Design Review

Lượt đọc builder độc lập yêu cầu làm rõ ba điểm: snapshot AI đã xem với MANUAL, thứ tự idempotency/version và hành vi migration legacy. Spec đã bổ sung reviewedAiVersion, version theo answer, tra committed request trước version, fail closed legacy MANUAL_EXAMINER và LEGACY_IMPORTED audit.

## Verification

Prototype dữ liệu mẫu, không gọi API hoặc chốt điểm thật. Kiểm tra Node xác nhận syntax/IDs và luồng dùng AI/chấm lại/chốt khóa/filter; đây là kiểm tra logic trên DOM giả lập, không thay kiểm tra trình duyệt/API. Chưa chạy application tests/build hay sửa product source.

## Handoff

- [Spec V2](../examiner-tenant-workspace/spec.md).
- Prototype: ../examiner-tenant-workspace/examiner-workspace.html.
- Sau duyệt thiết kế: ck:plan rồi ck:cook theo scope mới frontend + backend.
- Không tự tiếp tục task Proctor đã dừng hoặc áp lựa chọn bỏ test/quality cũ vào Examiner.
