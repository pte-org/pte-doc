# Kế hoạch cải thiện giao diện chat box

**Ngày:** 2026-10-29 · **Phạm vi:** `pte-practice/features/chat` · **Trạng thái:** **Đã làm U1 đến U10** (được duyệt 2026-10-29, làm theo TDD, chưa commit). Chưa kiểm bằng trình duyệt thật sau khi làm; xem phần "Kết quả" ở cuối.

Nguồn: mình đã kiểm giao diện thật trên trình duyệt (desktop 1280x800 và mobile 375x812) bằng một trang xem thử tạm với API giả lập (trang này đã xoá). Đã thấy hoạt động đúng: panel đẩy nội dung bài tập sang bên, bảng và code cuộn ngang, chuỗi dài tự ngắt dòng, liên kết nguy hiểm thành chữ thường, ảnh bị chặn, nhãn "Ngoài phạm vi", đếm lượt, khoá khi hết lượt kèm giờ reset, cảnh báo ≤ 3 lượt, nút "Thử lại" khi tải phiên lỗi, overlay toàn màn hình trên mobile, focus vào ô nhập khi mở.

## Đã sửa ngay trong lúc kiểm (nằm trong Phase 4)

| Vấn đề thấy được | Cách xử lý |
| --- | --- |
| Nút mở chat che nút "Next/Skip" của footer bài làm | Đổi thành tab dọc ở mép phải, chừa dải 44px khi panel đóng; ≤ 960px là nút nổi đặt trên footer |
| Tải phiên lỗi vẫn tạo `session_id` mới (mất cuộc trò chuyện cũ) | Giữ khoá ô nhập, hiện nút "Thử lại" |
| Panel hiện ngay cả khi backend chưa bật chat | Thêm cờ `NEXT_PUBLIC_CHAT_ENABLED` (mặc định tắt) |

## Đề xuất cải thiện (xếp theo giá trị/công sức)

| # | Cải thiện | Vì sao | Công sức |
| --- | --- | --- | --- |
| U1 | Khi nhận câu trả lời dài, cuộn tới **đầu** bong bóng trả lời mới thay vì cuối danh sách | Hiện cuộn xuống cuối nên học viên thấy phần kết trước, phải kéo ngược để đọc từ đầu | S (nửa giờ) |
| U2 | Gợi ý nhanh trong khung trống (3 đến 4 chip: "Cấu trúc bài Write Essay", "Sửa câu của tôi", "Khác nhau giữa A và B") bấm vào điền sẵn ô nhập | Khung trống chỉ có một dòng chữ; chip giúp người mới biết hỏi gì và tiết kiệm lượt vì câu hỏi phổ biến trúng cache | S |
| U3 | Nút "Sao chép" trên mỗi câu trả lời | Học viên hay chép mẫu câu/template | S |
| U4 | Ghi nhớ trạng thái mở/đóng panel trong phiên làm việc (sessionStorage) | Hiện mỗi lần sang câu mới panel đóng lại nếu trang remount | S |
| U5 | Dialog semantics + khoá cuộn + bẫy focus cho overlay màn hẹp (đã ghi là nợ chấp nhận ở quality gate Phase 4) | Người dùng bàn phím/đọc màn hình có thể tab ra sau lớp phủ | M |
| U6 | Phím tắt mở/đóng (ví dụ `Ctrl+/`) và nhãn hiển thị | Dùng bàn phím nhanh khi đang làm bài | S |
| U7 | Hiện số lượt còn lại ngay trên nút mở chat (huy hiệu nhỏ) | Học viên biết còn bao nhiêu mà không cần mở panel | S |
| U8 | Hiệu ứng xuất hiện cho tin mới (mờ dần, tôn trọng `prefers-reduced-motion`) | Cảm giác mượt hơn | S |
| U9 | Đổi tên action `sendFailed` khi dùng cho lỗi tải thành `requestFailed`; đặt tên cho offset `bottom: 96px` của nút nổi mobile | Dọn gợi ý của quality gate (QUAL-009 Phase 4) | S |
| U10 | Làm mới quota khi countdown về 0 nhưng server trả `resetAt` cũ (lệch đồng hồ): hiện trạng thái "đang làm mới" | Tránh dòng "còn 0 giờ 0 phút" kẹt khi đồng hồ máy học viên nhanh | S |

## Việc cần thiết kế/xác nhận thêm

- Vị trí cuối cùng của tab ở màn rộng và bề rộng 380px của panel: hẹn 15 phút với UI/UX Designer (đã có trong checklist release).
- Giao diện tiếng Anh của disclaimer chờ PM/pháp lý duyệt.

## Cách làm

Làm theo TDD như các phase trước: viết test cho hàm thuần mới trước (thấy đỏ), rồi mới viết code.

## Kết quả (2026-10-29)

| # | Làm gì | Ở đâu |
| --- | --- | --- |
| U1 | Câu trả lời mới cuộn tới **đầu** bong bóng; câu hỏi đang chờ và lịch sử vừa tải cuộn xuống cuối | `chat-scroll.ts`, `ChatMessageList.tsx` |
| U2 | 3 chip gợi ý ở khung trống, bấm chỉ điền ô nhập, không gửi; ẩn khi hết lượt | `chat-suggestions.ts`, `ChatSuggestions.tsx` |
| U3 | Nút "Sao chép" trên mỗi câu trả lời (không có ở câu từ chối) | `chat-copy.ts`, `ChatCopyButton.tsx` |
| U4 | Nhớ panel đang mở trong tab (sessionStorage, đọc bằng `useSyncExternalStore` để không lệch hydration) | `chat-open-state.ts`, `ChatLayout.tsx` |
| U5 | Màn hẹp: `role="dialog"`, `aria-modal`, khoá cuộn trang, bẫy focus bằng Tab | `chat-focus-trap.ts`, `useNarrowScreen.ts`, `ChatPanel.tsx` |
| U6 | `Ctrl+/` (hoặc `Cmd+/`) mở/đóng, nhãn trong `title` và `aria-keyshortcuts` của nút | `chat-shortcut.ts`, `ChatLayout.tsx` |
| U7 | Huy hiệu số lượt còn lại trên nút mở chat (đổi màu khi ≤ 3); số lượt được lấy ngay khi trang mở | `chat-quota.ts`, `ChatToggleButton.tsx`, `ChatLayout.tsx` |
| U8 | Bong bóng mới mờ dần vào, tắt khi `prefers-reduced-motion` | `chat.css` |
| U9 | Đổi `sendFailed` thành `requestFailed`; offset 96px của nút nổi thành biến `--chat-toggle-bottom` | `chat-state.ts`, `chat.css` |
| U10 | Hết giờ reset mà server vẫn trả `resetAt` cũ: hiện "đang kiểm tra lượt hỏi mới" và hỏi lại server mỗi 30 giây | `chat-quota.ts`, `ChatQuotaNotice.tsx` |

Thay đổi cấu trúc đi kèm: `ChatLayout` tách thành vỏ kiểm cờ và `EnabledChatLayout`, nên khi `NEXT_PUBLIC_CHAT_ENABLED` tắt thì **không có hook hay request nào chạy**. Quota và `api` được nâng từ panel lên layout để nút ngoài panel biết số lượt.

Kiểm tra: `vitest` 71 file / 611 test xanh, `tsc` sạch, `eslint` không lỗi mới. **Chưa kiểm bằng trình duyệt thật**: các phần chỉ thấy được khi chạy (huy hiệu, chip, nút sao chép, hiệu ứng, bẫy focus, phím tắt) cần một lượt xem tay trước khi release.
