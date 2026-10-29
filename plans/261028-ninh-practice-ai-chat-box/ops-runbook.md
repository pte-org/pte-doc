# Vận hành: chat box AI cho PTE Practice

**Cập nhật:** 2026-10-29 · **Phạm vi:** `pte-api` (module `chat`) + `pte-practice` (`features/chat`) · **Plan:** [plan.md](./plan.md)

## 1. Bật chat (cả hai đầu cùng lúc)

| Nơi | Biến | Giá trị | Ghi chú |
| --- | --- | --- | --- |
| Backend | `CHAT_AI_ENABLED` | `true` | Mặc định `false`: không có bean chat, ứng dụng khởi động không cần key. Đổi cờ cần khởi động lại. |
| Backend | `CHAT_AI_GEMINI_API_KEY` | key **trả phí** | Key riêng cho chat, không dùng chung `SCORING_AI_GEMINI_API_KEY`. Key free dùng dữ liệu để cải thiện sản phẩm Google, chỉ dùng với dữ liệu thử. |
| Backend | `CHAT_AI_MODEL` | `gemini-2.5-flash-lite` (hoặc bản ghim cùng họ) | Không có mặc định. Từ chối tên có `-latest`; chỉ nhận họ `gemini-2.5-flash-lite*` vì mô hình này tắt thinking mặc định. |
| Backend | `PRACTICE_STRICT_ENTITLEMENT_ENABLED` | `true` | **Bắt buộc.** Mặc định `false` làm `assertUnlocked` fail-closed: mọi student nhận 403 từ chat. |
| Backend | `PRACTICE_WEB_ENABLED` | `true` | Đã cần cho các API practice khác. |
| Web (`pte-practice`) | `NEXT_PUBLIC_CHAT_ENABLED` | `true` | Biến build-time: đặt khi build. Tắt thì panel ẩn hoàn toàn. |
| Web | `NEXT_PUBLIC_API_BASE_URL` | URL backend | Đã có sẵn. |

**Đường deploy Docker đã chuyển tiếp các biến này** (thêm ngày 2026-10-29, mặc định tắt): `pte-api/docker-compose.services.yml` (service backend: `CHAT_AI_ENABLED`, `CHAT_AI_GEMINI_API_KEY`, `CHAT_AI_MODEL` và các tham số `CHAT_AI_*` bên dưới), `pte-api/deploy/practice.Dockerfile` (`ARG NEXT_PUBLIC_CHAT_ENABLED`) và `pte-api/docker-compose.deploy.yml` (build arg của `web-practice`). Đặt giá trị trong file env của compose trên VPS (cùng chỗ với `PRACTICE_STRICT_ENTITLEMENT_ENABLED`); đổi biến web cần **build lại image `web-practice`**. Workflow `deploy-production.yml` của `pte-practice` lint, test, build rồi deploy qua SSH tới VPS (chạy `deploy/production.sh`, build lại `web-practice` ở **mỗi lần** push lên `main`); workflow không cần cờ này vì cờ được đọc từ file env của `pte-api` trên VPS. Vì vậy `NEXT_PUBLIC_CHAT_ENABLED` phải luôn có mặt trong file env đó: thiếu nó thì một lần deploy không liên quan cũng làm panel tắt mà không báo lỗi. Chưa kiểm bằng một lần deploy thật.

Thứ tự phát hành: backend (`CHAT_AI_ENABLED=true`) trước, kiểm bằng `GET /api/v1/student/chat/quota`, rồi build web với `NEXT_PUBLIC_CHAT_ENABLED=true`.

## 2. Tham số cấu hình (`chat.ai.*`)

