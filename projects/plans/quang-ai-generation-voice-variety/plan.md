# Sinh đề AI: giọng đọc đa dạng và đổi giọng từng câu

**Trạng thái:** Phase 1–4 xong, phase 5 để sau · **Tác giả:** quang · **Ngày:** 2026-11-26
**Nguồn:** [spec.md](spec.md) (brainstorm: [brainstorm.md](brainstorm.md))
**Phạm vi:** `pte-api/app` (module `itembank`, gói `internal/generation`) và `pte-web/apps/vendor-web`. Không có migration.
**Chuẩn bắt buộc:** `docs/CODING_STANDARDS_API.md`, `pte-web/docs/CODING_STANDARDS_WEB.md`, `pte-web/AGENTS.md`

## Mục tiêu

- Lô sinh đề có audio dùng nhiều giọng: Mỹ/Anh cân bằng, nam/nữ cân bằng, hai câu liền nhau không trùng giọng (P1).
- Người tạo đề đổi giọng một câu đã sinh, có nghe thử. Câu nhận `audioPromptRef` mới, file cũ giữ nguyên (P1).
- Câu hội thoại xáo lại giọng người nói (P2).

## Tóm tắt khảo sát code (Hard mode)

Các điểm dưới đây đã đọc trong code và quyết định thiết kế của các phase.

1. **Job biết lô của mình.** `QuestionGenerationJob` có `batchId`, `batchSeq`, `batchRowIndex`. Nhưng `JobClaim` (`internal/generation/pipeline/JobClaim.java`) chưa mang các giá trị này, và `GenerationPipeline` chỉ truyền `claim.jobPublicId().getLeastSignificantBits()` làm seed cho `MediaRenderer.render`. `JobLeaseService.claimOf` (`internal/generation/worker/JobLeaseService.java`) là nơi tạo claim.
2. **Vị trí toàn lô tính được, không cần lưu.** `BatchSplitter` cắt các hàng thành job liên tục theo `seq`, mỗi job có `requestedCount` cố định (CHECK 1..10). Vị trí toàn lô của câu = tổng `requested_count` của các job có `batchSeq` nhỏ hơn + index trong job. Seed lô = một số lấy từ `publicId` của lô. Hàm `(seed lô, vị trí)` cho ra giọng, lặp lại được kể cả khi job chạy lại. **Chọn cách tính, không lưu giọng theo slot**: lưu cần cột mới và migration, và phải đồng bộ khi job bị hủy hoặc chạy lại. Cái giá: một truy vấn tổng khi claim job.
3. **Văn bản đọc suy ra được từ `Question`.** Mọi dạng `ListeningDraft` và `HiwDraft` lưu transcript vào `referenceAnswerText` (xem `AudioDraftMapper`, `HiwDraftMapper`): WRITE_FROM_DICTATION, REPEAT_SENTENCE, ANSWER_SHORT_QUESTION, SUMMARIZE_SPOKEN_TEXT, MC_LISTENING_SINGLE/MULTIPLE, HIGHLIGHT_CORRECT_SUMMARY, SELECT_MISSING_WORD, FILL_IN_THE_BLANKS_TYPE_IN, RE_TELL_LECTURE, HIGHLIGHT_INCORRECT_WORDS. **Hội thoại không dựng lại được**: SGD không lưu gì ngoài key points, RTS chỉ lưu `situation` ở `promptText`, các lượt thoại (`turns`) không lưu. Phase 3 báo `GENERATION_VOICE_NOT_SUPPORTED_FOR_TASK` cho hội thoại; phase 5 lưu `turns` vào `generation_meta.media` cho câu mới.
4. **Đề đã xuất bản.** `QuestionFreezeView` và `SnapshotItemFactory` chụp `audioPromptRef`. Đổi giọng tạo ref mới và không gọi `MediaService.deleteGenerated` với ref cũ. `QuestionLifecycleService.update` chỉ cho sửa câu `DRAFT`; endpoint đổi giọng theo cùng luật.
5. **Mã giọng có hai nơi cấu hình cần dọn:** `QuestionGenerationProperties.Kokoro.voicesUs/voicesUk`, `application.yml` (dòng 331-332), `pte-api/.env.example`, `docker-compose.services.yml` (dòng 105-106) và `.env.local` (đã gitignore, sửa tay).
6. **Trần kích thước.** `QuestionDetailView.tsx` đang 299 dòng nên không thêm trực tiếp được; phase 4 tách phần audio ra component riêng. Gói `internal/generation/media` có 9 class (trần 15); `internal/generation/controller` có 4.

## Các phase

