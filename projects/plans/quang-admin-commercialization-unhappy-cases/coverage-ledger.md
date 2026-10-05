# Coverage ledger — 45 unhappy cases

Planning ledger, 2026-10-05. Mỗi ID xuất hiện một lần, primary owner không có nghĩa chỉ một phase có dependency/tests. Phase01 đóng baseline/contracts cho tất cả, phase07 đối chiếu toàn bộ. Existing lifecycle evidence: [prior test report](../quang-archive-lifecycle-cleanup/test-report.md), chỉ là evidence đợt trước; không tự gán Passed cho đợt mới.

Implementation disposition (Residual/Inherited/Partial/Deferred) khác execution (Not run/Passed/Failed/Blocked). Không claim45/45 implemented nếuAPP-07 delivery hoặccapacity reversal được deferred. Không xóa IDs hoặc thay expected snapshot cũ mà không ghi approved guard policy.

| ID | Primary phase | Implementation disposition | Residual scope / accepted expectation | New execution |
|---|---|---|---|---|
| APP-01 | phase02 | Residual implementation + verification | Detail GET độc lập; loading/error/404/retry. | Not run |
| APP-02 | phase02 | Residual implementation + verification | List query states, cached-stale và statistics không giả0. | Not run |
| APP-03 | phase02 | Residual implementation + verification | Lock application; approve/reject một winner và rollback tenant/host. | Not run |
| APP-04 | phase02 | Residual implementation + verification | Trim reason, boundary500/501 và Unicode. | Not run |
| APP-05 | phase02 | Residual implementation + verification | 409 refetch decision;404 not found, không tiếp tục review. | Not run |
| APP-06 | phase02 | Residual implementation + verification | Approval-time name/code/tax collision mapping/rollback; không thêm pending-tax policy. | Not run |
| APP-07 | phase02 | Partial; deferred subcase explicit | Truthful approval/email wording + existing reset; durable delivery/retry deferred. | Not run |
| APP-08 | phase02 | Residual implementation + verification | Timeout sau commit -> GET đối chiếu; không approve lại. | Not run |
| APP-09 | phase02 | Partial; deferred subcase explicit | Schema length validation; orgType/reserved-code semantics mới deferred. | Not run |
| APP-10 | phase02 | Residual implementation + verification | Reset error theo record/action và disable chéo pending. | Not run |
| APP-11 | phase02 | Residual implementation + verification | Render existing reviewer/time/reason theo quyền. | Not run |
| APP-12 | phase02 | Residual implementation + verification | Fault config/host creation rollback mọi write. | Not run |
| PLN-01 | phase03 | Residual implementation + verification | Decimal/required/family validation UI + HTTP400/422 giữ contract. | Not run |
| PLN-02 | phase03 | Residual implementation + verification | Name/description lengths và input giữ khi error. | Not run |
| PLN-03 | phase03 | Residual implementation + verification | Required/min/step integer, bỏ payload family đối lập. | Not run |
| PLN-04 | phase03 | Residual implementation + verification | Bỏ silent clamp, raw numeric string + range lỗi explicit. | Not run |
| PLN-05 | phase03 | Residual implementation + verification | New/edited VND; legacy inventory, không bulk convert. | Not run |
| PLN-06 | phase03 | Residual implementation + verification | New/edited duration1..3650; expiry persistence safety. | Not run |
| PLN-07 | phase03 | Partly inherited; remaining work explicit | Reuse lifecycle narrowing/pending; versioned stale transition regression. | Not run |
| PLN-08 | phase03 | Residual implementation + verification | ExpectedVersion trên update/transition chống stale overwrite; lock giữ nguyên. | Not run |
| PLN-09 | phase07 | Inherited lifecycle protection; rerun, không làm lại | Guard lưu hành đã implement; rerun archive/subscription/race evidence, không snapshot. | Not run |
| PLN-10 | phase07 | Inherited lifecycle protection; rerun, không làm lại | ACTIVE family immutable/outstanding entitlement guard đã implement; regression. | Not run |
| PLN-11 | phase03 | Partly inherited; remaining work explicit | Pending guard đã implement; còn dirty/navigation/late-operation regression. | Not run |
| PLN-12 | phase03 | Partly inherited; remaining work explicit | Catch/reset đã implement một phần; còn decimal formatter + fresh error/browser tests. | Not run |
| LIC-01 | phase06 | Residual implementation + verification | Plan query loading/error/empty và retry độc lập với code list. | Not run |
| LIC-02 | phase04 | Residual implementation + verification | Recheck EXAM-only dưới lock insert; reuse issue/archive protection. | Not run |
| LIC-03 | phase04 | Residual implementation + verification | UTC Instant server-time effective expiry; UIdatetime timezone explicit. | Not run |
| LIC-04 | phase04 | Residual implementation + verification | Redeem single-use đã có; PostgreSQL races/rollback/linkage tests trước fix. | Not run |
| LIC-05 | phase05 | Residual implementation + verification | Reason+preview và action REDEEMED EXAM. | Not run |
| LIC-06 | phase07 | Inherited guard; legacy edge verification | Giữ guard đã duyệt; inconsistent legacy archived/code fixture controlled error, không redeem snapshots. | Not run |
| LIC-07 | phase07 | Inherited guard; legacy edge verification | Giữ family/outstanding guard; không đổi entitlement mã cũ, không snapshot. | Not run |
| LIC-08 | phase05 | Residual implementation + verification | Preview expectedState/subscription/ackscope; redeem/revoke/cron races. | Not run |
| LIC-09 | phase05 | Residual implementation + verification | Code/subscription/SCHEDULED atomic commit; lockorder open/schedule/change safety. | Not run |
| LIC-10 | phase06 | Residual implementation + verification | Bounded server paging/filter và lookup mã101+. | Not run |
| LIC-11 | phase04 | Partial; new issue protection, legacy reversal deferred | Issue mới EXAM-only; legacycapacity inventory. Quota reversal deferred. | Not run |
| LIC-12 | phase04 | Residual implementation + verification | Durable issuance idempotency cùng insert; lost-response recovery. | Not run |
| LIC-13 | phase05 | Residual implementation + verification | Boundary reason/token/errors/status và operation resets. | Not run |
| LIC-14 | phase04 | Residual implementation + verification | Effective server expiry trước/sau cron; REDEEMED không tựexpire. | Not run |
| LIC-15 | phase06 | Residual implementation + verification | Masked list, reveal/lookup qua quyền, plan/recipient display, không secretURLs/log/cache. | Not run |
| COM-01 | phase06 | Residual implementation + verification | Real auth role/scoping403/401 không empty; menu không làsecurity. | Not run |
| COM-02 | phase06 | Residual implementation + verification | Reuse refresh/replay; logout/session-generationlate result isolation. | Not run |
| COM-03 | phase06 | Residual implementation + verification | Error mapping/catch/reset cho3views, không raw stack/SQL. | Not run |
| COM-04 | phase06 | Residual implementation + verification | Commit success != refetchfailed; stale banner/capability refetch. | Not run |
| COM-05 | phase06 | Residual implementation + verification | Operation uncertain/pending/dirty/navigation/session guards. | Not run |
| COM-06 | phase06 | Residual implementation + verification | License paging >100; Applications/Plans list scale fixtures, không inventSLO/paginationglobal. | Not run |

