# Phase 1: Vendor foundation và spike

Covers: P1-2 (nền tảng), FR-05, FR-06, FR-12

## Requirements
Có sẵn các client vendor bằng Java thuần:
- Azure Speech qua REST short audio (en-US, Prosody), kèm bộ cắt audio dài thành các đoạn ≤ 28 giây và bước gộp kết quả.
- Gemini native với schema output.
- Bước chuẩn hoá audio và config chọn provider fail-fast.

Spike xác nhận được hai điều tài liệu Azure chưa nói rõ, để Phase 3 và 4 chọn đúng cách gọi.

## Steps
1. Không đổi Dockerfile và không thêm Speech SDK. Client Azure dùng `java.net.http.HttpClient` như client Gemini, nên chạy giống nhau trên amd64 của máy dev và arm64 của VPS.
2. Viết bước chuẩn hoá audio về WAV PCM 16 kHz mono 16-bit bằng thư viện chuẩn của JDK; kiểm trên một bản ghi thật của pte-app (44.1 kHz) và trên mẫu trong `ai-research/samples`; nếu không đủ thì chuyển đổi 2 bước.
3. Viết bộ cắt audio (chỉ chạy khi audio > 28 giây):
   - Đo RMS theo khung 20 ms. Trong cửa sổ giây 18–28 của mỗi đoạn, cắt ở giữa khoảng lặng dài nhất ≥ 200 ms, với ngưỡng tương đối theo năng lượng của chính bản ghi.
   - Không có khoảng lặng thì cắt ở khung nhỏ tiếng nhất. Đoạn cuối toàn im lặng thì bỏ.
   - Mỗi đoạn là một WAV hợp lệ (header đúng độ dài), kèm offset và thời lượng của nó trong bản gốc.
4. Viết client Azure REST short audio:
   - Endpoint `https://{region}.stt.speech.microsoft.com/speech/recognition/conversation/cognitiveservices/v1?language=en-US&format=detailed`.
   - Key qua header `Ocp-Apim-Subscription-Key`, không bao giờ đặt trên URL. Header `Pronunciation-Assessment` là JSON mã hoá base64: `GradingSystem=HundredMark`, `Granularity=Word`, `Dimension=Comprehensive`, `EnableMiscue=false`, `EnableProsodyAssessment=true`, `ReferenceText`.
   - Hai chế độ: scripted (có reference) và unscripted (reference rỗng); thêm chế độ chỉ nhận dạng (không gửi header chấm) để dùng cho cách 2 lượt.
   - Các đoạn của một câu gọi tuần tự. Timeout mỗi lời gọi ≤ 60 giây.
   - Phân loại lỗi: 429 (đọc `Retry-After` nếu có) và 5xx là tạm thời; 400/401/403 là vĩnh viễn. `RecognitionStatus=NoMatch` / `InitialSilenceTimeout` là kết quả điểm thấp hợp lệ. Thông báo lỗi chỉ mang mã phân loại, không chép body của provider.
   - Gộp kết quả: Accuracy theo số từ, Fluency và Prosody theo thời lượng đoạn, transcript và danh sách từ ghép theo thứ tự (offset cộng thêm offset của đoạn). Completeness và pronunciation score để Phase 3 tính sau khi căn với reference.
