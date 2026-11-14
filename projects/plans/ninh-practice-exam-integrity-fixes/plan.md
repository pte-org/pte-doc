# Plan: Sửa lỗi nghiệp vụ thi PTE và lỗi giao diện từ đợt rà soát UI

Status: Implemented (chưa chạy test thủ công trên trình duyệt)
Date: 2026-11-14
Owner/slug: Ninh — `ninh-practice-exam-integrity-fixes`
Scope: `pte-practice`, `pte-web` (`vendor-web`, `tenant-web`), `pte-doc`. Không đổi `pte-api`.
Related: [hung-practice-timed-modes](../hung-practice-timed-modes/plan.md)

## Bối cảnh

Báo cáo rà soát UI nêu 4 lỗi nghiệp vụ và 5 lỗi giao diện. Mỗi điểm đã được đối chiếu với code
trước khi sửa. Kết quả đối chiếu và cách xử lý nằm ở bảng dưới.

## Kết quả đối chiếu và quyết định

| # | Vấn đề | Kết luận | Cách xử lý |
|---|---|---|---|
| 1.1 | Lộ transcript bài Nghe/Nói | Đúng | `questionPresentation.ts` ẩn transcript và yêu cầu audio cho RS, WFD, SST, SMW, HCS, ASQ trước khi nộp |
| 1.2 | Re-order hiện sẵn đáp án | Đúng | Xáo trộn có seed (`publicId` của câu) trong `task-content.ts`, đảm bảo không trùng thứ tự đúng |
| 1.3 | Hết giờ không tự nộp | Đúng ở frontend | Auto-submit khi `timeUp`. **Không** thêm deadline ở server: plan `hung-practice-timed-modes` chủ động đặt `deadlineAt = null` ("Không làm: ép thời gian ở server") |
| 1.4 | Lệch state khi nộp lại câu Skip | Đúng một phần | Không sửa. Câu hiện tại không mất; Next đi tuần tự qua lịch sử rồi về câu hiện tại. Cần xác nhận hành vi mong muốn nếu muốn đổi |
| 2.1 | Firefox/Safari luôn hiện Start gate | Đúng | `useTimedPhase.ts` ghi nhận cử chỉ người dùng đầu tiên ở cấp window khi API `userActivation` không có |
| 2.2 | "Đúng một phần" hiện icon X | Đúng | Đổi sang icon cảnh báo. Giữ thang `/100`: thang 10–90 là quyết định sản phẩm, chưa đổi |
| 2.3 | Fill in the Blanks kéo-thả | Đúng | Key không trùng, từ đã dùng bị làm mờ, không dùng một từ quá số lần có, kéo blank về ngân hàng để trả từ, xáo trộn ngân hàng từ |
| 2.4 | Hardcode tiếng Anh ở Question Review | Đúng | Chọn bộ message theo `useLocale()` |
| 2.5 | Giám khảo nhập điểm sai | Đúng một phần | Hook trả `false` im lặng nhưng controller đã hiện toast "kiểm tra kết nối" — sai nguyên nhân. Thêm thông báo riêng cho điểm không hợp lệ |

## Rủi ro đã biết

- Backend vẫn trả `orderIndex` của Re-order và Fill in the Blanks đúng thứ tự đáp án trong payload.
  Xáo trộn ở frontend chỉ chặn việc đọc từ giao diện, không chặn việc đọc từ tab Network. Chặn hẳn cần
  backend xáo trộn và đổi định danh đáp án; để lại cho đợt sau.
- Bài nghe thiếu audio sẽ bị khóa (giống ASQ hiện tại) thay vì rơi về hiển thị transcript.

## Phases

- [x] Phase 1: `pte-practice` — ẩn transcript bài nghe, xáo trộn Re-order / ngân hàng từ
- [x] Phase 2: `pte-practice` — auto-submit khi hết giờ, sửa gate Firefox
- [x] Phase 3: `pte-practice` — icon kết quả, BlankRenderer
- [x] Phase 4: `pte-web` — i18n Question Review, thông báo điểm không hợp lệ của giám khảo
- [x] Phase 5: kiểm chứng (`npm run test:unit`, `tsc --noEmit`) và cập nhật test

## Kiểm thử thủ công còn lại

1. RS / WFD: không thấy câu chữ trước khi nộp, thấy sau khi nộp.
2. Re-order: mở lại cùng câu vẫn ra cùng thứ tự; thứ tự ban đầu không phải đáp án.
3. Timed Reading/Writing: hết giờ tự nộp (có bài) hoặc tự bỏ qua (chưa có bài).
4. Firefox: chỉ phải bấm "Start question" một lần sau khi tải lại trang.
5. Blanks kéo-thả: từ đã dùng bị mờ, kéo blank về ngân hàng trả lại từ.
6. Vendor-web ở tiếng Việt: trang review câu hỏi hiện tiếng Việt.
7. Examiner nhập điểm 101 / -1 / 3.5: có toast báo điểm không hợp lệ.
