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

## Phase07 execution reconciliation

This section is the authoritative current execution record for the 45 IDs. The original `New execution` column above remains the planning-time placeholder from 2026-10-05 so the ledger preserves its audit history. `Passed` is always qualified by the evidence type and does not imply browser, live-backend, scale, or production proof. `Blocked`/`Not run` are explicit evidence states, not implementation dispositions.

Evidence anchors: the fresh Java21 and web command results, selected PostgreSQL run, source scan, and handoff limits are recorded in [phase-07-regression-handoff.md](phase-07-regression-handoff.md#execution-update-2026-10-06). Prior phase receipts remain historical supporting evidence and are not silently upgraded to current browser/production evidence.

| IDs | Current execution | Evidence and residual boundary |
|---|---|---|
| APP-01, APP-02 | Passed (backend/client automated subset) | Tenant application service/client contracts and full suite pass; 503/404/retry and list-state browser acceptance not run. |
| APP-03 | Passed (PostgreSQL decision-race subset) | Ten approval-vs-reject races commit exactly one terminal decision with committed readback; name/code collision races and browser acceptance remain unrun. |
| APP-04 | Passed (service validation) | Trim/blank/reason boundary service checks pass; native UI Unicode/field-retention acceptance not run. |
| APP-05 | Passed (unit/HTTP error subset) | Reviewed/not-found classifications pass; stale-detail refetch browser path not run. |
| APP-06 | Passed (unit conflict subset) | Submit/approval conflict mapping passes; PostgreSQL name/code/tax collision race and rollback not run. |
| APP-07 | Blocked (partial scope) | Truthful approval/reset subset is retained; durable SMTP/broker delivery/retry remains explicitly Deferred. |
| APP-08 | Passed (service guard subset) | Pending/review guards pass; response-loss-after-commit and retry browser acceptance not run. |
| APP-09 | Passed (schema/bound subset) | Current schema/bound checks pass; organization taxonomy/reserved-code policy remains Deferred. |
| APP-10, APP-11 | Passed (service/full-suite subset) | Action error/decision metadata contracts pass; multi-record UI reset and authenticated display acceptance not run. |
| APP-12 | Passed (PostgreSQL rollback subset) | Injected approval-side identity failure leaves the application PENDING; durable delivery and other external-side-effect failures remain outside this checkpoint. |
| PLN-01..PLN-08 | Passed (Plan service/controller/client subset) | Java21 Plan/HTTP/API-client checks pass, including version/lifecycle guards; native form and PostgreSQL stale-write overlap acceptance not run. |
| PLN-09, PLN-10 | Passed (fresh PostgreSQL inherited guards) | Archive lifecycle and issue/archive/entitlement-edit repetition plus outstanding-code and ACTIVE-family guards pass; no snapshot policy was introduced. |
| PLN-11, PLN-12 | Blocked (browser residual) | Pending-modal/late-callback/error-reset/decimal-display browser scenarios were not runnable without an existing harness. |
| LIC-01 | Passed (service/client subset) | Bounded admin/service contracts pass; plan loading/error/empty browser states not run. |
| LIC-02 | Passed (issue/archive guard subset) | Active-plan and issue/archive protections pass; direct 404/legacy-edge UI acceptance not run. |
| LIC-03 | Passed (HTTP/service expiry subset) | UTC/equivalent-offset and expiry contract checks pass; browser timezone/native input acceptance not run. |
| LIC-04 | Passed (fresh PostgreSQL race/rollback) | Ten-repetition two-tenant redemption and linkage rollback pass; no production DB evidence. |
| LIC-05 | Passed (service/HTTP subset) | Redeemed revoke behavior and contract checks pass; list UI action availability was not browser-tested. |
| LIC-06 | Passed (legacy archived-plan subset) | Direct legacy ISSUED-code-on-ARCHIVED-plan fixture fails closed with the plan-inactive error and leaves the code ISSUED; broader legacy data repair policy is not claimed. |
| LIC-07 | Blocked (legacy entitlement edge not executed) | Post-issue family/capacity mutation followed by redemption was not run; no snapshot bypass was claimed. |
| LIC-08, LIC-09 | Passed (unit/HTTP subset) | Preview/revoke/listener contracts pass; PostgreSQL revoke/session interleaving and fault-after-listener commit are not run. |
| LIC-10 | Passed (bounded page/client subset) | Server paging/filter/lookup contracts pass; the local scale sample measured the current ISSUED query at 0.324 ms, but production-like query budget/load evidence is not run. |
| LIC-11 | Passed (approved partial scope) | Fresh PostgreSQL proves new capacity issue denial and valid legacy capacity redemption; quota reversal/compensation remains Deferred. |
| LIC-12 | Passed (fresh PostgreSQL idempotency) | Same-key/different-payload races, rollback, collision retry and replay identity pass in the isolated container. |
| LIC-13, LIC-14 | Passed (service/HTTP/expiry subset) | Error/status/reason and effective expiry contracts pass; complete stale UI and cron/revoke interleaving acceptance not run. |
| LIC-15 | Passed (privacy contract subset) | Masked page, reveal/lookup no-store, redaction and client cache boundaries pass; authenticated browser trace/access-log inspection not run. |
| COM-01 | Passed (backend/client security subset) | Backend role/error contracts and client checks pass; authenticated role switch/revocation browser acceptance not run. |
| COM-02 | Passed (client session-generation subset) | Refresh/replay and stale-generation tests pass; real multi-tab/logout cache acceptance not run. |
| COM-03 | Passed (error contract subset) | API error mapping and client fallbacks pass; browser console/unhandled-rejection inspection not run. |
| COM-04 | Blocked (cache/refetch residual) | Commit-vs-refetch failure and stale-tab browser scenario were not directly executable. |
| COM-05 | Passed (client/session guard subset) | Session-generation fencing and operation cleanup are typechecked/tested; navigation/tab acceptance not run. |
| COM-06 | Passed (bounded local scale/EXPLAIN sample; pagination deferred) | Isolated PostgreSQL measured 174 applications, 606 plans, and 613 license codes (479 current ISSUED); tested list/page/enrichment queries ran in 0.084–0.951 ms in this fixture, with seq scans/sorts observed on unbounded lists. Production-like load/query-budget evidence and global Applications/Plans pagination remain Deferred. |

## Evidence khi cook

Bổ sung từngcase: fixture/preconditions, observedHTTP+errorcode, DBaftercommit/actor/audit, raceinterleaving, browsernetwork/mockvsreal, testcommand+timestamp, defect/deferredowner. Mộtcasebao gồm nhiều nhánh phải đủ scopeđãchốt mới Passed; nhánhdeferred ghi Partial trongdisposition và Blocked/Notrun với reason ởexecution/subcase. Checklist scope không thay test receipt.