5. Viết client Gemini gọi REST native với schema output theo từng lời gọi, model đọc từ config (mặc định `gemini-flash-lite-latest`, xác minh alias bằng models list thật), hỗ trợ ảnh inline, timeout <= 60 giây, và phân loại lỗi (429 kèm `retryDelay`, 503, lỗi vĩnh viễn như sai key) thành loại tạm thời hoặc vĩnh viễn. Key gửi qua header `x-goog-api-key`, không bao giờ đặt trên query string, để không lộ trong URL, log HTTP hay exception. Thông báo lỗi chỉ mang mã phân loại, không chép body của provider.
6. Mở rộng cấu hình provider: stub vẫn mặc định, Azure và Gemini cấu hình riêng (key, region, model từ env), bật provider thật mà thiếu key/region/model thì app dừng ngay khi khởi động; giữ nguyên adapter OpenAI-compatible hiện có và validation provider hiện tại.
7. Trước khi chạy spike, báo user số lời gọi Azure, số phút audio và chi phí ước tính (bảng "Chi phí Azure dự kiến" trong `plan.md`, khoảng 20 phút audio). Chờ user đồng ý.
   Chạy spike (user cung cấp key qua env; implementer không đọc `.env`), ghi điểm, thời gian, số lời gọi, số phút audio thực tế và lỗi nếu có vào Execution Log:
   - Một mẫu RA ≤ 28 giây của POC (1 lời gọi). So với điểm POC.
   - Một mẫu RA > 28 giây (ghép 2 mẫu POC nếu không có sẵn), chấm bằng cách A (nguyên bài gốc mỗi đoạn) và cách B (2 lượt, reference từng phần). Ghi cách được chọn cho Phase 3 và lý do.
   - Một mẫu unscripted với `ReferenceText` rỗng: Azure có trả Fluency, Prosody, transcript không. Nếu không thì thử cách 2 lượt (chấm với chính transcript làm reference). Ghi cách được chọn cho Phase 4.
   - Một mẫu SGD khoảng 2 phút, để kiểm số đoạn và thời gian chấm.
   - Một lời gọi Gemini có schema.
   - Kiểm `media` có cấp được ảnh câu hỏi (question bank) dưới tenant của kỳ thi hay không, vì ảnh DI phụ thuộc vào điều này.
   - Chạy ít nhất một lần trong container `app` của docker compose local, để chắc client đọc key từ env và ra mạng được từ trong container.
   - Nếu cả cách A lẫn cách B đều không cho điểm RA hợp lý, dừng và hỏi user trước khi đổi phạm vi.
8. Viết unit test cho chuẩn hoá audio, bộ cắt audio, client Azure với HTTP giả lập, phân loại lỗi, và fail-fast config; xác nhận test hiện có của module scoring vẫn pass.

### Test cho bộ cắt audio
- Audio ≤ 28 giây: 1 đoạn, giữ nguyên.
- Audio 40 giây có khoảng lặng 300 ms ở giây 22: cắt tại giữa khoảng lặng đó.
- Audio 40 giây không có khoảng lặng: cắt tại khung nhỏ tiếng nhất trong cửa sổ 18–28 giây, mọi đoạn ≤ 28 giây.
- Audio 120 giây: mọi đoạn ≤ 28 giây, tổng thời lượng các đoạn bằng bản gốc (trừ đoạn cuối im lặng bị bỏ).
- Mỗi đoạn có header WAV đúng độ dài dữ liệu.

## Success Criteria
- Build thành công, test hiện có của module scoring pass và test mới của phase pass.
- Mẫu RA ≤ 28 giây của POC được Azure REST chấm và trả Accuracy, Fluency, Prosody, transcript; điểm khớp POC.
- Mẫu RA > 28 giây và mẫu SGD được cắt thành các đoạn ≤ 28 giây, mỗi đoạn được chấm, kết quả gộp có đủ chỉ số và transcript liền mạch.
- Execution Log ghi rõ cách chọn cho RA nhiều đoạn (A hoặc B) và cho unscripted (reference rỗng hoặc 2 lượt), kèm số liệu.
- Spike chạy được trong container `app` của docker compose local.
- Một lời gọi Gemini thật trả JSON đúng schema và alias model được xác nhận bằng models list.
- Khởi động app với provider thật nhưng thiếu key/region/model thì lỗi ngay và nêu rõ thiếu gì; khởi động mặc định vẫn dùng stub.
- Audio 44.1 kHz stereo từ app được chuyển thành 16 kHz mono 16-bit và Azure chấp nhận.

## Risks
- REST không hỗ trợ reference rỗng hoặc chấm lệch khi gửi nguyên bài gốc với một đoạn: đã có cách 2 lượt cho từng trường hợp, chỉ tốn thêm lời gọi.
- Ngưỡng khoảng lặng không hợp với bản ghi có tiếng ồn nền: ngưỡng tương đối theo chính bản ghi, kiểm trên bản ghi thật của app.
- Giới hạn tần suất gọi của Azure với SGD nhiều đoạn: các đoạn gọi tuần tự, lỗi 429 đi vào retry của Phase 2.
- Alias model Gemini đổi trỏ theo thời gian: model là config và kết quả ghi lại model thực đã dùng.