## Deferred backlog có chủ đích

- APP-07: durable onboarding delivery intent/retry/delivery evidence và invitation/reset-link mới. Đợt này chỉtruthful wording+manualexistingreset; SMTP/broker fault thể hiện approved/unknown delivery, không guarantee tựphục hồi.
- LIC-11: redeemed capacity quota reversal/compensation ledger. Không xóa legacy code hoặc grant; issue mới EXAM-only. Unsupported legacy revoke vẫn cần controlled policy/error, không pretend quota đã hoàn.
- APP-09: taxonomy organizationType mới, reserved routing codes và cleanuplegacy nếu existingdomain chưa có authoritativepolicy. Bound/schema/currentcontract vẫn trongscope.
- APP-06: global pending-tax exclusivity là productrule mới, không thêm ngầm; giữ uniqueness ở creation/approval.
- COM-06: pagination Applications/Plans chỉ quyết định sau fixtures/đo thực tế; boundedLicensepagination và independentapplicationdetail vẫn bắtbuộc.
- Full-suite: 11 failures là evidence lịch sử trên HEAD906345c, chưa xác nhận lại ở HEAD hiện tại. Phase01 chạy baseline mới; nếu còn lỗi ngoài scope thì đề xuất task riêng, không waive gate hoặc tự mở rộng implementation.

## Evidence khi cook

Bổ sung từngcase: fixture/preconditions, observedHTTP+errorcode, DBaftercommit/actor/audit, raceinterleaving, browsernetwork/mockvsreal, testcommand+timestamp, defect/deferredowner. Mộtcasebao gồm nhiều nhánh phải đủ scopeđãchốt mới Passed; nhánhdeferred ghi Partial trongdisposition và Blocked/Notrun với reason ởexecution/subcase. Checklist scope không thay test receipt.
