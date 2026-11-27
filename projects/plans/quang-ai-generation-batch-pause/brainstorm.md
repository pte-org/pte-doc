# Brainstorm: tạm dừng và tiếp tục lô sinh đề AI

**Ngày:** 2026-11-27 · **Tác giả:** quang · **Trạng thái:** đã chốt hướng, chờ `/ck:plan`

## Vấn đề

Một lô sinh đề (ví dụ 85 câu, chạy 30–60 phút) hiện chỉ có **Hủy lô**. Người dùng muốn dừng giữa chừng (để xem kết quả, đổi model, hết giờ làm) rồi chạy tiếp mà không mất phần đã làm và không phải tạo lại lô.

## Hiện trạng đã xác minh trong code

| Thành phần | Thực tế |
|---|---|
| Lô | `BatchStatus`: `QUEUED, RUNNING, CANCELLING` (mở) → `COMPLETED, PARTIALLY_COMPLETED, FAILED, CANCELLED`. Cờ `cancel_requested`. |
| Job con | `BatchSplitter` cắt lô thành job tối đa `perJob` câu (1..10). Job chờ ở `PENDING`, `BatchChainingService.topUp` đẩy lên `QUEUED` theo `maxConcurrentJobs`. |
| Worker | `GenerationJobRunner` chạy từng câu; trước mỗi câu đọc `LeaseState` (`CANCEL_REQUESTED`, `LOST`). |
| Ngắt ngay | Hủy lô đã ngắt được lời gọi AI đang chạy: `GenerationCancelRequested` → `QuestionGenerationWorker.onCancelRequested` → `task.cancel(true)`. |
| Câu dở | `pendingIndexes` trả mọi câu chưa ở trạng thái cuối, kể cả câu đang `GENERATING`. Job mất lease thì job đó chạy lại câu dở từ đầu. Pipeline đã chịu được việc chạy lại. |
| Quota | Trừ một lần cho cả lô lúc gửi (`GenerationQuotaGuard`). |
| Một lô mở | Unique index `uk_qgen_batches_one_open_per_requester` trên các trạng thái mở. |

## Quyết định của người dùng

1. **Dừng ngay lập tức:** ngắt lời gọi AI đang chạy. Câu bị ngắt được viết lại từ đầu khi tiếp tục.
2. **Lô tạm dừng quá 24 giờ thì tự hủy.**
3. **Lô đang tạm dừng vẫn tính là lô đang mở:** không được tạo lô khác cho tới khi tiếp tục hoặc hủy.

## Các hướng đã cân nhắc

| Hướng | Ưu | Nhược | Kết luận |
|---|---|---|---|
| A. Ngừng đẩy job mới, job đang chạy chạy hết | Ít code nhất | Có thể mất vài phút mới dừng hẳn | Người dùng không chọn |
| B. Dừng ở ranh giới câu | Không phí token | Phải chờ câu hiện tại (30 giây–2 phút) | Người dùng không chọn |
| **C. Ngắt ngay, trả câu về hàng chờ** | Dừng trong khoảng 1 giây, đúng nghĩa "tạm dừng" | Phí token của câu bị ngắt; phải tách đường "dừng" khỏi đường "hủy" | **Chọn** |

Hướng C rẻ hơn tưởng tượng, vì đường ngắt (`task.cancel(true)`) và việc chạy lại câu dở đã có sẵn. Việc chính là **tách kết quả "tạm dừng" khỏi "hủy"**: câu và job quay về hàng chờ, không bị đóng `CANCELLED`.

## Thiết kế đề xuất

### Trạng thái

- **Lô:** thêm `PAUSING` (đang ngắt các job đang chạy) và `PAUSED`. Cả hai nằm trong `BatchStatus.OPEN`, nên unique index một-lô-mở giữ nguyên, đúng quyết định 3. Thêm cột `paused_at` để tính hạn 24 giờ.
- **Job:** thêm `PAUSING` (giống `CANCELLING`: worker đang giữ lease, đã được yêu cầu dừng). Khi worker dừng xong, job **quay về `PENDING`** chứ không đóng. Không cần trạng thái `PAUSED` riêng cho job.
- **Câu:** câu bị ngắt quay về `QUEUED`, xóa bản nháp, review và media dở của vòng đó. Câu đã `SAVED`/`FAILED` giữ nguyên.

