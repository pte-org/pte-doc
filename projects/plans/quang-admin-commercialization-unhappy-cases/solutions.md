# Giải pháp đề xuất cho 45 unhappy cases của Admin

Ngày: 2026-10-05. Trạng thái: đề xuất, chưa phê duyệt hoặc triển khai. Đối chiếu với [ma trận case](unhappy-cases.md) và [spec kiểm thử](spec.md).

## 1. Hướng giải quyết

Không xử lý 45 case thành 45 bản vá riêng. Dùng sáu nhóm giải pháp: validation chung, query/mutation lifecycle, concurrency, quyền lợi catalog/license, tính bền vững transaction và khả năng phục hồi/vận hành.

Ưu tiên backend bảo vệ invariant; disable nút hoặc cảnh báo UI chỉ là lớp hỗ trợ. Các case giả thuyết phải có test tái hiện trước khi quyết định thay implementation. Các đề xuất API/schema bên dưới là thay đổi tương lai, không phải contract đã có.

### Những quyết định nghiệp vụ đề xuất

| Quyết định | Đề xuất chính | Đánh đổi / phương án tối thiểu |
|---|---|---|
| Quyền lợi mã đã phát | Snapshot immutable của family, duration, cap/slots, tên/version plan tại issue. Archive chỉ dừng phát/bán mới; mã còn hạn vẫn redeem snapshot. Revoke là hành động thu hồi riêng. | Cần schema và activation contract mới. Hotfix trước mắt: cấm đổi family khi ACTIVE; chặn archive và sửa entitlement nếu còn mã ISSUED chưa hết hạn, trả 409 có số lượng phụ thuộc. Không dùng hotfix này như chính sách cuối cùng nếu admin cần archive thường xuyên. |
| License capacity | Trước mắt đồng bộ UI/API chỉ issue EXAM_PACKAGE, phù hợp wording hiện tại. Chỉ mở capacity khi có quy tắc hoàn quota được duyệt. | Không xóa hoặc làm hỏng capacity code đã tồn tại. Inventory và xử lý riêng mã legacy. Nếu hỗ trợ capacity, grant/reversal phải đi qua ledger của tenancy, không sửa số quota trực tiếp. |
| Email onboarding | Approval tạo tenant/host và durable delivery intent; UI báo approved + queued/failed, không tự nói inbox đã nhận. Khuyến nghị chuyển từ gửi password sang link thiết lập mật khẩu một lần có hạn. | Email intent/worker cần đầu tư thêm; invitation/reset-link là thay đổi auth cần phê duyệt. Trước mắt sửa wording, hiển thị delivery status, phục hồi bằng reset credential được audit thay vì approve lại hoặc gửi password cũ. |

Không tự quyết thay chủ sản phẩm ba policy này. Những sửa nhỏ như GET detail, validation, xử lý error/pending không cần chờ toàn bộ policy.

## 2. Applications — giải pháp và acceptance