| Biến | Mặc định | Ý nghĩa |
| --- | --- | --- |
| `CHAT_AI_DAILY_LIMIT` | 20 | Số tin/student/ngày, reset 00:00 giờ Việt Nam (ngày do server tính). |
| `CHAT_AI_MAX_INPUT_CHARS` | 1000 | Độ dài tối đa một tin (không quá 4000, bằng cột `question`). |
| `CHAT_AI_MAX_TOKENS` | 800 | `maxOutputTokens`. Chốt theo số đo thật (xem [prompt-suite](./tests/phase-05-test-report.md)). Tiếng Việt tốn token hơn tiếng Anh. |
| `CHAT_AI_TEMPERATURE` | 0.2 | 0 đến 2. |
| `CHAT_AI_READ_TIMEOUT_MS` / `CHAT_AI_CONNECT_TIMEOUT_MS` | 20000 / 2000 | Một lần gọi, không retry. |
| `CHAT_AI_HISTORY_SIZE` | 6 | Số tin OK gần nhất gửi làm ngữ cảnh. |
| `CHAT_AI_MAX_CONCURRENT` | 20 | Số lệnh gọi Gemini đồng thời toàn hệ thống; đầy thì trả 503, không trừ lượt. |
| `CHAT_AI_MAX_CACHE_HITS_PER_DAY` | 100 | Trần câu trả lời từ cache mỗi student/ngày; vượt thì câu hỏi đi đường thường và tính quota. |

Khởi động lỗi nếu cấu hình sai (liệt kê hết lỗi một lần): thiếu key, model thiếu/có `-latest`, giá trị < 1, timeout < 1, `temperature` ngoài 0 đến 2, `max-input-chars` > 4000.

## 3. Giả định một instance

Khoá "một request đang xử lý mỗi student" (HTTP 409) và semaphore toàn hệ thống nằm **trong bộ nhớ** của từng instance. Với N instance, giới hạn thực tế thành N request mỗi student và N × `CHAT_AI_MAX_CONCURRENT` toàn hệ thống. **Quota trong DB vẫn đúng với mọi số instance.** Khi cần scale ngang: chuyển khoá sang bảng khoá có TTL trong DB (công sức ~1 ngày); không dùng advisory lock theo session vì giữ connection tới 20 giây.

## 4. Chi phí và hạn mức

