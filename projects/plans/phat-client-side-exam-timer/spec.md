# Spec: Client-side exam timer — bỏ server-side per-task polling/enforcement

**Date:** 2026-09-07
**Status:** Ready

---

## Problem Statement

`pte-api`/`pte-app` hiện dùng cơ chế server-authoritative timer: mỗi task có `prepDeadline`/`responseDeadline` lưu trong Postgres, client poll `GET /attempts/{id}/timer` mỗi 10s để đồng bộ đồng hồ, và mọi lần nộp bài server so `Instant.now()` với deadline trước khi chấp nhận. Cơ chế này tồn tại để chống gian lận (thí sinh tự ý điều khiển thời gian), nhưng đã gây chi phí thật (request liên tục, 2 bug đã phát sinh — xem [refactor_polling.md](../../../research/refactor_polling.md)) trong khi động cơ gian lận ban đầu không còn áp dụng cho 2 kênh bán hàng thực tế của sản phẩm (B2C tự luyện tại nhà; B2B bán cho tổ chức cấp bằng có giám thị + máy kiosk khóa OS). Cần đơn giản hóa bằng cách chuyển toàn bộ việc đếm giờ/tự động chuyển task về client, giữ nguyên cấu trúc thời lượng per-item đúng như đề PTE thật.

---

## User Stories

- **[P1]** Là thí sinh luyện tập, tôi muốn đồng hồ prep/response và việc tự chuyển câu (phát audio → ghi âm → dừng → next) chạy mượt trên máy tôi mà không phụ thuộc vào 1 request nền định kỳ, để việc ghi âm bắt đầu đúng lúc, không bị trễ do chờ poll.
  Accepted when: `TimerService` (pte-app) tính và điều khiển toàn bộ chuyển pha prep→response chỉ từ `prepSeconds`/`responseSeconds`/`preListenSeconds`/`preRecordSeconds` nhận 1 lần lúc task bắt đầu — không còn gọi mạng tới bất kỳ endpoint timer nào.

- **[P1]** Là người bảo trì backend, tôi muốn `AttemptService` không còn phải so sánh thời gian nộp bài với deadline lưu sẵn, để logic khóa task đơn giản hơn và bớt 1 lớp bug desync.
  Accepted when: `TimerState` (entity + bảng `timer_states`), `isResponseWindowExpired`, và đoạn check grace-window bị xóa khỏi `AttemptService.processAnswer`; `TimerController`/`GET /attempts/{id}/timer` bị xóa.

- **[P1]** Là người triển khai tính năng giám sát kết nối thí sinh (brainstorm song song), tôi muốn có 1 tín hiệu heartbeat độc lập với timer/deadline, để việc xóa `/timer` không phá tính năng đó.
  Accepted when: tồn tại 1 endpoint heartbeat mới (vd `POST /attempts/{id}/heartbeat`), tách hoàn toàn khỏi mọi dữ liệu deadline/countdown, được pte-app gọi định kỳ trong suốt lúc attempt `IN_PROGRESS` — kể cả giữa lúc đang làm 1 task dài (không bị `SyncEngine`-style active-task exclusion).

- **[P2]** Là product owner, tôi muốn việc xóa là xóa hẳn (không giữ feature-flag bật/tắt theo gói) theo đúng quyết định đã chốt, chấp nhận đánh đổi phải làm lại nếu sau này có khách B2B không đáp ứng điều kiện khóa kiosk.
  Accepted when: không có cờ cấu hình nào điều khiển việc bật/tắt lại `isResponseWindowExpired`/`TimerState` — code enforcement bị xóa thẳng khỏi codebase, không đứng sau flag.

- **[P3]** _(ngoài phạm vi)_ Thay đổi cơ chế mã hóa payload STRICT (`submitEncryptedAnswer`) — không liên quan tới refactor này.

---

## Functional Requirements

