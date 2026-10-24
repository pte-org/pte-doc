# Phase 8: Làm bài & sự cố — ExamAttempt, AttemptAnswer, ExamIncident

## Requirements

`ExamAttempt` trỏ trực tiếp `ExamVersion` (bỏ `PinnedExamSnapshot`/`PinnedItem`), `AttemptHeartbeat` thành `lastSeenAt`, `AttemptAnswer` giữ vai trò; `AttemptSecurityEvent` + `ViolationEvent` + `ExamSessionIncident`(+History) thành `ExamIncident`; bỏ `ProctorSession`. Đáp ứng story P1 làm bài trên nội dung đóng băng và FR-05.

## Design Constraints

- Đọc đầy đủ `docs/CODING_STANDARDS_API.md`, `docs/API_RESPONSE_SETUP.md`, `docs/COMMON_EXCEPTION_SETUP.md`, `docs/CODING_STANDARDS_WEB.md` và `docs/CODING_STANDARDS_APP.md` (client `pte-web` tenant proctor + `pte-app`). Ghi standards-read note vào progress update đầu tiên.
- NFR: `next-task`, `answers`, `submit` không tăng số query so với baseline phase 1.
- Presign URL/expiry và nội dung tính tại thời điểm đọc từ ExamVersion; không ghim lúc tạo attempt. `pinnedItemPublicId` == `examVersionItemPublicId` (phase 5); tiêu chí: không còn `Pinned*` trong attempt, scoring chỉ còn UUID tham chiếu tới phase 9.
- `ExamIncident`: AUTO vs REPORTED; history jsonb đọc nguyên khối; `organizationId`, `sessionId`, `attemptId`, `type`, `status` là cột thật. `GET .../security-audit` và `/incidents/**/history` đọc từ `AuditLog` + `ExamIncident` (không mất chức năng). Hash chain (`HashChainService`) bỏ theo spec.
- Giữ mã hoá nộp bài (`SubmissionDecryptionService`) và hợp đồng STOMP của `ProctorStompController`.

## Steps

1. Thiết kế `ExamAttempt` (`examVersionId`, trạng thái, thời gian, vị trí câu, `lastSeenAt`, `playCount`) thay `ExamAttempt`/`AttemptHeartbeat`: `AttemptController`, `HeartbeatController`/`HeartbeatService`, `TimerService`, `CapabilityNegotiationService`.
2. Xoá `PinnedExamSnapshot`, `PinnedItem`, `SnapshotPinService`, `PinnedSnapshotCacheService`; thêm cache đọc ExamVersion theo versionId và tính presign khi đọc; cập nhật `AttemptExaminerPromptQueryService`, `AttemptSummaryQueryService`, `AttemptGradingQueryService`, `AttemptStaffContextService`/`AttemptStaffContextQueryService`; chuyển nốt consumer `ScoreConfigFacade` của attempt sang ExamVersion item.
3. Chuyển `AttemptAnswer` (payload, trạng thái, điểm đã chọn — cột sẵn sàng cho phase 9) và `SubmissionDecryptionService`; không đổi hợp đồng `answers`/`submit`.
4. Thiết kế `ExamIncident` trong `proctoring` thay `AttemptSecurityEvent`, `ViolationEvent`, `ExamSessionIncident`, `ExamSessionIncidentHistory`: `ViolationService`, `AttemptSecurityAuditService`/`QueryService`/`RetentionService`, `SecurityAuditQueryService`, `ExamSessionIncidentService`/`CommandService`/`QueryService`, `ViolationAuditController`, `ExamSessionIncidentController`, `MonitoringController`.
5. Xoá `ProctorSession` (`ProctorSessionController`, `ProctorSessionService`) và `POST /api/v1/proctor-sessions/{id}/close`; kết thúc giám sát theo trạng thái ExamSession; cập nhật `ProctorAccessPolicy`, `ProctorCommandDispatchService`, `ProctorStompController`.
6. Đổi tên field `templatePublicId` → `examDefinitionPublicId` trong `AttemptScoreContextView`, `SubmittedAnswerView`, `AttemptGradingItemView`, `AttemptStaffContextView`.
7. Sửa client cùng phase: `pte-web/packages/api-client/src/requests/proctoring.ts`, `apps/tenant-web/features/proctor/transport.ts` (+ `decodeTopicMessage.ts`, test), `pte-app/lib/features/live_proctor/data/transport/stomp_live_proctor_transport.dart` (+ test), cùng nơi dùng 4 view đổi tên (xác định bằng grep); chạy lint/type/build theo hai standards; grep `/proctor-sessions` và `templatePublicId` (phần attempt) trong client trả 0. Cập nhật `seed-local-exam-ready.ps1` cho các bước làm bài.
8. Test: flow làm bài trên ExamVersion (start → next-task → answers → submit), incident AUTO/REPORTED + history + security-audit, so sánh query count với baseline phase 1; cập nhật `V1__baseline.sql` (`exam_attempt`, `attempt_answer`, `exam_incident`); chạy compile, test toàn app, `ModuleStructureTest`, gate Postgres.

## Success Criteria

- `ExamAttempt` có `examVersionId`; grep `Pinned` trong module attempt rỗng; số query `next-task`/`answers`/`submit` không vượt baseline (ghi số).
- Không còn `AttemptHeartbeat`, `AttemptSecurityEvent`, `ViolationEvent`, `ExamSessionIncident*`, `ProctorSession`, `SnapshotPinService`.
- Client `pte-web`/`pte-app` build/typecheck/test pass sau đổi.
- Gate dev DB (profile `local-schema`): từ `D:\GitHub\pte-org\pte-api`, DB `pte` trống trên Docker Postgres 17; `APP_SPRING_PROFILES=local-schema` trong `.env.local`; `docker compose --env-file .env.local -f docker-compose.yml -f docker-compose.services.yml up -d --no-deps --build app` khởi động (health UP) với Hibernate dựng schema, `db/dev-seed/*.sql` chạy xong, và `POST /api/v1/auth/login` thành công với `admin@test.local` và `host.e2e@test.local`. Ràng buộc chỉ Postgres phải có trong `db/dev-seed/000-postgres-objects.sql`. Không chạy được thì ghi "not verified", không bỏ qua im lặng.
- `.\mvnw.cmd -pl app -DskipTests compile`, `.\mvnw.cmd -pl app test`, `ModuleStructureTest` xanh; ghi số `@Entity` và số bảng do Hibernate dựng.

## Quality and Testing State

- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementing this phase)
- Testing: not started

## Risks

- Heartbeat ghi `lastSeenAt` mỗi lần có thể nặng write: throttle bằng cache/Redis, không đổi hợp đồng client.
- Mất hash chain: log sửa được, đã chấp nhận.
- `pte-app` có thể phụ thuộc response `ProctorSession`: kiểm bằng grep trước khi xoá.
