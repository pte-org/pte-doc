# Plan: Tenant Exam Staff workspace

**Date:** 2026-10-10
**Status:** Implementation completed — Phases 01–07 quality approved; manual/runtime validation pending
**Mode:** ck:plan --hard
**Scope:** pte-api, pte-web, pte-doc
**Related:** [brainstorm](brainstorm.md), [spec](spec.md)

## Objective

Host xem hồ sơ Proctor/Examiner và theo dõi phân công, tiến độ theo ca thi. Reuse phần trình bày Learner qua common; không biến Host thành workspace chấm bài của Examiner.

## Scope challenge / Spec quality

- Có một phần: staff list/account modal, session assignment, Examiner personal queue, Learner profile. Chưa có staff inverse schedule/progress projection và detail route.
- Minimum: same-tab profile, role-aware overview/work tabs, read-only tracking, account edit whitelist và actions hiện có.
- Hard: nhiều repository/module, authorization, aggregate/pagination và common migration.
- Spec có P1/P2 stories và acceptance kiểm chứng được. Người dùng đã xác nhận ba quyết định sản phẩm; Phase 01 vẫn phải đóng băng contract kỹ thuật trước code.
- UX đã được thảo luận và chọn hướng; không dựng mockup/đổi style trong lượt này.

## Source evidence (khảo sát tĩnh)

| Source | Ràng buộc |
| --- | --- |
| pte-web/features/studentDetail | Có shell/header/account presentation; chứa Student-specific DTO/mutation, cần tách trước reuse |
| pte-web/features/examStaff | Modal cũ, role/status filter và send credential email action |
| identity/UserService | Student PATCH chỉ nhận Student; cần staff-specific mutation |
| session/ProctorAssignment | Một assignment mỗi ca/proctor; không giữ deleted/unassigned audit |
| scoring/ExaminerAttemptAssignment, ExaminerAnswerScore | Nguồn workload/progress theo nhân sự |
| scoring/ExaminerWorkQueueRepository | Personal queue không phục vụ Host, loại published sessions |
| scoring/ExaminerAssignmentService | GET batch overview expire previews; không reuse làm query thuần đọc |
| nextjs-admin-dashboard | Reference composition; không tìm thấy source Kanban, không port style/dependencies |

Các path bảng trên relative với app source của repo tương ứng; endpoint/status/schema phải đối chiếu source lần nữa phase 01.
Frontend source thực tế nằm dưới `pte-web/apps/tenant-web/features/`; backend dưới `pte-api/app/src/main/java/com/pte/`. Organization hiện chưa có trường timezone trong entity đã khảo sát: V1 dùng timezone hiển thị được chốt ở product validation, không tự thêm org settings/migration. Nếu sau này có cấu hình hợp lệ mới ưu tiên zone tổ chức.

## Architecture decisions

1. Backend thêm query/composition boundary nhỏ `examstaff`; Identity giữ profile mutation, Session giữ Proctor schedule, Scoring giữ Examiner projections.
2. Chỉ public module services; không identity -> scoring (tránh cycle với scoring -> identity), không repository xuyên module. Kiểm module metadata/allowlist/Modulith nếu hiện có.
3. Reuse domain-neutral ProfileHeader/ProfileLayout/account field presentation, không universal role-branch component. Features giữ DTO adapter/state/draft/actions/messages.
4. New board primitive @pte/ui nhận column/card slots/count/page/loading callbacks; không fetch, status derivation, DnD hoặc domain enums.
5. Dedicated tenant Host read APIs; không browser fan-out và không Examiner impersonation.
6. Account edit cần identity whitelist mới; không broaden Student PATCH. Staff email required theo hiện hành, username/roles không sửa. Email uniqueness canonical/case-insensitive trong tenant và xử lý conflict server.
7. Server filtering/count/paging; dates timezone-aware, stats theo cùng filter rõ ràng. Không hứa historical attendance/audit mà model không lưu.
8. Giữ credential email staff và account-wide suspend/reactivate; user manual UI, không auto E2E.

## Phase map

