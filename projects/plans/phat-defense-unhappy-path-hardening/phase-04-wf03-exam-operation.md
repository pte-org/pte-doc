# Phase 4: WF-03 tổ chức kỳ thi

**Owner gợi ý:** Phát · **Ưu tiên:** P1 · **Phụ thuộc:** phase 01 (và phase 07 cho audit publish)

## Overview

Server từ chối lưu bài và submit sau hạn, tự nộp attempt quá hạn; timer pte-app dùng giờ server; không publish được khi còn câu objective chưa có điểm và UI nêu rõ ai thiếu gì; gán lại class không kéo thêm học viên sau publish; ghi lại quyết định cho RF-18 và thêm CHECK cho RF-20.

## Spec stories covered

- P1: gửi `answers/save` và `submit` sau `examEndTime + grace` bị từ chối, timer app theo giờ server (FR-01, FR-02, 3-1, 3-2, 3-3).
- P1: Host không publish được kết quả thiếu điểm, UI liệt kê học viên, task type, lý do (FR-03, 3-8, DS-03d).
- P1: gán lại class không thêm học viên vào lớp sau publish (FR-15, 3-9).
- RF-18, RF-20 (Phát, quá hạn).
- Ngoài phạm vi, giữ nguyên: sửa lại câu đã qua trong bài thi (3-6), `AttemptAnswerRecorder` không đổi hành vi này.

## Files to modify/create

Đọc trước: `docs/CODING_STANDARDS_API.md`, `docs/CODING_STANDARDS_APP.md`, `docs/CODING_STANDARDS_WEB.md`, `docs/API_RESPONSE_SETUP.md`, `docs/COMMON_EXCEPTION_SETUP.md`. Đường dẫn dưới `pte-api/app/src/main/` trừ khi ghi khác:

- `java/com/pte/attempt/internal/service/AnswerSubmitService.java` (dòng 28-34 ghi "no server-side deadline") — kiểm hạn cho save và submit; xác minh nơi xử lý submit attempt trong `attempt/internal/service/`.
- `java/com/pte/attempt/internal/service/` — tạo lớp nhỏ tính hạn (examEndTime + grace, tôn trọng thời gian riêng của attempt nếu có) dùng chung cho save/submit/sweeper; lớp sweeper mới theo mẫu `session/internal/service/lifecycle/SessionAutoCloseWorker.java`.
- `java/com/pte/attempt/internal/constant/*Constants.java` — mã lỗi quá hạn, setting key grace (xác minh tên file).
- `resources/db/migration/V63__attempt_deadline_grace_and_incident_status_check.sql` — tạo mới (kiểm lại số): seed platform setting grace (mặc định 30 giây); CHECK trạng thái cho bảng incident (RF-20), kiểm dữ liệu hiện có trước khi thêm CHECK hoặc dùng `NOT VALID` rồi validate.
- `java/com/pte/proctoring/domain/ExamIncident.java`, `proctoring/internal/repository/ExamIncidentRepository.java` — đối chiếu tập trạng thái thực với CHECK; `AttemptEvidenceContextService.java` (3-7, gửi incident sau submit) chỉ ghi nhận, không bắt buộc sửa.
- `java/com/pte/reporting/internal/service/ReportPublishService.java` — thêm blocker `OBJECTIVE_NOT_SCORED`, trả danh sách chi tiết (học viên, task type, lý do).
- `java/com/pte/scoring/internal/service/review/ScoringReviewReadQueryService.java` (dòng 218-222 loại câu chưa điểm khỏi report) — cung cấp nguồn dữ liệu cho blocker qua public API của scoring; không cho reporting chọc internals.
- `java/com/pte/session/internal/service/audience/SessionClassSourceService.java` (dòng 73) — khi gán lại class vào exam SCHEDULED chỉ lấy học viên có mặt trong lớp trước thời điểm publish.
- Cho RF-18: nơi tạo attempt CREATED trong `attempt/internal/service/` và bước đóng session (`session/internal/service/lifecycle/SessionStateService.java`).
- pte-app: `pte-app/lib/core/network/api_client.dart` (đọc header `Date`, tính `serverOffset`), `pte-app/lib/features/exam_attempt/domain/timer_service.dart` (dòng ~78, 107 dùng `DateTime.now()`), `pte-app/lib/core/security/lockdown_service.dart` (dòng ~536-542 debounce), `pte-app/lib/core/sync/sync_engine.dart` (xử lý lỗi quá hạn từ server).
- tenant-web: `pte-web/apps/tenant-web/features/exams/components/ReportPublicationPanel.tsx` (dòng 53-58, 177) — hiện danh sách blocker; chuỗi chữ đặt trong file messages; giữ component dưới 150 dòng, tách component con.

## Implementation steps

1. Thêm tính hạn dùng chung (examEndTime + grace từ setting seed); save và submit trả lỗi nghiệp vụ khi quá hạn.
2. Thêm sweeper tự submit attempt quá hạn (đọc `Clock`, cùng đường submit để scoring ingest vẫn chạy), có test idempotent.
3. pte-app: tính `serverOffset` từ header `Date`, timer và debounce dùng đồng hồ monotonic, xử lý lỗi quá hạn trên màn hình thân thiện.
4. Thêm blocker `OBJECTIVE_NOT_SCORED` vào publish, kèm danh sách chi tiết; tenant-web hiển thị học viên, task type, lý do.
5. Sửa nguồn học viên khi gán lại class để không thêm người vào lớp sau thời điểm publish.
6. RF-18: quyết định bằng văn bản (đề xuất: ghi nhận vắng cho attempt CREATED khi đóng session thay vì rollback; nếu chọn giữ nguyên thì ghi lý do vào phase và báo cáo) rồi làm theo quyết định.
7. RF-20: migration CHECK trạng thái incident; xác minh dữ liệu cũ.

