# Phase 06: durable jobs, recovery, retries và budget

Status: planned. Dependencies: 04,05; D08 budget/retry/retention approval trước enable. Stories: US-06, US-07, US-09. Requirements: PR-07,08,10,13.

## Work packages

1. Default đề xuất on-demand: submit commit immutable response/evaluation/evidence và AI readiness; explicit POST explanation tạo logical job **cùng transaction** với outbox và atomic budget reservation. Không bắt mỗi bài nộp gọi Gemini. Auto-generation là policy riêng chỉ bật sau approval. GET result/explanation thuần read, không tạo job, retry hay budget reservation.
2. Unique database key trên explanation fingerprint canonical, độc lập `Idempotency-Key` header. Thêm DB-unique resolver slot `(owner,context,immutable_submission_revision,language,generation_sequence)`, default sequence=0, độc lập active model/prompt. Atomically reserve/read slot trước policy lookup; winning transaction freeze bundle + reservation + outbox, loser trả cùng request. Slot tồn tại cả khi WAITING_EVIDENCE; fingerprint hoàn tất sau khi derived artifacts được pin. Header cùng key khác payload phải conflict. Job foreign owner không lộ tồn tại qua error detail.
3. State machine theo normative contract: WAITING_EVIDENCE (nếu cần) → QUEUED → RUNNING → AVAILABLE; nhánh RETRY_WAIT/FAILED/CANCELLED. Readiness NOT_REQUESTED/UNAVAILABLE/BUDGET_LIMITED, coverage FULL/LIMITED/NOT_ASSESSABLE và failure category/canRetry/cooldown là fields độc lập, không thêm chúng thành job states. Submission state độc lập. Attempts lưu riêng; retry giữ slot/identity. Explicit regeneration cấp sequence mới, reason/role/version lineage và budget mới, giữ explanation cũ.
4. DB job/outbox là durable truth. Dispatcher scheduled tìm committed undispatched jobs, publish với delivery confirmation, idempotent consumer. Rabbit down sau commit không mất việc. Worker claim bằng compare-and-set/lock + lease token/fencing generation; heartbeat nếu workload cần; reclaim expired lease theo bounded retry policy. Scheduler recovery không phụ thuộc Host mở scoring hoặc Student revisit.
5. Accept result transaction kiểm tra job identity, active fencing token, attempt state, schema/evidence validation và chưa có canonical accepted result; persist immutable explanation + transition + reservation settlement. Late response stale worker bị discard; không overwrite dù model trả thành công. Crash giữa provider call và save có thể gọi lại và tính phí thêm; chỉ bảo đảm một result được accept, không hứa exactly-once provider call.
6. Error taxonomy: credential/model/config lỗi → terminal và ops alert; 429/timeout/temporary 5xx → bounded backoff+jitter/Retry-After, global deadline, attempt cap; invalid semantic output → limited bounded correction trong cùng cap nếu approved. Cancel/retired policy không xóa submitted evidence. No infinite resubmission loop từ frontend polling.
7. Atomic budget reservation theo owner/context/day và deployment/project aggregate; account shared key/quota với exam workload. Reservation trước dispatch, đồng thời kiểm tra concurrency và estimated input/output limits. Attempts tính usage để retry không bypass cap; uncertain billing/timeout giữ conservative usage ledger, release unused reservation theo policy. Ops knobs pause new generation, disable model/prompt version, reconcile orphan reservations, retry controlled. Không làm submit phụ thuộc AI quota.
8. Observability: queue age, lease expiry, retries, failure category, validation rejects, usage/cost estimate, dedup ratio, accepted/discarded late response, outbox backlog. Correlation IDs không gồm raw answer/key. Alert thresholds/config values là proposal cần chốt; tham khảo 45s/call,120s/job,3 total attempts và verify workload/quota trước enable.
9. Default POST cho cùng submission/language phải tìm canonical existing request **trước** đọc active prompt/model policy hiện tại. First accepted request freeze prompt/model/schema/config/language; policy upgrade không tự tạo job mới cho old answers. New-language request hoặc regeneration là explicit action có reason/quyền/lineage, không xảy ra vì refresh hoặc config drift. Unique full identity không đủ nếu mỗi POST tự tính key bằng active config mới.
10. Job input pin derived transcript/assessment artifact revision/hash + assessor policy/version/config. `WAITING_EVIDENCE` có bounded deadline và scheduled recovery độc lập; hết hạn → `NOT_ASSESSABLE` có lý do, không infinite retries. Không re-ASR trong explanation retry; revised artifact là explicit new evaluation lineage.

## Proposed files

Practice-owned explanation job/attempt/outbox/reservation entities/repositories/services + scheduled dispatcher/worker and Rabbit configuration theo existing app patterns. `scoring/internal` existing `AiScoringDispatcher` chỉ là nghiên cứu, không kéo Host-triggered recovery sang practice. Flyway additive tables/indexes/unique constraints/lease fields, approved transaction boundary and constants.

## Failure paths / tests to consider

20 concurrent identical POST khác header → một logical job; hai first POST qua thời điểm policy activation khác nhau vẫn một default resolver slot/request/reservation/outbox; same key different payload; DB commit rồi Rabbit down; duplicate message; crash trước/sau provider call; expired lease + stale successful response; failed validation; cross-owner job lookup; quota race; retries vượt budget; worker restart không có Host revisit; GET 20 lần → zero calls. Recovery target 2 configured reconciliation cycles. Đây là coverage đề xuất.

## Design Constraints

Request authorization dùng current entitlement; historical GET theo D08 và owner/context, không tự tạo generation. Lease/fencing và unique accepted result phải enforcement DB/transaction, không chỉ in-memory lock. Budget/quota global không thể chỉ check UI hoặc count query rời transaction.

## Exit criteria

Recovery/idempotency/budget invariants có implementation evidence; one accepted result, no overwrite; AI unavailable vẫn đọc được bài/result. Không mô tả cached reads là bằng chứng model deterministic.

## Quality and Testing State

Quality: not evaluated. Testing: not started. TDD chưa chọn; khuyến nghị mạnh concurrent DB integration/fault scenarios khi được chọn. Cook xác nhận optional test/quality; compile/standards checks bắt buộc khi code.
