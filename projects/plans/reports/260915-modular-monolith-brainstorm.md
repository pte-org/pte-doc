# Brainstorm: Chuyển pte-api từ microservices sang modular monolith

**Date:** 2026-09-15

## Bối cảnh

Nhóm sinh viên năm 4 xây dựng nền tảng thi thử PTE gồm 11 microservice Spring Boot,
4 instance Postgres, RabbitMQ (outbox + projection), Redis, MinIO, và 2 app Next.js.
Hệ thống đã deploy và chạy thật tại `pte-tenant.duckdns.org`.

Phiên brainstorm bắt đầu ngay sau khi sửa một bug production: trang Students trả về
rỗng trong khi trang Overview hiện đủ dữ liệu. Nguyên nhân là projection
`student_roster_entries` của service `admin` chưa bao giờ được backfill — các event
`UserCreated` mà IAM publish trước khi queue `admin.user-events` tồn tại đã bị topic
exchange loại bỏ. Bug đó trở thành ví dụ cụ thể cho chi phí của kiến trúc hiện tại.

## Ideas Explored

- **Giữ microservices, bổ sung tài liệu + tracing** — Ít rủi ro nhất, nhưng không
  giải quyết được vấn đề gốc: chủ sở hữu không giải thích được hệ thống của mình.
  Loại.
- **Tách theo vai trò thành 3 service (admin / host / student)** — Ý định ban đầu
  của nhóm. Loại vì cả ba vai trò thao tác trên cùng một tập dữ liệu (student, exam,
  result), nên mỗi service đều cần toàn bộ dữ liệu — đúng anti-pattern đang gây đau.
- **Gộp một phần, còn 2–3 service** — Vẫn phải sống chung với đồng bộ dữ liệu ở các
  đường ranh còn lại. Không đáng, vì không có ràng buộc scale nào bắt buộc phải tách.
- **Monolith phân tầng cổ điển (controller/service/repository)** — Dễ hiểu ở quy mô
  nhỏ, nhưng ~11 domain sẽ tạo ra những thư mục hàng chục file. Loại.
- **Monolith gộp to, 6 module trừu tượng** (`identity`, `academic`, `delivery`…) —
  Loại vì tái lập đúng vấn đề của tên `admin` / `authoring` / `exam-delivery` hiện
  nay: tên module không tự nói lên nó chứa gì.
- **Modular monolith, 11 module theo danh từ nghiệp vụ** — Được chọn.

## Phát hiện chính trong quá trình brainstorm

**1. Trục tách của backend và frontend không khớp nhau.**
Nhóm định tách theo vai trò, nhưng backend thực tế được tách theo năng lực nghiệp vụ
(`iam`, `authoring`, `scoring`, `media`…), trong khi frontend lại tách theo vai trò
(`tenant-web`, `vendor-web`). Câu hỏi "code của host nằm ở đâu?" không có câu trả
lời, vì nó nằm rải khắp 11 service. Đây là nguyên nhân trực tiếp của việc "không
hiểu được cấu trúc" — người đọc đang tìm một cấu trúc không tồn tại trong code.

**2. 21% codebase không phục vụ nghiệp vụ nào.**
Đo trên code thật: 140/639 file Java trong `src/main` tồn tại chỉ để các service đồng
bộ với nhau (outbox, consumer, projection, idempotency guard, snapshot pinning, export
client). 19 bảng database cùng loại — `OutboxEntry` bị nhân bản 8 lần, `ProcessedEvent`
7 lần. Toàn bộ số này biến mất trong monolith một database.

**3. Ý tưởng tách theo vai trò của nhóm đúng, chỉ sai tầng áp dụng.**
Thất bại khi làm ranh giới service, nhưng hoạt động tốt khi làm ranh giới package —
vì trong monolith mọi module dùng chung một domain layer và một database.

## User's Direction

Chuyển sang **modular monolith** với 11 module đặt tên theo danh từ nghiệp vụ, kiểu
`order` / `product` / `customer` của một dự án e-commerce.

Lý do người dùng đưa ra, nguyên văn: *"chúng tôi không thể hiểu được sản phẩm thì
không thể nào tự tin mà phỏng vấn được"*. Đây là tiêu chí quyết định — ưu tiên khả
năng đọc hiểu và trình bày được hệ thống, cao hơn mọi tiêu chí kỹ thuật khác.