| Case | Giải pháp đề xuất | Điều kiện nghiệm thu |
|---|---|---|
| APP-01 | Thêm API-client/hook GET `/api/v1/applications/{publicId}` hiện backend đã hỗ trợ. Query key theo ID; render loading/error/404 riêng, có Retry. Không dùng list để xác định existence. | 503 báo lỗi tải; 404 mới báo không tồn tại; refresh trực tiếp detail hoạt động độc lập list. |
| APP-02 | Query-state pattern chung: initial loading skeleton, error + Retry, success-empty, filter-empty. Có cached data thì giữ bảng với cảnh báo stale, không thay bằng số0. | Bốn trạng thái không bị lẫn; lỗi initial không render KPI0 như dữ liệu thật. |
| APP-03 | UI dùng `isReviewing = approvePending || rejectPending` để khóa cả hai action. Backend lấy application bằng PESSIMISTIC_WRITE trong approval/rejection transaction rồi check PENDING; cập nhật decision/audit cùng transaction. Không thêm `@Version` vào BaseEntity toàn hệ thống chỉ để sửa case này. | Hai decision cạnh tranh: một success, một409; không tenant/user/email tương ứng decision thua. Integration test đọc bằng transaction mới sau commit. |
| APP-04 | Chuẩn hóa trim reason tại server; validate nonblank và tối đa500 ký tự đã chuẩn hóa; DTO/UI giới hạn phù hợp DB. UI có helper/counter. Giữ external error text/codes theo module constants. | 500 được nhận;501 bị validation4xx; whitespace bị chặn; không DB 500. Unicode phải có test biên để quy tắc đếm không mâu thuẫn FE/BE. |
| APP-05 | Conflict review → refetch detail/list, hiển thị decision mới và dừng action.404 → state không tồn tại. Trả code cụ thể thay generic failure. | B không tiếp tục review app đã xử lý; reason/input không bị mất trước khi biết kết quả. |
| APP-06 | Giữ approval-time uniqueness và transaction rollback; kiểm tra tax code lúc submit nếu policy yêu cầu unique tổ chức. Constraint DB là bảo vệ cuối; map constraint violation đã biết thành domain conflict ngoài transaction đã rollback, không catch rồi tiếp tục ghi trong transaction rollback-only. | Collision name/code/tax trả lỗi đúng trường; không host/tenant mồ côi; race vẫn bị DB bảo vệ. |
| APP-07 | Xem thiết kế delivery ở mục5: durable intent trong transaction approval; worker retry/dedupe; endpoint/status UI cho admin. Không lưu plaintext password vào notification history để phục vụ resend. | Broker/SMTP fail không mất khả năng phục hồi; approved không bị đảo về PENDING chỉ vì mail lỗi; user không bị tạo lại. |
| APP-08 | Khi timeout, hiển thị “Chưa xác định kết quả”; đọc lại GET detail trước retry. Nếu APPROVED thì chuyển sang xử lý delivery, không approve lần nữa. Decision state guard/lock là bảo vệ server. | Ngắt response sau commit không tạo tenant thứ hai; UI không báo definitive failure khi chưa đối chiếu. |
| APP-09 | Bổ sung độ dài name/email/phone/type theo schema. Lấy danh mục organization type từ contract hiện có, không tự hardcode tập enum khác tenancy. Tenant code phải có chữ/số và reserved-name policy dùng chung tenancy/auth nếu sản phẩm sử dụng code để định tuyến. Rà legacy invalid để admin reject với reason, không sửa ngầm. | Dữ liệu sai trả4xx trước save; dữ liệu legacy có hướng giải quyết; code`---` được quyết định rõ theo policy. |
| APP-10 | Lỗi gắn với action/current record; reset mutation khi mở/chuyển review và clear operation message khi bắt đầu action. Không chọn lỗi bằng null-coalescing xuyên nhiều mutation. | Reject lỗi mới không bị lỗi approve cũ đè; đổi record không mang error/message từ record khác. |
| APP-11 | Bổ sung reviewedAt, reviewer theo public identity được phép, rejectReason trong detail read-only; giữ audit backend. Không expose internal credential/identifier nhạy cảm. | Admin đọc được decision đã lưu và reason; timezone rõ; missing optional metadata hiển thị neutral fallback. |
| APP-12 | Giữ approval một transaction cho tenant/host/login hash/decision; validate setting qua owning service, readiness check/config error riêng. Không tách createHostAdmin sang REQUIRES_NEW. | Fault sau tenant creation rollback mọi write trước commit; app vẫnPENDING; lỗi cấu hình có correlation ID, không lộ env. |

## 3. Plan catalog — giải pháp và acceptance

