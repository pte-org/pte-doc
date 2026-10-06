# Unhappy cases: Applications · Plan catalog · License codes

Ngày khảo sát: 2026-10-05. 45 case đề xuất: 12 Applications, 12 Plan catalog, 15 License codes, 6 dùng chung.

Snapshot khảo sát ban đầu, giữ45 ID ổn định. Code lifecycle đã thay đổi một phần các nhánh PLN/LIC sau khảo sát; dùng [implementation-spec.md](implementation-spec.md) và coverage của plan mới để xác định residual scope. Không tự đánh dấu các case này Passed từ khảo sát/lifecycle receipts.

## Cách đọc và giới hạn bằng chứng

- **C**: thấy trực tiếp nhánh xử lý hoặc khoảng trống trong code; không có nghĩa đã tái hiện lỗi runtime.
- **H**: giả thuyết cần test DB/network/concurrency hoặc chốt policy; chưa phải bug confirmed.
- **T**: có test hiện tại liên quan đã chạy qua; không thay thế việc thực thi toàn bộ case/màn hình.
- P1: nên test trước vì quyền truy cập/quyền lợi, mất khả năng vận hành hoặc dữ liệu không nhất quán. P2: validation/phục hồi/truy vết. P3: hardening tùy policy.

Tất cả case mới dưới đây có execution status **Not run**. Đã chạy riêng 27 unit tests hiện có, ghi ở phần cuối. Không có browser E2E hoặc test concurrency/PostgreSQL trong lượt khảo sát này.

Expected là đề xuất acceptance criteria: với case policy, phải chốt expected trước khi mở bug. Nguồn Sxx ở cuối tài liệu là code hiện tại, không phải suy đoán dựa trên tên màn.

## 1. Applications — 12 case