## Tests

Dưới `pte-api/app/src/test/java/com/pte/`:
- Tạo/mở rộng test `AnswerSubmitService` (`attempt/`): trong hạn lưu được, đúng ranh giới grace, sau grace bị từ chối; submit sau hạn.
- Test sweeper mới theo mẫu `session/internal/service/lifecycle/SessionAutoCloseWorkerTest.java`: tự nộp một lần, bỏ qua attempt đã nộp.
- Mở rộng `reporting/internal/service/ReportPublishServiceTest.java`: thiếu điểm objective bị chặn kèm danh sách; đủ điểm thì qua.
- Test `SessionClassSourceService` (xác minh test hiện có): student vào lớp sau publish không được thêm.
- Test migration CHECK (Postgres IT).
- pte-app: mở rộng `pte-app/test/unit/features/exam_attempt/timer_service_test.dart` và `pte-app/test/unit/core/security/lockdown_service_test.dart` (đồng hồ lùi không làm mất violation; offset được áp dụng); chạy `flutter test`.
- tenant-web: vitest cho `ReportPublicationPanel` hiển thị blocker chi tiết.
- Test hồi quy: sửa lại câu cũ trong bài thi vẫn được phép.

## Design Constraints

- Migration additive V63 (kiểm số cao nhất, hiện V60); setting grace seed cùng migration.
- Mã lỗi và thông điệp ở `*Constants.java` của `attempt`, `reporting`; giữ envelope/mã lỗi cũ; lỗi quá hạn là lỗi nghiệp vụ (4xx), không phải 500.
- Cross-module qua public service API: reporting đọc trạng thái điểm qua scoring public, session không đọc entity attempt.
- File ≤ 300 dòng, `internal/**` ≤ 15 lớp; `attempt/internal/service` có nguy cơ đầy, tách package con nếu cần.
- Mọi so sánh thời gian dùng `Clock` inject ở backend; app dùng offset + monotonic, không dựa `DateTime.now()` cho hạn.
- Không đổi hành vi sửa lại câu đã qua (3-6).
- Tuân `CODING_STANDARDS_APP.md` và `CODING_STANDARDS_WEB.md` cho phần client.
- Restart docker app local sau backend.

## Risks

- Mất bài hợp lệ khi lệch giờ hoặc mạng chậm: grace cấu hình được, đo 1 lần với giờ thật.
- Sweeper và submit tay đua nhau: dùng chuyển trạng thái có điều kiện và test idempotent.
- Thay đổi blocker làm Host cũ mắc kẹt: UI chỉ rõ cách xử lý (bấm Score) và thông điệp đúng.

## Quality and Testing State

- Quality gate: skipped_by_user (user_confirmed_skip)
- Testing: passed (2026-11-28: 221 backend tests + Flutter server_clock/timer/lockdown; 2 old tests moved to new contract; RF-20 CHECK added NOT VALID — VALIDATE after prod data check in phase 08)

## Todo

- [ ] Tính hạn + save/submit + constants + V63 seed grace
- [ ] Sweeper + test
- [ ] pte-app serverOffset + monotonic debounce + flutter test
- [ ] Blocker OBJECTIVE_NOT_SCORED + ReportPublicationPanel chi tiết + vitest
- [ ] FR-15 re-assign class
- [ ] RF-18 quyết định và ghi lại; RF-20 CHECK
- [ ] tsc/eslint cho tenant-web, ratchet architecture, restart docker
- [ ] Thử curl 3-1, 3-8, 3-9; đổi đồng hồ máy thử 3-2

## Bổ sung sau red-team (2026-11-27)

- **[H1] Hạn server không được làm mất bài hợp lệ ở DS-03b.** Quyết định ở mục Validation của plan.md. Ràng buộc chung:
  hạn = `examEndTime` của attempt (đọc field gia hạn riêng nếu có, phải xác minh field đó thật sự được đọc) + grace (setting, mặc định **120 giây**).
  Sweeper không tự submit khi session còn OPEN và attempt có `answers/save` trong vòng grace. Kịch bản DS-03b phải kết thúc mất mạng trước `examEndTime` ít nhất 5 phút (phase 08 kiểm).
- **[H4] Định nghĩa "chưa chấm" cho `OBJECTIVE_NOT_SCORED`:** chỉ câu objective **đã nộp, có payload, chấm được** mà chưa có điểm.
  Câu bỏ trống hoặc skip, attempt vắng mặt, và report đã publish trước thay đổi này không tính. Test hồi quy: session cũ đã chấm đủ thì vẫn publish được.
  UI: blocker hiện kèm nút "Chấm điểm" (gọi lại `POST /sessions/{id}/score`).
- **[M4] CHECK trạng thái incident:** dùng `ADD CONSTRAINT ... NOT VALID` rồi `VALIDATE CONSTRAINT` sau khi đã kiểm dữ liệu prod
  (`SELECT DISTINCT status`). Có giá trị lạ thì dừng và báo lại, không tự sửa dữ liệu.
- **[Gap] Header `Date` qua Caddy:** xác minh `curl -I` tới API công khai có header `Date`. Nếu không có, trả `serverTime` trong response start/resume attempt.
