# Phase 3: BE chat service + endpoints

**Repo:** `pte-api` · **Ước lượng:** 3–4 ngày · **Phủ:** FR-02, FR-04, FR-07, P1 (quota, đồng thời, lỗi/hoàn quota, 429/409), P2 (phiên, lịch sử, cache), NFR-01, NFR-02, NFR-04

## Requirements
Student gửi một tin và nhận câu trả lời markdown kèm `remaining/limit/resetAt`; xem được trạng thái quota; nạp lại phiên gần nhất cùng lịch sử. Quota đúng khi chạy đồng thời và khi lỗi; phiên chống IDOR; cache không tốn quota.

## Design Constraints
- Quota chỉ đổi qua câu UPSERT nguyên tử trong DB; không đếm trong bộ nhớ, không đọc-rồi-ghi. Không giữ transaction DB mở qua lời gọi Gemini.
- Server là nguồn sự thật: ngày (qua `Clock` inject, `vnClock = clock.withZone(ZONE)` gán trong constructor, không đăng ký bean `Clock` thứ hai), `resetAt`, phiên có rỗng không, lịch sử 6 tin — tất cả do server tính; không tin `session_id`/lịch sử/cờ từ client ngoài việc đề xuất UUID và kiểm tra quyền sở hữu.
- Không ghi `chat_session` trước khi trừ quota thành công; trước đó chỉ SELECT để kiểm tra chủ phiên.
- Không retry; mọi lỗi provider/JSON hỏng/off-topic/lỗi lưu tin đều hoàn quota đúng `usage_date` đã trừ; cache hit không trừ quota. Hoàn quota chạy trong `try/catch` riêng; khoá và semaphore nhả trong `finally` sau khi hoàn quota, ở mọi nhánh.
- Ghi cache là best-effort (`ON CONFLICT DO NOTHING`, nuốt exception, log); không bao giờ làm hỏng response.
- `taskType` đi vào prompt nên chỉ nhận giá trị thuộc enum whitelist; mọi giá trị khác bị từ chối 400.
- Không log câu hỏi/câu trả lời; không trả thân lỗi của provider cho client.
- Lỗi dùng `DomainException` + `GlobalExceptionHandler` hiện có (không sửa handler); 429 mang `data` (`resetAt`, `limit`, `remaining`) qua hàm tạo có `data`.
- Mọi bean của phase này (service, quota, gate, cache, controller) gắn điều kiện `chat.ai.enabled=true`; `@PreAuthorize("hasRole('STUDENT')")`; tuân thủ ≤ 15 class mỗi package và ≤ 300 dòng mỗi file (chia `service/quota`, `service/session`, `service/cache`...).

