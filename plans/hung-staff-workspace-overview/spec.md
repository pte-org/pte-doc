# Spec: Tổng quan công việc Proctor và Examiner

Date: 2026-10-12. Status: Approved product direction; time and count scope validated by user.

## Problem statement

Trang phân công Proctor và queue Examiner đã tồn tại, nhưng chưa cho biết ngay công việc ưu tiên và khối lượng toàn bộ phân công. Nâng cấp hai trang đó, giữ tenant shell và các luồng thao tác đang có.

## User stories

- P1 Proctor: thấy ca có thể giám sát, ca sắp tới và lịch hôm nay; vào đúng phòng từ một CTA trên danh sách.
- P1 Examiner: thấy số bài chưa bắt đầu, đang chấm và đã chốt trên toàn bộ queue được phép xem; tiếp tục bài đang chấm mà không phải tìm qua mọi trang.
- P1 Examiner: phân biệt chờ Host chuẩn bị cohort và đủ điều kiện chấm; AI chưa có điểm không được thể hiện như lý do cấm chấm thủ công.
- P1 Actor: các thẻ, danh sách và deep link chỉ thuộc tenant/phân công hiện tại; chuyển actor không hiện cache của người trước.
- P2: filter/page lưu qua URL và responsive/locale vi-en đầy đủ trên hai trang.
- P3 outside MVP: biểu đồ lịch sử, ranking, tenant-wide metrics, deadline/AI confidence, reopen quyết định.

## Product layout

- Proctor `/proctor/sessions`: 3 thẻ “Có thể giám sát”, “Ca sắp tới”, “Ca hôm nay”; lịch hôm nay và danh sách phân công phân trang. Tối đa 5 ca ưu tiên, lấy server-side, không từ trang bảng. CTA chỉ bật khi role/assignment/status/window cho phép; backend vẫn là quyền quyết định.
- Examiner `/examiner/work`: 3 thẻ “Chưa bắt đầu”, “Đang chấm”, “Đã chốt”; tổng tiến độ câu đã chốt/câu phải chấm với mẫu số rõ; tối đa 5 bài ưu tiên (đang chấm có thể tiếp tục trước, rồi bài mới đủ điều kiện). Dòng trạng thái chờ Host/không đủ điều kiện, kèm lý do server. Các thẻ link vào filter hiện hữu, không tạo route dashboard mới.
- Danh sách chính giữ phân trang/filter và cách quay lại URL đã có. Không tự mở monitoring session, subscribe WebSocket, ký media hoặc tải answer detail khi hiển thị thẻ.

## Functional requirements

1. FR01: 2 read-only overview endpoints, DTO public an toàn, CurrentUser-derived actor/tenant; không nhận actor ID do client chọn.
2. FR02: aggregates server-side trên toàn tập được phép xem, bounded priority list≤5; không tải mọi page về client. Summary không phụ thuộc filter/page của bảng; tiêu đề nêu phạm vi.
3. FR03: Proctor dùng 1 asOf server instant và múi giờ trình duyệt. Client resolve IANA timezone qua Intl.DateTimeFormat, gửi timezone trong overview và filter TODAY; server validate bằng ZoneId, lỗi timezone trả400. “Có thể giám sát” = OPEN + opensAt≤asOf<closesAt + active assignment/session. “Sắp tới” = SCHEDULED/OPEN chưa tới opensAt, không gồm CLOSED/CANCELLED. “Hôm nay” = opensAt trong [dayStart,dayEnd) của timezone đó, không gồm cancelled/deleted; ca bắt đầu hôm qua không thuộc hôm nay dù còn diễn ra. Thẻ hôm nay có thể trùng hai thẻ kia; không hiển thị như ba phần loại trừ nhau.
4. FR04: Proctor lịch hôm nay/priority có sort ổn định: có thể vào trước, sắp bắt đầu tiếp, tie opensAt rồi publicId; không chỉ sort một page sau fetch. Giữ danh sách lịch sử riêng qua bảng/filter; không suy ra state session từ thời gian để ghi database.
5. FR05: Examiner counts dùng cùng visible-queue scope và công thức quyết định như danh sách chính: tenant/actor assignment active, unpublished, human decisions; published không nằm trong “Đã chốt” ở MVP. Không đếm AI rawScore là finalized. Tập assignment có scope tenant/actor/deleted chính xác; số score giữ cùng semantics queue hiện tại theo tenant/session/attempt, không âm thầm thêm predicate chỉ ở overview. Kiểm tra invariants owner/deleted của score và ghi anomaly riêng nếu có; không sửa policy/data trong feature này. Aggregate tránh join nhân bản. eligible0 vẫn COMPLETED theo queue nhưng không được mô tả là đã review hay có CTA chấm.
6. FR06: Trạng thái finalization read model bám permission detail đã có: MANUAL_EXAMINER cohort FROZEN/COMPLETED, member tồn tại không excluded, chưa publication, owned assignment. Chờ freeze, incompatible mode, excluded, published có reason rõ; không quảng cáo mọi PENDING là chấm được.
7. FR07: Waiting/progress là hai trục độc lập; ví dụ pending có thể chờ freeze. Priority và table labels diễn đạt rõ; không gọi đã chốt là đã công bố. “Tiếp tục chấm” không hứa khôi phục local draft sau reload; MVP chỉ tiếp tục bài còn câu chưa chốt.
8. FR08: AI availability không đi vào capability tổng quan. Không tạo lời nhận xét, student PII, answer key, fake tên ca, deadline hay model metadata.
9. FR09: frontend query keys gồm tenant+actor và scope/timezone nếu ảnh hưởng response. Session logout/account switch clears relevant caches; invalidation sau chốt điểm cập nhật overview và queue. 403/404/error hiển thị phù hợp, không biến lỗi thành count0.
10. FR10: Overview độc lập với bảng: overview lỗi không khóa bảng; bảng lỗi không tạo số liệu giả. Empty overview có 0 thật từ server; summary có updatedAt/asOf và refresh; không polling nền liên tục trong MVP.
11. FR11: Thẻ/filter dùng shared primitives và locale vi-en, light/dark semantic tokens; widths320/768/1024; số đếm/CTA có label đọc bằng keyboard/screen reader.
12. FR12: Không đổi auth default-route precedence, Examiner write/receipt/reviewVersion, Host publication, monitoring STOMP lifecycle; flag Proctor giữ nguyên trạng thái tắt/bật hiện hữu, không tự rollout.

