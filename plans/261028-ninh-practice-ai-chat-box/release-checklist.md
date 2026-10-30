# Release checklist: chat box AI (task 76)

**Cập nhật:** 2026-10-29 · Đánh dấu `[x]` khi đã làm và có bằng chứng; mục **bắt buộc** chặn release nếu chưa xong. Không có bước git trong plan: bạn tự commit và push.

## A. Đã xong trong code (bằng chứng ở báo cáo test và quality của từng phase)

- [x] Backend: module `chat` (Flyway V7, quota upsert nguyên tử, phiên, cache, endpoint). Toàn module backend 3794 test, 0 lỗi (59 bỏ qua là các test cần dịch vụ thật có từ trước và bộ test prompt cần key), gồm test Postgres thật (Testcontainers) cho quota đồng thời, IDOR phiên, hoàn quota theo ngày đã trừ và test tải mô hình ~70 request/phút. Chi tiết ở [tests/phase-05-test-report.md](./tests/phase-05-test-report.md).
- [x] Frontend: `features/chat` (hộp chat nhỏ nổi, markdown an toàn, "Đoạn chat mới", cảnh báo ≤ 3 lượt, khoá khi hết lượt kèm giờ reset, cờ `NEXT_PUBLIC_CHAT_ENABLED`). 560 test, `typecheck` sạch, `lint` không lỗi mới, `npm run build` chạy được.
- [x] Đường deploy Docker chuyển tiếp biến `CHAT_AI_*` và `NEXT_PUBLIC_CHAT_ENABLED` (mặc định tắt); chưa kiểm bằng một lần deploy thật.
- [x] Quality gate từng phase có receipt trong `quality/`.

## B. Bắt buộc trước khi bật ở production

- [ ] **Key Gemini trả phí** (Cloud Project có billing) cho chat, **không** dùng key free. Người làm: Tech Lead/PM.
- [ ] **`PRACTICE_STRICT_ENTITLEMENT_ENABLED=true`** ở môi trường chạy chat (mặc định `false` làm mọi student nhận 403).
- [ ] `CHAT_AI_ENABLED=true`, `CHAT_AI_MODEL` ghim `gemini-2.5-flash-lite` (không `-latest`), `CHAT_AI_DAILY_LIMIT` đúng chính sách (mặc định 20).
- [ ] **Budget alert** đã bật trên Cloud Billing; bảng RPM/TPM trong [ops-runbook.md](./ops-runbook.md) đã điền.
- [ ] **Bằng chứng đồng thời trên Postgres** (đã có một lần chạy xanh ngày 2026-10-29 với Docker, xem [tests/phase-05-test-report.md](./tests/phase-05-test-report.md); chạy lại trên máy release và đính kèm): chạy `./mvnw -pl app test -Dtest='ChatQuotaRepositoryPostgresTest,ChatServiceConcurrencyPostgresTest,ChatLoadPostgresTest'` với Docker và đính kèm kết quả xanh. Nếu máy không có Docker thì chạy kịch bản `psql` đồng thời thủ công (nhiều phiên cùng `INSERT ... ON CONFLICT` với `limit` nhỏ, kiểm đúng số thành công và 1 dòng `chat_usage` mỗi ngày) và ghi lại lệnh cùng kết quả.
- [ ] **Chạy bộ test prompt với Gemini thật** (cần key, cách chạy ở [prompt-test-suite.md](./prompt-test-suite.md), kết quả test ở [phase-05-test-report.md](./tests/phase-05-test-report.md)): mỗi ca 3 lần, cả 3 lần đạt; không còn câu trả lời `MAX_TOKENS`; ghi `max-tokens` chốt và số đo token thật. Chưa chạy vì phiên làm việc không có key.
- [ ] **Pháp lý duyệt** disclaimer VI/EN và đoạn Privacy Policy/ToS, trả lời các đề xuất trong [legal-review-request.md](./legal-review-request.md) ([privacy-handoff.md](./privacy-handoff.md)); xác nhận thời hạn lưu. Chưa duyệt thì không bật.
- [x] **Hồ sơ đánh giá chuyển dữ liệu cá nhân ra nước ngoài** (gửi câu hỏi tới Google): **quyết định 2026-10-29 của người phụ trách (PM): không nộp (hướng B)**, dựa trên lập luận hệ thống không gửi mã định danh nào tới Google. Rủi ro được chấp nhận có chủ đích; xem [legal-review-request.md](./legal-review-request.md) mục 4.6 để biết lập luận, các biện pháp giảm rủi ro đã có và điều kiện xem lại. Chưa kiểm văn bản gốc của luật.
- [x] Ô đồng ý trước lần dùng đầu (V8 `chat_consent`), ẩn danh sau 12 tháng và không cache câu hỏi dài/có email/số điện thoại: **đã làm và có test** (xem mục 2b, 4.1, 4.3, 4.5 của [legal-review-request.md](./legal-review-request.md)). Pháp lý vẫn cần duyệt câu chữ màn đồng ý. Nút "Rút lại đồng ý" và "Xoá các đoạn chat của tôi" **đã có** trong panel (xem [next-steps-plan.md](./next-steps-plan.md)); riêng học viên chưa có quyền luyện tập không thấy panel nên vẫn phải gửi yêu cầu qua email.
- [x] Trang Chính sách bảo mật `/privacy` (VI/EN, công khai, không cần đăng nhập) và liên kết từ màn đồng ý: **đã làm** (`features/privacy/`). Còn phải làm trước khi release: (a) người có thẩm quyền đọc và duyệt toàn bộ chữ, đặc biệt các mục ngoài chat (dữ liệu thu thập, thời hạn lưu dữ liệu luyện tập khác, chia sẻ với tổ chức) vì mình soạn theo những gì thấy hệ thống làm; (b) thay `PRIVACY_CONTACT_EMAIL` (đang là email cá nhân `leninh2004@gmail.com`) bằng hộp thư dùng chung của dịch vụ; (c) xác nhận tên `PTE Prep` có đúng là pháp nhân vận hành.
- [ ] Kiểm tay màn đồng ý với backend thật: học viên mới thấy màn đồng ý, tick rồi bấm mới chat được, tải lại không hỏi lại, đổi `CONSENT_POLICY_VERSION` ở cả hai phía thì hỏi lại.
- [ ] Kiểm tay các việc thêm sau review với backend thật: học viên chưa mở khoá luyện tập **không thấy** nút chat; "Rút lại đồng ý" đưa về màn đồng ý; "Xoá các đoạn chat của tôi" làm panel trống và lượt hôm nay không đổi; gọi `GET /api/v1/admin/chat/usage` bằng token `PLATFORM_ADMIN` trả số liệu đúng, bằng token khác trả 403.
- [x] Màn hình báo cáo chi phí trên admin web (`pte-web`, trang `/admin/chat-usage`): đã làm, xem [next-steps-plan.md](./next-steps-plan.md) mục 2.1. Còn phải kiểm tay với backend thật bằng tài khoản `PLATFORM_ADMIN`: menu System có mục "Mức dùng chat AI", số liệu khớp câu SQL trong runbook, tài khoản không phải platform admin không thấy mục này, và khi backend tắt chat thì trang hiện thông báo lỗi dễ hiểu (không lộ mã lỗi).
- [ ] Quyết định có làm câu trả lời hiện dần (streaming) không và khi nào: xem [next-steps-plan.md](./next-steps-plan.md) mục 2.2.
- [ ] Kiểm tay end-to-end trên trình duyệt với backend thật: hết lượt (0), cảnh báo ≤ 3, tải lại giữ đúng phiên, "Đoạn chat mới", màn hẹp, hai tab cùng gửi (409), student khác không đọc được `session_id` của bạn, task Speaking và task có đồng hồ không bị ảnh hưởng.
- [ ] Hẹn 15 phút với UI/UX Designer chốt vị trí tab chat và bề rộng panel ([ui-improvements-plan.md](./ui-improvements-plan.md)).
- [ ] Web build với `NEXT_PUBLIC_CHAT_ENABLED=true` **sau** khi backend đã bật và `GET /api/v1/student/chat/quota` trả 200.