| # | Phase | Story | Trạng thái | File |
|---|---|---|---|---|
| 1 | Danh mục giọng và cấu hình tắt giọng | nền cho P1 | [x] | [phase-01-voice-catalog.md](phase-01-voice-catalog.md) |
| 2 | Chia giọng theo vị trí trong lô | P1 (lô) | [x] | [phase-02-batch-voice-assignment.md](phase-02-batch-voice-assignment.md) |
| 3 | API đổi giọng, danh mục giọng, mẫu nghe thử | P1 (đổi giọng) | [x] | [phase-03-change-voice-api.md](phase-03-change-voice-api.md) |
| 4 | Hộp "Đổi giọng" ở trang chi tiết câu hỏi | P1 (đổi giọng) | [x] | [phase-04-vendor-change-voice-dialog.md](phase-04-vendor-change-voice-dialog.md) |
| 5 | Xáo lại giọng câu hội thoại | P2 | [ ] | [phase-05-dialogue-reshuffle.md](phase-05-dialogue-reshuffle.md) |

Thứ tự: 1 → 2 → 3 → 4 → 5. Phase 2 và 3 cùng cần danh mục của phase 1. Phase 3 trích `SpeechFitter` từ `MediaRenderer`, phase 2 cũng sửa `MediaRenderer`, nên làm tuần tự. Phase 4 cần API của phase 3. Phase 5 dùng lại hộp thoại của phase 4 và `DialogueRenderer` tách từ `MediaRenderer`.

## Kiểm tra chung

Backend (từ `pte-api`):

```powershell
.\mvnw.cmd -pl app -DskipTests compile
.\mvnw.cmd -pl app test -Dtest=<lớp test của phase>
.\mvnw.cmd -pl app test   # cuối kế hoạch
```

- `SourceFileSizeTest` đang fail sẵn ở `ExamPublishService.java`, không thuộc kế hoạch này. Báo riêng, không sửa.
- Sau mỗi thay đổi backend, build lại container `app` local (compose `docker-compose.services.yml`).

Web (từ `pte-web/apps/vendor-web`):

```bash
pnpm exec tsc --noEmit
pnpm exec eslint <đường dẫn đã sửa>
pnpm exec vitest run <đường dẫn test>
```

- Không mở trình duyệt; user tự kiểm tra giao diện.

## Rủi ro

- **CAO. Cloudinary dùng chung local và prod.** Đổi giọng tạo file mới, không xóa file cũ. Chỉ xóa file mới do chính lần gọi đó tạo, khi lưu DB thất bại. Có test khẳng định ref cũ không bị `deleteGenerated`.
- **CAO. Độ dài audio vượt luật khi đổi giọng.** Dùng lại logic chỉnh tốc độ một lần (trích thành `SpeechFitter`). Vẫn vượt thì trả `GENERATION_AUDIO_DURATION_OUT_OF_RANGE`, không lưu file.
- **TRUNG BÌNH. Server Kokoro thật thiếu giọng trong danh mục.** Bước kiểm tra `GET {KOKORO_BASE_URL}/v1/audio/voices` ở phase 1; giọng thiếu đưa vào `QUESTION_GEN_VOICES_DISABLED`. Mã giọng không có trong danh mục khi tắt chỉ bị bỏ qua và ghi cảnh báo một lần.
- **TRUNG BÌNH. Giữ transaction DB trong lúc gọi Kokoro (tới 90 giây).** Tách service điều phối (không transaction) và writer (có `@Transactional`, chỉ ghi DB). Có kiểm tra `version` khi ghi.
- **TRUNG BÌNH. Gọi đổi giọng đồng thời trên cùng một câu.** Kiểm tra `version`; lần thua xóa file mới của mình và trả lỗi xung đột phiên bản có sẵn.
- **TRUNG BÌNH. Mật độ gói và kích thước file.** Class mới đặt ở gói `internal/generation/voice` và `media` (≤ 15 class); `QuestionDetailView.tsx` phải tách bớt trước khi thêm nút. Chạy `PackageDensityTest` và `SourceFileSizeTest` ở mỗi phase.
- **THẤP. Phát mẫu nghe thử tốn băng thông.** Cache bộ nhớ trong tiến trình cộng `Cache-Control`; mỗi giọng chỉ gọi Kokoro một lần mỗi lần khởi động app.
- **TRUNG BÌNH. File mồ côi trên Cloudinary.** App sập giữa `storeGenerated` và lúc commit sẽ để lại file mới không ai dùng. Mỗi lần đổi giọng thành công cũng giữ file cũ mãi mãi. Chấp nhận: dung lượng tăng theo số lần đổi giọng. Xóa file thất bại thì ghi WARN kèm ref để dọn tay. (red-team M1, NOTED)
- **TRUNG BÌNH. Câu đã duyệt không đổi giọng được.** Đổi giọng chỉ áp dụng cho câu `DRAFT`. Câu đã duyệt phải qua `createRevision`. Phase 3 kiểm tra `createRevision` có chép `generation_meta.media` không. Nếu không chép, bản revision bị báo "không hỗ trợ"; ghi lại thành giới hạn đã biết. (red-team M3, NOTED)
- **TRUNG BÌNH. Lạm dụng Kokoro.** Giới hạn mỗi user 1 lần đổi giọng đang chạy. Toàn app tối đa 2 lần gọi Kokoro tương tác cùng lúc. Mẫu nghe thử dùng single-flight và chỉ nhận giọng có trong danh mục. (red-team H3, ACCEPTED)
- **THẤP. Câu cũ không có `generation_meta.media`** (nhập tay): từ chối bằng `GENERATION_VOICE_NOT_SUPPORTED_FOR_TASK`, không thay audio thu âm của người dùng.