| ID / ưu tiên / bằng chứng | Tình huống và cách kiểm tra | Expected đề xuất | Code hiện tại / rủi ro |
|---|---|---|---|
| APP-01 / P2 / C | Mở detail trực tiếp; giả lập GET applications trả 503/mất mạng; đợi query kết thúc retry. | Báo lỗi tải và cho retry; chỉ báo không tồn tại khi có dữ liệu xác nhận hoặc GET detail trả 404. | Detail tìm bản ghi trong list, không đọc `isError`; `data=[]` dẫn đến NOT_FOUND. Backend đã có GET detail nhưng UI chưa dùng. S01, S04. |
| APP-02 / P2 / C | Mở list khi API 500; riêng một lượt dùng filter không có kết quả và một lượt DB thật sự rỗng. | Ba trạng thái error, empty database và empty filter khác nhau; không diễn giải thống kê mặc định 0 là dữ liệu thật. | List có Alert lỗi nhưng vẫn render thống kê/dữ liệu mặc định rỗng; không có nút retry riêng. S02. |
| APP-03 / P1 / C,H | Application PENDING; nhập reason; giữ approval request pending rồi bấm reject. Lặp lại với hai admin độc lập, barrier trước khi commit. | Chỉ một decision hợp lệ; loser nhận conflict; application, tenant/user và email phản ánh cùng decision. | Hai nút không disable chéo; `findPending` dùng đọc thường, entity không có version. Có thể race approve/reject; chưa chứng minh DB cuối cùng sai. S01, S04, S05. |
| APP-04 / P2 / C,H | Reject với 0/whitespace, 500 và 501 ký tự qua UI/API. | Rỗng bị chặn; giới hạn được công bố; quá giới hạn trả validation 4xx, không generic 500; giữ input. | UI trim/chặn rỗng, DTO chỉ NotBlank; cột `reject_reason` VARCHAR(500). Case 501 có nguy cơ lỗi persistence. S01, S06, S07. |
| APP-05 / P1 / C,T | Admin A review xong; B đang giữ detail PENDING bấm lại; thử application UUID không tồn tại. | Trả 409 cho đã review, 404 cho không tồn tại; UI cập nhật trạng thái và dừng mời review lại. | Service có not-pending/not-found; hooks chỉ invalidate khi success, conflict không chủ động refetch. Nhánh backend có test; stale UI còn phải test. S03, S04, S21. |
| APP-06 / P1 / C,T,H | Application chờ review; tenant khác chiếm name/code/tax code trước approval. Thử thêm hai pending cùng tax code, name/code khác nhau. | Không tạo tenant/user một phần; lỗi nói rõ trường xung đột; admin có hướng reject/xử lý. | Submit kiểm tra name/code, không kiểm tra tax code; lúc tạo tenant có kiểm tra cả ba. Approval transaction cần test rollback và uniqueness race. Test hiện có cover submit name/code, không chứng minh race. S04, S08. |
| APP-07 / P1 / C,H | Approve khi SMTP worker lỗi, RabbitMQ unavailable hoặc recipient sai nhưng đúng format; đọc lại trạng thái app và email job/log. | Phân biệt approved, email queued/failed và delivered; có cơ chế phục hồi credentials mà không approve lại. | Email listener AFTER_COMMIT; dispatch REQUIRES_NEW gửi RabbitMQ. UI thông báo credentials “were sent”. Commit nghiệp vụ có thể xong trước lỗi mail; chưa kiểm tra lỗi hậu commit hoặc inbox. S09, S10. |
| APP-08 / P1 / H | Ngắt kết nối sau server commit approval nhưng trước khi browser nhận response; admin retry. | Admin xác minh decision hiện tại, không tạo tenant/host thứ hai; không hiểu retry conflict là application chưa approved. | Sau commit, retry tuần tự bị chặn bởi PENDING check; client không có luồng đối chiếu kết quả uncertain. Đây không phải cùng loại với race APP-03. S01, S03, S04. |
| APP-09 / P2 / C,H | Submit upstream orgName 255/256, phone hoặc orgType rất dài; dùng code `---` hoặc orgType không có trong sản phẩm; admin thử approve dữ liệu đã tồn tại. | Validation theo domain trước review; admin nhìn được lý do không thể approve dữ liệu lỗi; không 500 do giới hạn DB. | Submit DTO thiếu Size cho nhiều trường; regex code cho phép toàn dấu gạch; orgType chỉ NotBlank. DB có VARCHAR. Giá trị có hợp lệ nghiệp vụ hay không cần policy, không mặc định mọi orgType lạ là bug. S06, S07. |
| APP-10 / P2 / C,H | Approve một app bị lỗi; sau đó reject cùng app với lỗi khác; đổi app trong cùng screen lifecycle. | Error mới nhất đúng action/record; không hiển thị lỗi cũ đè lỗi mới. | `approve.error ?? reject.error` ưu tiên lỗi approve tồn dư; không có reset mutation rõ ràng. Mount/unmount cụ thể cần test browser. S01. |
| APP-11 / P2 / C | Xem application đã REJECTED hoặc APPROVED khi xử lý khiếu nại. | Có thể truy vết reason/người review/thời điểm theo quyền admin; không bắt admin đoán lý do từ trạng thái. | Entity giữ reviewedBy/reviewedAt/rejectReason nhưng detail hiện tại không trình bày các trường review này. Xác nhận nhu cầu audit trước khi coi thiếu UI là bug. S01, S05. |
| APP-12 / P1 / C,H | Config `free_student_limit` thiếu/sai kiểu hoặc lỗi tạo host sau khi tạo tenant; fault injection trong môi trường test. | Toàn bộ approval rollback nếu lỗi trước commit; giữ PENDING; không tenant/user/login hash mồ côi; lỗi có hướng xử lý. | Approval đọc setting và gọi tenancy/identity trong transaction chung. Test mock hiện tại không chứng minh rollback DB; cần integration. Không đưa config thật hoặc generated password vào evidence. S04, S08. |

## 2. Plan catalog — 12 case