| Case | Giải pháp đề xuất | Điều kiện nghiệm thu |
|---|---|---|
| PLN-01 | Form schema theo family; BE vẫn authoritative. Giá giữ decimal string/BigDecimal; validate precision17,scale2, không tự round. Phân biệt “plan được cấp qua license” và “plan bán qua PayOS”: giá0 có thể hợp lệ cho gift nhưng không thể đặt paid order hiện tại. | UI/API cùng chặn invalid; không bắt mọi giá0 thành bug; plan không purchasable có trạng thái/validation rõ theo channel. |
| PLN-02 | Name/description max255 cả UI/DTO; trim trước validate; field errors cụ thể. Không làm migration tăng column chỉ để né validation. | Boundary255/256 đúng; payload quá dài không generic500, form giữ input. |
| PLN-03 | Required/min1/step1 cho trường family hiện tại; validate null/forbidden fields BE; khi đổi type reset/chuẩn hóa fields với thông tin rõ. | Không submit trống fields bắt buộc; API vẫn chặn mix family khi bypassUI. |
| PLN-04 | Giữ raw numeric input string để nhập/edit; validate integer/range, bỏ silent clamp. Cap hiện tại1..2000. Input quá lớn báo lỗi, không tự đổi3000 thành2000. | Giá trị lưu đúng giá trị admin đã xác nhận; overflow JSON trả400, vượt business bound trảdomain4xx. |
| PLN-05 | Catalog whitelist currency theo payment capability. Với channel PayOS hiện tại enforceVND trước publish bán; nếu chưa có channel model, đề xuất catalogVND-only là phương án đơn giản cần duyệt. Không chỉ kiểm tra length3. | `123/ZZZ` bị chặn; currency không được payment hỗ trợ không được quảng bá như purchasable. |
| PLN-06 | Cấu hình maxDurationDays dùng chung contract/form/BE; đề xuất range1..3650 ngày để trao đổi, không xem3650 là rule đã chốt. Kiểm tra tính toán expiry và khả năng lưuDB trước publish/activation; định nghĩa ceiling cho clock/expiry hợp lệ. | max/max+1 có test; mọi duration hợp lệ redeem được và lưu expiry; không chờ DB báo rangeerror. |
| PLN-07 | Disable row transition khi request pending; BE giữ lifecycle checks. Không mở thêm Archive DRAFT: draft chưa sử dụng nên có Delete/discard với guard tham chiếu; thu hẹp API archive sau khi có cleanup thay thế an toàn. Giữ archive cho ACTIVE đã đưa vào sử dụng. Xem [đánh giá archive](archive-assessment.md). | Doubleclick không gửi spam; stale transition trả409 và reload; UI/API cùng lifecycle; bỏ draft không xóa tài nguyên có lịch sử. |
| PLN-08 | `@Version` riêng Plan + version/If-Match trong update/transition contract để phát hiện stale form. Server-only version không đủ nếu request mới đã load record mới rồi overwrite với payload cũ. Áp dụng check ở mọi writer kể cả archive/activate. | A save form version cũ nhận409/412 theo contract đãchọn; không revive archived/lost update; preserve form để đối chiếu. |
| PLN-09 | Chọn policy snapshot ở mục1; archive dialog trình bày số mã lưu hành và thông báo chỉ ngừng bán/phát mới. Trước migration snapshot: dependency guard chặn archive có mãISSUED còn hạn, khóa/check trong cùng transaction với issue. | Mã đã phát xử lý đúng policy; existing subscription không bị hủy; issue/archive race không vượt guard. |
| PLN-10 | Không đổi family của ACTIVE plan, tạo plan mới cho family mới. Entitlement revision/snapshot giữ quyền lợi mã đã phát; price/name metadata cũng có version/audit. Không sửa snapshot của subscription cũ. | Code đã issue dùng revisionđã cam kết; edit mới chỉ ảnh hưởng issuance/order theo policy mới; có migration legacy rõ. |
| PLN-11 | Modal hỗ trợ canClose/busy; chặn Cancel/X/Escape/backdrop khi pending, báo rõ đang lưu. Nếu cho navigation thì operation ID guards ngăn callback cũ resetform mới; đóngUI không được coi là hủy business request. Dirty form cần confirm bỏ thay đổi. | Delayed success không đóng/reset form mới; lỗi giữ input; không bỏ requestserver vì clientunmount. |
| PLN-12 | Catch mutateAsync tại event boundary, reset error khi mở/thực hiện action mới; toast theo operation. Dùng formatter decimal chính xác, không Number cho giá17digits. Tận dụng thư viện decimal hiện có nếu có trước khi thêm dependency. | API reject không tạo unhandledrejection; lỗi mới đúng action; giá lớn render không thay giá trị. |

## 4. License codes — giải pháp và acceptance

