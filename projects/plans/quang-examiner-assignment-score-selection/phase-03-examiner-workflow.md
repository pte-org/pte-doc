# Phase 03 — Examiner queue và blind scoring

**Plan:** [plan.md](plan.md) · **Spec:** [spec.md](spec.md)  
**Covers:** P1 Examiner; FR-03, FR-04, FR-09–11, FR-18.  
**Depends on:** Phase 01–02.  
**Outcome:** Examiner chỉ xem/chấm attempt đã giao cho mình, gồm playback cần thiết, và nộp điểm tổng 0–100 riêng cho từng answer đủ điều kiện.

## Mục tiêu

Tạo authenticated Examiner work area tách khỏi Host answer review. Blind marking là server-side data minimization: không chỉ ẩn cột bằng UI.

## Backend/API work

1. **Role boundary và queue**
   - Thêm Examiner queue/list API dùng principal hiện tại; không nhận examiner ID để quyết định ownership.
   - Query filter đồng thời authenticated examiner ID + tenant + assignment state; chỉ trả assigned attempts.
   - Kiểm tra tài khoản active/role ở authorization layer theo convention auth hiện có.
   - DTO trả attempt status/attempt-safe student label, câu AI-eligible, answer payload cần chấm và trạng thái score submission; loại bỏ `rawScore`, `teacherScore`, selected source, provider provenance, Host review metadata.

2. **Detail và media**
   - Detail API xác minh assignment trước khi đọc answer payload hoặc xin presigned media URL.
   - Không tạo media URL rồi mới lọc answer; URL được cấp ngắn hạn chỉ sau tenant + assignment + answer-to-attempt checks.
   - Phân biệt answer/media không tồn tại với không được quyền theo quy tắc no-existence-leak đang dùng trong scoring.
   - Upload mới dùng Cloudinary `authenticated`; media facade phát hành private-download URL ký số có `expires_at` thật. Các asset cũ vẫn mang delivery type `UPLOAD`, được giữ tương thích và trả `expiresInSeconds=0` cho tới khi operator migrate chúng trên Cloudinary.

3. **Score submission**
   - Chỉ chấp nhận integer 0–100 cho answer AI-eligible thuộc attempt được giao.
   - Persist examiner, answer, attempt, session, tenant, submittedAt và status; giữ nguyên AI raw score và Host teacher score.
   - Một answer chỉ submit một lần trong MVP. Retry cùng examiner/cùng score trả kết quả đã lưu; khác score, examiner khác hoặc answer đã publish bị từ chối.
   - Batch completeness/query xác định answer đã submit để Host review hiển thị chính xác.

4. **Examiner web area**
   - Bổ sung route/layout và navigation dành riêng cho role EXAMINER trong tenant-web; không reuse Host-only shell nếu gây lộ Host controls.
   - Queue filter trạng thái chưa chấm/đã chấm; attempt detail liệt kê các câu cần chấm, render đúng task response và audio/image prompt media cần thiết.
   - Score field numeric 0–100, validation FE hỗ trợ UX nhưng backend vẫn validate; trạng thái submitted read-only.
   - Không render AI score, Host score, selected source, score availability của AI hoặc Host approval controls.

## Kiểm chứng và acceptance

- Security matrix: Examiner đúng tenant + assignment được phép; cùng tenant nhưng chưa assigned, assigned cho người khác, tenant khác, inactive, sai role đều bị từ chối.
- Gọi list/detail/media/submit bằng ID đoán được không lộ attempt title/payload/audio/AI score.
- JSON contract snapshot/serialization asserts không có AI/Host score và selected source, kể cả trạng thái lỗi.
- Media presign chỉ chạy sau assignment ownership; test answer thuộc attempt khác.
- Score range/type/eligibility/identity/timestamp; score không đổi rawScore/objective/teacherScore.
- Identical retry idempotent; conflicting retry rejected; concurrent duplicate submit chỉ ghi một score.
- E2E role navigation: EXAMINER mở queue; không truy cập Host routes; HOST_ADMIN vẫn dùng Host answer review như trước.

**Acceptance:** secure examiner workflow và một lần chấm cho mọi AI-eligible answer trong assignment; Host source-selection UI/API đến ở Phase 04.

## Design Constraints

