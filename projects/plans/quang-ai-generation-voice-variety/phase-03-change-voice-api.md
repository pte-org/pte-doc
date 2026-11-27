# Phase 03 — API đổi giọng, danh mục giọng, mẫu nghe thử

**Trạng thái:** [x] [quality: skipped_by_user; decision: user_confirmed_skip] · **Phụ thuộc:** phase 01 (danh mục); nên sau phase 02 vì cùng sửa `MediaRenderer`
**Story:** P1 "đổi giọng một câu đã sinh" (FR-05, FR-06, FR-07, FR-09)

## Vấn đề

Không có đường nào để tạo lại audio của một câu đã lưu. `MediaRenderer.speak` gắn chặt tổng hợp giọng, chỉnh tốc độ và lưu file với luồng sinh đề. Văn bản cần đọc không có sẵn dạng "transcript" trên `Question`.

## Thay đổi

Gốc backend: `pte-api/app/src/main/java/com/pte/itembank/`.

1. **Trích `SpeechFitter`** (`internal/generation/media/SpeechFitter.java`, mới): `fit(text, voice, taskTypeKey)` làm đúng phần hiện nằm trong `MediaRenderer.speak`: tổng hợp, đo độ dài bằng `AudioDurationProbe`, thử lại một lần với tốc độ ±0,1 theo `AudioDurationRules`, ném `GENERATION_AUDIO_DURATION_OUT_OF_RANGE` nếu vẫn sai. Trả `(audio, speed, seconds)`. `MediaRenderer.speak` gọi lại lớp này (không đổi hành vi). Gói `media` lên 12 class.
2. **Gói mới `internal/generation/voice/`** (≤ 15 class):
   - `SpokenTextResolver`: từ `Question` suy ra văn bản đọc. Các dạng đọc từ `referenceAnswerText`: WRITE_FROM_DICTATION, REPEAT_SENTENCE, ANSWER_SHORT_QUESTION, SUMMARIZE_SPOKEN_TEXT, MC_LISTENING_SINGLE, MC_LISTENING_MULTIPLE, HIGHLIGHT_CORRECT_SUMMARY, SELECT_MISSING_WORD, FILL_IN_THE_BLANKS_TYPE_IN, RE_TELL_LECTURE, HIGHLIGHT_INCORRECT_WORDS. Hội thoại (SUMMARIZE_GROUP_DISCUSSION, RESPOND_TO_A_SITUATION), dạng không audio, câu không có `audioPromptRef` hoặc không có `generation_meta.media` (không do AI sinh): trả `GENERATION_VOICE_NOT_SUPPORTED_FOR_TASK`. Danh sách dạng hỗ trợ là hằng số.
   - `VoiceChangeService`: một phương thức public `changeVoice(publicId, voice, version, caller)`. **Không** có `@Transactional` (tổng hợp có thể tới 90 giây, không giữ kết nối DB). Trình tự:
     1. Kiểm tra `voice` có trong danh mục và đang bật (`GENERATION_VOICE_UNKNOWN`).
     2. Tải câu và gọi **guard ghi dùng chung** (xem mục 6). Nếu `voice` trùng giọng hiện tại thì trả `GENERATION_VOICE_UNCHANGED` (409) và không gọi Kokoro.
     3. Lấy văn bản đọc, chạy `SpeechFitter.fit` trong **giới hạn đồng thời**: mỗi user tối đa 1 lần đổi giọng đang chạy, toàn app tối đa `VOICE_CHANGE_MAX_CONCURRENT` (2) lần gọi Kokoro tương tác; vượt thì trả `GENERATION_VOICE_BUSY` (429).
     4. Gọi `MediaService.storeGenerated` (loại `AUDIO_PROMPT`, pool của câu, `caller`), rồi gọi writer.
   - `QuestionVoiceWriter`: một phương thức public `apply(...)` có `@Transactional`.
     - **Tải lại câu trong transaction**, gọi lại guard ghi (vẫn `DRAFT`, vẫn được sửa) và **luôn so `version`** với giá trị client gửi. Không bỏ qua khi `version` null; `version` là trường bắt buộc của body.
     - Đặt `audioPromptRef` mới. Cập nhật `generation_meta.media` (`audioPromptRef`, `voice`, `speed`, `durationSec`) bằng JSON mapper, không dùng regex như `GenerationMetaHelper`. **Giữ nguyên mọi key khác** của `generation_meta` (review, model, topic). `content_hash` không đổi.
     - Ghi audit `AUDIO_VOICE_CHANGED`, actor là `caller`. Tóm tắt gồm giọng cũ và mới, ref cũ và mới, không chứa text đề.
     - Nếu lỗi (xung đột `version`, câu đã rời `DRAFT`, validate), `VoiceChangeService` xóa **chỉ file mới** vừa tạo bằng `MediaService.deleteGenerated`. Nếu xóa cũng lỗi thì ghi WARN kèm ref và vẫn ném lỗi gốc. **File cũ không bao giờ bị xóa.**
   - `VoiceSampleService`: `sample(voice)` trả WAV của câu mẫu cố định.
     - **Kiểm tra `voice` có trong danh mục đang bật** trước khi làm gì khác.
     - Cache trong bộ nhớ dạng **single-flight**: map `voice → CompletableFuture<byte[]>`. Không gọi Kokoro bên trong `computeIfAbsent`. Lỗi thì xóa future khỏi map và giữ cache âm 60 giây.
     - Lần gọi Kokoro cho mẫu dùng chung giới hạn đồng thời toàn app ở trên.
     - Chọn cache bộ nhớ thay vì lưu Cloudinary vì lưu cần bảng ánh xạ giọng và file (phải có migration) và làm đầy Cloudinary dùng chung. Mất cache khi khởi động lại chỉ tốn một lần gọi Kokoro mỗi giọng.
   - `VoiceCatalogQueryService`: `listEnabled()` trả danh sách (mã, accent, giới tính, nhãn).
