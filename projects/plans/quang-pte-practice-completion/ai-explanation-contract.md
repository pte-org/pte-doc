# Hợp đồng đề xuất: giải thích Gemini nhất quán và có bằng chứng

Date: 2026-10-22. Status: Proposed design, chưa triển khai.
Read with [spec.md](spec.md) và [rubric-and-task-matrix.md](rubric-and-task-matrix.md).

## 1. Ba loại “nhất quán” cần phân biệt

| Loại | Cách bảo đảm | Giới hạn |
|---|---|---|
| Mở lại cùng bài thấy cùng lời giải | Đọc explanation bất biến đã lưu, không gọi Gemini bằng GET | Không phụ thuộc khả năng model tái tạo từng chữ |
| Cùng câu/rubric có cùng đáp án chuẩn | Pinned answer key/reference + evaluator xác định; AI không sửa kết quả | Lỗi ngân hàng học liệu vẫn cần academic review |
| Các bài khác nhau được nhận xét công bằng | Rubric version, anchored examples, output validation, corpus kiểm định trước thay model/prompt | Không có lời hứa model luôn đúng hoặc tuyệt đối ổn định |

Tách correctness, criterion assessment và lời khuyên học tập. Viết câu giải thích khác nhau không tự động là lỗi; mâu thuẫn đáp án, bỏ tiêu chí, hoặc thay kết luận không có bằng chứng là lỗi chất lượng.

## 2. Snapshot và quyền

Khi tạo/begin phiên, transaction pin đủ question revision, source/reference revision, rubric revision, task/runtime/scoring policy và media manifest. Phần delivery chỉ có prompt và dữ liệu làm bài; phần evaluation chứa keys và rubric/reference bị hạn chế truy cập. Nếu revision không có immutable storage thì copy đủ dữ liệu vào snapshot server, không chỉ giữ một UUID trỏ record có thể sửa.

Khi submit, khóa câu trả lời và media IDs/content hashes, confidence và thời điểm nhận. Confidence là tự đánh giá của Student, không gửi vào AI để gây thiên lệch hoặc dùng làm điểm. Không thay answer payload khi retry AI. Một lần làm lại câu tạo bản nộp mới.

Proposed reads/mutations phải áp dụng owner + organization context từ token/session, không tin `organizationId`, `studentId`, `rubricId` hoặc model do browser gửi. Session public UUID không là quyền. Không trả keys qua HTML, hydration props, logs hoặc API ẩn trước submit. Nếu nhóm luyện cho phép feedback từng item thì chỉ item đã nộp mới được reveal; chưa nộp vẫn ẩn.

History/result GET sau hết gói vẫn đọc dữ liệu đã sở hữu theo policy được duyệt; POST mới/retry/regenerate kiểm tra entitlement và budget. Account bị xóa/đình chỉ truy cập có policy riêng, không suy từ expiry gói. Worker chạy job đã được chấp nhận theo snapshot quyền ghi nhận; thao tác xóa dữ liệu/incident có thể cancel job.

## 3. Identity và lưu trữ

Một logical evaluation key gồm:

```text
owner_public_id + organization_context_id
+ session_item_id + immutable_submission_revision
+ canonical_answer_hash + response_media_hashes
+ derived_evidence_bundle_hash + transcript_revision + assessor_policy_version
+ question_revision + reference_revision
+ rubric_version + rubric_hash
+ deterministic_evaluator_version + deterministic_result_hash
+ prompt_version + response_schema_version
+ model_policy_version + requested_model_id + generation_config_hash
+ explanation_language
```

Canonical JSON có serialization rõ; sort set-valued choices, giữ nguyên thứ tự reorder/blank/token/text/audio references. Không normalize câu trả lời trước khi lưu raw evidence; evaluator có normalization policy riêng. Hash chỉ là identity/integrity, không thay quyền, không xuất hash có thể dò dữ liệu nhạy cảm ra public.

Unique DB constraint trên key là nguồn chống trùng. `Idempotency-Key` chỉ thêm lớp retry HTTP: cùng body/key trả trạng thái cũ; cùng key khác body trả conflict; khác key cùng logical evaluation vẫn về cùng job.