| Phase | Stories | Outcome |
| --- | --- | --- |
| [01 Contracts/security](phase-01-contracts-and-security.md) | US-01..06,08 | Chốt permissions, DTO, count/status/date semantics |
| [02 Backend](phase-02-backend-projections-and-profile.md) | US-02..06,08 | Staff detail/edit, Proctor query, Examiner aggregation |
| [03 API client/state](phase-03-api-client-and-state.md) | US-01..06,08,09 | Typed contracts/hooks/query keys/invalidation |
| [04 Common profile](phase-04-common-profile-and-account.md) | US-01,05..07,09 | Extract Learner presentation; staff route/account |
| [05 Proctor](phase-05-proctor-overview-and-schedule.md) | US-02,03,09 | Role-aware overview + date-grouped schedule/table |
| [06 Examiner](phase-06-examiner-overview-and-board.md) | US-02,04,08,09 | Session aggregate cards/board/table, read-only |
| [07 Verification](phase-07-verification-and-handoff.md) | All | Focused tests/typechecks/build/review + manual handoff |

Dependencies: 01 -> 02 -> 03 -> 04 -> (05,06) -> 07. Phase 04 may prepare presentation after 01 while backend runs, but cannot ship unconnected mock data as completed.
Phases 01–07 passed independent quality gates. Current integrated output has a fresh Phase07 receipt and post-gate final code review. Earlier phase receipts record completion-time snapshots, not collective freshness after later shared-output changes. Standard automatic continuation was explicitly authorized; manual/runtime acceptance remains pending.

## Design Constraints

- Đọc pte-web AGENTS.md và docs/CODING_STANDARDS_WEB.md; backend rules của repo trước implementation.
- Đọc relevant installed Next docs trước code route/navigation/loading/error, không dựa API cũ.
- Dùng common như shipped; không override font/font-size/menu trigger; layout composition được phép.
- Components <150 dòng, files <300 dòng; tách hook/actions/render/types/constants, không split để giấu complexity.
- Constants+i18n cho labels/messages/errors, không show raw API errors.
- Thin route `/host/exam-staff/[staff-id]`, awaited params theo installed Next docs, shared loading + route/query errors.
- Same-tab router navigation, không native href gây full reload hoặc window.open. Hidden work tabs lazy fetch theo role.
- Không sửa vendor/admin ngoài regression shared consumers; không migrate toàn hệ thống typography.
- No new dependencies/calendar/DnD, DB destructive operations, push/deploy.
- Không sửa assignment commands/lịch sử audit trong feature này trừ scope riêng được duyệt; queries phải bảo vệ malformed cross-tenant references.

## Quality and Testing State

- Execution choices: ck:cook Standard --no-tests --quality --checks-all-phases. User explicitly requested implementation of all phases before a single manual review; intermediate hard-mode pauses are superseded. Quality gates remain enabled; tests remain declined.
- Phase 01: completed; independent quality APPROVED, receipt verified VALID. [Report](quality/phase-01-contracts-and-security-quality-report.json), [receipt](quality/phase-01-contracts-and-security-receipt.json). User confirmed continuation of all remaining phases.
- Phase 02: completed; independent quality APPROVED, fresh receipt verified VALID after canonical attempt and scalar projection remediation. Compile passed; no live API/database evidence.
- Phase 03: completed; independent quality APPROVED, receipt verified VALID. API/tenant typechecks and scoped lint passed, no tests executed.
- Phase 04: completed; independent quality APPROVED after draft-preservation/canonical-cache remediation. Typecheck/lint/build passed, tests declined.
- Phase 05: completed; independent APPROVED after preview-time remediation, receipt VALID. Tenant/API typechecks, lint and diff check exit 0; no tests.
- Phase 06: completed; independent APPROVED, receipt VALID. Scoped lint/typechecks and tenant production build exit 0; no tests.
- Phase 07: completed; independent APPROVED after assertion-rationale advisory resolution, receipt VALID, separate post-gate final code review APPROVED. Backend compile, API/UI/tenant/vendor typechecks, scoped lint, tenant production build, three-repo diff checks exit 0. FE3000/3001 running, login HTTP200 only.
- Plan quality: self-review và independent Markdown red-team thực hiện; verdict WARN, ba finding ACCEPTED đã bổ sung. Xem [plan-review](plan-review.md). Đây không phải approval chất lượng implementation hoặc live source/API proof.
- Implementation quality: 7 approved phase gates; final source integration review zero open findings. Phase testing: not_started, explicitly declined by user. See [handoff](handoff.md) and [final code review](quality/final-code-review.md).
- Tests skipped by user for this execution; scoped lint/typecheck/build remain required where applicable, user tự kiểm UI.
- Quality choice was enabled for all phases; independent verdict is not human UI/runtime acceptance.
- Node-only Vitest không chứng minh rendered accessibility/client navigation.
- PostgreSQL live/HTTP/browser/E2E/release proof phải ghi riêng, không đồng nhất với H2/static/build.

