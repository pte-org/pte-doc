# Rà soát nghiệp vụ vòng đời kỳ thi

Ngày rà soát: 2026-10-13  
Phạm vi: `pte-api` và `pte-web`, luồng tạo, sinh đề, phát hành, mở/đóng, hủy và xóa kỳ thi.

## Quyết định phạm vi

Không triển khai chức năng **Lưu trữ/Archive**. Kỳ thi đã hủy, đã đóng hoặc đã có dữ liệu tham gia phải được giữ lại để tra cứu, đối soát, chấm điểm và audit. Hiện code chưa có trạng thái hoặc action archive riêng.

## Quy tắc xóa đề xuất

| Trạng thái | Xóa | Ghi chú |
|---|---:|---|
| `DRAFT` | Có | Xóa mềm bản nháp chưa phát hành; giữ audit log. |
| `PREPARING` | Không | Đang sinh đề; cần hủy job trước. |
| `READY` | Không | Đã có snapshot/form; nên giữ lịch sử. |
| `SCHEDULED` | Không | Đã phát hành và đã materialize enrollment. |
| `OPEN` | Không | Đang diễn ra. |
| `CLOSED` | Không | Có thể liên quan đến chấm điểm, báo cáo, phát hành kết quả. |
| `CANCELLED` | Không | Trạng thái terminal, giữ để giải thích lịch sử và thông báo. |

## Các nghiệp vụ còn thiếu hoặc cần chốt

### P0 — Backend cho phép đóng sai trạng thái

`SessionStateService.close()` đang gọi `session.close()` mà không kiểm tra trạng thái hiện tại. Trong khi UI chỉ hiện nút đóng khi `OPEN`, gọi trực tiếp API vẫn có thể chuyển `DRAFT`, `PREPARING`, `READY` hoặc `SCHEDULED` thành `CLOSED`. Domain method cũng đang cho phép chuyển mọi trạng thái không phải `CANCELLED` sang `CLOSED`.

Đề xuất: backend chỉ cho phép `OPEN -> CLOSED`; mọi trạng thái khác trả lỗi nghiệp vụ. Bổ sung test cho toàn bộ trạng thái không hợp lệ.

### P1 — Hủy thủ công chưa phát thông báo cho exam staff

`SessionCancelledEvent` và listener hiện chỉ được phát trong `SessionRevocationService` khi subscription bị thu hồi. Luồng host bấm hủy trong `ExamOrchestrationService.cancel()` chỉ đổi trạng thái, hủy generation job và ghi audit; chưa phát event cho exam staff được gán vào kỳ thi.

Theo phạm vi đã chốt, exam staff là các tài khoản tenant-scoped có role `PROCTOR` hoặc `EXAMINER` đang được gán vào kỳ thi. Không gửi notification cho `STUDENT`, không broadcast cho toàn bộ staff trong tổ chức và không phụ thuộc vào giao diện `pte-practice`.

Đề xuất: khi hủy, snapshot danh sách proctor assignment và examiner assignment hiện hành rồi phát notification cho các recipient active, tenant-scoped. Event không nên tiếp tục đặt tên trường là `studentPublicIds`.

### P1 — Hủy bản nháp và xóa bản nháp đang chồng nghĩa

Hiện `DRAFT` vừa có thể `cancel`, vừa có thể `delete`. Sau khi hủy, bản nháp thành `CANCELLED` và không còn đường xóa; điều này dễ tạo dữ liệu rác trong danh sách.

Đề xuất nghiệp vụ đơn giản:

- `DRAFT`: dùng **Xóa bản nháp**, không hiển thị **Hủy kỳ thi**.
- `PREPARING`: cho phép **Hủy sinh đề**; cần chốt hủy xong về `DRAFT` để sửa/sinh lại hay thành `CANCELLED` terminal.
- `READY` và `SCHEDULED`: cho phép **Hủy kỳ thi**; `SCHEDULED` phải phát thông báo.

### P1 — Chưa có tự động chuyển trạng thái theo thời gian

Có worker nhắc sắp đóng, nhưng chưa thấy worker chuyển `SCHEDULED -> OPEN` tại `opensAt` hoặc `OPEN -> CLOSED` tại `closesAt`. Hệ thống vẫn chặn học viên vào ngoài khung giờ, nhưng trạng thái có thể bị treo `OPEN`; khi đó các nghiệp vụ yêu cầu `CLOSED` như chấm điểm/phát hành báo cáo có thể bị chặn nếu host quên đóng.

Cần chốt một trong hai hướng:

- Host mở/đóng thủ công: đổi copy và hướng dẫn để thể hiện rõ đây là thao tác bắt buộc.
- Theo lịch: bổ sung worker idempotent, lock theo session và audit event cho auto-open/auto-close.

### P1 — Quy tắc xóa mềm và dữ liệu con chưa được đặc tả đầy đủ

Xóa bản nháp hiện chỉ đánh dấu `ExamSession.deleted = true`. Các dữ liệu con như audience source/member, generation job, form assignment hoặc selected skills vẫn còn. Đây có thể là lựa chọn đúng để giữ audit, nhưng cần quy định rõ dữ liệu nào được giữ và bảo đảm mọi query nghiệp vụ đều loại session đã xóa.

Đặc biệt cần rà soát các repository dùng `findByPublicId(UUID)` không kèm `deleted = false`; các luồng host/student phải luôn dùng truy vấn đã lọc xóa mềm.

### P2 — Cần tăng test cho state machine và cạnh tranh thao tác

Nên bổ sung test backend cho:

- `close()` với từng trạng thái ngoài `OPEN`.
- Hủy thủ công `SCHEDULED` có event và notification recipient đúng.
- Hủy generation job ở `PREPARING` không để job chạy tiếp và xác định trạng thái sau hủy.
- Session đã xóa mềm không xuất hiện ở list/detail/enrollment/attempt lookup.
- Hai request mở/đóng hoặc hủy đồng thời không tạo transition sai.

## Kết luận

Quy tắc **chỉ xóa `DRAFT`**, không xóa `CANCELLED`, `OPEN`, `CLOSED` và không thêm Archive là phù hợp với dữ liệu exam hiện tại. Ưu tiên xử lý theo thứ tự: chặn backend close sai trạng thái, bổ sung notification khi host hủy kỳ thi, sau đó chốt semantics của hủy bản nháp và auto/manual scheduling.
