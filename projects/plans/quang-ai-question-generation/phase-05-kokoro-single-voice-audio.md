# Phase 5: Upload phía server + Kokoro, các dạng một giọng (P2)

## Mục tiêu
10 dạng có audio: WFD, RS, ASQ, SST, MC_LISTENING_SINGLE/MULTIPLE, HCS, SMW, HIW, L-FIB, RE_TELL_LECTURE.

## Media: upload phía server (module `media`)
- Thêm API public `MediaService.storeGenerated(byte[] bytes, String contentType, String assetKind, CurrentUser owner)`, trả về `UUID mediaPublicId`.
  - Upload lên Cloudinary bằng signed upload phía server (dùng lại `CloudinaryRequestSigner`), `resource_type=video` cho audio
    và `image` cho ảnh, đúng như asset do trình duyệt upload.
  - Tạo `MediaAsset` ở trạng thái đã hoàn tất, lưu duration nếu Cloudinary trả về.
  - Asset được `validateAuthoringMedia` chấp nhận như asset upload từ trình duyệt.
- Giới hạn kích thước (10 MB), mã lỗi đặt trong `MediaConstants`.

## Kokoro (`.../generation/media`)
- `KokoroSpeechClient`: `POST {kokoroBaseUrl}/v1/audio/speech`, body `{model:"kokoro", input, voice, speed, response_format:"wav"}`, Bearer key.
  - Dùng WAV để phase 6 ghép được. Một giọng thì cũng upload WAV; Cloudinary phát qua `f_mp3` khi delivery (kiểm tra lại
    `presignGet` có hỗ trợ transformation hay không, nếu không thì yêu cầu `mp3` cho dạng một giọng).
  - Khi khởi động (nếu `enabled`): gọi `GET /v1/audio/voices` một lần, log số giọng có sẵn, không làm fail app.
- `VoicePicker`: danh sách giọng trong config, mặc định chỉ dùng giọng hạng A/B: Mỹ `af_heart`, `af_bella`, `am_michael`...;
  Anh `bf_emma`, `bm_george`... (xác nhận lại với `/v1/audio/voices` khi code). Chọn ngẫu nhiên, nhưng xen kẽ Mỹ và Anh trong cùng một job.
- Tốc độ: 1.0. RS và WFD dùng 0.95.
- `AudioDurationProbe`: đọc header WAV để tính thời lượng. Nếu nằm ngoài khoảng của dạng bài thì đọc lại một lần với tốc độ ±0.1,
  vẫn lệch thì fail `GENERATION_AUDIO_DURATION_OUT_OF_RANGE`.

| Dạng | Khoảng transcript | Khoảng thời lượng |
|---|---|---|
| WFD | 8–14 từ | 3–8 giây |
| RS | 8–15 từ | 3–9 giây |
| ASQ | câu hỏi 6–20 từ | 2–8 giây |
| SST, RL | 120–200 từ | 50–95 giây |
| MC_L, HCS, SMW, HIW, L-FIB | 60–160 từ | 25–75 giây |

## Generator/validator cho dạng có audio
- Hình dạng mới: `ListeningDraft(topic, transcript, ...phần câu hỏi dùng lại ChoiceDraft/BlankFillDraft)` và
  `HiwDraft(topic, transcript, displayedText, changedIndexes[])`.
- Luật validator:
  - L-FIB: mỗi ô trống là một từ có trong transcript, đúng vị trí.
  - HIW: `displayedText` và `transcript` có cùng số từ; khác nhau đúng ở `changedIndexes` (4–7 từ); từ thay khác từ gốc
    về chính tả và khác 2 ký tự đầu (tránh trùng âm).
  - SMW: phần cuối transcript bị bỏ đi chính là đáp án đúng.
  - ASQ: đáp án 1–3 từ.
  - Chung: không có chữ số (số phải viết bằng chữ), không có từ viết tắt viết hoa.
- Reviewer duyệt **transcript** trước. Kokoro chỉ chạy khi đã PASS.
- Mapper: `audioPromptRef` = media id; transcript lưu vào `referenceAnswerText` hoặc trường transcript hiện có
  (kiểm tra trường mà runtime và AI scorer đang đọc cho SST và RL); `generation_meta.media` = `{voice, speed, durationSec}`.

## Test
- `KokoroSpeechClientTest` (mock server): body, header, phân loại lỗi.
- `AudioDurationProbeTest` với WAV mẫu tự sinh trong test.
- `VoicePickerTest`: xen kẽ giọng, ổn định khi dùng seed.
- Validator test cho HIW, L-FIB, SMW, ASQ.
- `MediaServiceStoreGeneratedTest`: chữ ký và trạng thái asset (mock Cloudinary).
- Smoke thủ công `QUESTION_GEN_SMOKE` thêm 1 câu WFD và 1 câu SST.

## Done khi
Câu WFD, SST và HIW sinh ra phát được audio trong preview của vendor-web và trong pte-app.

## Design Constraints
- Giữ các ratchet (300 dòng/file, 15 class/package `internal`, `Clock`, constants) và áp dụng các quyết định red-team của phase này trong plan.md.

## Quality and Testing State
- Implementation: tests written, not run (user chose to save tokens).
- test-compile: SUCCESS (2026-11-07).
- Quality gate: skipped by user.

## Implementation Status (2026-11-07)
- **Media module**: `MediaService.storeGenerated` + `CloudinaryGeneratedUploader` implement server-side Cloudinary upload
- **Kokoro client**: `KokoroSpeechClient` with POST /v1/audio/speech, Bearer auth, error classification
- **Audio probing**: `AudioDurationProbe` parses WAV headers; `VoicePicker` alternates US/UK voices per item, seed-stable
- **Drafts**: `ListeningDraft` and `HiwDraft` sealed interfaces added to `ItemDraft`
- **Validators**: `AudioCommonValidator`, `HiwValidator`, `ListenFibValidator`, `AudioTypeValidators` (ASQ, WFD, RS, SST, SMW, HCS, RL)
- **DraftParser**: updated to parse 11 audio task types + ListeningDraft, HiwDraft
- **Prompts**: 11 audio type prompts created (WFD, RS, ASQ, SST, MC_L_SINGLE/MULTIPLE, HCS, SMW, HIW, L-FIB, RL)
- **PromptRegistry**: updated to load all 19 prompts (8 text + 11 audio)
- **Tests**: 3 unit test files written (KokoroSpeechClientTest, AudioDurationProbeTest, VoicePickerTest); existing media tests fixed

## Quyết định đã chốt (red-team H7, H8)
- Transcript lưu trong `reference_answer_text` theo bảng ánh xạ trong plan.md ("Quyết định đã chốt: transcript"); không thêm cột mới, không lưu transcript trong `generation_meta`.
- Test bắt buộc: payload thí sinh qua `AttemptMapper` và kết quả practice không chứa transcript; mapper ghi đúng cột cho từng dạng.
- Audio dùng WAV nguyên bản, giới hạn `MAX_AUTHORING_BYTES`.

## Unverified (deferred for phase 6+)
- Pipeline integration (Reviewer runs transcript draft, Kokoro synthesis, storeGenerated, question creation)
- DraftToQuestionMapper extensions for all 11 audio types
- Review prompt updates for audio types
- Multiple-voice dialogue (phase 6)
- Full end-to-end generation smoke test with real Kokoro