## Execution Log

### Errors Encountered
- Spike: cột Completeness của Azure gần như luôn 100 với mọi mẫu RA, kể cả mẫu đọc sai nhiều (Ver2), nên không dùng được để so với POC.
- Spike: cách A (gửi nguyên bài gốc kèm từng đoạn audio) cho Accuracy ~54 ở cả ba mẫu Ver1, Ver2, Ver3, tức là không phân biệt được bài tốt và bài kém.
- Lúc kiểm env trong container: safety check của Claude Code chặn lệnh `docker compose exec app sh -c '... eval ...'`.
- Code review (code-reviewer: APPROVED 8,5/10, 0 CRITICAL, 0 HIGH, 3 MEDIUM, 4 LOW) chỉ ra:
  - `AudioNormalizer` không giới hạn độ dài bản ghi. File WAV dài vẫn được giải mã hết vào bộ nhớ, trong khi heap trên VPS chỉ ~358 MiB.
  - `VendorHttp.send` không chặn được body bị treo sau khi header đã về. Test mới cho thấy lời gọi chờ đủ 3 s dù timeout là 300 ms.
  - Key có khoảng trắng hoặc xuống dòng (dán nhầm) vẫn qua kiểm tra lúc khởi động, đến khi chấm từng câu mới lộ ra thành 401.
  - `SilenceChunker`: bản ghi gần như toàn số 0 làm ngưỡng im lặng bằng 0, nên không frame nào được coi là im lặng.
  - Offset của từ được dời theo cả bản ghi, còn offset của segment vẫn tính theo từng đoạn, mà code không ghi chú điều này.
  - Retry hint của vendor chưa bị chặn trần, và `isTransient()` chưa có chỗ nào dùng.

### Root Cause
- Với `EnableMiscue=false`, Azure ép chuỗi lexical theo reference, nên Completeness không phản ánh số từ thật sự được đọc.
- Mỗi đoạn chỉ đọc một phần bài, nhưng Azure chấm đoạn đó với cả bài gốc, nên phần không đọc bị tính là đọc sai và kéo Accuracy của mọi mẫu về cùng một mức.
- Lệnh có `eval` bị safety check coi là rủi ro, dù chỉ dùng để đọc độ dài biến môi trường.
- Code review:
  - Trên JDK 21, `HttpRequest.timeout` chỉ tính đến lúc nhận header, không tính phần body.
  - `AudioNormalizer` chỉ chặn header khai khống độ dài, không chặn độ dài thật.
  - Kiểm tra key chỉ xét `isBlank`.
  - Ngưỡng im lặng chỉ tương đối theo mức âm của chính bản ghi.

### Resolution
- Bỏ cột Completeness của Azure khỏi spike. Phase 3 tính Completeness bằng cách căn transcript lượt 1 (chỉ nhận dạng) với reference (đã ghi vào phase-03).
- Chọn cách B cho RA nhiều đoạn: nhận dạng từng đoạn, cắt reference theo LCS với transcript, rồi chấm mỗi đoạn với phần reference của nó. Hiện cách B nằm trong `perChunkReference` của spike test. Phase 3 đưa nó vào `AzureSpeechAssessor` (đã ghi vào phase-03 bước 3).
- Viết lại thành các lệnh đơn `printenv VAR | wc -c` và `java --list-modules`, không dùng `eval`. Không in giá trị key.
- Bước simplify (ck-cook 3.S), đã sửa:
  - `VendorHttp` có thêm `httpFailure(vendor, response)` và `readJson`, dùng chung cho Azure và Gemini. Khi đọc JSON lỗi, cause bị bỏ để body của provider không lọt vào exception.
  - Constructor HTTP/transport của `AiProviderException` giờ là package-private, chỉ `VendorHttp` tạo được.
  - `SpeechAssessment` tự suy ra transcript và cờ có tiếng nói từ danh sách đoạn. `AzureSpeechAssessor` có `prepare(audio)`, nên mỗi file chỉ chuẩn hoá và cắt một lần cho cả hai lượt.
  - `AudioNormalizer` đọc audio theo khối 64 KB, gộp kênh ngay khi đọc, và giới hạn số frame theo kích thước file. Không còn nhánh riêng cho 16 kHz mono.
  - `WavEncoder` ghi samples hàng loạt. Gemini gửi ảnh qua `Map.of` (Jackson tự mã hoá base64).
  - Thêm comment về timeout trong `application.yml` và `VendorHttpTest` cho phân loại status. Test của Azure/Gemini gọn lại.
