# Phase 01: schema và trạng thái

**Trạng thái:** [ ] Chưa làm · **Repo:** pte-api

## Mục tiêu

Lô và job có trạng thái tạm dừng trong DB và trong enum. Chưa có hành vi mới.

## Việc cần làm

- [ ] Migration `V60__question_generation_batch_pause.sql`:
  - Tạo lại CHECK `status` của `question_generation_batches`, thêm `PAUSING`, `PAUSED`. CHECK của V53 là inline, nên tìm theo định nghĩa giống cách V53 làm với bảng job.
  - Thêm cột `paused_at TIMESTAMPTZ NULL`.
  - Tạo lại `uk_qgen_batches_one_open_per_requester` và `ix_qgen_batches_open` với `status IN ('QUEUED','RUNNING','CANCELLING','PAUSING','PAUSED')` (D3).
  - Thêm index một phần `ix_qgen_batches_paused_at ON (paused_at) WHERE status = 'PAUSED'` cho job tự hủy.
  - Tạo lại CHECK `status` của `question_generation_jobs`, thêm `PAUSING`.
  - Không đổi `uk_qgen_jobs_one_active_per_requester`, vì index này chỉ áp cho job lẻ (`batch_id IS NULL`).
- [ ] `BatchStatus`: thêm `PAUSING`, `PAUSED`; thêm cả hai vào `OPEN`; thêm tập `PAUSABLE = {QUEUED, RUNNING}`, `RESUMABLE = {PAUSED}`, `CANCELLABLE = OPEN − {CANCELLING}`.
- [ ] `JobStatus`: thêm `PAUSING`; thêm vào `OPEN`, `LEASED` và `ACTIVE`. Job đang `PAUSING` vẫn giữ lease và chiếm luồng cho tới khi nhả, nên `topUp` không được đẩy thêm job.
- [ ] `QuestionGenerationBatch`: thêm field `pausedAt`.
- [ ] Kiểm tra mọi chỗ `switch`/`if` trên hai enum (grep `BatchStatus.` và `JobStatus.`) để không có nhánh rơi vào mặc định sai: mapper response, `BatchStatusCalculator`, query service, live feed.

## Ràng buộc thiết kế

- Migration chỉ thêm, không xóa dữ liệu. Lô `CANCELLING` đang có không bị ảnh hưởng.
- Repository dùng hằng `STATUS` sẵn có; không viết chuỗi trạng thái rời trong JPQL mới.

## Kiểm thử

- Test enum: `OPEN` chứa `PAUSING`, `PAUSED`; `TERMINAL` không chứa.
- Test migration chạy trên Postgres test DB nếu có (`lifecycle.test.db.url`); nếu không thì ghi là đã bỏ qua.
- `ModuleStructureTest`, `SourceFileSizeTest` và các ratchet kiến trúc vẫn qua.

## Tiêu chí xong

- `.\mvnw.cmd -pl app -DskipTests compile` qua; các test enum và kiến trúc qua.
- Local `local-schema` không dùng Flyway, nên phải áp migration bằng tay rồi rebuild container `app`.
