# Kiểm tra: tạm dừng và tiếp tục lô sinh đề AI

**Ngày:** 2026-11-27 · **Plan:** [quang-ai-generation-batch-pause](../../projects/plans/quang-ai-generation-batch-pause/plan.md)

## Kết luận

Phase 01–06 đã xong và qua test tự động. Phase 07 còn **kiểm tra tay trên local với một lô thật** (mục "Chưa kiểm tra" bên dưới). Lý do: lúc kiểm tra, tài khoản admin local đang có một lô khác chạy, và mỗi người chỉ được mở một lô.

## Đã chạy

| Phạm vi | Lệnh | Kết quả |
|---|---|---|
| pte-api, sinh đề + kiến trúc | `mvnw -pl app -Dtest='com.pte.itembank.internal.generation.**.*Test,ApiInventoryExportTest,SourceFileSizeTest,PackageDensityTest,NoDirectClockAccessTest' test` | 634 test; 1 lỗi có sẵn không liên quan (xem dưới) |
| pte-api, compile | `mvnw -pl app -DskipTests compile` | Qua |
| vendor-web | `tsc --noEmit`, `eslint features tests/...`, `vitest run` | Sạch, 0 lỗi eslint, 997/997 test |
| api-client | `tsc --noEmit`, `vitest run` | Sạch, 933/933 test |
| Local stack | Áp V60 bằng tay (`local-schema` không chạy Flyway), build lại `app` | `app` healthy; `POST .../pause` và `.../resume` khi chưa đăng nhập trả 401; danh sách lô trả 200 |

**Lỗi có sẵn, không do thay đổi này:**
- `SourceFileSizeTest`: `BrandedEmailTemplate.java` (306 dòng), `ExamPublishService.java` (322 dòng).
- `ModuleStructureTest`: `proctoring` phụ thuộc `session.domain.enums.AttendanceStatus`.

## Test mới

- **Backend:**
  - `BatchPauseServiceTest`
  - `BatchPausedExpiryTest`
  - `GenerationItemStateServiceTest`
  - `LiveJobRegistryTest`
  - Thêm ca vào `GenerationJobRunnerTest`: ngắt vì dừng, hủy thắng dừng, dừng giữa các câu.
  - Thêm ca vào `JobLeaseServiceTest`: nhả job, job đang dừng mà worker chết.
  - Thêm ca vào `BatchChainingServiceTest`: không đẩy job khi đang dừng, tiếp tục.
- **Web:**
  - `batchActions.test.tsx`
  - Thêm ca vào `generationActivity.test.ts` cho lô dừng.
  - Thêm ca vào `buildScript.test.ts` cho lần chạy mới sau khi dừng.
  - Fixture `pause-midway-resume` chạy cùng bộ bất biến I1–I7.

## Lỗi tìm ra trong lúc kiểm tra và đã sửa

1. **Câu bị ngắt bị đánh `FAILED`:** pipeline bắt exception của lời gọi AI bị ngắt rồi ghi `FAILED` trước khi runner biết là bị ngắt. Giờ `GenerationItemStateService.fail` bỏ qua khi luồng đang bị ngắt.
2. **Luồng live báo "đã xong" khi job chạy lại:** registry dùng lại `LiveJob` đã kết thúc. Giờ `LiveJobRegistry.start` tạo mới khi worker nhận lại job.
3. **Danh sách lô lỗi 500 sau khi thêm setting:** đọc một platform setting chưa có dòng sẽ đánh dấu transaction ngoài là rollback. V60 tạo sẵn dòng setting, giống cách V53 làm với giới hạn kích thước lô. Gốc lỗi nằm ở `BillingSettingsService.questionGenerationLimit`, chưa sửa.

4. **Dừng chưa dừng ngay (lần thử thật đầu tiên).** Bấm dừng lúc 04:29:59, nhưng câu đang viết vẫn chạy tiếp và được lưu lúc 04:30:15. Lô chỉ thành `PAUSED` sau đó. Log cho thấy lời gọi AI có bị ngắt, nhưng retry và fallback gọi lại model dự phòng, và luồng đó mất cờ interrupt. Đã sửa bằng tín hiệu dừng riêng cho từng job (xem ghi chú trong plan). Test mới:
   - `GenerationStopTest`
   - Thêm ca vào `NineRouterLlmGatewayStreamTest`: dừng giữa stream; lời gọi lỗi sau khi dừng thì không gọi lại.
   - Thêm ca vào `FallbackLlmGatewayTest`: job đã dừng thì không gọi fallback.
   - Thêm ca vào `GeneratedQuestionWriterTest`: job `PAUSING` thì không lưu.
   - Thêm 2 ca vào `GenerationJobRunnerTest`.
   - Web: `buildScript`, `advance`.

## Chưa kiểm tra

Các kịch bản 1–5 của [phase 07](../../projects/plans/quang-ai-generation-batch-pause/phase-07-verification-and-docs.md):
- dừng khi 3 luồng đang viết
- chặn tạo lô mới
- tiếp tục cho đủ câu
- dừng rồi hủy, kiểm tra quota
- tự hủy theo hạn admin đặt

Chạy được khi tài khoản admin local không còn lô đang mở.
