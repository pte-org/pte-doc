# Chữ "Ai xử lý" khó đọc ở light mode (`/admin/ai/prompts`)

## Nguyên nhân
Tailwind v4 mặc định áp biến thể `dark:` theo hệ điều hành (`prefers-color-scheme`), còn app đổi giao diện bằng `data-theme` trên `<html>`.
Máy bật dark mode nhưng app ở light thì các chip LLM / Kokoro TTS / Vẽ biểu đồ vẫn nhận màu của dark (chữ `*-200` nhạt, nền `/25`), nên chữ nhạt trên nền nhạt.
Đo trên trình duyệt: `color: lab(84)` ở theme light khi OS dark.

## Sửa
`packages/ui/src/styles/design-tokens.css`: `@custom-variant dark (&:where([data-theme="dark"], [data-theme="dark"] *));` — `dark:` giờ theo công tắc của app (dùng chung tenant-web và vendor-web).
Ảnh hưởng: 12 file có dùng `dark:` nay theo theme của app thay vì hệ điều hành (đúng ý định).

## Kết quả
- Light (OS vẫn dark): chữ LLM `rgb(51,89,210)`, nền `/10` — đọc rõ. Dark: chữ `rgb(182,198,255)` — giữ nguyên như trước.
- Chưa rà từng màn khác dùng `dark:` bằng mắt; chưa có test tự động cho phần CSS này.
