# Phase 3: Backend — link phát bản ghi của chính mình và lưu draft

Status: Not started
User stories: US-2 (nghe lại / ghi lại, bản nộp là bản cuối), US-5 (sóng âm bản ghi sau reload),
US-3 (trạng thái "đã ghi" sống qua thoát/tải lại ở chế độ tính giờ)
Tiêu chí §7: 5, 7 (phần BE), 6 (nguồn dữ liệu cho sóng tĩnh sau reload)

## Requirements

- Học viên lấy được link tạm phát **bản ghi `STUDENT_RESPONSE_AUDIO` của chính mình** gắn với
  một item trong phiên của chính mình (mọi trạng thái phiên, để sau này trang Review dùng lại).
  Mọi trường hợp khác (phiên/ item của người khác, khác tenant, item không ghi âm, draft không có
  `mediaPublicId`, media không thuộc đúng session/item/owner, chưa upload xong) → **404**.
- Lưu draft của một item mà **không** thoát phiên, để: (a) bản ghi tính giờ được lưu ngay sau
  upload; (b) ghi lại ở chế độ không tính giờ thay `media` trong payload đã lưu.
- Giữ cơ chế `Idempotency-Key` + `clientVersion` cho lệnh mới.

## Design Constraints

- Kiểm chủ sở hữu ở module sở hữu dữ liệu: practice kiểm session/item (như `PracticeMediaBindingService`
  và `findOwned`), media kiểm owner/purpose/binding/trạng thái của `MediaObject`. Practice không đọc
  repository của media; media không đọc repository của practice.
- Không dùng `PracticeResponseMediaValidator.validatePracticeResponseAudio` cho playback: nó đi qua
  `assertCanUseResponseAudio` vốn đòi phiên `IN_PROGRESS` + item `PENDING` (đúng cho nộp, sai cho nghe lại).
- Không mở rộng `GET /api/v1/objects/{id}/preview-url` cho học viên: nó chỉ kiểm owner, không kiểm
  binding session/item.
- TTL link ≤ trần `SIGNATURE_TTL_SECONDS = 900` của `CloudinaryMediaService`; asset `upload` công khai cũ
  trả `expiresInSeconds = 0` như `toTrustedDownloadResponse` hiện tại.
- Operation type mới phải vừa `VARCHAR(16)` của `practice_session_operations.operation_type` (`SAVE_DRAFT` = 10 ký tự).

## Related files

- `pte-api/app/src/main/java/com/pte/media/MediaService.java`
- `pte-api/app/src/main/java/com/pte/media/internal/service/CloudinaryMediaService.java`
  (`validatePracticeResponseAudio`, `toTrustedDownloadResponse`, `privateDownloadUrl`)
- `pte-api/app/src/main/java/com/pte/media/dto/response/PresignedDownloadResponse.java`
- `pte-api/app/src/main/java/com/pte/practice/internal/controller/PracticeSessionController.java`
- `pte-api/app/src/main/java/com/pte/practice/internal/service/PracticeSessionService.java`
- `pte-api/app/src/main/java/com/pte/practice/internal/service/PracticeSessionItemService.java` (`saveDraft`)
- `pte-api/app/src/main/java/com/pte/practice/internal/service/PracticeAnswerValidationService.java`
  (`requireRecordedMediaPublicId`)
- `pte-api/app/src/main/java/com/pte/practice/internal/service/PracticeRecordingPlaybackService.java` (mới)
- `pte-api/app/src/main/java/com/pte/practice/internal/domain/enums/PracticeSessionOperationType.java`
- `pte-api/app/src/main/java/com/pte/practice/internal/dto/request/PracticeDraftRequest.java` (mới)
- `pte-api/app/src/main/java/com/pte/practice/internal/dto/response/PracticeRecordingPlaybackResponse.java` (mới)
- `pte-api/app/src/test/java/com/pte/RouteContractTest.java` (nếu nó liệt kê route student)

## Steps

1. **media:** thêm `PresignedDownloadResponse presignOwnedPracticeResponseAudio(UUID mediaPublicId,
   UUID sessionPublicId, UUID itemPublicId, CurrentUser owner, long ttlSeconds)` vào `MediaService`,
   uỷ quyền cho phương thức mới trong `CloudinaryMediaService` (`@Transactional(readOnly = true)`):
   `findByPublicId` lọc `ownerPublicId == owner.userId()`, purpose `PRACTICE_RESPONSE_AUDIO`,
   `practiceSessionPublicId`/`practiceItemPublicId` khớp, `status == UPLOADED`, tenant khớp (nếu
   media có tenant) → `toTrustedDownloadResponse(media, ttl, owner.tenantId())`; lệch → `MediaNotFoundException`.
   Phương thức này **không** được gọi `requirePracticeBinding(media, caller)` hay `validatePracticeResponseAudio`:
   cả hai đi qua `PracticeMediaBindingPort.assertCanUseResponseAudio`, vốn đòi phiên `IN_PROGRESS` + item `PENDING`
   → sẽ chặn nghe lại item đã nộp/phiên đã xong. Kiểm session/item thuộc học viên là việc của practice (bước 2).
