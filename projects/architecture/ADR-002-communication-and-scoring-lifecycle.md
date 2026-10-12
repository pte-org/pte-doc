# ADR-002: Giao tiếp giữa module & vòng đời chấm điểm

**Date:** 2026-07-24 · **Viết lại 2026-09-16** theo kiến trúc Spring Modulith
**Status:** Accepted
**Depends on:** [ADR-001](ADR-001-module-boundaries.md)

> **Lịch sử:** bản gốc mô tả **async-first + Transactional Outbox + choreography saga** trên Kafka (sau đổi sang RabbitMQ + polling outbox relay). Sau khi thu gọn về monolith, **outbox và saga không còn tồn tại trong code** — không có entity `OutboxEntry`, không có relay, không có `ProcessedEvent`. Giao tiếp xuyên module nay là **lời gọi hàm in-process**. Phần nghiệp vụ *host-gated scoring* thì không đổi và vẫn là quyết định trung tâm của ADR này.

---

## Decision

**Gọi trực tiếp in-process qua facade module cho mọi luồng đồng bộ.** RabbitMQ chỉ giữ đúng một vai: **work-queue** cho việc chậm và có thể thất bại độc lập (chấm AI, gửi email). Không có event backbone, không outbox, không saga phân tán.

Lý do: trong một tiến trình, "phát event để module khác xử lý" không mua được gì mà mất tính nguyên tử. Dual-write bug — thứ mà outbox sinh ra để giải — **không tồn tại** khi hai thao tác nằm trong cùng một transaction JPA.

---

## Ma trận giao tiếp

| Từ | Tới | Kiểu | Ghi chú |
|---|---|---|---|
| `session` | `assessment` | gọi hàm | `AssessmentService.getSummary` — giải snapshot lúc tạo kỳ thi |
| `attempt` | `session` | gọi hàm | `SessionService.checkEntitlement` — **chỉ lúc tạo attempt**, không gọi giữa lúc thi |
| `attempt` | `assessment`, `media` | gọi hàm | Pin snapshot, lấy presigned URL |
| `proctoring` | `session` | gọi hàm | `SessionService.checkProctorAssignment` |
| `scoring` | `session` | gọi hàm | `SessionService.verifyHostAccess` — host có sở hữu kỳ thi không |
| `scoring` | RabbitMQ | **work-queue** | `AiScoringDispatcher` → `AiScoringWorker`, gọi AI vendor |
| `notification` | RabbitMQ | **work-queue** | `NotificationDispatchService` → `EmailWorker` |

**Auth:** `identity` ký JWT RS256. Resource server validate cục bộ bằng public key — không tra DB mỗi request.

---

## Vì sao RabbitMQ vẫn còn, dù đã là monolith

Hai công việc trong hệ này có tính chất mà lời gọi hàm không phục vụ được:

| | Chấm AI | Gửi email |
|---|---|---|
| Thời gian | Hàng giây tới hàng phút mỗi câu | Hàng giây |
| Thất bại | Vendor timeout, rate limit, lỗi tạm | SMTP down |
| Cần | Retry có backoff, DLQ, chạy song song nhiều worker | Retry, không chặn caller |

Để chúng chạy đồng bộ trong request thread nghĩa là host bấm "chấm" rồi ngồi chờ vài phút, và một lỗi vendor làm hỏng cả request. Queue là đúng công cụ — **nhưng chỉ cho hai việc này**, không phải cho mọi giao tiếp xuyên module.

**Ranh giới phải giữ:** RabbitMQ ở đây là *work-queue* ("việc cần làm, một bên xử lý"), không phải *event backbone* ("chuyện đã xảy ra, nhiều bên quan tâm"). Lẫn hai vai là nguồn nhầm phổ biến nhất khi hệ lớn lên.

---

## Vòng đời chấm điểm — HOST-GATED, không tự động

Đây là quyết định nghiệp vụ, **không đổi qua cả hai kiến trúc**.

Scoring **không** tự chạy khi sinh viên nộp. Trigger là **lệnh của host**, và có **cổng publish do host quyết định**. Hai điểm người-trong-vòng-lặp: (1) *khi nào* chấm, (2) *có* cho sinh viên thấy không. Khớp với việc Pearson có human-review-on-top-of-AI cho một số task type — cổng publish là chỗ human moderation sống.

```
AttemptAnswer / Attempt:
  SUBMITTED ──(host kích hoạt chấm)──> SCORING ──> SCORED ──(host publish)──> PUBLISHED
                                                     │
                                         host review/điều chỉnh ở đây
```

- **SUBMITTED** — sinh viên nộp xong, lưu, **không** chấm, **không** auto-trigger.
- **SCORING → SCORED** — host bấm chấm → điểm tính và lưu nội bộ, sinh viên **chưa** thấy.
- **PUBLISHED** — host review → publish → sinh viên mới thấy report.

### Luồng

```
1. Sinh viên nộp bài
   └─ attempt: 1 transaction → INSERT AttemptAnswer (status=SUBMITTED)
      Không phát gì, không kích hoạt gì.

2. Host chủ động phát lệnh "chấm kỳ thi X"
   └─ scoring: kiểm quyền qua SessionService.verifyHostAccess
      → AiScoringDispatcher đẩy job vào RabbitMQ

3. AiScoringWorker (idempotent theo answerId):
   ├─ task khách quan  → chấm rule-based (ObjectiveScoringService)
   └─ speaking/writing → gọi AI vendor → fail thì retry, hết retry thì DLQ
   → status = SCORED. Nội bộ, sinh viên chưa thấy.

4. Host review → phát lệnh publish → status = PUBLISHED
   → reporting expose report cho sinh viên
```