### Luồng tạm dừng (`PATCH /batches/{id}/status {action: PAUSE}`)

Dùng chung khóa thứ tự (lô trước, job sau) như `cancel`:

1. Cập nhật có điều kiện `RUNNING|QUEUED → PAUSING`, ghi `paused_at`.
2. Job `QUEUED` chưa được nhận thì về lại `PENDING`.
3. Job đang giữ lease (`RUNNING`) chuyển sang `PAUSING`, rồi phát `GenerationPauseRequested` sau commit. Worker gọi `task.cancel(true)` giống hủy.
4. Runner thấy bị ngắt, đọc lại trạng thái job:
   - `PAUSING` thì trả câu dở về `QUEUED`, job về `PENDING`, nhả lease.
   - `CANCELLING` thì vẫn hủy như cũ.
   Phải đọc lại vì cờ ngắt của luồng không cho biết lý do.
5. Hook `onChildTerminal` hoặc reconcile: lô `PAUSING` không còn job nào đang giữ lease thì chuyển sang `PAUSED`. `topUp` **không đẩy job mới** khi lô `PAUSING|PAUSED`.

### Luồng tiếp tục (`action: RESUME`)

`PAUSED → RUNNING`, xóa `paused_at`, gọi `topUp(batchId)`. Các job `PENDING` chạy theo đúng thứ tự `batch_seq` cũ. Câu bị ngắt được viết lại từ vòng 1.

Tiếp tục khi lô còn `PAUSING` sẽ bị từ chối, trả `409 GENERATION_BATCH_NOT_RESUMABLE`. Nút trên giao diện bị khóa trong lúc `PAUSING`, thường chỉ kéo dài khoảng 1 giây.

### Hủy khi đang dừng

`cancel` nhận thêm `PAUSING|PAUSED`. Các job `PENDING` bị hủy như cũ. Lô `PAUSED` không còn job đang chạy nên đóng `CANCELLED` ngay.

### Tự hủy sau 24 giờ

Job định kỳ (cùng chỗ với `BatchReconciler`) tìm lô `PAUSED` có `paused_at < now - 24h`, rồi gọi đúng đường hủy với người thực hiện là hệ thống. Audit ghi `BATCH_EXPIRED_WHILE_PAUSED`.

### Quota (đã xác minh)

`GenerationQuotaGuard` đếm **số câu đã đặt** (`requested_count`) của các job **tạo trong ngày UTC**, trừ job `CANCELLED` mà chưa từng chạy (`started_at is null`, xem `NOT_REFUNDED` trong `GenerationJobRepository`). Vì vậy:

- **Hủy, kể cả tự hủy sau 24 giờ, tự hoàn quota** cho các job con chưa từng chạy. Không cần viết thêm code hoàn quota.
- **Job đã chạy rồi bị dừng** vẫn giữ `started_at`. Nếu sau đó lô bị hủy thì các câu còn lại của job đó không được hoàn. Tối đa là số luồng song song × số câu mỗi job. Chấp nhận, vì token đã tiêu cho job đó.
- **Dừng qua đêm rồi tiếp tục:** quota tính theo ngày tạo job, nên phần chạy hôm sau không bị trừ vào hôm sau. Lượng này bị giới hạn bởi kích thước lô và hạn 24 giờ, nên chấp nhận và ghi chú lại, không đổi cách đếm.
- Câu bị ngắt khi dừng đã tiêu token. Token này vẫn được ghi vào thống kê dù câu chưa thành.

### Giao diện (vendor-web)

- **Nút ở tiêu đề trang chi tiết lô, cạnh "Hủy lô":**
  - lô `RUNNING`/`QUEUED`: hiện **"Tạm dừng"**
  - lô `PAUSED`: hiện **"Tiếp tục"**
  - lô `PAUSING`: nút khóa, ghi "Đang dừng…"
  - Không cần hộp xác nhận, vì thao tác này không làm mất gì.
- **Chip trạng thái:**
  - lô: "Đang dừng…", "Đã tạm dừng · tự hủy lúc {giờ}"
  - job quay về hàng chờ: hiện lại "Chờ lượt"
