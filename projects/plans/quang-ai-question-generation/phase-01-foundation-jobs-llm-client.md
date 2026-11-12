# Phase 1: Nền tảng (config, client 9router, V34, job + worker, API)

> **Đã điều chỉnh theo red-team** (xem bảng trong plan.md). Nếu có chỗ nào bên dưới mâu thuẫn, bảng red-team thắng:
> bảng `question_generation_job_items` thay cho `items_json`; claim bằng lease và gọi ngoài transaction; trạng thái `CANCELLING`;
> partial unique index cho "1 job mỗi người"; trần toàn cục; `content_hash` và `(job_public_id, item_index)` trên `questions`;
> kiểm tra lại quyền admin khi tiếp tục job; allowlist `topicHint`; tổng ngân sách gọi mỗi câu và circuit breaker;
> stub chỉ ở profile test/local; https và không follow redirect.

## Design Constraints
- Ratchet: file tối đa 300 dòng, mỗi `internal/**` tối đa 15 class, dùng `Clock` được inject, thông điệp và mã lỗi trong `QuestionGenerationConstants`.
- Chỉ gọi API public của module khác (`MediaService`, `com.pte.scoring.rubric`); chạy `ModuleStructureTest`.
- Envelope và mã lỗi theo `API_RESPONSE_SETUP.md` và `COMMON_EXCEPTION_SETUP.md`.

## Quality and Testing State
- Chưa cook. Cần: unit test như mục Test bên dưới, các ratchet kiến trúc xanh, `ApiInventoryExportTest` cập nhật.
- Test race: 2 submit đồng thời của cùng một người chỉ có 1 thành công.

## Mục tiêu
Một job tạo đề chạy được end-to-end: API nhận yêu cầu, worker nhận job, gọi generator (ở phase này dùng `StubItemGenerator`), ghi kết quả từng câu.
Chưa có prompt thật.

## Thay đổi

### Config (`itembank/internal/generation/config`)
- `QuestionGenerationProperties` (`@ConfigurationProperties("itembank.generation")`):
  - `enabled` (mặc định `false`)
  - `llm.baseUrl`, `llm.apiKey`, `llm.generatorModel`, `llm.reviewerModel`, `llm.timeout` (90s), `llm.maxTokens`
  - `kokoro.baseUrl`, `kokoro.apiKey`, `kokoro.timeout` (60s)
  - `limits.maxItemsPerJob` (10), `limits.maxItemsPerDay` (100), `limits.staleRunningAfter` (10m)
  - `worker.pollDelayMs` (3000)
- `application.yml` map sang env `QUESTION_GEN_BASE_URL`, `QUESTION_GEN_API_KEY`, `QUESTION_GEN_GENERATOR_MODEL`,
  `QUESTION_GEN_REVIEWER_MODEL`, `KOKORO_BASE_URL`, `KOKORO_API_KEY`. Hai biến model mặc định là `Capstone`.
- Validator lúc khởi động: nếu `enabled=true` mà thiếu `baseUrl` hoặc `apiKey` thì fail fast. Thông điệp không chứa giá trị secret.
- `.env.example` của pte-api thêm tên biến, giá trị để trống.

### Client LLM (`.../generation/llm`)
- `LlmGateway` (interface): `String completeJson(LlmRole role, String system, String user)`. `LlmRole` có 2 giá trị `GENERATOR` và `REVIEWER`,
  mỗi vai có model và temperature riêng (generator 0.8, reviewer 0).
- `NineRouterLlmGateway`: dùng `RestClient` gọi `POST {baseUrl}/chat/completions` với `response_format: {type: json_object}`
  và Bearer key. Lấy `choices[0].message.content`.
- Phân loại lỗi:
  - 401/403 → `GENERATION_PROVIDER_AUTH`
  - 429/5xx/timeout → `GENERATION_PROVIDER_UNAVAILABLE`, retry 1 lần sau 2 giây
  - nội dung rỗng → `GENERATION_EMPTY_RESPONSE`
- Log: chỉ ghi role, model, thời gian, token usage (nếu có) và mã lỗi. **Không** log prompt, response hay key.
- **Không** import bất cứ thứ gì từ `scoring.internal`.

### Migration `V34__question_generation_jobs.sql`
```sql
CREATE TABLE question_generation_jobs (
  id BIGSERIAL PRIMARY KEY,
  public_id UUID NOT NULL UNIQUE,
  requested_by_user_public_id UUID NOT NULL,
  task_type_key VARCHAR(64) NOT NULL,
  cefr_level VARCHAR(2) NOT NULL,
  pool VARCHAR(16) NOT NULL,
  topic_hint VARCHAR(200),
  requested_count INT NOT NULL CHECK (requested_count BETWEEN 1 AND 10),
  status VARCHAR(16) NOT NULL,             -- QUEUED|RUNNING|COMPLETED|FAILED|CANCELLED
  succeeded_count INT NOT NULL DEFAULT 0,
  failed_count INT NOT NULL DEFAULT 0,
  items_json JSONB NOT NULL DEFAULT '[]',  -- [{index, stage, questionPublicId?, failureCode?, failureNote?}]
                                           -- stage: QUEUED|GENERATING|VALIDATING|REVIEWING|RENDERING_MEDIA|SAVED|FAILED (cho StepTimeline ở phase 4)
  heartbeat_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL, started_at TIMESTAMPTZ, finished_at TIMESTAMPTZ,
  version BIGINT NOT NULL DEFAULT 0
);
CREATE INDEX ix_qgen_jobs_status ON question_generation_jobs(status, created_at);
CREATE INDEX ix_qgen_jobs_requester ON question_generation_jobs(requested_by_user_public_id, created_at DESC);
ALTER TABLE questions ADD COLUMN generation_meta JSONB;
```
- Thêm entity `QuestionGenerationJob` và field `generationMeta` (kiểu `String`, JSONB) vào `Question`, đi qua `ddl-auto: validate`.
- Local `local-schema`: phải apply V34 bằng psql (xem memory "restart docker after backend").