## Proposed contract decisions

- GET `/api/v1/proctor-assignments/mine/overview?timezone={IANA}`: asOf, timezone, dayStart/dayEnd, counts, todaySessions bounded (or separately paginated list with TODAY filter and matching timezone), prioritySessions≤5. Do not claim the bounded list is the complete day schedule; show total and link to full today filter. Resolve timezone client-side before enabling the query; missing/invalid timezone returns controlled400 rather than silently using server timezone.
- GET `/api/v1/examiner/work/overview`: asOf, scope=`ASSIGNED_UNPUBLISHED`, pending/inProgress/completed counts, eligible/finalized answer totals, priorityItems≤5 with capability+blockingReason. Reuse safe queue item fields; no student/media/provider projection.
- Exact repository projection/envelope decided from research. Queue additive capability/sort fields may be necessary; reuse the read predicate rather than parallel incompatible policy.

## Non-functional constraints

- 0 mutations and 0 schema changes by default; add index migration only if measured query plan justifies it, never speculative.
- API counts from SQL aggregates; bounded data query volume independent of total assignment count, no per-item GET/detail/presign.
- Scale check plan: at least >1 page (e.g. 101 assignments) and cross-tenant/actor fixtures; page-size change must leave summary unchanged. No unmeasured latency/throughput claim.
- Day boundaries based on validated browser IANA ZoneId and server Clock, not client clock. Client cache includes timezone; SSR renders placeholder until client timezone resolves. Use next local midnight rather than adding24hours so DST is correct. Do not permanently cache the first timezone resolution across environment/timezone changes without re-evaluation on focus.

## Success criteria

- Exactly 3 overview cards per workspace; priority preview≤5 items and all CTAs open existing task routes.
- Visible Proctor page refreshes date-dependent overview/TODAY at the local midnight boundary; hidden page refreshes on focus after resolving timezone again. No repeated polling. List context supports independent rendering/refresh when overview fails.
- Summary stays identical for page0/page1 of a stable dataset, including assignments outside page0.
- 0 foreign tenant/actor items/count leakage in denied/read checks; 0 stale previous-actor cache on account switch.
- All manual readiness states agree with detail policy on representative cases; AI pending does not turn a permitted manual item into blocked.
- Today includes ca whose opensAt falls within that local day; a ca crossing midnight does not count in the next day's Today card, but remains in “Có thể giám sát” if permission/window allows. opensAt boundary includes, closesAt boundary excludes access CTA. Non-Vietnam/DST ZoneIds produce consistent date labels and server bounds.
- Published items excluded from Examiner queue overview; completed card explicitly says unpublished assigned work.
- No additional WebSocket or media/detail fan-out from overview; background polling disabled.
- Existing force-submit/finalize/publish behavior preserved; locale/layout/accessibility checks recorded, not assumed.

## Out of scope

New dashboard routes/sidebar duplication; Host analytics; charts/ranking; global history; AI bulk accept; local-draft persistence/recovery; Proctor rollout; deployment; production data repair.

## Validated decisions and execution state

User selected browser timezone, Today by start date (not overlap), and Examiner completed totals for unpublished assigned work. Prior no-test/no-quality preference remains recorded; plan verification is compile/typecheck/build only unless the user changes that choice. Acceptance scenarios remain requirements even when automated tests are skipped. Plan only; no product code written here.