| ID / ưu tiên / bằng chứng | Tình huống và cách kiểm tra | Expected đề xuất | Code hiện tại / rủi ro |
|---|---|---|---|
| PLN-01 / P2 / C,T | Name whitespace; giá thiếu/âm/3 số lẻ/18 số phần nguyên; currency thiếu/khác 3 ký tự; type không hợp lệ qua API. | Chặn trước save; không để DB tự round giá; lỗi field dễ hiểu và HTTP phù hợp. | DTO @Digits(17,2), @DecimalMin; service kiểm tra thêm. Validation DTO thường 400, service domain 422. Test service cover precision, không chứng minh form/controller. S11, S12, S20, S21. |
| PLN-02 / P2 / C,H | Name 255/256 ký tự; description 255/256 qua form/API. | Giới hạn đồng nhất FE/BE/DB; lỗi quá dài 4xx, giữ form. | DTO name thiếu Size, DB255; description có Size255 nhưng form không maxLength. Name dài có nguy cơ 500, description thường 400. S11, S12, S07. |
| PLN-03 / P2 / C,T | Xóa duration/cap của EXAM_PACKAGE; chuyển STUDENT_CAPACITY để slots trống. API thêm trường của family đối lập. | UI required theo family; API không nhận null/âm/0 hoặc mix family; không tạo plan không usable. | Các numeric input chưa required; null đi tới service validation. Payload UI chủ động null trường family khác; backend chặn mix family, có test. S11, S12, S21. |
| PLN-04 / P2 / C,H | Nhập capacity 2000/2001/3000, số âm, thập phân; duration int overflow qua API. | Rõ lỗi vượt giới hạn, không tự đổi quyền lợi khác ý định; controller xử lý sai kiểu/overflow 400. | FE `Math.min` silently clamp trên max; backend cap2000. Native number validation có thể chặn một số nhập trực tiếp; phải kiểm tra UI thực, không suy API nhận được mọi giá trị UI. S11, S12, S20. |
| PLN-05 / P2 / C,H | Nhập currency `123`, `ZZZ`, hoặc currency không được payment hỗ trợ; activate và dùng trong luồng downstream. | Chỉ currency được sản phẩm hỗ trợ, hoặc báo rõ unsupported trước bán/phát quyền lợi. | DTO/service chỉ yêu cầu nonblank/length3, không whitelist. Chưa kết luận payment nào lỗi vì task không audit payment provider. S12. |
| PLN-06 / P1 / C,H | Tạo EXAM_PACKAGE duration rất lớn (vd 2.000.000.000), activate, phát mã rồi redeem trong DB test. | Duration có business upper bound; mọi plan ACTIVE đã bán/phát mã phải tạo expiry lưu DB được. | FE max2 tỷ, service chỉ >0; activation cộng số ngày vào Instant. PostgreSQL timestamp có giới hạn khác Java Instant; cần kiểm tra thực lỗi persistence, không chỉ assert service mock. S11, S12, S15. |
| PLN-07 / P2 / C,H | Bấm Activate nhiều lần; hai admin activate cùng DRAFT; sửa/activate ARCHIVED; API archive DRAFT. | Transition ngoài policy 409, UI không spam request; DRAFT archive có/không hỗ trợ phải nhất quán UI/API. | ACTIVE activate và ARCHIVED edit/activate bị chặn; UI không có archive DRAFT trong khi API cho phép. Activate action không disable theo pending; race chưa test. S11, S12, S21. |
| PLN-08 / P1 / C,H | A đang edit ACTIVE; B archive rồi A save. Test thêm hai update khác nhau và update/archive overlap trước commit. | Không revive plan archived hoặc silently overwrite người khác; loser nhận conflict và reload. | Service kiểm tra archived lúc read nhưng entity không version; full-field update có nguy cơ lost update/stale status write tùy interleaving. Phải chứng minh bằng DB test, không gọi là confirmed resurrection. S05, S11, S12. |
| PLN-09 / P1 / C,H | Có mã ISSUED chưa hết hạn; archive plan rồi tenant redeem; kiểm tra subscription đã tạo trước archive riêng. | Policy rõ: chặn archive có mã lưu hành hoặc giữ redeem theo snapshot, hoặc cảnh báo/thu hồi có quy trình. Existing subscription không bị mất chỉ vì archive. | Redeem lấy plan live, activation bắt ACTIVE → conflict khi archived. Đây là hành vi code, việc có sai yêu cầu cần chốt policy. Archive dialog chưa nói hậu quả cho mã lưu hành. S10, S12, S14, S15. |
| PLN-10 / P1 / C,H | Phát code rồi sửa duration/cap/type ACTIVE trước redeem; đồng thời kiểm tra subscription đã tồn tại. | Admin biết mã chưa redeem đổi quyền lợi hay giữ snapshot; đổi family không vô tình đổi loại quyền lợi đã hứa. | Update cho cả ACTIVE, áp dụng type/limits; code chỉ planId nên redeem dùng giá trị mới. Subscription lưu expiry/cap tại activation, không giống snapshot lúc issue. S12, S14, S15. |
| PLN-11 / P2 / C,H | Delay save; đóng modal bằng Cancel/X/Escape; mở form mới; cho request cũ success/fail. | Không reset/đóng form mới hoặc đánh mất input; hiển thị kết quả gắn đúng operation; bảo vệ unsaved/pending state. | Save success gọi `resetForm`; modal/Cancel vẫn cho close khi save pending. Button submit có disable khi loading nhưng không bảo vệ modal lifecycle. S11, S19. |
| PLN-12 / P2 / C,H | Create lỗi rồi mở Edit; activate/archive lỗi; kiểm tra console sau API reject; giá gần giới hạn 17 digits hiển thị. | Lỗi theo action mới; không unhandled promise rejection; giữ chính xác giá đã lưu khi render. | Mutation error chain không reset; handlers `void save/transition/confirm` gọi mutateAsync không catch. `Number(plan.price)` có thể mất precision; price truyền form dạng string nên không tự kết luận payload bị mất số. S11. |