- Bước simplify, đã bỏ qua kèm lý do:
  - Resampler polyphase: viết lại quá lớn so với lợi ích (~1 giây CPU cho 3 phút audio).
  - Bean Validation cho config: đổi kiểu exception lúc khởi động.
  - Dùng chung `read-timeout-ms`: timeout riêng cho mỗi vendor là có chủ đích.
  - Thu hẹp `classifyStatus`/`retryAfterHeader`: Gemini ở package khác vẫn cần.
  - Vài điểm nhỏ: bỏ `PcmAudio.sampleRate`, SpEL của stub, dựng header PA một lần mỗi câu, `List.copyOf` trong `RecordingHttpServer`.
- Sửa theo code review (TDD: viết 4 test trước, cả 4 fail đúng lý do rồi mới sửa code):
  - Thêm `AiFailureReason.AUDIO_TOO_LONG` (lỗi vĩnh viễn). `AudioNormalizer` từ chối bản ghi dài hơn 180 s trước khi giải mã.
  - `VendorHttp.send` dùng `sendAsync` và chờ kết quả với cùng timeout. Quá hạn thì huỷ request và trả `PROVIDER_TIMEOUT`. `RecordingHttpServer` có thêm `enqueueStalledBody` để test trường hợp này.
  - Key Azure và Gemini phải gồm toàn ký tự ASCII nhìn thấy được (`\p{Graph}+`). Sai thì khởi động fail, thông báo nêu tên biến nhưng không in giá trị.
  - `SilenceChunker` có ngưỡng im lặng tối thiểu 1.0, nên im lặng số (toàn số 0) luôn được coi là im lặng.
  - Thêm ghi chú trong `SpeechAssessment` về offset của từ và của segment.
- Code review, để sang Phase 2: chặn trần retry hint theo ngân sách thời gian của job, và dùng `isTransient()`/`getRetryAfter()` trong worker. Đã ghi rõ vào bước 5 của phase-02.

### Test Results After Fix
- `./mvnw -q -pl app test -Dtest='com.pte.scoring.**' -Dsurefire.failIfNoSpecifiedTests=false` (JDK ms-21.0.12, sau bước simplify), theo surefire reports:
  - 260 test, 0 failure, 0 error, 4 skipped. 4 test skipped đều là `AzureGeminiSpikeTest`, chỉ chạy khi có `SCORING_AI_SPIKE=true`.
  - Phase này thêm 87 test: `AiProviderExceptionTest` 12, `VendorHttpTest` 10, `AudioNormalizerTest` 7, `SilenceChunkerTest` 8, `AzureSpeechRestClientTest` 15, `SpeechAggregatorTest` 8, `AzureSpeechAssessorTest` 5, `GeminiRestClientTest` 15, `AzureGeminiProviderConfigTest` 7.
- Cùng lệnh, sau khi sửa theo code review: 265 test, 0 failure, 0 error, 4 skipped (vẫn là spike test).
  - Thêm 5 test: `VendorHttpTest` +1 (body treo, timeout sau 0,32 s), `AudioNormalizerTest` +1, `SilenceChunkerTest` +1, `AzureGeminiProviderConfigTest` +1, `AiProviderExceptionTest` +1 (case cho enum mới).
  - Phase 1 có tổng cộng 92 test.

### Spike Results
Spike chạy bằng `AzureGeminiSpikeTest`, mỗi lần một method, trong container `maven:3.9-eclipse-temurin-21`. Container lấy key từ env file của pte-api qua compose, implementer không đọc file đó. Lệnh chạy: `docker compose -f spike.compose.yml --project-directory <pte-api> run --rm -e SPIKE_TEST='AzureGeminiSpikeTest#<method>' ai-spike`. Mẫu lấy từ `ai-research/samples`, đổi sang WAV.

Chuẩn hoá audio: mọi mẫu nguồn đều là 44,1 kHz stereo, được chuyển về 16 kHz mono 16-bit, và Azure nhận tất cả.