**Nguyên tắc:**
- Nộp bài **không bao giờ** kéo theo chấm.
- **Cổng publish thuộc quyền host.** Không phải "chấm xong tự hiện".
- `scoring` chỉ **thực thi khi được lệnh**, không tự quyết.
- `reporting` chỉ expose attempt ở trạng thái `PUBLISHED`; `SCORED`-chưa-publish chỉ host thấy.
- **Sau khi nộp, không luồng nghiệp vụ nào ghi ngược vào `attempt`.** Điểm sống ở `scoring`, projection sống ở `reporting`; `ExamAttempt` không mang trạng thái SCORED/PUBLISHED. Đây là thứ giữ cho bất biến #1 của ADR-001 còn nghĩa.

---

## Cross-cutting bắt buộc

- **Idempotency ở worker.** RabbitMQ là at-least-once → `AiScoringWorker` phải dedup theo `answerId`. Đây là nơi **duy nhất** còn cần idempotency; các lời gọi khác nằm trong transaction nên không có vấn đề giao lại.
- **Tracing.** OpenTelemetry (`micrometer-tracing-bridge-otel` + OTLP exporter → Jaeger). Vẫn cần dù là monolith: đường đi từ lệnh chấm tới AI vendor tới DB vẫn cắt qua một queue.
- **Retry.** `spring-retry` cho lời gọi vendor. Không có Resilience4j; không còn lời gọi mạng nội bộ nào để mà cắt. (Lời gọi tới vendor AI thì có retry và circuit breaker tự viết — xem Amendment 2026-10-12.)
- **Payload queue là JSON** (Jackson). Thêm field mới phải nullable — message đang nằm trong queue lúc deploy sẽ được consumer phiên bản mới đọc.

---

## Consequences

**Được:** không dual-write bug, không eventual consistency giữa các bước nghiệp vụ, không cần dedup ở mọi consumer, không cần tracing để hiểu một luồng đơn giản. Nộp bài không bị chặn bởi chấm chậm — vẫn giữ được, vì chấm vốn đã tách bằng lệnh của host chứ không bằng kiến trúc.

**Trả giá:**
- **Mất log sự kiện.** Không có event stream để dựng lại lịch sử hay để module mới bắt kịp. Muốn audit thì phải chủ động ghi.
- **Mất load-leveling cho write spike.** 500 sinh viên nộp cùng lúc đập thẳng vào DB, không có queue đứng giữa điều tiết.
- **RabbitMQ sập** → không chấm được, không gửi email được. Bài thi và việc nộp bài không ảnh hưởng.
- **Không còn ranh giới nào ép việc "không ghi ngược vào attempt".** Trước đây là ranh giới service; nay chỉ là quy ước.

---

## Amendment 2026-10-12 — chấm AI bằng Azure + Gemini (plan `phat-ai-scoring`)

Phần nghiệp vụ trung tâm **không đổi**: scoring vẫn do host kích hoạt, vẫn có cổng publish. **Thời điểm chấm không đổi** — nộp bài không kéo theo chấm, chỉ lệnh của host mới đẩy job. Những điểm sau được bổ sung:

1. **Chi tiết AI lưu trong bảng riêng** `scoring_answer_ai_details` (một dòng cho mỗi câu, unique theo `answer_public_id`), không nhét vào `ScoringAnswer`. Dòng chấm giữ điểm và trạng thái; bảng chi tiết giữ tiêu chí, transcript, nhận xét, model, cờ fallback. Chi tiết này chỉ trả ra qua API của host và examiner, không có trong response của sinh viên.
2. **Message chỉ gửi sau khi transaction commit, và mang dispatch token.** `AiScoringDispatcher` đặt dòng sang `AI_SCORING` kèm token trong transaction, commit xong mới đẩy job (chỉ chứa id + token, không chứa audio hay bài viết). `AiScoringWorker` đọc nội dung từ dòng và chỉ chạy khi dòng còn chờ đúng token đó; redelivery hoặc job cũ gặp dòng đã kết thúc/đã gửi lại token mới thì bị bỏ qua và không gọi vendor lần nữa. Message vào DLQ chỉ đánh dấu `SCORING_FAILED` (`INTERNAL_ERROR`) khi token còn khớp.
3. **Chấm lại.** Host bấm chấm lại sẽ gửi lại các câu `SCORING_FAILED` và các câu `AI_SCORING` quá hạn (`staleDispatchMinutes`, tức job coi như mất). Mỗi lần gửi lại cấp token mới nên kết quả muộn của lần gửi trước không ghi đè.
4. **Gọi vendor.** Retry và circuit breaker nằm trong `ProviderGuard` quanh từng vendor; mọi câu lỗi kết thúc ở `SCORING_FAILED` với một `AiFailureReason` (chỉ là mã phân loại, không chứa nội dung). Không log audio, transcript, bài viết hay body trả về của vendor; key chỉ đọc từ biến môi trường; URL presigned của audio có TTL ngắn (mặc định 120 giây, tối đa 900 giây).
5. **Examiner luôn thấy điểm AI.** Trước đây examiner chấm mù. Nay màn hình examiner luôn hiển thị điểm AI và chi tiết đi kèm.
   - **Hạn chế đã biết:** examiner có thể bị điểm AI kéo theo (anchoring). Tín hiệu "lệch ≥ 20 điểm giữa AI và examiner" vì thế yếu đi: hai điểm không còn độc lập, nên độ lệch nhỏ không còn chứng minh hai bên cùng đánh giá đúng.
   - Giảm nhẹ: điểm AI chỉ là gợi ý, điểm cuối vẫn là điểm của examiner/host; host vẫn publish thủ công.
