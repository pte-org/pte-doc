# Phase 09: reports, runbook và coordinated release staging

Status: planned. Dependencies: 08, approval của product/academic/ops. Stories: US-09, US-10; traceability toàn scope.

## Work packages

1. Cập nhật Report 3 requirement/business rule, Report 4 schema/API/sequence, Report 5 actual test scope/evidence, Report 6 Student/academic/operator instructions. Giữ tên đề tài và template mục lục gốc; phân biệt implemented/verified/proposed/deferred. Cập nhật DOCX bằng generator sau Markdown stable, kiểm ZIP/XML/metadata/logo/TOC và kiểm trực quan Word/PDF nếu tool khả dụng; không claim visual review từ ZIP check.
2. Runbook config: Practice Gemini enable/model/prompt/schema version, direct-run vs Compose mapping `GEMINI_API_KEY`→`SCORING_AI_GEMINI_API_KEY`, timeouts/attempt caps/global concurrency/budget/reconciliation intervals/retention policy. Chỉ tên biến/placeholders, không real secrets. Check startup không yêu cầu Azure khi practice Gemini enabled và exam provider khác.
3. Migrations rollout additive: backup/restore plan; new rubric/flags/snapshots/jobs tables/indexes; safe legacy pool backfill; deploy compatible backend; migrate exam/practice consumers; verify readiness/permissions; deploy vendor UI và practice UI; enable limited cohort; monitor; wider enable sau approvals. Không drop old pool/DTO fields trong same rollout nếu client compatibility chưa proven.
4. Content activation: publish approved rubric/reference/content fixtures theo task, flags theo release scope; cả hai channels true chỉ sau explicit academic disclosure/approval. D01 task selection là release gate. Không đánh dấu toàn product completed khi một committed task còn unsupported/content-empty.
5. Operations: pause new AI generation mà vẫn đọc stored results; handle invalid key/quota spikes/broker backlog/expired leases/orphan reservations; replay outbox và controlled retries có audit; inspect late response rejection; model/prompt retirement/re-evaluation. Do not reveal answers in health metrics/logs. Restore storage không overwrite current response evidence.
6. Rollback theo layers: disable new generation, dừng dispatcher admission nhưng giữ reads; frontend rollback compatible DTO; backend rollback chỉ khi schema tương thích; preserve submissions/job/explanations/keys ownership; không destructive down-volumes hoặc xóa lịch sử để “fix”. Migration rollback phá dữ liệu cần explicit authorization, không suy từ plan này.
7. Coordinated release record: exact commits per repo, standards read, compile/build outputs, selected tests/quality findings, academic approvals, model actual/requested versions, synthetic smoke evidence, decision log, remaining limits và owner. Commit groups explicit paths sau user authorization; push/deploy là bước riêng cần instruction thực tế. Plan không tự cấp quyền production writes.
8. Trước release staging, đọc actual deployment workflows/Compose/edge configuration cho backend, web và practice; source hiện tại có nginx/practice deployment cần đối chiếu. Không suy topology từ AGENTS snapshot Caddy cũ. Ghi actual routes/health/readiness/deployment ownership rồi mới đề xuất thứ tự rollout; không tự chuyển reverse proxy theo documentation cũ.

## Proposed files

`pte-doc/report/report03..report06` và `report/docx` nếu cần publication; relevant README/config examples theo app conventions; canonical release/runbook report dưới `pte-doc/plans/reports/`; plan status và decision log. Source changes ngoài config/runbook chỉ khi một gap cụ thể được review, không mở thêm feature scope ở phase này.

## Failure paths / checks to consider

Old client/new backend flags mismatch; migration duplicate numbers; stale rubric binding; feature enabled trước content; provider invalid key; direct-run không đọc mapped env; rollback frontend incompatible; pool old writer làm sai flags; budget reset/reservation leak; media retention mất review recording. Deployment dry-run/config validation phải không print secrets. Chưa chạy lệnh release.

## Design Constraints

Production deployment/merge/push không authorized từ việc lập plan. Không gọi package submission-ready nếu DOCX chưa được visual review như yêu cầu nộp. Retention theo hợp đồng/approved policy, không tự thêm số năm. Không đổi tên PTEPrep registered title.

## Exit criteria

Reports/runbook khớp implementation đã verified, remaining decisions không ảnh hưởng enabled features; evidence và approvals truy vết được; migration/rollback compatibility rõ; release checklist có owner. Chỉ đánh achieved khi action đã làm có bằng chứng, staging plan không đồng nghĩa deployment xong.

## Quality and Testing State

Quality: not evaluated. Testing: not started. Optional review/check choices do cook xác nhận; bắt buộc config/compile/build gates theo standards trước release claim. Live production verification chưa có và chỉ thực hiện khi user yêu cầu riêng.
