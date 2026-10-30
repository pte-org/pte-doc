# Host xem thử kỳ thi trên PTE App — kế hoạch triển khai
Ngày: 2026-10-29. Người yêu cầu: Quang.
Trạng thái: chỉ lập kế hoạch; chưa code, chưa discard, chưa thay DB.
Master: [plan.json](../quang-host-exam-app-preview/plan.json). 5 phase, 32 bước.

## Bộ bàn giao cho agent triển khai

Đọc theo thứ tự: [hướng dẫn triển khai chi tiết](../quang-host-exam-app-preview/quang-agent-handoff.md),
[bảng nghiệm thu](../quang-host-exam-app-preview/quang-acceptance-matrix.md),
[file manifest](../quang-host-exam-app-preview/quang-execution-file-manifest.md), rồi master và từng phase JSON.
Handoff là hợp đồng chi tiết đã rà source; các quyết định bên dưới được làm rõ ở đó.
Thông tin nguồn được kiểm tra ngày 2026-10-29, agent phải đối chiếu lại khi bắt đầu.

## Kết quả mong đợi
Host tạo đề thành công nhận thông báo ở chuông trên tenant-web. Đăng nhập PTE App bằng HOST_ADMIN, chọn kỳ thi và xem thử đúng snapshot, kể cả khi kỳ thi còn READY. App tự nhận diện host sau xác thực, không có toggle trên màn login. Preview không bật fullscreen, chống gian lận, chặn clipboard/shortcut/process, close/minimize guard hay gửi violations. Next có ở mọi dạng bài; Previous chỉ trong preview.

Student giữ luồng hiện có. Host không tạo attempt, không ghi danh, không lưu đáp án, không upload audio, không gọi chấm điểm hoặc trừ quota thi/chấm điểm. Đáp án giữ RAM; file ghi âm tạm trên máy phải dọn khi chuyển câu/thoát. Request tải đề/media vẫn dùng băng thông/request bình thường.

## Kết quả rà source
- App hiện chỉ nhận STUDENT qua lib/features/auth/domain/exam_access_policy.dart.
- API đã có SessionExamPreviewService + ExamPreviewResponse: tenant-scoped, snapshot immutable, strip đáp án, media URL TTL 300 giây. DTO hiện thiếu timing/runtime đầy đủ so với task renderer; cần bổ sung additive.
- ExamPublishService.generate tạo snapshot và chuyển DRAFT -> READY. Publish tiếp sang SCHEDULED. Preview không cần OPEN và không gọi các command này.
- App có ExamUiPreviewScreen offline và ApiMockExamPreviewScreen cho dev. Chỉ tái dùng presentation/adapter phù hợp, không đưa mock backend thành production.
- Thông báo chuông dùng InboxNotificationRequested, InboxAppendService và listener transactional; có dedup và target SESSION. Enum hiện chưa có loại preview-ready.
- Native enforcement còn có khâu bootstrap, device-check, exit guard, retry app-scoped; chỉ sửa một lệnh activateLockdown là chưa đủ.

## Phase 1 — preflight và discard trước code
1. Đọc đầy đủ AGENTS, CODING_STANDARDS_APP/API/WEB, TEST_SCENARIOS_IAM, API_RESPONSE_SETUP, COMMON_EXCEPTION_SETUP. Ghi baseline từng repo; xác nhận source mới nhất.
2. Chỉ sao lưu và discard nhóm flag tạm sau:
   - pte-app/README.md
   - pte-app/lib/core/config/app_config.dart
   - pte-app/lib/core/di/security_module.dart
   - pte-app/lib/core/security/lockdown_service.dart
   - pte-app/test/unit/core/security/lockdown_service_test.dart
   Diff hiện tại: 75 dòng thêm, 2 dòng xóa; tất cả phục vụ PTE_EXAM_SECURITY_ENABLED mặc định false và no-op enforcement.
   Nhóm này không cần cho giải pháp role/session mới. Lưu binary patch vào reports/assets/261029-quang-host-exam-app-preview-preflight trước restore. Kiểm diff ngay trước thao tác; nếu file có thay đổi mới khác nhóm này, không restore toàn file. Không reset toàn repo; không chạm pte-web/pte-api dirty changes.
3. Verify 5 file sạch, patch có thể phục hồi, chạy security test baseline. Chỉ sau đó bắt đầu implementation.
Lưu ý: discard source không đổi executable đang chạy; các build cũ cần rebuild.

## Phase 2 — API preview read-only
- HOST_ADMIN được list các kỳ thi trong tenant qua API hiện có và lấy snapshot preview sau server authorization. DRAFT chưa có snapshot hiển thị chưa sẵn sàng; READY/SCHEDULED/OPEN/CLOSED/CANCELLED có snapshot đều xem được.
- Runtime lấy từ frozen snapshot; timing hiện chưa có trong SnapshotContentResponse. Trích resolver read-only public dùng chung để giữ parity với ExamItemLoader (definition + TaskTimingConfig + audio duration), theo handoff §4. Không tự đoán số và không import attempt.internal vào session.
- Không lộ correctness, scoring metadata hoặc đáp án.
- Khi media URL hết hạn, lấy lại preview qua endpoint được bảo vệ; tải lười theo câu để giảm request. Không lưu payload đề vào DB của app.
- Không tạo bảng preview session nếu không cần: mode/session chỉ tồn tại local.
- Test 403 role sai, tenant isolation, snapshot consistency, không có writes/attempt/quota, URL refresh.
- API DTO bổ sung phải tương thích web; rà client schema và exhaustive mappings.

