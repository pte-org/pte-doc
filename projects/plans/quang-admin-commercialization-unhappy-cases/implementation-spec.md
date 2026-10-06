# Implementation spec — Admin commercialization unhappy cases

Ngày: 2026-10-05. Scope: lên plan, chưa cho phép code/commit/push/deploy. Spec này là đầu vào triển khai tương lai, không sửa kết quả khảo sát lịch sử trong [spec.md](spec.md) hoặc [unhappy-cases.md](unhappy-cases.md).

## Quyết định đã được user duyệt

| ID | Quyết định | Giới hạn |
|---|---|---|
| DEC-01 | Giữ guard Archive/entitlement-edit khi còn mã ISSUED lưu hành; ACTIVE family immutable. | Đã có code lifecycle; không làm immutable license snapshot/revision system, không mở Archive DRAFT. |
| DEC-02 | Chỉ issue mới EXAM_PACKAGE. | Capacity legacy giữ nguyên để kiểm kê/xử lý riêng; không tự revoke, đổi family, hoàn quota hoặc làm mất quyền redeem theo policy cũ. |
| DEC-03 | Email đợt này: thông báo đúng mức bằng chứng, phục hồi bằng reset/credential flow hiện có. | Không dựng durable email intent, invitation/reset-link mới, delivery dashboard hoặc resend plaintext password cũ. APP-07 chỉ xử lý một phần. |
| DEC-04 | Plan mới/chỉnh sửa dùng VND; EXAM duration1..3650 ngày. | Cap1..2000 giữ nguyên; capacity add-on Plan vẫn tồn tại, chỉ license issuance mới là EXAM-only. Không bulk rewrite legacy. |
| DEC-05 | UI cho revoke REDEEMED EXAM_PACKAGE. | Reason1..255 sau trim; xác nhận subscription/SCHEDULED impact, OPEN/CLOSED không bị hủy. Khi state/scope thay đổi phải preview/xác nhận lại. Không quota compensation cho capacity. |

Các câu hỏi policy chính đã được chốt qua hội thoại. TDD và test/quality consent cho cook của plan mới chưa được chốt; đề xuất bật cả hai cho mọi phase. Chấp thuận plan không phải chấp thuận production mutation.

## Scope challenge

- Exists: backend đã có review, redeem atomic claim, revoke, validation/error envelope, current auth refresh; lifecycle guard/soft Delete/pending Modal vừa được implement ở plan riêng.
- Minimum: sửa gaps/contract thật sự thiếu, viết regression cho invariant đã có; không rewrite billing hoặc xây45 patches độc lập.
- Complexity: Hard — nhiều module, bearer secrets, transaction/commit/races và API compatibility. Chia phase trong cùng phạm vi45 case đã được user yêu cầu; không kéo cả payment/tenant system vào task.
- Spec quality: PASS cho scope dưới đây. Những nhánh deferred có disposition explicit, không để unresolved policy trở thành expected ngầm.

## Stories và acceptance

### US-01 [P1] Review application atomic và có thể đối chiếu

Một application chỉ có một decision committed; approve/reject race >=10 lượt với transactions độc lập: một winner, loser409, tenant/host/login hash không mồ côi. POST-response mất sau commit: GET detail xác minh decision trước retry. GET404 khác lỗi tải403/503. Decision metadata/reason hiển thị theo quyền PLATFORM_ADMIN, không expose password.

### US-02 [P1] Catalog không mất thay đổi hoặc thay quyền lợi ngoài ý định

Plan update/transition gửi expectedVersion từ response mới; stale form409, không auto-overwrite, giữ input để đối chiếu. Chỉ thêm version ở Plan, không BaseEntity. Existing Plan lock/guard outstanding codes giữ nguyên. Form không silent clamp, decimal giữ string/BigDecimal; VND, lengths và duration/cap boundary test qua UI và HTTP.

### US-03 [P1] Issue/redeem/revoke không cấp hoặc thu hồi sai quyền lợi