## C. Nên làm

- [ ] Chạy `npm audit` / nâng cấp Next.js: `next@16.4.0` hiện báo có lỗ hổng bảo mật đã biết khi build (ngoài phạm vi task này, cần quyết định riêng).
- [ ] Quyết định có cần lớp phòng thủ cho thân request lớn (không có giới hạn kích thước JSON toàn repo); chat đã chặn 1000 ký tự ở service.
- [ ] Đồng bộ `pnpm-lock.yaml` nếu team dùng pnpm (chỉ `package-lock.json` được cập nhật).
- [x] Xoá dữ liệu theo thời hạn lưu (tác vụ đêm `ChatRetentionService`, 12 tháng/30 ngày, cấu hình `CHAT_AI_RETENTION_*`) và theo yêu cầu học viên (script SQL trong [ops-runbook.md](./ops-runbook.md)). Xem [privacy-handoff.md](./privacy-handoff.md) mục 5.
- [ ] Kiểm tay bằng trình duyệt các cải thiện giao diện U1 đến U10 ([ui-improvements-plan.md](./ui-improvements-plan.md)): huy hiệu lượt, chip gợi ý, nút sao chép, bẫy focus ở màn hẹp, phím tắt `Ctrl+/`.

## D. Rollback

Cờ web là build-time nên bước chậm nhất là build lại image `web-practice`; bắt đầu bước 2 **trước hoặc song song** với bước 1. Trong lúc web chưa build xong, học viên mở panel sẽ thấy thông báo lỗi nhưng bài làm không bị ảnh hưởng.

1. Backend: `CHAT_AI_ENABLED=false` và khởi động lại (bean chat biến mất, schema V7 giữ nguyên, không cần migrate ngược).
2. Web: build lại với `NEXT_PUBLIC_CHAT_ENABLED=false` (hoặc bỏ biến): panel biến mất, trang luyện tập như trước.
3. Dữ liệu chat đã lưu giữ nguyên cho đến khi có quyết định xoá.

## E. Theo dõi 48 giờ đầu

- `chat.quota.refunded` theo `cause` (tăng bất thường = lạm dụng hoặc lỗi provider); `chat.quota.refund.failed` phải bằng 0.
- Tỉ lệ dòng FAILED theo `finish_reason` (MAX_TOKENS cao: tăng `max-tokens` hoặc siết prompt).
- `chat.slot.rejected` và `chat.inflight.rejected` (503 và 409), tỉ lệ cache hit, chi phí token theo ngày so với ước tính 105 đến 510 USD/tháng.
- Phản hồi học viên về câu từ chối oan (hỏi đúng chủ đề tiếng Anh mà bị từ chối): sửa `ChatPrompts` và tăng `VERSION`.
