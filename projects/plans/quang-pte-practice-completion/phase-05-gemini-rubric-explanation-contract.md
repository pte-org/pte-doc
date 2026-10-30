# Phase 05: Gemini provider độc lập và explanation theo rubric

Status: planned. Dependencies: 02,04; D05 VI/EN và D06 feedback-first đã xác nhận; D08 data handling trước live processing. Stories: US-04, US-06, US-09. Requirements: PR-05,08,09,11,12.

## Work packages

1. Tách capability/config practice khỏi `AzureGeminiProviderConfig`. `GeminiRestClient` hiện ở `scoring.internal.vendor.gemini` không là public module contract. Chọn seam public do owning module sở hữu hoặc provider adapter chung đúng kiến trúc; practice không import internals. Exam provider giữ nguyên lựa chọn, Practice Gemini hoạt động được khi exam không dùng azure-gemini; không bắt Azure key để giải thích practice.
2. Dùng credential đã có tại backend: env `GEMINI_API_KEY` → Compose `SCORING_AI_GEMINI_API_KEY` theo mapping hiện tại. Java direct run không tự áp Compose interpolation: document explicit property/env mapping tới secret source; không copy giá trị vào source. Thêm practice enable/model/timeout/schema/prompt/budget settings theo standards; validate nonempty khi enabled, disabled an toàn. Không in secret qua diagnostic command/log/frontend bundle.
3. Input template gồm task ID, pinned question/reference/rubric, submitted answer/evidence, deterministic objective result và language. Instruction tách rõ untrusted answer/source khỏi rubric/instruction; không tools, browsing, arbitrary URL fetch hoặc secret context. Không gửi PII không cần thiết. Source explanation và curated examples học thuật có provenance, không coi chúng là output personalized đã chạy.
4. Structured output đề xuất: schemaVersion, language, taskId, summary, criteria[{criterionId, applicability, level, evidenceRefs, explanation, improvement}], verifiedObjectiveExplanation, nextPracticeHints, limitations. Evidence có source ID và text offset/quote hoặc audio time range đã kiểm chứng. D05 đã chọn VI mặc định/EN option và lưu variants riêng; đổi UI locale không tự regenerate. D06 đã chọn nhận xét rubric trước: numeric field Writing/Speaking không xuất trong initial release, chỉ capability sau calibration/sign-off.
5. Validator hai tầng: JSON/schema và semantic. Chặn criterion/reference ID lạ, invalid offsets/quotes, invented audio evidence, objective contradiction, confidence biến thành score, missing required applicability và unsupported task. Invalid response không được available; có bounded corrective attempt trong tổng budget nếu policy cho phép, không loop sửa prompt vô hạn.
6. Writing nhận xét task-specific content/organization/language bằng quote thật. Speaking: text content feedback chỉ khi transcript đủ tin cậy; pronunciation/fluency cần direct audio/assessor evidence đã kiểm định. Native Gemini request hiện text/image chưa chứng minh audio support; nếu thêm audio, kiểm tra API/model limits, MIME/size/upload lifecycle, privacy và evaluate corpus trước bật. Transcript-only phải limited/NA, không dựng nhận xét phát âm. Personal Introduction chỉ coaching nếu academic duyệt, unscored.
7. Lưu provenance: requested model, actual provider modelVersion khi có, prompt/schema/rubric/reference/evaluator versions, config hash, finish/validation classification và latency/usage metadata không chứa raw bài nhạy cảm. Actual version unavailable ghi unavailable, không đoán. Model alias/temperature không là lời hứa same output khi gọi mới; consistency của Student reads do persisted result ở phase 06.
8. Prompt input dùng frozen derived transcript/audio-assessment artifact revision/hash và assessor policy/version/config từ phase 04. Evidence chưa sẵn sàng giữ `WAITING_EVIDENCE`, không gọi lại model trên input đang thay đổi. Retry cùng request dùng cùng artifacts; không silently re-ASR để có transcript khác.

## Proposed files

`scoring/internal/vendor/gemini/{GeminiRestClient,GeminiRequest,GeminiResponse}.java`, `scoring/internal/config/{AzureGeminiProviderConfig,AiProviderConfig}.java` chỉ sửa theo owned seam; proposed practice explanation public provider interface, immutable prompt/schema resources và validator/service. Config trong app application properties, `.env.example` chỉ names/placeholders, Compose mapping hiện tại. Không sửa real secret values.

## Failure paths / tests to consider

Disabled/missing key, invalid credential/model, timeout/429/5xx, truncated/empty output, malformed JSON/schema, forged evidence/criterion, injected instruction trong answer/reference, unavailable actual version, unsupported audio/model, objective contradiction. Unit/provider fake và synthetic live checks là đề xuất; không gọi Gemini trong plan.

## Design Constraints

Gemini không quyết định objective correctness. Rubric approved/pinned mới được gửi; numeric AI release cần calibration. Không guarantee alias consistency hoặc actual model pin nếu provider không hỗ trợ. Check official provider docs theo model thực tế lúc implement, không hardcode sampling advice từ model khác.

## Exit criteria

Provider config không phụ thuộc exam Azure; request/schema/evidence validator có fixtures; output chất lượng chưa được tuyên bố chỉ nhờ JSON valid. Secret không ra browser/log; audio capabilities hiển thị giới hạn thật.

## Quality and Testing State

Quality: not evaluated. Testing: not started. TDD chưa chọn. Cook xác nhận optional tests/quality; live synthetic smoke thuộc phase 08 và phải có approved data/budget trước chạy.
