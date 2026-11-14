# Plan: Chặn rò đáp án và transcript từ backend practice

Status: Draft — chờ xác nhận các quyết định ở mục "Cần quyết định"
Date: 2026-11-14
Owner/slug: Ninh — `ninh-practice-answer-leak-backend`
Scope: `pte-api` (module `practice`), `pte-practice` (renderer Re-order, hiển thị sau khi nộp), `pte-doc`
Related: [ninh-practice-exam-integrity-fixes](../ninh-practice-exam-integrity-fixes/plan.md)

## Vấn đề còn lại

Đợt sửa trước chỉ che ở giao diện. Payload của `GET session` vẫn chứa dữ liệu mà học viên đọc được ở tab Network:

| Rò | Nguồn trong code | Hậu quả |
|---|---|---|
| Thứ tự đáp án Re-order | `PracticeTaskContentResponse.Option.orderIndex` là vị trí đúng; `PracticeAnswerCanonicalizer` so `order` với đúng các `orderIndex` đó | Đọc JSON là biết đáp án |
| Thứ tự ngân hàng từ của Fill in the Blanks | `PracticeSessionResponseMapper.toContent` trả option theo thứ tự lưu (từ đúng trước, rồi từ gây nhiễu của từng blank) | Đoán đáp án theo vị trí |
| Transcript bài nghe/nói | `toContent` luôn trả `promptText`, dù là RS, WFD, RE_TELL_LECTURE, SST, SMW, HCS, ASQ | Đọc JSON là biết nội dung audio |

Điểm dữ liệu chấm (`objectiveOptionsJson`, `correctAnswerText`, `referenceAnswerText`) không nằm trong response của học viên, không cần sửa.

## Thiết kế

Việc che đặt ở **lớp chiếu dữ liệu cho học viên** (`PracticeSessionResponseMapper.toContent`), không đổi dữ liệu đã ghim trong `PracticeResponse`. Nhờ vậy không cần migration và phiên cũ cũng được che.

### 1. Transcript bài nghe/nói

- `toContent` trả `promptText = null` cho các task trong danh sách audio-only khi item còn `PENDING`/chưa nộp.
- Danh sách task audio-only dùng chung một hằng ở backend, khớp với `AUDIO_ONLY_TASKS` ở frontend.
- Sau khi nộp hoặc bỏ qua, `promptText` được trả lại. Frontend đang dùng bản `fixture` đã tải sẵn để hiện transcript sau khi nộp; cần để response của `answer` mang lại `promptText` (hoặc đọc từ review) — xem Phase 3.
- Item `PENDING` không có audio nhưng bị che transcript sẽ bị khóa phía UI như hiện tại, không rơi về transcript.

### 2. Fill in the Blanks

- `toContent` xáo trộn thứ tự option bằng seed ổn định `itemPublicId`, rồi đánh lại `orderIndex` theo vị trí hiển thị.
- An toàn vì đáp án blank khớp theo **text** (`joinBlankSelections`), không theo `orderIndex`. Dropdown vẫn giữ `blankIndex`.
- Frontend đã tự xáo trộn; sau thay đổi này việc đó chỉ là lớp thứ hai.

### 3. Re-order Paragraphs (phần khó nhất)

`orderIndex` vừa là định danh đoạn văn, vừa là vị trí đúng. Phải tách hai vai trò:

- Tạo hoán vị `π` cho từng item, suy ra từ `itemPublicId` (không cần cột mới): `RenderedReorderIds.permutation(itemPublicId, n)`.
- Phía học viên: mỗi đoạn có id mới `π(orderIndex)`, danh sách đã xáo trộn theo thứ tự hiển thị.
- `PracticeAnswerCanonicalizer` đảo `π` trước khi so với đáp án đúng.
- `PracticeReviewService` và hiển thị đáp án đã lưu phải dùng cùng ánh xạ.
- Phiên và câu trả lời **đã có** dùng id cũ. Cần cờ phiên bản để không chấm sai: dùng renderer key mới `RE_ORDER_PARAGRAPHS_V2` cho item tạo sau thay đổi, item V1 giữ hành vi cũ.

## Phases

- [ ] Phase 1: Transcript audio-only — `toContent` che `promptText`, hằng dùng chung, test mapper.
- [ ] Phase 2: Fill in the Blanks — xáo trộn có seed ở `toContent`, test thứ tự ổn định và đáp án vẫn khớp.
- [ ] Phase 3: Frontend hiển thị lại transcript sau khi nộp từ response (`answer`/review), cập nhật `SessionTaskView`/`InlineResultCard`.
- [ ] Phase 4: Re-order V2 — `RenderedReorderIds`, canonicalizer đảo hoán vị, review service, renderer key V2 ở `renderer-registry` và `renderer-allowlist`, capability manifest.
- [ ] Phase 5: Kiểm chứng — test đơn vị backend và frontend, thử tay một phiên cũ (V1) và một phiên mới (V2), kiểm tra tab Network không còn thứ tự đáp án hay transcript.

## Test

- Mapper: item audio-only `PENDING` không có `promptText`, item đã nộp thì có.
- Mapper: cùng `itemPublicId` cho cùng thứ tự; hai item khác nhau cho thứ tự khác nhau.
- Canonicalizer: học viên nộp thứ tự hiển thị đúng ⇒ canonical `0,1,2,3`; V1 vẫn chấm như cũ.
- Hồi quy: chấm điểm Re-order và Blanks cho cả V1 và V2; Review hiển thị đúng đoạn văn theo đáp án đã lưu.

## Rủi ro

- Sai ánh xạ `π` làm chấm sai Re-order. Đây là lý do cần cờ V2 và test hồi quy trước khi bật.
- Phiên V1 đang dở vẫn lộ thứ tự đáp án qua Network; chấp nhận cho đến khi các phiên đó kết thúc.
- Che transcript phía server buộc frontend đổi luồng hiển thị sau khi nộp (Phase 3); nếu bỏ sót, màn kết quả mất transcript.
- Bài nghe thiếu audio bị khóa thay vì hiện transcript.

## Cần quyết định

1. Có chấp nhận renderer key V2 cho Re-order (kéo theo đổi frontend và capability manifest), hay chỉ làm Phase 1–3 và để Re-order đến đợt sau?
2. Transcript sau khi nộp lấy từ response của `answer` hay chỉ từ trang Review?
3. Phiên V1 đang dở: để nguyên, hay buộc làm mới?