Thêm DB-unique **resolver slot** độc lập active policy: `(owner, context, immutable_submission_revision, language, generation_sequence)`, default `generation_sequence=0`. POST phải atomically reserve/read slot này trước đọc active model/prompt hoặc build full fingerprint. Hai first POST đi qua hai thời điểm activate policy vẫn chỉ một slot thắng và freeze bundle; loser trả canonical request của winner, không tạo job/reservation/outbox thứ hai. Chỉ lookup trước policy mà không unique slot vẫn có race. Explicit regeneration cấp sequence mới có audit; language variant có language key riêng. Slot giữ được danh tính ngay khi evidence chưa ready; khi artifact hoàn tất mới freeze full fingerprint rồi dispatch, không sinh request thứ hai.

Trước khi tính explanation identity, pin derived evidence: bản transcript được dùng, ASR provider/model/config version, assessment output và hash, quality flags, alignment/timestamps và assessor/rubric compatibility. Retry dùng đúng artifact đã lưu; không chạy ASR lại rồi đổi âm thầm input của cùng job. Re-transcription/re-assessment tạo evidence revision mới có lineage/lý do; chỉ explicit reevaluation được dùng bản mới. Chưa có artifact hợp lệ thì WAITING_EVIDENCE với timeout budget hoặc NOT_ASSESSABLE rõ, không gọi model như đủ bằng chứng.

Pin prompt/model/schema/generation config/language policy ở lần request được chấp nhận đầu tiên. Default POST cho cùng submission và ngôn ngữ phải resolve về request/result cũ **trước khi** đọc active policy mới; nâng prompt/model toàn hệ thống không tự sinh bản khác cho bài cũ. Explicit đổi ngôn ngữ tạo variant riêng; explicit regeneration/reevaluation có version/lý do/quyền và không đổi default result đã chọn âm thầm. GET luôn đọc ID đã lưu, không tra active model để quyết định tạo mới.

Lưu actual provider `modelVersion` từ response cùng requested model/config. Không biết actual version trước request, vì vậy actual version là provenance kết quả, không cần đưa vào unique key trước generation. Chọn model version định danh được nếu provider hỗ trợ; alias chuyển model phải trigger policy review, không tạo lời hứa pin bằng string `latest`.

Logical records đề xuất, physical names và module owner xác nhận ở Phase 01:

| Record | Nội dung |
|---|---|
| Practice submission/evidence | Immutable answer, question/reference/rubric/evaluator pins, media manifest; safe projection riêng |
| Practice evaluation | Objective result và criterion applicability; version, state, owner/context |
| Explanation request/job | Unique key, pending state, request language/config, retry count, nextAttemptAt, lease/fencing |
| Explanation result | Immutable validated content, provenance, result hash, createdAt; không overwrite |
| Feedback outbox | Job ID/event type, dispatch state/retry; chỉ metadata, không answer/key |
| Rubric revision + publication | Academic descriptor, anchors, compatibility, review; không thuộc Student ownership |

Không tạo `ScoringAnswer`/official attempt/report giả cho practice. Public evaluation facade nhận immutable DTO/evidence hợp lệ, dùng cùng algorithms canonical.

Phiên lịch sử từ trước migration có thể chỉ giữ source UUID/prompt/options và không đủ answer-key/rubric pins. Chỉ backfill evaluation khi có immutable source revision/hash chứng minh đúng dữ liệu từng dùng; nếu không có thì đánh dấu `LEGACY_EVIDENCE_UNAVAILABLE`, vẫn đọc bài cũ nhưng không chấm bằng answer key/rubric hiện tại như thể đó là version gốc. Không fabricate provenance hoặc xóa bài để làm sạch dữ liệu.

## 4. Lifecycle và consistency dưới lỗi

Không cần state machine Mermaid để triển khai; hợp đồng trạng thái:

| Trạng thái | Ý nghĩa | Chuyển tiếp |
|---|---|---|
| NOT_REQUESTED | Có submission/result, chưa yêu cầu personalized AI | Student yêu cầu -> WAITING_EVIDENCE hoặc QUEUED |
| UNAVAILABLE | Task/rubric/provider capability chưa có | Không gọi Gemini; reason rõ, có reference nếu cho phép |
| WAITING_EVIDENCE | Request/slot đã lưu, đang đợi artifact transcript/assessor được pin | Có đủ evidence -> QUEUED; quá deadline -> FAILED với reason NOT_ASSESSABLE |
| QUEUED | Request + outbox đã commit | Worker claim -> RUNNING |
| RUNNING | Có lease và generation token | Validate/commit -> AVAILABLE; transient -> RETRY_WAIT; terminal -> FAILED |
| RETRY_WAIT | Lỗi tạm thời, có nextAttemptAt/attempt budget | Scheduler -> QUEUED; hết budget -> FAILED |
| AVAILABLE | Một result đã validate và commit | GET cùng result; regeneration tạo version request mới |
| FAILED | Lỗi terminal/không còn retry budget | Retry chỉ theo reason/policy và quota; giữ attempt history |
| CANCELLED | Xóa dữ liệu/quyết định hủy job hợp lệ | Worker cũ không được commit |

