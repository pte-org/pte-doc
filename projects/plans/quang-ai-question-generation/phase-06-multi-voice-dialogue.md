# Phase 6: Hội thoại nhiều giọng, SGD và RTS (P3a)

## Mục tiêu
SUMMARIZE_GROUP_DISCUSSION (3 người thảo luận) và RESPOND_TO_A_SITUATION (tình huống, 1 giọng kể chuyện, có thể thêm 1 câu thoại).

## Thay đổi
- `DialogueDraft(topic, turns[{speaker:"A|B|C", text}], keyPoints[])`. Với RTS: `situation`, `turns` (1–2 lượt) và `keyPoints` của câu trả lời tốt.
- Luật validator:
  - SGD: 3 speaker, 6–12 lượt, tổng 180–280 từ, mỗi speaker có từ 2 lượt trở lên.
  - RTS: tình huống 40–90 từ.
- `DialogueSynthesizer`:
  - gán mỗi speaker một giọng cố định, khác nhau về giới tính hoặc giọng vùng;
  - gọi Kokoro cho từng lượt (WAV) rồi ghép PCM bằng `javax.sound.sampled`, chèn 300ms khoảng lặng giữa các lượt;
  - kiểm tra mọi đoạn có cùng sample rate và channels (Kokoro trả 24 kHz mono), nếu khác thì báo lỗi;
  - một lượt lỗi thì retry lượt đó 1 lần.
- Khoảng thời lượng: SGD 70–150 giây, RTS 15–45 giây.
- Mapper: `keyPoints` được ghi vào `referenceAnswerText` để AI scorer dùng cho trait Content (đối chiếu với `RubricCatalog` SGD/RTS).
  `generation_meta.media.voices` = `{A: "...", B: "...", C: "..."}`.

## Test
- `DialogueSynthesizerTest`: ghép 3 WAV giả thì độ dài = tổng + khoảng lặng; khác sample rate thì lỗi.
- Validator cho SGD và RTS.

## Done khi
Một câu SGD phát được, nghe ra 3 giọng khác nhau, có keyPoints trong panel review.

## Design Constraints
- Giữ các ratchet (300 dòng/file, 15 class/package `internal`, `Clock`, constants) và áp dụng các quyết định red-team của phase này trong plan.md.

## Quality and Testing State
- Chưa cook. Test theo mục Test của phase; cổng `ck:quality` bắt buộc trước khi đóng phase.
