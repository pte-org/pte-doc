# Phase 06: replay engine với vòng bị ngắt

**Trạng thái:** [x] Đã làm (2026-11-27) · **Repo:** pte-web · **Phụ thuộc:** 03, 05

## Mục tiêu

Khi câu bị ngắt rồi viết lại, phần phát lại không nhảy lùi bước, không coi phần viết dở là kết quả, và mở vòng mới khi tiếp tục.

## Bối cảnh

Replay engine (`features/questiongeneration/replay/`) mở vòng mới ở mỗi check `PROMPT`. Khi viết lại sau tạm dừng, backend phát `PROMPT` mới, nên vòng mới tự mở. Phần cần thêm là cách xử lý **phần đuôi của vòng bị ngắt** và trạng thái chờ giữa hai lần chạy.

## Việc cần làm

- [x] `buildScript`/`mergeSnapshot`: khi câu nhận `stage QUEUED` sau khi đã có bước trong vòng hiện tại (sự kiện phase 03 phát), đánh dấu bước write/review dở của vòng đó là `superseded` và **không** thêm bước outcome.
- [x] Bảng quy tắc gộp snapshot: snapshot sau khi dừng có thể đã xóa check của vòng dở. Giữ đúng quy tắc chỉ thêm (không xóa bước đã phát lại).
- [x] Chip và view: câu đang chờ sau khi dừng hiện "Chờ lượt"; playhead dừng ở bước cuối đã phát (I7), không tiến tới outcome.
- [x] Fixture `tests/fixtures/replay/pause-midway-resume.ndjson`: viết tay theo đúng thứ tự sự kiện phase 03 phát (vòng 1 dở, `stage QUEUED`, `end`, kết nối lại, snapshot, `PROMPT` vòng 2, viết xong, lưu). Ghi thêm một fixture thật nếu chạy được trên local, tối đa 3 job.
- [x] Đăng ký fixture trong `fixtureRegistry.ts`, chạy cùng bộ bất biến I1–I7.

## Ràng buộc thiết kế

- Không thêm nguồn sự thật mới: mọi thứ đi qua script và playhead (ratchet `replayEngineRatchet.test.ts`).
- Không đụng đến cách mở vòng ở `PROMPT`.

## Kiểm thử

- `buildScript`: `stage QUEUED` giữa vòng làm vòng đó `superseded`, không có outcome.
- `mergeSnapshot`: snapshot sau khi dừng không xóa bước.
- Harness: fixture mới qua I1–I7 ở mọi chế độ (mặc định, nhanh, hiện hết, dừng sau mỗi bước, bỏ qua).

## Tiêu chí xong

Toàn bộ test replay và architecture qua; trên local, câu bị ngắt hiện vòng 1 bị gạch, vòng 2 viết lại và lưu.
