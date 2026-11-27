# Sinh đề AI: hiển thị mượt khi 9Router fallback — Brainstorm

**Ngày:** 2026-11-26 · **Phạm vi:** `pte-api` (itembank generation), `pte-web/apps/vendor-web` (questiongeneration)
**Ràng buộc:** giữ combo `Capstone` trong 9Router để fallback (Gemini/Codex lỗi → model free). Không bỏ fallback.

## 1. Vấn đề

Màn sinh đề AI đôi khi gõ chữ dần, đôi khi chờ rất lâu rồi hiện cả khối. Nguyên nhân không nằm ở code của mình. Thời điểm chữ về phụ thuộc vào model mà `Capstone` đang dùng thực tế.

## 2. Số liệu đo (2026-11-26, gọi thẳng 9Router, `stream: true`)

| Model | Kết quả |
|---|---|
| `Capstone` | Model thực sự trả lời: `nvidia/nemotron-3.5-super-vl:free`. Có 1.343 đoạn suy nghĩ và 83 đoạn trả lời, nhưng **tất cả về trong 55,6s → 57,6s**. Chữ trả lời đầu tiên đến ở giây 56,9. |
| `kc/google/gemini-2.5-flash` | HTTP 503 |
| `kc/openai/gpt-4.1` | HTTP 503 |
| `mmf/mimo-auto` | HTTP 502 |
| `oc/jev-1.13-free` | HTTP 400 |

Kết luận:

- **Các model chính đang lỗi 503**, nên mọi lần gọi hiện nay đều rơi xuống model free.
- **Model free giữ lại toàn bộ câu trả lời**, cả phần suy nghĩ, rồi gửi một lần ở cuối. Thời gian chờ gồm thời gian 9Router thử các model chính rồi chuyển, cộng thời gian model free chạy.
- **Backend đọc đúng:** `LlmStreamReader` nhận được cả `reasoning` lẫn `content`. Tuy vậy, nó **chưa đọc trường `model`** trong mỗi đoạn trả về, tức là tên model thực sự đã trả lời.
- **Có rủi ro timeout:** `llm.readTimeout = 90s` là thời gian tối đa chấp nhận không nhận được dữ liệu nào. Lần đo này đã im lặng 56s. Một passage dài hơn, hoặc 9Router chuyển qua nhiều model hơn, có thể vượt 90s. Khi đó backend sẽ retry và người dùng phải chờ thêm một vòng nữa.

## 3. Các trường hợp phải xử lý

| # | Trường hợp | Dữ liệu về thế nào | Màn hình cần hiển thị |
|---|---|---|---|
| 1 | Model chính chạy, trả chữ dần | Đoạn đầu sau 1–3s, các đoạn trải đều | Chữ gõ theo dữ liệu thật. Nhãn model chính. |
| 2 | Model chính lỗi, fallback giữ cả câu trả lời | Im lặng 30–60s rồi về cả khối | Thẻ chờ có đếm giây. Sau ~20s hiện gợi ý "có thể đang chuyển sang model dự phòng". Khi chữ về: gõ đều kèm nút **Hiện hết**. Nhãn **dự phòng**. |
| 3 | Model có suy nghĩ, trả dần | Đoạn suy nghĩ về dần, sau đó đến câu trả lời | Ô "Đang suy nghĩ" chạy theo dữ liệu thật, rồi chuyển sang gõ câu trả lời. |
| 4 | Model có suy nghĩ, giữ cả câu trả lời | Suy nghĩ và câu trả lời về cùng lúc | **Không phát lại** phần suy nghĩ (1.000+ đoạn sẽ làm chậm thêm). Thu gọn thành "Đã suy nghĩ · N giây" và gõ câu trả lời ngay. |
| 5 | Không trả theo kiểu stream (một JSON duy nhất) | Một khối | Đã có `plainAnswer`. Hiển thị như trường hợp 2. |
| 6 | Mọi model trong combo đều lỗi | 4xx/5xx | Dùng retry hiện có, sau đó báo FAILED với mã lỗi. Không đổi. |
| 7 | Im lặng lâu hơn read timeout | Hết thời gian chờ | Nâng `readTimeout` và tính lại tổng thời gian tối đa của job (mục 5.1). |
| 8 | Sinh theo lô | Như trên, cho từng câu | Như trên. Lô vẫn tự lưu, không có nút tiếp tục. |

## 4. Các hướng đã cân nhắc

| Hướng | Đánh giá |
|---|---|
| A. Bỏ `Capstone`, gọi thẳng Gemini | **Loại.** Mất fallback, trái ràng buộc. |
| B. Backend tự fallback theo thời gian chờ đoạn đầu (gọi model trả dần với timeout ngắn, rồi mới gọi `Capstone`) | **Loại.** Lặp lại việc 9Router đã làm. Hiện các model chính đang 503 nên cũng không nhanh hơn. Thêm cấu hình và rủi ro tính phí hai lần. |
| C. Giao diện tự thích ứng với cách dữ liệu về, cộng nhãn model đã trả lời | **Chọn.** Xử lý được mọi trường hợp ở mục 3, giữ fallback, sửa ít. |
| D. Sửa nguyên nhân 503 của các model `kc/*` trong 9Router (quota hoặc tài khoản) | **Làm song song, ngoài code.** Đây mới là cách thật sự để chữ nhanh và gõ dần. |