Công thức ngày = (token vào ÷ 10^6 × giá vào) + (token ra ÷ 10^6 × giá ra), giả định 10.000 tin/ngày × (1.500 vào + 500 ra). Giá tra ngày 2026-10-28 tại [bảng giá Gemini API](https://ai.google.dev/gemini-api/docs/pricing):

| Model | Chi phí tối đa/tháng (500 student dùng hết quota) |
| --- | --- |
| Gemini 2.5 Flash-Lite (0,10 / 0,40 USD mỗi 1M) | ~105 USD |
| Gemini 3.1 Flash-Lite (0,25 / 1,50) | ~338 USD |
| Gemini 3.5 Flash-Lite (0,30 / 2,50) | ~510 USD |

Cache hit không tốn token; lượt bị hoàn quota (off-topic, lỗi) vẫn tốn token.

**Việc cho Tech Lead / PM (chưa làm):**
- [ ] Tạo Google Cloud Project có billing, lấy key cho chat.
- [ ] Đặt **budget alert** trong Cloud Billing (Budgets & alerts), ngưỡng gợi ý 50% / 90% / 100% mức dự kiến.
- [ ] Ghi hạn mức thực tế vào bảng dưới (Google AI Studio, trang rate limit của project).

| Chỉ số | Giá trị thực tế |
| --- | --- |
| RPM (request/phút) | _chờ Tech Lead/PM_ |
| TPM (token/phút) | _chờ Tech Lead/PM_ |
| RPD (request/ngày) | _chờ Tech Lead/PM_ |

Mục tiêu tải: ~70 request/phút giờ cao điểm (ước tính 500 student).

## 5. Quan sát

Micrometer (không có nội dung câu hỏi hay student id trong tag):

| Metric | Tag | Cách đọc |
| --- | --- | --- |
| `chat.message.stored` | `status` (OK/REFUSED/FAILED), `from_cache` | Lưu lượng và tỉ lệ cache. |
| `chat.quota.refunded` | `cause` (off_topic, provider_failure, store_failure, setup_failure) | **Tín hiệu lạm dụng/chi phí**: hoàn lượt thì học viên không mất lượt nhưng vẫn tốn token. Cảnh báo khi tăng bất thường. |
| `chat.quota.refund.failed` | | Hoàn quota thất bại (học viên mất một lượt). Trừ số này khỏi `chat.quota.refunded`: metric kia cũng đếm cả lần hoàn thất bại. |
| `chat.provider.failed` | `reason` (TIMEOUT, RATE_LIMITED, UNAVAILABLE, TRUNCATED, ...) | Lỗi Gemini do `ChatAiException`. Lỗi RuntimeException ngoài dự kiến **không** có metric này: xem dòng FAILED trong DB. |
| `chat.slot.rejected` | | Semaphore đầy (503). |
| `chat.inflight.rejected` | | Gửi chồng (409). |

Giới hạn đã biết: `chat.cache.store.failed` chưa được tăng ở đâu; lỗi ghi cache chỉ có dòng log mức WARN. Log không chứa câu hỏi, câu trả lời hay key: chỉ có tên kiểu exception và SQLState.

## 6. Truy vấn mẫu (PostgreSQL)

```sql
-- Quota hôm nay (ngày Việt Nam), nhiều nhất trước
SELECT student_id, used FROM chat_usage
WHERE usage_date = (now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date ORDER BY used DESC LIMIT 50;

-- Số tin theo trạng thái, 24 giờ gần nhất
SELECT status, count(*) FROM chat_message WHERE created_at > now() - interval '24 hours' GROUP BY status;

-- Dòng FAILED theo finish_reason (MAX_TOKENS nhiều => tăng max-tokens hoặc siết prompt)
SELECT finish_reason, count(*) FROM chat_message
WHERE status = 'FAILED' AND created_at > now() - interval '24 hours' GROUP BY finish_reason ORDER BY 2 DESC;

-- Token theo ngày (không tính cache hit)
SELECT (created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS day,
       sum(tokens_in) AS tokens_in, sum(tokens_out) AS tokens_out, sum(tokens_thinking) AS tokens_thinking
FROM chat_message WHERE from_cache = false GROUP BY 1 ORDER BY 1 DESC LIMIT 14;

-- Tỉ lệ cache hit trong các câu trả lời OK, 24 giờ gần nhất
SELECT round(100.0 * count(*) FILTER (WHERE from_cache) / nullif(count(*), 0), 1) AS cache_hit_pct
FROM chat_message WHERE status = 'OK' AND created_at > now() - interval '24 hours';

-- Student có nhiều cache hit nhất hôm nay (phát hiện lạm dụng)
SELECT student_id, count(*) FROM chat_message
WHERE from_cache AND created_at >= (date_trunc('day', now() AT TIME ZONE 'Asia/Ho_Chi_Minh') AT TIME ZONE 'Asia/Ho_Chi_Minh')
GROUP BY student_id ORDER BY 2 DESC LIMIT 20;
```

## 7. Khi Gemini lỗi hàng loạt

1. Xem `chat.provider.failed` theo `reason`: `RATE_LIMITED` nghĩa là hạn mức; `AUTH_FAILED` là key sai/hết hạn; `UNAVAILABLE`/`TIMEOUT` là phía Google.
2. Học viên không mất lượt (mỗi lỗi được hoàn quota) và thấy thông báo "hệ thống đang bận".
3. Muốn tắt hẳn: `CHAT_AI_ENABLED=false` rồi khởi động lại backend. Panel phía web vẫn hiện nếu `NEXT_PUBLIC_CHAT_ENABLED=true` (cờ web là build-time), nên build lại image `web-practice` với `false`; khi đó học viên thấy thông báo lỗi trong panel cho tới khi build xong. Xem thứ tự rollback trong [release-checklist.md](./release-checklist.md#d-rollback).

## 8. Đổi prompt hoặc model

Cache khoá theo (câu hỏi chuẩn hoá, ngôn ngữ, dạng bài, `ChatPrompts.VERSION`), **không** có tên model. Khi đổi system prompt, đổi model hoặc đổi cách từ chối: tăng `ChatPrompts.VERSION` (hiện `v1`, chưa có cache thật ở môi trường nào) để các câu trả lời cũ ngừng được phát lại.

## 9. Việc chưa làm ở bản này

- Chưa đo bằng Gemini thật (không có key trong phiên làm việc): chạy bộ test prompt theo [phase-05-test-report.md](./tests/phase-05-test-report.md) trước khi bật ở production.
- Chưa kiểm tay end-to-end trên trình duyệt với backend thật (giao diện đã kiểm với API giả lập).
- Chưa có thời hạn lưu dữ liệu/xoá hội thoại (xem [privacy-handoff.md](./privacy-handoff.md)).
