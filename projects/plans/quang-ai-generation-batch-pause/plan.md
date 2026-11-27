# Plan: tạm dừng và tiếp tục lô sinh đề AI

**Tác giả:** quang · **Ngày:** 2026-11-27 · **Trạng thái:** Phase 01–06 đã làm; phase 07 còn phần kiểm tra tay trên local
**Nguồn:** [brainstorm.md](brainstorm.md)

## Mục tiêu

Lô sinh đề có thêm **Tạm dừng** (ngắt ngay lời gọi AI đang chạy, câu dở quay về hàng chờ) và **Tiếp tục** (chạy lại đúng thứ tự cũ). Lô dừng quá hạn (mặc định 24 giờ, admin cấu hình được) thì tự hủy. Lô đang dừng vẫn tính là lô đang mở.

## Quyết định đã chốt

| # | Quyết định | Nguồn |
|---|---|---|
| D1 | Dừng **ngay**: dùng chung đường ngắt `task.cancel(true)` với Hủy lô. Câu bị ngắt viết lại từ vòng 1. | Người dùng |
| D2 | Lô `PAUSED` quá hạn thì tự hủy theo đường hủy, người thực hiện là hệ thống. Hạn mặc định 24 giờ, **platform admin sửa được** trong panel "Giới hạn" (platform setting `question_generation_paused_batch_expiry_hours`, 0..168, 0 = không tự hủy). | Người dùng |
| D3 | `PAUSING`/`PAUSED` thuộc `BatchStatus.OPEN`: vẫn chặn tạo lô mới, unique index một-lô-mở giữ nguyên ý nghĩa. | Người dùng |
| D4 | Không đổi cách đếm quota. Hủy tự hoàn quota cho job chưa chạy (`NOT_REFUNDED`). | Đề xuất, đã duyệt |
| D5 | Chỉ lô, không làm cho job lẻ. | Đề xuất, đã duyệt |
| D6 | Endpoint theo kiểu của `cancel`: `POST /batches/{id}/pause` và `POST /batches/{id}/resume`. Lô đã dùng `POST .../cancel`; để ba hành động cùng một kiểu thì dễ đọc hơn là trộn với `PATCH status`. | Plan |
| D7 | Khi bị ngắt, runner **đọc lại trạng thái job trong DB** để biết lý do (dừng hay hủy). Cờ interrupt không mang lý do. Hủy luôn thắng dừng. | Plan |

## Các phase

| Phase | Nội dung | Repo | Phụ thuộc |
|---|---|---|---|
| [01](phase-01-schema-and-states.md) | Migration V60, enum trạng thái, `paused_at` | pte-api | — |
| [02](phase-02-pause-resume-service.md) | Service + endpoint pause/resume, chaining, hủy khi đang dừng, audit | pte-api | 01 |
| [03](phase-03-worker-interrupt-reason.md) | Worker phân biệt dừng/hủy, trả câu về hàng chờ, nhả lease | pte-api | 01, 02 |
| [04](phase-04-paused-expiry.md) | Tự hủy lô dừng quá hạn, hạn là platform setting admin sửa được | pte-api | 02 |
| [05](phase-05-web-controls.md) | api-client + nút, chip, sidebar activity, thông báo lỗi, dòng hạn tự hủy trong panel "Giới hạn" | pte-web | 02, 04 |
| [06](phase-06-replay-interrupted-round.md) | Replay engine: vòng bị ngắt, fixture, bất biến | pte-web | 03, 05 |
| [07](phase-07-verification-and-docs.md) | Chạy suite, kiểm tra tay trên local, báo cáo, cập nhật AGENTS.md | tất cả | 01–06 |

## Tiêu chuẩn bắt buộc

- pte-api: `docs/CODING_STANDARDS_API.md`, `docs/API_RESPONSE_SETUP.md`, `docs/COMMON_EXCEPTION_SETUP.md`. Hằng số và mã lỗi đặt trong `*Constants`; dùng `Clock` được inject; file không quá 300 dòng; package `internal/**` không quá 15 lớp (có ratchet test).
- pte-web: `docs/CODING_STANDARDS_WEB.md`. Câu chữ đặt trong file messages; component không quá 150 dòng; dùng `Button` của `@pte/ui`.

## Rủi ro chính