- Assignment và tenant ownership được enforce server-side cho mọi endpoint đọc/chấm/media.
- Examiner DTO không chứa AI score, selected source, Host teacher score hoặc provenance; blind marking áp dụng trước/trong khi chấm.
- Examiner score là record riêng, immutable sau submit trong MVP; không ghi đè objective/AI/Host score.
- Không tin examinerPublicId do client truyền vào để quyết định work ownership.
- Không mở rộng quyền `HOST_ADMIN` hoặc chuyển examiner vào Host-only controls.

## Files

- Backend assessment prompt projection: `../pte-api/app/src/main/java/com/pte/assessment/AssessmentService.java`, `../pte-api/app/src/main/java/com/pte/assessment/dto/response/ExaminerQuestionPromptView.java`, `../pte-api/app/src/main/java/com/pte/assessment/internal/repository/SnapshotItemRepository.java`, `../pte-api/app/src/main/java/com/pte/assessment/internal/service/SnapshotPromptQueryService.java`.
- Assessment error-message constants: `../pte-api/app/src/main/java/com/pte/assessment/internal/constant/AssessmentConstants.java`, `../pte-api/app/src/main/java/com/pte/assessment/domain/AssessmentDomainConstants.java`, `../pte-api/app/src/main/java/com/pte/assessment/domain/SnapshotItem.java`, `../pte-api/app/src/main/java/com/pte/assessment/internal/service/BlueprintService.java`.
- Trusted tenant-scoped media batch resolution: `../pte-api/app/src/main/java/com/pte/media/MediaService.java`, `../pte-api/app/src/main/java/com/pte/media/internal/repository/MediaObjectRepository.java`, `../pte-api/app/src/main/java/com/pte/media/internal/service/CloudinaryMediaService.java`.
- Authenticated Cloudinary upload contract: `../pte-api/app/src/main/java/com/pte/media/domain/MediaObject.java`, `../pte-api/app/src/main/java/com/pte/media/domain/enums/CloudinaryDeliveryType.java`, `../pte-api/app/src/main/java/com/pte/media/internal/constant/MediaConstants.java`, `../pte-api/app/src/main/resources/db/migration/V63__authenticated_cloudinary_media.sql`, `../pte-web/apps/vendor-web/features/questionbank/components/QuestionEditorForm.tsx`, `../pte-app/lib/core/network/raw_upload_client.dart`, `../pte-app/test/unit/network/raw_upload_client_test.dart`.
- Backend Examiner scoring/API: `../pte-api/app/src/main/java/com/pte/scoring/domain/enums/ExaminerAnswerContentKind.java`, `../pte-api/app/src/main/java/com/pte/scoring/domain/enums/ExaminerQueueStatus.java`, `../pte-api/app/src/main/java/com/pte/scoring/dto/request/SubmitExaminerScoreRequest.java`, `../pte-api/app/src/main/java/com/pte/scoring/dto/response/ExaminerAnswerDetailResponse.java`, `../pte-api/app/src/main/java/com/pte/scoring/dto/response/ExaminerAnswerPayloadResponse.java`, `../pte-api/app/src/main/java/com/pte/scoring/dto/response/ExaminerAttemptDetailResponse.java`, `../pte-api/app/src/main/java/com/pte/scoring/dto/response/ExaminerPromptOptionResponse.java`, `../pte-api/app/src/main/java/com/pte/scoring/dto/response/ExaminerPromptResponse.java`, `../pte-api/app/src/main/java/com/pte/scoring/dto/response/ExaminerQueueItemResponse.java`, `../pte-api/app/src/main/java/com/pte/scoring/dto/response/ExaminerQueueResponse.java`, `../pte-api/app/src/main/java/com/pte/scoring/dto/response/ExaminerResponseOptionResponse.java`, `../pte-api/app/src/main/java/com/pte/scoring/dto/response/ExaminerScoreSubmissionResponse.java`, `../pte-api/app/src/main/java/com/pte/scoring/internal/constant/ExaminerScoringConstants.java`, `../pte-api/app/src/main/java/com/pte/scoring/internal/controller/ExaminerWorkController.java`, `../pte-api/app/src/main/java/com/pte/scoring/internal/exception/ExaminerScoreConflictException.java`, `../pte-api/app/src/main/java/com/pte/scoring/internal/exception/ExaminerWorkNotFoundException.java`, `../pte-api/app/src/main/java/com/pte/scoring/internal/exception/InvalidExaminerQueueStatusException.java`, `../pte-api/app/src/main/java/com/pte/scoring/internal/exception/InvalidExaminerScoreException.java`, `../pte-api/app/src/main/java/com/pte/scoring/internal/repository/ExaminerAnswerScoreRepository.java`, `../pte-api/app/src/main/java/com/pte/scoring/internal/repository/ExaminerWorkQueueRepository.java`, `../pte-api/app/src/main/java/com/pte/scoring/internal/service/ExaminerScoringService.java`.
- Scoring facade/domain and post-publication assignment fence: `../pte-api/app/src/main/java/com/pte/scoring/ScoringService.java`, `../pte-api/app/src/main/java/com/pte/scoring/domain/ExaminerAnswerScore.java`, `../pte-api/app/src/main/java/com/pte/scoring/domain/ScoringAnswer.java`, `../pte-api/app/src/main/java/com/pte/scoring/domain/enums/ScoringMethod.java`, `../pte-api/app/src/main/java/com/pte/scoring/internal/service/ExaminerAssignmentService.java`, `../pte-api/app/src/main/java/com/pte/scoring/internal/service/AiScoringResultPersistenceService.java`.
- Backend unit tests: `../pte-api/app/src/test/java/com/pte/assessment/internal/service/SnapshotPromptQueryServiceTest.java`, `../pte-api/app/src/test/java/com/pte/media/internal/service/CloudinaryMediaServiceTest.java`, `../pte-api/app/src/test/java/com/pte/scoring/internal/service/ExaminerScoringServiceTest.java`.
- Persistence/queue and media access tests: `../pte-api/app/src/test/java/com/pte/scoring/internal/repository/ExaminerWorkQueueRepositoryTest.java`; Cloudinary delivery-mode schema: `../pte-api/app/src/main/resources/db/migration/V63__authenticated_cloudinary_media.sql`.
- Carried-over verification context (created and reviewed in Phase 02; unchanged by Phase 03, but still untracked in this shared worktree): `../pte-api/app/src/test/java/com/pte/scoring/internal/service/ExaminerAssignmentDatabaseIntegrationTest.java`.
- API client: `../pte-web/packages/api-client/src/requests/index.ts`, `../pte-web/packages/api-client/src/requests/scoring/examiner.ts`, `../pte-web/packages/api-client/src/requests/scoring/examiner.test.ts`, `../pte-web/packages/api-client/src/types/scoring/index.ts`.
- Tenant Examiner UI/auth/navigation: `../pte-web/apps/tenant-web/app/(dashboard)/examiner/work/page.tsx`, `../pte-web/apps/tenant-web/features/examiner/api.ts`, `../pte-web/apps/tenant-web/features/examiner/ExaminerWorkView.tsx`, `../pte-web/apps/tenant-web/features/examiner/constants.ts`, `../pte-web/apps/tenant-web/features/auth/components/LoginView.tsx`, `../pte-web/apps/tenant-web/features/auth/constants.ts`, `../pte-web/apps/tenant-web/lib/navigation.tsx`, `../pte-web/apps/tenant-web/lib/navigationConstants.ts`.

## Phase Checkpoint

- Unit tests: yes (user confirmed for Phases 03–05 on 2026-09-23)
- `ck:quality`: yes (user confirmed for Phases 03–05 on 2026-09-23)
- Hard-mode confirmation: required from the user after this phase's build, tests, and quality gate.
- Preflight: scoring contracts live behind public `ScoringService`; human endpoint ownership is based on the authenticated principal and assignment data. The implementation decodes answers only after assignment checks, resolves prompts/media in tenant-scoped batches, and keeps examiner DTOs blind. Published sessions are removed from Examiner queue/detail and reject further assignment. New Cloudinary media uses authenticated delivery and signed expiring download URLs; historical public uploads remain explicitly marked as legacy until operator migration.

## Quality and Testing State

- quality: not evaluated
- testing: not started
- Kế hoạch: authorization/DTO/media integration tests; submit idempotency/concurrency tests; Examiner route/component/E2E tests.
