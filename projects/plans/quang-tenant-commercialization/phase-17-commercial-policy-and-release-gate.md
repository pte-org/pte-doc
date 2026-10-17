# Phase 17: Đóng chính sách thương mại & release gate

Owner: **Quang**
Status: **Planned**
Depends on: **Phases 14–16**
Maps to: [ADR-006](../../architecture/ADR-006-commercialization-and-exam-templates.md) §3, §7, §9

## Requirements

Một số behavior hiện đã có code/test nhưng chưa có quyết định business thống nhất: renewal có nối sau subscription đang active hay mỗi lần mua tính từ activation, tenant suspended có được login/refresh để xem report không, re-suspend có đổi deadline không, và license student-capacity/refund/chargeback xử lý thế nào. Không được đưa commercialization rollout vào production khi các behavior này chỉ tồn tại như assumption trong service hoặc test.

## Design Constraints

- Mọi decision phải có một canonical source trong ADR/plan và có acceptance test; không để code hiện tại tự trở thành business policy.
- Khuyến nghị giữ mô hình đã ghi trong master plan: mỗi purchase là một `Subscription` lane độc lập và `expiresAt = activationTime + durationDays`. Code hiện tại đang tìm `latestExpiry` cùng plan rồi nối duration; đó là discrepancy cần quyết định, không được âm thầm sửa.
- Suspension không tự gia hạn subscription theo ADR. Nếu deadline/rule re-suspend thay đổi, phải giữ nguyên nguyên tắc không tạo “free time” ngoài policy.
- Refund/chargeback, license revoke và capacity ledger phải có trạng thái/owner/audit rõ ràng. Nếu chưa làm trong release, phải ghi “unsupported” trong API/UI thay vì giả vờ đã xử lý.
- Release evidence phải phân biệt focused test, local/mock test, Postgres integration và full regression. Một test bị skip vì Docker không có không được ghi là passed.

## Steps

1. Lập decision table và chốt với owner Quang:

   | Policy | Khuyến nghị để review |
   |---|---|
   | Renewal expiry | Mỗi activation tính từ `startsAt`, không nối sau lane cũ; khớp ADR/multi-instance |
   | Suspended login/refresh | Cho phép đúng capability cần cho report/ongoing attempt, không mở lại command forward-moving |
   | Re-suspend | Idempotent no-op nếu không có policy đổi deadline; nếu cho đổi phải có impact preview mới và audit |
   | Student-capacity revoke | Không tự giảm quota trong release nếu ledger chưa có reversal invariant |
   | Refund/chargeback | Không hỗ trợ trong release hiện tại nếu chưa có payment/refund contract; trả lỗi có machine code rõ ràng |

2. Sau khi chốt, cập nhật ADR-006, master plan, phase 13 notes và API/UI copy để không còn câu mâu thuẫn. Mọi thay đổi expiry phải cập nhật test `SubscriptionActivationServiceTest` và contract của cả PayOS/license activation.

3. Implement đúng policy đã ký: expiry calculation, suspended auth matrix, re-suspend behavior, unsupported refund/revoke behavior và audit. Không mở thêm scope billing khác trong phase này.

4. Chạy release-gate checklist:

   - API focused business-rule suite và Postgres migration/concurrency suite;
   - tenant-web/vendor-web typecheck và route contract checks;
   - full app regression, ghi riêng baseline `ModuleStructureTest` violation nếu vẫn còn;
   - kiểm tra report quality/test evidence của Phase 14–16;
   - xác nhận không có generated artifact, secret hoặc migration chưa review trong commit groups.

5. Ghi handoff với trạng thái từng gate: `passed`, `skipped_by_user`, `blocked_by_environment` hoặc `failed`; owner Quang quyết định có rollout hay giữ plan ở `In progress`.

## Success Criteria

- Renewal behavior khớp một ADR duy nhất và có test cho activation mới, lane đang active, PayOS, license redeem và expiry.
- Suspended auth, re-suspend, refund/revoke đều có response contract và UI copy không gây hiểu sai.
- Mỗi skipped/failed release check có lý do, scope và người chịu trách nhiệm; không dùng focused pass để tuyên bố production-ready.
- Master plan chỉ chuyển trạng thái hoàn tất sau khi các decision gate và evidence được ghi nhận.

## Quality and Testing State

- Quality gate: **not evaluated**.
- Testing: **not started**. Đây là phase gate; không tạo report “passed” trước khi policy decision và Postgres-dependent checks có bằng chứng thật.

## Decision Gates

- Chọn `activationTime + durationDays` hay contiguous renewal làm contract chính thức.
- Chốt capability tối thiểu của suspended tenant khi login/refresh.
- Chốt refund/chargeback và capacity license revoke có nằm trong release này không.
