# Phase 5: Sửa giao diện nhỏ — trang xem lại và thanh trên

Preflight: Unit tests created and run: no (skipped_by_user) · ck:quality gate: skipped_by_user
Status: Completed · Bug: sáu lỗi giao diện Hung gặp khi test, mỗi lỗi một commit

## Requirements

1. **Trang xem lại sáng sai mục thanh bên và không có Pip.** Trang xem lại bài làm phải sáng đúng mục của trang đã mở nó ("Luyện đề" hoặc "Luyện kỹ năng") và có trợ lý AI Pip.
2. **Thanh "Trang chủ" bị chữ đè lên.** Khi cuộn, nội dung lọt qua khoảng hở 16px phía trên thanh nổi.
3. **Dải sáng trên thanh khi có nền ảnh.** Bản vá của lỗi 2 tạo ra một dải tô màu chắn ngang ảnh nền ngay cả lúc chưa cuộn.
4. **Ô "Dạng bài" trong trang xem lại hiện mã bị cắt** (`MC LISTENING MULT…`).
5. **Ô chú giải "Chưa làm" mờ tới mức không thấy.**
6. **Chữ lỗi mờ ở giao diện sáng.** `.form-error`, `.access-banner-error` và `.task-count-warning` dùng màu hồng nhạt cứng viết cho giao diện tối, trên nền đỏ nhạt của giao diện sáng thì gần như biến mất.

## Design Constraints

- Mục thanh bên của trang xem lại do trang gốc quyết định, không do đường dẫn: `ActiveNav` là context, `sessionOrigin` cho biết MOCK_TEST thuộc Luyện đề và còn lại thuộc Luyện kỹ năng, `FinishSessionButton` truyền `reviewFrom`.
- Thanh trên: nền mặc định giữ lớp che khoảng hở (`::before`, cao đúng `--studio-top-gap`, 16px, còn 12px ở ≤1100px và ≤760px); khi có nền ảnh thì **bỏ lớp che** và thanh dính sát mép trên (`top: 0`), vì không có màu phẳng nào che khớp được lên ảnh.
- Tên dạng bài dùng hàm có sẵn `taskDisplayName` (cùng nguồn với Trang chủ và Tiến độ), không viết lại bảng tên.
- Chip "Chưa làm" khác hai chip còn lại bằng viền nét đứt màu `--muted`, không dùng `opacity`.

## Related files

`pte-practice`: `features/shell/{nav-active.ts,ActiveNav.tsx,StudentShell.tsx,shell-chrome.css}`, `features/practice/{review-return.ts,PracticeReviewView.tsx,PracticeSessionView.tsx}`, `features/practice/session/FinishSessionButton.tsx`, `features/practice/review/{ReviewQuestion.tsx,review.css}`.

## Steps

1. `defaultNavHref`, `ActiveNav` và `sessionOrigin`; trang xem lại và `FinishSessionButton` truyền nguồn; Pip hiện trên trang xem lại.
2. Thanh trên: biến `--studio-top-gap` và `::before`; sau đó với nền ảnh đặt `top: 0` và `::before { display: none }`.
3. `ReviewQuestion`: giá trị ô Dạng bài lấy từ `taskDisplayName`; `review.css` chia lại cột (`max-content`, `2.4fr`, `1fr`, `1fr`), cho chữ xuống dòng, dưới 900px còn hai cột.
4. `.review-chip-empty`: `border: 1.5px dashed var(--muted)`, bỏ `opacity`.
5. Một rule riêng cho giao diện sáng đặt màu chữ ba lớp lỗi về `var(--red)`, dùng `:where()` để không ghi đè trang có màu lỗi riêng như trang đăng nhập (`5b3a1e9`).

## Success Criteria

- Mở xem lại từ Luyện đề: mục Luyện đề sáng và Pip có mặt; từ Luyện kỹ năng: ngược lại.
- Cuộn Trang chủ với nền mặc định: không còn chữ lọt phía trên thanh. Với nền ảnh: không có dải sáng trước hay sau khi cuộn, thanh dính sát mép trên.
- Dạng bài dài hiện đủ tên đã dịch (ví dụ "Multiple Choice (Multiple) (Chọn nhiều đáp án)") và xuống dòng.
- Ô "Chưa làm" trong chú giải nhìn thấy rõ ở cả giao diện sáng và tối.
- Gửi form đổi mật khẩu với mật khẩu mới dưới 8 ký tự ở giao diện sáng: chữ lỗi đỏ đậm, đọc được; giao diện tối không đổi.

## Quality and Testing State

- Quality: skipped_by_user
- Testing: skipped_by_user. `tsc` và `eslint` sạch.
- Chưa chụp ảnh thật sau khi sửa lỗi 3, 4, 5 và 6. Hai góc bo trên của thanh khi dính mép có thể lộ một chút nội dung phía sau; nếu thấy chướng thì bỏ bo góc trên ở trạng thái đó.
