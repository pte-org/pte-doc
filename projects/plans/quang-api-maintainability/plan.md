# Plan: Trả nợ bảo trì pte-api — `Clock` thống nhất, tách file > 300 dòng, gom thư mục

Status: 📝 Draft — chờ duyệt
Date: 2026-10-25
Mode: Hard
Test: mỗi phase chạy `./mvnw.cmd -pl app clean test` (kèm DB test Postgres theo `quang-entity-consolidation/local-dev-runbook.md`) + quality gate `ck:quality --gate`
Created by: quang
Bắt đầu sau khi: nhánh gộp entity (`quang/feat/maintain-v2`) đã review và merge, để diff không trộn.
Branch đề xuất: `quang/refactor/api-maintainability` (tách từ nhánh đã merge). Agent KHÔNG commit/push.

## Overview

Ba loại nợ có sẵn trong `pte-api/app/src/main/java/com/pte` (số liệu đo ngày 2026-10-25):

| Nợ | Số liệu | Hậu quả |
|---|---|---|
| Lấy giờ trực tiếp (`Instant.now()`, `LocalDateTime.now()`...) thay vì `Clock` | 69 chỗ / ~50 file, 5 trong entity (`ExamAttempt`, `NotificationLog`, `ExamIncident`, `AiEvaluation`, `Organization`); 43 file đã dùng `Clock` | Test không cố định được thời gian; hai kiểu lấy giờ song song |
| File vượt 300 dòng (giới hạn trong `CODING_STANDARDS_API.md`) | 23 file, lớn nhất `ItembankService` 828, `ExamDefinitionAdminService` 735, `QuestionTypeService` 689, `ExaminerScoringService` 617 | Khó review, nhiều trách nhiệm trong một lớp |
| Thư mục phẳng quá đông | `session/internal/exception` 55 file, `scoring/internal/service` 38, `session/internal/service` 30, `billing/internal/exception` 20... | Khó tìm, khó theo dõi thay đổi |

Plan **không đổi hành vi, API, schema hay mã lỗi**. Chỉ dời code, tách lớp và thay nguồn thời gian.

## Quy tắc chung (áp dụng mọi phase)

1. **Đọc chuẩn trước khi sửa:** `docs/CODING_STANDARDS_API.md` đầy đủ; thêm `API_RESPONSE_SETUP.md` / `COMMON_EXCEPTION_SETUP.md` khi chạm exception hoặc handler. Ghi standards-read note vào progress update đầu tiên.
2. **Thời gian:** mọi lớp Spring lấy giờ qua `Clock` inject (bean `shared/config/ClockConfig`). Entity/domain không gọi `now()`: nhận `Instant` làm tham số (ví dụ `attempt.submit(clock.instant())`). Đường scheduled cũng dùng `clock.instant()`.
3. **Tách file:** mỗi file ≤ 300 dòng. Tách theo trách nhiệm (command / query / validator / mapper / policy), đặt tên theo việc nó làm, không dùng tên chung chung `*Helper`/`*Utils` khi có tên rõ hơn. **Facade công khai của module** (`ItembankService`, `IdentityService`, `SessionService`... ở gốc module) giữ nguyên chữ ký public để module khác không phải sửa; phần thân chuyển vào service `internal/` và facade chỉ ủy quyền.
4. **Gom thư mục:** thư mục `internal/**` có > 15 file cùng loại thì gom vào package con theo khái niệm nghiệp vụ (ví dụ `exception/attendance/`, `service/examiner/`). Mỗi package con nên có từ 3 file trở lên, không tạo package một file.
5. **Không gom package công khai có `@NamedInterface`** (`*/dto/response`, `*/dto/event`, `*/domain/enums`...): Spring Modulith chỉ xuất đúng package đó, dời vào package con sẽ phá ranh giới module. Các package này giữ phẳng (ngoại lệ có chủ đích, ghi trong phase 1).
6. **Không đổi:** endpoint, JSON, mã lỗi, message (`*Constants`), tên bảng/cột, thứ tự giao dịch. Chuyển package của exception không đổi `code` trả về.
7. **Gate mỗi phase:** `./mvnw.cmd -pl app clean test` xanh (gồm `ModuleStructureTest`, `ApiInventoryExportTest` vẫn 260 endpoint); 42 test Postgres xanh trên container `pte-test-pg`; Docker app healthy + đăng nhập `admin@test.local`, `host.e2e@test.local`; `ck:quality --gate` APPROVED.

## Phases

- [ ] Phase 1: Hàng rào kiểm tra — [phase-01-guardrails.md](phase-01-guardrails.md) — test kiến trúc chặn `now()` và file > 300 dòng (allowlist chỉ được co lại), quy tắc gom thư mục
- [ ] Phase 2: `Clock` toàn bộ — [phase-02-clock.md](phase-02-clock.md) — thay 69 lời gọi `now()`, entity nhận `Instant`
- [ ] Phase 3: Gom exception và DTO nội bộ — [phase-03-group-internal-packages.md](phase-03-group-internal-packages.md) — `session/internal/exception` (55), `billing/internal/exception` (20), các `internal/dto/*` > 15 file
- [ ] Phase 4: itembank + assessment — [phase-04-itembank-assessment.md](phase-04-itembank-assessment.md) — `ItembankService` 828, `QuestionTypeService` 689, `ExamDefinitionAdminService` 735, `ExamGenerationService` 340, `SnapshotPublishService` 311
- [ ] Phase 5: scoring — [phase-05-scoring.md](phase-05-scoring.md) — 6 file lớn + gom `scoring/internal/service` (38 file) theo nhóm examiner / ai / objective / review / grading
- [ ] Phase 6: attempt + session — [phase-06-attempt-session.md](phase-06-attempt-session.md) — `AttemptLifecycleService` 597, `CapabilityNegotiationService` 520, `ProctorMonitoringQueryService` 344, `SessionService` 319 + gom `session/internal/service` (30)
- [ ] Phase 7: billing, identity, tenancy, media, practice — [phase-07-remaining-modules.md](phase-07-remaining-modules.md) — 8 file lớn còn lại
- [ ] Phase 8: Chốt — [phase-08-finalize.md](phase-08-finalize.md) — allowlist rỗng, cập nhật tài liệu, báo cáo

## Dependencies

- Phase 1 trước tất cả (để mỗi phase sau chỉ được làm allowlist nhỏ đi).
- Phase 2 trước 4–7: tách file sau khi đã đổi sang `Clock` để không sửa một chỗ hai lần.
- Phase 3 độc lập với 4–7 nhưng chạy trước để các phase sau import đúng package mới.
- Phase 4–7 độc lập nhau, có thể đổi thứ tự.

## Rủi ro chính

| Rủi ro | Giảm thiểu |
|---|---|
| Dời package làm hỏng ranh giới Modulith | Chỉ gom `internal/**`; `ModuleStructureTest` chạy mỗi phase |
| Tách service làm đổi ranh giới `@Transactional` / proxy (gọi nội bộ `this.x()` thành gọi bean khác) | Ghi rõ trong phase: method nào đang dựa vào self-invocation; giữ ranh giới giao dịch cũ; test Postgres race/rollback phải xanh |
| Diff lớn khó review (chuẩn giới hạn PR 400 dòng logic) | Dời file thuần (`git mv` + sửa import) để riêng một commit với tách logic; người dùng tự commit theo từng phase |
| `@MockitoBean` trong test trỏ lớp cũ | Sửa test cùng phase; không xoá test để cho qua |