### Job service + worker (`.../generation/job`)
- `QuestionGenerationJobService.submit(request, caller)`:
  - kiểm tra `enabled`, task type thuộc danh sách hỗ trợ (`SupportedGenerationTaskTypes`), count, trần mỗi ngày,
    và không có job QUEUED hoặc RUNNING khác của cùng người;
  - lưu job `QUEUED`, trả về DTO.
- `QuestionGenerationWorker`:
  - `@Scheduled(fixedDelayString=...)`, nhận 1 job bằng `SELECT ... WHERE status='QUEUED' OR (status='RUNNING' AND heartbeat_at < now-stale) ORDER BY created_at LIMIT 1 FOR UPDATE SKIP LOCKED`;
  - chạy các câu chưa xong theo thứ tự. **Mỗi câu chạy trong transaction riêng**: ghi kết quả câu, tăng counter, cập nhật heartbeat;
  - kiểm tra trạng thái `CANCELLED` trước mỗi câu;
  - kết thúc với `COMPLETED` nếu có ít nhất 1 câu thành công, ngược lại `FAILED`.
- `GenerationPipeline.runItem(job, index)`: phase này gọi `ItemGenerator` (interface) rồi map sang `CreateQuestionRequest`,
  sau đó `ItembankService.create(..., caller)`. Caller được dựng lại từ `requested_by_user_public_id` với vai PLATFORM_ADMIN và `tenantId=null`.
  Kiểm tra cách dựng `CurrentUser` cho tác vụ hệ thống mà các worker hiện có đang dùng.
- `StubItemGenerator` (`@Profile("test")` hoặc `itembank.generation.stub=true`) trả về một câu MC_READING_SINGLE hợp lệ.

### API (`.../generation/controller`, `@PreAuthorize("hasRole('PLATFORM_ADMIN')")`)
| Method | Path | Body / kết quả |
|---|---|---|
| POST | `/api/v1/question-generation/jobs` | `{taskType, cefrLevel, pool: PRACTICE|EXAM, topicHint?, count}` → 202 `ApiResponse<GenerationJobResponse>` |
| GET | `/api/v1/question-generation/jobs/{publicId}` | job + items (chỉ người tạo hoặc PLATFORM_ADMIN) |
| GET | `/api/v1/question-generation/jobs?page&size` | job của tôi, mới nhất trước |
| PATCH | `/api/v1/question-generation/jobs/{publicId}/status` | `{action: "CANCEL"}`. Theo quy ước `PATCH .../status` |
| GET | `/api/v1/question-generation/task-types` | các dạng đang hỗ trợ kèm `section`, `needsAudio`, `needsImage`, `estimatedSecondsPerItem` |
| GET | `/api/v1/question-generation/quota` | `{usedToday, dailyLimit}` để FE cảnh báo trước khi submit |

- Mã lỗi và thông điệp đặt trong `QuestionGenerationConstants`:
  `GENERATION_DISABLED`, `GENERATION_TASK_TYPE_UNSUPPORTED`, `GENERATION_COUNT_OUT_OF_RANGE`, `GENERATION_DAILY_LIMIT_REACHED`,
  `GENERATION_JOB_ALREADY_RUNNING`, `GENERATION_JOB_NOT_FOUND`, `GENERATION_JOB_NOT_CANCELLABLE`.
  Ánh xạ theo `COMMON_EXCEPTION_SETUP.md`.

## Test
- `NineRouterLlmGatewayTest` (MockRestServiceServer): request đúng model, đúng header, đúng `response_format`; phân loại 401/429/500/timeout; không log nội dung.
- `QuestionGenerationJobServiceTest`: các luật submit (giới hạn, trùng job, task type không hỗ trợ, `enabled=false`).
- `QuestionGenerationWorkerTest` với stub và `Clock` cố định: câu thành công, câu thất bại, cancel giữa chừng, nhận lại job bị treo.
- Controller test: 403 với role khác, 202 và shape của envelope.
- `ApiInventoryExportTest`: cập nhật số endpoint (+5).

## Done khi
- `mvnw -pl app -DskipTests compile` xanh. Test mới và các ratchet kiến trúc xanh.
- Local: tạo job với stub thì sinh ra 1 câu DRAFT xem được trong question bank.