## Risks / quyết định trước cook

| Risk | Mitigation |
| --- | --- |
| IDOR/cross-tenant session metadata | Scope target + every assignment/session; negative integration tests |
| Lifecycle/progress lẫn nhau | Separate sessionStatus/workStatus/publicationStatus |
| Kanban page đầu tạo count sai | Full-filter counts; separate page per column; server predicate reused |
| Double-count supplemental batches | Group by session/examiner; count distinct attempts/submitted answers |
| Proctor assignment đã xóa | Label remaining assignments; không claim lịch sử đầy đủ |
| Timezone/day bounds lệch | Explicit zone + UTC half-open interval + DST/boundary tests |
| Target suspended mất lịch sử | Allow suspended read; still server-authorize actions |
| Shared refactor gây Learner regression | Keep adapter and mutation feature-local; focused regression |
| Side-effectful existing GET | Dedicated read projection, test no writes |
| Mixed roles Student/staff hoặc privileged role | Phase01 dùng existing manageable-role policy; không broadening lifecycle rights |
| Không có scoring snapshot hợp lệ | unavailable và diagnostic, không fake zero |

Known follow-ups ngoài scope từ review Learner baseline: period attempt count(createdAt) khác score average(publishedAt); email lookup case sensitivity; deletion class/program coverage.
Known separate assignment-command gap: assignProctor target validation tenant/role/status cần task riêng, không tự sửa trong plan này.

## Baseline commits đã tạo trước khi lên plan

| Repo | Commits theo nhóm |
| --- | --- |
| pte-api | f920e7e identity; ca60f46 roster; 301152d reporting projections; 3afc376 student workspace |
| pte-web | fd59099 merge marker; 82e93ee API client; 48a83a5 Dropdown; e3a65e1 breadcrumb/i18n; f6f0602 Learner workspace; 02b810a coding rules |
| pte-doc | d269770 Learner plan và superseding UX decisions |

Baseline verification: 23 focused backend tests pass (0 failures/errors/skips); tenant/vendor tsc và UI/API-client typecheck pass.
Không fresh production build/browser/PostgreSQL verification trong lượt commit. Các commit trên KHÔNG là implementation Exam Staff.
Chưa push. Ba file exam mode ở pte-web không thuộc thay đổi này được giữ ngoài commit.

## Product validation (đã xác nhận)

1. Dual-role: cùng hồ sơ hiển thị cả Lịch coi thi và Theo dõi chấm bài.
2. Whitelist edit: fullName/email/phone/dateOfBirth; username và roles read-only.
3. Date filter: ưu tiên zone tổ chức nếu có cấu hình hợp lệ; nếu chưa có thì Asia/Ho_Chi_Minh, hiển thị rõ và gửi UTC bounds. Không tự thêm org settings/migration.

Người dùng trả lời “ok” để chốt cả ba đề xuất. Đây là xác nhận quyết định sản phẩm, không phải approval implementation, testing hoặc quality gate. Chưa có implementation trong lượt xác nhận này.

## Definition of done

- Mỗi story acceptance có evidence đúng loại; tenant permissions/count/status/date rules được kiểm chứng.
- Staff route và Learner common migration không clone visual defaults.
- Proctor schedule và Examiner board/table dùng dữ liệu API thật, filtered/paged, không fake stats.
- Account field/lifecycle/credential đúng role và ownership.
- Optional quality gate choices + results ghi per phase; test/build/manual UI giới hạn báo rõ.
- Không thay unrelated work, không deploy/push.

## Handoff command (chỉ sau validation)

```text
/ck:cook --no-tests --quality --checks-all-phases projects/plans/quang-tenant-exam-staff-workspace/plan.md
```

Có thể chọn --tdd nếu muốn test-first; mặc định hiện tại không tự bật.
Chạy với working directory pte-doc hoặc dùng absolute plan path khi ở pte-web.