1. FR-01: `TimerService` (pte-app) tính và điều khiển toàn bộ countdown + auto-advance (phát audio → ghi âm → dừng → next) hoàn toàn từ `prepSeconds`/`responseSeconds`/`preListenSeconds`/`preRecordSeconds` trả về 1 lần trong response lúc task bắt đầu — không poll bất kỳ endpoint timer/deadline nào.
2. FR-02: Xóa `GET /attempts/{id}/timer` (`TimerController`), `TimerState` (domain + bảng `timer_states`), và toàn bộ logic poll định kỳ + one-shot poll trong `TimerService` (pte-app). **Điều kiện tiên quyết bắt buộc** (phát hiện qua research, không phải giả định ban đầu): `TimerState` hiện đang giữ cả `currentOrderIndex` (con trỏ task hiện tại — nền tảng của `NotCurrentTaskException`, phải giữ nguyên theo FR-03) lẫn `playCount`/`lastPlayRequestId`/`lastPlayAllowed` (giới hạn phát lại audio trong `playAudio`) — hai nhóm state này **không liên quan gì tới deadline** nhưng chưa có chỗ nào khác để tồn tại (`ExamAttempt` hiện không có field tương ứng). Phải di dời 2 nhóm state này sang `ExamAttempt` (hoặc 1 entity gọn mới) **ở 1 commit riêng, đứng trước** commit xóa `TimerState` — không được gộp chung, nếu không sẽ phá `getNextTask`/`processAnswer`/`playAudio` chứ không chỉ phá timer.
3. FR-03: `AttemptService.processAnswer` không còn gọi `timerService.isResponseWindowExpired(timer)` / áp dụng grace 15s trước khi chấp nhận answer — việc chấp nhận dựa trên trạng thái task (còn là current item hay không, `NotCurrentTaskException`), không dựa trên so sánh giờ server với deadline lưu sẵn.
4. FR-04: Thêm 1 endpoint heartbeat mới, tối giản, tách khỏi mọi dữ liệu timer/deadline (vd `POST /attempts/{id}/heartbeat`), pte-app gọi **mỗi 15 giây** trong suốt lúc attempt `IN_PROGRESS` — kể cả trong lúc đang làm 1 task đang active (không bị loại trừ như `POST /answers` qua `SyncEngine`) — chỉ để cập nhật tín hiệu "còn sống" phục vụ tính năng giám sát kết nối (brainstorm song song, ngưỡng phát hiện 45-60s → margin ~3 nhịp).
5. FR-05: Đóng phiên thi tổng thể (`POST /attempts/{id}/submit`) do client tự quyết định kích hoạt — khi đồng hồ tổng local hết giờ, hoặc thí sinh bấm force-submit — không còn bị chặn/enforce bởi deadline phía server.
6. FR-06: Thời lượng riêng từng câu/section (`prepSeconds`, `responseSeconds`, `preListenSeconds`, `preRecordSeconds`, deadline dùng chung cho cả section Reading) tiếp tục được server tính và trả về đúng như hiện tại — không đổi.
7. FR-07: Khi countdown local của 1 task về 0 mà chưa có answer nào, client **tái dùng `POST /attempts/{id}/answers` hiện có với payload rỗng/null** — không thêm endpoint mới. Backend cần chấp nhận payload rỗng như 1 answer hợp lệ (coi như bỏ trống), tận dụng nguyên logic advance/khóa task đã có trong `processAnswer`. **Rủi ro cụ thể đã xác nhận qua research**: `SubmitAnswerRequest.payload` hiện đang gắn `@NotBlank` (Bean Validation) — request rỗng sẽ bị chặn 400 trước khi chạm tới `processAnswer`. Ràng buộc này bắt buộc phải được nới (bỏ `@NotBlank`, hoặc cho phép 1 giá trị sentinel rỗng) như 1 phần của việc implement FR-07, không phải chi tiết phụ.
8. FR-08: `AttemptService.advanceUntilLiveOrComplete` (vòng lặp catch-up dựa-trên-deadline) bị **xóa hẳn** — không còn deadline nào ở server để "bắt kịp"; `currentItem` chỉ còn tiến theo đúng thứ tự answer đã nộp (kể cả answer rỗng từ FR-07).

---

## Non-Functional Requirements

- Performance: loại bỏ ~1 request/10s cho mỗi attempt đang `IN_PROGRESS` toàn hệ thống (heartbeat poll cũ); thay bằng heartbeat mới (FR-04) ở nhịp thưa hơn, cần chốt cụ thể ở `/ck:plan`.
- Security: không suy giảm ở kênh B2C (tự luyện, gian lận chỉ hại chính thí sinh); ở kênh B2B chỉ đúng **với điều kiện** máy thi của tổ chức thật sự bị khóa OS (kiosk mode) — điều kiện này nằm ngoài phạm vi code, cần là yêu cầu triển khai/hợp đồng.
- Compatibility: `submitEncryptedAnswer`/tầng tích hợp STRICT, `NotCurrentTaskException`, `AttemptAlreadyCompleteException`, và toàn bộ outbox local-first (`SyncEngine`, `AnswerOutboxDao`) không bị ảnh hưởng bởi refactor này.

