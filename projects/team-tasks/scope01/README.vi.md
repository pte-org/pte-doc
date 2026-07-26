# Chia việc cho team — Bàn giao sau phần Backend

*[English version](README.md)*

## Tình trạng hiện tại

`pte-api` (backend) Phase 0–11 đã **xong và được quality-approved** (`ck:quality --gate` APPROVED cho từng phase — xem `../plan.md` và `../quality/phase-*-receipt.json`). 12 service + gateway, build sạch trên cùng 1 Maven reactor.

**"Xong" ở đây KHÔNG có nghĩa là:**
- **Chưa từng chạy runtime.** Mỗi phase chỉ được verify bằng `mvn install` (compile + quality review) thôi. Chưa ai từng chạy `docker compose up` rồi gọi thử request thật vào các service này. Chắc chắn sẽ có bug runtime lộ ra.
- **Chưa có test tự động nào.** Cả project chạy chế độ "quality only, không test" theo quyết định rõ ràng của bạn từ đầu — không có unit/integration test nào trong `pte-api`.
- **Chấm điểm AI vẫn là stub.** `StubSpeechScoringClient`/`StubEssayScoringClient` của `scoring` trả điểm giả cố định, không gọi mạng thật. Xem `../phase-09-media-speaking-writing-ai-vendor.md` để biết interface seam và các phát hiện đã live-test (cách parse response của reasoning model) để dùng lại khi nối vendor thật.
- **`pte-app` (Flutter) chưa đụng tới** — thư mục `pte-app/` hiện tại là scaffold từ trước pivot, tên `aptis_app`, chỉ có 1 commit ("init"), trỏ tới backend khác (`api.aptis.example.com`). Không chung contract gì với `pte-api`. Phần `core/` (Dio client, Drift offline-outbox, timer service, sync engine) có kiến trúc khá generic — có thể tái dùng được — nhưng đây là **quyết định chưa chốt**. Cần thống nhất với leader trước khi Member 2/3 code (xem file task của họ).
- **WebSocket qua gateway (proctor) chưa verify** — đã cấu hình đúng theo pattern chuẩn của Spring Cloud Gateway (phase-10) nhưng chưa từng kết nối thử thật.

## Chia 4 người

| # | Trọng tâm | Phụ thuộc |
|---|---|---|
| [Member 1](member_1/tasks.md) | Verify runtime backend, fix bug, viết integration test cho critical path | Không phụ thuộc gì — bắt đầu ngay |
| [Member 2](member_2/tasks.md) | Flutter: luồng thi của student (auth, 3 loại task, timer, submit) | Backend phải chạy được thật (Member 1); có thể vừa làm UI song song theo contract đã tài liệu hóa |
| [Member 3](member_3/tasks.md) | Flutter: host mini-console (author, tạo session, enroll, chấm, publish, review) | Giống Member 2 |
| [Member 4](member_4/tasks.md) | Nối AI vendor thật + Dockerize service + CI | Phần AI vendor cần API key thật (phụ thuộc bên ngoài, không phải Member 1); Dockerize/CI làm được ngay |

**Gợi ý thứ tự làm:** Member 1 nên dựng stack chạy được và smoke-test critical path (onboard → author → schedule → thi → chấm → publish → report) trước tiên — vì mọi người còn lại đều cần cái này để test tích hợp. Member 2–4 có thể vừa code song song theo contract REST đã có (file controller + DTO của từng service là nguồn chuẩn — chưa có OpenAPI spec sinh sẵn) và tích hợp vào backend thật khi Member 1 xác nhận ổn định.

## Tài liệu nên đọc trước

- `../plan.md` — toàn bộ danh sách phase, Design Constraints, Risks (đặc biệt mục "Red-team findings" — vấn đề nguồn thời gian làm bài per-task vẫn chưa giải quyết, và risk RLS+PgBouncer áp dụng cho ai thêm connection pooling sau này).
- `../../architecture/ADR-001-microservice-boundaries.md` / `ADR-002-communication-and-exam-submission-saga.md` / `ADR-003-tenant-isolation-and-infrastructure.md` / `ADR-004-per-service-code-structure.md`.
- Từng file `../phase-XX-*.md` — mục "Quality and Testing State" và "Risks" ghi rõ cái gì đã verify, cái gì còn để đó, theo từng service.
- `docs/CODING_STANDARDS_MICROSERVICE.md` (pte-api) và `docs/CODING_STANDARDS_APP.md` (pte-app) — quy chuẩn bắt buộc tuân theo, không phải tùy chọn.

## Nguyên tắc chung

- Đừng redesign lại cái đã quality-approved. Nếu tìm ra bug thật, sửa gọn đúng chỗ và ghi chú vào mục "Runtime-verification TODO" / "Risks" của phase doc liên quan — đừng thiết kế lại cả service quanh cái bug đó.
- Đừng commit khi chưa tự review lại — mỗi phase trong project này đều qua quality gate trước khi được coi là xong, giữ đúng chuẩn đó.
- Nếu bị chặn bởi 1 quyết định chỉ leader mới quyết được (chọn kiến trúc, cắt scope, chọn vendor), dừng lại hỏi — đừng đoán rồi code tiếp trên cái đoán đó.