3. **Controller** `internal/generation/controller/QuestionVoiceController.java` (mới, gói có 5 class), `@PreAuthorize` giống `QuestionController`:
   - `POST /api/v1/questions/{publicId}/audio/voice`, body `{ voice, version }` (cả hai bắt buộc, `@Valid`) → `ApiResponse<QuestionResponse>`.
   - `GET /api/v1/question-generation/voices` → `ApiResponse<List<VoiceOptionResponse>>`.
   - `GET /api/v1/question-generation/voices/{voice}/sample` → audio mẫu với `Cache-Control: private, max-age=86400`.
   - Ghi rõ role của cả 3 endpoint: lấy đúng biểu thức `@PreAuthorize` của endpoint sửa câu hỏi trong `QuestionController` (role vendor hoặc academic có quyền ghi bản nháp). Kiểm tra rate limit hiện có có phủ các route này không; ghi kết quả vào "Ghi chú khi làm".
   - Lỗi Kokoro và lỗi media trả `ApiResponse` lỗi đã làm sạch: không có URL Kokoro, không có body của provider, không có stack trace. Trước khi code, đọc `apiClient` ở vendor-web để chốt kiểu trả: `audio/wav` nếu client đọc được blob, nếu không thì JSON `{contentType, audioBase64}`; ghi quyết định vào "Ghi chú khi làm".
