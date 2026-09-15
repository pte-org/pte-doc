# Phase 07 — Attempt ★

**Plan:** [plan.md](plan.md) · [kế hoạch tổng hợp](remaining-modules-refactor-plan.md) · **Spec:** [spec.md](spec.md)
**Covers:** Luồng thi đầu-cuối, pinned snapshot, answer submission
**Nguồn:** `services/exam-delivery` (83 file)
**Đích:** `com.pte.attempt`

---

## Mục tiêu

Đưa state machine thi vào monolith và đạt mốc demo quan trọng nhất:

```text
session OPEN → start/resume attempt → pin đề → play/answer → submit attempt
```

Sau khi tạo attempt, dữ liệu đề phải tự chứa trong pinned snapshot; request của student
không được gọi lại session, assessment hoặc media để lấy nội dung đề.

---

## Design Constraints

- Dependency: `attempt → session`, `assessment`, `media`, `shared`.
- Một student chỉ có attempt hợp lệ theo session; duplicate start giữ semantics
  resume/reject của source.
- Giữ optimistic version, pessimistic lock ở các đường mutate current item/play
  count/complete và idempotency của play request.
- Pinned snapshot là bản copy riêng của attempt; assessment source đổi sau đó không
  ảnh hưởng attempt đang thi.
- Flow tạo attempt gọi đúng một lần:
  `SessionService.checkEntitlement` → `AssessmentService.getFullContent` →
  `MediaService.presignGet` → lưu pinned graph.
- Plain answer chỉ cho STANDARD; encrypted answer chỉ cho STRICT; private key không
  được phơi qua response.
- Giữ client-side timer semantics hiện có: heartbeat là presence signal, không tự
  khôi phục deadline bằng projection/catch-up loop.
- `AttemptAnswer` là dữ liệu canonical của attempt. Scoring chỉ nhận application
  event/work handoff, không tạo `AnswerProjection` chung cho reporting.
- Public `AttemptService.forceSubmit(attemptPublicId, tenantId)` phải đủ cho
  proctoring gọi mà không mở repository.
- Không port outbox, relay, `ProcessedEvent`, export controller hoặc
  `ProctorCommandConsumer` vào app.

---

## Việc cần làm

1. **Port domain**
   - Port `ExamAttempt`, `AttemptAnswer`, `AttemptHeartbeat`,
     `PinnedExamSnapshot`, `PinnedItem` và enum/status.
   - Giữ quan hệ cascade, unique constraint, answer integrity, timing fields,
     media URL expiry và public ID.

2. **Port services**
   - Port `AttemptService`, `AnswerSubmitService`, `HeartbeatService`,
     `TimerService`, `SnapshotPinService`, `SubmissionDecryptionService`,
     cache và mapper.
   - Giữ mọi domain exception và status code.
   - Giữ `saveAndFlush`/lock ở những chỗ source cần generated timestamp hoặc
     chống concurrent update.

3. **Thay HTTP clients**
   - `SchedulingClient` → public Session entitlement API.
   - `AuthoringClient` → public Assessment full-content API.
   - `MediaClient` → public Media presign API.
   - Xóa internal service auth/key khỏi code app; giữ chúng trong service nguồn đến
     Phase 11 nếu còn dual-run.

4. **Giữ pin semantics**
   - Áp composition theo task type, timing override và max play count.
   - Resolve audio duration/image URL, grace period và URL expiry như source.
   - Reject missing prompt, empty snapshot, entitlement lỗi và device check chưa pass.

5. **Application events**
   - Sau answer submit, phát payload bất biến để scoring tạo work state.
   - Sau attempt submit, phát lifecycle event cho reporting/notification.
   - Event không được dùng để dựng projection; scoring/reporting phải sở hữu dữ liệu
     của chính module mình.

6. **Flyway**
   - Viết `V9__attempt.sql` cho attempt, answer, heartbeat, pinned snapshot/item.
   - Không tạo bảng outbox/processed event/projection.

---

## Tests to Write First

- Start attempt cần session OPEN và enrollment; duplicate start resume/reject đúng
  status.
- Pin đề deep-copy đúng snapshot, composition và timing; source đổi không ảnh hưởng.
- Missing audio/image, thiếu duration, presign lỗi và expired URL.
- Device check, STANDARD/plain và STRICT/encrypted boundary.
- Submit sai current task, duplicate answer, empty answer và completed attempt.
- Replay limit, duplicate playRequestId và concurrent play/answer/complete.
- Heartbeat create/update và first-insert race không làm hỏng transaction chính.
- Student ownership, tenant isolation và force-submit stale/no-op.
- End-to-end từ session OPEN đến attempt submit.

---

## Acceptance

- [ ] Luồng thi đầu-cuối chạy hoàn toàn trong app.
- [ ] Sau khi pin, attempt không còn gọi HTTP/client sang module khác.
- [ ] Plain/encrypted answer không thể dùng sai integrity level.
- [ ] Pinned snapshot immutable và media URL có TTL/duration đúng.
- [ ] Application event answer/attempt không tạo projection chung.
- [ ] `V9__attempt.sql` chạy được trên Postgres monolith.
- [ ] Test exam-delivery nguồn và test app xanh.
- [ ] `ApplicationModules.verify()` pass.

---

## Quality and Testing State

Chưa thực thi. Đây là phase cần ưu tiên quality gate và smoke test cao nhất vì là
mốc demo end-to-end trước khi bắt đầu Scoring.
