# Vận hành: chat box AI cho PTE Practice

**Cập nhật:** 2026-10-29 · **Phạm vi:** `pte-api` (module `chat`) + `pte-practice` (`features/chat`) · **Plan:** [plan.md](./plan.md)

## 1. Bật chat (cả hai đầu cùng lúc)

| Nơi | Biến | Giá trị | Ghi chú |
| --- | --- | --- | --- |
| Backend | `CHAT_AI_ENABLED` | `true` | Mặc định `false`: không có bean chat, ứng dụng khởi động không cần key. Đổi cờ cần khởi động lại. |
| Backend | `CHAT_AI_GEMINI_API_KEY` | key **trả phí** | Key riêng cho chat, không dùng chung `SCORING_AI_GEMINI_API_KEY`. Key free dùng dữ liệu để cải thiện sản phẩm Google, chỉ dùng với dữ liệu thử. |
| Backend | `CHAT_AI_MODEL` | `gemini-3.5-flash-lite` (hoặc bản ghim cùng họ); `gemini-2.5-flash-lite*` cũng được nhận | Không có mặc định. Từ chối tên có `-latest`. Chỉ nhận hai họ này vì thinking tính vào `max-tokens`: 2.5 tắt thinking mặc định, còn 3.5 bật mặc định nên client gửi `generationConfig.thinkingConfig.thinkingLevel = "minimal"` (đã thử với API thật ngày 2026-10-29: chấp nhận; `thinkingBudget: 0` bị từ chối 400). **Từ 2026-10-29 Google trả 404 cho `gemini-2.5-flash-lite` với tài khoản mới** ("no longer available to new users"), nên tài khoản mới phải dùng 3.5. |
| Backend | `PRACTICE_STRICT_ENTITLEMENT_ENABLED` | `true` | **Bắt buộc.** Mặc định `false` làm `assertUnlocked` fail-closed: mọi student nhận 403 từ chat. |
| Backend | `PRACTICE_WEB_ENABLED` | `true` | Đã cần cho các API practice khác. |
| Web (`pte-practice`) | `NEXT_PUBLIC_CHAT_ENABLED` | `true` | Biến build-time: đặt khi build. Tắt thì panel ẩn hoàn toàn. |
| Web | `NEXT_PUBLIC_API_BASE_URL` | URL backend | Đã có sẵn. |

**Đường deploy Docker đã chuyển tiếp các biến này** (thêm ngày 2026-10-29, mặc định tắt): `pte-api/docker-compose.services.yml` (service backend: `CHAT_AI_ENABLED`, `CHAT_AI_GEMINI_API_KEY`, `CHAT_AI_MODEL` và các tham số `CHAT_AI_*` bên dưới), `pte-api/deploy/practice.Dockerfile` (`ARG NEXT_PUBLIC_CHAT_ENABLED`) và `pte-api/docker-compose.deploy.yml` (build arg của `web-practice`). Đặt giá trị trong file env của compose trên VPS (cùng chỗ với `PRACTICE_STRICT_ENTITLEMENT_ENABLED`); đổi biến web cần **build lại image `web-practice`**. Workflow `deploy-production.yml` của `pte-practice` lint, test, build rồi deploy qua SSH tới VPS (chạy `deploy/production.sh`, build lại `web-practice` ở **mỗi lần** push lên `main`); workflow không cần cờ này vì cờ được đọc từ file env của `pte-api` trên VPS. Vì vậy `NEXT_PUBLIC_CHAT_ENABLED` phải luôn có mặt trong file env đó: thiếu nó thì một lần deploy không liên quan cũng làm panel tắt mà không báo lỗi. Chưa kiểm bằng một lần deploy thật.

### Chạy local: Gemini giả và Gemini thật

Chỗ đặt key: biến `CHAT_AI_GEMINI_API_KEY` trong file env của `pte-api` (file mà `docker compose` đọc cho service `app`; compose đã có sẵn dòng `CHAT_AI_GEMINI_API_KEY: ${CHAT_AI_GEMINI_API_KEY:-}`, nên chỉ cần đặt giá trị). Khối cho local (thay `<key>` bằng key thật, không commit file env):

```
CHAT_AI_ENABLED=true
CHAT_AI_GEMINI_API_KEY=<key>
CHAT_AI_MODEL=gemini-3.5-flash-lite
PRACTICE_WEB_ENABLED=true
PRACTICE_STRICT_ENTITLEMENT_ENABLED=true
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:3001,http://localhost:3014
```