1. Đọc nhầm lý do bị ngắt khiến câu bị hủy thay vì quay về hàng chờ. Xử lý ở phase 03 (D7), có test cho cả hai thứ tự dừng/hủy.
2. Media dở trên Cloudinary khi bị ngắt giữa lúc tải lên. Phase 03 chốt cách xử lý: xóa nếu có ref trong vòng bị ngắt, còn lại chấp nhận. Local và prod dùng chung tài khoản Cloudinary.
3. Nhiều instance: sự kiện ngắt chỉ tới instance đang chạy job. Job ở instance khác dừng ở lần kiểm tra lease kế tiếp. Hiện chỉ có một instance; ghi chú lại.
4. Replay: phần viết dở của vòng bị ngắt không được bị coi là kết quả của câu (I3).

## Ngoài phạm vi

- Tạm dừng job lẻ.
- Đổi cách đếm quota.
- Tạm dừng theo lịch hoặc tự động tạm dừng khi provider lỗi.

## Ghi chú khi làm (2026-11-27)

- **Câu bị ngắt không được đánh `FAILED`.** Khi lời gọi AI bị ngắt, pipeline bắt exception và gọi `itemState.fail`. Giờ `fail` bỏ qua khi luồng đang bị ngắt, để runner quyết định: tạm dừng thì câu về `QUEUED`, hủy thì `CANCELLED`. Hệ quả phụ: câu bị hủy giữa chừng giờ là `CANCELLED` thay vì `FAILED`, đúng nghĩa hơn.
- **Media dở:** pipeline đã có `finally { mediaRenderer.discard(stored) }`, nên media của câu bị ngắt được xóa sẵn. Không cần code mới cho rủi ro 2.
- **Luồng live khi chạy lại:** `LiveJobRegistry.start` thay `LiveJob` đã kết thúc bằng một cái mới khi worker nhận lại job. Nếu không, người xem nhận snapshot cũ và `end` ngay.
- **Replay:** `startNewRun` (khi snapshot `finished: false` đến sau `end`) đánh dấu phần viết dở là `superseded` và ghi `runBase`, để snapshot của lần chạy mới được đọc chồng lên các vòng trước. `useLiveJob` kết nối lại khi job chuyển giữa chờ và chạy.
- **Endpoint:** đặt trong controller riêng `QuestionGenerationBatchPauseController`, để không đổi constructor của controller lô.
- **Setting phải được seed:** đọc một platform setting chưa có dòng sẽ đánh dấu transaction ngoài là rollback (lỗi sẵn có của `BillingSettingsService.questionGenerationLimit`). V60 tạo sẵn dòng `question_generation_paused_batch_expiry_hours = 24`.
- **V60** dùng `DROP ... IF EXISTS` để chạy được cả trên DB local dựng bằng Hibernate (`local-schema`).
- **Dừng không dựa vào cờ interrupt (sửa sau lần thử thật, 2026-11-27).** Lần thử đầu cho thấy lời gọi AI có bị ngắt, nhưng lớp retry và fallback coi đó là provider lỗi và gọi lại model dự phòng. Một luồng còn mất cờ interrupt ở giữa, nên câu vẫn viết xong, được lưu, và job thành `COMPLETED` khoảng 16 giây sau khi bấm dừng. Cách sửa:
  - Mỗi job đang chạy có một `GenerationStop` (package `stop`). Worker bật tín hiệu trước, rồi mới `task.cancel(true)`.
  - Gateway kiểm tra tín hiệu trước mỗi lần thử lại, khi lời gọi lỗi và trước khi chuyển sang fallback. Lỗi do bị dừng là `GenerationStoppedException`, không phải `LlmProviderException`, nên không lớp nào gọi lại.
  - Tín hiệu đóng luôn response đang đọc. Stream reader kiểm tra tín hiệu ở từng dòng, nên không còn chữ nào tới live view.
  - Pipeline trả `STOPPED`. `GeneratedQuestionWriter.save` không lưu khi job `PAUSING`.
  - Web: khi stream kết thúc giữa lúc câu đang viết, phần chữ dở hiện hết ngay (`ItemScript.halted`) thay vì gõ tiếp theo tốc độ đọc.
  - Web, lần thử thứ hai: câu bị dừng trước khi agent viết chữ nào thì không có gì bị cắt, nên replay vẫn hiện con trỏ và chữ "Đang viết đề". Giờ khi job về chờ lượt (`PENDING`/`QUEUED`), mọi câu đang dở đều bị đánh `halted`. Khi đó `Frame.halted` ẩn con trỏ agent, chip trong panel hiện "Chờ lượt", và dòng "Đang kết nối…" không còn hiện.