Issue mới chỉ EXAM dưới cùng transaction eligibility+insert+idempotency. Một ý định/key+canonical payload retry sau mất response trả cùng publicId, khác payload409; không lưu raw code trong idempotency records/logs. Redeem vẫn single-use cùng activation transaction, rollback không cấp quyền nửa vời. Effective expiry dùng server time trước cron và tại boundary. Revoke theo preview/expected scope, atomic code/subscription/SCHEDULED persistence, OPEN/CLOSED giữ nguyên.

### US-04 [P2] Admin tìm được dữ liệu và biết kết quả bất định

License record101+ vẫn tra cứu bằng bounded pagination/filter; stable sort issuedAt/publicId. List mask token, secret lookup/reveal không nằm URL/log/query cache hoặc success banner dài hạn. Plan name/recipient được batch-enrich, không N+1 hoặc snapshot giả. Common loading/error/empty/stale và committed-but-refetch-failed được phân biệt; logout/user switch không nhận late write của phiên cũ.

### US-05 [P2] Email recovery trung thực, không mở auth workflow mới

Approval success không nói delivered/credentials sent khi chưa có bằng chứng. Dùng existing authorized host reset/credential flow: xác định đúng target tenant/user, manual confirm rotation, kiểm tra scope+audit; không auto-reset sau timeout và không tìm lại password cũ. Nếu flow hiện có thiếu khả năng target hoặc audit, sửa tối thiểu trong owning identity boundary hoặc ghi blocker trước wiring; không bỏ authorization để phục hồi. Durable delivery/retry/invitation được deferred, không claim APP-07 Passed toàn bộ.

### US-06 [P1] Báo cáo45 ID có coverage và execution đúng

Mỗi ID có primary phase, residual/deferred scope, tests, current evidence và result Not run/Passed/Failed/Blocked. Kết quả khảo sát/lifecycle cũ không tự trở thành pass của đợt này. Các nhánh deferred được ghi Partial/Deferred ở cột implementation disposition, không chế thêm Passed cho execution. Đợt lifecycle trước ghi11 baseline failures trên HEAD906345c; planning hiện đọc API f070e38/web eafe3c8, chưa rerun. Phase01 phải xác minh baseline mới; không sửa ngoài phạm vi hoặc coi scoped pass là release-ready.

## Non-goals

Không redesign/mockup/brand mới; không trash/restore, license snapshots, capacity ledger/reversal, durable email workflow/invitation, audit toàn payment, global pagination architecture, auth refresh rewrite, production action hoặc sửa11 baseline failures tự động. Organization type/reserved-code policy chưa có catalog authoritative thì chỉ enforce existing contract/schema lengths; không tự invent enum/reserved list. Application duplicate-tax submission policy không đổi thành globally unique pending nếu chưa có rule; approval-time uniqueness remains authoritative.

## Design constraints

Spring modular monolith/public facades, constructor DI, DomainException + existing ApiResponse mapping400 DTO/422 business/409 conflict/410 expired; code/messages in owning Constants. Không áp generic skill advice để thay cả exception/envelope architecture. JDK target21; test runtime21 phải được kiểm tra khi cook.

Reference writers cùng transaction/lock order; no billing import session internals. Prefer synchronous BEFORE_COMMIT/public-facade cancellation to preserve dependency direction, nhưng phải chứng minh commit/rollback và fix opposite session→subscription order ở changeSubscription; không gọi AFTER_COMMIT là atomic. Offset pagination là locate/access improvement, không hứa stable snapshot khi concurrent inserts.

Migration chọn version tiếp theo tại cook (V77 lifecycle phải được giữ); expand-first, clean + legacy rehearsals, no implicit bulk value changes. Missing expectedVersion/preview/key trên stale clients không cho phép bypass protections; rollout/compatibility phải được chốt contract trong phase01.

## Required evidence / exit

Unit và HTTP validation/auth; real isolated PostgreSQL migration/committed readback/races >=10 từng scenario; fault injection trước/sau commit; mocked browser states tách live authenticated E2E; no secrets in traces/logs/screenshots. Compile/typecheck/lint/build, quality receipt từng phase, final code-review và45-case ledger. Gate fail/skip phải ghi rõ, không waive full-suite hoặc phase để báo complete.
