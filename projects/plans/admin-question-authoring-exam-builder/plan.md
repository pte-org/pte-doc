# Plan: Question authoring & exam builder

Status: Implemented; build verified  
Date: 2026-09-18  
Mode: Hard  
Scope: `pte-api` + `pte-web` + API client  
Primary actors: Platform Admin, Platform Author  
Related architecture: [ADR-006](../../architecture/ADR-006-commercialization-and-exam-templates.md)

## Objective

Hoàn thiện hai luồng đang là placeholder:

1. Platform Admin/Author tạo, sửa, preview, submit approval, archive và khôi phục câu hỏi PTE trong Question Bank.
2. Platform Admin/Author tạo và chỉnh sửa blueprint theo template PTE hiện hành, có thứ tự mặc định và filter; Admin là người duyệt/publish.
3. Host vẫn dùng luồng sinh đề theo skill và snapshot bất biến của hệ thống.

## Scope challenge

### Hiện trạng đã có

- `itembank` đã có `Question`, `QuestionOption`, 23 `PteTaskType`, validation cơ bản và lifecycle publish/archive/unarchive.
- `media` đã có upload flow nhưng frontend đang gọi contract cũ `/api/v1/assets/upload`; implementation mới sẽ dùng Cloudinary.
- `assessment` đã có random generation, shortage check và snapshot deep-copy; HTTP API tạo đề cho vendor chưa có.
- `QuestionEditorForm` và `ExamBuilderForm` hiện chỉ là UI placeholder.

### Quyết định phạm vi của plan

- Question authoring dành cho `PLATFORM_ADMIN` và `PLATFORM_AUTHOR`. Host, Proctor, Lecturer và Student không được truy cập Question Bank.
- Thêm trạng thái `PENDING_APPROVAL`: Author chỉ tạo/sửa/submit; Admin mới approve/reject/publish. Giữ `APPROVED` làm trạng thái đã publish để không phá query generation hiện tại; UI hiển thị `APPROVED` với nhãn “Published”.
- “Xóa” là soft delete bằng archive; “khôi phục” là unarchive về DRAFT. Không hard-delete câu hỏi đã từng được dùng trong snapshot.
- Câu hỏi APPROVED không sửa tại chỗ. Thao tác edit tạo một bản revision DRAFT mới; snapshot cũ tiếp tục tham chiếu nội dung version cũ.
- Exam Builder vendor là platform-curated: nạp thứ tự mặc định từ PTE score template, cho filter question bank, chọn/thêm/bỏ/sắp xếp item và submit chờ Admin duyệt. Host không được dùng manual builder; host vẫn sinh đề random theo skill.

## Phases

- [x] Phase 1: Question lifecycle, revision và validation backend
- [x] Phase 2: Media authoring contract và question API security
- [x] Phase 3: Vendor Question Bank UI
- [x] Phase 4: Assessment blueprint, template ordering và approval API
- [x] Phase 5: Vendor Exam Builder UI
- [ ] Phase 6: Optional release smoke và verification

## Dependency order

```text
Phase 1 ──┬──> Phase 3 ──┐
          └──> Phase 2 ──┘

Phase 1 + existing score-template generation ──> Phase 4 ──> Phase 5

Phase 2 + Phase 3 + Phase 4 + Phase 5 ──> Phase 6
```

Phase 1 và Phase 2 có thể làm song song nếu backend owners khác nhau, nhưng Phase 3 không bắt đầu trước khi API contract/status/media flow được chốt.

## Cross-cutting design constraints

- Không để frontend tự suy đoán rule theo task type khác với `QuestionValidationHelper`; tạo metadata contract dùng chung hoặc giữ một mapping có test đối chiếu toàn bộ 23 task.
- Media Cloudinary phải được backend xác nhận hoàn tất trước khi question được publish. Không trả answer key trong các response preview dành cho host/student.
- Snapshot là write-once. Sau khi snapshot publish, sửa source question hoặc score template không được thay đổi snapshot.
- Tất cả endpoint mutation phải kiểm tra role server-side; route guard ở vendor-web chỉ là lớp UX.
- Generation phải kiểm tra stock trước khi ghi blueprint/snapshot và trả shortage theo từng task type.
- Mọi mutation cần trạng thái loading, retry, lỗi field-level và lỗi nghiệp vụ có thể hiển thị được.
- API client không được giữ các endpoint “ảo” đã biết là chưa tồn tại.