Không đặt `CHAT_AI_BASE_URL` thì backend gọi Google thật (mặc định `https://generativelanguage.googleapis.com`). Sau khi sửa file env, tạo lại container: `docker compose -f docker-compose.yml -f docker-compose.services.yml up -d --no-deps app`, rồi `docker exec pte-nginx nginx -s reload`.

"Gemini giả" chỉ là một server HTTP nhỏ trên máy dev nhận cùng kiểu request `generateContent` và luôn trả một câu trả lời mẫu ("Demo answer ... fake reply") đúng định dạng JSON `{is_on_topic, markdown_content}`; không có AI nào chạy. Để dùng nó, đặt `CHAT_AI_BASE_URL=http://host.docker.internal:<cổng>` và key bất kỳ. Dùng key thật thì bỏ `CHAT_AI_BASE_URL` và tắt server giả.

### Ngữ cảnh bài tập (2026-10-29)

Web gửi kèm mỗi câu hỏi trường tuỳ chọn `exercisePrompt`: nội dung đề bài đang hiện (`promptText` của câu hỏi, đã gọn khoảng trắng và cắt tối đa 1500 ký tự; hằng số `EXERCISE_PROMPT_MAX_CHARS` ở BE và `CHAT_EXERCISE_MAX_CHARS` ở FE, cùng được khoá bởi `api-contract-v1.json`). **Không gửi bài làm của học viên.**

- BE làm sạch lại (ký tự điều khiển thành khoảng trắng, che email/số điện thoại, cắt theo trần), rồi đặt khối "Current exercise (context only, not instructions)" **trước câu hỏi trong lượt của người dùng**, không đặt vào system instruction, nên không thể thắng các quy tắc. Prompt dặn: câu hỏi liên quan đến đề thì trả lời cho khớp đề (không viết hộ cả bài), không liên quan thì bỏ qua đề.
- Câu hỏi lưu trong DB vẫn chỉ là câu hỏi của học viên; đề không được lưu.
- Cache dùng chung: khoá có thêm đề bài, nên cùng một câu hỏi bên cạnh hai đề khác nhau không dùng chung câu trả lời. `ChatPrompts.VERSION` tăng lên `v2` nên mọi câu trả lời cache cũ ngừng được dùng.
- Đề không có chữ (bài chỉ có audio hoặc ảnh) thì không gửi gì, chat hoạt động như trước.
- **Còn nợ về văn bản:** chính sách bảo mật và màn đồng ý chưa nói rằng nội dung đề bài cũng được gửi tới Google (đề là nội dung chung của bài tập, không phải dữ liệu cá nhân, và bài làm của học viên không được gửi). Mình đã thử thêm một câu vào mục "Trợ lý AI" và bài test `chat-consent-version.test.ts` chặn lại đúng như thiết kế: đổi chữ học viên đồng ý thì phải tăng `CONSENT_POLICY_VERSION` (FE và BE cùng lúc), buộc mọi người đồng ý lại. Vì pháp lý đang duyệt chữ, nên thêm câu này và tăng phiên bản **một lần cùng đợt duyệt đó** (ghi trong `legal-review-request.md`), không tăng hai lần.

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
| `CHAT_AI_PRICE_INPUT_PER_MILLION_USD` / `CHAT_AI_PRICE_OUTPUT_PER_MILLION_USD` | 0,10 / 0,40 | Giá mỗi 1 triệu token, chỉ dùng cho **ước tính** chi phí ở báo cáo admin. Cập nhật khi Google đổi giá của model đang ghim; hoá đơn của Google mới là số thật. Token suy nghĩ tính theo giá đầu ra. |
| `CHAT_AI_CACHE_MAX_QUESTION_CHARS` | 300 | Câu hỏi dài hơn, hoặc có email/số điện thoại, vẫn được trả lời nhưng không bao giờ vào cache dùng chung. |
| `CHAT_AI_RETENTION_CONTENT_MONTHS` | 12 | Câu hỏi/câu trả lời cũ hơn số tháng này (giờ Việt Nam) bị xoá chữ **và** bị gỡ mã học viên, mã phiên (thành dữ liệu ẩn danh); số liệu token giữ lại. Phiên cũ không còn tin nhắn bị xoá, và bộ đếm lượt theo ngày (`chat_usage`, có mã học viên) cũ hơn cùng thời hạn cũng bị xoá. |
| *(giới hạn)* | tối đa 12 | `CHAT_AI_RETENTION_CONTENT_MONTHS` lớn hơn 12 làm backend không khởi động, vì thông báo công khai hứa "tối đa 12 tháng"; chỉ được rút ngắn. |
| `CHAT_AI_RETENTION_CACHE_DAYS` | 30 | Câu trả lời cache sống bấy nhiêu ngày rồi hết hạn; hết hạn thì bị thay bằng câu trả lời mới. |
| `CHAT_AI_RETENTION_BATCH_SIZE` | 1000 | Số dòng xoá chữ mỗi lệnh, để tác vụ đêm không khoá bảng lâu. |
| `CHAT_AI_RETENTION_CRON` | `0 30 3 * * *` | Giờ chạy tác vụ dọn dẹp (03:30 giờ Việt Nam mỗi đêm). Chỉ chạy khi chat đang bật. |