| Case | Giải pháp đề xuất | Điều kiện nghiệm thu |
|---|---|---|
| LIC-01 | Separate plan-query loading/error/empty; disable Issue khi không xác định eligible plans; Retry riêng plans. Giữ list codes hoạt động nếu loadplans lỗi. | Admin phân biệt không cóplan và tải plan thấtbại; không submit selection stale. |
| LIC-02 | Đưa eligibility check, snapshot và insertcode vào transaction nhất quán; khóa Plan có thứ tự thống nhất với edit/archive. Không check trong outer transaction rồi save bằng REQUIRES_NEW khiến lock/rollback không bao phủ write. Retry token collision phải retry cả transaction ở ngoài. | Issue chỉ nhận revisionACTIVE hợp lệ lúc linearization; archive race không phát token trái policy; uniqueness DB vẫn giữ. |
| LIC-03 | Contract expiry là UTC Instant; form hiển thị timezone rõ và min-date chỉ là hỗ trợ. Nếu admin nhập ngày, định nghĩa timezone business và boundary chính xác ởserver; dùng exclusive next-midnight cho “hết ngày”, không dùng23:59:59 để bỏ sót fractions. | Exactly at expiry khôngredeem; optionalnull rõ; cùng ngày nhập theo timezone đãchọn cho cùng Instant ở mọi browser. |
| LIC-04 | Giữ atomicmarkRedeemed + transaction chung activation/linkage, không thêm grant riêng REQUIRES_NEW. Thêm constraint/linkage uniqueness phù hợp nếu cần, worker/business outcome dedupe. Trước tiên viết test PostgreSQL concurrency/rollback vì bảo vệ đã có. | Hai tenant chỉmột entitlement; activation fail rollback tokenstate và quota/subscription; không cấp lại do retry. |
| LIC-05 | Hiện Revoke cho ISSUED còn hiệu lực và REDEEMED exam theo policy; yêu cầu reason, hiển thị tenant/subscription và tác động sessions. Không mởcapacity reversal khi chưa chốt. | ActionUI tương ứng API; admin xác nhận hậu quả thực; reason đãtrim1..255 được lưu/audit. |
| LIC-06 | Redeem snapshot hợp lệ ngay cả catalog archived; kiểm tra hiệu lựccode và tenant/user hiện tại, không bỏ authorization vì plan đãarchived. Activation path dùng immutableterms, không sửaglobalACTIVE check của paidorders để lách lỗi. | Archived ngừngissuance mới nhưng token cũ redeem theo policy; revoked/expired vẫn bịchặn. |
| LIC-07 | Immutableterms lúc issue và family không đổi trênACTIVE plan; redemption lưu snapshot provenance/revision vào entitlement. | Sửa catalog không đổi loại/cap/duration của mã cũ; receipt có thể đối chiếu điều đã cam kết. |
| LIC-08 | GET revoke-preview có version/effective state/affectedentitlements; confirm gửi expectedversion hoặc explicit expectedstate + acknowledgedscope. BE recheck dưới lock; nếu vừa redeemed thì409 yêu cầu preview/confirmmới, không tựcancel dưới confirmationISSUED. | Race không hủy entitlement ngoài quyết định admin; hai revoke không códuplicate effect/audit; cronexpiry nhất quán. |
| LIC-09 | Ưu tiên atomic revoke trong monolith: cancellation qua session publicfacade tham gia cùng billingtransaction, bằng sync orchestration hoặc BEFORE_COMMIT listener sau khi kiểm chứng flush/order. Khóa sessions theo thứ tự và recheckSCHEDULED; audit/inboxintent cùngcommit. Không chỉ thêmREQUIRES_NEW rồi tuyênbố atomic. | Subscription/code/session cùngcommit hoặc rollback; OPEN/CLOSED không hủy; concurrentopen không bịcancel dựa trên stalestatus. Nếu không thể cùng transaction, dùng durableintent + pendingstate/retry/reconciliation, UI không báo fullycompleted sớm. |
| LIC-10 | Paginated/search adminAPI với page/size bounded, stable sort `(issuedAt, publicId)`, total hoặc hasNext; filter status/plan/tenant và exact-code lookup theo quyền. UI loadsearch/page, không clientfilter chỉ100code. | Mã101+ được tìm/revoke; response không unbounded; không dùngrawtoken trong log/searchURL không cầnthiết. |
| LIC-11 | Theo đề xuất phaseđầu, BE cũng chỉ issuing EXAM; inventorylegacycapacitycode trước thay đổi. Nếu cho capacity: ledger grant và compensation idempotent, policy không giảm quota dướiusage thiếu quy trình remediation. | Không âmquota, không xóa students để “hoànquota”; xửlýlegacy và audit rõ; không silentlyrevoke token mà nói quotađãhoàn. |
| LIC-12 | Idempotency-Key cho issue: client tạo một key cho một ýđịnh, dùng lại khi retry; server lưu caller+operation+key+payload hash+result reference và insertcode cùng transaction, uniqueconstraint chống race. Payloadkhác cùng key trả409; request mới có key mới. | Commitresponse bịmất rồiretry trả cùngcode/result, không issue thêm; result chỉ accessible cho caller/quyền hợp lệ; TTL/recoverywindow rõ. |
| LIC-13 | Error codes riêng404notfound/409stateconflict/410expired; field reason helper/max255; standard trim + uppercase như hiện tại, không normalize mạnh làm token khác tương đương. Có catch/resetmessage và refetch khi conflict. | No raw stack trace; error đúng case; stale action dừng; normalized valid token hoạt động mà invalid token không được cấp quyền. |
| LIC-14 | Một hàm effective state dùng server clock cho read/redeem/revoke; ISSUED có expiry<=now được coi EXPIRED dù cron chưa chạy. Cron chỉ materialize, không là nguồn quyết định entitlement. Không đổi REDEEMED thành EXPIRED vì code expiry đã qua. | Trước/sau cron cho cùng kết quả nghiệp vụ; exact boundary ổn định; UI dùng UTC timestamp và refresh nếu clock stale. |
| LIC-15 | List mask token mặc định, reveal/copy có authorization và audit theo policy; dùng publicId thay bearer token làm target admin endpoints mới để giảm URL log exposure. Hiển thị tên plan/revision, redeemed tenant/subscription; clear success message trước action mới. | Screenshot/list không lộ toàn token mặc định; reveal/copy fail báo đúng; log không chứa token; support truy vết được recipient. |