## Data and lifecycle decisions

### Question revision

MVP dùng version row dựa trên aggregate hiện tại, tránh tách 23 task thành 23 bảng:

- Thêm `revisionGroupPublicId`, `revisionNumber`, `supersedesPublicId` và optimistic-lock field vào `Question`.
- Migration backfill mỗi Question hiện hữu thành group riêng, `revisionNumber = 1`, `isCurrent = true`; thêm unique partial index để mỗi group chỉ có một current revision.
- Create tạo revision đầu tiên ở DRAFT.
- Question mới chưa từng publish có thể là current DRAFT; draft clone của APPROVED là non-current để bản APPROVED cũ tiếp tục được generation chọn trong lúc soạn.
- Edit question DRAFT cập nhật bản DRAFT hiện tại.
- Edit question APPROVED tạo một Question row DRAFT mới, giữ bản APPROVED cũ cho đến khi revision mới publish.
- Author submit revision sẽ chuyển DRAFT → PENDING_APPROVAL. Admin approve trong transaction có row/group lock: bản cũ thành ARCHIVED + non-current, bản mới thành APPROVED + current; snapshot đã tồn tại không bị sửa.
- Admin reject PENDING_APPROVAL về DRAFT và lưu rejection reason; Author có thể sửa rồi submit lại.
- Question selection cho generation chỉ lấy bản APPROVED current.
- Revision history trả metadata và nội dung theo quyền Platform Admin/Author; không cho sửa revision đã publish.
- Unarchive một revision đã bị supersede phải bị từ chối; chỉ revision hiện hành ARCHIVED mới được restore về DRAFT.

Nếu schema hiện tại không thể biểu diễn `current`/`supersedes` an toàn, thay thế bằng `question_revisions` immutable table với cùng các invariant. Không dùng update in-place cho bản đã APPROVED.

### Status mapping

| Backend | UI label | Ý nghĩa |
|---|---|---|
| `DRAFT` | Draft | Đang soạn, chưa được random vào đề |
| `PENDING_APPROVAL` | Pending approval | Author đã submit, chờ Admin duyệt |
| `APPROVED` | Published | Admin đã duyệt, được phép random/chọn vào đề |
| `ARCHIVED` | Archived | Không được random/chọn; có thể khôi phục thành DRAFT |

Author không có quyền chuyển `PENDING_APPROVAL` thành `APPROVED`. Admin approve sẽ chuyển sang `APPROVED`; Admin reject chuyển về `DRAFT` kèm lý do.

## API contract target

### Question

```text
POST   /api/v1/questions
GET    /api/v1/questions?taskType=&status=&q=&page=&size=
GET    /api/v1/questions/{publicId}
GET    /api/v1/questions/{publicId}/revisions
PUT    /api/v1/questions/{publicId}                 # DRAFT only
POST   /api/v1/questions/{publicId}/edit             # clone APPROVED -> DRAFT revision
POST   /api/v1/questions/{publicId}/submit-approval    # Author
POST   /api/v1/questions/{publicId}/approve            # Admin
POST   /api/v1/questions/{publicId}/reject             # Admin
POST   /api/v1/questions/{publicId}/archive          # soft delete
POST   /api/v1/questions/{publicId}/unarchive        # restore -> DRAFT
GET    /api/v1/question-types                        # task metadata for forms
```

`OptionRequest` phải truyền được `text`, `correct`, `orderIndex`, `blankIndex` và `correctGapIndex`. Request không nhận `status` từ client.

### Media

```text
POST /api/v1/objects                                  # returns Cloudinary signed-upload params
POST <cloudinary uploadUrl>                           # direct browser -> Cloudinary
POST /api/v1/objects/{publicId}/complete              # backend verifies Cloudinary asset
GET  /api/v1/objects/{publicId}/preview-url           # authenticated author preview
```

Media contract phải dùng Cloudinary signed upload, không expose `api_secret` ở frontend, phân biệt `AUDIO_PROMPT` và `IMAGE_PROMPT`, kiểm tra MIME/size/ownership/status và không cho overwrite asset đã complete. Backend lưu `publicId`, `resourceType`, `secureUrl`, `format`, `bytes`, `duration` và `assetId`/checksum cần thiết để audit.

### Assessment generation