## 5. Thiết kế đã chọn (hướng C)

Các quyết định đã được user xác nhận:

- Khi câu trả lời về cả khối: **gõ đều ~60 ký tự/giây và có nút Hiện hết**.
- **Hiện nhãn model dự phòng** dựa trên tên model 9Router trả về.

### 5.1 Backend (`pte-api`, module itembank)

1. **Đọc tên model đã trả lời.** `LlmStreamReader` lấy trường `model` đầu tiên khác rỗng trong các đoạn stream, hoặc `root.model` nếu là JSON thường. `Result` thêm `servedModel`. `TokenSink` thêm `servedBy(String model)`, được gọi một lần khi biết tên.
2. **Xác định có phải dự phòng không.** Thêm property `question-generation.llm.fallback-model-markers` (mặc định `[":free"]`). Model trả lời khớp một marker thì coi là dự phòng. Khi cần đổi thì sửa cấu hình, không sửa code.
3. **Đưa vào live feed.** `LiveItem.generator` (và `reviewer`) thêm `servedModel` và `fallback: boolean`. Đây là thay đổi có thêm trường, không phá vỡ API cũ. Cập nhật type trong `@pte/api-client`.
4. **Timeout.** Nâng `readTimeout` mặc định (đề xuất 150s, cho cấu hình qua env). Tính lại `timeout` của job theo ghi chú tại `QuestionGenerationProperties:135` (lần gọi chậm nhất × số lần thử + delay). Không log prompt, câu trả lời hay key.

### 5.2 Web (`vendor-web/features/questiongeneration`)

1. **Thẻ chờ (`_WritingBrief`).** Giữ dòng đếm giây. Sau `FALLBACK_HINT_AFTER_MS` (~20s) thêm một dòng: "Model chính có thể đang bận — 9Router đang chuyển sang model dự phòng".
2. **Nút Hiện hết.** Hiện khi phần chữ chưa gõ còn dài hơn `SKIP_BACKLOG_CHARS` (~200 ký tự). Bấm vào thì `useTypedText` hiện ngay toàn bộ chữ đã nhận. Chỉ bỏ qua chữ đang chờ gõ: tạm dừng theo bước và xác nhận trước khi lưu vẫn giữ nguyên. Không cần đoán dữ liệu về dần hay cả khối, vì khi về dần thì phần chờ gõ luôn ngắn và nút tự không hiện.
3. **Suy nghĩ về cả khối.** Nếu phần suy nghĩ và câu trả lời đến trong cùng một lần cập nhật, hoặc phần suy nghĩ chỉ đến sau khi đã có chữ trả lời, thì thu gọn thành "Đã suy nghĩ · N giây" (bấm để mở) thay vì phát lại.
4. **Nhãn model.** Hiện chip cạnh tên agent: tên model thực sự trả lời, có màu cảnh báo nhẹ và chữ "dự phòng" khi `fallback = true`. Toàn bộ chữ hiển thị đặt trong constants (vi/en).
5. Cấu hình `TYPING_CHARS_PER_FRAME = 1` giữ nguyên, không thêm tăng tốc.

### 5.3 Kiểm thử

- Backend: unit test `LlmStreamReader` cho các trường hợp: đọc được `model` từ stream, từ JSON thường, và không có `model`; marker `:free` đánh dấu dự phòng.
- Web (vitest): nút Hiện hết chỉ hiện khi phần chờ gõ vượt ngưỡng và bấm vào thì hiện hết chữ; suy nghĩ về cả khối bị thu gọn; thẻ chờ hiện gợi ý sau ngưỡng thời gian.
- Không kiểm tra bằng trình duyệt; user tự kiểm tra giao diện.

## 6. Rủi ro và lưu ý

- Khi dữ liệu về cả khối, nhãn dự phòng **chỉ biết được lúc khối đó đến**, không biết trong lúc đang chờ. Trong lúc chờ chỉ có gợi ý theo thời gian ở mục 5.2.1.
- Danh sách marker có thể sai nếu 9Router đổi tên model. Chấp nhận được: nhãn chỉ để thông tin, không ảnh hưởng luồng sinh đề.
- Nâng read timeout làm job lỗi thật sẽ chậm phát hiện hơn (tối đa ~150s mỗi lần thử).

## 7. Ngoài phạm vi

- Cấu hình combo hoặc quota của 9Router (các model `kc/*` đang 503). Nên kiểm tra riêng phía 9Router. Khi model chính chạy lại, trường hợp 1 sẽ tự gõ dần mà không cần sửa gì.

## 8. Bước tiếp theo

→ `/ck:plan` theo thiết kế ở mục 5. Làm backend trước (5.1), web sau (5.2), mỗi phần một phase.