2. **practice:** `PracticeRecordingPlaybackService.playback(UUID sessionPublicId, UUID itemPublicId, CurrentUser caller)`:
   `sessionRepository.findByPublicIdAndStudentPublicIdAndDeletedFalse` + kiểm tenant (giống
   `PracticeMediaBindingService`), item theo `findByPublicIdAndPracticeSessionIdAndDeletedFalse`,
   renderer thuộc `PRACTICE_RECORDING_RENDERER_KEYS`, `savedPayload` có `mediaPublicId` (dùng
   `requireRecordedMediaPublicId`, lỗi parse → `PracticeSessionNotFoundException`), rồi gọi
   `mediaService.presignOwnedPracticeResponseAudio(..., PRACTICE_RECORDING_PLAYBACK_TTL_SECONDS)`.
   Hằng mới `PRACTICE_RECORDING_PLAYBACK_TTL_SECONDS = 900L`.
3. Response `PracticeRecordingPlaybackResponse(String url, long expiresInSeconds, Integer durationSeconds)`.
4. Controller: `@GetMapping("/{publicId}/items/{itemPublicId}/recording")` → `ApiResponse.success(...)`.
   Không cần `assertUnlocked` (chỉ đọc dữ liệu của chính mình) — ghi rõ lý do trong javadoc.
5. **draft:** thêm `SAVE_DRAFT` vào `PracticeSessionOperationType`; record
   `PracticeDraftRequest(@NotNull Long clientVersion, @NotBlank @Size(max = MAX_ANSWER_PAYLOAD_LENGTH) String payload,
   ResponseConfidence confidence)`; `PracticeSessionService.saveDraft(publicId, itemPublicId, request, key, caller)`:
   `findOwnedForUpdate` → `entitlementService.assertUnlocked` → replay theo operation → `requireLiveInProgress`
   → `itemService.saveDraft(...)` (đã validate draft + `validateRecordedMedia`) → `lastActivityAt` → operation → `saveAndMap`.
   Hash: `itemPublicId`, `clientVersion`, `payload`, `confidence` (giống `answerRequestHash`).
6. Controller: `@PostMapping("/{publicId}/items/{itemPublicId}/draft")` với header `Idempotency-Key`.
7. **Spike CORS (bắt buộc ghi kết quả vào report P7):** trên local có Cloudinary thật, gọi endpoint
   playback rồi `fetch(url)` từ origin `http://localhost:3014`. Nếu bị chặn CORS: thêm
   `GET .../recording/content` stream byte qua backend (cùng kiểm quyền bước 2, `Content-Type: audio/wav`,
   trần `MAX_PRACTICE_RESPONSE_BYTES`) và FE dùng đường này để decode; nếu không bị chặn thì bỏ bước này.

## Tests to add

- `PracticeRecordingPlaybackServiceTest`: `playback_ownRecordedItem_returnsSignedUrl`,
  `playback_otherStudentsSession_throwsNotFound`, `playback_otherTenant_throwsNotFound`,
  `playback_itemFromAnotherSession_throwsNotFound`, `playback_nonRecordingItem_throwsNotFound`,
  `playback_noSavedPayload_throwsNotFound`, `playback_completedSession_stillReturnsUrl`.
- `CloudinaryMediaServiceTest` (hoặc file test media hiện có): `presignOwnedPracticeResponseAudio_ownerAndBindingMatch_returnsUrl`,
  `..._otherOwner_throwsNotFound`, `..._differentItemBinding_throwsNotFound`, `..._notUploaded_throwsNotFound`,
  `..._authoringAudio_throwsNotFound`, `..._ttlAboveCap_isClampedTo900`.
- `PracticeSessionServiceTest`: `saveDraft_pendingRecordingItem_replacesSavedMedia`,
  `saveDraft_sameKeySamePayload_replaysWithoutWrite`, `saveDraft_staleVersion_throwsConflict`,
  `saveDraft_answeredItem_throwsNotStartable`, `saveDraft_keepsSessionInProgress`,
  `saveDraft_afterHeartbeatWithCurrentVersion_succeeds` (red-team #1: heartbeat tăng `version`, draft gửi
  `clientVersion` = version sau heartbeat thì lưu được; gửi version cũ → 409 như `saveDraft_staleVersion_throwsConflict`).
- `CloudinaryMediaServiceTest.presignOwnedPracticeResponseAudio_answeredItemInCompletedSession_doesNotCallBindingPort`
  (verify `PracticeMediaBindingPort` không được gọi).
- Controller slice/route test cho 2 route mới (theo mẫu `PracticeSessionControllerReviewTest`).

## Success criteria

- Học viên A không lấy được link bản ghi của học viên B dù đoán đúng `publicId` (404).
- Ghi lại 2 lần rồi gọi draft → `savedPayload.mediaPublicId` là bản cuối; `answer` sau đó nộp đúng bản cuối.
- Có kết luận CORS rõ ràng (link trực tiếp dùng được, hoặc đã có đường stream).
- Suite `practice`, `media`, `ModuleStructureTest`, `RouteContractTest` xanh.

## Quality and Testing State

- quality: not evaluated
- testing: not started