## Phase 3 — host vào app và trải nghiệm xem thử
- Auth route: HOST_ADMIN -> danh sách preview; STUDENT -> luồng thi; role khác -> access denied. Tài khoản đa role host+student mặc định preview; không dùng role host để miễn bảo mật cho student attempt.
- Màn chọn kỳ thi: tên, mã, status, nút xem thử khi có snapshot. Loading/empty/error/expired-session dùng common UI. Không thêm selector ở màn login.
- Dùng cùng renderer và layout bài thi, nhưng response controller riêng. Đảm bảo renderer dùng thực cho student và host không phân kỳ UI, tránh chỉ dùng component offline fixture.
- Preview có nhãn nhỏ để phân biệt. Next/Previous điều hướng local, không gọi navigate/submit attempt API. Không tự chuyển vì upload vì preview không upload; khi hết giờ chỉ kết thúc recording/audio theo runtime và host chủ động Next.
- Audio/recording dùng controller local. Khi Next trong lúc ghi/phát: cancel timer/listener, stop recorder/player, xóa file tạm, đổi câu một lần. Chống stale callback và double-click.
- Đáp án RAM chỉ tồn tại trong preview session (có thể giữ khi Previous trong cùng phiên); thoát/reload/logout xóa. Xóa file tạm thay vì giữ audio cũ khi quay lại.
- Khi app crash, chỉ dọn thư mục temp riêng của preview ở lần mở sau; không đụng audio/outbox student.
- Host không kích hoạt native security và violation pipeline. Logout/401/account switch phải dispose mode, player, recorder và khôi phục policy student. Không sửa backend auth chung cho phép host vào student endpoints.

## Phase 4 — thông báo chuông
- Trigger khi generate thành công lần đầu và READY đã có snapshot, không khi mới lưu draft hoặc chỉ toast FE. Trường hợp READY thành công nhưng publish lỗi vẫn được thông báo có đề để xem.
- Event do session module sở hữu, listener notification map sang inbox common; cùng transaction/durable theo pattern hiện có, không tự tạo delivery thứ hai.
- Người nhận là HOST_ADMIN thực hiện generate thành công, còn active trong đúng tenant. ExamSession hiện không có createdBy; không thêm creator field cho v1. Event key session + snapshot + actor, replay/retry không sinh trùng.
- Copy đề xuất: “Đề thi {name} đã sẵn sàng. Đăng nhập PTE App bằng tài khoản host, chọn kỳ thi {code} để xem thử. Bài làm thử không được lưu.”
- Chuông và lịch sử hiển thị loại mới, unread count cập nhật qua transport hiện có. Click mở exam detail trên web; không cần app deep link ở phiên bản đầu.
- Bổ sung enum/mapping/constants và bắt buộc migration mới vì baseline hiện có notifications_notification_type_check allowlist. Giữ đầy đủ giá trị cũ, thêm SESSION_PREVIEW_READY; lấy số version mới nhất tại lúc code, không sửa V1. Tái dùng indexes/dedup hiện có.
- API-client/shared web enum và i18n vi/en phải cùng hiểu loại notification mới.

## Phase 5 — kiểm chứng và bàn giao
- API: compile, full default suite, Postgres inbox integration và tenant/role guards.
- App: flutter analyze, relevant unit/widget tests, regression security tests; smoke Windows build/runtime.
- Web: typecheck, lint, notification enum/target tests và chuông thật.
- E2E local: tạo kỳ thi -> nhận chuông -> host login app -> mở READY -> thử đủ 22 task types -> Next khi đang audio/recording -> thoát -> login student.
- Chụp DB/network/quota trước/sau: session status/snapshot không đổi; attempts/answers/enrollments/media uploads không tăng; không request upload, submit, grading hay outbox writes; quota không giảm.
- Case biên: mic denied, audio lỗi/URL hết hạn, network mất, logout/401, host+student, role sai, đổi tenant, crash temp cleanup, Next cuối đề. Mic lỗi cho phép bỏ qua trong preview, thông báo gọn.
- Có báo cáo command/exit code/screenshot và checklist cho Quang tự test; ghi rõ kiểm nào chưa chạy. Không push/deploy/commit ngoài yêu cầu.

## Phạm vi UI và giả định đã chọn
Giữ bố cục Read Aloud theo ảnh Quang đã cung cấp; không gộp redesign UI vào feature này. Chỉ thêm danh sách chọn kỳ thi và nhãn preview/navigation cần thiết. Phiên đầu không có deep link, mã đăng nhập riêng, lưu tiến độ host, báo cáo host hay đánh giá AI. HOST_ADMIN là role source hiện có; không tự thêm HOST_STAFF. Chưa thay contract kiến trúc trước khi phase preflight kiểm tra.

## Ước lượng phạm vi
Độ phức tạp Hard: 3 repo ứng dụng + pte-doc. Dự kiến 25–40 file code/test/docs (ước lượng, không phải inventory đã chốt). Renderer adapter và session security là rủi ro lớn nhất; phải chốt file inventory chính xác sau preflight. Mọi phase hiện pending.