---

## Success Criteria

- [x] Không có request nào tới endpoint timer/deadline từ pte-app trong suốt 1 lượt làm bài đầy đủ (kiểm chứng qua network log hoặc test). **Xác nhận (2026-09-08, Phase 7)**: đi bộ thủ công thật trên local stack (docker compose, DB reset sạch, seed-e2e.ps1) — app Windows desktop thật, không phải mock — network log của `exam-delivery` cho thấy 0 request `/timer` trong toàn bộ phiên (start → 6 heartbeat → submit).
- [x] `TimerState`, bảng `timer_states` (kèm migration drop), `TimerController` bị xóa khỏi `exam-delivery`; `AttemptService.processAnswer` không còn đoạn so deadline nào. **Xác nhận (Phase 5, re-verify Phase 7)**: cả 3 lớp bị xóa hẳn khỏi source; DB fresh-reset xác nhận `exam_delivery` schema không hề có bảng `timer_states` (Hibernate không bao giờ tạo lại vì entity đã xóa). Kịch bản drop cho một DB production có sẵn bảng cũ đã sẵn sàng ở `phase-06-runbook.md` (chưa cần chạy thật vì chưa có production).
- [x] Cả 5 màn hình audio-prompt Speaking (Repeat Sentence, Retell Lecture, Answer Short Question, Respond to a Situation, Summarize Group Discussion) vẫn qua được test hiện có sau khi `TimerService` được viết lại chạy hoàn toàn local (điều chỉnh test theo quy ước đã có ở `timer_service_test.dart`, không nhất thiết giữ nguyên). **Xác nhận (Phase 7)**: chạy riêng cả 5 file test — 39/39 pass.
- [x] Endpoint heartbeat mới tồn tại và được ghi nhận là dependency mà spec/plan của tính năng giám sát kết nối phải trỏ vào, thay vì `/timer`. **Xác nhận**: `260907-attempt-connectivity-monitoring-brainstorm.md` đã cập nhật (từ brainstorm ban đầu + đóng vòng lặp nhịp gọi 15s ở Phase 7); network log Phase 7 xác nhận endpoint hoạt động thật với cadence 15s trên app thật.

---

## Out of Scope

- Thay đổi cơ chế mã hóa payload / tầng tích hợp STRICT.
- Ngưỡng phát hiện/giao diện của tính năng giám sát kết nối — spec này chỉ chịu trách nhiệm cung cấp endpoint heartbeat dùng chung.

## Migration cho attempt đang `IN_PROGRESS` tại thời điểm deploy

Đã nghiên cứu và chốt qua research của `/ck:plan` (không còn để ngỏ): **quét/drain trước deploy** — trước khi cutover, chặn deploy trừ khi số attempt `IN_PROGRESS` gần 0 (khả thi cho B2B vì phiên thi có giờ giấc cố định — lên lịch deploy ngoài giờ thi), số còn sót lại (nếu có) được đẩy qua thẳng `completeAttempt()` (cơ chế idempotent-safe đã có sẵn, dùng chung với `submitAttempt`) để chuyển sang `SUBMITTED` với answer hiện có, rồi mới xóa bảng `timer_states`. Đã cân nhắc và **bác** phương án "compatibility shim theo sự tồn tại của row `TimerState`" (giữ song song 2 luồng enforcement cũ/mới) — vi phạm trực tiếp Success Criteria (đòi xóa sạch `TimerState`) và tái tạo đúng lớp bug desync mà [refactor_polling.md](../../../research/refactor_polling.md) đã ghi nhận.

---

## Assumptions

- Hai kênh bán hàng hiện tại (B2C tự luyện; B2B bán cho tổ chức cấp bằng có giám thị + máy kiosk khóa OS) đúng như mô tả — nếu xuất hiện kênh thứ 3 không thuộc 2 dạng này (vd thi thật không giám sát, trên thiết bị không kiểm soát), tiền đề của spec này cần đánh giá lại trước khi áp dụng.
- Report brainstorm giám sát kết nối ([260907-attempt-connectivity-monitoring-brainstorm.md](../../../.claude/plans/reports/260907-attempt-connectivity-monitoring-brainstorm.md)) đã được cập nhật để trỏ vào endpoint heartbeat mới (FR-04, nhịp 15s) thay vì `/timer`/`POST /answers`.