Quyết định đã chốt:
- **12 module** đặt tên theo *bounded context* chứ không theo entity. Quy tắc áp
  dụng: module là một năng lực nghiệp vụ, nên `identity` (không phải `user`),
  `tenancy` (không phải `tenant`), `enrollment` (không phải `program`), `proctoring`
  (quy trình, không phải `proctor` là người), `reporting` (năng lực, không phải
  `report` là sản phẩm). `exam` bị tách đôi thành `assessment` (đề thi) và `session`
  (ca thi) vì đó là hai khái niệm khác nhau.
- Dùng **thuật ngữ chuẩn ngành khảo thí** (IMS QTI): `itembank`, `assessment`,
  `attempt`.
- Sáu module cốt lõi xếp thành dây chuyền đọc được thành câu — dùng làm xương sống
  khi trình bày: `itembank → assessment → session → attempt → scoring → reporting`.
- **Spring Modulith** đầy đủ: quy ước `internal/` cho chi tiết nội bộ,
  `ApplicationModules.verify()` chặn vi phạm ranh giới ngay trong test suite, và
  sinh sơ đồ module tự động từ code cho báo cáo đồ án.
- Phép so sánh làm xương sống để hiểu hệ thống: **`attempt` chính là `order`**.
  Student tạo Attempt chứa các Question, rồi Scoring chấm — giống Customer đặt Order
  chứa Product rồi Payment xử lý.
- **Giữ toàn bộ stack công nghệ**: MinIO, RabbitMQ, Redis, Postgres, Docker,
  OpenTelemetry. Thêm load balancer.
- **RabbitMQ đổi mục đích**: từ đồng bộ dữ liệu giữa service sang *queue-based load
  leveling*. Người dùng tự nêu đúng tình huống: *"1000 người cùng nộp thì hệ thống sẽ
  vỡ mất"* — nhận bài nhanh, trả 202, worker chấm dần.
- Câu chuyện scaling: LB lo burst HTTP, queue lo việc nặng phía sau, Redis giữ app
  stateless để nhân bản.

Cách thực hiện migration: **người dùng hoãn quyết định** đến sau khi chốt cấu trúc.

## Open Questions

Những mục `/ck:plan` phải xử lý:

1. **Cách migration** — port code cũ sang cấu trúc mới, viết lại từ đầu, hay gộp dần
   giữ prod chạy. Người dùng chưa quyết.
2. **Chiến lược database** — một schema duy nhất, hay schema-per-module trong cùng
   một Postgres. Ảnh hưởng trực tiếp đến việc có giữ được ranh giới module hay không.
3. **Số phận bản deploy hiện tại** — giữ song song để bảo vệ đồ án, hay cutover dứt
   điểm.
4. **Snapshot/pinning có phải nghiệp vụ thật không** — `ExamSnapshot`, `PinnedExamSnapshot`,
   `SnapshotRef` hiện tồn tại 3 bản ở 3 service. Bất biến của đề thi khi đang thi là
   yêu cầu nghiệp vụ hợp lệ, nhưng chỉ cần **một** bản trong monolith.
5. **Dữ liệu prod hiện có** — có cần migrate từ 4 Postgres về 1 không, hay chấp nhận
   khởi tạo lại từ đầu.

## Risks

1. **Migration nửa chừng rồi bỏ dở** — rủi ro lớn nhất. Kết quả tệ hơn cả hai phương
   án: vừa có microservice, vừa có monolith, không hiểu cái nào. Giảm thiểu bằng cách
   chia mốc theo module và luôn giữ trạng thái build được.
2. **Mất hành vi đã chạy đúng** — 639 file có chứa những xử lý biên đã được sửa qua
   thời gian (ví dụ `saveAndFlush` trước khi ghi outbox để lấy `createdAt`). Viết lại
   từ đầu dễ đánh rơi những chỗ này.
3. **Không còn đủ thời gian cho tính năng nghiệp vụ** — 3 tháng đủ để gộp, nhưng nếu
   migration nuốt hết thì đồ án không có gì mới để trình bày.
4. **Nhận thức của hội đồng** — nếu đề tài đã đăng ký là "microservices platform",
   việc đổi kiến trúc cần được giải thích trước, không phải đến lúc bảo vệ mới nói.
   Đây là rủi ro phi kỹ thuật nhưng có thật.
5. **Bỏ luôn RabbitMQ vì tưởng nó thuộc về microservices** — cần tách bạch rõ: đồng
   bộ dữ liệu giữa service (bỏ) khác với load leveling (giữ).