- **Mục nhấp nháy dưới "Ngân hàng câu hỏi":** lô đang dừng hiện chấm tĩnh màu xám kèm chữ "Tạm dừng", không nhấp nháy. Bấm vẫn mở lô.
- **Replay engine:**
  - Câu bị ngắt: nhận `stage` quay về `QUEUED` (hoặc `end` của job) sau một `PROMPT` dở. Khi tiếp tục, có `PROMPT` mới nên mở vòng mới; đây là quy tắc "mỗi vòng bắt đầu bằng PROMPT" đã có.
  - Phần viết dở của vòng bị ngắt phải được đánh dấu `superseded`, giống một lần ghi bị thay bằng fallback.
  - Cần fixture mới `pause-midway-resume.ndjson`.
  - Bất biến I1–I7 giữ nguyên.

### Phạm vi thay đổi dự kiến

| Repo | Thay đổi |
|---|---|
| pte-api | migration (CHECK của `status` + cột `paused_at`), `BatchStatus`/`JobStatus`, endpoint `PATCH status`, nhánh dừng trong `GenerationJobRunner` + `GenerationItemStateService.requeueOpen`, `topUp` bỏ qua lô dừng, job tự hủy, hằng số mã lỗi và audit, test |
| pte-web | api-client (request + type trạng thái mới), nút và chip ở `batchgeneration`, mục activity ở sidebar, replay engine + fixture, i18n |
| pte-doc | plan + phase |

## Rủi ro

1. **Cờ ngắt bị hiểu sai:**
   - Runner hiện coi mọi lần bị ngắt là `CANCELLED`, nên phải đọc lại trạng thái job dưới lease trước khi quyết định. Đọc sai thì câu bị hủy thay vì được trả về hàng chờ.
   - Phải có test cả hai thứ tự: dừng rồi hủy, và hủy rồi dừng.
2. **Media bị bỏ dở trên Cloudinary:** nếu bị ngắt giữa lúc tải audio hoặc ảnh, file có thể đã nằm trên Cloudinary nhưng câu không trỏ tới. Phải dọn file đó, hoặc chấp nhận và ghi rõ là đã chấp nhận. Lưu ý local và prod dùng chung một tài khoản Cloudinary.
3. **Chạy nhiều instance:**
   - Sự kiện ngắt chỉ tới được instance đang chạy job. Job ở instance khác vẫn dừng được, nhưng chỉ ở lần kiểm tra lease kế tiếp (trước câu sau), không ngắt ngay.
   - Hiện stack chỉ có một instance `app`, nên chấp nhận và ghi chú lại.
4. **Bấm liên tục dừng/tiếp:** cập nhật có điều kiện kèm khóa hàng lô làm việc này an toàn. Phía giao diện thì khóa nút trong lúc gửi.
5. **Phí token:** mỗi lần dừng mất token của các câu đang viết dở, tối đa bằng số luồng song song, hiện là 3. Hiển thị một dòng nhỏ cạnh nút: "Câu đang viết sẽ được viết lại".

## Tiêu chí hoàn thành

- **Tạm dừng:** lô đang chạy dừng trong khoảng 2 giây; không còn job nào giữ lease; câu đã lưu giữ nguyên.
- **Tiếp tục:** chạy đúng thứ tự cũ, câu bị ngắt viết lại từ đầu, tổng số câu cuối cùng đúng như yêu cầu ban đầu.
- **Tự hủy:** lô dừng quá 24 giờ chuyển `CANCELLED` và có audit.
- **Một lô mở:** trong lúc tạm dừng không gửi được lô mới, nhận `GENERATION_JOB_ALREADY_RUNNING`.
- **Giao diện:** replay của câu bị ngắt không nhảy lùi bước (I1) và không hiện kết quả trước bước kết quả (I3).

## Phạm vi đã chốt

- **Chỉ lô có tạm dừng.** Job lẻ (sinh từ form câu hỏi) chỉ có 1 câu và kết quả về lại form, nên dừng không có ích: người dùng hủy rồi bấm sinh lại là đủ. Dừng job lẻ còn kéo theo trạng thái và giao diện riêng cho trang chạy job, không đáng.
- **Quota:** không đổi cách đếm (xem mục Quota).

**Bước tiếp theo:** `/ck:plan pte-doc/projects/plans/quang-ai-generation-batch-pause/brainstorm.md`