## 3. License codes — 15 case

Case redeem nằm phía tenant/API nhưng được đưa vào vì quyết định phát/thu hồi của admin trực tiếp ảnh hưởng entitlement. Không mở rộng sang audit toàn tenant web.

| ID / ưu tiên / bằng chứng | Tình huống và cách kiểm tra | Expected đề xuất | Code hiện tại / rủi ro |
|---|---|---|---|
| LIC-01 / P2 / C | License list tải được, plans API fail/đang loading; riêng một lượt không có ACTIVE exam plan. | Phân biệt loading/error/no eligible plan; admin biết vì sao không phát được và có thể retry. | `usePlansQuery` chỉ lấy data=[], không đọc loading/error; selector rỗng ở cả ba trạng thái. S13. |
| LIC-02 / P1 / C,T | Chọn ACTIVE plan, admin khác archive trước issue; API dùng UUID không tồn tại, DRAFT/ARCHIVED/null. | Không phát mã unusable; 404/not-active/validation rõ ràng; refresh selection. | Service check plan tồn tại/ACTIVE, có test inactive. Check nằm ngoài transaction save REQUIRES_NEW nên archive sau check vẫn cần race test riêng. S14, S21. |
| LIC-03 / P2 / C | Expiry ngày hôm qua/hôm nay/không nhập; API expiry đúng now, trước now, malformed Instant; browser timezone khác nhau. | Quá khứ bị chặn, optional expiry được hiểu rõ; admin biết chính xác mốc hết hạn và timezone. | Date input không min; UI dùng 23:59:59 local → UTC, table hiển thị ngày. DTO @Future thường400; service thời gian422. Không được coi code expiry là subscription expiry. S13, S14, S16. |
| LIC-04 / P1 / C,T,H | Hai tenant HOST_ADMIN redeem cùng code; fault injection activation thất bại sau markRedeemed; retry. | Tối đa một entitlement; failure rollback để mã còn dùng nếu chưa cấp quyền; tenant thua nhận already-used rõ ràng. | Conditional bulk update + transaction + lock; test hiện tại có sequential redeem twice, chưa có concurrency/rollback DB thật. S14, S17, S21. |
| LIC-05 / P1 / C,T | Có code REDEEMED gắn subscription; admin cần revoke từ màn list. | Nếu hỗ trợ revoke redeemed, có action và cảnh báo hủy quyền lợi; nếu không, API/policy phải nhất quán. | Backend revoke REDEEMED cancels linked subscription, có test; UI chỉ action ISSUED. Đây là chênh lệch khả năng UI/API thấy trực tiếp. S13, S14, S21. |
| LIC-06 / P1 / C,H | Code ISSUED còn hạn nhưng plan đã archive; tenant redeem. | Theo policy đã chốt cho mã lưu hành; không để khách nhận generic error mà admin không có hướng giải quyết. | Activation yêu cầu ACTIVE; conflict là hành vi hiện tại. Không có snapshot lúc phát. Liên quan PLN-09. S14, S15. |
| LIC-07 / P1 / C,H | Sau issue, đổi family EXAM → STUDENT_CAPACITY hoặc giảm cap/duration rồi redeem. | Không đổi entitlement đã cam kết mà thiếu cảnh báo/quy trình; xác nhận snapshot policy. | Redeem lấy plan live; activation có thể chuyển sang grantQuota và không tạo subscription. Không mặc định đổi price ảnh hưởng code vì redeem không tính tiền theo price. S12, S14, S15. |
| LIC-08 / P1 / C,H | Admin xem ISSUED, mở revoke dialog; tenant redeem trước confirm; hai admin cùng revoke; cron expire chạy cạnh revoke. | Re-read trạng thái dưới lock; cảnh báo đúng ảnh hưởng thực tế; không cancel ngoài ý định, không ghi đè sai trạng thái. | BE lock và kiểm tra states nhưng dialog chỉ nói “no longer redeemable”. Nếu vừa redeemed, BE có thể cancel subscription dù admin nghĩ chỉ vô hiệu mã chưa dùng. Cần test các interleaving. S10, S13, S14, S17. |
| LIC-09 / P1 / C,H | Revoke REDEEMED exam code với sessions SCHEDULED/OPEN/CLOSED; gây lỗi listener hoặc kiểm tra flush/persistence sau commit. | Subscription canceled; SCHEDULED được hủy persisted; OPEN/CLOSED không bị hủy; có phục hồi/quan sát hậu commit thất bại. | Session bridge AFTER_COMMIT; target lifecycle `@Transactional` REQUIRED, không REQUIRES_NEW. Cần kiểm chứng resource/commit semantics thật; nguy cơ session cancel không durable hoặc fail sau billing commit. Test LicenseCodeService chỉ xác nhận subscription/event, không chứng minh session DB. S14, S18, S21. |
| LIC-10 / P1 / C | Seed >100 code, cần tìm/revoke code thứ101 theo issuedAt. | Admin truy xuất được mã cũ theo cơ chế search/page được duyệt; không tưởng tất cả mã chỉ có100. | Repository top100; UI không pagination/search, không hiển thị giới hạn. Mã vẫn tồn tại DB nhưng không accessible qua list UI này. S13, S17. |
| LIC-11 / P2 / C,H | Case có ACTIVE capacity plan; thử issue qua UI và API; redeem rồi revoke capacity code. | Chốt capacity code có được hỗ trợ; nếu được thì UI chọn được và giải thích quota revoke policy. | UI lọc EXAM_PACKAGE; issueBE chỉ yêu cầuACTIVE. Capacity activation grantQuota; revoke không có subscriptionId không hoàn quota. Không gọi đây là bug nếu quota permanent/flow không được hỗ trợ theo policy. S13, S14, S15. |
| LIC-12 / P1 / C,H | Ngắt response issue sau DB save; admin không biết thành công và bấm lại. | Có thể đối chiếu/recover code đã cấp; retry không vô tình phát nhiều mã cấp quyền nếu operation phải là một lần. | Issue tạo token mới mỗi request; chưa thấy idempotency key. Khác redeem single-use: single-use không chống duplicate issuance do retry. S13, S14. |
| LIC-13 / P2 / C,T | Sai token, trim/lowercase, token expired/revoked/redeemed; revoke blank/>255 reason; code EXPIRED nhưng UI cache ISSUED. | Error 404/409/410 được phân biệt; stale UI refresh; chuẩn hóa không làm token sai thành hợp lệ. | Redeem trim+uppercase, branch lỗi riêng; revoke REVOKED/EXPIRED conflict. DTO reason validation400, service422. UI reason cố định không cho admin giải thích tình huống. Test liên quan cover non-issued statuses, chưa cover toàn bộ boundaryUI. S13, S14, S16, S21. |
| LIC-14 / P2 / C,H | Nhìn code ISSUED sau timestamp hết hạn nhưng cron chưa đánh EXPIRED; click revoke; refresh trong lúc cron chạy. | Thể hiện effective expired theo thời gian, không mời redeem; quy định revoke expired phải nhất quán. | Redeem check thời gian; revoke check statusEXPIRED, không check expiry timestamp. Mã elapsed nhưng cònISSUED có thể revoke, sau job lại bị409. Không có quota/subscription nếu chưaredeem; cần test trạng thái trước/sau cron. S14, S17. |
| LIC-15 / P2 / C,H | Share màn hình/screenshot list hoặc cần tra code đãredeem cho tenant nào; issue thành công rồi action khác fail. | Hiển thị token theo policy bảo mật, truy vết recipient/entitlement đủ để hỗ trợ; success cũ không che kết quả action mới. | List in full bearer code +planUUID, không tenant/subscription column; success message chứa token tồn tại qua action khác. API admin có quyền đọc code nên đây là hardening/operability, chưa chứng minh unauthorized leak. Không dùng token thật trong test evidence. S13. |