`LIMITED` là mức coverage trong result, không giả failed hay full score: ví dụ chỉ nhận xét nội dung do thiếu audio assessor. `SKIPPED`, `UNSCORED`, `NOT_ASSESSABLE` nằm ở evaluation/criterion status, không lẫn provider success.

Bảng job states này là normative cho các phase. `NOT_REQUESTED`, `UNAVAILABLE` và `BUDGET_LIMITED` là readiness/admission states trước job; persisted job chỉ dùng WAITING_EVIDENCE/QUEUED/RUNNING/RETRY_WAIT/AVAILABLE/FAILED/CANCELLED. Failure category, canRetry/cooldown và coverage là fields độc lập, không thêm PROCESSING/FAILED_FINAL/LIMITED như job states song song.

Transaction submit commit evidence/evaluation identity cùng nhau. Nếu auto-request được bật: commit outbox cùng submit. Với mặc định proposed on-demand: POST explanation commit job+outbox trong một transaction sau khi kiểm tra submission, quyền và ngân sách. Dispatcher đọc outbox định kỳ; Rabbit down không làm mất work. Worker claim DB bằng lease/token rồi mới gọi external I/O ngoài transaction. Duplicate message thấy job đã claim/available thì không gọi mới.

Nếu call timeout nhưng provider đã xử lý, retry có thể tốn thêm request. Vì vậy chỉ bảo đảm một canonical result accepted, không bảo đảm exactly one external charge. Ghi chi phí theo attempts; không retry đồng thời nhiều lớp không kiểm soát. DB result commit cần đúng lease/generation và state; worker đến muộn bỏ kết quả. Lease đủ cover configured call/job budget hoặc có heartbeat; reclaim không đẩy hai worker hợp lệ cùng commit.

Outbox publish rồi crash trước đánh dấu sent có thể publish lại; consumer idempotent. Worker crash sau call trước commit có thể gọi lại; immutable result unique constraint và fencing ngăn overwrite. Có scheduled reconciler cho expired leases, orphan outbox, retry due, DLQ mapping, không đợi Host/Student mở trang.

## 5. Prompt/output policy

Input gồm system instruction versioned, rubric approved, reference/source snapshot, verified objective result, raw Student evidence, task constraints và language. Student text và học liệu là untrusted data trong sections có escaped delimiters; không cho nội dung bài thay instruction. Không browsing, function/tool calling, arbitrary external URL fetching, RAG hay ký ức người dùng khác.

Output structured schema đề xuất:

| Field | Quy tắc |
|---|---|
| `summary` | Ngắn, ngôn ngữ đã pin, không khẳng định official score |
| `criteria[]` | Chỉ criterion IDs trong rubric; applicability, level label, feedback, evidence IDs; không criterion tự bịa |
| `mistakes[]` | Evidence có thật, explanation và suggested correction; không sửa đáp án đúng bằng suy đoán |
| `strengths[]` | Có evidence khi khẳng định nội dung cụ thể |
| `nextSteps[]` | Hành động gắn với lỗi/criterion; không thành adaptive study planner |
| `limitations[]` | Missing source/audio/assessor/unclear response cần hiển thị |
| `coverage` | FULL/LIMITED/NOT_ASSESSABLE theo khả năng bằng chứng, được server kiểm tra |

Provider/model/createdAt/job identity/provenance do server điền, không tin model tự khai. Objective correctness/score tách field server, không nhờ AI copy rồi coi là authoritative.

Validator kiểm schema (required, enums, sizes, nesting) và nghiệp vụ (criterion coverage/duplicates, ranges khi dùng score, text spans/token/option/media-time refs tồn tại, limitations phù hợp). Content hallucination không bắt hết bằng regex/schema: corpus và academic review là bắt buộc trước release. Invalid output không tới Student; tối đa một repair trong tổng attempt budget nếu policy cho phép; mọi repair giữ input pins, không tự đổi rubric/model.

Rendering chỉ plain text hoặc sanitize allowlist; không execute HTML/model Markdown links/scripts. Không hiển thị chain-of-thought/internal prompts, chỉ lý giải sư phạm dựa evidence.

## 6. API đề xuất, chưa phải route có sẵn