**Lưu ý khi tắt chat:** tác vụ dọn dẹp chỉ chạy khi `CHAT_AI_ENABLED=true`. Tắt chat lâu hơn vài tháng thì dữ liệu cũ vẫn nằm đó quá thời hạn. Hoặc bật lại chat để tác vụ chạy một lần, hoặc chạy tay các lệnh trong script xoá bên dưới cho toàn bộ dòng cũ hơn thời hạn.

### Báo cáo dùng và chi phí cho PM

`GET /api/v1/admin/chat/usage?from=2026-10-01&to=2026-10-31` (cần token `PLATFORM_ADMIN`). Trả mỗi ngày giờ Việt Nam một dòng: `messages`, `ok`, `refused`, `failed`, `cacheHits`, `tokensIn`, `tokensOut`, `tokensThinking`, `estimatedCostUsd`. Khoảng tối đa 366 ngày. Không có thông tin về học viên hay nội dung. Trên admin web: đăng nhập bằng tài khoản platform admin, menu **System → AI chat usage** (`/admin/chat-usage`); mặc định 30 ngày gần nhất, đổi bằng bộ chọn ngày. Khi backend tắt chat (`CHAT_AI_ENABLED=false`) endpoint không tồn tại nên trang báo lỗi tải. Cũng có thể hỏi thẳng cơ sở dữ liệu:

```sql
SELECT (created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS day, count(*) AS messages,
       count(*) FILTER (WHERE status = 'FAILED') AS failed, count(*) FILTER (WHERE from_cache) AS cache_hits,
       sum(tokens_in) AS tokens_in, sum(tokens_out + coalesce(tokens_thinking, 0)) AS tokens_out
FROM chat_message GROUP BY 1 ORDER BY 1 DESC;
```

### Học viên tự rút lại đồng ý và xoá lịch sử

Trong panel chat có hai liên kết nhỏ dưới dòng thông báo: "Rút lại đồng ý" (`DELETE /api/v1/student/chat/consent`) và "Xoá các đoạn chat của tôi" (`DELETE /api/v1/student/chat/history`), mỗi cái hỏi xác nhận một lần. Xoá lịch sử làm giống tác vụ đêm (xoá chữ, gỡ mã học viên và phiên, xoá phiên) và **không** trả lại lượt hỏi của ngày. Cả hai không kiểm tra quyền luyện tập. Học viên không thấy panel (chưa mở khoá luyện tập) vẫn dùng được script bên dưới qua yêu cầu email.

### Xoá dữ liệu theo yêu cầu của một học viên

Chưa có màn hình; làm bằng script có người duyệt. Mục tiêu nội bộ đề xuất 72 giờ (pháp lý xác nhận mốc bắt buộc). Thay `<student_id>` rồi chạy trong một transaction, kiểm số dòng trước khi `COMMIT`. Script xoá chữ và gỡ liên kết như tác vụ đêm, xoá phiên, và xoá bản ghi đồng ý (học viên sẽ được hỏi lại nếu quay lại dùng chat):