## Steps
1. Dựng tầng quota: trừ quota bằng một câu UPSERT trả 0 dòng khi hết lượt (qua JDBC, transaction ngắn riêng), hoàn quota có chặn không âm theo đúng ngày đã trừ, đọc trạng thái quota (`used`, `remaining`, `limit`, `resetAt` = 00:00 ngày kế giờ VN). Ngày lấy bằng `LocalDate.now(vnClock)` với `vnClock` gán trong constructor từ `Clock` inject (tên biến kết thúc bằng "clock" để qua `NoDirectClockAccessTest`); không thêm bean `Clock` mới.
2. Dựng cổng đồng thời: tập khoá "đang xử lý" theo student (chiếm được thì tiếp, không thì 409) và `Semaphore` toàn hệ thống theo cấu hình (mặc định 20, `tryAcquire` không chờ; đầy thì 503 trước khi trừ quota). Ghi chú giả định một instance trong code và tài liệu (Open Decision b).
3. Dựng tầng phiên và lịch sử: trước khi trừ quota chỉ SELECT chủ phiên (phiên tồn tại mà khác student → 404); **sau khi trừ quota thành công** chèn `chat_session` bằng `ON CONFLICT DO NOTHING` rồi kiểm lại chủ phiên (lệch → hoàn quota + 404). Đếm phiên rỗng và nạp tối đa `history-size`=6 tin gần nhất của đúng phiên đó từ DB, chỉ tính `status=OK` (REFUSED/FAILED bị loại). "Phiên gần nhất" = phiên có tin nhắn mới nhất (mọi status); endpoint trả `session_id` đó cùng danh sách `OK`+`REFUSED` để hiển thị (có giới hạn số tin); nếu student chưa có phiên nào thì trả rỗng để client tự sinh UUID đầu tiên.
4. Dựng cache: chuẩn hoá câu hỏi (NFKC, trim, gộp khoảng trắng, lowercase), băm cùng ngôn ngữ + task type + phiên bản system prompt; chỉ tra khi phiên rỗng; chỉ ghi câu trả lời `is_on_topic=true` đã qua validate và sau khi tin `OK` đã lưu; ghi best-effort (`ON CONFLICT DO NOTHING`, nuốt exception); hit lưu tin `OK` với `from_cache=true`, token 0, không trừ quota.
5. Dựng luồng `ChatService` theo AD-06: entitlement (cổng từ Phase 1) → validate (độ dài ≤ 1000 ký tự sau trim, không rỗng, `session_id` là UUID v4, `taskType` thuộc enum whitelist, ngôn ngữ ∈ {vi,en} dạng gợi ý) → SELECT chủ phiên → khoá user → cache → semaphore → trừ quota → chèn phiên + kiểm lại chủ → gọi client Phase 2 → xử lý kết quả: hợp lệ on-topic thì lưu tin `OK` rồi ghi cache nếu phiên rỗng; off-topic thì hoàn quota, lưu tin `REFUSED` (`on_topic=false`), trả câu từ chối cố định; lỗi provider/JSON hỏng thì hoàn quota, lưu tin `FAILED` (answer rỗng + `finish_reason` + token, lưu best-effort) và trả 503. Nếu không lưu được tin `OK` sau khi đã có câu trả lời tốt → hoàn quota + 503. Response luôn tính `remaining`/`resetAt` theo **ngày đã trừ**. Lưu `finishReason`, token vào/ra/thinking, model, phiên bản prompt. Mỗi thao tác DB trong transaction ngắn riêng; hoàn quota trong `try/catch` riêng, khoá + semaphore nhả trong `finally` sau đó.
6. Dựng controller và DTO: gửi tin, đọc quota, nạp phiên gần nhất (đường dẫn chốt theo hằng số, gợi ý `/api/v1/student/chat/...`, thống nhất với FE ở bước 2 Phase 4). Request validate bằng Bean Validation; response luôn có `remaining`, `limit`, `resetAt`, `onTopic`, `fromCache`. Định nghĩa lỗi: 429 `CHAT_QUOTA_EXCEEDED` (kèm `resetAt`), 409 `CHAT_REQUEST_IN_FLIGHT`, 503 `CHAT_BUSY` (provider/semaphore/lỗi lưu tin), 400 độ dài/định dạng/`taskType` ngoài whitelist, 404 phiên không thuộc về mình, 403 từ entitlement. Có `userMessage` cho từng lỗi để FE hiển thị.
7. Quan sát được: bộ đếm (số tin theo status, cache hit, **số lần hoàn quota** có cảnh báo khi tăng bất thường, lỗi provider theo loại, semaphore đầy, 409) theo mẫu `PracticeObservability`; cảnh báo log khi chạy mà `daily-limit`/model không hợp lệ.
8. Viết test: unit cho chuẩn hoá cache/khoá cache, tính `resetAt`, thứ tự hoàn quota → nhả khoá, whitelist `taskType`; test xác định trong CI (fake client, không cần Docker) cho đường `is_on_topic=false` → hoàn quota + câu từ chối cố định + tin `REFUSED`; test tích hợp trên hồ sơ Postgres (Open Decision e, Flyway bật + `@DynamicPropertySource`) cho: hai request song song `limit=1`, N luồng `limit=20`, một dòng `chat_usage` mỗi ngày, hoàn quota không âm, hoàn quota vắt nửa đêm, `session_id` của người khác (kể cả hai request tranh chấp cùng `session_id`: không để rác `chat_session`), lịch sử 6 tin chỉ tính `OK`, cache hit không trừ quota, lỗi ghi cache không phá response, lỗi lưu tin → hoàn quota + 503, mỗi kịch bản lỗi hoàn quota và chỉ 1 lần gọi fake client, 409 khi gửi chồng, 503 khi semaphore đầy; test controller/`@WebMvcTest` cho mã lỗi và dạng JSON của 429. Nếu không có Docker, các test Postgres bị bỏ qua và phải thay bằng lần chạy `psql` thủ công có ghi lại ở Phase 5 (cổng bắt buộc).