Reuse `/api/v1/student/practice` và response envelope hiện hữu. Tên chính xác freeze ở Phase 01; các routes sau là proposal:

| Method / path | Contract |
|---|---|
| GET `/sessions/{id}/results` | Owner/context, immutable submitted items và AI state; không generate |
| GET `/sessions/{id}/items/{itemId}/result` | Kết quả item đã submit, source/reference phù hợp reveal policy; chưa submit trả safe not-ready |
| POST `/sessions/{id}/items/{itemId}/explanations` | Body chỉ language được phép; Idempotency-Key; submit/entitlement/budget/ownership guards; trả logical request có state/ID |
| GET `/sessions/{id}/items/{itemId}/explanations/{explanationId}` | Đọc cùng stored result hoặc trạng thái chờ, không tăng số lần gọi |
| POST `/.../explanations/{explanationId}/retry` | Chỉ retryable/eligible failed job, cooldown/quota/permission; không regenerate bản AVAILABLE |
| GET `/progress?cursor=...` | Cursor ổn định; tổng toàn bộ phải query đúng hoặc ghi rõ window, không gọi latest-100 là lifetime |

HTTP statuses/envelopes/errors phải theo `docs/API_RESPONSE_SETUP.md`, `COMMON_EXCEPTION_SETUP.md` và existing `ApiResponse`; đưa machine codes và user messages vào `PracticeConstants`. Không sửa shape mọi API sẵn có chỉ vì thêm feedback. Giới hạn max input/token/output theo cấu hình được chốt trong phase triển khai.

## 7. Credential, ngân sách và vận hành

Đã kiểm tra presence, không kiểm key validity: `pte-api/.env` có `GEMINI_API_KEY`, Compose map `SCORING_AI_GEMINI_API_KEY`; Java chạy trực tiếp không tự nhận tên bên trái Compose. Tạo practice property binding rõ và không có secret fallback string/source value. Không dùng prefix `NEXT_PUBLIC_` cho key; browser chỉ gọi backend.

Practice AI toggle/budget/config độc lập exam scoring. Gemini-only text explanation chạy được khi Azure unavailable. Shared transport qua public interface/module cho phép bởi ModuleStructureTest; không import `scoring.internal` từ practice và không extract generic framework chưa cần.

Budget có per-student/org/day, global/provider project concurrency/RPM/token ceiling và reserve cho exam nếu dùng chung quota. Existing key không chứng minh billing tier/rate. Atomic quota reservation trước enqueue; duplicate không trừ quota lần nữa; metering external attempts kể cả timeout. Config đề xuất trong spec cần thống nhất thành values khi implementation preflight; lỗi config/key không retry tự động lặp lại. `429/503/timeout` bounded backoff/jitter và Retry-After trong remaining job budget.

Log chỉ request/job ID, state, latency, tokens, error category và version; không answer, transcript, prompt, signed URL, raw provider body hay key. Operational dashboard không mặc định cho Platform Manager quyền đọc Student essays/audio. Academic review dataset dùng synthetic/de-identified có quyền và sampling policy.

## 8. Kiểm định và rollout

Model/prompt/rubric update là policy release: chạy objective regression, schema/evidence validation và academic gold corpus trước activation; không tự regen kết quả cũ. A/B/alias drift có record modelVersion và alert; policy rollback pin cấu hình mới về version cũ cho request mới, không xóa lịch sử.

Live synthetic smoke sau code mới gồm một case objective, writing, optional audio khi assessor supported; chứng minh env injection và actual model/quota, không suy từ key presence. Không gửi bài Student thật trong smoke. Feature flag staged; nếu provider lỗi tắt AI nhưng giữ làm bài/đọc result/reference. Retention theo hợp đồng và policy AI đã duyệt; deletion phải lan tới jobs/results/cache/media theo legal/business ownership, không chỉ xóa UI row.

## 9. Official references

- [Google structured outputs](https://ai.google.dev/gemini-api/docs/generate-content/structured-output).
- [Google API key handling](https://ai.google.dev/gemini-api/docs/api-key).
- [Google troubleshooting](https://ai.google.dev/gemini-api/docs/troubleshooting).
- [Google project rate limits](https://ai.google.dev/gemini-api/docs/rate-limits).
- [Google model parameter guide](https://ai.google.dev/gemini-api/docs/generate-content/gemini-3).
- [Google API data terms](https://ai.google.dev/gemini-api/terms).

Checked 2026-10-22; recheck model availability/schema/parameters/account handling at implementation. Persisted result + validation/calibration is the proposed design inference, not a provider guarantee of determinism.
