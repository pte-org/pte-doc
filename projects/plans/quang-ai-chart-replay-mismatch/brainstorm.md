# Brainstorm: biểu đồ web vẽ lại khác ảnh thật (2026-11-26)

## Vấn đề
Khi ảnh Describe Image về, vendor-web phát lại 3 giây cảnh "vẽ biểu đồ"
(`features/questiongeneration/components/_MakingMedia.tsx`). Cảnh này tự vẽ bằng HTML:
- chỉ lấy **series đầu tiên** của Writer;
- luôn vẽ **cột màu vàng**, bất kể `chartType` (BAR/LINE/PIE/TABLE);
- không có trục, nhãn, chú thích.

Ảnh thật do server vẽ bằng **XChart** ra PNG
(`pte-api/.../generation/media/ChartRenderer.java`): nhiều series, đúng loại biểu đồ, có màu, trục và chú thích.
Hai hình vì vậy không khớp. Người xem thấy một biểu đồ được vẽ, rồi một biểu đồ khác bay vào màn thi.

## Phương án
| | Cách làm | Khớp ảnh thật | Công sức | Rủi ro |
|---|---|---|---|---|
| A | Web vẽ lại đầy đủ: grouped bar, line, pie, table, cùng bảng màu XChart | Gần đúng | Vừa đến lớn | Lệch dần mỗi khi renderer đổi; trùng logic hai nơi |
| **B** | **Dùng chính ảnh PNG thật, "vẽ" bằng hiệu ứng lộ dần**: mặt nạ quét trái → phải, con trỏ bám mép quét, kèm thống kê thật (loại biểu đồ, số cột/series, kích thước) | **100%** | Nhỏ | Hiệu ứng là quét, không phải từng cột mọc |
| C | Server xuất SVG (XChart hỗ trợ), web animate từng phần tử của SVG thật | 100% và mọc từng cột | Lớn: thêm định dạng lưu trữ, sanitize SVG, map phần tử | Phức tạp, dễ vỡ khi đổi theme |

## Khuyến nghị: B
- Không bao giờ lệch, vì đó chính là ảnh sẽ lên màn thi. Một code path dùng chung cho cả CHART và PICTURE.
- Giữ đúng tinh thần "chỉ hiện dữ liệu thật". Thời lượng 3 giây và cơ chế giữ ảnh lại (`useReplay`, `CHART_REPLAY_MS`) vẫn dùng như hiện tại.
- Bỏ phần vẽ cột HTML và `chartData`. Thay bằng: tải ảnh qua `usePromptMedia(imageRef)`, đặt trong khung có lớp phủ `clip-path` tăng dần theo `fill` hiện có, gắn `data-cursor-target` ở mép quét. Phần thống kê dùng `chartType` và dữ liệu Writer (số category, số series).
- **Trước khi ảnh về:** với ảnh PICTURE do AI vẽ, thời gian thật kéo dài, nên giữ khung nét đứt và đồng hồ đếm như hiện tại. Không vẽ hình giả.

## Câu hỏi còn mở
- Hướng quét: trái → phải, hay từ dưới lên (giống cột mọc)? Mặc định đề xuất trái → phải.
- Có cần làm C sau này không? Chỉ khi thật sự cần hiệu ứng từng cột.

## Bước tiếp theo
Nếu chọn B: sửa trực tiếp, không cần plan nhiều phase. Gồm `_MakingMedia.tsx` (nhánh image), xoá `utils/chartData.ts` cùng test của nó, và sửa `_LiveAssembly.tsx` (điều kiện `useReplay` không còn dựa vào `chartData`).
