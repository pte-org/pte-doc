# Phase 01 — Gõ theo thời gian, chọn tốc độ, Hiện hết

**Trạng thái:** [x] · **Phụ thuộc:** không có

## Vấn đề

`useTypedText` hiện `TYPING_CHARS_PER_FRAME = 1` ký tự mỗi `requestAnimationFrame`. Vì vậy tốc độ gõ phụ thuộc tần số màn hình: 60 ký tự/giây ở 60 Hz, 144 ký tự/giây ở 144 Hz.

## Thay đổi (`features/questiongeneration`)

1. **`typingConstants.ts` (mới).**
   - `TYPING_SPEEDS = { slow: 15, normal: 30, fast: 60 } as const` (ký tự/giây), `type TypingSpeed`.
   - `DEFAULT_TYPING_SPEED = "normal"`.
   - `TYPING_SPEED_STORAGE_KEY`.
   - Xóa `TYPING_CHARS_PER_FRAME` khỏi `liveConstants.ts`.
2. **`utils/typingStep.ts`.** Đổi thành hàm thuần `revealedChars(elapsedMs, charsPerSecond, length)`, trả về `min(length, floor(elapsedMs × cps / 1000))`.
3. **`hooks/useTypedText.ts`.**
   - Chữ ký mới: `useTypedText(target, charsPerSecond, revealAll)`.
   - Lấy thời gian bằng `performance.now()` tại mỗi frame, cộng dồn từ lúc đoạn chữ bắt đầu.
   - Khi target bắt đầu lại từ đầu (một lần gọi model mới) thì reset mốc thời gian, giữ đúng hành vi hiện tại.
   - Khi `revealAll` là true thì trả về toàn bộ target.
4. **`hooks/useTypingSpeed.ts` (mới).**
   - Trả về `{ speed, setSpeed }`, đọc và ghi `localStorage` an toàn khi render phía server.
   - Giá trị lạ trong storage thì dùng mặc định.
5. **Hiện hết.**
   - State `revealAll` đặt trong `_LiveItemPanel` và reset khi đổi `live.index`.
   - Cả `generatorText` và `reviewerText` đều nhận cờ này.
   - Hiện hết **không** mở các bước gate đang dừng và **không** bỏ qua bước xác nhận trước khi lưu.
6. **Thanh điều khiển.**
   - Mở rộng `_StepGateBar`, hoặc thêm `_ReplayControls.tsx` nếu file vượt giới hạn dòng.
   - Gồm: chọn tốc độ bằng component `@pte/ui` có sẵn (tìm segmented control hoặc `Select` trước) và nút **Hiện hết**.
   - Nút Hiện hết chỉ hiện khi đang gõ (`busy`).
7. **Chữ hiển thị** (vi/en) trong `liveConstants.ts`, hoặc trong `typingConstants.ts` nếu `liveConstants` vượt 300 dòng:
   - `typingSpeed` (Tốc độ gõ), `speedSlow` (Chậm), `speedNormal` (Vừa), `speedFast` (Nhanh), `revealAll` (Hiện hết).
8. Tìm các nơi khác gọi `useTypedText` (`grep useTypedText`) và truyền tốc độ cho đúng.

## Test

- `tests/unit/features/questiongeneration/typingStep.test.ts`: viết lại cho `revealedChars`. Cùng `elapsedMs` thì cùng kết quả; không vượt quá `length`; 0 ms cho 0 ký tự.
- `useTypingSpeed`: giá trị lạ trong storage thì dùng mặc định; đổi tốc độ thì lưu lại.

## Hoàn thành khi

- [x] Không còn `TYPING_CHARS_PER_FRAME`.
- [x] Tốc độ gõ không phụ thuộc tần số màn hình.
- [x] Chọn được tốc độ và trình duyệt nhớ lựa chọn; Hiện hết hoạt động.
- [x] tsc, eslint và vitest đều qua.