## 5. Transaction và delivery: tránh sửa nửa vời

### Review và email

- Approval transaction khóa application, tạo tenant/host, lưu quyết định và **ý định gửi email bền vững**. Không gửi broker/SMTP trong transaction này.
- Worker lấy intent sau commit, retry có giới hạn/backoff, dedupe theo application + decision, có trạng thái failed/dead-letter và cách phục hồi cho admin. Publish có thể lặp; consumer phải idempotent. Không hứa email chỉ gửi đúng một lần nếu mail provider không hỗ trợ dedupe.
- `NotificationLog`/RabbitMQ dispatch AFTER_COMMIT hiện tại chưa chứng minh ý định gửi email được lưu cùng approval. Inbox delivery intent hiện có phục vụ notification inbox, không đồng nhất với email credentials. Tái dùng đúng capability, không tạo thêm infrastructure chỉ vì tên outbox xuất hiện trong plan cũ.
- Khuyến nghị link thiết lập/reset mật khẩu một lần thay password để retry/resend không cần giữ password plaintext. Nếu chưa đổi auth: không đặt generated password vào plaintext intent; payload mã hóa có hạn cần retention, quản lý key và security review. Admin reset credential phải có audit, vô hiệu credential/link cũ theo policy và không tự reset người đang dùng bình thường.

### Revoke và sessions

- Trong modular monolith dùng public API của module, không import repository hoặc session internals vào billing.
- Review thứ tự lock giữa redeem/revoke/open/schedule; đặt thứ tự thống nhất ở các write path. Lock timeout trả lỗi có thể thử lại và log correlation ID, không retry mù thao tác non-idempotent.
- Nếu dùng BEFORE_COMMIT listener, kiểm tra persistence bằng transaction mới sau commit và thử ném exception trong listener để xác nhận toàn operation rollback. Test rollback-only mặc định không đủ.
- AFTER_COMMIT + REQUIRES_NEW chỉ cải thiện persistence của side effect, không đảm bảo all-or-nothing với billing. Chỉ chọn eventual mode khi có durable intent, retry và trạng thái pending rõ ràng.

### Snapshot và migration

- Tạo immutable terms/revision; activation nhận terms qua API của billing thay vì giả lập một Plan ACTIVE để bypass check.
- Snapshot lúc issue và snapshot lúc subscription activation là hai mốc khác nhau; giữ cả provenance để audit.
- Với mã legacy không có snapshot, không thể suy ra cấu hình lúc phát chỉ từ plan hiện tại. Inventory, tạm khóa sửa entitlement có mã legacy lưu hành, đối chiếu audit nếu có; nếu không khôi phục được thì chủ sản phẩm duyệt mapping/reissue có thông báo. Không backfill giá trị hiện tại rồi gọi là “snapshot lịch sử”.

## 6. Giải pháp common — 6 case