## Quyết định của user (2026-11-26)

- Đổi giọng chỉ áp dụng cho câu `DRAFT`.
- Mẫu nghe thử cache trong bộ nhớ của app.
- Bỏ qua quality gate từ phase 3 (user yêu cầu 2026-11-26).
- Đợt này chỉ cook phase 1–4. Phase 5 (P2) để sau.

## Review phản biện (2026-11-26)

Verdict: WARN, không có lỗi CRITICAL. Cách xử lý từng điểm:
- **H1. Ghi đè lẫn nhau khi đổi giọng đồng thời.** ACCEPTED. `version` bắt buộc trong body. Writer tải lại câu, kiểm tra lại `DRAFT` và luôn so `version` (phase 3).
- **H2. Kiểm tra quyền viết lại theo kiểu "giống update".** ACCEPTED. Trích một guard ghi dùng chung từ `update` (phase 3, mục 6).
- **H3. Lạm dụng Kokoro qua mẫu nghe thử và đổi giọng.** ACCEPTED. Kiểm tra giọng có trong danh mục, single-flight, giới hạn đồng thời (phase 3).
- **H4. Vị trí trong lô lệch khi lô hỗn hợp hoặc job retry.** ACCEPTED. Chỉ đếm câu audio; xác minh `requested_count` và `batch_seq` không đổi; test lô hỗn hợp và retry (phase 2).
- **H5. Bỏ cấu hình giọng cũ có thể làm hỏng prod.** ACCEPTED một phần. Có cảnh báo khi khởi động, kiểm tra `compose config`, ghi chú dọn `.env` trên VPS (phase 1). REJECTED phần "giữ danh mục giống danh sách cũ", vì thêm giọng là mục tiêu của tính năng.
- **M2. Ghi lại meta làm mất review hoặc rubric.** ACCEPTED. Giữ mọi key khác của meta.
- **M4. Còn giả định chưa xác minh, lộ lỗi Kokoro.** ACCEPTED. Thêm trường hẹp `currentVoice` thay vì cả `generationMeta`; lỗi Kokoro đã làm sạch.
- **M6. Bấm hai lần gọi Kokoro hai lần.** ACCEPTED. Chọn trùng giọng hiện tại thì trả 409; giao diện khóa nút khi đang gửi.
- **M1, M3.** NOTED, xem mục Rủi ro.
- **M5. Trần kích thước file.** Đã có trong plan: phase 4 tách `QuestionDetailView.tsx` ngay ở bước đầu.

## Giả định chưa xác minh

- Cách `apiClient` (`pte-web/apps/vendor-web/lib/apiClient`) đọc phản hồi nhị phân. Phase 3 chốt: trả `audio/wav` nếu đọc được blob, nếu không thì trả JSON base64.
- `QuestionResponse` (backend `dto/response` và `packages/api-client/src/types/question/index.ts`) có sẵn `generationMeta` hay không. Phase 3 kiểm tra và bổ sung nếu thiếu.
- `GenerationMediaException` được global handler map sang mã HTTP nào (Kokoro lỗi, độ dài sai).
- Thư mục request trong `packages/api-client/src` (dự kiến `requests/`).
- `.env.local` không có trong kho (gitignore) nên chưa đọc được; sửa tay ở phase 1.

## Ngoài phạm vi

- Chọn accent hoặc giọng ở form tạo lô; bảng giọng trong DB; giọng Úc, Ấn Độ; tạo lại audio hàng loạt cho câu cũ.
- Nút "Đổi giọng" ở trang lô.
- Chọn giọng riêng cho từng người nói trong hội thoại.
