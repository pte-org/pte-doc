# Phase 3: BE chat service + endpoints

**Repo:** `pte-api` · **Ước lượng:** 2–3 ngày · **Phủ:** FR-02, FR-04, FR-07, P1 (quota, đồng thời, lỗi/hoàn quota, 429/409), P2 (phiên, lịch sử, cache), NFR-01, NFR-02, NFR-04

## Requirements
Student gửi một tin và nhận câu trả lời markdown kèm `remaining/limit/resetAt`; xem được trạng thái quota; nạp lại phiên gần nhất cùng lịch sử. Quota đúng khi chạy đồng thời và khi lỗi; phiên chống IDOR; cache không tốn quota.

## Design Constraints
- Quota chỉ đổi qua câu UPSERT nguyên tử trong DB; không đếm trong bộ nhớ, không đọc-rồi-ghi. Không giữ transaction DB mở qua lời gọi Gemini.
- Server là nguồn sự thật: ngày (qua `Clock` múi `Asia/Ho_Chi_Minh`), `resetAt`, phiên có rỗng không, lịch sử 6 tin — tất cả do server tính; không tin `session_id`/lịch sử/cờ từ client ngoài việc đề xuất UUID và kiểm tra quyền sở hữu.
- Không retry; mọi lỗi provider/JSON hỏng/off-topic đều hoàn quota đúng `usage_date` đã trừ; cache hit không trừ quota. Nhả khoá và semaphore trong `finally` ở mọi nhánh.
- Không log câu hỏi/câu trả lời; không trả thân lỗi của provider cho client.
- Lỗi dùng `DomainException` + `GlobalExceptionHandler` hiện có (không sửa handler); 429 mang `data` (`resetAt`, `limit`, `remaining`) qua hàm tạo có `data`.
- Controller chỉ bật khi `chat.ai.enabled=true`, `@PreAuthorize("hasRole('STUDENT')")`, tuân thủ ≤ 15 class mỗi package và ≤ 300 dòng mỗi file (chia `service/quota`, `service/session`, `service/cache`...).