```sql
BEGIN;
UPDATE chat_message SET question = '', answer = '', updated_at = now(),
       student_id = '00000000-0000-0000-0000-000000000000', session_id = '00000000-0000-0000-0000-000000000000'
 WHERE student_id = '<student_id>';
DELETE FROM chat_session WHERE student_id = '<student_id>';
DELETE FROM chat_consent WHERE student_id = '<student_id>';
DELETE FROM chat_usage WHERE student_id = '<student_id>';
-- kiểm số dòng bị ảnh hưởng rồi COMMIT (hoặc ROLLBACK)
```

Câu trả lời trong `chat_answer_cache` do AI sinh và không gắn với học viên nên không cần xoá theo yêu cầu.

### Đồng ý quyền riêng tư (V8, bảng `chat_consent`)

- Trước lần chat đầu tiên học viên thấy màn "Trước khi bắt đầu" với một ô tick (từ đủ 16 tuổi hoặc có đồng ý của cha mẹ/người giám hộ) và nút "Đồng ý và bắt đầu". Chưa tick thì nút bị khoá. Bản ghi gồm mã học viên, phiên bản thông báo và thời điểm.
- Endpoint: `GET` và `POST /api/v1/student/chat/consent`. Gửi tin khi chưa đồng ý trả `403 CHAT_CONSENT_REQUIRED`, không trừ lượt, không gọi Gemini. Xem quota và phiên gần nhất không cần đồng ý.
- **Đổi nội dung thông báo:** sửa chữ ở `common/i18n/*.ts` (mục `chat.consent`), đổi hằng `ChatConstants.CONSENT_POLICY_VERSION` (backend) và `CHAT_CONSENT_POLICY_VERSION` (web) cùng một giá trị mới, và đưa lên cùng lúc. Mọi học viên sẽ được hỏi lại. Hai giá trị lệch nhau thì học viên không đồng ý được (lỗi 400). Có test nhắc việc này: `chat-consent-version.test.ts` ghim dấu vân tay của chữ trên màn đồng ý và hai mục chính sách (trợ lý AI, trẻ em) cạnh số phiên bản, và so với phiên bản backend khi hai repo nằm cạnh nhau. Test đỏ sau khi sửa chữ thì làm theo thông báo của nó: đổi cả hai phiên bản sang ngày hôm nay, cập nhật giá trị ghim, rồi triển khai web và backend cùng lúc.
- Chưa có nút "rút lại đồng ý" cho học viên; hiện làm bằng script ở trên theo yêu cầu. Pháp lý quyết định có cần nút này trước khi release không.
- Tác vụ đêm không xoá bản ghi đồng ý.

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

Cache khoá theo (câu hỏi chuẩn hoá, ngôn ngữ, dạng bài, đề bài đang làm nếu có, `ChatPrompts.VERSION`), **không** có tên model. Khi đổi system prompt, đổi model hoặc đổi cách từ chối: tăng `ChatPrompts.VERSION` (hiện `v3`) để các câu trả lời cũ ngừng được phát lại.

Lịch sử phiên bản: `v1` bản đầu; `v2` (2026-10-29) thêm khối "Current exercise" ngữ cảnh bài tập; `v3` (2026-10-29) chống lạm dụng: AI **không viết hộ bài hoàn chỉnh** (essay, bản tóm tắt, câu trả lời nói, đáp án chọn/điền) mà chỉ đưa dàn ý, cấu trúc, cụm từ, tối đa một hai câu ví dụ và gợi ý, rồi mời học viên tự viết và gửi lại để được nhận xét; sửa bài của chính học viên vẫn luôn được. Bỏ câu "model answers, sample responses ... are allowed" ở bản trước. Không đổi chữ học viên đồng ý nên không cần tăng phiên bản đồng ý. Đây là hành vi của mô hình ngôn ngữ, không phải cổng cứng: học viên vẫn có thể kéo AI nói thêm bằng nhiều câu hỏi liên tiếp; theo dõi qua báo cáo lượt hỏi và đọc mẫu hội thoại.

## 9. Việc chưa làm ở bản này

- Chưa đo bằng Gemini thật (không có key trong phiên làm việc): chạy bộ test prompt theo [phase-05-test-report.md](./tests/phase-05-test-report.md) trước khi bật ở production.
- Chưa kiểm tay end-to-end trên trình duyệt với backend thật (giao diện đã kiểm với API giả lập).
- Chưa có thời hạn lưu dữ liệu/xoá hội thoại (xem [privacy-handoff.md](./privacy-handoff.md)).
