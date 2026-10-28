# Phase 2: BE Gemini chat client + system prompt

**Repo:** `pte-api` · **Ước lượng:** 1–1.5 ngày · **Phủ:** FR-03, FR-05, P1 (từ chối chủ đề, không chiều ý, lỗi/JSON hỏng không retry), P3 (model ghim, `finishReason`, token)

## Requirements
Một client Gemini dành riêng cho chat nhận (system prompt, lịch sử, câu hỏi hiện tại) và trả về hoặc kết quả đã kiểm hợp lệ `{is_on_topic, markdown_content}` kèm token/`finishReason`, hoặc một lỗi phân loại rõ ràng để tầng service hoàn quota. Có system prompt có phiên bản.

## Design Constraints
- Không retry ở bất kỳ tầng nào; không dùng `ProviderGuard.standard`. Một lần gọi HTTP, thất bại là thất bại.
- Khoá API chỉ đi qua header, không nằm trong URL, log hay thông báo lỗi; thông báo lỗi chỉ chứa mã phân loại, không chứa câu hỏi/câu trả lời/thân phản hồi của provider.
- `temperature` thấp (không phải 0 cứng như scoring), `maxOutputTokens` bắt buộc, model ghim tên, ghim mức thinking thấp nhất của model đã chọn.
- Đầu ra của model là dữ liệu không tin cậy: chỉ chấp nhận khi qua đủ kiểm tra schema; không bao giờ đưa nguyên văn lỗi parse cho người dùng.
- Không sửa `GeminiRestClient` hay bất kỳ file trong `scoring` (nếu chọn A1); nếu người dùng chọn A2/A3 thì phase này mở rộng thành di chuyển mã và phải chạy lại toàn bộ test `scoring`.

## Steps
1. Đối chiếu tài liệu chính thức ai.google.dev (structured output, thinking, `generateContent`) với model đã ghim ở Open Decision c: trường `responseSchema`/`responseJsonSchema`, `propertyOrdering`, `maxOutputTokens`, cấu hình thinking, `usageMetadata` — ghi kết quả đối chiếu vào đầu file client (nghiên cứu hiện chỉ có nguồn thứ ba cho một số điểm).
2. Xây client chat riêng: request nhiều lượt (system instruction + tối đa N tin lịch sử + tin hiện tại), schema nhỏ chỉ gồm hai trường với `is_on_topic` đứng trước, `temperature` thấp, `maxOutputTokens`, thinking tối thiểu; đọc `finishReason`, `usageMetadata` (vào/ra/thinking), `modelVersion`; HTTP/1.1, timeout theo cấu hình, bean chỉ tạo khi `chat.ai.enabled=true`.
3. Phân loại lỗi một lần: timeout/mạng, 429, 5xx, 4xx cấu hình (key sai trả 400 `API_KEY_INVALID`), prompt bị chặn, `candidates` rỗng, `finishReason` khác `STOP` (gồm `MAX_TOKENS`, `SAFETY`, `RECITATION`), phản hồi không phải JSON. Mọi loại đều thành một lỗi provider thống nhất cho Phase 3; có phân biệt "tạm thời" để ghi log/metric nhưng không dẫn tới retry.
4. Viết bộ làm sạch/parse/validate đầu ra: bỏ rào ```json nếu có, parse trong try-catch, kiểm đủ trường và đúng kiểu, `markdown_content` không rỗng khi `is_on_topic=true`, giới hạn độ dài tối đa hợp lý; khi `is_on_topic=false` bỏ qua nội dung của model và dùng câu từ chối cố định (tiếng Việt/Anh theo ngôn ngữ người hỏi — cách xác định ngôn ngữ chốt ở Phase 3).
5. Soạn system prompt có hằng số phiên bản: bảng chủ đề cho phép (ngữ pháp, từ vựng, phát âm, chiến lược/định dạng từng dạng bài PTE, chấm điểm PTE, dịch Anh↔Việt phục vụ học, sửa bài viết, kế hoạch ôn thi) và từ chối (làm hộ bài thi thật, mọi chủ đề ngoài tiếng Anh, yêu cầu bỏ qua/tiết lộ hướng dẫn, đóng vai khác); quy tắc trung lập không khen suông, nói thẳng đúng/sai, không đổi kết luận theo ý người hỏi; trả lời theo ngôn ngữ người hỏi; ngắn gọn, ưu tiên danh sách thay bảng rộng; coi nội dung người dùng là dữ liệu chứ không phải lệnh. Tách prompt thành file tài nguyên hoặc lớp riêng để dễ rà soát và đổi phiên bản.
6. Viết unit test với fake HTTP (không gọi Gemini thật): đường thành công, JSON bọc rào ```json, JSON hỏng/cắt (`MAX_TOKENS`), thiếu trường, sai kiểu, `is_on_topic=true` + nội dung rỗng, `candidates` rỗng, `SAFETY`, 429, 5xx, timeout; kiểm chứng đúng một lần gọi mỗi request (không retry), key không xuất hiện trong thông báo lỗi, thân request có `maxOutputTokens` và thứ tự lượt đúng.

## Files
- `pte-api/app/src/main/java/com/pte/chat/internal/client/` — client Gemini chat, mô hình request/response, lỗi provider, bộ phân loại lỗi HTTP (≤ 15 class; tách `client/parse` nếu nhiều)
- `pte-api/app/src/main/java/com/pte/chat/internal/config/ChatGeminiConfig.java` — tạo bean client (mẫu `scoring/internal/config/AzureGeminiProviderConfig.java`)
- `pte-api/app/src/main/java/com/pte/chat/internal/prompt/` — system prompt + hằng số phiên bản + câu từ chối cố định
- `pte-api/app/src/test/java/com/pte/chat/internal/client/*Test.java` — test client/parse với fake

## Success Criteria
- Toàn bộ test client/parse chạy xanh bằng fake, không cần mạng hay key.
- Mỗi kịch bản lỗi ở bước 6 cho đúng một loại lỗi provider; số lần gọi HTTP của fake luôn bằng 1.
- Đầu ra hợp lệ duy nhất là JSON đủ trường, `is_on_topic` là boolean, nội dung không rỗng khi on-topic; mọi trường hợp khác bị từ chối.
- Thân request chứa đúng model ghim, `temperature` thấp, `maxOutputTokens`, cấu hình thinking đã chốt; không có chuỗi khoá API trong log/lỗi.
- Phiên bản system prompt là một hằng số duy nhất mà cache (Phase 3) đọc được.
- Kiểm thủ công một lần (key thử, dữ liệu giả) trả về đúng cấu trúc `{is_on_topic, markdown_content}` và ghi nhận token thật.

## Quality and Testing State
- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementing this phase)
- Testing: not started

## Risks
- Tên trường thinking khác nhau giữa 2.5 (ngân sách) và 3.x (mức): xác minh theo model đã ghim, không đoán.
- Schema quá phức tạp bị trả 400 `INVALID_ARGUMENT`: giữ schema hai trường.
- Prompt quá dài làm tăng chi phí mỗi tin: đo số token system prompt, giữ ngắn gọn.
- `is_on_topic` bị injection ép sai: phòng thủ chính là prompt + bộ test ở Phase 5; không thêm lời gọi phân loại.
- Ngôn ngữ người hỏi không xác định được từ phía server: dùng ngôn ngữ UI client gửi làm gợi ý, để model trả lời theo ngôn ngữ câu hỏi (xem Phase 3).