```text
POST /api/v1/blueprints/generation-preview
POST /api/v1/blueprints/generate
POST /api/v1/blueprints                         # create curated DRAFT
GET  /api/v1/blueprints
GET  /api/v1/blueprints/{publicId}
PUT  /api/v1/blueprints/{publicId}               # edit DRAFT
POST /api/v1/blueprints/{publicId}/submit-approval
POST /api/v1/blueprints/{publicId}/approve       # Admin
POST /api/v1/blueprints/{publicId}/reject        # Admin
GET  /api/v1/snapshots/{publicId}
```

Curated blueprint phải lấy ACTIVE PTE score template làm thứ tự mặc định: section order → template sequence → task type → item order. UI có filter question bank theo section, task type, status, keyword và các metadata đã lưu; Admin/Author có thể chọn, thêm, bỏ và sắp xếp item trong DRAFT. `approve` sẽ validate blueprint rồi publish snapshot. `generate` vẫn nhận `name` và 1–4 `skills` cho random flow; không dùng `POST /sessions` từ vendor vì endpoint đó thuộc host/subscription workflow.

## Main risks and mitigations

| Risk | Mitigation |
|---|---|
| Backend `APPROVED` và frontend `PUBLISHED` lệch nhau | Chốt API enum là `APPROVED`, map label ở một nơi, thêm contract test |
| Cloudinary upload không được server xác minh | Signed params, upload signature, backend confirm qua Cloudinary API, allow-list resource type/folder |
| Sửa câu hỏi làm thay đổi đề cũ | Revision row + snapshot deep-copy + test immutability |
| Cloudinary upload tạo asset mồ côi | Complete timeout/cleanup job hoặc reconciliation report; không gắn question trước khi complete |
| Validation task type không đủ | Parameterized backend test cho cả 23 task và schema metadata test |
| Stock thay đổi giữa check và draw | Giữ shortage check sau draw, transaction rollback all-or-nothing, test concurrent archive |
| Manual builder mâu thuẫn ADR-006 | Chỉ cho Platform Admin/Author; Host vẫn generated-only theo skill |
| Preview lộ đáp án | Tách DTO preview/answer-key; security test theo role |

## Acceptance criteria for the whole plan

- Platform Admin/Author tạo được DRAFT cho các task type được hỗ trợ và nhận lỗi đúng field.
- Author submit question/blueprint thì chuyển sang PENDING_APPROVAL; chỉ Admin approve/publish.
- Audio/image upload dùng Cloudinary signed flow, preview được sau confirm, publish bị chặn nếu media pending/invalid.
- Question APPROVED không bị sửa in-place; edit tạo revision DRAFT và snapshot cũ không đổi.
- Archive loại question khỏi generation; unarchive đưa về DRAFT và phải publish lại.
- Vendor có thể filter question bank, tạo/chỉnh sửa blueprint theo thứ tự mặc định của PTE template và submit chờ Admin duyệt.
- Vendor xem được blueprint/snapshot kết quả nhưng không thấy answer key ở màn hình không được phép.
- Host/Proctor/Lecturer/Student bị từ chối ở Question Bank platform endpoints.
- Không còn nút Save disabled hoặc thông báo “API chưa kết nối” ở hai màn hình trong phạm vi MVP.
- Backend, API client và frontend có contract/status mapping thống nhất.

## Decisions recorded

1. Exam Builder phải có thứ tự mặc định theo PTE template và filter question bank; curated blueprint là platform-only.
2. Platform Author phải submit và chờ Platform Admin approve/reject.
3. Media provider là Cloudinary, không dùng MinIO cho authoring media.
4. Không bắt buộc test hoặc quality audit ở từng phase theo yêu cầu hiện tại.
5. Hard-delete không nằm trong MVP; archive/restore giữ audit trail.

## Optional test strategy

- Backend unit/parameterized: task validation, option semantics, lifecycle transition, revision clone/approval, media validation, generation shortage.
- Backend integration: PostgreSQL/Flyway, role matrix, Cloudinary signed flow, snapshot immutability, concurrent archive/approve.
- API client: request/response mapper and status contract tests.
- Frontend component: schema rendering, field validation, media upload retry, preview, mutation error handling.
- Automated tests/E2E/quality audit: không bắt buộc ở từng phase theo quyết định hiện tại. Nếu cần tăng độ tin cậy trước release, chạy smoke flow này như một gate tùy chọn.