## 4. Cases dùng chung — 6 case

| ID / ưu tiên / bằng chứng | Tình huống và cách kiểm tra | Expected đề xuất | Căn cứ / điểm cần xác minh |
|---|---|---|---|
| COM-01 / P1 / H | Đăng nhập PLATFORM_AUTHOR/tenant role; gọi trực tiếp mutation admin; PLATFORM_ADMIN bị thu hồi quyền khi tab đang mở. | API chặn403; UI không coi403 là empty/no record; không chỉ dựa vào sidebar để bảo vệ. | Controllers yêu cầu PLATFORM_ADMIN; license service kiểm tra caller thêm. Test API security thực, không sửa localstorage role để giả lập đã có quyền backend. S22. |
| COM-02 / P1 / H | Token hết hạn trong khi mutation pending; refresh thất bại hoặc logout giữa request. | Không hiển thị success giả; không replay mutation tạo duplicate khi kết quả cũ chưa rõ; không giữ dữ liệu nhạy cảm cho user khác. | Cần test auth/API-client integration và cache lifecycle; khảo sát ba view chưa đủ kết luận refresh/replay sai. S03, S22. |
| COM-03 / P2 / C,H | API 400/404/409/422/500, response lỗi thiếu message, offline/timeout; mở lại form sau lỗi. | User message actionable, không lộ stacktrace/DB; lỗi field khác conflict; console không unhandled rejection. | Global handler mapping và error helper có cơ chế fallback; Plan/License async handlers khôngcatch, lỗi mutation tồn dư có thể đè lỗi mới. Không khẳng định whole app crash. S01, S11, S13, S20. |
| COM-04 / P2 / C,H | Mutation success nhưng invalidate/refetch thất bại; chuyển tab có cache; quay lại màn sau admin khác cập nhật. | Toast phản ánh commit nhưng list có trạng thái refresh thất bại/stale; không gợi thao tác theo dữ liệu obsolete. | Hooks invalidation trên success dùngvoid, không chờ list refresh; conflict không invalidate riêng. TanStack có refetch khác nên không kết luận cache vĩnh viễn stale. S03. |
| COM-05 / P2 / H | Hai browser/tab, back/forward, refresh lúc pending, dữ liệu thay đổi giữa xem và confirm. | Quyết định dựa trên state server; không để navigation hoặc retry hiểu nhầm operation đãhủy; test ghi lại actual persisted. | Các view mutation không phải cơ chế cancellation nghiệp vụ; request có thể commit dù UI đãrời màn. S01, S11, S13. |
| COM-06 / P2 / H | Dataset lớn cho Applications/Plans, danh sách License vượt100; lọc/format với tên dài, thiếu optional field và nhiều UUID. | Có cách locate tài nguyên và phân biệt loading; không cắt mất thông tin ra quyết định; đo trước khi đặt SLO. | Applications/Plans lấy toàn list; License top100. Đây là khả năng vận hành/scale cần fixtures, chưa có số đo latency hoặc bug layout runtime. S02, S11, S13, S17. |

