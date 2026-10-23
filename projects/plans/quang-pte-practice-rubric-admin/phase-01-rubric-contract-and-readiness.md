# Phase 01: rubric contract, task matrix và readiness

**Status:** implemented and reviewed  
**Dependency:** none  
**Output:** contract được chốt để backend, Gemini và Admin Web dùng cùng một vocabulary.

## Mục tiêu

Chuyển `practice-rubric-v1.md` từ tài liệu chính sách thành contract có thể kiểm tra. Mỗi canonical task type phải biết rubric nào áp dụng, cần evidence gì, criterion nào được trả về và khi nào kết quả là `NOT_ASSESSABLE`.

## Công việc

1. Đối chiếu task type đang có trong itembank/practice với rubric task matrix; ghi rõ task nào có rubric v1, task nào chưa đủ reference hoặc evidence. Mapping máy đọc nằm trong `rubric-contract-v1.json`.
2. Chốt schema rubric gồm criterion, level, applicability, evidence policy, empty/invalid/off-topic policy, anchor example và provenance.
3. Chốt vocabulary level và output state. Không dùng numeric AI score cho Writing/Speaking.
4. Chốt runtime compatibility: task type, channel, renderer/runtime profile, answer schema, evaluator/reference version.
5. Tạo readiness checklist server-side; không coi checkbox trên UI là bằng chứng sẵn sàng.
6. Chốt canonical JSON serialization, hash input và quy tắc thay đổi tạo revision mới.
7. Đánh dấu Personal Introduction là coaching-only, không có tổng điểm hoặc rubric score.
8. Dùng `PUBLISHED` làm vocabulary canonical cho rubric. Nếu dữ liệu legacy có `ACTIVE`, migration/read adapter phải map `ACTIVE` → `PUBLISHED` khi đọc và chỉ ghi `PUBLISHED` cho rubric mới; không để hai trạng thái có cùng ý nghĩa chạy song song.

## Common/shared bắt buộc

- Dùng các task/role constants hiện có khi contract đã có canonical key; không tạo tên task trùng nghĩa trong feature riêng.
- Reuse response/error vocabulary ở `pte-api` và localization key conventions ở `vendor-web`.
- Không thêm business state vào `@pte/ui`; contract chỉ mô tả dữ liệu và quy tắc.

## Design Constraints

**Preflight:** Đã đối chiếu `practice-rubric-v1.md`, `rubric-and-task-matrix.md`, practice explanation contract và task/runtime conventions hiện có. Phase này chỉ chốt vocabulary/contract; không tạo module hoặc UI riêng.

- Không coi ScoreTemplate weight là rubric criterion.
- Không gửi answer key, restricted reference hoặc internal prompt vào projection Student.
- Không tạo global rubric áp dụng ngầm cho mọi task.
- `NOT_ASSESSABLE` chỉ được phép ở criterion có evidence policy cho phép.
- Hash phải phụ thuộc vào canonical content và compatibility metadata, không chỉ version string.

## Quality and Testing State

- Quality: **APPROVED** by the independent review; final phase completion remains subject to the `--hard` confirmation gate.
- Testing: contract and validator coverage is included in the backend targeted suite; the full backend regression also passes.
- TDD: contract/validator tests were written before the related implementation was accepted.
- Exit gate: task matrix, JSON schema, readiness rules, lifecycle transitions and server-owned evidence requirements are recorded in the phase artifacts.