| Case | Giải pháp đề xuất | Điều kiện nghiệm thu |
|---|---|---|
| COM-01 | Backend role check giữ nguyên; UI guard đúng PLATFORM_ADMIN;403 render forbidden không empty. Khi quyền thay đổi, clear/refresh session authorization theo contract. | Gọi trực tiếp API không bypass; không dựa menu để bảo mật. |
| COM-02 | Giữ deduped token refresh và tối đa một replay 401 hiện có; server 401 phải trước business mutation. Network timeout khác 401: không tự retry create; dùng idempotency/reconcile. Logout clear sensitive cache, guard callback bằng session generation. | User mới không thấy dữ liệu cũ;401 refresh không vòng lặp; logout không có late cache write cho session khác. |
| COM-03 | Pattern shared ở hook/helper: catch mọi event async, error code → user message, field errors với correlation ID; reset operation error. Giữ khác biệt 400 DTO/422domain/409state theo contract hiện tại. | Error không lộ stack/SQL; không unhandled rejection; text/constants thuộc module sở hữu. |
| COM-04 | Mutation success cập nhật cache từ server response nếu đủ, invalidate cả list/detail liên quan; error 409 refetch; nếu refetch fail giữ dữ liệu cũ và banner stale. Không đổi “đã lưu” thành “lưu thất bại” chỉ vì refresh fail. | UI phân biệt committed save và load failed; không giữ stale action enabled. |
| COM-05 | Pending/dirty navigation policy chung; operation IDs và request/session guards; return to màn dùng query server. Không gọi AbortController là rollback server. | Back/forward/refresh không làm callback cũ clear form mới, status được đối chiếu; operation uncertain có hướng recover. |
| COM-06 | Server filter/pagination cho list lớn; detail GET độc lập; label wrap/ellipsis+accessible reveal, null fallback, timezone/decimal format chuẩn. Đo fixture trước đặt SLO; tránh tối ưu toàn app không cần thiết. | Dataset>100 vẫn locate được record; tên long không che action; dữ liệu không đủ không format thành NaN hoặc lỗi quyết định. |

## 7. Thứ tự thực hiện đề xuất

1. **Đợt A — rõ trạng thái, validation:** APP-01/02/04/05/09/10/11; PLN-01/02/03/04/11/12; LIC-01/03/13/14; commonerror/pending/cache. Ít phụ thuộc policy, khôngredesign.
2. **Đợt B — invariant/transaction:** APP-03/06/08/12; PLN-08; LIC-02/04/08/09/12; authisolation. Integration test trước fix các giả thuyết, kiểm traDB sau commit.
3. **Đợt C — policy quyền lợi:** duyệt snapshot/legacy/family, capacity, deliveryrecovery; thực hiện PLN-05/06/07/09/10, LIC-05/06/07/11, APP-07. Hotfixguard có thể đưa sớm hơn nếu risk được xác nhận.
4. **Đợt D — vận hành:** LIC-10/15, COM-06, audit/reconciliation/metrics; đoquy mô và quyết định pagination Applications/Plans.

Đợt là trình tự đềxuất, khôngestimate thời gian và khôngapproval triểnkhai.

## 8. Tiêu chí bàn giao khi triển khai sau này

- 45 case có result/evidence; case policy chỉ pass sau expected được duyệt.
- Cạnh tranh decision/entitlement có test independent transactions + repeated runs; rollback khôngmồcôi tenant/user/subscription/quota.
- Timeoutpost-commit với cùng idempotency key không duplicate issue; khác payload cùng key conflict.
- Revoke commit có thể đọc cancellation ởtransaction mới; lỗi intent/SMTP có recovery state, không nhầm inbox delivery.
- Snapshotlegacy có migration decision, không thay quyền lợibằng silent backfill.
- Browser network fixtures cóerror/loading/stale/retry/pendingclose và console không unhandled rejection.
- Không token/password/email nhạy cảm thật trong test artifact; tests không mutation production; deployment chỉkhi user cho phép.

## 9. Căn cứ và giới hạn

Căn cứ nguồn S01–S22 ở [ma trận](unhappy-cases.md). Kiểmtra thêm [OrderService.java](../../../../pte-api/app/src/main/java/com/pte/billing/internal/service/OrderService.java) cho điều kiện giápositive/currency PayOS và [CommercialNotificationListener.java](../../../../pte-api/app/src/main/java/com/pte/notification/internal/listener/CommercialNotificationListener.java) cho inboxintent BEFORE_COMMIT. [API client](../../../../pte-web/packages/api-client/src/client/client.ts) hiện có dedupedrefresh/replay 401; không đềxuất viết thêm một cơ chếrefresh trùng.

Đây là giải pháp thiết kế, không patchcode hoặc xác nhận các giả thuyết thànhbug runtime. 27 unit tests đượcghi ở lượt khảo sát trước, không rerun trong lượt đềxuất này. Thayđổi lượt này chỉ là tài liệu; việc review link/coverage 45 case không thay thế implementationtests.