## 5. Bộ test nên làm trước

Thứ tự đề xuất không đồng nghĩa user đã cho phép implement:

1. **Data integrity:** APP-03/12, LIC-04/09; PostgreSQL thật, separate requests/transactions, kiểm tra sau commit.
2. **Entitlement policy:** PLN-09/10, LIC-06/07/11; chốt policy trước expected cuối cùng.
3. **Admin vận hành:** APP-01/07, LIC-01/05/10/12; UI mock + backend integration/fault injection phù hợp từng case.
4. **Validation:** APP-04/09, PLN-01…06, LIC-03/13; test native form và controller riêng.
5. **Recovery và stale state:** APP-05/08/10, PLN-08/11/12, LIC-08, COM-01…06.

Fixtures tối thiểu: 3 trạng thái application; 2 family × 3 trạng thái plan; 4 trạng thái code; mã hết timestamp nhưng vẫnISSUED; codeREDEEMED có subscription và capacity code nếu được phép; sessionsSCHEDULED/OPEN/CLOSED; >100 mã; 2 PLATFORM_ADMIN và2 tenantHOST_ADMIN riêng biệt.

Test không được dùng approve/revoke thật trên production. Unit mock chỉ chứng minh logic nhánh; test transaction phải commit thật rồi đọc bằng transaction mới, không assert persistence từ object đang nằm trong persistence context. Fault injection trước/sau commit cần ghi rõ điểm xảy ra lỗi.

## 6. Những việc không nên gọi nhầm là unhappy case/bug