## Steps
1. Dựng tầng quota: trừ quota bằng một câu UPSERT trả 0 dòng khi hết lượt (qua JDBC, transaction ngắn riêng), hoàn quota có chặn không âm theo đúng ngày đã trừ, đọc trạng thái quota (`used`, `remaining`, `limit`, `resetAt` = 00:00 ngày kế giờ VN) — ngày và `resetAt` tính từ một `Clock` đã gắn múi VN (đặt tên biến có chữ "clock" để qua `NoDirectClockAccessTest`).
2. Dựng cổng đồng thời: tập khoá "đang xử lý" theo student (chiếm được thì tiếp, không thì 409) và `Semaphore` toàn hệ thống theo cấu hình (mặc định 20, `tryAcquire` không chờ; đầy thì 503 trước khi trừ quota). Ghi chú giả định một instance trong code và tài liệu (Open Decision b).
3. Dựng tầng phiên và lịch sử: chèn-nếu-chưa-có bản ghi phiên rồi so chủ sở hữu (khác chủ → từ chối kiểu 404); đếm phiên rỗng từ DB (chỉ tính tin `on_topic=true` nếu Open Decision f được xác nhận); nạp tối đa `history-size`=6 tin gần nhất của đúng phiên đó cho prompt; endpoint "phiên gần nhất" trả `session_id` mới nhất theo tin cuối + danh sách tin để hiển thị (có giới hạn số tin).
4. Dựng cache: chuẩn hoá câu hỏi (NFKC, trim, gộp khoảng trắng, lowercase), băm cùng ngôn ngữ + task type + phiên bản system prompt; chỉ tra/ghi khi phiên rỗng; chỉ ghi câu trả lời `is_on_topic=true` đã qua validate; hit lưu tin với `from_cache=true`, token 0, không trừ quota.
5. Dựng luồng `ChatService` theo AD-06: entitlement (cổng từ Phase 1) → validate (độ dài ≤ 1000 ký tự sau trim, không rỗng, `session_id` là UUID v4, `taskType` thuộc tập/định dạng hợp lệ, ngôn ngữ ∈ {vi,en} dạng gợi ý) → phiên → khoá user → cache → semaphore → trừ quota → gọi client Phase 2 → xử lý kết quả: hợp lệ on-topic thì lưu tin + ghi cache nếu phiên rỗng; off-topic thì hoàn quota, lưu `on_topic=false`, trả câu từ chối cố định; lỗi provider/JSON hỏng thì hoàn quota và ném lỗi bận. Lưu `finishReason`, token vào/ra/thinking, model, phiên bản prompt. Mỗi bước ghi thao tác DB trong transaction ngắn riêng.
6. Dựng controller và DTO: gửi tin, đọc quota, nạp phiên gần nhất (đường dẫn chốt theo hằng số, gợi ý `/api/v1/student/chat/...`, cần thống nhất với FE ở bước 8 phase 4). Request validate bằng Bean Validation; response luôn có `remaining`, `limit`, `resetAt`, `onTopic`, `fromCache`. Định nghĩa lỗi: 429 `CHAT_QUOTA_EXCEEDED` (kèm `resetAt`), 409 `CHAT_REQUEST_IN_FLIGHT`, 503 `CHAT_BUSY` (provider/semaphore), 400 độ dài/định dạng, 404 phiên không thuộc về mình, 403 từ entitlement. Có `userMessage` cho từng lỗi để FE hiển thị.
7. Quan sát được: bộ đếm (số tin, cache hit, hoàn quota, lỗi provider theo loại, semaphore đầy, 409) theo mẫu `PracticeObservability`; cảnh báo log khi chạy mà `daily-limit`/model không hợp lệ.
8. Viết test: unit cho chuẩn hoá cache/khoá cache, tính `resetAt`, thứ tự nhả khoá; test tích hợp trên Postgres thật (Open Decision e) cho: hai request song song `limit=1`, N luồng `limit=20`, một dòng `chat_usage` mỗi ngày, hoàn quota không âm, hoàn quota vắt nửa đêm, `session_id` của người khác, lịch sử 6 tin, cache hit không trừ quota, mỗi kịch bản lỗi hoàn quota và chỉ 1 lần gọi fake client, 409 khi gửi chồng, 503 khi semaphore đầy; test controller/`@WebMvcTest` cho mã lỗi và dạng JSON của 429.

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
- Mỗi lỗi (timeout, 429, 5xx, JSON hỏng, `MAX_TOKENS`, off-topic) → `used` trở lại giá trị trước; số lần gọi fake = 1.
- 429 có body chứa `resetAt`, `limit`, `remaining=0`; 409 và 503 có mã lỗi ổn định; student khác dùng `session_id` không đọc/ghi được.
- Cache: hit lần 2 cho cùng câu hỏi trong phiên rỗng, `from_cache=true`, `used` không đổi; phiên đã có tin thì không tra cache.
- `curl` thủ công với key thử: một tin on-topic, một tin off-topic (được hoàn lượt), quota khớp giữa response và endpoint trạng thái.

## Quality and Testing State
- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementing this phase)
- Testing: not started

## Risks
- Lệch nửa đêm giữa lúc trừ và lúc hoàn: hoàn theo `usage_date` đã trừ, có test riêng.
- App sập giữa lúc đã trừ và chưa hoàn: user mất một lượt; chấp nhận ở mức 20 tin/ngày, ghi trong tài liệu vận hành.
- Nhiều instance làm khoá/semaphore sai: ghi giả định (b); nâng cấp khoá TTL trong DB nếu scale.
- Số luồng servlet bị giữ tối đa ~20 giây × 20 slot: semaphore không chờ + timeout 20 giây giới hạn thiệt hại; xem lại khi có số đo tải thật ở Phase 5.
- `RateLimitFilter` toàn cục cũng trả 429 với dạng body khác: FE phân biệt bằng mã lỗi `CHAT_QUOTA_EXCEEDED`.
- Entity/DTO lớn làm vượt giới hạn 15 class hoặc 300 dòng: chia sub-package ngay từ đầu.