| Mẫu | Thời lượng | Các đoạn (offset+độ dài, ms) |
|---|---|---|
| Ver1 (RA) | 34,2 s | 0+18850, 18850+15325 |
| Ver2 (RA) | 38,3 s | 0+23900, 23900+14435 |
| Ver3 (RA) | 33,8 s | 0+21660, 21660+12174 |
| describe_good (unscripted) | 39,3 s | 0+21140, 21140+18125 |
| lecture_source (thay SGD) | 98,6 s | 4 đoạn: 0+21800, 21800+24650, 46450+25560, 72010+26590 |

**RA nhiều đoạn: chọn cách B**

| Mẫu | Cách A Accuracy | Cách B Accuracy / Fluency / Prosody | Thời gian cách B |
|---|---|---|---|
| Ver1 | ~54 | 96,9 / 91,6 / 82,0 | 14–17 s |
| Ver2 | ~54 | 71,2 / 61,8 / 42,3 | 14–17 s |
| Ver3 | ~54 | 78,5 / 83,4 / 55,7 | 14–17 s |

Cách B xếp hạng Ver1 > Ver3 > Ver2 ở cả ba chỉ số, khớp thứ hạng của POC. Cách A không phân biệt được các mẫu nên bị loại.

**Unscripted: chọn reference rỗng**

| Cách | Accuracy / Fluency / Prosody | Thời gian |
|---|---|---|
| Reference rỗng (1 lượt) | 94,2 / 89,0 / 90,4 | 12,4 s |
| 2 lượt (transcript làm reference) | 96,8 / 89,5 / 90,4 | 17,5 s |

Với reference rỗng, Azure vẫn trả Fluency, Prosody và transcript. Kết quả gần như bằng cách 2 lượt mà chỉ tốn một nửa số lời gọi, nên Phase 4 dùng reference rỗng. Fluency đang lệch POC khoảng 10 điểm; sẽ hiệu chỉnh khi so mẫu ở Phase 4.

**SGD (dùng lecture_source thay thế):** 98,6 s audio, cắt 4 đoạn, mọi đoạn ≤ 28 s, gọi tuần tự hết 31,6 s. Kết quả gộp có đủ chỉ số và transcript liền mạch.

**Gemini:**
- Models list trả HTTP 200 và có alias `gemini-flash-lite-latest`. Alias này hiện trỏ tới `gemini-3.5-flash-lite`.
- Lời gọi có schema mất 1459 ms và trả JSON đúng schema.

**Trong container `app`** (compose local của user, provider `azure-gemini`):
- App khởi động qua được fail-fast config. Kiểm biến key chỉ bằng độ dài.
- Có module `java.desktop` (cần cho `javax.sound`).
- Gọi thử Azure từ container: HTTP 200. Gọi Gemini: HTTP 200, 0,362 s.

**Ảnh DI:** không có vấn đề. Lúc thí sinh làm bài, `SnapshotPinService` đã lấy ảnh câu hỏi theo tenant của kỳ thi. Ảnh dùng chung của hệ thống được cấp cho mọi tenant, còn ảnh của tenant chỉ tenant đó lấy được. Bước chấm sẽ dùng lại cách này với tenant của bài thi.

**Chi phí thực tế:**
- Azure: 29 lời gọi, khoảng 9,0 phút audio, khoảng $0,15–0,20. Dự toán là ~20 phút, ~$0,45.
- Gemini: 3 request.

**Sai khác so với plan:**
- Không có mẫu RA ≤ 28 s: các mẫu RA của POC đều 34–38 s, nên mỗi mẫu cắt 2 đoạn. Không còn spike riêng cho trường hợp 1 lời gọi; trường hợp này được unit test che.
- Thiếu mẫu RS, ASQ, SGD, RTS trong `ai-research/samples`: dùng lecture_source thay cho SGD. Các dạng còn lại kiểm ở Phase 3, 4 và 6.
- Spike chạy trong container maven riêng. Container `app` chỉ dùng để kiểm khởi động, env, module và mạng ra (curl tới Azure và Gemini).
- Chưa thử bản ghi thật từ pte-app. Mẫu POC cũng là 44,1 kHz stereo nên đã che phần định dạng; bản ghi thật để lại cho Phase 6.