- ARCHIVED không sửa/activate được: chặn cố ý, expected của lifecycle.
- Mã đãredeem không redeem lại được: bảo vệ single-use, không phải lỗi.
- Subscription đãtồn tại giữ expiry/cap sau sửa plan: snapshot ở activation là chủ ý hiện tại; khác câu hỏi snapshot code lúcissue.
- Cùng email ở hai tenant khác nhau không tự động là duplicate identity: `createHostAdmin` tạo identity tenant-scoped.
- Code expiry khác subscription expiry: code hết hạn ngăn redeem, không tự rút ngắn subscription đãkích hoạt.
- Không có ACTIVE exam package thực sự thì không issue được ở UI là hợp lý; không hợp lý khi lỗi tải bị biểu diễn giống trường hợp này.
- Full token visible cho authorized admin là câu hỏi hardening; không tự chứng minh privilege leak.

## 7. Căn cứ code hiện tại

Đường dẫn tương đối vượt từ docs repo sang web/api repo cùng workspace; các ID nguồn dùng xuyên suốt ma trận.

| Nguồn | File / vị trí nên xem |
|---|---|
| S01 | [AdminApplicationDetailView.tsx](../../../../pte-web/apps/vendor-web/features/commercialization/components/AdminApplicationDetailView.tsx): query dòng17, NOT_FOUND38, review47–52, disabled98–105. |
| S02 | [AdminApplicationsView.tsx](../../../../pte-web/apps/vendor-web/features/commercialization/components/AdminApplicationsView.tsx): error, stats, default[], empty state. |
| S03 | [commercialization/api.ts](../../../../pte-web/apps/vendor-web/features/commercialization/api.ts): queries/mutations và onSuccess invalidation; [applications client](../../../../pte-web/packages/api-client/src/requests/billing/applications.ts): không gọi GET một application. |
| S04 | [TenantApplicationService.java](../../../../pte-api/app/src/main/java/com/pte/billing/internal/service/TenantApplicationService.java): submit59+, approve104+, reject124+, findPending134+; [controller](../../../../pte-api/app/src/main/java/com/pte/billing/internal/controller/TenantApplicationController.java). |
| S05 | [TenantApplication.java](../../../../pte-api/app/src/main/java/com/pte/billing/domain/TenantApplication.java), [Plan.java](../../../../pte-api/app/src/main/java/com/pte/billing/domain/Plan.java), [BaseEntity.java](../../../../pte-api/app/src/main/java/com/pte/shared/domain/BaseEntity.java): trường trạng thái, review metadata, không optimistic version. |
| S06 | [RejectApplicationRequest.java](../../../../pte-api/app/src/main/java/com/pte/billing/internal/dto/request/RejectApplicationRequest.java), [SubmitApplicationRequest.java](../../../../pte-api/app/src/main/java/com/pte/billing/internal/dto/request/SubmitApplicationRequest.java). |
| S07 | [V21 application schema](../../../../pte-api/app/src/main/resources/db/migration/V21__billing_tenant_application.sql), [V22 plan schema](../../../../pte-api/app/src/main/resources/db/migration/V22__billing_plan_catalog.sql). |
| S08 | [TenantLifecycleService.java](../../../../pte-api/app/src/main/java/com/pte/tenancy/internal/service/TenantLifecycleService.java): createFromApplication64+, name/code/tax uniqueness; [IdentityService.java](../../../../pte-api/app/src/main/java/com/pte/identity/IdentityService.java): createHostAdmin154+. |
| S09 | [TenantApplicationNotificationListener.java](../../../../pte-api/app/src/main/java/com/pte/notification/internal/listener/TenantApplicationNotificationListener.java): AFTER_COMMIT, approved46+; [NotificationDispatchService.java](../../../../pte-api/app/src/main/java/com/pte/notification/internal/service/NotificationDispatchService.java): REQUIRES_NEW, RabbitMQ enqueue. |
| S10 | [commercialization/constants.ts](../../../../pte-web/apps/vendor-web/features/commercialization/constants.ts): APPROVED, ARCHIVE_CONFIRM_DESCRIPTION, REVOKE_DESCRIPTION, REVOKE_REASON. |
| S11 | [PlanCatalogView.tsx](../../../../pte-web/apps/vendor-web/features/commercialization/components/PlanCatalogView.tsx): clamp57+, errors84+, reset109+, save124+, transition144+, modal187+, form208+. |
| S12 | [PlanService.java](../../../../pte-api/app/src/main/java/com/pte/billing/internal/service/PlanService.java): update62+, lifecycle76+, apply101+, validate122+; [PlanRequest.java](../../../../pte-api/app/src/main/java/com/pte/billing/internal/dto/request/PlanRequest.java). |
| S13 | [LicenseCodesView.tsx](../../../../pte-web/apps/vendor-web/features/commercialization/components/LicenseCodesView.tsx): plansquery31, eligible38+, issue51+, reason64, ISSUED action140+. |
| S14 | [LicenseCodeService.java](../../../../pte-api/app/src/main/java/com/pte/billing/internal/service/LicenseCodeService.java): issue65+, list103, redeem109+, liveplan123, revoke150+, failures188+; [LicenseCodePersistenceService.java](../../../../pte-api/app/src/main/java/com/pte/billing/internal/service/LicenseCodePersistenceService.java). |
| S15 | [SubscriptionActivationService.java](../../../../pte-api/app/src/main/java/com/pte/billing/internal/service/SubscriptionActivationService.java): quota52+, expiry61, snapshot85+, ACTIVE120+. |
| S16 | [IssueLicenseCodeRequest.java](../../../../pte-api/app/src/main/java/com/pte/billing/internal/dto/request/IssueLicenseCodeRequest.java), [RevokeLicenseCodeRequest.java](../../../../pte-api/app/src/main/java/com/pte/billing/internal/dto/request/RevokeLicenseCodeRequest.java). |
| S17 | [LicenseCodeRepository.java](../../../../pte-api/app/src/main/java/com/pte/billing/internal/repository/LicenseCodeRepository.java): lock, top10026, atomic redeem28+, expire45+; [LicenseCodeExpirationService.java](../../../../pte-api/app/src/main/java/com/pte/billing/internal/service/LicenseCodeExpirationService.java). |
| S18 | [SubscriptionRevokedSessionListener.java](../../../../pte-api/app/src/main/java/com/pte/session/internal/listener/SubscriptionRevokedSessionListener.java): AFTER_COMMIT19+; [SessionLifecycleService.java](../../../../pte-api/app/src/main/java/com/pte/session/internal/service/SessionLifecycleService.java): cancelScheduled270+. |
| S19 | [Modal.tsx](../../../../pte-web/packages/ui/src/components/Modal.tsx): Escape50 và X87; [ConfirmDialog.tsx](../../../../pte-web/packages/ui/src/components/ConfirmDialog.tsx): Cancel37; [Button.tsx](../../../../pte-web/packages/ui/src/components/Button.tsx): loading disable56. |
| S20 | [GlobalExceptionHandler.java](../../../../pte-api/app/src/main/java/com/pte/shared/exception/GlobalExceptionHandler.java): DTO validation44+, malformed64+, forbidden72+, fallback50082+. |
| S21 | [TenantApplicationServiceTest.java](../../../../pte-api/app/src/test/java/com/pte/billing/internal/service/TenantApplicationServiceTest.java), [PlanServiceTest.java](../../../../pte-api/app/src/test/java/com/pte/billing/internal/service/PlanServiceTest.java), [LicenseCodeServiceTest.java](../../../../pte-api/app/src/test/java/com/pte/billing/internal/service/LicenseCodeServiceTest.java). |
| S22 | [PlanController.java](../../../../pte-api/app/src/main/java/com/pte/billing/internal/controller/PlanController.java), [LicenseCodeController.java](../../../../pte-api/app/src/main/java/com/pte/billing/internal/controller/LicenseCodeController.java), [TenantApplicationController.java](../../../../pte-api/app/src/main/java/com/pte/billing/internal/controller/TenantApplicationController.java): PreAuthorize và route hiện tại. |

## 8. Kiểm tra đã thực hiện

```powershell
# cwd: D:\GitHub\pte-org\pte-api
.\mvnw.cmd -pl app '-Dtest=TenantApplicationServiceTest,PlanServiceTest,LicenseCodeServiceTest' test
```

Ngày 2026-10-05: BUILD SUCCESS; Application11 + Plan7 + License9 = **27 tests; 0 failures, 0 errors, 0 skipped**.

Có Mockito dynamic-agent warning, không làm fail test. Các suite dùng mock dependencies; không chạy database concurrency, SMTP delivery, cancellation AFTER_COMMIT với commit thật hoặc browser test. Không gán trạng thái Passed cho 45 case mới dựa vào kết quả này.

Tài liệu kế hoạch đã tham chiếu để hiểu ngữ cảnh: `quang-tenant-commercialization` phases02/03/06 và `quang-web-billing-integration` phases03/04. Một số nội dung cũ như trả password cho admin đã khác code hiện tại; báo cáo không dùng chúng làm hợp đồng API hiện hành.