## Files
- `pte-api/app/src/main/java/com/pte/chat/internal/controller/ChatController.java` — 3 endpoint
- `pte-api/app/src/main/java/com/pte/chat/internal/service/ChatService.java` — điều phối luồng
- `pte-api/app/src/main/java/com/pte/chat/internal/service/quota/` — quota UPSERT/hoàn/trạng thái
- `pte-api/app/src/main/java/com/pte/chat/internal/service/session/` — phiên + lịch sử + gate đồng thời
- `pte-api/app/src/main/java/com/pte/chat/internal/service/cache/` — chuẩn hoá + khoá + lưu cache
- `pte-api/app/src/main/java/com/pte/chat/internal/dto/{request,response}/` — DTO
- `pte-api/app/src/main/java/com/pte/chat/internal/exception/` — các `DomainException` của chat
- `pte-api/app/src/main/java/com/pte/chat/internal/repository/` — repository phiên/tin/cache
- `pte-api/app/src/test/java/com/pte/chat/**` — unit + tích hợp Postgres

## Success Criteria
- `./mvnw test` xanh cho module `chat`, kể cả `ModuleStructureTest` và ba bài kiểm tra kiến trúc.
- Test song song: `limit=1` + 2 request → đúng 1 thành công, 1 nhận 429; `limit=20` + 50 luồng → đúng 20 thành công; `chat_usage` đúng 1 dòng/student/ngày.
- Mỗi lỗi (timeout, 429, 5xx, JSON hỏng, `MAX_TOKENS`, off-topic, lỗi lưu tin) → `used` trở lại giá trị trước; số lần gọi fake = 1; tin FAILED/REFUSED có đúng `status`, không vào lịch sử và không làm phiên "không rỗng".
- Test CI xác định (fake client) pass: off-topic → hoàn quota + câu từ chối cố định.
- 429 có body chứa `resetAt`, `limit`, `remaining=0`; 409 và 503 có mã lỗi ổn định; student khác dùng `session_id` không đọc/ghi được; request bị từ chối/hết lượt không để lại dòng `chat_session`.
- Cache: hit lần 2 cho cùng câu hỏi trong phiên rỗng, `from_cache=true`, `used` không đổi; phiên đã có tin `OK` thì không tra cache.
- `curl` thủ công với key thử **và `practice.strict-entitlement.enabled=true`** (mặc định `false` sẽ trả 403): một tin on-topic, một tin off-topic (được hoàn lượt), quota khớp giữa response và endpoint trạng thái.

## Quality and Testing State
- Quality gate: approved after one remediation round (report: plans/261028-ninh-practice-ai-chat-box/quality/phase-03-be-chat-service-endpoints-quality-report.json; receipt: plans/261028-ninh-practice-ai-chat-box/quality/phase-03-be-chat-service-endpoints-receipt.json; 0 blocking, 6 LOW and 2 NOTED open). Fixed: unbounded free cache hits (daily cap), control-character validation, log safety, ChatService split. Accepted debt (pinned by locked tests): unused constructor dependencies, metric gaps, partial entity return type, package cycle.
- Testing: passed - report `plans/261028-ninh-practice-ai-chat-box/tests/phase-03-be-chat-service-endpoints-test-report.json`; plus quality-remediation tests (report `plans/261028-ninh-practice-ai-chat-box/tests/phase-03-be-chat-service-endpoints-remediation-test-report.json`: 160 new tests, 2 failing - ChatErrors cyclic-cause infinite loop, locked ChatDtoShapeTest conflicts with new @Size)

## Risks
- Lệch nửa đêm giữa lúc trừ và lúc hoàn: hoàn theo `usage_date` đã trừ, response tính theo ngày đã trừ, có test riêng.
- App sập giữa lúc đã trừ và chưa hoàn: user mất một lượt; chấp nhận ở mức 20 tin/ngày, ghi trong tài liệu vận hành.
- Lỗi hoàn quota che lỗi gốc hoặc làm rò khoá: hoàn quota trong `try/catch` riêng, nhả khoá/semaphore trong `finally`.
- Nhiều instance làm khoá/semaphore sai: ghi giả định (b); nâng cấp khoá TTL trong DB nếu scale.
- Số luồng servlet bị giữ tối đa ~20 giây × 20 slot: semaphore không chờ + timeout 20 giây giới hạn thiệt hại; xem lại khi có số đo tải thật ở Phase 5.
- `RateLimitFilter` toàn cục cũng trả 429 với dạng body khác: FE phân biệt bằng mã lỗi `CHAT_QUOTA_EXCEEDED`.
- Lượt hoàn quota/cache hit vẫn tốn token hoặc dòng DB mà không dùng quota: chỉ bị chặn bởi 1 request đang xử lý/user + `RateLimitFilter`; đã có metric đếm hoàn quota, giới hạn số lần hoàn mỗi ngày là câu hỏi mở.
- Entity/DTO lớn làm vượt giới hạn 15 class hoặc 300 dòng: chia sub-package ngay từ đầu.