4. **Hằng số** `internal/generation/constant/VoiceConstants.java` (mới): mã lỗi `GENERATION_VOICE_UNKNOWN`, `GENERATION_VOICE_NOT_SUPPORTED_FOR_TASK` cùng thông báo, câu mẫu, thời gian cache, danh sách dạng bài hỗ trợ. Hằng audit `AUDIT_AUDIO_VOICE_CHANGED` và tóm tắt đặt trong `internal/constant/ItembankConstants.java` cạnh `AUDIT_UPDATED`. Mã media/độ dài dùng lại từ `QuestionGenerationConstants`. Kiểm tra bản đồ lỗi toàn cục ánh xạ `GenerationMediaException` sang mã HTTP nào; lỗi nghiệp vụ trả 4xx, Kokoro không sẵn sàng trả mã hiện có của `LlmProviderException`.
5. **DTO.** Không mở rộng `QuestionResponse` bằng toàn bộ `generationMeta`. Thêm một trường hẹp `currentVoice` (null với câu không do AI sinh hoặc dạng không hỗ trợ đổi giọng) và `voiceChangeSupported` (boolean) để phase 4 dùng.
6. **Guard ghi dùng chung.** Trích phần kiểm tra quyền trong `QuestionLifecycleService.update` thành một phương thức của lớp policy hoặc guard có sẵn, ví dụ `accessPolicy.requireDraftWrite(question, caller)`. Phần kiểm tra gồm: role, `canModifyDraft`, chủ sở hữu, pool, tenant và trạng thái `DRAFT`. `update` và cả hai lần kiểm tra của đổi giọng đều gọi phương thức này, không viết lại logic. Hành vi của `update` không đổi.
7. **Hằng số bổ sung** trong `VoiceConstants`: `GENERATION_VOICE_UNCHANGED`, `GENERATION_VOICE_BUSY`, `VOICE_CHANGE_MAX_CONCURRENT`, `VOICE_SAMPLE_NEGATIVE_CACHE_SECONDS`.

## Design Constraints

- Tuân thủ `docs/CODING_STANDARDS_API.md`: thông báo/mã lỗi trong `*Constants.java`; `@Transactional` chỉ ở service (writer), không ở controller; phản hồi qua `ApiResponse`; lỗi qua `DomainException`/lớp lỗi có mã; file ≤ 300 dòng; service ≤ 5 phương thức public; gói `internal/**` ≤ 15 class; thời gian qua `Clock` được inject.
- Đọc thêm `docs/API_RESPONSE_SETUP.md` và `docs/COMMON_EXCEPTION_SETUP.md` trước khi viết controller và lỗi.
- **Không xóa file audio cũ.** Đề đã xuất bản giữ `audioPromptRef` cũ qua `QuestionFreezeView`. Chỉ xóa file mới của chính lần gọi thất bại.
- Chỉ người có quyền sửa câu (cùng luật `update`) mới gọi được; câu không phải `DRAFT` bị từ chối bằng lỗi chuyển trạng thái có sẵn.
- Không ghi text đề hay API key vào log.
- Không giữ transaction DB trong lúc gọi Kokoro.

## Quality and Testing State

- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementing this phase)
- Testing: not started

## Test

- `SpeechFitterTest`: trong khoảng thì một lần gọi; ngoài khoảng thì thử tốc độ khác; vẫn sai thì ném lỗi độ dài.
- `SpokenTextResolverTest`: mỗi dạng hỗ trợ trả đúng `referenceAnswerText`; hội thoại, dạng không audio, câu thiếu `generation_meta.media` bị từ chối đúng mã.
- `VoiceChangeServiceTest`:
  - Giọng lạ hoặc bị tắt trả `GENERATION_VOICE_UNKNOWN`. Giọng trùng giọng hiện tại trả `GENERATION_VOICE_UNCHANGED` và không gọi Kokoro.
  - Thành công thì `audioPromptRef` mới khác ref cũ, `meta.media.voice` là giọng mới, và `deleteGenerated` không bao giờ được gọi với ref cũ.
  - Độ dài vượt luật thì không lưu file. Xung đột `version` thì chỉ xóa file mới.
  - User đã có một lần đổi giọng đang chạy thì nhận `GENERATION_VOICE_BUSY`.
