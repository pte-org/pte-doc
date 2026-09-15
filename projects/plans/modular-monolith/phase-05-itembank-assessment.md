# Phase 05 — Itembank + Assessment

**Plan:** [plan.md](plan.md) · [kế hoạch tổng hợp](remaining-modules-refactor-plan.md) · **Spec:** [spec.md](spec.md)
**Covers:** Question CRUD, blueprint, immutable exam snapshot
**Nguồn:** `services/authoring` (56 file)
**Đích:** `com.pte.itembank`, `com.pte.assessment`

---

## Mục tiêu

Tách `authoring` theo bounded context thay vì chuyển nguyên một service lớn:

- `itembank` sở hữu câu hỏi và option.
- `assessment` sở hữu blueprint và snapshot đề thi.

Kết thúc phase, publish blueprint tạo ra một snapshot canonical bất biến; session có
thể đọc summary, còn attempt có thể đọc trusted full content qua public API.

---

## Design Constraints

- Dependency một chiều: `assessment → itembank → shared`.
- `assessment` không truy cập `QuestionRepository`; chỉ dùng public query/freeze
  API của `itembank` với DTO bất biến.
- Question shared chỉ được dùng theo access policy hiện có; question tenant khác
  không được lộ qua GET, list, blueprint hoặc publish.
- Giữ nguyên task type, section, visibility, question status và validation.
- Snapshot phải deep-copy prompt, reference/correct answer, audio/image ref, word
  count và toàn bộ option metadata.
- Giữ option order, `blankIndex`, `correctGapIndex` và quy tắc rotate
  `RE_ORDER_PARAGRAPHS`.
- Snapshot version tăng theo blueprint; snapshot sau publish không bị thay đổi khi
  question/blueprint gốc được sửa.
- Media reference chỉ là public ID. Không gọi MinIO trong authoring; attempt resolve
  URL ở Phase 07.
- Không mang `OutboxEntry`, `ProcessedEvent`, `ExamSnapshotPublishedEvent`,
  outbox relay hoặc snapshot consumer/cache sang app.
- Student response không được chứa answer key; trusted full content chỉ dành cho
  application call của attempt.

---

## Việc cần làm

1. **Port Itembank**
   - Port `Question`, `QuestionOption`, enum, exception, validation helper và
     access policy vào `com.pte.itembank`.
   - Tổ chức repository/mapper/service/controller dưới `internal/`.
   - Tạo public `ItembankService` cho create/get/list-accessible và DTO cần để
     assessment freeze question.

2. **Port Assessment**
   - Port `ExamBlueprint`, `BlueprintItem`, `ExamSnapshot`, `SnapshotItem`
     vào `com.pte.assessment`.
   - Port blueprint CRUD, publish, snapshot summary và trusted full-content query.
   - `SnapshotPublishService` gọi public Itembank API, không dùng repository chéo.

3. **Giữ snapshot semantics**
   - Reject blueprint rỗng.
   - Resolve từng question theo access policy trước khi copy.
   - Copy đúng field order và JSON option shape mà scoring đang parse.
   - Bảo đảm một publish request không tạo hai snapshot version do race.

4. **Port controller và contract**
   - Giữ path question/blueprint/snapshot/publish như service cũ.
   - Tách controller user-facing vào module tương ứng; trusted full-content adapter
     không expose answer key cho student.
   - Kiểm tra role AUTHOR, HOST_ADMIN, PLATFORM_ADMIN theo source.

5. **Flyway**
   - Viết `V6__itembank.sql` cho bảng question/option hiện có.
   - Viết `V7__assessment.sql` cho blueprint/item/snapshot/snapshot item.
   - Giữ tên bảng hiện tại, không tạo bảng event/outbox.

6. **Cập nhật boundary cho phase sau**
   - Public API phải đủ cho Phase 06 lấy snapshot summary.
   - Public API phải đủ cho Phase 07 lấy full content để pin đề.
   - Ghi rõ trusted caller/DTO thay vì mở repository hoặc controller nội bộ.

---

## Tests to Write First

- Question CRUD cùng tenant, shared visibility và cross-tenant denial.
- Blueprint chỉ nhận question accessible; question không tồn tại/không hợp lệ bị
  reject.
- Publish blueprint rỗng bị reject.
- Snapshot deep-copy đầy đủ field và không đổi sau khi source đổi.
- Versioning và concurrent publish không tạo duplicate snapshot sai.
- Option order, blank/gap metadata và paragraph rotation.
- Summary không chứa answer key; full content chỉ dùng ở trusted boundary.
- Modulith chặn `assessment → itembank.internal` và mọi repository cross-module.

---

## Acceptance

- [ ] CRUD question/blueprint chạy qua app với API contract cũ.
- [ ] Publish tạo đúng một snapshot immutable và version đúng.
- [ ] Session có thể lấy summary qua `AssessmentService`.
- [ ] Attempt có thể lấy full content qua trusted public API.
- [ ] Không còn `ExamSnapshotPublishedEvent`/outbox/cache flow trong app.
- [ ] `V6__itembank.sql` và `V7__assessment.sql` validate được trên Postgres.
- [ ] Test authoring nguồn và test app xanh.
- [ ] `ApplicationModules.verify()` pass với dependency một chiều.

---

## Quality and Testing State

Chưa thực thi. Cập nhật sau khi hoàn tất port và kiểm tra answer-key boundary.
