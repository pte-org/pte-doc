# Phase 7: Describe Image, từ số liệu vẽ bằng XChart (P3b)

## Mục tiêu
DESCRIBE_IMAGE với 4 loại: BAR, LINE, PIE, TABLE. Ảnh được **vẽ bằng code từ số liệu đã duyệt**, không dùng model sinh ảnh.

## Phụ thuộc
- `org.knowm.xchart:xchart` (Apache 2.0) trong `app/pom.xml`. Chạy với `-Djava.awt.headless=true`. Kiểm tra image Docker có font (Debian slim có thể
  cần `fontconfig` và `fonts-dejavu-core`), nếu thiếu thì sửa Dockerfile.

## Thay đổi
- `ChartDraft(topic, chartType, title, xLabel?, yLabel?, unit, categories[], series[{name, values[]}], keyPoints[])`.
- Luật validator (code tự kiểm được):
  - 3–8 nhóm; tối đa 3 series (PIE chỉ 1); mọi giá trị ≥ 0.
  - PIE: tổng bằng 100 ±0.5.
  - TABLE: tối đa 6 hàng × 5 cột.
  - Mỗi keyPoint có kiểu dữ liệu `{kind: MAX|MIN|TREND_UP|TREND_DOWN|COMPARE|TOTAL, ref...}` kèm câu chữ.
    Code xác minh `kind` khớp số liệu (ví dụ MAX phải đúng là nhóm lớn nhất).
- `ChartRenderer`: dùng XChart vẽ PNG 800×500. Theme cố định (màu trung tính, cỡ chữ ≥ 14), có tiêu đề, nhãn trục và đơn vị.
  TABLE được vẽ bằng `Graphics2D` (lưới đơn giản). Sau đó `MediaService.storeGenerated(png, "image/png", ...)`.
- Reviewer (tùy chọn, bật bằng `itembank.generation.review.visionCheck`): gửi PNG (base64 `image_url`) kèm keyPoints và hỏi
  "ảnh có đọc được và có thể hiện đúng các ý này không". `Capstone` có hỗ trợ vision. Nếu FAIL thì vẽ lại không giúp được gì, câu bị bỏ.
- Mapper: `imagePromptRef`; `referenceAnswerText` = câu chữ của keyPoints.

## Test
- `ChartDraftValidatorTest`: tổng PIE, keyPoint MAX sai thì báo lỗi, giới hạn số nhóm.
- `ChartRendererTest`: mỗi loại trả về PNG hợp lệ (đọc lại được bằng `ImageIO`, đúng kích thước). Không so sánh pixel.

## Done khi
Sinh được 4 câu DI (mỗi loại 1 câu), ảnh hiện trong preview, keyPoints khớp số liệu.

## Design Constraints
- Giữ các ratchet (300 dòng/file, 15 class/package `internal`, `Clock`, constants) và áp dụng các quyết định red-team của phase này trong plan.md.

## Quality and Testing State
- Chưa cook. Test theo mục Test của phase; cổng `ck:quality` bắt buộc trước khi đóng phase.