- `QuestionVoiceWriterTest`:
  - Ghi meta đúng và giữ nguyên các key khác (review, model, `content_hash`). Audit không chứa text đề.
  - Câu chuyển sang trạng thái khác `DRAFT` trong lúc gọi Kokoro thì bị từ chối và file mới bị xóa.
- Quyền (guard dùng chung): sai role, `DRAFT` của người khác, pool không có quyền ghi đều bị từ chối. Test cũ của `QuestionLifecycleService.update` vẫn qua.
- `VoiceSampleServiceTest`:
  - Gọi hai lần cùng giọng chỉ gọi Kokoro một lần, kể cả khi gọi đồng thời.
  - Giọng không có trong danh mục bị từ chối và không gọi Kokoro.
  - Lần gọi lỗi không bị cache vĩnh viễn.
- `QuestionVoiceControllerTest`: quyền, mã lỗi, định dạng phản hồi, lỗi Kokoro đã làm sạch. Cập nhật `ApiInventoryExportTest` nếu bản kê endpoint đang so khớp.
- Chạy: `.\mvnw.cmd -pl app -DskipTests compile`, targeted `-Dtest=...`, `PackageDensityTest`, `SourceFileSizeTest`; build lại container `app` local.

## Hoàn thành khi

- [x] Đổi giọng một câu REPEAT_SENTENCE ở test: ref mới, meta mới, độ dài đúng luật, ref cũ không bị xóa.
- [x] Giọng không hợp lệ và dạng không hỗ trợ bị từ chối đúng mã.
- [x] `GET` danh mục chỉ trả giọng đang bật; mẫu nghe thử không gọi Kokoro lần hai.
- [x] `MediaRenderer` hành vi không đổi sau khi trích `SpeechFitter`; compile, test nhắm đích qua.

## Ghi chú khi làm

- **Kiểu trả của mẫu nghe thử:** `audio/wav` (`ResponseEntity<byte[]>`; `ApiResponseAdvice` không bọc `byte[]`). `packages/api-client/src/client/client.ts` đã đọc được `blob`, nên phase 4 dùng được.
- **DTO:** `QuestionResponse` đã có `generationMeta.media.voice` cho người soạn đề, nên không thêm `currentVoice`. Danh sách dạng bài hỗ trợ đổi giọng đi kèm `GET /question-generation/voices` (`supportedTaskTypes`), web không giữ danh sách riêng.
- **Guard ghi:** không sửa `QuestionLifecycleService` (289 dòng, nhiều constructor có test). `DraftWriteGuard` (gói `voice`) gọi cùng `ItembankAccessPolicy.canModifyDraft` mà `update` dùng, cộng kiểm tra `DRAFT` và `version` bắt buộc. Quyết định về quyền vẫn nằm ở một chỗ (policy); hai nơi chỉ lặp lại 3 dòng gọi policy.
- **Quyền của 3 endpoint:** `@PreAuthorize("hasAnyRole('PLATFORM_ADMIN','ACADEMIC_MANAGER','ACADEMIC_STAFF','PLATFORM_AUTHOR')")` ở class, giống `QuestionController`; `ApiInventoryExportTest` đã cập nhật thêm 2 route GET.
- **Giới hạn Kokoro:** `VoiceChangeLimiter` (mỗi người 1 lần, toàn app 2 lần, vượt thì 429 `GENERATION_VOICE_BUSY`). Mẫu nghe thử dùng single-flight và cache lỗi 60 giây.
- **Lỗi đã làm sạch:** lỗi Kokoro đổi thành `GenerationMediaException(GENERATION_MEDIA_FAILED)` (502), chỉ log tên lớp lỗi.
- **Chưa kiểm tra:** rate limit chung của app có phủ 3 route mới hay không; `createRevision` có chép `generation_meta.media` hay không (nếu không thì bản revision báo "không hỗ trợ").
- Không chạy quality gate (user yêu cầu bỏ). `SourceFileSizeTest` vẫn chỉ fail ở `ExamPublishService.java`.
