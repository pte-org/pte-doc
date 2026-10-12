# Codebase audit — Examiner completion

Ngày: 2026-10-12. Đối chiếu source hiện tại; không kiểm kê database thật hoặc chạy tests trong bước lập kế hoạch.

## Framework và conventions

- Backend: pte-api/app, Java21, Spring Boot4.0.5, JPA/JDBC/Postgres/Flyway; domain `com.pte.scoring`, public facades cho module boundary; DTO request/response public trong scoring/dto. Không import repository nội bộ module khác.
- Web: pte-web workspace, tenant-web Next16.2.9 App Router, React19, TanStack Query5; common @pte/ui và typed @pte/api-client. Routes dưới `app/(dashboard)/examiner`, feature `features/examiner`, sidebar `lib/navigation.tsx`.
- Backend tests: JUnit/Mockito, repository/database integration tests hiện có. Web/api-client Vitest; tenant Vitest hiện Node environment. Scripts: turbo dev/build/lint/test; tenant next build/eslint/vitest; typecheck dùng installed tsc.
- AGENTS web yêu cầu common UI, không override visual defaults, locale copy, thin routes, function<150 lines/file<300 lines. Các file lớn hiện hữu cần tách theo trách nhiệm khi thay đổi.

## Bảng hiện trạng

| Chức năng | Đã có / thiếu / lỗi | Bằng chứng source và file cần sửa | Migration / rủi ro |
|---|---|---|---|
| Sidebar | Đã có 4 mục query-aware, thiếu Resources thực sự | lib/navigation.tsx, lib/navigationConstants.ts, features/auth/utils/resolveActiveNavItem.ts | Không schema; giữ fromStatus/fromPage và Host Classes override |
| Overview và queue | Trùng nội dung: cùng view luôn render overview+priority+queue | features/examiner/ExaminerQueueView.tsx, ExaminerWorkView.tsx, work/page.tsx | Không migration riêng; tách views, không nhân bản datafetch |
| Thống kê | Counts/progress/priority/asOf có sẵn; scope unpublished | ExaminerWorkspaceQueryService, ExaminerWorkspaceReadRepository, ExaminerWorkspaceOverviewResponse | Q3 quyết định scope; phải cùng predicate list/counts |
| Pending/In Progress/Completed | Có list/status/paging; status suy từ số final scores, chưa explicit start | ExaminerWorkQueueRepository, ExaminerWorkspaceReadRepository, ExaminerQueueItemResponse | Work-state additive; tránh drafts làm bài Completed |
| Phân công | Một Examiner nguyên attempt, immutable assignment | ExaminerAttemptAssignment, ExaminerAssignmentService, V58–62 | Không mở multi-rater/partial ownership trong refactor |
| Bắt đầu chấm | Thiếu API và persistent started state | ExaminerWorkController, service mới theo trách nhiệm, api-client/requests/scoring/examiner.ts | Work row/start receipt; GET không mutation |
| Prompt/response/media | Có safe DTO, audio/text/options và presign | ExaminerScoringService.getAttempt, AnswerContentRenderer, AttemptExaminerPromptQueryService | Reuse public Attempt/Media; retry presign không mất draft |
| AI-assisted decision | Có CONFIRM_AI/MANUAL, version/hash/receipt, điểm0–100 | ExaminerReviewVersionService, DecisionPanel, AiReferencePanel | Giữ pinned eligibility và reviewVersion, không mặc định accept AI |
| Nháp/comment | Draft React state; không reload-safe, chưa comment persisted | useExaminerSubmissions.ts, ExaminerAttemptDetailView.tsx, DTO/hooks mới | Separate draft table/version; draft không final source |
| Chốt điểm | Có per-answer immutable score, chưa whole-attempt finalize | ExaminerScoringService.submitScore, ExaminerAnswerScore, ScoreSourceSelectionService | Q1: additive work+receipt; giữ score cũ, transactional finalize |
| Rubric/guidelines | Có pinned scoretemplate method/weights; chưa criteria/bands/conversion | ScoringMethodResolver, ScoreTemplateItemResponse, restricted projection mới | Q2; không seed rubric giả hoặc load active template thay pinned |
| Completed sau publication | Queue/detail chặn published | ExaminerScoringService.getAttempt, read repositories | Q3; read-only history projection, tuyệt đối giữ write guard |
| History | Chưa history Examiner riêng | new grading event/read DTO/API; Resources page mới | Append-only own assignment; không mở tenant-wide AuditLogService.list |
| Issue/reopen | Chưa Examiner flow; Support chỉ HOST_ADMIN/Admin | HostSupportTicketController; new own issue API nếu Q4 chọn | Q4; role-safe reporting/Host resolution, không tự reopen finals |
| Host công bố | Có cohort/source/readiness/report publication | ReportPublishService, scoring/ScoringService, source selection | Draft/new work chưa finalized không được vượt publish readiness |
| Loading/error | Overview có trạng thái nguồn; detail header default0 trước success, copy/hardstyled controls cần chuẩn hóa | ExaminerAttemptDetailView, ExaminerAttemptHeader, messages/en.ts/vi.ts | No schema; giữ stale-success data và safe error mapping |
| Search/sort/filter | Queue chỉ status/session/page/size | ExaminerWorkController.list, read repository, queue API/hook/view | Whitelist safe IDs/date/task supported; filter trước paging; không deadline giả |

## Dữ liệu và compatibility cần kiểm kê trước thay đổi

Chỉ inventory read-only trước migration/backfill: no/partial/all final scores; eligibleAnswerCount so với pinned actual pool; published/unpublished; cohort-less/manual/AI_ONLY; excluded members; missing owner references. Không giả định môi trường không có dữ liệu cũ.

V95 lưu decision metadata/receipts, V96 legacy alignment. V97 là migration attendance chưa commit của người dùng; chọn migration Examiner kế tiếp còn trống lúc triển khai, không sửa migration applied hoặc attendance.

Backfill không viết lại ExaminerAnswerScore/Report snapshot. Giữ unknown startedAt/actor khi không có bằng chứng. Phân biệt assignment/work/question/publication states. Rollback ứng dụng bảo toàn bảng additive và dữ liệu chấm mới; không cho client cũ bypass completion bằng endpoint per-answer trong workflow mới.

## Phạm vi ổn định và phụ thuộc quyết định

Q1–Q4 đã được trả lời và ghi trong spec: durable drafts, atomic assigned-scope finalization, giữ scalar0–100, published Completed/History và Host-resolved issues, chưa reopen. Source audit phục vụ kế hoạch; chưa triển khai source trong bước audit này.

Hai research report kèm source cụ thể và lựa chọn alternative: research-primary.md, research-alternative.md. Những giới hạn source-only được giữ nguyên, không khẳng định runtime production đã được kiểm thử.
